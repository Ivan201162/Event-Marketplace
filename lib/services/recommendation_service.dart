import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Сервис для получения рекомендаций
class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Получить топ-10 рекомендаций по активности (не подписан)
  Future<List<AppUser>> getTopRecommendations({
    int limit = 10,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      // Получаем подписки
      final followingSnapshot = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .get();

      final followingIds = followingSnapshot.docs
          .map((doc) => doc.data()['followingId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      followingIds.add(userId); // Исключаем себя

      // Получаем пользователей с наибольшей активностью
      // Активность = количество постов + рилсов + идей
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'specialist')
          .limit(limit * 3)
          .get();

      final userScores = <String, int>{};
      for (final userDoc in usersSnapshot.docs) {
        if (followingIds.contains(userDoc.id)) continue;

        final userId = userDoc.id;
        int score = 0;

        // Подсчитываем посты
        final postsCount = await _firestore
            .collection('posts')
            .where('authorId', isEqualTo: userId)
            .count()
            .get();
        score += postsCount.count ?? 0;

        // Подсчитываем рилсы
        final reelsCount = await _firestore
            .collection('reels')
            .where('authorId', isEqualTo: userId)
            .count()
          .get();
        score += reelsCount.count ?? 0;

        // Подсчитываем идеи
        final ideasCount = await _firestore
            .collection('ideas')
            .where('authorId', isEqualTo: userId)
            .count()
            .get();
        score += ideasCount.count ?? 0;

        // Добавляем лайки на контент
        final likesCount = await _firestore
            .collectionGroup('likes')
            .where('contentId', isEqualTo: userId)
            .count()
          .get();
        score += (likesCount.count ?? 0) ~/ 10; // Нормализуем

        userScores[userId] = score;
      }

      // Сортируем по активности
      final sortedUserIds = userScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final recommendations = <AppUser>[];
      for (final entry in sortedUserIds.take(limit)) {
        final userDoc = await _firestore
            .collection('users')
            .doc(entry.key)
            .get();
        if (userDoc.exists) {
          try {
            recommendations.add(AppUser.fromFirestore(userDoc));
          } catch (e) {
            debugPrint('Error parsing user ${entry.key}: $e');
          }
        }
      }

      return recommendations;
    } catch (e) {
      debugPrint('Error getting recommendations: $e');
      return [];
    }
  }
}
