import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/review.dart';
import 'notification_service.dart';

/// Сервис для работы с отзывами
class ReviewService {
  factory ReviewService() => _instance;
  ReviewService._internal();
  static final ReviewService _instance = ReviewService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Создать отзыв (перегруженный метод для совместимости)
  Future<String> createReview({
    String? targetId,
    String? type,
    String? title,
    String? content,
    List<String>? tags,
    required String specialistId,
    required String customerId,
    required String customerName,
    required int rating,
    required String comment,
    String? bookingId,
    String? eventTitle,
    String? specialistName,
    String? customerAvatar,
    List<String> serviceTags = const [],
  }) async {
    try {
      // Если есть bookingId, проверяем статус бронирования
      if (bookingId != null) {
        final bookingDoc =
            await _firestore.collection('bookings').doc(bookingId).get();
        if (!bookingDoc.exists) {
          throw Exception('Бронирование не найдено');
        }

        final booking = Booking.fromDocument(bookingDoc);
        if (booking.status != BookingStatus.completed) {
          throw Exception(
            'Отзыв можно оставить только после завершения заказа',
          );
        }

        // Проверяем, что пользователь не оставлял отзыв для этого бронирования
        final existingReview = await _firestore
            .collection('reviews')
            .where('bookingId', isEqualTo: bookingId)
            .where('customerId', isEqualTo: customerId)
            .get();

        if (existingReview.docs.isNotEmpty) {
          throw Exception('Вы уже оставили отзыв для этого заказа');
        }

        // Защита от накруток: проверяем, что пользователь действительно был заказчиком
        if (booking.customerId != customerId) {
          throw Exception('Отзыв может оставить только заказчик');
        }

        // Защита от накруток: проверяем, что прошло достаточно времени с завершения заказа
        final now = DateTime.now();
        final endDate = booking.endDate ?? booking.startDate;
        if (endDate != null) {
          final timeSinceCompletion = now.difference(endDate);
          if (timeSinceCompletion.inHours < 1) {
            throw Exception(
              'Отзыв можно оставить не ранее чем через час после завершения заказа',
            );
          }
        }
      }

      // Защита от накруток: проверяем количество отзывов от пользователя за последние 24 часа
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      final recentReviews = await _firestore
          .collection('reviews')
          .where('customerId', isEqualTo: customerId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(yesterday))
          .get();

      if (recentReviews.docs.length >= 10) {
        throw Exception('Превышен лимит отзывов. Попробуйте позже.');
      }

      // Создаем отзыв
      final reviewData = {
        'bookingId': bookingId,
        'customerId': customerId,
        'customerName': customerName,
        'customerAvatar': customerAvatar,
        'specialistId': specialistId,
        'specialistName': specialistName,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isEdited': false,
        'isDeleted': false,
        'serviceTags': serviceTags,
        'eventTitle': eventTitle,
        'metadata': {},
      };

      final docRef = await _firestore.collection('reviews').add(reviewData);

      // Обновляем статистику специалиста
      await _updateSpecialistRating(specialistId);

      // Отправляем уведомление специалисту о новом отзыве
      // await _notificationService.sendNewReviewNotification(
      //   specialistId: specialistId,
      //   customerName: customerName,
      //   rating: rating,
      //   reviewId: docRef.id,
      // );

      debugPrint('Review created: ${docRef.id}');
      return docRef.id;
    } on Exception catch (e) {
      debugPrint('Error creating review: $e');
      throw Exception('Ошибка создания отзыва: $e');
    }
  }

