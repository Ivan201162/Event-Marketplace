import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/review.dart';

/// Сервис для работы с отзывами и рейтингами
class ReviewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Добавить отзыв
  Future<String> addReview({
    required String specialistId,
    required String customerId,
    required String customerName,
    required double rating,
    required String text,
    List<String> photos = const [],
    String? bookingId,
    String? eventTitle,
    String? customerAvatar,
    String? specialistName,
  }) async {
    try {
      // Валидация
      if (text.length < 20) {
        throw Exception('Отзыв должен содержать минимум 20 символов');
      }
      if (rating < 1 || rating > 5) {
        throw Exception('Рейтинг должен быть от 1 до 5');
      }

      // Создаем отзыв
      final review = Review(
        id: '', // Будет установлен Firestore
        specialistId: specialistId,
        customerId: customerId,
        customerName: customerName,
        rating: rating,
        text: text,
        date: DateTime.now(),
        photos: photos,
        responses: const [],
        bookingId: bookingId,
        eventTitle: eventTitle,
        customerAvatar: customerAvatar,
        specialistName: specialistName,
        metadata: const {},
      );

      // Добавляем в Firestore
      final docRef = await _firestore.collection('reviews').add(review.toMap());

      // Обновляем рейтинг специалиста
      await _updateSpecialistRating(specialistId);

      // Логируем событие
      await _analytics.logEvent(
        name: 'add_review',
        parameters: {
          'specialist_id': specialistId,
          'rating': rating,
          'has_photos': photos.isNotEmpty,
          'text_length': text.length,
        },
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка при добавлении отзыва: $e');
    }
  }

  /// Получить отзывы специалиста
  Future<List<Review>> getSpecialistReviews(
    String specialistId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
    ReviewSortType sortType = ReviewSortType.newest,
    ReviewFilter? filter,
  }) async {
    try {
      Query query = _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .where('isDeleted', isEqualTo: false);

      // Применяем фильтры
      if (filter != null) {
        if (filter.minRating != null) {
          query = query.where('rating', isGreaterThanOrEqualTo: filter.minRating);
        }
        if (filter.hasPhotos) {
          query = query.where('photos', isNotEqualTo: []);
        }
      }

      // Применяем сортировку
      switch (sortType) {
        case ReviewSortType.newest:
          query = query.orderBy('date', descending: true);
          break;
        case ReviewSortType.oldest:
          query = query.orderBy('date', descending: false);
          break;
        case ReviewSortType.highest:
          query = query.orderBy('rating', descending: true);
          break;
        case ReviewSortType.lowest:
          query = query.orderBy('rating', descending: false);
          break;
        case ReviewSortType.mostLiked:
          query = query.orderBy('likes', descending: true);
          break;
      }

      // Пагинация
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map(Review.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка при получении отзывов: $e');
    }
  }

  /// Редактировать отзыв
  Future<void> editReview({
    required String reviewId,
    required String text,
    double? rating,
    List<String>? photos,
  }) async {
    try {
      final reviewRef = _firestore.collection('reviews').doc(reviewId);
      final reviewDoc = await reviewRef.get();

      if (!reviewDoc.exists) {
        throw Exception('Отзыв не найден');
      }

      final review = Review.fromDocument(reviewDoc);

      // Проверяем, что прошло не более 24 часов
      final hoursSinceCreation = DateTime.now().difference(review.date).inHours;
      if (hoursSinceCreation > 24) {
        throw Exception('Отзыв можно редактировать только в течение 24 часов');
      }

      // Валидация
      if (text.length < 20) {
        throw Exception('Отзыв должен содержать минимум 20 символов');
      }
      if (rating != null && (rating < 1 || rating > 5)) {
        throw Exception('Рейтинг должен быть от 1 до 5');
      }

      // Обновляем отзыв
      await reviewRef.update({
        'text': text,
        if (rating != null) 'rating': rating,
        if (photos != null) 'photos': photos,
        'editedAt': FieldValue.serverTimestamp(),
        'isEdited': true,
      });

      // Обновляем рейтинг специалиста
      await _updateSpecialistRating(review.specialistId);

      // Логируем событие
      await _analytics.logEvent(
        name: 'edit_review',
        parameters: {
          'review_id': reviewId,
          'specialist_id': review.specialistId,
          'hours_since_creation': hoursSinceCreation,
        },
      );
    } catch (e) {
      throw Exception('Ошибка при редактировании отзыва: $e');
    }
  }

  /// Удалить отзыв
  Future<void> deleteReview(String reviewId) async {
    try {
      final reviewRef = _firestore.collection('reviews').doc(reviewId);
      final reviewDoc = await reviewRef.get();

      if (!reviewDoc.exists) {
        throw Exception('Отзыв не найден');
      }

      final review = Review.fromDocument(reviewDoc);

      // Проверяем, что прошло не более 24 часов
      final hoursSinceCreation = DateTime.now().difference(review.date).inHours;
      if (hoursSinceCreation > 24) {
        throw Exception('Отзыв можно удалить только в течение 24 часов');
      }

      // Помечаем как удаленный
      await reviewRef.update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      // Обновляем рейтинг специалиста
      await _updateSpecialistRating(review.specialistId);

      // Логируем событие
      await _analytics.logEvent(
        name: 'delete_review',
        parameters: {
          'review_id': reviewId,
          'specialist_id': review.specialistId,
          'hours_since_creation': hoursSinceCreation,
        },
      );
    } catch (e) {
      throw Exception('Ошибка при удалении отзыва: $e');
    }
  }

  /// Поставить лайк отзыву
  Future<void> likeReview(
    String reviewId,
    String userId,
    String userName,
  ) async {
    try {
      final likeRef =
          _firestore.collection('reviews').doc(reviewId).collection('likes').doc(userId);

      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // Убираем лайк
        await likeRef.delete();
        await _firestore.collection('reviews').doc(reviewId).update({
          'likes': FieldValue.increment(-1),
        });
      } else {
        // Ставим лайк
        await likeRef.set(
          ReviewLike(
            userId: userId,
            userName: userName,
            date: DateTime.now(),
          ).toMap(),
        );
        await _firestore.collection('reviews').doc(reviewId).update({
          'likes': FieldValue.increment(1),
        });
      }

      // Логируем событие
      await _analytics.logEvent(
        name: 'like_review',
        parameters: {
          'review_id': reviewId,
          'user_id': userId,
        },
      );
    } catch (e) {
      throw Exception('Ошибка при лайке отзыва: $e');
    }
  }

  /// Ответить на отзыв
  Future<void> respondToReview({
    required String reviewId,
    required String authorId,
    required String authorName,
    required String text,
  }) async {
    try {
      final reviewRef = _firestore.collection('reviews').doc(reviewId);
      final reviewDoc = await reviewRef.get();

      if (!reviewDoc.exists) {
        throw Exception('Отзыв не найден');
      }

      final response = ReviewResponse(
        authorId: authorId,
        authorName: authorName,
        text: text,
        date: DateTime.now(),
      );

      // Добавляем ответ
      await reviewRef.update({
        'responses': FieldValue.arrayUnion([response.toMap()]),
      });

      // Логируем событие
      await _analytics.logEvent(
        name: 'respond_review',
        parameters: {
          'review_id': reviewId,
          'author_id': authorId,
        },
      );
    } catch (e) {
      throw Exception('Ошибка при ответе на отзыв: $e');
    }
  }

  /// Пожаловаться на отзыв
  Future<void> reportReview({
    required String reviewId,
    required String reporterId,
    required String reporterName,
    required ReviewReportReason reason,
    String? description,
  }) async {
    try {
      final report = ReviewReport(
        id: '',
        reviewId: reviewId,
        reporterId: reporterId,
        reporterName: reporterName,
        reason: reason.value,
        description: description,
        date: DateTime.now(),
      );

      // Добавляем жалобу
      await _firestore.collection('review_reports').add(report.toMap());

      // Увеличиваем счетчик жалоб
      await _firestore.collection('reviews').doc(reviewId).update({
        'reportCount': FieldValue.increment(1),
        'isReported': true,
      });

      // Логируем событие
      await _analytics.logEvent(
        name: 'report_review',
        parameters: {
          'review_id': reviewId,
          'reporter_id': reporterId,
          'reason': reason.value,
        },
      );
    } catch (e) {
      throw Exception('Ошибка при жалобе на отзыв: $e');
    }
  }

  /// Получить репутацию специалиста
  Future<SpecialistReputation> getSpecialistReputation(
    String specialistId,
  ) async {
    try {
      final doc = await _firestore.collection('userStats').doc(specialistId).get();

      if (doc.exists) {
        return SpecialistReputation.fromMap(doc.data()!);
      } else {
        // Создаем новую запись репутации
        return SpecialistReputation(
          specialistId: specialistId,
          ratingAverage: 0,
          reviewsCount: 0,
          positiveReviews: 0,
          negativeReviews: 0,
          reputationScore: 0,
          status: ReputationStatus.needsExperience,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      throw Exception('Ошибка при получении репутации: $e');
    }
  }

  /// Обновить рейтинг специалиста
  Future<void> _updateSpecialistRating(String specialistId) async {
    try {
      // Получаем все отзывы специалиста
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .where('isDeleted', isEqualTo: false)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        return;
      }

      final reviews = reviewsSnapshot.docs.map(Review.fromDocument).toList();

      // Рассчитываем статистику
      final totalReviews = reviews.length;
      final totalRating = reviews.fold(0, (sum, review) => sum + review.rating);
      final averageRating = totalRating / totalReviews;

      final positiveReviews = reviews.where((r) => r.rating >= 4).length;
      final negativeReviews = reviews.where((r) => r.rating <= 2).length;

      final reputationScore = SpecialistReputation.calculateReputationScore(
        positiveReviews,
        negativeReviews,
      );

      final status = SpecialistReputation.getReputationStatus(reputationScore);

      // Обновляем статистику
      final reputation = SpecialistReputation(
        specialistId: specialistId,
        ratingAverage: averageRating,
        reviewsCount: totalReviews,
        positiveReviews: positiveReviews,
        negativeReviews: negativeReviews,
        reputationScore: reputationScore,
        status: status,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('userStats')
          .doc(specialistId)
          .set(reputation.toMap(), SetOptions(merge: true));

      // Обновляем рейтинг в профиле специалиста
      await _firestore.collection('specialists').doc(specialistId).update({
        'rating': averageRating,
        'reviewCount': totalReviews,
        'reputationScore': reputationScore,
        'reputationStatus': status.value,
      });
    } catch (e) {
      debugPrint('Ошибка при обновлении рейтинга: $e');
    }
  }

  /// Сохранить фильтры отзывов
  Future<void> saveReviewFilters(ReviewFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('review_filters', filter.toJson());
  }

  /// Загрузить фильтры отзывов
  Future<ReviewFilter?> loadReviewFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final filtersJson = prefs.getString('review_filters');
    if (filtersJson != null) {
      return ReviewFilter.fromJson(filtersJson);
    }
    return null;
  }

  /// Сохранить тип сортировки отзывов
  Future<void> saveReviewSortType(ReviewSortType sortType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('review_sort_type', sortType.name);
  }

  /// Загрузить тип сортировки отзывов
  Future<ReviewSortType> loadReviewSortType() async {
    final prefs = await SharedPreferences.getInstance();
    final sortTypeName = prefs.getString('review_sort_type');
    if (sortTypeName != null) {
      return ReviewSortType.values.firstWhere(
        (type) => type.name == sortTypeName,
        orElse: () => ReviewSortType.newest,
      );
    }
    return ReviewSortType.newest;
  }
}

