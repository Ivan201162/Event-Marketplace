import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/story.dart';
import 'storage_service.dart';

/// Сервис для работы со сторис
class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Получить активные сторис пользователя
  Stream<List<Story>> getUserStories(String userId) {
    return _firestore
        .collection('stories')
        .where('userId', isEqualTo: userId)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Story.fromFirestore(doc)).toList();
    });
  }

  /// Получить все сторис пользователя (включая истекшие)
  Stream<List<Story>> getAllUserStories(String userId) {
    return _firestore
        .collection('stories')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Story.fromFirestore(doc)).toList();
    });
  }

  /// Получить все активные сторис (для ленты)
  Stream<List<Story>> getAllActiveStories() {
    return _firestore
        .collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Story.fromFirestore(doc)).toList();
    });
  }

  /// Получить сторис специалиста
  Stream<List<Story>> getStoriesBySpecialist(String specialistId) {
    return _firestore
        .collection('stories')
        .where('specialistId', isEqualTo: specialistId)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Story.fromFirestore(doc)).toList();
    });
  }

  /// Выбрать изображение
  Future<File?> pickImage() async {
    // Implementation for image picking
    return null;
  }

  /// Выбрать видео
  Future<File?> pickVideo() async {
    // Implementation for video picking
    return null;
  }

  /// Сделать фото
  Future<File?> takePhoto() async {
    // Implementation for taking photo
    return null;
  }

  /// Записать видео
  Future<File?> recordVideo() async {
    // Implementation for recording video
    return null;
  }

  /// Загрузить изображение сторис
  Future<String> uploadStoryImage(File imageFile) async {
    // Implementation for uploading story image
    return '';
  }

  /// Загрузить видео сторис
  Future<String> uploadStoryVideo(File videoFile) async {
    // Implementation for uploading story video
    return '';
  }

  /// Лайкнуть сторис
  Future<void> likeStory(String storyId, String userId) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'likes': FieldValue.increment(1),
        'reactions': FieldValue.arrayUnion([
          {
            'userId': userId,
            'type': 'like',
            'timestamp': Timestamp.now(),
          }
        ]),
      });
    } catch (e) {
      debugPrint('Error liking story: $e');
      rethrow;
    }
  }

  /// Создать новую сторис
  Future<String> createStory({
    required File? imageFile,
    required String? textContent,
    required StoryPrivacy privacy,
    List<String> mentions = const [],
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      String? content;
      StoryType type = StoryType.text;

      // Загружаем изображение, если есть
      if (imageFile != null) {
        final storageService = StorageService();
        final storyId = _firestore.collection('stories').doc().id;
        content = await storageService.uploadStoryImage(storyId, imageFile);
        type = StoryType.image;
      } else if (textContent != null && textContent.isNotEmpty) {
        content = textContent;
        type = StoryType.text;
      } else {
        throw Exception('Story content is required');
      }

      final storyData = {
        'userId': user.uid,
        'content': content,
        'type': type.value,
        'privacy': privacy.value,
        'mentions': mentions,
        'viewers': [],
        'reactions': [],
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'isHighlighted': false,
        'highlightTitle': null,
        'metadata': {},
      };

      final docRef = await _firestore.collection('stories').add(storyData);

      debugPrint('✅ Story created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating story: $e');
      rethrow;
    }
  }

  /// Отметить сторис как просмотренную
  Future<void> markStoryAsViewed(String storyId, String viewerId) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'viewers': FieldValue.arrayUnion([viewerId]),
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✅ Story marked as viewed: $storyId');
    } catch (e) {
      debugPrint('❌ Error marking story as viewed: $e');
      rethrow;
    }
  }

  /// Добавить реакцию к сторис
  Future<void> addReaction(String storyId, String userId, String emoji) async {
    try {
      final reaction = {
        'userId': userId,
        'emoji': emoji,
        'createdAt': Timestamp.now(),
      };

      await _firestore.collection('stories').doc(storyId).update({
        'reactions': FieldValue.arrayUnion([reaction]),
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✅ Reaction added to story: $storyId');
    } catch (e) {
      debugPrint('❌ Error adding reaction: $e');
      rethrow;
    }
  }

  /// Удалить реакцию с сторис
  Future<void> removeReaction(
      String storyId, String userId, String emoji) async {
    try {
      final reaction = {
        'userId': userId,
        'emoji': emoji,
        'createdAt': Timestamp.now(),
      };

      await _firestore.collection('stories').doc(storyId).update({
        'reactions': FieldValue.arrayRemove([reaction]),
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✅ Reaction removed from story: $storyId');
    } catch (e) {
      debugPrint('❌ Error removing reaction: $e');
      rethrow;
    }
  }

  /// Закрепить сторис (добавить в highlights)
  Future<void> highlightStory(String storyId, String title) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'isHighlighted': true,
        'highlightTitle': title,
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✅ Story highlighted: $storyId');
    } catch (e) {
      debugPrint('❌ Error highlighting story: $e');
      rethrow;
    }
  }

  /// Убрать сторис из highlights
  Future<void> unhighlightStory(String storyId) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'isHighlighted': false,
        'highlightTitle': null,
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✅ Story unhighlighted: $storyId');
    } catch (e) {
      debugPrint('❌ Error unhighlighting story: $e');
      rethrow;
    }
  }

  /// Удалить сторис
  Future<void> deleteStory(String storyId) async {
    try {
      await _firestore.collection('stories').doc(storyId).delete();
      debugPrint('✅ Story deleted: $storyId');
    } catch (e) {
      debugPrint('❌ Error deleting story: $e');
      rethrow;
    }
  }

  /// Получить закрепленные сторис (highlights)
  Stream<List<Story>> getHighlights(String userId) {
    return _firestore
        .collection('stories')
        .where('userId', isEqualTo: userId)
        .where('isHighlighted', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Story.fromFirestore(doc)).toList();
    });
  }

  /// Получить сторис друзей/подписок
  Stream<List<Story>> getFollowingStories(String userId) {
    // Сначала получаем список подписок
    return _firestore
        .collection('following')
        .doc(userId)
        .collection('users')
        .snapshots()
        .asyncMap((followingSnapshot) async {
      final followingIds = followingSnapshot.docs.map((doc) => doc.id).toList();

      if (followingIds.isEmpty) return <Story>[];

      // Получаем активные сторис от подписок
      final storiesSnapshot = await _firestore
          .collection('stories')
          .where('userId', whereIn: followingIds)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      return storiesSnapshot.docs
          .map((doc) => Story.fromFirestore(doc))
          .toList();
    });
  }

  /// Получить статистику сторис
  Future<Map<String, int>> getStoryStats(String userId) async {
    try {
      final storiesSnapshot = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: userId)
          .get();

      int totalViews = 0;
      int totalReactions = 0;
      int activeStories = 0;

      for (final doc in storiesSnapshot.docs) {
        final story = Story.fromFirestore(doc);
        totalViews += story.viewCount;
        totalReactions += story.reactionCount;

        if (!story.isExpired) {
          activeStories++;
        }
      }

      return {
        'totalStories': storiesSnapshot.docs.length,
        'activeStories': activeStories,
        'totalViews': totalViews,
        'totalReactions': totalReactions,
      };
    } catch (e) {
      debugPrint('❌ Error getting story stats: $e');
      return {
        'totalStories': 0,
        'activeStories': 0,
        'totalViews': 0,
        'totalReactions': 0,
      };
    }
  }

  /// Очистить истекшие сторис (вызывается периодически)
  Future<void> cleanupExpiredStories() async {
    try {
      final expiredStories = await _firestore
          .collection('stories')
          .where('expiresAt', isLessThan: Timestamp.now())
          .where('isHighlighted', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in expiredStories.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ Cleaned up ${expiredStories.docs.length} expired stories');
    } catch (e) {
      debugPrint('❌ Error cleaning up expired stories: $e');
    }
  }
}
