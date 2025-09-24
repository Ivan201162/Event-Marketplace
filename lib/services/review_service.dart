import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';
import '../models/booking.dart';
import 'fcm_service.dart';

/// Сервис для работы с отзывами
class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FCMService _fcmService = FCMService();

  /// Создает новый отзыв
  Future<String> createReview({
    required String bookingId,
    required String specialistId,
    required String customerId,
    required double rating,
    required String comment,
    List<String> tags = const [],
  }) async {
    try {
      // Проверяем, что заказчик может оставить отзыв
      await _validateReviewPermission(bookingId, customerId);

      final reviewRef = _firestore.collection('reviews').doc();
      
      final review = Review(
        id: reviewRef.id,
        bookingId: bookingId,
        specialistId: specialistId,
        customerId: customerId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
        tags: tags,
      );

      await reviewRef.set(review.toMap());

      // Обновляем аналитику специалиста
      await _updateSpecialistRating(specialistId);

      // Отправляем уведомление специалисту
      await _sendReviewNotification(specialistId, rating, comment);

      return reviewRef.id;
    } catch (e) {
      throw Exception('Ошибка создания отзыва: $e');
    }
  }

  /// Получает отзывы специалиста
  Stream<List<Review>> getSpecialistReviews(String specialistId) {
    return _firestore
        .collection('reviews')
        .where('specialistId', isEqualTo: specialistId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Review.fromDocument(doc)).toList());
  }

  /// Получает отзывы с пагинацией
  Future<List<Review>> getSpecialistReviewsPaginated(
    String specialistId, {
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Review.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Ошибка получения отзывов: $e');
    }
  }

  /// Получает средний рейтинг специалиста
  Future<double> getSpecialistAverageRating(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      double totalRating = 0.0;
      for (final doc in snapshot.docs) {
        final review = Review.fromDocument(doc);
        totalRating += review.rating;
      }

      return totalRating / snapshot.docs.length;
    } catch (e) {
      throw Exception('Ошибка получения рейтинга: $e');
    }
  }

  /// Получает статистику рейтинга (количество по звездам)
  Future<Map<int, int>> getRatingDistribution(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (final doc in snapshot.docs) {
        final review = Review.fromDocument(doc);
        final stars = review.rating.round();
        distribution[stars] = (distribution[stars] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      throw Exception('Ошибка получения распределения рейтинга: $e');
    }
  }

  /// Добавляет ответ специалиста на отзыв
  Future<void> addReplyToReview(String reviewId, String reply) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'reply': reply,
        'repliedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка добавления ответа: $e');
    }
  }

  /// Отмечает отзыв как полезный
  Future<void> markReviewHelpful(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'isHelpful': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Ошибка отметки полезности: $e');
    }
  }

  /// Жалоба на отзыв
  Future<void> reportReview(String reviewId, String reason) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'isReported': true,
      });

      // Создаем запись о жалобе
      await _firestore.collection('review_reports').add({
        'reviewId': reviewId,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка отправки жалобы: $e');
    }
  }

  /// Получает отзыв по ID бронирования
  Future<Review?> getReviewByBookingId(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return Review.fromDocument(snapshot.docs.first);
    } catch (e) {
      throw Exception('Ошибка получения отзыва: $e');
    }
  }

  /// Проверяет, может ли пользователь оставить отзыв
  Future<bool> canUserLeaveReview(String bookingId, String userId) async {
    try {
      // Проверяем статус бронирования
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) return false;

      final booking = Booking.fromDocument(bookingDoc);
      
      // Только заказчик может оставлять отзывы
      if (booking.customerId != userId) return false;
      
      // Только после завершения события
      if (booking.status != 'completed') return false;
      
      // Проверяем, что отзыв еще не оставлен
      final existingReview = await getReviewByBookingId(bookingId);
      return existingReview == null;
    } catch (e) {
      return false;
    }
  }

  /// Проверяет разрешение на создание отзыва
  Future<void> _validateReviewPermission(String bookingId, String customerId) async {
    final canReview = await canUserLeaveReview(bookingId, customerId);
    if (!canReview) {
      throw Exception('Нет разрешения на создание отзыва');
    }
  }

  /// Обновляет рейтинг специалиста
  Future<void> _updateSpecialistRating(String specialistId) async {
    try {
      final averageRating = await getSpecialistAverageRating(specialistId);
      final reviewCount = await _getSpecialistReviewCount(specialistId);

      await _firestore.collection('specialists').doc(specialistId).update({
        'averageRating': averageRating,
        'reviewCount': reviewCount,
      });
    } catch (e) {
      print('Ошибка обновления рейтинга специалиста: $e');
    }
  }

  /// Получает количество отзывов специалиста
  Future<int> _getSpecialistReviewCount(String specialistId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('specialistId', isEqualTo: specialistId)
        .get();
    return snapshot.docs.length;
  }

  /// Отправляет уведомление о новом отзыве
  Future<void> _sendReviewNotification(String specialistId, double rating, String comment) async {
    try {
      await _fcmService.sendReviewNotification(
        specialistId: specialistId,
        rating: rating,
        comment: comment,
      );
    } catch (e) {
      print('Ошибка отправки уведомления о отзыве: $e');
    }
  }
}