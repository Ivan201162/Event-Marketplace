import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:event_marketplace_app/models/post.dart';
import 'package:event_marketplace_app/models/story.dart';

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
}
