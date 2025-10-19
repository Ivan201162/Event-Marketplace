import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/specialist_profile.dart';

/// Репозиторий для работы с профилями специалистов
class SpecialistProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'specialist_profiles';

  /// Получить профиль специалиста по ID
  Future<SpecialistProfile?> getProfile(String specialistId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(specialistId).get();
      if (doc.exists) {
        return SpecialistProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting specialist profile: $e');
      return null;
    }
  }

  /// Получить профиль специалиста по ID пользователя
  Future<SpecialistProfile?> getProfileByUserId(String userId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return SpecialistProfile.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting specialist profile by user ID: $e');
      return null;
    }
  }

  /// Создать профиль специалиста
  Future<bool> createProfile(SpecialistProfile profile) async {
    try {
      await _firestore.collection(_collection).doc(profile.id).set(profile.toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error creating specialist profile: $e');
      return false;
    }
  }

  /// Обновить профиль специалиста
  Future<bool> updateProfile(String specialistId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_collection).doc(specialistId).update(updates);
      return true;
    } catch (e) {
      debugPrint('Error updating specialist profile: $e');
      return false;
    }
  }

  /// Удалить профиль специалиста
  Future<bool> deleteProfile(String specialistId) async {
    try {
      await _firestore.collection(_collection).doc(specialistId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting specialist profile: $e');
      return false;
    }
  }

  /// Получить список профилей специалистов по категориям
  Future<List<SpecialistProfile>> getProfilesByCategories(List<String> categories) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('categories', arrayContainsAny: categories)
          .orderBy('rating', descending: true)
          .limit(50)
          .get();
      
      return query.docs.map((doc) => SpecialistProfile.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting profiles by categories: $e');
      return [];
    }
  }

  /// Получить топ специалистов
  Future<List<SpecialistProfile>> getTopSpecialists({int limit = 10}) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .orderBy('rating', descending: true)
          .orderBy('reviewCount', descending: true)
          .limit(limit)
          .get();
      
      return query.docs.map((doc) => SpecialistProfile.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting top specialists: $e');
      return [];
    }
  }
}