  /// Получить отзывы специалиста
  Future<List<Review>> getSpecialistReviews(
    String specialistId, {
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map(Review.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Error getting specialist reviews: $e');
      throw Exception('Ошибка получения отзывов: $e');
    }
  }

  /// Получить статистику отзывов специалиста
  Future<ReviewStats> getSpecialistReviewStats(String specialistId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .where('isDeleted', isEqualTo: false)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        return ReviewStats(
          specialistId: specialistId,
          averageRating: 0,
          totalReviews: 0,
          ratingDistribution: {},
          lastUpdated: DateTime.now(),
        );
      }

      final reviews = reviewsSnapshot.docs.map(Review.fromDocument).toList();

      // Рассчитываем средний рейтинг
      final totalRating = reviews.fold<double>(
        0,
        (sum, review) => sum + review.rating.toDouble(),
      );
      final averageRating = totalRating / reviews.length;

      // Рассчитываем распределение рейтингов
      final ratingDistribution = <String, int>{};
      for (var i = 1; i <= 5; i++) {
        ratingDistribution[i.toString()] =
            reviews.where((r) => r.rating == i).length;
      }

      return ReviewStats(
        specialistId: specialistId,
        averageRating: averageRating,
        totalReviews: reviews.length,
        ratingDistribution: ratingDistribution,
        lastUpdated: DateTime.now(),
      );
    } on Exception catch (e) {
      debugPrint('Error getting review stats: $e');
      throw Exception('Ошибка получения статистики отзывов: $e');
    }
  }

  /// Получить отзыв по ID бронирования
  Future<Review?> getReviewByBookingId(String bookingId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('bookingId', isEqualTo: bookingId)
          .where('customerId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return Review.fromDocument(querySnapshot.docs.first);
    } on Exception catch (e) {
      debugPrint('Error getting review by booking ID: $e');
      throw Exception('Ошибка получения отзыва: $e');
    }
  }

  /// Обновить отзыв
  Future<void> updateReview(
    String reviewId, {
    int? rating,
    String? comment,
  }) async {
    try {
      // Проверяем, что отзыв существует и не удален
      final reviewDoc =
          await _firestore.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists) {
        throw Exception('Отзыв не найден');
      }

      final review = Review.fromDocument(reviewDoc);
      if (review.isDeleted) {
        throw Exception('Отзыв был удален');
      }

      // Проверяем, что прошло не более 24 часов с момента создания
      final now = DateTime.now();
      final timeSinceCreation = now.difference(review.createdAt);
      if (timeSinceCreation.inHours > 24) {
        throw Exception('Отзыв можно редактировать только в течение 24 часов');
      }

      final updateData = <String, dynamic>{
        'editedAt': Timestamp.fromDate(now),
        'isEdited': true,
      };

      if (rating != null) updateData['rating'] = rating;
      if (comment != null) updateData['comment'] = comment;

      await _firestore.collection('reviews').doc(reviewId).update(updateData);

      // Обновляем статистику специалиста
      await _updateSpecialistRating(review.specialistId);

      debugPrint('Review updated: $reviewId');
    } on Exception catch (e) {
      debugPrint('Error updating review: $e');
      throw Exception('Ошибка обновления отзыва: $e');
    }
  }

  /// Удалить отзыв
  Future<void> deleteReview(String reviewId) async {
    try {
      // Получаем отзыв перед удалением
      final reviewDoc =
          await _firestore.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists) {
        throw Exception('Отзыв не найден');
      }

      final review = Review.fromDocument(reviewDoc);
      if (review.isDeleted) {
        throw Exception('Отзыв уже удален');
      }

      // Проверяем, что прошло не более 24 часов с момента создания
      final now = DateTime.now();
      final timeSinceCreation = now.difference(review.createdAt);
      if (timeSinceCreation.inHours > 24) {
        throw Exception('Отзыв можно удалить только в течение 24 часов');
      }

      // Помечаем отзыв как удаленный (мягкое удаление)
      await _firestore.collection('reviews').doc(reviewId).update({
        'isDeleted': true,
        'deletedAt': Timestamp.fromDate(now),
      });

      // Обновляем статистику специалиста
      await _updateSpecialistRating(review.specialistId);

      debugPrint('Review deleted: $reviewId');
    } on Exception catch (e) {
      debugPrint('Error deleting review: $e');
      throw Exception('Ошибка удаления отзыва: $e');
    }
  }

  /// Добавить ответ специалиста на отзыв
  Future<void> addResponseToReview(String reviewId, String response) async {
    try {
      // Проверяем, что отзыв существует и не удален
      final reviewDoc =
          await _firestore.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists) {
        throw Exception('Отзыв не найден');
      }

      final review = Review.fromDocument(reviewDoc);
      if (review.isDeleted) {
        throw Exception('Отзыв был удален');
      }

      await _firestore.collection('reviews').doc(reviewId).update({
        'response': response,
        'responseAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('Response added to review: $reviewId');
    } on Exception catch (e) {
      debugPrint('Error adding response to review: $e');
      throw Exception('Ошибка добавления ответа: $e');
    }
  }

  /// Обновить рейтинг специалиста в профиле
  Future<void> _updateSpecialistRating(String specialistId) async {
    try {
      final stats = await getSpecialistReviewStats(specialistId);

      await _firestore.collection('specialists').doc(specialistId).update({
        'rating': stats.averageRating,
        'reviewCount': stats.totalReviews,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('Specialist rating updated: $specialistId');
    } on Exception catch (e) {
      debugPrint('Error updating specialist rating: $e');
      // Не выбрасываем исключение, так как это не критично
    }
  }

  /// Получить отзывы пользователя
  Future<List<Review>> getUserReviews(String userId, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('customerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map(Review.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Error getting user reviews: $e');
      throw Exception('Ошибка получения отзывов пользователя: $e');
    }
  }

  /// Проверить, может ли пользователь оставить отзыв для бронирования
  Future<bool> canUserReviewBooking(String bookingId, String userId) async {
    try {
      // Проверяем существование бронирования
      final bookingDoc =
          await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) {
        return false;
      }

      final booking = Booking.fromDocument(bookingDoc);

      // Проверяем, что бронирование завершено
      if (booking.status != BookingStatus.completed) {
        return false;
      }

      // Проверяем, что пользователь - заказчик
      if (booking.customerId != userId) {
        return false;
      }

      // Проверяем, что отзыв еще не оставлен
      final existingReview = await _firestore
          .collection('reviews')
          .where('bookingId', isEqualTo: bookingId)
          .where('customerId', isEqualTo: userId)
          .get();

      return existingReview.docs.isEmpty;
    } on Exception catch (e) {
      debugPrint('Error checking if user can review: $e');
      return false;
    }
  }
}
