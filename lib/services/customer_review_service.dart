import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/customer_review.dart';
import 'error_logging_service.dart';

/// Сервис для работы с отзывами заказчиков
class CustomerReviewService {
  factory CustomerReviewService() => _instance;
  CustomerReviewService._internal();
  static final CustomerReviewService _instance =
      CustomerReviewService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ErrorLoggingService _errorLogger = ErrorLoggingService();

  /// Создать отзыв
  Future<CustomerReview?> createReview({
    required String specialistId,
    required String orderId,
    required double rating,
    required String text,
    List<String>? images,
    Map<ReviewCriteria, double>? criteriaRatings,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        await _errorLogger.logError(
          error: 'User not authenticated',
          stackTrace: StackTrace.current.toString(),
          action: 'create_review',
        );
        return null;
      }

      final reviewId = _firestore.collection('customer_reviews').doc().id;
      final now = DateTime.now();

      final review = CustomerReview(
        id: reviewId,
        customerId: user.uid,
        specialistId: specialistId,
        orderId: orderId,
        rating: rating,
        text: text,
        images: images,
        createdAt: now,
        updatedAt: now,
        isVerified: false,
        metadata: metadata,
      );

      // Сохраняем отзыв
      await _firestore
          .collection('customer_reviews')
          .doc(reviewId)
          .set(review.toMap());

      // Сохраняем детальные оценки по критериям
      if (criteriaRatings != null && criteriaRatings.isNotEmpty) {
        final detailedRating = DetailedRating(
          reviewId: reviewId,
          criteriaRatings: criteriaRatings,
          createdAt: now,
        );

        await _firestore
            .collection('detailed_ratings')
            .doc(reviewId)
            .set(detailedRating.toMap());
      }

      // Обновляем статистику специалиста
      await _updateSpecialistReviewStats(specialistId);

      await _errorLogger.logInfo(
        message: 'Customer review created',
        userId: user.uid,
        action: 'create_review',
        additionalData: {
          'reviewId': reviewId,
          'specialistId': specialistId,
          'orderId': orderId,
          'rating': rating,
        },
      );

      return review;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to create review: $e',
        stackTrace: stackTrace.toString(),
        action: 'create_review',
        additionalData: {
          'specialistId': specialistId,
          'orderId': orderId,
          'rating': rating,
        },
      );
      return null;
    }
  }

  /// Получить отзывы специалиста
  Future<List<CustomerReview>> getSpecialistReviews(
    String specialistId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('customer_reviews')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map(CustomerReview.fromDoc).toList();
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get specialist reviews: $e',
        stackTrace: stackTrace.toString(),
        action: 'get_specialist_reviews',
        additionalData: {'specialistId': specialistId},
      );
      return [];
    }
  }

  /// Получить отзыв по ID
  Future<CustomerReview?> getReviewById(String reviewId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('customer_reviews').doc(reviewId).get();

      if (doc.exists) {
        return CustomerReview.fromDoc(doc);
      }
      return null;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get review by ID: $e',
        stackTrace: stackTrace.toString(),
        action: 'get_review_by_id',
        additionalData: {'reviewId': reviewId},
      );
      return null;
    }
  }

  /// Обновить отзыв
  Future<bool> updateReview(
    String reviewId, {
    double? rating,
    String? text,
    List<String>? images,
    Map<ReviewCriteria, double>? criteriaRatings,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (rating != null) updates['rating'] = rating;
      if (text != null) updates['text'] = text;
      if (images != null) updates['images'] = images;

      await _firestore
          .collection('customer_reviews')
          .doc(reviewId)
          .update(updates);

      // Обновляем детальные оценки
      if (criteriaRatings != null && criteriaRatings.isNotEmpty) {
        final detailedRating = DetailedRating(
          reviewId: reviewId,
          criteriaRatings: criteriaRatings,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('detailed_ratings')
            .doc(reviewId)
            .set(detailedRating.toMap());
      }

      // Получаем specialistId для обновления статистики
      final review = await getReviewById(reviewId);
      if (review != null) {
        await _updateSpecialistReviewStats(review.specialistId);
      }

      await _errorLogger.logInfo(
        message: 'Review updated',
        userId: user.uid,
        action: 'update_review',
        additionalData: {'reviewId': reviewId},
      );

      return true;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to update review: $e',
        stackTrace: stackTrace.toString(),
        action: 'update_review',
        additionalData: {'reviewId': reviewId},
      );
      return false;
    }
  }

  /// Удалить отзыв
  Future<bool> deleteReview(String reviewId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Получаем отзыв для получения specialistId
      final review = await getReviewById(reviewId);
      if (review == null) return false;

      // Удаляем отзыв
      await _firestore.collection('customer_reviews').doc(reviewId).delete();

      // Удаляем детальные оценки
      await _firestore.collection('detailed_ratings').doc(reviewId).delete();

      // Обновляем статистику специалиста
      await _updateSpecialistReviewStats(review.specialistId);

      await _errorLogger.logInfo(
        message: 'Review deleted',
        userId: user.uid,
        action: 'delete_review',
        additionalData: {'reviewId': reviewId},
      );

      return true;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to delete review: $e',
        stackTrace: stackTrace.toString(),
        action: 'delete_review',
        additionalData: {'reviewId': reviewId},
      );
      return false;
    }
  }

  /// Ответить на отзыв
  Future<bool> respondToReview(String reviewId, String response) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('customer_reviews').doc(reviewId).update({
        'response': response,
        'responseDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _errorLogger.logInfo(
        message: 'Review response added',
        userId: user.uid,
        action: 'respond_to_review',
        additionalData: {'reviewId': reviewId},
      );

      return true;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to respond to review: $e',
        stackTrace: stackTrace.toString(),
        action: 'respond_to_review',
        additionalData: {'reviewId': reviewId},
      );
      return false;
    }
  }

  /// Получить статистику отзывов специалиста
  Future<CustomerReviewStats?> getSpecialistReviewStats(
    String specialistId,
  ) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('review_stats').doc(specialistId).get();

      if (doc.exists) {
        return CustomerReviewStats.fromMap(doc.data()! as Map<String, dynamic>);
      }

      // Если статистики нет, создаем ее
      return await _calculateAndSaveReviewStats(specialistId);
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get specialist review stats: $e',
        stackTrace: stackTrace.toString(),
        action: 'get_specialist_review_stats',
        additionalData: {'specialistId': specialistId},
      );
      return null;
    }
  }

  /// Получить детальные оценки отзыва
  Future<DetailedRating?> getDetailedRating(String reviewId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('detailed_ratings').doc(reviewId).get();

      if (doc.exists) {
        return DetailedRating.fromMap(doc.data()! as Map<String, dynamic>);
      }
      return null;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get detailed rating: $e',
        stackTrace: stackTrace.toString(),
        action: 'get_detailed_rating',
        additionalData: {'reviewId': reviewId},
      );
      return null;
    }
  }

  /// Поиск отзывов
  Future<List<CustomerReview>> searchReviews({
    String? query,
    String? specialistId,
    double? minRating,
    double? maxRating,
    bool? isVerified,
    bool? hasImages,
    bool? hasResponse,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
  }) async {
    try {
      Query firestoreQuery = _firestore.collection('customer_reviews');

      // Базовые фильтры
      if (specialistId != null) {
        firestoreQuery =
            firestoreQuery.where('specialistId', isEqualTo: specialistId);
      }
      if (minRating != null) {
        firestoreQuery =
            firestoreQuery.where('rating', isGreaterThanOrEqualTo: minRating);
      }
      if (isVerified != null) {
        firestoreQuery =
            firestoreQuery.where('isVerified', isEqualTo: isVerified);
      }

      // Сортировка
      firestoreQuery = firestoreQuery
          .orderBy('createdAt', descending: true)
          .limit(limit * 2);

      final snapshot = await firestoreQuery.get();
      var reviews = snapshot.docs.map(CustomerReview.fromDoc).toList();

      // Дополнительная фильтрация на клиенте
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        reviews = reviews
            .where(
              (review) =>
                  review.text.toLowerCase().contains(lowerQuery) ||
                  (review.response?.toLowerCase().contains(lowerQuery) ??
                      false),
            )
            .toList();
      }

      if (maxRating != null) {
        reviews =
            reviews.where((review) => review.rating <= maxRating).toList();
      }

      if (hasImages != null) {
        reviews = reviews
            .where(
              (review) => hasImages
                  ? (review.images?.isNotEmpty ?? false)
                  : (review.images?.isEmpty ?? true),
            )
            .toList();
      }

      if (hasResponse != null) {
        reviews = reviews
            .where(
              (review) => hasResponse
                  ? (review.response?.isNotEmpty ?? false)
                  : (review.response?.isEmpty ?? true),
            )
            .toList();
      }

      if (startDate != null) {
        reviews = reviews
            .where((review) => review.createdAt.isAfter(startDate))
            .toList();
      }

      if (endDate != null) {
        reviews = reviews
            .where((review) => review.createdAt.isBefore(endDate))
            .toList();
      }

      return reviews.take(limit).toList();
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to search reviews: $e',
        stackTrace: stackTrace.toString(),
        action: 'search_reviews',
        additionalData: {
          'query': query,
          'specialistId': specialistId,
          'minRating': minRating,
          'maxRating': maxRating,
          'isVerified': isVerified,
        },
      );
      return [];
    }
  }

  /// Обновить статистику отзывов специалиста
  Future<void> _updateSpecialistReviewStats(String specialistId) async {
    try {
      await _calculateAndSaveReviewStats(specialistId);
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to update specialist review stats: $e',
        stackTrace: stackTrace.toString(),
        action: 'update_specialist_review_stats',
        additionalData: {'specialistId': specialistId},
      );
    }
  }

  /// Вычислить и сохранить статистику отзывов
  Future<CustomerReviewStats?> _calculateAndSaveReviewStats(
    String specialistId,
  ) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('customer_reviews')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final reviews = snapshot.docs.map(CustomerReview.fromDoc).toList();

      if (reviews.isEmpty) return null;

      // Вычисляем статистику
      final totalReviews = reviews.length;
      final averageRating =
          reviews.map((r) => r.rating).reduce((a, b) => a + b) / totalReviews;

      final ratingDistribution = <int, int>{};
      for (var i = 1; i <= 5; i++) {
        ratingDistribution[i] =
            reviews.where((r) => r.rating.round() == i).length;
      }

      final verifiedReviews = reviews.where((r) => r.isVerified).length;
      final reviewsWithImages =
          reviews.where((r) => r.images?.isNotEmpty ?? false).length;
      final reviewsWithResponse =
          reviews.where((r) => r.response?.isNotEmpty ?? false).length;

      final stats = CustomerReviewStats(
        specialistId: specialistId,
        averageRating: averageRating,
        totalReviews: totalReviews,
        ratingDistribution: ratingDistribution,
        verifiedReviews: verifiedReviews,
        reviewsWithImages: reviewsWithImages,
        reviewsWithResponse: reviewsWithResponse,
        lastUpdated: DateTime.now(),
      );

      // Сохраняем статистику
      await _firestore
          .collection('review_stats')
          .doc(specialistId)
          .set(stats.toMap());

      return stats;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to calculate and save review stats: $e',
        stackTrace: stackTrace.toString(),
        action: 'calculate_and_save_review_stats',
        additionalData: {'specialistId': specialistId},
      );
      return null;
    }
  }

  /// Получить отзывы пользователя
  Future<List<CustomerReview>> getUserReviews(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('customer_reviews')
          .where('customerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(CustomerReview.fromDoc).toList();
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get user reviews: $e',
        stackTrace: stackTrace.toString(),
        action: 'get_user_reviews',
        additionalData: {'userId': userId},
      );
      return [];
    }
  }

  /// Проверить, может ли пользователь оставить отзыв
  Future<bool> canUserReview(String userId, String orderId) async {
    try {
      // Проверяем, есть ли уже отзыв на этот заказ
      final existingReview = await _firestore
          .collection('customer_reviews')
          .where('customerId', isEqualTo: userId)
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      return existingReview.docs.isEmpty;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to check if user can review: $e',
        stackTrace: stackTrace.toString(),
        action: 'can_user_review',
        additionalData: {'userId': userId, 'orderId': orderId},
      );
      return false;
    }
  }
}
