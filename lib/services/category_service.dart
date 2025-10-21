import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/idea_category.dart';
import '../models/specialist_category.dart';

/// Service for managing categories
class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _ideaCategoriesCollection = 'categories';
  static const String _specialistCategoriesCollection = 'specialist_categories';

  /// Get all idea categories
  Future<List<IdeaCategory>> getIdeaCategories() async {
    try {
      final snapshot = await _firestore
          .collection(_ideaCategoriesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      return snapshot.docs.map((doc) => IdeaCategory.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting idea categories: $e');
      return [];
    }
  }

  /// Get featured idea categories
  Future<List<IdeaCategory>> getFeaturedIdeaCategories() async {
    try {
      final snapshot = await _firestore
          .collection(_ideaCategoriesCollection)
          .where('isActive', isEqualTo: true)
          .where('isFeatured', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      return snapshot.docs.map((doc) => IdeaCategory.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting featured idea categories: $e');
      return [];
    }
  }

  /// Get specialist categories
  Future<List<SpecialistCategory>> getSpecialistCategories() async {
    try {
      final snapshot = await _firestore
          .collection(_specialistCategoriesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SpecialistCategory.fromMap({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      debugPrint('Error getting specialist categories: $e');
      return [];
    }
  }

  /// Get category by ID
  Future<IdeaCategory?> getIdeaCategoryById(String categoryId) async {
    try {
      final doc = await _firestore
          .collection(_ideaCategoriesCollection)
          .doc(categoryId)
          .get();

      if (doc.exists) {
        return IdeaCategory.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting idea category by ID: $e');
      return null;
    }
  }

  /// Get specialist category by ID
  Future<SpecialistCategory?> getSpecialistCategoryById(String categoryId) async {
    try {
      final doc = await _firestore
          .collection(_specialistCategoriesCollection)
          .doc(categoryId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return SpecialistCategory.fromMap({'id': doc.id, ...data});
      }
      return null;
    } catch (e) {
      debugPrint('Error getting specialist category by ID: $e');
      return null;
    }
  }

  /// Create idea category (admin only)
  Future<String?> createIdeaCategory(IdeaCategory category) async {
    try {
      final docRef = await _firestore
          .collection(_ideaCategoriesCollection)
          .add(category.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating idea category: $e');
      return null;
    }
  }

  /// Create specialist category (admin only)
  Future<String?> createSpecialistCategory(SpecialistCategory category) async {
    try {
      final docRef = await _firestore
          .collection(_specialistCategoriesCollection)
          .add(category.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating specialist category: $e');
      return null;
    }
  }

  /// Update idea category (admin only)
  Future<bool> updateIdeaCategory(String categoryId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(_ideaCategoriesCollection)
          .doc(categoryId)
          .update({
        ...updates,
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating idea category: $e');
      return false;
    }
  }

  /// Update specialist category (admin only)
  Future<bool> updateSpecialistCategory(String categoryId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(_specialistCategoriesCollection)
          .doc(categoryId)
          .update({
        ...updates,
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating specialist category: $e');
      return false;
    }
  }

  /// Delete idea category (admin only)
  Future<bool> deleteIdeaCategory(String categoryId) async {
    try {
      await _firestore
          .collection(_ideaCategoriesCollection)
          .doc(categoryId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting idea category: $e');
      return false;
    }
  }

  /// Delete specialist category (admin only)
  Future<bool> deleteSpecialistCategory(String categoryId) async {
    try {
      await _firestore
          .collection(_specialistCategoriesCollection)
          .doc(categoryId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting specialist category: $e');
      return false;
    }
  }

  /// Stream of idea categories
  Stream<List<IdeaCategory>> getIdeaCategoriesStream() {
    return _firestore
        .collection(_ideaCategoriesCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => IdeaCategory.fromFirestore(doc)).toList());
  }

  /// Stream of specialist categories
  Stream<List<SpecialistCategory>> getSpecialistCategoriesStream() {
    return _firestore
        .collection(_specialistCategoriesCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return SpecialistCategory.fromMap({'id': doc.id, ...data});
        }).toList());
  }

  /// Search categories by name
  Future<List<IdeaCategory>> searchIdeaCategories(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_ideaCategoriesCollection)
          .where('isActive', isEqualTo: true)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .get();

      return snapshot.docs.map((doc) => IdeaCategory.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error searching idea categories: $e');
      return [];
    }
  }

  /// Search specialist categories by name
  Future<List<SpecialistCategory>> searchSpecialistCategories(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_specialistCategoriesCollection)
          .where('isActive', isEqualTo: true)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SpecialistCategory.fromMap({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      debugPrint('Error searching specialist categories: $e');
      return [];
    }
  }
}
