import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/specialist_post.dart';
import '../models/specialist_story.dart';

/// Сервис для управления контентом специалиста (посты и сторис)
class SpecialistContentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final Uuid _uuid = const Uuid();

  /// Создать пост
  Future<SpecialistPost> createPost({
    required String specialistId,
    required PostContentType contentType,
    required String content,
    List<String> mediaUrls = const [],
    String? caption,
    List<String> hashtags = const [],
    String? location,
    List<String> tags = const [],
  }) async {
    try {
      final postId = _uuid.v4();
      final now = DateTime.now();

      final post = SpecialistPost(
        id: postId,
        specialistId: specialistId,
        contentType: contentType,
        content: content,
        mediaUrls: mediaUrls,
        caption: caption,
        hashtags: hashtags,
        createdAt: now,
        location: location,
        tags: tags,
      );

      await _db.collection('specialist_posts').doc(postId).set(post.toMap());

      // Обновить статистику специалиста
      await _updateSpecialistStats(specialistId, 'postsCount', 1);

      return post;
    } catch (e) {
      debugPrint('Ошибка создания поста: $e');
      throw Exception('Не удалось создать пост: $e');
    }
  }

  /// Получить посты специалиста
  Future<List<SpecialistPost>> getSpecialistPosts({
    required String specialistId,
    int limit = 20,
    String? lastPostId,
    bool includeArchived = false,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _db
          .collection('specialist_posts')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true);

      if (!includeArchived) {
        query = query.where('isArchived', isEqualTo: false);
      }

      if (lastPostId != null) {
        final lastDoc = await _db.collection('specialist_posts').doc(lastPostId).get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => SpecialistPost.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения постов: $e');
      return [];
    }
  }

  /// Обновить пост
  Future<void> updatePost({
    required String postId,
    String? content,
    String? caption,
    List<String>? hashtags,
    String? location,
    List<String>? tags,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (content != null) updateData['content'] = content;
      if (caption != null) updateData['caption'] = caption;
      if (hashtags != null) updateData['hashtags'] = hashtags;
      if (location != null) updateData['location'] = location;
      if (tags != null) updateData['tags'] = tags;

      await _db.collection('specialist_posts').doc(postId).update(updateData);
    } catch (e) {
      debugPrint('Ошибка обновления поста: $e');
      throw Exception('Не удалось обновить пост: $e');
    }
  }

  /// Удалить пост
  Future<void> deletePost(String postId) async {
    try {
      final postDoc = await _db.collection('specialist_posts').doc(postId).get();
      if (postDoc.exists) {
        final post = SpecialistPost.fromDocument(postDoc);
        
        // Удалить медиа файлы
        for (final mediaUrl in post.mediaUrls) {
          try {
            final ref = _storage.refFromURL(mediaUrl);
            await ref.delete();
          } catch (e) {
            debugPrint('Ошибка удаления медиа файла: $e');
          }
        }

        // Удалить пост
        await _db.collection('specialist_posts').doc(postId).delete();

        // Обновить статистику специалиста
        await _updateSpecialistStats(post.specialistId, 'postsCount', -1);
      }
    } catch (e) {
      debugPrint('Ошибка удаления поста: $e');
      throw Exception('Не удалось удалить пост: $e');
    }
  }

  /// Закрепить/открепить пост
  Future<void> togglePostPin(String postId, bool isPinned) async {
    try {
      await _db.collection('specialist_posts').doc(postId).update({
        'isPinned': isPinned,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Ошибка изменения статуса закрепления поста: $e');
      throw Exception('Не удалось изменить статус поста: $e');
    }
  }

  /// Создать сторис
  Future<SpecialistStory> createStory({
    required String specialistId,
    required StoryMediaType mediaType,
    required String mediaUrl,
    String? thumbnailUrl,
    String? caption,
    List<String> hashtags = const [],
    String? location,
    List<String> tags = const [],
  }) async {
    try {
      final storyId = _uuid.v4();
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      final story = SpecialistStory(
        id: storyId,
        specialistId: specialistId,
        mediaType: mediaType,
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        caption: caption,
        hashtags: hashtags,
        createdAt: now,
        expiresAt: expiresAt,
        location: location,
        tags: tags,
      );

      await _db.collection('specialist_stories').doc(storyId).set(story.toMap());

      // Обновить статистику специалиста
      await _updateSpecialistStats(specialistId, 'storiesCount', 1);

      return story;
    } catch (e) {
      debugPrint('Ошибка создания сторис: $e');
      throw Exception('Не удалось создать сторис: $e');
    }
  }

  /// Получить активные сторис специалиста
  Future<List<SpecialistStory>> getActiveStories(String specialistId) async {
    try {
      final now = DateTime.now();
      final query = await _db
          .collection('specialist_stories')
          .where('specialistId', isEqualTo: specialistId)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => SpecialistStory.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения сторис: $e');
      return [];
    }
  }

  /// Получить все сторис специалиста (включая истекшие)
  Future<List<SpecialistStory>> getAllStories({
    required String specialistId,
    int limit = 50,
    String? lastStoryId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _db
          .collection('specialist_stories')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true);

      if (lastStoryId != null) {
        final lastDoc = await _db.collection('specialist_stories').doc(lastStoryId).get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => SpecialistStory.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения всех сторис: $e');
      return [];
    }
  }

  /// Отметить сторис как просмотренную
  Future<void> markStoryAsViewed({
    required String storyId,
    required String viewerId,
    Duration? viewDuration,
  }) async {
    try {
      final viewId = _uuid.v4();
      final view = StoryView(
        id: viewId,
        storyId: storyId,
        viewerId: viewerId,
        viewedAt: DateTime.now(),
        viewDuration: viewDuration,
      );

      await _db.collection('story_views').doc(viewId).set(view.toMap());

      // Обновить счетчик просмотров
      await _db.collection('specialist_stories').doc(storyId).update({
        'viewersCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Ошибка отметки просмотра сторис: $e');
    }
  }

  /// Добавить сторис в избранное (хайлайты)
  Future<void> addToHighlights({
    required String storyId,
    required String highlightTitle,
  }) async {
    try {
      await _db.collection('specialist_stories').doc(storyId).update({
        'isHighlighted': true,
        'highlightTitle': highlightTitle,
      });
    } catch (e) {
      debugPrint('Ошибка добавления в хайлайты: $e');
      throw Exception('Не удалось добавить в хайлайты: $e');
    }
  }

  /// Удалить сторис из избранного
  Future<void> removeFromHighlights(String storyId) async {
    try {
      await _db.collection('specialist_stories').doc(storyId).update({
        'isHighlighted': false,
        'highlightTitle': null,
      });
    } catch (e) {
      debugPrint('Ошибка удаления из хайлайтов: $e');
      throw Exception('Не удалось удалить из хайлайтов: $e');
    }
  }

  /// Загрузить медиа файл
  Future<String> uploadMedia({
    required String specialistId,
    required String filePath,
    required String fileName,
    required String contentType,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('specialist_content')
          .child(specialistId)
          .child(contentType)
          .child(fileName);

      final uploadTask = await ref.putFile(
        // В реальном приложении здесь был бы File объект
        // await ref.putFile(File(filePath)),
        // Для демонстрации используем заглушку
        throw UnimplementedError('File upload not implemented'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Ошибка загрузки медиа: $e');
      throw Exception('Не удалось загрузить медиа файл: $e');
    }
  }

  /// Получить статистику контента специалиста
  Future<Map<String, int>> getContentStats(String specialistId) async {
    try {
      final postsQuery = await _db
          .collection('specialist_posts')
          .where('specialistId', isEqualTo: specialistId)
          .where('isArchived', isEqualTo: false)
          .get();

      final storiesQuery = await _db
          .collection('specialist_stories')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      int totalLikes = 0;
      int totalComments = 0;
      int totalViews = 0;

      for (final doc in postsQuery.docs) {
        final data = doc.data();
        totalLikes += data['likesCount'] as int? ?? 0;
        totalComments += data['commentsCount'] as int? ?? 0;
      }

      for (final doc in storiesQuery.docs) {
        final data = doc.data();
        totalViews += data['viewersCount'] as int? ?? 0;
      }

      return {
        'postsCount': postsQuery.docs.length,
        'storiesCount': storiesQuery.docs.length,
        'totalLikes': totalLikes,
        'totalComments': totalComments,
        'totalViews': totalViews,
      };
    } catch (e) {
      debugPrint('Ошибка получения статистики контента: $e');
      return {};
    }
  }

  /// Очистить истекшие сторис
  Future<void> cleanupExpiredStories() async {
    try {
      final now = DateTime.now();
      final expiredStories = await _db
          .collection('specialist_stories')
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = _db.batch();
      for (final doc in expiredStories.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Ошибка очистки истекших сторис: $e');
    }
  }

  /// Обновить статистику специалиста
  Future<void> _updateSpecialistStats(String specialistId, String field, int increment) async {
    try {
      await _db.collection('specialists').doc(specialistId).update({
        field: FieldValue.increment(increment),
        'lastActivityAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Ошибка обновления статистики специалиста: $e');
    }
  }

  /// Получить популярные посты
  Future<List<SpecialistPost>> getPopularPosts({
    int limit = 10,
    String? category,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _db
          .collection('specialist_posts')
          .where('isArchived', isEqualTo: false)
          .orderBy('likesCount', descending: true)
          .orderBy('createdAt', descending: true);

      if (category != null) {
        query = query.where('tags', arrayContains: category);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => SpecialistPost.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения популярных постов: $e');
      return [];
    }
  }

  /// Поиск постов по хештегам
  Future<List<SpecialistPost>> searchPostsByHashtag({
    required String hashtag,
    int limit = 20,
  }) async {
    try {
      final query = await _db
          .collection('specialist_posts')
          .where('hashtags', arrayContains: hashtag)
          .where('isArchived', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => SpecialistPost.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Ошибка поиска постов по хештегу: $e');
      return [];
    }
  }
}
