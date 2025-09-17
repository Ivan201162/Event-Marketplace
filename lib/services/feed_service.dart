import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:event_marketplace_app/core/feature_flags.dart';
import 'package:event_marketplace_app/models/feed_post.dart';
import 'package:uuid/uuid.dart';

/// Сервис для работы с лентой новостей
class FeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Создать пост в ленте
  Future<FeedPost> createPost({
    required String specialistId,
    required String specialistName,
    String? specialistPhotoUrl,
    required String content,
    required PostType type,
    List<XFile>? mediaFiles,
    List<String>? tags,
  }) async {
    if (!FeatureFlags.feedEnabled) {
      throw Exception('Лента новостей отключена');
    }

    try {
      List<String> mediaUrls = [];

      // Загружаем медиа файлы
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        for (final file in mediaFiles) {
          final url = await _uploadMediaFile(file, specialistId);
          mediaUrls.add(url);
        }
      }

      final now = DateTime.now();

      final post = FeedPost(
        id: '',
        specialistId: specialistId,
        specialistName: specialistName,
        specialistPhotoUrl: specialistPhotoUrl,
        content: content,
        mediaUrls: mediaUrls,
        tags: tags ?? [],
        type: type,
        createdAt: now,
        updatedAt: now,
        likes: 0,
        comments: 0,
        shares: 0,
        likedBy: [],
        metadata: {},
      );

      final docRef =
          await _firestore.collection('feed_posts').add(post.toMap());

      return post.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Ошибка создания поста: $e');
    }
  }

  /// Получить ленту новостей
  Future<List<FeedPost>> getFeedPosts({
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      Query query = _firestore
          .collection('feed_posts')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocumentId != null) {
        final lastDoc =
            await _firestore.collection('feed_posts').doc(lastDocumentId).get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => FeedPost.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Ошибка получения ленты: $e');
    }
  }

  /// Получить посты специалиста
  Future<List<FeedPost>> getSpecialistPosts({
    required String specialistId,
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      Query query = _firestore
          .collection('feed_posts')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocumentId != null) {
        final lastDoc =
            await _firestore.collection('feed_posts').doc(lastDocumentId).get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => FeedPost.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Ошибка получения постов специалиста: $e');
    }
  }

  /// Лайкнуть пост
  Future<void> likePost({
    required String postId,
    required String userId,
  }) async {
    try {
      final postDoc = _firestore.collection('feed_posts').doc(postId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(postDoc);
        if (!doc.exists) return;

        final post = FeedPost.fromDocument(doc);
        if (post.likedBy.contains(userId)) return;

        final updatedLikedBy = List<String>.from(post.likedBy)..add(userId);

        transaction.update(postDoc, {
          'likedBy': updatedLikedBy,
          'likes': FieldValue.increment(1),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      });
    } catch (e) {
      throw Exception('Ошибка лайка поста: $e');
    }
  }

  /// Убрать лайк с поста
  Future<void> unlikePost({
    required String postId,
    required String userId,
  }) async {
    try {
      final postDoc = _firestore.collection('feed_posts').doc(postId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(postDoc);
        if (!doc.exists) return;

        final post = FeedPost.fromDocument(doc);
        if (!post.likedBy.contains(userId)) return;

        final updatedLikedBy = List<String>.from(post.likedBy)..remove(userId);

        transaction.update(postDoc, {
          'likedBy': updatedLikedBy,
          'likes': FieldValue.increment(-1),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      });
    } catch (e) {
      throw Exception('Ошибка удаления лайка: $e');
    }
  }

  /// Поделиться постом
  Future<void> sharePost({
    required String postId,
    required String userId,
  }) async {
    try {
      await _firestore.collection('feed_posts').doc(postId).update({
        'shares': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Создаем запись о шаре
      await _firestore.collection('post_shares').add({
        'postId': postId,
        'userId': userId,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка шаринга поста: $e');
    }
  }

  /// Добавить комментарий к посту
  Future<PostComment> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final now = DateTime.now();

      final comment = PostComment(
        id: '',
        postId: postId,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        content: content,
        createdAt: now,
        updatedAt: now,
        likes: 0,
        likedBy: [],
        parentCommentId: parentCommentId,
        replies: [],
      );

      final docRef =
          await _firestore.collection('post_comments').add(comment.toMap());

      // Увеличиваем счетчик комментариев
      await _firestore.collection('feed_posts').doc(postId).update({
        'comments': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(now),
      });

      return comment.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Ошибка добавления комментария: $e');
    }
  }

  /// Получить комментарии к посту
  Future<List<PostComment>> getPostComments({
    required String postId,
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      Query query = _firestore
          .collection('post_comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: false)
          .limit(limit);

      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection('post_comments')
            .doc(lastDocumentId)
            .get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => PostComment.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Ошибка получения комментариев: $e');
    }
  }

  /// Лайкнуть комментарий
  Future<void> likeComment({
    required String commentId,
    required String userId,
  }) async {
    try {
      final commentDoc = _firestore.collection('post_comments').doc(commentId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(commentDoc);
        if (!doc.exists) return;

        final comment = PostComment.fromDocument(doc);
        if (comment.likedBy.contains(userId)) return;

        final updatedLikedBy = List<String>.from(comment.likedBy)..add(userId);

        transaction.update(commentDoc, {
          'likedBy': updatedLikedBy,
          'likes': FieldValue.increment(1),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      });
    } catch (e) {
      throw Exception('Ошибка лайка комментария: $e');
    }
  }

  /// Удалить пост
  Future<void> deletePost(String postId) async {
    try {
      // Получаем информацию о посте
      final postDoc =
          await _firestore.collection('feed_posts').doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Пост не найден');
      }

      final post = FeedPost.fromDocument(postDoc);

      // Удаляем медиа файлы
      for (final mediaUrl in post.mediaUrls) {
        await _deleteMediaFile(mediaUrl);
      }

      // Удаляем комментарии
      final commentsSnapshot = await _firestore
          .collection('post_comments')
          .where('postId', isEqualTo: postId)
          .get();

      for (final commentDoc in commentsSnapshot.docs) {
        await commentDoc.reference.delete();
      }

      // Удаляем шары
      final sharesSnapshot = await _firestore
          .collection('post_shares')
          .where('postId', isEqualTo: postId)
          .get();

      for (final shareDoc in sharesSnapshot.docs) {
        await shareDoc.reference.delete();
      }

      // Удаляем пост
      await _firestore.collection('feed_posts').doc(postId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления поста: $e');
    }
  }

  /// Получить статистику постов специалиста
  Future<FeedStatistics> getSpecialistFeedStatistics(
      String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('feed_posts')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final posts =
          snapshot.docs.map((doc) => FeedPost.fromDocument(doc)).toList();

      final totalPosts = posts.length;
      final totalLikes = posts.fold(0, (sum, post) => sum + post.likes);
      final totalComments = posts.fold(0, (sum, post) => sum + post.comments);
      final totalShares = posts.fold(0, (sum, post) => sum + post.shares);

      return FeedStatistics(
        totalPosts: totalPosts,
        totalLikes: totalLikes,
        totalComments: totalComments,
        totalShares: totalShares,
        averageLikes: totalPosts > 0 ? (totalLikes / totalPosts).round() : 0,
        averageComments:
            totalPosts > 0 ? (totalComments / totalPosts).round() : 0,
      );
    } catch (e) {
      throw Exception('Ошибка получения статистики ленты: $e');
    }
  }

  // Приватные методы

  Future<String> _uploadMediaFile(XFile file, String specialistId) async {
    try {
      final fileName = '${specialistId}/feed/${_uuid.v4()}_${file.name}';
      final ref = _storage.ref().child(fileName);

      final uploadTask = await ref.putFile(File(file.path));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Ошибка загрузки медиа файла: $e');
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

/// Статистика ленты
class FeedStatistics {
  final int totalPosts;
  final int totalLikes;
  final int totalComments;
  final int totalShares;
  final int averageLikes;
  final int averageComments;

  const FeedStatistics({
    required this.totalPosts,
    required this.totalLikes,
    required this.totalComments,
    required this.totalShares,
    required this.averageLikes,
    required this.averageComments,
  });
}
