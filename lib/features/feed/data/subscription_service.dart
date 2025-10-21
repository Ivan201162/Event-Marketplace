import 'package:cloud_firestore/cloud_firestore.dart';

/// Сервис для управления подписками
class SubscriptionService {
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();
  static final SubscriptionService _instance = SubscriptionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Подписаться на пользователя
  Future<void> followUser(String userId, String targetUserId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Добавляем подписку в профиль пользователя
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final following = List<String>.from((userData['following'] as List<dynamic>?) ?? []);

          if (!following.contains(targetUserId)) {
            following.add(targetUserId);
            transaction.update(userRef, {'following': following});
          }
        }

        // Добавляем подписчика в профиль целевого пользователя
        final targetRef = _firestore.collection('users').doc(targetUserId);
        final targetDoc = await transaction.get(targetRef);

        if (targetDoc.exists) {
          final targetData = targetDoc.data()!;
          final followers = List<String>.from((targetData['followers'] as List<dynamic>?) ?? []);

          if (!followers.contains(userId)) {
            followers.add(userId);
            transaction.update(targetRef, {'followers': followers});
          }
        }
      });
    } catch (e) {
      throw Exception('Ошибка при подписке: $e');
    }
  }

  /// Отписаться от пользователя
  Future<void> unfollowUser(String userId, String targetUserId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Убираем подписку из профиля пользователя
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final following = List<String>.from((userData['following'] as List<dynamic>?) ?? []);
          following.remove(targetUserId);
          transaction.update(userRef, {'following': following});
        }

        // Убираем подписчика из профиля целевого пользователя
        final targetRef = _firestore.collection('users').doc(targetUserId);
        final targetDoc = await transaction.get(targetRef);

        if (targetDoc.exists) {
          final targetData = targetDoc.data()!;
          final followers = List<String>.from((targetData['followers'] as List<dynamic>?) ?? []);
          followers.remove(userId);
          transaction.update(targetRef, {'followers': followers});
        }
      });
    } catch (e) {
      throw Exception('Ошибка при отписке: $e');
    }
  }

  /// Получить список подписок пользователя
  Future<List<String>> getUserFollowing(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return List<String>.from((userData['following'] as List<dynamic>?) ?? []);
      }

      return [];
    } catch (e) {
      throw Exception('Ошибка при получении подписок: $e');
    }
  }

  /// Получить список подписчиков пользователя
  Future<List<String>> getUserFollowers(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return List<String>.from((userData['followers'] as List<dynamic>?) ?? []);
      }

      return [];
    } catch (e) {
      throw Exception('Ошибка при получении подписчиков: $e');
    }
  }

  /// Проверить, подписан ли пользователь на другого
  Future<bool> isFollowing(String userId, String targetUserId) async {
    try {
      final following = await getUserFollowing(userId);
      return following.contains(targetUserId);
    } catch (e) {
      return false;
    }
  }

  /// Получить поток подписок пользователя
  Stream<List<String>> getUserFollowingStream(String userId) =>
      _firestore.collection('users').doc(userId).snapshots().map((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data()!;
          return List<String>.from((data['following'] as List<dynamic>?) ?? []);
        }
        return [];
      });

  /// Получить поток подписчиков пользователя
  Stream<List<String>> getUserFollowersStream(String userId) =>
      _firestore.collection('users').doc(userId).snapshots().map((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data()!;
          return List<String>.from((data['followers'] as List<dynamic>?) ?? []);
        }
        return [];
      });

  /// Получить статистику подписок
  Future<SubscriptionStats> getSubscriptionStats(String userId) async {
    try {
      final following = await getUserFollowing(userId);
      final followers = await getUserFollowers(userId);

      return SubscriptionStats(followingCount: following.length, followersCount: followers.length);
    } catch (e) {
      throw Exception('Ошибка при получении статистики: $e');
    }
  }
}

/// Статистика подписок
class SubscriptionStats {
  const SubscriptionStats({required this.followingCount, required this.followersCount});

  final int followingCount;
  final int followersCount;
}