/// Типы сортировки отзывов
enum ReviewSortType {
  newest('newest', 'Сначала новые'),
  oldest('oldest', 'Сначала старые'),
  highest('highest', 'Сначала лучшие'),
  lowest('lowest', 'Сначала худшие'),
  mostLiked('most_liked', 'Больше лайков');

  const ReviewSortType(this.value, this.displayName);
  final String value;
  final String displayName;
}

/// Фильтр отзывов
class ReviewFilter {
  const ReviewFilter({
    this.minRating,
    this.hasPhotos = false,
    this.fromDate,
    this.toDate,
  });

  factory ReviewFilter.fromJson(String json) {
    // Простая реализация парсинга JSON
    final hasPhotos = json.contains('"hasPhotos": true');
    final minRatingMatch = RegExp(r'"minRating": (\d+(?:\.\d+)?)').firstMatch(json);
    final minRating = minRatingMatch != null ? double.tryParse(minRatingMatch.group(1)!) : null;

    return ReviewFilter(
      minRating: minRating,
      hasPhotos: hasPhotos,
    );
  }
  final double? minRating;
  final bool hasPhotos;
  final DateTime? fromDate;
  final DateTime? toDate;

  String toJson() => '''
    {
      "minRating": ${minRating ?? 'null'},
      "hasPhotos": $hasPhotos,
      "fromDate": ${fromDate?.millisecondsSinceEpoch ?? 'null'},
      "toDate": ${toDate?.millisecondsSinceEpoch ?? 'null'}
    }
    ''';
}
