import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feed_post.dart';

/// Сервис для работы с лентой новостей
class FeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить посты ленты
  Stream<List<FeedPost>> getFeedPosts() => _firestore
      .collection('feed_posts')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(FeedPost.fromDocument).toList(),
      );

  /// Получить комментарии поста
  Stream<List<FeedComment>> getPostComments(String postId) => _firestore
      .collection('feed_posts')
      .doc(postId)
      .collection('comments')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(FeedComment.fromDocument).toList(),
      );

  /// Получить лайки поста
  Stream<List<String>> getPostLikes(String postId) =>
      _firestore.collection('feed_posts').doc(postId).snapshots().map(
            (snapshot) => List<String>.from(snapshot.data()?['likedBy'] ?? []),
          );

  /// Создать пост
  Future<String> createPost(FeedPost post) async {
    try {
      final docRef =
          await _firestore.collection('feed_posts').add(post.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания поста: $e');
    }
  }

  /// Обновить пост
  Future<void> updatePost(FeedPost post) async {
    try {
      await _firestore
          .collection('feed_posts')
          .doc(post.id)
          .update(post.toMap());
    } catch (e) {
      throw Exception('Ошибка обновления поста: $e');
    }
  }

  /// Удалить пост
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('feed_posts').doc(postId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления поста: $e');
    }
  }

  /// Лайкнуть/убрать лайк с поста
  Future<void> toggleLike(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('feed_posts').doc(postId);
      final postDoc = await postRef.get();

      if (!postDoc.exists) {
        throw Exception('Пост не найден');
      }

      final postData = postDoc.data();
      final likedBy = List<String>.from(postData?['likedBy'] ?? []);
      final isLiked = likedBy.contains(userId);

      if (isLiked) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }

      await postRef.update({
        'likedBy': likedBy,
        'likesCount': likedBy.length,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка изменения лайка: $e');
    }
  }

  /// Добавить комментарий
  Future<String> addComment(FeedComment comment) async {
    try {
      final docRef = await _firestore
          .collection('feed_posts')
          .doc(comment.postId)
          .collection('comments')
          .add(comment.toMap());

      // Обновить количество комментариев в посте
      await _firestore.collection('feed_posts').doc(comment.postId).update({
        'commentsCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка добавления комментария: $e');
    }
  }

  /// Удалить комментарий
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _firestore
          .collection('feed_posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // Обновить количество комментариев в посте
      await _firestore.collection('feed_posts').doc(postId).update({
        'commentsCount': FieldValue.increment(-1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка удаления комментария: $e');
    }
  }

  /// Лайкнуть/убрать лайк с комментария
  Future<void> toggleCommentLike(
    String postId,
    String commentId,
    String userId,
  ) async {
    try {
      final commentRef = _firestore
          .collection('feed_posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId);

      final commentDoc = await commentRef.get();

      if (!commentDoc.exists) {
        throw Exception('Комментарий не найден');
      }

      final commentData = commentDoc.data();
      final likedBy = List<String>.from(commentData?['likedBy'] ?? []);
      final isLiked = likedBy.contains(userId);

      if (isLiked) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }

      await commentRef.update({
        'likedBy': likedBy,
        'likesCount': likedBy.length,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка изменения лайка комментария: $e');
    }
  }

  /// Лайкнуть пост
  Future<void> likePost(String postId, String userId) async {
    try {
      await _firestore
          .collection('feed_posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .set({
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка лайка поста: $e');
    }
  }

  /// Поделиться постом
  Future<void> sharePost(String postId, String userId) async {
    try {
      await _firestore
          .collection('feed_posts')
          .doc(postId)
          .collection('shares')
          .doc(userId)
          .set({
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка шаринга поста: $e');
    }
  }

  /// Получить ленту специалиста
  Stream<List<FeedPost>> getSpecialistFeed(String specialistId) => _firestore
      .collection('feed_posts')
      .where('authorId', isEqualTo: specialistId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(FeedPost.fromDocument).toList(),
      );
}
