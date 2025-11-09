import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Сервис для работы с комментариями
class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Получить коллекцию комментариев для контента
  CollectionReference _getCommentsCollection(String contentType, String contentId) {
    return _firestore
        .collection(contentType) // posts, reels, stories, ideas
        .doc(contentId)
        .collection('comments');
  }

  /// Добавить комментарий
  Future<String> addComment({
    required String contentType, // 'posts', 'reels', 'stories', 'ideas'
    required String contentId,
    required String text,
    String? parentId, // для threaded comments
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Получаем данные пользователя
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final authorName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
      final authorPhotoUrl = userData['photoURL'] as String? ?? user.photoURL;

      final commentRef = _getCommentsCollection(contentType, contentId).doc();
      
      await commentRef.set({
        'authorId': user.uid,
        'authorName': authorName.isNotEmpty ? authorName : (user.displayName ?? 'Пользователь'),
        'authorPhotoUrl': authorPhotoUrl,
        'text': text.trim(),
        'parentId': parentId,
        'likesCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugLog("COMMENT_ADD:$contentType:$contentId:${commentRef.id}");
      return commentRef.id;
    } catch (e) {
      debugLog("COMMENT_ADD_ERR:$contentType:$contentId:$e");
      rethrow;
    }
  }

  /// Редактировать комментарий
  Future<void> editComment({
    required String contentType,
    required String contentId,
    required String commentId,
    required String newText,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final commentRef = _getCommentsCollection(contentType, contentId).doc(commentId);
      final commentDoc = await commentRef.get();
      
      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }

      final commentData = commentDoc.data() as Map<String, dynamic>;
      final authorId = commentData['authorId'] as String;

      // Проверяем права: автор комментария или автор контента
      final contentDoc = await _firestore.collection(contentType).doc(contentId).get();
      final contentData = contentDoc.data() ?? {};
      final contentAuthorId = contentData['authorId'] as String?;

      if (authorId != user.uid && contentAuthorId != user.uid) {
        throw Exception('No permission to edit this comment');
      }

      await commentRef.update({
        'text': newText.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugLog("COMMENT_EDIT:$commentId");
    } catch (e) {
      debugLog("COMMENT_EDIT_ERR:$commentId:$e");
      rethrow;
    }
  }

  /// Удалить комментарий
  Future<void> deleteComment({
    required String contentType,
    required String contentId,
    required String commentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final commentRef = _getCommentsCollection(contentType, contentId).doc(commentId);
      final commentDoc = await commentRef.get();
      
      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }

      final commentData = commentDoc.data() as Map<String, dynamic>;
      final authorId = commentData['authorId'] as String;

      // Проверяем права: автор комментария или автор контента
      final contentDoc = await _firestore.collection(contentType).doc(contentId).get();
      final contentData = contentDoc.data() ?? {};
      final contentAuthorId = contentData['authorId'] as String?;

      if (authorId != user.uid && contentAuthorId != user.uid) {
        throw Exception('No permission to delete this comment');
      }

      await commentRef.delete();

      debugLog("COMMENT_DELETE:$commentId");
    } catch (e) {
      debugLog("COMMENT_DELETE_ERR:$commentId:$e");
      rethrow;
    }
  }

  /// Лайкнуть/снять лайк с комментария
  Future<void> toggleLike({
    required String contentType,
    required String contentId,
    required String commentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final commentRef = _getCommentsCollection(contentType, contentId).doc(commentId);
      final commentDoc = await commentRef.get();
      
      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }

      final commentData = commentDoc.data() as Map<String, dynamic>;
      final likes = List<String>.from(commentData['likes'] ?? []);
      final isLiked = likes.contains(user.uid);

      if (isLiked) {
        likes.remove(user.uid);
        debugLog("COMMENT_UNLIKE:$commentId");
      } else {
        likes.add(user.uid);
        debugLog("COMMENT_LIKE:$commentId");
      }

      await commentRef.update({
        'likes': likes,
        'likesCount': likes.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugLog("COMMENT_LIKE_ERR:$commentId:$e");
      rethrow;
    }
  }

  /// Получить поток комментариев
  Stream<QuerySnapshot> getCommentsStream({
    required String contentType,
    required String contentId,
    String? parentId, // null для корневых комментариев
  }) {
    Query query = _getCommentsCollection(contentType, contentId)
        .orderBy('createdAt', descending: false);

    if (parentId != null) {
      query = query.where('parentId', isEqualTo: parentId);
    } else {
      query = query.where('parentId', isNull: true);
    }

    return query.snapshots();
  }
}

