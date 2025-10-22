import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/story_content_type.dart';

/// Сервис для работы с историями
class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Выбор изображения из галереи
  Future<File?> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      print('Ошибка выбора изображения: $e');
      return null;
    }
  }

  /// Выбор видео из галереи
  Future<File?> pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      return video != null ? File(video.path) : null;
    } catch (e) {
      print('Ошибка выбора видео: $e');
      return null;
    }
  }

  /// Съемка фото
  Future<File?> takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      print('Ошибка съемки фото: $e');
      return null;
    }
  }

  /// Запись видео
  Future<File?> recordVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2),
      );
      return video != null ? File(video.path) : null;
    } catch (e) {
      print('Ошибка записи видео: $e');
      return null;
    }
  }

  /// Загрузка изображения истории
  Future<String?> uploadStoryImage(File imageFile, String userId) async {
    try {
      final String fileName = 'stories/${userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child(fileName);
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Ошибка загрузки изображения: $e');
      return null;
    }
  }

  /// Загрузка видео истории
  Future<String?> uploadStoryVideo(File videoFile, String userId) async {
    try {
      final String fileName = 'stories/${userId}/${DateTime.now().millisecondsSinceEpoch}.mp4';
      final Reference ref = _storage.ref().child(fileName);
      
      final UploadTask uploadTask = ref.putFile(videoFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Ошибка загрузки видео: $e');
      return null;
    }
  }

  /// Создание истории
  Future<bool> createStory({
    required String specialistId,
    required String mediaUrl,
    required String text,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      await _firestore.collection('stories').add({
        'specialistId': specialistId,
        'mediaUrl': mediaUrl,
        'text': text,
        'metadata': metadata,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        'views': 0,
        'likes': 0,
        'type': StoryContentType.text.toString(),
      });
      return true;
    } catch (e) {
      print('Ошибка создания истории: $e');
      return false;
    }
  }

  /// Получение историй специалиста
  Stream<List<Map<String, dynamic>>> getSpecialistStories(String specialistId) {
    return _firestore
        .collection('stories')
        .where('specialistId', isEqualTo: specialistId)
        .where('expiresAt', isGreaterThan: DateTime.now().toIso8601String())
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Удаление истории
  Future<bool> deleteStory(String storyId) async {
    try {
      await _firestore.collection('stories').doc(storyId).delete();
      return true;
    } catch (e) {
      print('Ошибка удаления истории: $e');
      return false;
    }
  }

  /// Получение историй специалиста (alias для getSpecialistStories)
  Stream<List<Map<String, dynamic>>> getStoriesBySpecialist(String specialistId) {
    return getSpecialistStories(specialistId);
  }
}