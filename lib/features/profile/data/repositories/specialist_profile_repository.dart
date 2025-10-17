import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/specialist_profile.dart';

/// Репозиторий для работы с профилями специалистов
class SpecialistProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Сохранение профиля специалиста
  Future<void> saveSpecialistProfile(SpecialistProfileForm profile) async {
    try {
      final docRef = _firestore.collection('specialists').doc(profile.id);

      // Используем merge: true для обновления существующих полей
      await docRef.set(profile.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Ошибка сохранения профиля специалиста: $e');
    }
  }

  /// Получение профиля специалиста по ID
  Future<SpecialistProfileForm?> getSpecialistProfile(
    String specialistId,
  ) async {
    try {
      final doc = await _firestore.collection('specialists').doc(specialistId).get();

      if (doc.exists && doc.data() != null) {
        return SpecialistProfileForm.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения профиля специалиста: $e');
    }
  }

  /// Загрузка изображения в Storage
  Future<String> uploadImage(
    File imageFile,
    String specialistId,
    String type,
  ) async {
    try {
      final fileName = '${specialistId}_${type}_${DateTime.now().millisecondsSinceEpoch}';
      final ref = _storage.ref().child('specialists/$specialistId/$fileName');

      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Ошибка загрузки изображения: $e');
    }
  }

  /// Удаление изображения из Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Игнорируем ошибки удаления - файл может не существовать
      debugPrint('Ошибка удаления изображения: $e');
    }
  }

  /// Обновление URL изображения в профиле
  Future<void> updateImageUrl(
    String specialistId,
    String imageUrl,
    String type,
  ) async {
    try {
      final docRef = _firestore.collection('specialists').doc(specialistId);

      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (type == 'avatar') {
        updateData['imageUrl'] = imageUrl;
      } else if (type == 'cover') {
        updateData['coverUrl'] = imageUrl;
      }

      await docRef.update(updateData);
    } catch (e) {
      throw Exception('Ошибка обновления URL изображения: $e');
    }
  }

  /// Проверка существования профиля специалиста
  Future<bool> profileExists(String specialistId) async {
    try {
      final doc = await _firestore.collection('specialists').doc(specialistId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Ошибка проверки существования профиля: $e');
    }
  }

  /// Получение списка всех специалистов
  Future<List<SpecialistProfileForm>> getAllSpecialists() async {
    try {
      final querySnapshot = await _firestore.collection('specialists').get();

      return querySnapshot.docs.map((doc) => SpecialistProfileForm.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Ошибка получения списка специалистов: $e');
    }
  }

  /// Удаление профиля специалиста
  Future<void> deleteSpecialistProfile(String specialistId) async {
    try {
      await _firestore.collection('specialists').doc(specialistId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления профиля специалиста: $e');
    }
  }
}
