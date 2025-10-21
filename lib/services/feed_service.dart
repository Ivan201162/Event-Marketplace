import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post.dart';
import '../models/feed_comment.dart';

/// Feed service for managing posts and comments
class FeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get posts stream
  Stream<List<Post>> getPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList());
  }

  /// Get post comments stream
  Stream<List<FeedComment>> getPostComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FeedComment.fromFirestore(doc)).toList());
  }

  /// Create a new post
  Future<String> createPost(Post post) async {
    final docRef = await _firestore.collection('posts').add(post.toFirestore());
    return docRef.id;
  }

  /// Update a post
  Future<void> updatePost(String postId, Post post) async {
    await _firestore.collection('posts').doc(postId).update(post.toFirestore());
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  /// Like/unlike a post
  Future<void> toggleLike(String postId, String userId) async {
    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      if (!postDoc.exists) return;

      final post = Post.fromFirestore(postDoc);
      final likedBy = List<String>.from(post.likedBy);

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }

      transaction.update(postRef, {
        'likedBy': likedBy,
        'likesCount': likedBy.length,
      });
    });
  }

  /// Add a comment to a post
  Future<String> addComment(String postId, FeedComment comment) async {
    final docRef = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add(comment.toFirestore());

    // Update post comments count
    await _firestore.collection('posts').doc(postId).update({
      'commentsCount': FieldValue.increment(1),
    });

    return docRef.id;
  }

  /// Like/unlike a comment
  Future<void> toggleCommentLike(String postId, String commentId, String userId) async {
    final commentRef =
        _firestore.collection('posts').doc(postId).collection('comments').doc(commentId);

    await _firestore.runTransaction((transaction) async {
      final commentDoc = await transaction.get(commentRef);
      if (!commentDoc.exists) return;

      final comment = FeedComment.fromFirestore(commentDoc);
      final likedBy = List<String>.from(comment.likedBy);

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }

      transaction.update(commentRef, {
        'likedBy': likedBy,
        'likesCount': likedBy.length,
      });
    });
  }

  /// Delete a comment
  Future<void> deleteComment(String postId, String commentId) async {
    await _firestore.collection('posts').doc(postId).collection('comments').doc(commentId).delete();

    // Update post comments count
    await _firestore.collection('posts').doc(postId).update({
      'commentsCount': FieldValue.increment(-1),
    });
  }
}
