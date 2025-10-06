import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';

/// Сервис для работы с постами специалистов
class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'posts';

  /// Получить все посты специалиста
  Future<List<Post>> getSpecialistPosts(String specialistId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map(Post.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки постов: $e');
    }
  }

  /// Получить поток постов специалиста
  Stream<List<Post>> getSpecialistPostsStream(String specialistId) => _firestore
      .collection(_collection)
      .where('specialistId', isEqualTo: specialistId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(Post.fromDocument).toList(),
      );

  /// Создать новый пост
  Future<Post> createPost({
    required String specialistId,
    String? text,
    required List<String> mediaUrls,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final postId = _firestore.collection(_collection).doc().id;
      final post = Post(
        id: postId,
        specialistId: specialistId,
        text: text,
        mediaUrls: mediaUrls,
        createdAt: DateTime.now(),
        metadata: metadata,
      );

      await _firestore.collection(_collection).doc(postId).set(post.toMap());

      return post;
    } catch (e) {
      throw Exception('Ошибка создания поста: $e');
    }
  }

  /// Обновить пост
  Future<void> updatePost(
    String postId, {
    String? text,
    List<String>? mediaUrls,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (text != null) updateData['text'] = text;
      if (mediaUrls != null) updateData['mediaUrls'] = mediaUrls;
      if (metadata != null) updateData['metadata'] = metadata;

      await _firestore.collection(_collection).doc(postId).update(updateData);
    } catch (e) {
      throw Exception('Ошибка обновления поста: $e');
    }
  }

  /// Удалить пост
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection(_collection).doc(postId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления поста: $e');
    }
  }

  /// Лайкнуть/убрать лайк с поста
  Future<void> toggleLike(String postId, String userId) async {
    try {
      final postRef = _firestore.collection(_collection).doc(postId);

      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Пост не найден');
        }

        final post = Post.fromDocument(postDoc);
        final likedBy = List<String>.from(post.likedBy);
        final isLiked = likedBy.contains(userId);

        if (isLiked) {
          likedBy.remove(userId);
        } else {
          likedBy.add(userId);
        }

        transaction.update(postRef, {
          'likedBy': likedBy,
          'likesCount': likedBy.length,
        });
      });
    } catch (e) {
      throw Exception('Ошибка лайка поста: $e');
    }
  }

  /// Проверить, лайкнул ли пользователь пост
  Future<bool> isPostLiked(String postId, String userId) async {
    try {
      final postDoc =
          await _firestore.collection(_collection).doc(postId).get();

      if (!postDoc.exists) return false;

      final post = Post.fromDocument(postDoc);
      return post.likedBy.contains(userId);
    } catch (e) {
      return false;
    }
  }

  /// Получить посты всех специалистов (лента)
  Future<List<Post>> getFeedPosts({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map(Post.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки ленты: $e');
    }
  }

  /// Получить поток ленты
  Stream<List<Post>> getFeedStream({int limit = 20}) => _firestore
      .collection(_collection)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(Post.fromDocument).toList(),
      );
}
