import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/post.dart';

/// Service for managing posts
class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage? _storage = kIsWeb ? null : FirebaseStorage.instance;
  static const String _collection = 'posts';

  /// Get all posts with pagination
  Future<List<Post>> getPosts(
      {int limit = 20, DocumentSnapshot? lastDocument}) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting posts: $e');
      return [];
    }
  }

  /// Get posts by user
  Future<List<Post>> getPostsByUser(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting posts by user: $e');
      return [];
    }
  }

  /// Get posts by specialist
  Future<List<Post>> getPostsBySpecialist(String specialistId,
      {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('authorId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting posts by specialist: $e');
      return [];
    }
  }

  /// Get posts by tags
  Future<List<Post>> getPostsByTags(List<String> tags, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('tags', arrayContainsAny: tags)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting posts by tags: $e');
      return [];
    }
  }

  /// Create a new post
  Future<String?> createPost({
    required String authorId,
    String? text,
    String? mediaUrl,
    MediaType? mediaType,
    List<String>? tags,
    String? location,
    String? authorName,
    String? authorAvatarUrl,
  }) async {
    try {
      final post = Post(
        id: '', // Will be set by Firestore
        authorId: authorId,
        text: text,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        tags: tags ?? [],
        location: location,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef =
          await _firestore.collection(_collection).add(post.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating post: $e');
      return null;
    }
  }

  /// Update a post
  Future<bool> updatePost(String postId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(postId).update({
        ...updates,
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating post: $e');
      return false;
    }
  }

  /// Delete a post
  Future<bool> deletePost(String postId) async {
    try {
      await _firestore.collection(_collection).doc(postId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting post: $e');
      return false;
    }
  }

  /// Like a post
  Future<bool> likePost(String postId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(postId).update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error liking post: $e');
      return false;
    }
  }

  /// Unlike a post
  Future<bool> unlikePost(String postId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(postId).update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likesCount': FieldValue.increment(-1),
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error unliking post: $e');
      return false;
    }
  }

  /// Toggle like on a post
  Future<bool> toggleLike(String postId, String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(postId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);

      if (likedBy.contains(userId)) {
        // Unlike
        await _firestore.collection(_collection).doc(postId).update({
          'likedBy': FieldValue.arrayRemove([userId]),
          'likesCount': FieldValue.increment(-1),
          'updatedAt': DateTime.now(),
        });
      } else {
        // Like
        await _firestore.collection(_collection).doc(postId).update({
          'likedBy': FieldValue.arrayUnion([userId]),
          'likesCount': FieldValue.increment(1),
          'updatedAt': DateTime.now(),
        });
      }
      return true;
    } catch (e) {
      debugPrint('Error toggling like: $e');
      return false;
    }
  }

  /// Get post by ID
  Future<Post?> getPostById(String postId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(postId).get();
      if (doc.exists) {
        return Post.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting post by ID: $e');
      return null;
    }
  }

  /// Upload media file
  Future<String?> uploadMedia(String filePath, String fileName) async {
    if (_storage == null) {
      debugPrint('Firebase Storage not available on web');
      return null;
    }
    try {
      final ref = _storage.ref().child('posts/$fileName');
      final uploadTask =
          await ref.putFile(filePath as dynamic); // In real app, use File
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading media: $e');
      return null;
    }
  }

  /// Get popular posts (by likes)
  Future<List<Post>> getPopularPosts({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('likesCount', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting popular posts: $e');
      return [];
    }
  }

  /// Get trending posts (by recent likes)
  Future<List<Post>> getTrendingPosts({int limit = 10}) async {
    try {
      // Get posts from last 7 days with most likes
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection(_collection)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
          .orderBy('createdAt', descending: true)
          .orderBy('likesCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting trending posts: $e');
      return [];
    }
  }

  /// Search posts
  Future<List<Post>> searchPosts(String query, {int limit = 20}) async {
    try {
      // Note: This is a simple text search. For better search, consider using Algolia or similar
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final posts =
          snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();

      // Filter posts that contain the query in text or tags
      return posts.where((post) {
        final searchQuery = query.toLowerCase();
        return (post.text?.toLowerCase().contains(searchQuery) ?? false) ||
            post.tags.any((tag) => tag.toLowerCase().contains(searchQuery));
      }).toList();
    } catch (e) {
      debugPrint('Error searching posts: $e');
      return [];
    }
  }

  /// Stream of posts (for real-time updates)
  Stream<List<Post>> getPostsStream({int limit = 20}) {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList());
  }

  /// Stream of posts by user
  Stream<List<Post>> getPostsByUserStream(String userId, {int limit = 20}) {
    return _firestore
        .collection(_collection)
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList());
  }

  /// Get post statistics
  Future<Map<String, int>> getPostStats(String postId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(postId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'likes': data['likesCount'] ?? 0,
          'comments': data['commentsCount'] ?? 0
        };
      }
      return {'likes': 0, 'comments': 0};
    } catch (e) {
      debugPrint('Error getting post stats: $e');
      return {'likes': 0, 'comments': 0};
    }
  }

  /// Increment comment count
  Future<bool> incrementCommentCount(String postId) async {
    try {
      await _firestore.collection(_collection).doc(postId).update({
        'commentsCount': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error incrementing comment count: $e');
      return false;
    }
  }

  /// Decrement comment count
  Future<bool> decrementCommentCount(String postId) async {
    try {
      await _firestore.collection(_collection).doc(postId).update({
        'commentsCount': FieldValue.increment(-1),
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error decrementing comment count: $e');
      return false;
    }
  }
}
