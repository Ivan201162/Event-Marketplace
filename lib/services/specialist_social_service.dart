import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/specialist_post.dart';
import '../models/specialist_story.dart';
import '../models/specialist.dart';

/// Сервис для работы с социальными функциями специалистов
class SpecialistSocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Создать пост
  Future<String> createPost({
    required String specialistId,
    required String content,
    List<String>? mediaUrls,
    MediaType mediaType = MediaType.image,
    List<String>? tags,
    String? location,
    PriceInfo? priceInfo,
    ServiceInfo? serviceInfo,
  }) async {
    try {
      final post = SpecialistPost(
        id: '', // Будет установлен Firestore
        specialistId: specialistId,
        content: content,
        mediaUrls: mediaUrls ?? [],
        mediaType: mediaType,
        createdAt: DateTime.now(),
        tags: tags ?? [],
        location: location,
        priceInfo: priceInfo,
        serviceInfo: serviceInfo,
      );

      final docRef = await _firestore.collection('specialist_posts').add(post.toMap());
      
      // Обновляем счетчик постов у специалиста
      await _updateSpecialistPostsCount(specialistId, 1);
      
      // Добавляем пост в список недавних постов
      await _addToRecentPosts(specialistId, docRef.id);

      debugPrint('Post created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating post: $e');
      throw Exception('Ошибка создания поста: $e');
    }
  }

  /// Создать сторис
  Future<String> createStory({
    required String specialistId,
    required String mediaUrl,
    required StoryMediaType mediaType,
    String? caption,
    String? location,
    List<String>? tags,
    int duration = 15,
    StoryPriceInfo? priceInfo,
    StoryServiceInfo? serviceInfo,
  }) async {
    try {
      final expiresAt = DateTime.now().add(const Duration(hours: 24));
      
      final story = SpecialistStory(
        id: '', // Будет установлен Firestore
        specialistId: specialistId,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
        caption: caption,
        location: location,
        tags: tags ?? [],
        duration: duration,
        priceInfo: priceInfo,
        serviceInfo: serviceInfo,
      );

      final docRef = await _firestore.collection('specialist_stories').add(story.toMap());
      
      // Обновляем счетчик сторис у специалиста
      await _updateSpecialistStoriesCount(specialistId, 1);
      
      // Добавляем сторис в список активных сторис
      await _addToActiveStories(specialistId, docRef.id);

      debugPrint('Story created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating story: $e');
      throw Exception('Ошибка создания сторис: $e');
    }
  }

  /// Получить посты специалиста
  Stream<List<SpecialistPost>> getSpecialistPosts(
    String specialistId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) {
    Query query = _firestore
        .collection('specialist_posts')
        .where('specialistId', isEqualTo: specialistId)
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SpecialistPost.fromDocument(doc)).toList();
    });
  }

  /// Получить активные сторис специалиста
  Stream<List<SpecialistStory>> getSpecialistStories(String specialistId) {
    return _firestore
        .collection('specialist_stories')
        .where('specialistId', isEqualTo: specialistId)
        .where('status', isEqualTo: StoryStatus.active.name)
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SpecialistStory.fromDocument(doc)).toList();
    });
  }

  /// Лайкнуть пост
  Future<void> likePost(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('specialist_posts').doc(postId);
      
      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) return;

        final post = SpecialistPost.fromDocument(postDoc);
        final isLiked = post.likedBy.contains(userId);
        
        if (isLiked) {
          // Убираем лайк
          transaction.update(postRef, {
            'likedBy': FieldValue.arrayRemove([userId]),
            'likes': FieldValue.increment(-1),
          });
        } else {
          // Добавляем лайк
          transaction.update(postRef, {
            'likedBy': FieldValue.arrayUnion([userId]),
            'likes': FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      debugPrint('Error liking post: $e');
      throw Exception('Ошибка лайка поста: $e');
    }
  }

  /// Сохранить пост
  Future<void> savePost(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('specialist_posts').doc(postId);
      
      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) return;

        final post = SpecialistPost.fromDocument(postDoc);
        final isSaved = post.savedBy.contains(userId);
        
        if (isSaved) {
          // Убираем из сохраненных
          transaction.update(postRef, {
            'savedBy': FieldValue.arrayRemove([userId]),
            'saves': FieldValue.increment(-1),
          });
        } else {
          // Добавляем в сохраненные
          transaction.update(postRef, {
            'savedBy': FieldValue.arrayUnion([userId]),
            'saves': FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      debugPrint('Error saving post: $e');
      throw Exception('Ошибка сохранения поста: $e');
    }
  }

  /// Просмотреть сторис
  Future<void> viewStory(String storyId, String userId) async {
    try {
      final storyRef = _firestore.collection('specialist_stories').doc(storyId);
      
      await _firestore.runTransaction((transaction) async {
        final storyDoc = await transaction.get(storyRef);
        if (!storyDoc.exists) return;

        final story = SpecialistStory.fromDocument(storyDoc);
        
        if (!story.viewers.contains(userId)) {
          transaction.update(storyRef, {
            'viewers': FieldValue.arrayUnion([userId]),
            'views': FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      debugPrint('Error viewing story: $e');
      throw Exception('Ошибка просмотра сторис: $e');
    }
  }

  /// Лайкнуть сторис
  Future<void> likeStory(String storyId, String userId) async {
    try {
      final storyRef = _firestore.collection('specialist_stories').doc(storyId);
      
      await _firestore.runTransaction((transaction) async {
        final storyDoc = await transaction.get(storyRef);
        if (!storyDoc.exists) return;

        transaction.update(storyRef, {
          'likes': FieldValue.increment(1),
        });
      });
    } catch (e) {
      debugPrint('Error liking story: $e');
      throw Exception('Ошибка лайка сторис: $e');
    }
  }

  /// Подписаться на специалиста
  Future<void> followSpecialist(String specialistId, String userId) async {
    try {
      final specialistRef = _firestore.collection('specialists').doc(specialistId);
      final userRef = _firestore.collection('users').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        // Увеличиваем счетчик подписчиков у специалиста
        transaction.update(specialistRef, {
          'followersCount': FieldValue.increment(1),
        });
        
        // Увеличиваем счетчик подписок у пользователя
        transaction.update(userRef, {
          'followingCount': FieldValue.increment(1),
        });
      });

      // Добавляем подписку в отдельную коллекцию
      await _firestore.collection('follows').add({
        'followerId': userId,
        'followingId': specialistId,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error following specialist: $e');
      throw Exception('Ошибка подписки на специалиста: $e');
    }
  }

  /// Отписаться от специалиста
  Future<void> unfollowSpecialist(String specialistId, String userId) async {
    try {
      final specialistRef = _firestore.collection('specialists').doc(specialistId);
      final userRef = _firestore.collection('users').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        // Уменьшаем счетчик подписчиков у специалиста
        transaction.update(specialistRef, {
          'followersCount': FieldValue.increment(-1),
        });
        
        // Уменьшаем счетчик подписок у пользователя
        transaction.update(userRef, {
          'followingCount': FieldValue.increment(-1),
        });
      });

      // Удаляем подписку
      final followsQuery = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .where('followingId', isEqualTo: specialistId)
          .get();

      for (final doc in followsQuery.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error unfollowing specialist: $e');
      throw Exception('Ошибка отписки от специалиста: $e');
    }
  }

  /// Проверить, подписан ли пользователь на специалиста
  Future<bool> isFollowing(String specialistId, String userId) async {
    try {
      final followsQuery = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .where('followingId', isEqualTo: specialistId)
          .limit(1)
          .get();

      return followsQuery.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      return false;
    }
  }

  /// Получить ленту постов (для подписчиков)
  Stream<List<SpecialistPost>> getFeed(String userId, {int limit = 20}) {
    // Сначала получаем список подписок
    return _firestore
        .collection('follows')
        .where('followerId', isEqualTo: userId)
        .snapshots()
        .asyncMap((followsSnapshot) async {
      if (followsSnapshot.docs.isEmpty) return <SpecialistPost>[];

      final followingIds = followsSnapshot.docs
          .map((doc) => doc.data()['followingId'] as String)
          .toList();

      // Получаем посты от подписанных специалистов
      final postsQuery = await _firestore
          .collection('specialist_posts')
          .where('specialistId', whereIn: followingIds)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return postsQuery.docs.map((doc) => SpecialistPost.fromDocument(doc)).toList();
    });
  }

  /// Загрузить медиа файл
  Future<String> uploadMedia(String filePath, Uint8List fileBytes) async {
    try {
      final ref = _storage.ref().child('specialist_media/$filePath');
      final uploadTask = ref.putData(fileBytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading media: $e');
      throw Exception('Ошибка загрузки медиа: $e');
    }
  }

  /// Удалить пост
  Future<void> deletePost(String postId, String specialistId) async {
    try {
      await _firestore.collection('specialist_posts').doc(postId).delete();
      
      // Обновляем счетчик постов у специалиста
      await _updateSpecialistPostsCount(specialistId, -1);
      
      // Удаляем пост из списка недавних постов
      await _removeFromRecentPosts(specialistId, postId);
    } catch (e) {
      debugPrint('Error deleting post: $e');
      throw Exception('Ошибка удаления поста: $e');
    }
  }

  /// Удалить сторис
  Future<void> deleteStory(String storyId, String specialistId) async {
    try {
      await _firestore.collection('specialist_stories').doc(storyId).delete();
      
      // Обновляем счетчик сторис у специалиста
      await _updateSpecialistStoriesCount(specialistId, -1);
      
      // Удаляем сторис из списка активных сторис
      await _removeFromActiveStories(specialistId, storyId);
    } catch (e) {
      debugPrint('Error deleting story: $e');
      throw Exception('Ошибка удаления сторис: $e');
    }
  }

  /// Обновить счетчик постов у специалиста
  Future<void> _updateSpecialistPostsCount(String specialistId, int increment) async {
    try {
      await _firestore.collection('specialists').doc(specialistId).update({
        'postsCount': FieldValue.increment(increment),
      });
    } catch (e) {
      debugPrint('Error updating posts count: $e');
    }
  }

  /// Обновить счетчик сторис у специалиста
  Future<void> _updateSpecialistStoriesCount(String specialistId, int increment) async {
    try {
      await _firestore.collection('specialists').doc(specialistId).update({
        'storiesCount': FieldValue.increment(increment),
      });
    } catch (e) {
      debugPrint('Error updating stories count: $e');
    }
  }

  /// Добавить пост в список недавних постов
  Future<void> _addToRecentPosts(String specialistId, String postId) async {
    try {
      await _firestore.collection('specialists').doc(specialistId).update({
        'recentPosts': FieldValue.arrayUnion([postId]),
      });
    } catch (e) {
      debugPrint('Error adding to recent posts: $e');
    }
  }

  /// Удалить пост из списка недавних постов
  Future<void> _removeFromRecentPosts(String specialistId, String postId) async {
    try {
      await _firestore.collection('specialists').doc(specialistId).update({
        'recentPosts': FieldValue.arrayRemove([postId]),
      });
    } catch (e) {
      debugPrint('Error removing from recent posts: $e');
    }
  }

  /// Добавить сторис в список активных сторис
  Future<void> _addToActiveStories(String specialistId, String storyId) async {
    try {
      await _firestore.collection('specialists').doc(specialistId).update({
        'activeStories': FieldValue.arrayUnion([storyId]),
      });
    } catch (e) {
      debugPrint('Error adding to active stories: $e');
    }
  }

  /// Удалить сторис из списка активных сторис
  Future<void> _removeFromActiveStories(String specialistId, String storyId) async {
    try {
      await _firestore.collection('specialists').doc(specialistId).update({
        'activeStories': FieldValue.arrayRemove([storyId]),
      });
    } catch (e) {
      debugPrint('Error removing from active stories: $e');
    }
  }

  /// Получить статистику специалиста
  Future<Map<String, dynamic>> getSpecialistStats(String specialistId) async {
    try {
      final specialistDoc = await _firestore.collection('specialists').doc(specialistId).get();
      if (!specialistDoc.exists) return {};

      final specialist = Specialist.fromDocument(specialistDoc);
      
      return {
        'postsCount': specialist.postsCount,
        'storiesCount': specialist.storiesCount,
        'followersCount': specialist.followersCount,
        'followingCount': specialist.followingCount,
        'totalLikes': await _getTotalLikes(specialistId),
        'totalViews': await _getTotalViews(specialistId),
        'engagementRate': await _getEngagementRate(specialistId),
      };
    } catch (e) {
      debugPrint('Error getting specialist stats: $e');
      return {};
    }
  }

  /// Получить общее количество лайков
  Future<int> _getTotalLikes(String specialistId) async {
    try {
      final postsQuery = await _firestore
          .collection('specialist_posts')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      int totalLikes = 0;
      for (final doc in postsQuery.docs) {
        totalLikes += doc.data()['likes'] as int? ?? 0;
      }

      final storiesQuery = await _firestore
          .collection('specialist_stories')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      for (final doc in storiesQuery.docs) {
        totalLikes += doc.data()['likes'] as int? ?? 0;
      }

      return totalLikes;
    } catch (e) {
      debugPrint('Error getting total likes: $e');
      return 0;
    }
  }

  /// Получить общее количество просмотров
  Future<int> _getTotalViews(String specialistId) async {
    try {
      final storiesQuery = await _firestore
          .collection('specialist_stories')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      int totalViews = 0;
      for (final doc in storiesQuery.docs) {
        totalViews += doc.data()['views'] as int? ?? 0;
      }

      return totalViews;
    } catch (e) {
      debugPrint('Error getting total views: $e');
      return 0;
    }
  }

  /// Получить уровень вовлеченности
  Future<double> _getEngagementRate(String specialistId) async {
    try {
      final stats = await getSpecialistStats(specialistId);
      final followersCount = stats['followersCount'] as int? ?? 0;
      final totalLikes = stats['totalLikes'] as int? ?? 0;
      
      if (followersCount == 0) return 0.0;
      
      return (totalLikes / followersCount) * 100;
    } catch (e) {
      debugPrint('Error getting engagement rate: $e');
      return 0.0;
    }
  }
}
