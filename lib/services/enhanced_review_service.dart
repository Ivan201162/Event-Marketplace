import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/review.dart';

/// Улучшенный сервис для работы с отзывами и рейтингами
class EnhancedReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _reviewsCollection = 'reviews';
  static const String _specialistsCollection = 'specialists';

  /// Создать новый отзыв
  Future<String> createReview({
    required String specialistId,
    required String customerId,
    required String customerName,
    required int rating,
    required String comment,
    String? bookingId,
    String? eventTitle,
    List<String>? serviceTags,
    String? customerAvatar,
  }) async {
    try {
      // Валидация данных
      if (rating < 1 || rating > 5) {
        throw Exception('Рейтинг должен быть от 1 до 5');
      }

      if (comment.trim().length < 10) {
        throw Exception('Комментарий должен содержать минимум 10 символов');
      }

      // Проверяем, что заказ завершен (если указан bookingId)
      if (bookingId != null) {
        final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();

        if (!bookingDoc.exists) {
          throw Exception('Заказ не найден');
        }

        final bookingData = bookingDoc.data()!;
        if (bookingData['status'] != 'completed') {
          throw Exception(
            'Отзыв можно оставить только для завершенных заказов',
          );
        }
      }

      // Проверяем, что отзыв еще не существует для этого заказа
      if (bookingId != null) {
        final existingReview = await _firestore
            .collection(_reviewsCollection)
            .where('bookingId', isEqualTo: bookingId)
            .limit(1)
            .get();

        if (existingReview.docs.isNotEmpty) {
          throw Exception('Отзыв для этого заказа уже существует');
        }
      }

      // Получаем имя специалиста
      final specialistDoc =
          await _firestore.collection(_specialistsCollection).doc(specialistId).get();

      final specialistName = specialistDoc.exists
          ? (specialistDoc.data()?['name'] ?? 'Unknown specialist')
          : 'Unknown specialist';

      // Создаем отзыв
      final reviewData = {
        'specialistId': specialistId,
        'customerId': customerId,
        'customerName': customerName,
        'rating': rating,
        'comment': comment.trim(),
        'serviceTags': serviceTags ?? [],
        'bookingId': bookingId,
        'eventTitle': eventTitle,
        'customerAvatar': customerAvatar,
        'specialistName': specialistName,
        'createdAt': FieldValue.serverTimestamp(),
        'isEdited': false,
        'isDeleted': false,
        'metadata': {},
      };

      final docRef = await _firestore.collection(_reviewsCollection).add(reviewData);

      // Обновляем статистику специалиста
      await _updateSpecialistStats(specialistId);

      return docRef.id;
    } catch (e) {
      debugPrint('Ошибка создания отзыва: $e');
      throw Exception('Не удалось создать отзыв: $e');
    }
  }

  /// Получить отзывы специалиста
  Future<List<Review>> getSpecialistReviews(
    String specialistId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      var query = _firestore
          .collection(_reviewsCollection)
          .where('specialistId', isEqualTo: specialistId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map(Review.fromDocument).toList();
    } catch (e) {
      debugPrint('Ошибка получения отзывов: $e');
      return [];
    }
  }

  /// Получить поток отзывов специалиста
  Stream<List<Review>> getSpecialistReviewsStream(String specialistId) => _firestore
      .collection(_reviewsCollection)
      .where('specialistId', isEqualTo: specialistId)
      .where('isDeleted', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Review.fromDocument).toList());

  /// Получить статистику отзывов специалиста
  Future<ReviewStats> getSpecialistReviewStats(String specialistId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('specialistId', isEqualTo: specialistId)
          .where('isDeleted', isEqualTo: false)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        return const ReviewStats(
          totalReviews: 0,
          averageRating: 0,
          ratingDistribution: {},
        );
      }

      final reviews = reviewsSnapshot.docs.map(Review.fromDocument).toList();

      // Подсчитываем распределение рейтингов
      final ratingDistribution = <int, int>{};
      double totalRating = 0;

      for (final review in reviews) {
        ratingDistribution[review.rating.round()] =
            (ratingDistribution[review.rating.round()] ?? 0) + 1;
        totalRating += review.rating;
      }

      final averageRating = totalRating / reviews.length;

      return ReviewStats(
        totalReviews: reviews.length,
        averageRating: averageRating,
        ratingDistribution: ratingDistribution,
      );
    } catch (e) {
      debugPrint('Ошибка получения статистики отзывов: $e');
      return const ReviewStats(
        totalReviews: 0,
        averageRating: 0,
        ratingDistribution: {},
      );
    }
  }

  /// Получить поток статистики отзывов
  Stream<ReviewStats> getSpecialistReviewStatsStream(String specialistId) => _firestore
          .collection(_reviewsCollection)
          .where('specialistId', isEqualTo: specialistId)
          .where('isDeleted', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          return const ReviewStats(
            totalReviews: 0,
            averageRating: 0,
            ratingDistribution: {},
          );
        }

        final reviews = snapshot.docs.map(Review.fromDocument).toList();

        final ratingDistribution = <int, int>{};
        double totalRating = 0;

        for (final review in reviews) {
          ratingDistribution[review.rating.round()] =
              (ratingDistribution[review.rating.round()] ?? 0) + 1;
          totalRating += review.rating;
        }

        final averageRating = totalRating / reviews.length;

        return ReviewStats(
          totalReviews: reviews.length,
          averageRating: averageRating,
          ratingDistribution: ratingDistribution,
        );
      });

  /// Обновить отзыв
  Future<void> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
  }) async {
    try {
      // Валидация данных
      if (rating < 1 || rating > 5) {
        throw Exception('Рейтинг должен быть от 1 до 5');
      }

      if (comment.trim().length < 10) {
        throw Exception('Комментарий должен содержать минимум 10 символов');
      }

      final reviewDoc = await _firestore.collection(_reviewsCollection).doc(reviewId).get();

      if (!reviewDoc.exists) {
        throw Exception('Отзыв не найден');
      }

      final reviewData = reviewDoc.data()!;
      final specialistId = reviewData['specialistId'] as String;

      // Проверяем, можно ли редактировать отзыв (в течение 24 часов)
      final createdAt = (reviewData['createdAt'] as Timestamp).toDate();
      final now = DateTime.now();
      final hoursSinceCreation = now.difference(createdAt).inHours;

      if (hoursSinceCreation > 24) {
        throw Exception('Отзыв можно редактировать только в течение 24 часов');
      }

      // Обновляем отзыв
      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'rating': rating,
        'comment': comment.trim(),
        'editedAt': FieldValue.serverTimestamp(),
        'isEdited': true,
      });

      // Обновляем статистику специалиста
      await _updateSpecialistStats(specialistId);
    } catch (e) {
      debugPrint('Ошибка обновления отзыва: $e');
      throw Exception('Не удалось обновить отзыв: $e');
    }
  }

  /// Удалить отзыв
  Future<void> deleteReview(String reviewId) async {
    try {
      final reviewDoc = await _firestore.collection(_reviewsCollection).doc(reviewId).get();

      if (!reviewDoc.exists) {
        throw Exception('Отзыв не найден');
      }

      final reviewData = reviewDoc.data()!;
      final specialistId = reviewData['specialistId'] as String;

      // Проверяем, можно ли удалить отзыв (в течение 24 часов)
      final createdAt = (reviewData['createdAt'] as Timestamp).toDate();
      final now = DateTime.now();
      final hoursSinceCreation = now.difference(createdAt).inHours;

      if (hoursSinceCreation > 24) {
        throw Exception('Отзыв можно удалить только в течение 24 часов');
      }

      // Помечаем отзыв как удаленный
      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      // Обновляем статистику специалиста
      await _updateSpecialistStats(specialistId);
    } catch (e) {
      debugPrint('Ошибка удаления отзыва: $e');
      throw Exception('Не удалось удалить отзыв: $e');
    }
  }

  /// Получить отзыв пользователя для специалиста
  Future<Review?> getUserReviewForSpecialist({
    required String specialistId,
    required String customerId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_reviewsCollection)
          .where('specialistId', isEqualTo: specialistId)
          .where('customerId', isEqualTo: customerId)
          .where('isDeleted', isEqualTo: false)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return Review.fromDocument(snapshot.docs.first);
    } catch (e) {
      debugPrint('Ошибка получения отзыва пользователя: $e');
      return null;
    }
  }

  /// Проверить, может ли пользователь оставить отзыв
  Future<bool> canUserLeaveReview({
    required String specialistId,
    required String customerId,
  }) async {
    try {
      // Проверяем, есть ли уже отзыв от этого пользователя
      final existingReview = await getUserReviewForSpecialist(
        specialistId: specialistId,
        customerId: customerId,
      );

      if (existingReview != null) {
        return false;
      }

      // Проверяем, есть ли завершенные заказы
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('customerId', isEqualTo: customerId)
          .where('status', isEqualTo: 'completed')
          .limit(1)
          .get();

      return bookingsSnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Ошибка проверки возможности оставить отзыв: $e');
      return false;
    }
  }

  /// Обновить статистику специалиста
  Future<void> _updateSpecialistStats(String specialistId) async {
    try {
      final stats = await getSpecialistReviewStats(specialistId);

      await _firestore.collection(_specialistsCollection).doc(specialistId).update({
        'rating': stats.averageRating,
        'reviewCount': stats.totalReviews,
        'lastReviewUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Ошибка обновления статистики специалиста: $e');
    }
  }

  /// Получить популярные отзывы
  Future<List<Review>> getPopularReviews({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_reviewsCollection)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(Review.fromDocument).toList();
    } catch (e) {
      debugPrint('Ошибка получения популярных отзывов: $e');
      return [];
    }
  }
}

/// Статистика отзывов
class ReviewStats {
  const ReviewStats({
    required this.totalReviews,
    required this.averageRating,
    required this.ratingDistribution,
  });

  final int totalReviews;
  final double averageRating;
  final Map<int, int> ratingDistribution; // рейтинг -> количество

  /// Получить процентное распределение рейтингов
  Map<int, double> get ratingPercentages {
    if (totalReviews == 0) return {};

    return ratingDistribution.map(
      (rating, count) => MapEntry(
        rating,
        (count / totalReviews) * 100,
      ),
    );
  }

  /// Получить количество отзывов с определенным рейтингом
  int getRatingCount(int rating) => ratingDistribution[rating] ?? 0;

  /// Получить процент отзывов с определенным рейтингом
  double getRatingPercentage(int rating) {
    if (totalReviews == 0) return 0;
    return (getRatingCount(rating) / totalReviews) * 100;
  }
}
