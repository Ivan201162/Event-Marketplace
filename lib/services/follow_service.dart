import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Сервис для работы с подписками
class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Подписаться на пользователя
  Future<void> followUser(String targetUserId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');
      if (currentUserId == targetUserId) {
        throw Exception('Cannot follow yourself');
      }

      final batch = _firestore.batch();

      // Добавляем в подписки текущего пользователя
      final followingRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);
      batch.set(followingRef, {
        'userId': targetUserId,
        'followedAt': Timestamp.now(),
      });

      // Добавляем в подписчики целевого пользователя
      final followersRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);
      batch.set(followersRef, {
        'userId': currentUserId,
        'followedAt': Timestamp.now(),
      });

      // Обновляем счетчики
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {
        'followingCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });

      final targetUserRef = _firestore.collection('users').doc(targetUserId);
      batch.update(targetUserRef, {
        'followersCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error following user: $e');
      rethrow;
    }
  }

  /// Отписаться от пользователя
  Future<void> unfollowUser(String targetUserId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');
      if (currentUserId == targetUserId) {
        throw Exception('Cannot unfollow yourself');
      }

      final batch = _firestore.batch();

      // Удаляем из подписок текущего пользователя
      final followingRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);
      batch.delete(followingRef);

      // Удаляем из подписчиков целевого пользователя
      final followersRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);
      batch.delete(followersRef);

      // Обновляем счетчики
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {
        'followingCount': FieldValue.increment(-1),
        'updatedAt': Timestamp.now(),
      });

      final targetUserRef = _firestore.collection('users').doc(targetUserId);
      batch.update(targetUserRef, {
        'followersCount': FieldValue.increment(-1),
        'updatedAt': Timestamp.now(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      rethrow;
    }
  }

  /// Проверить, подписан ли пользователь
  Future<bool> isFollowing(String targetUserId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;
      if (currentUserId == targetUserId) return false;

      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      return false;
    }
  }

  /// Получить подписчиков пользователя
  Stream<List<FollowUser>> getFollowers(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .orderBy('followedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final followers = <FollowUser>[];
      for (final doc in snapshot.docs) {
        final followerId = doc.data()['userId'] as String;
        final userDoc =
            await _firestore.collection('users').doc(followerId).get();
        if (userDoc.exists) {
          followers.add(FollowUser.fromFirestore(userDoc));
        }
      }
      return followers;
    });
  }

  /// Получить подписки пользователя
  Stream<List<FollowUser>> getFollowing(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .orderBy('followedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final following = <FollowUser>[];
      for (final doc in snapshot.docs) {
        final followingId = doc.data()['userId'] as String;
        final userDoc =
            await _firestore.collection('users').doc(followingId).get();
        if (userDoc.exists) {
          following.add(FollowUser.fromFirestore(userDoc));
        }
      }
      return following;
    });
  }

  /// Получить количество подписчиков
  Stream<int> getFollowersCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Получить количество подписок
  Stream<int> getFollowingCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Получить рекомендуемых пользователей для подписки
  Future<List<FollowUser>> getRecommendedUsers(String userId,
      {int limit = 10,}) async {
    try {
      // Получаем пользователей, на которых подписан текущий пользователь
      final followingSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .get();

      final followingIds = followingSnapshot.docs.map((doc) => doc.id).toList();
      followingIds.add(userId); // Исключаем себя

      // Получаем пользователей с наибольшим количеством подписчиков
      final usersSnapshot = await _firestore
          .collection('users')
          .where('followersCount', isGreaterThan: 0)
          .orderBy('followersCount', descending: true)
          .limit(limit * 2) // Берем больше, чтобы отфильтровать
          .get();

      final recommendedUsers = <FollowUser>[];
      for (final doc in usersSnapshot.docs) {
        if (!followingIds.contains(doc.id)) {
          recommendedUsers.add(FollowUser.fromFirestore(doc));
          if (recommendedUsers.length >= limit) break;
        }
      }

      return recommendedUsers;
    } catch (e) {
      debugPrint('Error getting recommended users: $e');
      return [];
    }
  }

  /// Поиск пользователей для подписки
  Future<List<FollowUser>> searchUsers(String query, {int limit = 20}) async {
    try {
      if (query.isEmpty) return [];

      final snapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(limit)
          .get();

      return snapshot.docs.map(FollowUser.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }
}

/// Модель пользователя для подписок
class FollowUser {

  const FollowUser({
    required this.id,
    required this.name,
    required this.followersCount, required this.followingCount, required this.isVerified, required this.isProAccount, this.avatarUrl,
    this.bio,
    this.lastActiveAt,
  });

  /// Создать пользователя из Firestore документа
  factory FollowUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return FollowUser(
      id: doc.id,
      name: data['name'] ?? data['displayName'] ?? 'Пользователь',
      avatarUrl: data['avatarUrl'] ?? data['photoURL'],
      bio: data['bio'] ?? data['description'],
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      isProAccount: data['isProAccount'] ?? false,
      lastActiveAt: data['lastActiveAt'] != null
          ? (data['lastActiveAt'] as Timestamp).toDate()
          : null,
    );
  }
  final String id;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final bool isVerified;
  final bool isProAccount;
  final DateTime? lastActiveAt;

  /// Конвертировать пользователя в Firestore документ
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'isVerified': isVerified,
      'isProAccount': isProAccount,
      'lastActiveAt':
          lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
    };
  }

  @override
  String toString() {
    return 'FollowUser(id: $id, name: $name, followersCount: $followersCount)';
  }
}
