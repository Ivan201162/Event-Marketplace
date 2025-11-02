import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/post.dart';
import 'package:event_marketplace_app/models/story.dart';
import 'package:event_marketplace_app/services/follow_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart';

/// Сервис для работы с лентой
class FeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить посты для ленты
  Future<List<Post>> getPosts() async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Post.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки постов: $e');
    }
  }

  /// Загрузить больше постов
  Future<List<Post>> getMorePosts(int offset) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .startAfter([offset])
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Post.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки дополнительных постов: $e');
    }
  }

  /// Получить Stories
  Future<List<Story>> getStories() async {
    try {
      final snapshot = await _firestore
          .collection('stories')
          .where('expiresAt', isGreaterThan: DateTime.now())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Story.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки Stories: $e');
    }
  }

  /// Поиск постов
  Future<List<Post>> searchPosts(String query) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('text', isGreaterThanOrEqualTo: query)
          .where('text', isLessThan: '$query\uf8ff')
          .orderBy('text')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Post.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка поиска постов: $e');
    }
  }

  /// Фильтрация постов
  Future<List<Post>> filterPosts(String filter) async {
    try {
      Query query = _firestore.collection('posts');

      switch (filter) {
        case 'popular':
          query = query.orderBy('likesCount', descending: true);
        case 'recent':
          query = query.orderBy('createdAt', descending: true);
        default:
          query = query.orderBy('createdAt', descending: true);
      }

      final snapshot = await query.limit(20).get();

      return snapshot.docs.map((doc) {
        final data = doc.data()! as Map<String, dynamic>;
        return Post.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Ошибка фильтрации постов: $e');
    }
  }

  /// Лайк поста
  Future<void> likePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'likesCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка лайка поста: $e');
    }
  }

  /// Поделиться постом
  Future<void> sharePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'sharesCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка шаринга поста: $e');
    }
  }

  /// Сохранить пост
  Future<void> savePost(String postId) async {
    try {
      // Добавить в коллекцию сохранённых постов пользователя
      await _firestore
          .collection('users')
          .doc('current_user_id') // TODO: Получить ID текущего пользователя
          .collection('saved_posts')
          .doc(postId)
          .set({
        'postId': postId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка сохранения поста: $e');
    }
  }

  /// Stream of posts authored by accounts the user follows, newest first.
  /// Must support following > 10 via whereIn chunking (chunks of 10).
  /// Merge multiple query snapshots into one stream, de-dup by docId, sort by createdAt desc.
  /// Use isActive=true filter.
  Stream<List<Post>> getFollowingFeed(String userId) {
    final controller = BehaviorSubject<List<Post>>.seeded([]);
    final followService = FollowService();
    final Map<String, StreamSubscription> chunkSubscriptions = {};
    StreamSubscription? followingSubscription;

    // Подписываемся на изменения в follows коллекции
    final followingStream = _firestore
        .collection('follows')
        .where('followerId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      final followingIds = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return (data['followingId'] ?? data['followedId'] ?? '') as String;
          })
          .where((id) => id.isNotEmpty)
          .toList();
      
      // Если follows пуста, пробуем fallback через subcollection
      if (followingIds.isEmpty) {
        try {
          final fallbackSnapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('following')
              .limit(300)
              .get();
          return fallbackSnapshot.docs
              .map((doc) {
                final data = doc.data();
                return (data['userId'] ?? doc.id) as String;
              })
              .where((id) => id.isNotEmpty)
              .toList();
        } catch (e) {
          debugPrint('Error getting fallback following: $e');
          return <String>[];
        }
      }
      
      return followingIds;
    });

    // Отслеживаем изменения в following и обновляем streams постов
    followingSubscription = followingStream.listen(
      (followingIds) {
        // Отменяем предыдущие подписки
        for (final sub in chunkSubscriptions.values) {
          sub.cancel();
        }
        chunkSubscriptions.clear();

        if (followingIds.isEmpty) {
          controller.add([]);
          return;
        }

        // Chunking для whereIn (макс. 10 элементов)
        final chunks = <List<String>>[];
        for (var i = 0; i < followingIds.length; i += 10) {
          final end = (i + 10).clamp(0, followingIds.length);
          chunks.add(followingIds.sublist(i, end));
        }

        // Создаём stream для каждого chunk
        final chunkStreams = chunks.map((chunk) {
          return _firestore
              .collection('posts')
              .where('authorId', whereIn: chunk)
              .where('isActive', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .limit(50)
              .snapshots()
              .map((snapshot) {
            return snapshot.docs.map((doc) {
              try {
                final data = doc.data();
                return Post.fromMap(data, doc.id);
              } catch (e) {
                debugPrint('Error parsing post ${doc.id}: $e');
                return null;
              }
            }).whereType<Post>().toList();
          });
        }).toList();

        // Объединяем все chunk streams
        if (chunkStreams.isEmpty) {
          controller.add([]);
        } else if (chunkStreams.length == 1) {
          final sub = chunkStreams.first.listen(
            (posts) {
              controller.add(posts);
            },
            onError: (error) {
              debugPrint('Error in getFollowingFeed: $error');
              controller.addError(error);
            },
          );
          chunkSubscriptions['chunk_0'] = sub;
        } else {
          // Используем Rx.combineLatest для объединения нескольких streams
          final combined = Rx.combineLatest(chunkStreams, (List<List<Post>> chunkResults) {
            // Де-дупликация по docId и сортировка
            final Map<String, Post> uniquePosts = {};
            for (final chunkPosts in chunkResults) {
              for (final post in chunkPosts) {
                uniquePosts[post.id] = post;
              }
            }
            final sortedPosts = uniquePosts.values.toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return sortedPosts;
          });
          
          final sub = combined.listen(
            (posts) {
              controller.add(posts);
            },
            onError: (error) {
              debugPrint('Error in getFollowingFeed: $error');
              controller.addError(error);
            },
          );
          chunkSubscriptions['combined'] = sub;
        }
      },
      onError: (error) {
        debugPrint('Error in following stream: $error');
        controller.addError(error);
      },
    );

    // Cleanup при закрытии stream
    controller.onListen = () {};
    controller.onCancel = () {
      followingSubscription?.cancel();
      for (final sub in chunkSubscriptions.values) {
        sub.cancel();
      }
      chunkSubscriptions.clear();
    };

    return controller.stream;
  }
}

// Helper для безопасного парсинга DateTime из Firestore
DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}
