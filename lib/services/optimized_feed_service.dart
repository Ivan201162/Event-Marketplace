import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/enhanced_feed_post.dart';

/// Оптимизированный сервис для работы с лентой
class OptimizedFeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Кэш для постов
  List<EnhancedFeedPost> _cachedPosts = [];
  DateTime? _postsCacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 15);

  /// Получить посты с обработкой состояний
  Future<FeedState> getPosts({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    bool forceRefresh = false,
  }) async {
    try {
      // Проверяем кэш для первой загрузки
      if (lastDocument == null && !forceRefresh && _cachedPosts.isNotEmpty) {
        if (_postsCacheTime != null &&
            DateTime.now().difference(_postsCacheTime!) < _cacheExpiry) {
          return FeedState(
            posts: _cachedPosts,
            isLoading: false,
            error: null,
            hasMore: true,
          );
        }
      }

      debugPrint('📰 Загрузка постов из Firestore...');

      Query query = _firestore
          .collection('posts')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      final posts = snapshot.docs.map((doc) {
        final data = doc.data();
        return EnhancedFeedPost(
          id: doc.id,
          authorId: data['authorId'] ?? '',
          authorName: data['authorName'] ?? 'Неизвестный автор',
          authorAvatar: data['authorAvatar'],
          content: data['content'] ?? '',
          media: _parseMedia(data['media']),
          tags: List<String>.from(data['tags'] ?? []),
          likes: data['likes']?.toInt() ?? 0,
          comments: data['comments']?.toInt() ?? 0,
          shares: data['shares']?.toInt() ?? 0,
          isLiked: data['isLiked'] ?? false,
          isSaved: data['isSaved'] ?? false,
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt:
              (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      // Обновляем кэш для первой загрузки
      if (lastDocument == null) {
        _cachedPosts = posts;
        _postsCacheTime = DateTime.now();
      }

      debugPrint('✅ Загружено ${posts.length} постов');

      return FeedState(
        posts: posts,
        isLoading: false,
        error: null,
        hasMore: posts.length == limit,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      debugPrint('❌ Ошибка загрузки постов: $e');
      return FeedState(
        posts: [],
        isLoading: false,
        error: e.toString(),
        hasMore: false,
      );
    }
  }

  /// Лайкнуть/убрать лайк с поста
  Future<bool> toggleLike(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);

      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Пост не найден');
        }

        final data = postDoc.data()!;
        final likes = data['likes']?.toInt() ?? 0;
        final likedBy = List<String>.from(data['likedBy'] ?? []);

        bool isLiked = likedBy.contains(userId);

        if (isLiked) {
          likedBy.remove(userId);
          transaction.update(postRef, {
            'likes': likes - 1,
            'likedBy': likedBy,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          likedBy.add(userId);
          transaction.update(postRef, {
            'likes': likes + 1,
            'likedBy': likedBy,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при лайке поста: $e');
      return false;
    }
  }

  /// Сохранить/убрать из сохранённых
  Future<bool> toggleSave(String postId, String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('Пользователь не найден');
        }

        final data = userDoc.data()!;
        final savedPosts = List<String>.from(data['savedPosts'] ?? []);

        bool isSaved = savedPosts.contains(postId);

        if (isSaved) {
          savedPosts.remove(postId);
        } else {
          savedPosts.add(postId);
        }

        transaction.update(userRef, {
          'savedPosts': savedPosts,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return true;
    } catch (e) {
      debugPrint('❌ Ошибка при сохранении поста: $e');
      return false;
    }
  }

  /// Создать новый пост
  Future<String?> createPost({
    required String authorId,
    required String authorName,
    String? authorAvatar,
    required String content,
    List<FeedPostMedia>? media,
    List<String>? tags,
  }) async {
    try {
      final postData = {
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'content': content,
        'media': media?.map((m) => m.toMap()).toList() ?? [],
        'tags': tags ?? [],
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'likedBy': [],
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('posts').add(postData);

      debugPrint('✅ Пост создан с ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Ошибка создания поста: $e');
      return null;
    }
  }

  /// Получить посты пользователя
  Future<List<EnhancedFeedPost>> getUserPosts(String userId,
      {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return EnhancedFeedPost(
          id: doc.id,
          authorId: data['authorId'] ?? '',
          authorName: data['authorName'] ?? 'Неизвестный автор',
          authorAvatar: data['authorAvatar'],
          content: data['content'] ?? '',
          media: _parseMedia(data['media']),
          tags: List<String>.from(data['tags'] ?? []),
          likes: data['likes']?.toInt() ?? 0,
          comments: data['comments']?.toInt() ?? 0,
          shares: data['shares']?.toInt() ?? 0,
          isLiked: data['isLiked'] ?? false,
          isSaved: data['isSaved'] ?? false,
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt:
              (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Ошибка загрузки постов пользователя: $e');
      return [];
    }
  }

  /// Очистить кэш
  void clearCache() {
    _cachedPosts.clear();
    _postsCacheTime = null;
    debugPrint('🧹 Кэш ленты очищен');
  }

  /// Парсинг медиа из Firestore
  List<FeedPostMedia> _parseMedia(dynamic mediaData) {
    if (mediaData == null) return [];

    try {
      if (mediaData is List) {
        return mediaData
            .map((item) {
              if (item is Map<String, dynamic>) {
                return FeedPostMedia(
                  type: item['type'] ?? 'image',
                  url: item['url'] ?? '',
                  thumbnail: item['thumbnail'],
                );
              }
              return null;
            })
            .where((item) => item != null)
            .cast<FeedPostMedia>()
            .toList();
      }
    } catch (e) {
      debugPrint('❌ Ошибка парсинга медиа: $e');
    }

    return [];
  }
}

/// Состояние ленты
class FeedState {
  final List<EnhancedFeedPost> posts;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  const FeedState({
    required this.posts,
    required this.isLoading,
    this.error,
    required this.hasMore,
    this.lastDocument,
  });

  bool get isEmpty => posts.isEmpty && !isLoading;
  bool get hasError => error != null;
}
