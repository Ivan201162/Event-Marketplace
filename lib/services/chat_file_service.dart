import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/app_constants.dart';
import '../core/feature_flags.dart';

/// Сервис для работы с файлами в чате
class ChatFileService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Загрузить файл в чат
  Future<String> uploadChatFile({
    required String chatId,
    required String senderId,
    required File file,
    required String fileName,
    String? thumbnailPath,
  }) async {
    if (!FeatureFlags.chatFileUploadEnabled) {
      throw Exception('Загрузка файлов в чат отключена');
    }

    try {
      // Проверяем размер файла
      final fileSize = await file.length();
      if (!_isFileSizeValid(fileName, fileSize)) {
        throw Exception('Файл слишком большой');
      }

      // Проверяем тип файла
      if (!_isFileTypeAllowed(fileName)) {
        throw Exception('Тип файла не поддерживается');
      }

      // Создаем путь для файла
      final fileExtension = fileName.split('.').last.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileNameWithTimestamp = '${timestamp}_$fileName';
      final filePath = 'chat_files/$chatId/$fileNameWithTimestamp';

      // Загружаем файл
      final ref = _storage.ref().child(filePath);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Загружаем миниатюру, если есть
      String? thumbnailUrl;
      if (thumbnailPath != null) {
        final thumbnailFile = File(thumbnailPath);
        final thumbnailRef = _storage.ref().child(
              'chat_files/$chatId/thumbnails/${timestamp}_${fileName.split('.').first}_thumb.jpg',
            );
        final thumbnailUploadTask = thumbnailRef.putFile(thumbnailFile);
        final thumbnailSnapshot = await thumbnailUploadTask;
        thumbnailUrl = await thumbnailSnapshot.ref.getDownloadURL();
      }

      return downloadUrl;
    } catch (e) {
      throw Exception('Ошибка загрузки файла: $e');
    }
  }

  /// Загрузить файл из байтов
  Future<String> uploadChatFileFromBytes({
    required String chatId,
    required String senderId,
    required Uint8List bytes,
    required String fileName,
    Uint8List? thumbnailBytes,
  }) async {
    if (!FeatureFlags.chatFileUploadEnabled) {
      throw Exception('Загрузка файлов в чат отключена');
    }

    try {
      // Проверяем размер файла
      if (!_isFileSizeValid(fileName, bytes.length)) {
        throw Exception('Файл слишком большой');
      }

      // Проверяем тип файла
      if (!_isFileTypeAllowed(fileName)) {
        throw Exception('Тип файла не поддерживается');
      }

      // Создаем путь для файла
      final fileExtension = fileName.split('.').last.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileNameWithTimestamp = '${timestamp}_$fileName';
      final filePath = 'chat_files/$chatId/$fileNameWithTimestamp';

      // Загружаем файл
      final ref = _storage.ref().child(filePath);
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Загружаем миниатюру, если есть
      String? thumbnailUrl;
      if (thumbnailBytes != null) {
        final thumbnailRef = _storage.ref().child(
              'chat_files/$chatId/thumbnails/${timestamp}_${fileName.split('.').first}_thumb.jpg',
            );
        final thumbnailUploadTask = thumbnailRef.putData(thumbnailBytes);
        final thumbnailSnapshot = await thumbnailUploadTask;
        thumbnailUrl = await thumbnailSnapshot.ref.getDownloadURL();
      }

      return downloadUrl;
    } catch (e) {
      throw Exception('Ошибка загрузки файла: $e');
    }
  }

  /// Удалить файл из чата
  Future<void> deleteChatFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Ошибка удаления файла: $e');
    }
  }

  /// Получить информацию о файле
  Future<Map<String, dynamic>> getFileInfo(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      final metadata = await ref.getMetadata();

      return {
        'name': metadata.name,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'timeCreated': metadata.timeCreated,
        'updated': metadata.updated,
      };
    } catch (e) {
      throw Exception('Ошибка получения информации о файле: $e');
    }
  }

  /// Проверить, валиден ли размер файла
  bool _isFileSizeValid(String fileName, int fileSize) {
    final extension = fileName.split('.').last.toLowerCase();

    // Ограничения по размеру в зависимости от типа файла
    if (AppConstants.supportedImageFormats.contains(extension)) {
      return fileSize <= AppConstants.maxImageUploadSizeMB * 1024 * 1024;
    } else if (AppConstants.supportedVideoFormats.contains(extension)) {
      return fileSize <= AppConstants.maxVideoUploadSizeMB * 1024 * 1024;
    } else if (AppConstants.supportedAudioFormats.contains(extension)) {
      return fileSize <= AppConstants.maxAudioUploadSizeMB * 1024 * 1024;
    } else if (AppConstants.supportedDocumentFormats.contains(extension)) {
      return fileSize <= 10 * 1024 * 1024; // 10MB для документов
    }

    return false;
  }

  /// Проверить, разрешен ли тип файла
  bool _isFileTypeAllowed(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    return AppConstants.supportedImageFormats.contains(extension) ||
        AppConstants.supportedVideoFormats.contains(extension) ||
        AppConstants.supportedAudioFormats.contains(extension) ||
        AppConstants.supportedDocumentFormats.contains(extension);
  }

  /// Получить поддерживаемые типы файлов
  Map<String, List<String>> getSupportedFileTypes() => {
        'Изображения': AppConstants.supportedImageFormats,
        'Видео': AppConstants.supportedVideoFormats,
        'Аудио': AppConstants.supportedAudioFormats,
        'Документы': AppConstants.supportedDocumentFormats,
      };

  /// Получить максимальный размер файла для типа
  int getMaxFileSizeForType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    if (AppConstants.supportedImageFormats.contains(extension)) {
      return AppConstants.maxImageUploadSizeMB;
    } else if (AppConstants.supportedVideoFormats.contains(extension)) {
      return AppConstants.maxVideoUploadSizeMB;
    } else if (AppConstants.supportedAudioFormats.contains(extension)) {
      return AppConstants.maxAudioUploadSizeMB;
    } else if (AppConstants.supportedDocumentFormats.contains(extension)) {
      return 10; // 10MB для документов
    }

    return 0;
  }

  /// Создать миниатюру для изображения
  Future<Uint8List?> createImageThumbnail(Uint8List imageBytes) async {
    try {
      // TODO: Реализовать создание миниатюры изображения
      // Пока возвращаем null
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Создать миниатюру для видео
  Future<Uint8List?> createVideoThumbnail(String videoPath) async {
    try {
      // TODO: Реализовать создание миниатюры видео
      // Пока возвращаем null
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Получить прогресс загрузки файла
  Stream<double> getUploadProgress(String chatId, String fileName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileNameWithTimestamp = '${timestamp}_$fileName';
    final filePath = 'chat_files/$chatId/$fileNameWithTimestamp';
    final ref = _storage.ref().child(filePath);

    // TODO: Реализовать отслеживание прогресса загрузки
    // Пока возвращаем заглушку
    return Stream.value(1);
  }
}
