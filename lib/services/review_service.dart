import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

/// Сервис для управления отзывами и рейтингами
class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Создать отзыв
  Future<Review> createReview({
    required String bookingId,
    required String customerId,
    required String specialistId,
    required int rating,
    String? title,
    String? comment,
    List<String> tags = const [],
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Проверяем, не оставлял ли уже отзыв по этой заявке
      final existingReview = await getReviewByBooking(bookingId);
      if (existingReview != null) {
        throw Exception('Отзыв по этой заявке уже существует');
      }

      // Валидируем рейтинг
      if (rating < 1 || rating > 5) {
        throw Exception('Рейтинг должен быть от 1 до 5');
      }

      final review = Review(
        id: _generateReviewId(),
        bookingId: bookingId,
        customerId: customerId,
        specialistId: specialistId,
        rating: rating,
        title: title,
        comment: comment,
        tags: tags,
        createdAt: DateTime.now(),
        isVerified: false,
        isPublic: true,
        metadata: metadata,
      );

      await _db.collection('reviews').doc(review.id).set(review.toMap());
      return review;
    } catch (e) {
      print('Ошибка создания отзыва: $e');
      throw Exception('Не удалось создать отзыв: $e');
    }
  }

  /// Получить отзыв по ID
  Future<Review?> getReview(String reviewId) async {
    try {
      final doc = await _db.collection('reviews').doc(reviewId).get();
      if (doc.exists) {
        return Review.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка получения отзыва: $e');
      return null;
    }
  }

  /// Получить отзыв по заявке
  Future<Review?> getReviewByBooking(String bookingId) async {
    try {
      final querySnapshot = await _db
          .collection('reviews')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Review.fromDocument(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Ошибка получения отзыва по заявке: $e');
      return null;
    }
  }

  /// Получить отзывы специалиста
  Future<List<Review>> getSpecialistReviews(
    String specialistId, {
    int limit = 50,
    bool onlyPublic = true,
  }) async {
    try {
      Query query = _db
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (onlyPublic) {
        query = query.where('isPublic', isEqualTo: true);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => Review.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Ошибка получения отзывов специалиста: $e');
      return [];
    }
  }

  /// Поток отзывов специалиста
  Stream<List<Review>> getSpecialistReviewsStream(
    String specialistId, {
    int limit = 50,
    bool onlyPublic = true,
  }) {
    Query query = _db
        .collection('reviews')
        .where('specialistId', isEqualTo: specialistId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (onlyPublic) {
      query = query.where('isPublic', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Review.fromDocument(doc))
        .toList());
  }

  /// Получить отзывы клиента
  Future<List<Review>> getCustomerReviews(
    String customerId, {
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _db
          .collection('reviews')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Review.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Ошибка получения отзывов клиента: $e');
      return [];
    }
  }

  /// Обновить отзыв
  Future<void> updateReview(
    String reviewId, {
    int? rating,
    String? title,
    String? comment,
    List<String>? tags,
    bool? isPublic,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (rating != null) {
        if (rating < 1 || rating > 5) {
          throw Exception('Рейтинг должен быть от 1 до 5');
        }
        updateData['rating'] = rating;
      }

      if (title != null) updateData['title'] = title;
      if (comment != null) updateData['comment'] = comment;
      if (tags != null) updateData['tags'] = tags;
      if (isPublic != null) updateData['isPublic'] = isPublic;

      await _db.collection('reviews').doc(reviewId).update(updateData);
    } catch (e) {
      print('Ошибка обновления отзыва: $e');
      throw Exception('Не удалось обновить отзыв: $e');
    }
  }

  /// Удалить отзыв
  Future<void> deleteReview(String reviewId) async {
    try {
      await _db.collection('reviews').doc(reviewId).delete();
    } catch (e) {
      print('Ошибка удаления отзыва: $e');
      throw Exception('Не удалось удалить отзыв: $e');
    }
  }

  /// Отметить отзыв как проверенный
  Future<void> verifyReview(String reviewId) async {
    try {
      await _db.collection('reviews').doc(reviewId).update({
        'isVerified': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка проверки отзыва: $e');
      throw Exception('Не удалось проверить отзыв: $e');
    }
  }

  /// Получить статистику отзывов специалиста
  Future<ReviewStatistics> getSpecialistReviewStatistics(String specialistId) async {
    try {
      final reviews = await getSpecialistReviews(specialistId, onlyPublic: true);
      
      if (reviews.isEmpty) {
        return ReviewStatistics.empty();
      }

      // Вычисляем средний рейтинг
      final totalRating = reviews.fold(0, (sum, review) => sum + review.rating);
      final averageRating = totalRating / reviews.length;

      // Распределение по рейтингам
      final ratingDistribution = <int, int>{};
      for (int i = 1; i <= 5; i++) {
        ratingDistribution[i] = reviews.where((r) => r.rating == i).length;
      }

      // Популярные теги
      final tagCounts = <String, int>{};
      for (final review in reviews) {
        for (final tag in review.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
      final commonTags = tagCounts.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
      final topTags = commonTags.take(5).map((e) => e.key).toList();

      // Процент проверенных отзывов
      final verifiedCount = reviews.where((r) => r.isVerified).length;
      final verifiedPercentage = (verifiedCount / reviews.length) * 100;

      // Дата последнего отзыва
      final lastReviewDate = reviews.isNotEmpty ? reviews.first.createdAt : null;

      return ReviewStatistics(
        averageRating: averageRating,
        totalReviews: reviews.length,
        ratingDistribution: ratingDistribution,
        commonTags: topTags,
        verifiedPercentage: verifiedPercentage,
        lastReviewDate: lastReviewDate,
      );
    } catch (e) {
      print('Ошибка получения статистики отзывов: $e');
      return ReviewStatistics.empty();
    }
  }

  /// Получить статистику отзывов клиента
  Future<ReviewStatistics> getCustomerReviewStatistics(String customerId) async {
    try {
      final reviews = await getCustomerReviews(customerId);
      
      if (reviews.isEmpty) {
        return ReviewStatistics.empty();
      }

      // Вычисляем средний рейтинг (как клиент оценивает специалистов)
      final totalRating = reviews.fold(0, (sum, review) => sum + review.rating);
      final averageRating = totalRating / reviews.length;

      // Распределение по рейтингам
      final ratingDistribution = <int, int>{};
      for (int i = 1; i <= 5; i++) {
        ratingDistribution[i] = reviews.where((r) => r.rating == i).length;
      }

      // Популярные теги
      final tagCounts = <String, int>{};
      for (final review in reviews) {
        for (final tag in review.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
      final commonTags = tagCounts.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
      final topTags = commonTags.take(5).map((e) => e.key).toList();

      // Процент проверенных отзывов
      final verifiedCount = reviews.where((r) => r.isVerified).length;
      final verifiedPercentage = (verifiedCount / reviews.length) * 100;

      // Дата последнего отзыва
      final lastReviewDate = reviews.isNotEmpty ? reviews.first.createdAt : null;

      return ReviewStatistics(
        averageRating: averageRating,
        totalReviews: reviews.length,
        ratingDistribution: ratingDistribution,
        commonTags: topTags,
        verifiedPercentage: verifiedPercentage,
        lastReviewDate: lastReviewDate,
      );
    } catch (e) {
      print('Ошибка получения статистики отзывов клиента: $e');
      return ReviewStatistics.empty();
    }
  }

  /// Создать детальную оценку
  Future<DetailedRating> createDetailedRating({
    required String reviewId,
    required Map<String, int> criteriaRatings,
  }) async {
    try {
      // Валидируем рейтинги критериев
      for (final rating in criteriaRatings.values) {
        if (rating < 1 || rating > 5) {
          throw Exception('Рейтинг критерия должен быть от 1 до 5');
        }
      }

      final detailedRating = DetailedRating(
        reviewId: reviewId,
        criteriaRatings: criteriaRatings,
        createdAt: DateTime.now(),
      );

      await _db.collection('detailed_ratings').doc(reviewId).set(detailedRating.toMap());
      return detailedRating;
    } catch (e) {
      print('Ошибка создания детальной оценки: $e');
      throw Exception('Не удалось создать детальную оценку: $e');
    }
  }

  /// Получить детальную оценку
  Future<DetailedRating?> getDetailedRating(String reviewId) async {
    try {
      final doc = await _db.collection('detailed_ratings').doc(reviewId).get();
      if (doc.exists) {
        return DetailedRating.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка получения детальной оценки: $e');
      return null;
    }
  }

  /// Получить топ специалистов по рейтингу
  Future<List<Map<String, dynamic>>> getTopSpecialists({
    int limit = 10,
    int minReviews = 5,
  }) async {
    try {
      // Получаем всех специалистов с отзывами
      final reviewsSnapshot = await _db
          .collection('reviews')
          .where('isPublic', isEqualTo: true)
          .get();

      final specialistStats = <String, Map<String, dynamic>>{};

      for (final doc in reviewsSnapshot.docs) {
        final review = Review.fromDocument(doc);
        final specialistId = review.specialistId;

        if (!specialistStats.containsKey(specialistId)) {
          specialistStats[specialistId] = {
            'specialistId': specialistId,
            'totalRating': 0,
            'reviewCount': 0,
            'averageRating': 0.0,
          };
        }

        final stats = specialistStats[specialistId]!;
        stats['totalRating'] = (stats['totalRating'] as int) + review.rating;
        stats['reviewCount'] = (stats['reviewCount'] as int) + 1;
      }

      // Вычисляем средние рейтинги и фильтруем
      final topSpecialists = specialistStats.values
          .where((stats) => (stats['reviewCount'] as int) >= minReviews)
          .map((stats) {
            final reviewCount = stats['reviewCount'] as int;
            final totalRating = stats['totalRating'] as int;
            stats['averageRating'] = totalRating / reviewCount;
            return stats;
          })
          .toList();

      // Сортируем по среднему рейтингу
      topSpecialists.sort((a, b) => 
          (b['averageRating'] as double).compareTo(a['averageRating'] as double));

      return topSpecialists.take(limit).toList();
    } catch (e) {
      print('Ошибка получения топ специалистов: $e');
      return [];
    }
  }

  /// Генерировать ID отзыва
  String _generateReviewId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'REV_${timestamp}_$random';
  }
}
