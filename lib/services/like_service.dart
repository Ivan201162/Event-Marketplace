import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Сервис для работы с лайками
class LikeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Лайкнуть/снять лайк с поста/рилса/идеи
  Future<bool> toggleLike({
    required String contentType, // 'posts', 'reels', 'ideas'
    required String contentId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final likeRef = _firestore
          .collection('likes')
          .doc(userId)
          .collection(contentType)
          .doc(contentId);

      final likeDoc = await likeRef.get();
      final batch = _firestore.batch();

      if (likeDoc.exists) {
        // Убираем лайк
        batch.delete(likeRef);
        batch.update(
          _firestore.collection(contentType).doc(contentId),
          {'likesCount': FieldValue.increment(-1)},
        );
      } else {
        // Добавляем лайк
        batch.set(likeRef, {
          'contentId': contentId,
          'contentType': contentType,
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        batch.update(
          _firestore.collection(contentType).doc(contentId),
          {'likesCount': FieldValue.increment(1)},
        );
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error toggling like: $e');
      return false;
    }
  }

  /// Проверить, лайкнул ли пользователь
  Future<bool> isLiked({
    required String contentType,
    required String contentId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final likeDoc = await _firestore
          .collection('likes')
          .doc(userId)
          .collection(contentType)
          .doc(contentId)
          .get();

      return likeDoc.exists;
    } catch (e) {
      debugPrint('Error checking like: $e');
      return false;
    }
  }

  /// Stream статуса лайка
  Stream<bool> isLikedStream({
    required String contentType,
    required String contentId,
  }) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(false);

    return _firestore
        .collection('likes')
        .doc(userId)
        .collection(contentType)
        .doc(contentId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Получить количество лайков
  Stream<int> getLikesCount({
    required String contentType,
    required String contentId,
  }) {
    return _firestore
        .collection(contentType)
        .doc(contentId)
        .snapshots()
        .map((doc) => (doc.data()?['likesCount'] as num?)?.toInt() ?? 0);
  }
}

