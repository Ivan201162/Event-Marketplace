import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Сервис для работы с рейтингами и отзывами
class RatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Создание отзыва
  Future<bool> createReview({
    required String specialistId,
    required double rating,
    required String comment,
    List<String>? tags,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final reviewData = {
        'specialistId': specialistId,
        'userId': user.uid,
        'rating': rating,
        'comment': comment,
        'tags': tags ?? [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('reviews').add(reviewData);

      // Обновление рейтинга специалиста
      await _updateSpecialistRating(specialistId);

      return true;
    } catch (e) {
      print('Ошибка создания отзыва: $e');
      return false;
    }
  }

  /// Получение отзывов специалиста
  Future<List<Map<String, dynamic>>> getSpecialistReviews(
      String specialistId,) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Ошибка получения отзывов: $e');
      return [];
    }
  }

  /// Получение рейтинга специалиста
  Future<Map<String, dynamic>> getSpecialistRating(String specialistId) async {
    try {
      final reviews = await getSpecialistReviews(specialistId);

      if (reviews.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
          'ratingDistribution': {},
        };
      }

      double totalRating = 0;
      final ratingDistribution = <int, int>{};

      for (final review in reviews) {
        final rating = review['rating'] as double;
        totalRating += rating;

        final ratingInt = rating.round();
        ratingDistribution[ratingInt] =
            (ratingDistribution[ratingInt] ?? 0) + 1;
      }

      final averageRating = totalRating / reviews.length;

      return {
        'averageRating': averageRating,
        'totalReviews': reviews.length,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      print('Ошибка получения рейтинга: $e');
      return {
        'averageRating': 0.0,
        'totalReviews': 0,
        'ratingDistribution': {},
      };
    }
  }

  /// Обновление рейтинга специалиста
  Future<void> _updateSpecialistRating(String specialistId) async {
    try {
      final rating = await getSpecialistRating(specialistId);

      await _firestore.collection('profiles').doc(specialistId).update({
        'rating': rating['averageRating'],
        'totalReviews': rating['totalReviews'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка обновления рейтинга специалиста: $e');
    }
  }

  /// Проверка, может ли пользователь оставить отзыв
  Future<bool> canUserReview(String specialistId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Проверка, не оставлял ли пользователь уже отзыв
      final existingReview = await _firestore
          .collection('reviews')
          .where('specialistId', isEqualTo: specialistId)
          .where('userId', isEqualTo: user.uid)
          .get();

      return existingReview.docs.isEmpty;
    } catch (e) {
      print('Ошибка проверки возможности оставить отзыв: $e');
      return false;
    }
  }

  /// Получение отзывов пользователя
  Future<List<Map<String, dynamic>>> getUserReviews() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Ошибка получения отзывов пользователя: $e');
      return [];
    }
  }

  /// Удаление отзыва
  Future<bool> deleteReview(String reviewId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final reviewDoc =
          await _firestore.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists) return false;

      final reviewData = reviewDoc.data()!;
      if (reviewData['userId'] != user.uid) return false;

      await _firestore.collection('reviews').doc(reviewId).delete();

      // Обновление рейтинга специалиста
      await _updateSpecialistRating(reviewData['specialistId']);

      return true;
    } catch (e) {
      print('Ошибка удаления отзыва: $e');
      return false;
    }
  }

  /// Получение популярных тегов
  Future<List<String>> getPopularTags() async {
    try {
      final querySnapshot = await _firestore.collection('reviews').get();

      final tagCounts = <String, int>{};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final tags = List<String>.from(data['tags'] ?? []);

        for (final tag in tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      final sortedTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedTags.take(10).map((e) => e.key).toList();
    } catch (e) {
      print('Ошибка получения популярных тегов: $e');
      return [];
    }
  }

  /// Получение статистики рейтингов
  Future<Map<String, dynamic>> getRatingStatistics() async {
    try {
      final querySnapshot = await _firestore.collection('reviews').get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'totalReviews': 0,
          'averageRating': 0.0,
          'ratingDistribution': {},
        };
      }

      double totalRating = 0;
      final ratingDistribution = <int, int>{};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final rating = data['rating'] as double;
        totalRating += rating;

        final ratingInt = rating.round();
        ratingDistribution[ratingInt] =
            (ratingDistribution[ratingInt] ?? 0) + 1;
      }

      final averageRating = totalRating / querySnapshot.docs.length;

      return {
        'totalReviews': querySnapshot.docs.length,
        'averageRating': averageRating,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      print('Ошибка получения статистики рейтингов: $e');
      return {
        'totalReviews': 0,
        'averageRating': 0.0,
        'ratingDistribution': {},
      };
    }
  }
}
