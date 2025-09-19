import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

/// Сервис для работы с Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Загрузить изображение профиля пользователя
  Future<String> uploadProfileImage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      // Получаем расширение файла
      final fileExtension = path.extension(imageFile.path);
      final fileName = 'profile_${user.uid}$fileExtension';

      // Создаем ссылку на файл в Storage
      final ref = _storage.ref().child('profile_images').child(fileName);

      // Загружаем файл
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Ждем завершения загрузки
      final snapshot = await uploadTask;

      // Получаем URL загруженного файла
      final downloadURL = await snapshot.ref.getDownloadURL();

      return downloadURL;
    } catch (e) {
      throw Exception('Ошибка загрузки изображения: $e');
    }
  }

  /// Удалить изображение профиля
  Future<void> deleteProfileImage(String imageURL) async {
    try {
      // Извлекаем путь к файлу из URL
      final ref = _storage.refFromURL(imageURL);
      await ref.delete();
    } catch (e) {
      throw Exception('Ошибка удаления изображения: $e');
    }
  }

  /// Загрузить изображение события
  Future<String> uploadEventImage(File imageFile, String eventId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      final fileExtension = path.extension(imageFile.path);
      final fileName =
          'event_${eventId}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';

      final ref = _storage.ref().child('event_images').child(fileName);

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'eventId': eventId,
            'uploadedBy': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadURL = await snapshot.ref.getDownloadURL();

      return downloadURL;
    } catch (e) {
      throw Exception('Ошибка загрузки изображения события: $e');
    }
  }

  /// Загрузить несколько изображений события
  Future<List<String>> uploadEventImages(
    List<File> imageFiles,
    String eventId,
  ) async {
    final urls = <String>[];

    for (var i = 0; i < imageFiles.length; i++) {
      final url = await uploadEventImage(imageFiles[i], '${eventId}_$i');
      urls.add(url);
    }

    return urls;
  }

  /// Получить размер файла
  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    return file.length();
  }

  /// Проверить, является ли файл изображением
  bool isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension);
  }

  /// Сжать изображение (базовая реализация)
  Future<File> compressImage(File imageFile) async {
    // В реальном приложении здесь можно использовать пакет image
    // для сжатия изображения
    return imageFile;
  }
}
