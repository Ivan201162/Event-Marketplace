import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';
import 'notification_service.dart';
import 'badge_service.dart';

/// Сервис для работы с отзывами
class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final BadgeService _badgeService = BadgeService();

  /// Создать отзыв
  Future<String> createReview(Review review) async {
    final batch = _db.batch();
    
    // Добавить отзыв
    final reviewRef = _db.collection('reviews').doc();
    batch.set(reviewRef, review.toMap());
    
    // Обновить статистику специалиста
    final specialistRef = _db.collection('specialists').doc(review.specialistId);
    batch.update(specialistRef, {
      'reviewCount': FieldValue.increment(1),
      'rating': FieldValue.increment(review.rating),
    });
    
    await batch.commit();
    
    // Отправить уведомление специалисту
    try {
      // Получаем данные заказчика для уведомления
      final customerDoc = await _db.collection('users').doc(review.customerId).get();
      final customerName = customerDoc.data()?['name'] as String? ?? 'Клиент';
      
      await _notificationService.sendReviewNotification(
        specialistId: review.specialistId,
        customerName: customerName,
        rating: review.rating,
        reviewText: review.comment,
      );
    } catch (e) {
      // Логируем ошибку, но не прерываем создание отзыва
      print('Error sending review notification: $e');
    }
    
    // Проверяем бейджи
    try {
      await _badgeService.checkReviewBadges(
        review.customerId,
        review.specialistId,
        review.rating,
      );
    } catch (e) {
      // Логируем ошибку, но не прерываем создание отзыва
      print('Error checking review badges: $e');
    }
    
    return reviewRef.id;
  }

  /// Обновить отзыв
  Future<void> updateReview(String reviewId, Review review) async {
    final batch = _db.batch();
    
    // Получить старый отзыв для обновления статистики
    final oldReviewDoc = await _db.collection('reviews').doc(reviewId).get();
    if (oldReviewDoc.exists) {
      final oldReview = Review.fromDocument(oldReviewDoc);
      
      // Обновить статистику специалиста
      final specialistRef = _db.collection('specialists').doc(review.specialistId);
      batch.update(specialistRef, {
        'rating': FieldValue.increment(review.rating - oldReview.rating),
      });
    }
    
    // Обновить отзыв
    final reviewRef = _db.collection('reviews').doc(reviewId);
    batch.update(reviewRef, review.toMap());
    
    await batch.commit();
  }

  /// Удалить отзыв
  Future<void> deleteReview(String reviewId) async {
    final batch = _db.batch();
    
    // Получить отзыв для обновления статистики
    final reviewDoc = await _db.collection('reviews').doc(reviewId).get();
    if (reviewDoc.exists) {
      final review = Review.fromDocument(reviewDoc);
      
      // Обновить статистику специалиста
      final specialistRef = _db.collection('specialists').doc(review.specialistId);
      batch.update(specialistRef, {
        'reviewCount': FieldValue.increment(-1),
        'rating': FieldValue.increment(-review.rating),
      });
    }
    
    // Удалить отзыв
    final reviewRef = _db.collection('reviews').doc(reviewId);
    batch.delete(reviewRef);
    
    await batch.commit();
  }

  /// Получить отзывы по специалисту
  Future<List<Review>> getReviewsBySpecialist(String specialistId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _db
        .collection('reviews')
        .where('specialistId', isEqualTo: specialistId)
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final querySnapshot = await query.get();
    return querySnapshot.docs.map((doc) => Review.fromDocument(doc)).toList();
  }

  /// Получить отзывы по заказчику
  Future<List<Review>> getReviewsByCustomer(String customerId) async {
    final querySnapshot = await _db
        .collection('reviews')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs.map((doc) => Review.fromDocument(doc)).toList();
  }

  /// Получить отзыв по бронированию
  Future<Review?> getReviewByBooking(String bookingId) async {
    final querySnapshot = await _db
        .collection('reviews')
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    return Review.fromDocument(querySnapshot.docs.first);
  }

  /// Получить статистику отзывов специалиста
  Future<ReviewStats> getReviewStats(String specialistId) async {
    final querySnapshot = await _db
        .collection('reviews')
        .where('specialistId', isEqualTo: specialistId)
        .where('isPublic', isEqualTo: true)
        .get();

    final reviews = querySnapshot.docs.map((doc) => Review.fromDocument(doc)).toList();
    return ReviewStats.fromReviews(reviews);
  }

  /// Проверить, может ли пользователь оставить отзыв
  Future<bool> canUserReview(String customerId, String specialistId, String bookingId) async {
    // Проверить, что бронирование завершено
    final bookingDoc = await _db.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) return false;
    
    final bookingData = bookingDoc.data() as Map<String, dynamic>;
    if (bookingData['customerId'] != customerId) return false;
    if (bookingData['specialistId'] != specialistId) return false;
    if (bookingData['status'] != 'completed') return false;
    
    // Проверить, что отзыв еще не оставлен
    final existingReview = await getReviewByBooking(bookingId);
    return existingReview == null;
  }

  /// Получить последние отзывы
  Future<List<Review>> getRecentReviews({int limit = 10}) async {
    final querySnapshot = await _db
        .collection('reviews')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return querySnapshot.docs.map((doc) => Review.fromDocument(doc)).toList();
  }

  /// Получить лучшие отзывы (5 звезд)
  Future<List<Review>> getTopReviews({int limit = 10}) async {
    final querySnapshot = await _db
        .collection('reviews')
        .where('isPublic', isEqualTo: true)
        .where('rating', isEqualTo: 5)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return querySnapshot.docs.map((doc) => Review.fromDocument(doc)).toList();
  }

  /// Поиск отзывов по тексту
  Future<List<Review>> searchReviews(String searchText) async {
    // Firestore не поддерживает полнотекстовый поиск,
    // поэтому используем простой поиск по заголовку и комментарию
    final querySnapshot = await _db
        .collection('reviews')
        .where('isPublic', isEqualTo: true)
        .get();

    final reviews = querySnapshot.docs.map((doc) => Review.fromDocument(doc)).toList();
    
    // Фильтруем на клиенте
    final searchLower = searchText.toLowerCase();
    return reviews.where((review) {
      return (review.title?.toLowerCase().contains(searchLower) ?? false) ||
             (review.comment?.toLowerCase().contains(searchLower) ?? false);
    }).toList();
  }

  /// Подтвердить отзыв (для администраторов)
  Future<void> verifyReview(String reviewId, bool isVerified) async {
    await _db.collection('reviews').doc(reviewId).update({
      'isVerified': isVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Сделать отзыв публичным/приватным
  Future<void> setReviewVisibility(String reviewId, bool isPublic) async {
    await _db.collection('reviews').doc(reviewId).update({
      'isPublic': isPublic,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Получить отзывы для модерации
  Future<List<Review>> getReviewsForModeration() async {
    final querySnapshot = await _db
        .collection('reviews')
        .where('isVerified', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs.map((doc) => Review.fromDocument(doc)).toList();
  }

  /// Обновить статистику специалиста
  Future<void> updateSpecialistStats(String specialistId) async {
    final reviews = await getReviewsBySpecialist(specialistId, limit: 1000);
    final stats = ReviewStats.fromReviews(reviews);
    
    await _db.collection('specialists').doc(specialistId).update({
      'rating': stats.averageRating,
      'reviewCount': stats.totalReviews,
      'reviewStats': stats.toMap(),
    });
  }
}