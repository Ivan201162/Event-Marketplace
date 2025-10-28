import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:event_marketplace_app/features/profile/data/models/specialist_profile.dart';

/// Репозиторий для работы с профилями специалистов
class SpecialistProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'specialist_profiles';

  /// Получить профиль специалиста по ID
  Future<SpecialistProfile?> getProfileById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return SpecialistProfile.fromDocument(doc);
    } catch (e) {
      throw Exception('Ошибка получения профиля: $e');
    }
  }

  /// Получить профиль специалиста по userId
  Future<SpecialistProfile?> getProfileByUserId(String userId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return SpecialistProfile.fromDocument(query.docs.first);
    } catch (e) {
      throw Exception('Ошибка получения профиля: $e');
    }
  }

  /// Создать новый профиль специалиста
  Future<String> createProfile(SpecialistProfile profile) async {
    try {
      final docRef =
          await _firestore.collection(_collection).add(profile.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания профиля: $e');
    }
  }

  /// Обновить профиль специалиста
  Future<void> updateProfile(String id, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(id).update(updates);
    } catch (e) {
      throw Exception('Ошибка обновления профиля: $e');
    }
  }

  /// Удалить профиль специалиста
  Future<void> deleteProfile(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Ошибка удаления профиля: $e');
    }
  }

  /// Получить все профили специалистов
  Future<List<SpecialistProfile>> getAllProfiles() async {
    try {
      final query = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map(SpecialistProfile.fromDocument)
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения профилей: $e');
    }
  }

  /// Получить профили по категории
  Future<List<SpecialistProfile>> getProfilesByCategory(String category) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map(SpecialistProfile.fromDocument)
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения профилей по категории: $e');
    }
  }

  /// Получить профили по городу
  Future<List<SpecialistProfile>> getProfilesByCity(String city) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('city', isEqualTo: city)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map(SpecialistProfile.fromDocument)
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения профилей по городу: $e');
    }
  }
}
