import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';
import '../models/booking.dart';

/// Сервис для работы с отзывами
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать отзыв
  Future<String> createReview(Review review) async {
    try {
      // Проверяем, что пользователь действительно участвовал в мероприятии
      final bookingSnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: review.userId)
          .where('eventId', isEqualTo: review.eventId)
          .where('status', whereIn: ['confirmed', 'completed'])
          .get();

      if (bookingSnapshot.docs.isEmpty) {
        throw Exception('Вы не можете оставить отзыв, так как не участвовали в этом мероприятии');
      }

      // Проверяем, не оставлял ли пользователь уже отзыв
      final existingReview = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: review.userId)
          .where('eventId', isEqualTo: review.eventId)
          .get();

      if (existingReview.docs.isNotEmpty) {
        throw Exception('Вы уже оставили отзыв на это мероприятие');
      }

      // Создаем отзыв
      final docRef = await _firestore.collection('reviews').add(review.toMap());
      
      // Обновляем средний рейтинг мероприятия
      await _updateEventRating(review.eventId);

      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания отзыва: $e');
    }
  }

  /// Получить отзывы для события
  Stream<List<Review>> getEventReviews(String eventId) {
    return _firestore
        .collection('reviews')
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromDocument(doc))
            .toList());
  }

  /// Получить отзывы пользователя
  Stream<List<Review>> getUserReviews(String userId) {
    return _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromDocument(doc))
            .toList());
  }

  /// Получить отзыв по ID
  Future<Review?> getReviewById(String reviewId) async {
    try {
      final doc = await _firestore.collection('reviews').doc(reviewId).get();
      if (doc.exists) {
        return Review.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения отзыва: $e');
    }
  }

  /// Обновить отзыв
  Future<void> updateReview(String reviewId, Review review) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update(review.toMap());
      
      // Обновляем средний рейтинг мероприятия
      await _updateEventRating(review.eventId);
    } catch (e) {
      throw Exception('Ошибка обновления отзыва: $e');
    }
  }

  /// Удалить отзыв
  Future<void> deleteReview(String reviewId) async {
    try {
      final review = await getReviewById(reviewId);
      if (review == null) {
        throw Exception('Отзыв не найден');
      }

      await _firestore.collection('reviews').doc(reviewId).delete();
      
      // Обновляем средний рейтинг мероприятия
      await _updateEventRating(review.eventId);
    } catch (e) {
      throw Exception('Ошибка удаления отзыва: $e');
    }
  }

  /// Получить статистику отзывов для события
  Future<Map<String, dynamic>> getEventReviewStats(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('eventId', isEqualTo: eventId)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'totalReviews': 0,
          'averageRating': 0.0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      int totalReviews = 0;
      double totalRating = 0.0;
      Map<int, int> ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (final doc in snapshot.docs) {
        final review = Review.fromDocument(doc);
        totalReviews++;
        totalRating += review.rating;
        ratingDistribution[review.rating] = (ratingDistribution[review.rating] ?? 0) + 1;
      }

      return {
        'totalReviews': totalReviews,
        'averageRating': totalRating / totalReviews,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики отзывов: $e');
    }
  }

  /// Проверить, может ли пользователь оставить отзыв
  Future<bool> canUserReview(String userId, String eventId) async {
    try {
      // Проверяем, участвовал ли пользователь в мероприятии
      final bookingSnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .where('status', whereIn: ['confirmed', 'completed'])
          .get();

      if (bookingSnapshot.docs.isEmpty) {
        return false;
      }

      // Проверяем, не оставлял ли уже отзыв
      final reviewSnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .get();

      return reviewSnapshot.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Обновить средний рейтинг мероприятия
  Future<void> _updateEventRating(String eventId) async {
    try {
      final stats = await getEventReviewStats(eventId);
      
      await _firestore.collection('events').doc(eventId).update({
        'averageRating': stats['averageRating'],
        'totalReviews': stats['totalReviews'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Логируем ошибку, но не прерываем выполнение
      print('Ошибка обновления рейтинга мероприятия: $e');
    }
  }

  /// Получить популярные события по рейтингу
  Stream<List<Map<String, dynamic>>> getTopRatedEvents({int limit = 10}) {
    return _firestore
        .collection('events')
        .where('averageRating', isGreaterThan: 0)
        .orderBy('averageRating', descending: true)
        .orderBy('totalReviews', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'title': doc.data()['title'],
                  'averageRating': doc.data()['averageRating'],
                  'totalReviews': doc.data()['totalReviews'],
                })
            .toList());
  }
}