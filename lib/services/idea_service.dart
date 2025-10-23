import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/idea.dart';

/// Service for managing ideas
class IdeaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage? _storage = kIsWeb ? null : FirebaseStorage.instance;
  static const String _collection = 'ideas';

  /// Get all ideas with pagination
  Future<List<Idea>> getIdeas(
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
      return snapshot.docs.map((doc) => Idea.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting ideas: $e');
      return [];
    }
  }

  /// Get ideas by category
  Future<List<Idea>> getIdeasByCategory(String category,
      {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Idea.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting ideas by category: $e');
      return [];
    }
  }

  /// Get ideas by tags
  Future<List<Idea>> getIdeasByTags(List<String> tags, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('tags', arrayContainsAny: tags)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Idea.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting ideas by tags: $e');
      return [];
    }
  }

  /// Get ideas by difficulty
  Future<List<Idea>> getIdeasByDifficulty(String difficulty,
      {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('difficulty', isEqualTo: difficulty)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Idea.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting ideas by difficulty: $e');
      return [];
    }
  }

  /// Get popular ideas (by likes)
  Future<List<Idea>> getPopularIdeas({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('likesCount', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Idea.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting popular ideas: $e');
      return [];
    }
  }

  /// Get trending ideas (by recent views)
  Future<List<Idea>> getTrendingIdeas({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('viewsCount', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Idea.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting trending ideas: $e');
      return [];
    }
  }

  /// Create a new idea
  Future<String?> createIdea({
    required String title,
    required String shortDesc,
    String? mediaUrl,
    List<String>? tags,
    String? authorId,
    String? authorName,
    String? category,
    String? difficulty,
    int? estimatedDuration,
    List<String>? requiredMaterials,
    String? detailedDescription,
  }) async {
    try {
      final idea = Idea(
        id: '', // Will be set by Firestore
        title: title,
        shortDesc: shortDesc,
        mediaUrl: mediaUrl,
        tags: tags ?? [],
        authorId: authorId,
        authorName: authorName,
        category: category,
        difficulty: difficulty,
        estimatedDuration: estimatedDuration,
        requiredMaterials: requiredMaterials ?? [],
        detailedDescription: detailedDescription,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef =
          await _firestore.collection(_collection).add(idea.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating idea: $e');
      return null;
    }
  }

  /// Update an idea
  Future<bool> updateIdea(String ideaId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(ideaId).update({
        ...updates,
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating idea: $e');
      return false;
    }
  }

  /// Delete an idea
  Future<bool> deleteIdea(String ideaId) async {
    try {
      await _firestore.collection(_collection).doc(ideaId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting idea: $e');
      return false;
    }
  }

  /// Like an idea
  Future<bool> likeIdea(String ideaId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(ideaId).update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error liking idea: $e');
      return false;
    }
  }

  /// Unlike an idea
  Future<bool> unlikeIdea(String ideaId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(ideaId).update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likesCount': FieldValue.increment(-1),
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error unliking idea: $e');
      return false;
    }
  }

  /// Save idea to user's favorites
  Future<bool> saveIdea(String ideaId, String userId) async {
    try {
      await _firestore
          .collection('user_favorites')
          .doc('${userId}_$ideaId')
          .set({
        'userId': userId,
        'ideaId': ideaId,
        'savedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error saving idea: $e');
      return false;
    }
  }

  /// Remove idea from user's favorites
  Future<bool> unsaveIdea(String ideaId, String userId) async {
    try {
      await _firestore
          .collection('user_favorites')
          .doc('${userId}_$ideaId')
          .delete();
      return true;
    } catch (e) {
      debugPrint('Error unsaving idea: $e');
      return false;
    }
  }

  /// Increment view count
  Future<bool> incrementViewCount(String ideaId) async {
    try {
      await _firestore.collection(_collection).doc(ideaId).update({
        'viewsCount': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
      return false;
    }
  }

  /// Get idea by ID
  Future<Idea?> getIdeaById(String ideaId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(ideaId).get();
      if (doc.exists) {
        return Idea.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting idea by ID: $e');
      return null;
    }
  }

  /// Search ideas
  Future<List<Idea>> searchIdeas(String query, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final ideas =
          snapshot.docs.map((doc) => Idea.fromFirestore(doc)).toList();

      // Filter ideas that contain the query in title, description, or tags
      return ideas.where((idea) {
        final searchQuery = query.toLowerCase();
        return idea.title.toLowerCase().contains(searchQuery) ||
            idea.shortDesc.toLowerCase().contains(searchQuery) ||
            idea.tags.any((tag) => tag.toLowerCase().contains(searchQuery)) ||
            (idea.category?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    } catch (e) {
      debugPrint('Error searching ideas: $e');
      return [];
    }
  }

  /// Get available categories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final categories = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return [];
    }
  }

  /// Get available tags
  Future<List<String>> getTags() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final tags = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final ideaTags = data['tags'] as List<dynamic>?;
        if (ideaTags != null) {
          for (final tag in ideaTags) {
            if (tag is String && tag.isNotEmpty) {
              tags.add(tag);
            }
          }
        }
      }

      return tags.toList()..sort();
    } catch (e) {
      debugPrint('Error getting tags: $e');
      return [];
    }
  }

  /// Upload media file
  Future<String?> uploadMedia(String filePath, String fileName) async {
    if (_storage == null) {
      debugPrint('Firebase Storage not available on web');
      return null;
    }
    try {
      final ref = _storage.ref().child('ideas/$fileName');
      final uploadTask =
          await ref.putFile(filePath as dynamic); // In real app, use File
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading media: $e');
      return null;
    }
  }

  /// Stream of ideas (for real-time updates)
  Stream<List<Idea>> getIdeasStream({int limit = 20}) {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Idea.fromFirestore(doc)).toList());
  }

  /// Stream of ideas by category
  Stream<List<Idea>> getIdeasByCategoryStream(String category,
      {int limit = 20}) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Idea.fromFirestore(doc)).toList());
  }

  /// Get idea statistics
  Future<Map<String, int>> getIdeaStats(String ideaId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(ideaId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'likes': data['likesCount'] ?? 0,
          'views': data['viewsCount'] ?? 0
        };
      }
      return {'likes': 0, 'views': 0};
    } catch (e) {
      debugPrint('Error getting idea stats: $e');
      return {'likes': 0, 'views': 0};
    }
  }
}
