import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:event_marketplace_app/core/feature_flags.dart';
import 'package:event_marketplace_app/models/story.dart';
import 'package:uuid/uuid.dart';

/// Сервис для работы со сторисами специалистов
class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Создать сторис
  Future<Story> createStory({
    required String specialistId,
    required String specialistName,
    String? specialistPhotoUrl,
    required StoryType type,
    required XFile mediaFile,
    String? caption,
    List<String>? tags,
  }) async {
    if (!FeatureFlags.storiesEnabled) {
      throw Exception('Сторисы отключены');
    }

    try {
      // Загружаем медиа файл
      final mediaUrl = await _uploadMediaFile(mediaFile, specialistId);
      String? thumbnailUrl;

      // Создаем превью для видео
      if (type == StoryType.video) {
        thumbnailUrl = await _generateVideoThumbnail(mediaFile, specialistId);
      }

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      final story = Story(
        id: '',
        specialistId: specialistId,
        specialistName: specialistName,
        specialistPhotoUrl: specialistPhotoUrl,
        type: type,
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        caption: caption,
        tags: tags ?? [],
        createdAt: now,
        expiresAt: expiresAt,
        views: 0,
        likes: 0,
        viewers: [],
        metadata: {},
      );

      final docRef = await _firestore.collection('stories').add(story.toMap());

      return story.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Ошибка создания сториса: $e');
    }
  }

  /// Получить активные сторисы специалиста
  Future<List<Story>> getSpecialistStories(String specialistId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('stories')
          .where('specialistId', isEqualTo: specialistId)
          .where('expiresAt', isGreaterThan: now)
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Story.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Ошибка получения сторисов: $e');
    }
  }

  /// Получить все активные сторисы
  Future<List<Story>> getAllActiveStories() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('stories')
          .where('expiresAt', isGreaterThan: now)
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Story.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Ошибка получения всех сторисов: $e');
    }
  }

  /// Отметить сторис как просмотренный
  Future<void> markStoryAsViewed({
    required String storyId,
    required String userId,
  }) async {
    try {
      final storyDoc = _firestore.collection('stories').doc(storyId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(storyDoc);
        if (!doc.exists) return;

        final story = Story.fromDocument(doc);
        if (story.viewers.contains(userId)) return;

        final updatedViewers = List<String>.from(story.viewers)..add(userId);

        transaction.update(storyDoc, {
          'viewers': updatedViewers,
          'views': FieldValue.increment(1),
        });
      });
    } catch (e) {
      throw Exception('Ошибка отметки просмотра: $e');
    }
  }

  /// Лайкнуть сторис
  Future<void> likeStory({
    required String storyId,
    required String userId,
  }) async {
    try {
      final likeDoc = await _firestore
          .collection('story_likes')
          .where('storyId', isEqualTo: storyId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (likeDoc.docs.isNotEmpty) {
        throw Exception('Вы уже лайкнули этот сторис');
      }

      // Сохраняем лайк
      await _firestore.collection('story_likes').add({
        'storyId': storyId,
        'userId': userId,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      // Увеличиваем счетчик лайков
      await _firestore.collection('stories').doc(storyId).update({
        'likes': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Ошибка лайка сториса: $e');
    }
  }

  /// Убрать лайк со сториса
  Future<void> unlikeStory({
    required String storyId,
    required String userId,
  }) async {
    try {
      // Находим лайк
      final likeDoc = await _firestore
          .collection('story_likes')
          .where('storyId', isEqualTo: storyId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (likeDoc.docs.isEmpty) {
        throw Exception('Вы не лайкали этот сторис');
      }

      // Удаляем лайк
      await _firestore
          .collection('story_likes')
          .doc(likeDoc.docs.first.id)
          .delete();

      // Уменьшаем счетчик лайков
      await _firestore.collection('stories').doc(storyId).update({
        'likes': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Ошибка удаления лайка: $e');
    }
  }

  /// Удалить сторис
  Future<void> deleteStory(String storyId) async {
    try {
      // Получаем информацию о сторисе
      final storyDoc =
          await _firestore.collection('stories').doc(storyId).get();
      if (!storyDoc.exists) {
        throw Exception('Сторис не найден');
      }

      final story = Story.fromDocument(storyDoc);

      // Удаляем медиа файлы из Storage
      await _deleteMediaFile(story.mediaUrl);
      if (story.thumbnailUrl != null) {
        await _deleteMediaFile(story.thumbnailUrl!);
      }

      // Удаляем лайки
      final likesSnapshot = await _firestore
          .collection('story_likes')
          .where('storyId', isEqualTo: storyId)
          .get();

      for (final likeDoc in likesSnapshot.docs) {
        await likeDoc.reference.delete();
      }

      // Удаляем сторис
      await _firestore.collection('stories').doc(storyId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления сториса: $e');
    }
  }

  /// Очистить истекшие сторисы
  Future<void> cleanupExpiredStories() async {
    try {
      final now = DateTime.now();
      final expiredStories = await _firestore
          .collection('stories')
          .where('expiresAt', isLessThan: now)
          .get();

      for (final doc in expiredStories.docs) {
        final story = Story.fromDocument(doc);

        // Удаляем медиа файлы
        await _deleteMediaFile(story.mediaUrl);
        if (story.thumbnailUrl != null) {
          await _deleteMediaFile(story.thumbnailUrl!);
        }

        // Удаляем лайки
        final likesSnapshot = await _firestore
            .collection('story_likes')
            .where('storyId', isEqualTo: doc.id)
            .get();

        for (final likeDoc in likesSnapshot.docs) {
          await likeDoc.reference.delete();
        }

        // Удаляем сторис
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Ошибка очистки истекших сторисов: $e');
    }
  }

  /// Получить статистику сторисов специалиста
  Future<StoryStatistics> getSpecialistStoryStatistics(
      String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('stories')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final stories =
          snapshot.docs.map((doc) => Story.fromDocument(doc)).toList();

      final totalStories = stories.length;
      final totalViews = stories.fold(0, (sum, story) => sum + story.views);
      final totalLikes = stories.fold(0, (sum, story) => sum + story.likes);
      final activeStories = stories.where((story) => !story.isExpired).length;

      return StoryStatistics(
        totalStories: totalStories,
        totalViews: totalViews,
        totalLikes: totalLikes,
        activeStories: activeStories,
        averageViews:
            totalStories > 0 ? (totalViews / totalStories).round() : 0,
        averageLikes:
            totalStories > 0 ? (totalLikes / totalStories).round() : 0,
      );
    } catch (e) {
      throw Exception('Ошибка получения статистики сторисов: $e');
    }
  }

  // Приватные методы

  Future<String> _uploadMediaFile(XFile file, String specialistId) async {
    try {
      final fileName = '${specialistId}/stories/${_uuid.v4()}_${file.name}';
      final ref = _storage.ref().child(fileName);

      final uploadTask = await ref.putFile(File(file.path));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Ошибка загрузки медиа файла: $e');
    }
  }

  Future<String> _generateVideoThumbnail(
      XFile videoFile, String specialistId) async {
    try {
      // TODO: Реализовать генерацию превью для видео
      // Пока возвращаем заглушку
      return '';
    } catch (e) {
      return '';
    }
  }

  Future<void> _deleteMediaFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Игнорируем ошибки удаления файлов
    }
  }
}

/// Статистика сторисов
class StoryStatistics {
  final int totalStories;
  final int totalViews;
  final int totalLikes;
  final int activeStories;
  final int averageViews;
  final int averageLikes;

  const StoryStatistics({
    required this.totalStories,
    required this.totalViews,
    required this.totalLikes,
    required this.activeStories,
    required this.averageViews,
    required this.averageLikes,
  });
}
