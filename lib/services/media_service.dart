import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../core/feature_flags.dart';
import '../core/safe_log.dart';
import '../models/media_item.dart';
import '../utils/storage_guard.dart';
import 'upload_service.dart';

/// Сервис для работы с медиафайлами в профиле специалиста
class MediaService {
  static const String _collection = 'media_items';
  static const String _storagePath = 'specialist_media';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage? _storage = getStorage();
  final UploadService _uploadService = UploadService();
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// Загрузить медиафайл из галереи
  Future<MediaItem?> uploadMediaFromGallery({
    required String userId,
    required MediaType type,
    String? title,
    String? description,
  }) async {
    if (!FeatureFlags.fileUploadEnabled) {
      throw Exception('Загрузка медиафайлов отключена');
    }

    try {
      SafeLog.info('MediaService: Starting media upload from gallery');

      // Выбираем файл из галереи
      final XFile? pickedFile;
      if (type == MediaType.photo) {
        pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
      } else {
        pickedFile = await _imagePicker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 5),
        );
      }

      if (pickedFile == null) {
        SafeLog.info('MediaService: No file selected');
        return null;
      }

      return await _uploadMediaFile(
        file: File(pickedFile.path),
        userId: userId,
        type: type,
        title: title,
        description: description,
      );
    } on Exception catch (e) {
      SafeLog.error('MediaService: Error uploading media from gallery: $e');
      rethrow;
    }
  }

  /// Загрузить медиафайл из камеры
  Future<MediaItem?> uploadMediaFromCamera({
    required String userId,
    required MediaType type,
    String? title,
    String? description,
  }) async {
    if (!FeatureFlags.fileUploadEnabled) {
      throw Exception('Загрузка медиафайлов отключена');
    }

    try {
      SafeLog.info('MediaService: Starting media upload from camera');

      // Выбираем файл из камеры
      final XFile? pickedFile;
      if (type == MediaType.photo) {
        pickedFile = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
      } else {
        pickedFile = await _imagePicker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(minutes: 5),
        );
      }

      if (pickedFile == null) {
        SafeLog.info('MediaService: No file captured');
        return null;
      }

      return await _uploadMediaFile(
        file: File(pickedFile.path),
        userId: userId,
        type: type,
        title: title,
        description: description,
      );
    } on Exception catch (e) {
      SafeLog.error('MediaService: Error uploading media from camera: $e');
      rethrow;
    }
  }

  /// Загрузить медиафайл из файла
  Future<MediaItem> uploadMediaFile({
    required File file,
    required String userId,
    required MediaType type,
    String? title,
    String? description,
  }) async =>
      _uploadMediaFile(
        file: file,
        userId: userId,
        type: type,
        title: title,
        description: description,
      );

  /// Внутренний метод загрузки медиафайла
  Future<MediaItem> _uploadMediaFile({
    required File file,
    required String userId,
    required MediaType type,
    String? title,
    String? description,
  }) async {
    try {
      SafeLog.info('MediaService: Uploading media file: ${file.path}');

      // Получаем информацию о файле
      final fileStat = await file.stat();
      final fileName = path.basename(file.path);
      final fileExtension = path.extension(fileName).toLowerCase();

      // Генерируем уникальное имя файла
      final uniqueFileName = '${_uuid.v4()}_$fileName';
      final storagePath = '$_storagePath/$userId/$uniqueFileName';

      // Загружаем файл в Firebase Storage
      final uploadResult = await _uploadService.uploadFile(
        file,
        fileType: type == MediaType.photo ? FileType.image : FileType.video,
        customPath: storagePath,
        metadata: {
          'userId': userId,
          'type': type.value,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Создаем превью для видео
      String? thumbnailUrl;
      if (type == MediaType.video) {
        thumbnailUrl = await _createVideoThumbnail(uploadResult.url);
      }

      // Получаем размеры изображения/видео
      int? width, height;
      if (type == MediaType.photo) {
        final dimensions = await _getImageDimensions(file);
        width = dimensions['width'];
        height = dimensions['height'];
      }

      // Создаем запись в Firestore
      final mediaItem = MediaItem(
        id: _uuid.v4(),
        userId: userId,
        type: type,
        url: uploadResult.url,
        createdAt: DateTime.now(),
        thumbnailUrl: thumbnailUrl,
        title: title,
        description: description,
        fileSize: fileStat.size,
        width: width,
        height: height,
        metadata: {
          'originalFileName': fileName,
          'fileExtension': fileExtension,
          'storagePath': storagePath,
        },
      );

      await _firestore
          .collection(_collection)
          .doc(mediaItem.id)
          .set(mediaItem.toMap());

      SafeLog.info(
          'MediaService: Media uploaded successfully: ${mediaItem.id}');
      return mediaItem;
    } on Exception catch (e) {
      SafeLog.error('MediaService: Error uploading media file: $e');
      rethrow;
    }
  }

  /// Удалить медиафайл
  Future<void> deleteMedia(String mediaId) async {
    try {
      SafeLog.info('MediaService: Deleting media: $mediaId');

      // Получаем информацию о медиафайле
      final doc = await _firestore.collection(_collection).doc(mediaId).get();
      if (!doc.exists) {
        throw Exception('Медиафайл не найден');
      }

      final mediaItem = MediaItem.fromDocument(doc);

      // Удаляем файл из Firebase Storage
      final storagePath = mediaItem.metadata['storagePath'] as String?;
      if (storagePath != null) {
        try {
          await _storage.ref().child(storagePath).delete();
        } on Exception catch (e) {
          SafeLog.warning('MediaService: Error deleting file from storage: $e');
        }
      }

      // Удаляем превью видео, если есть
      if (mediaItem.thumbnailUrl != null) {
        try {
          final thumbnailPath =
              _extractStoragePathFromUrl(mediaItem.thumbnailUrl!);
          if (thumbnailPath != null) {
            await _storage.ref().child(thumbnailPath).delete();
          }
        } on Exception catch (e) {
          SafeLog.warning('MediaService: Error deleting thumbnail: $e');
        }
      }

      // Удаляем запись из Firestore
      await _firestore.collection(_collection).doc(mediaId).delete();

      SafeLog.info('MediaService: Media deleted successfully: $mediaId');
    } on Exception catch (e) {
      SafeLog.error('MediaService: Error deleting media: $e');
      rethrow;
    }
  }

  /// Получить медиафайлы пользователя
  Future<List<MediaItem>> getMediaForUser(String userId) async {
    try {
      SafeLog.info('MediaService: Getting media for user: $userId');

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final mediaItems =
          querySnapshot.docs.map(MediaItem.fromDocument).toList();

      SafeLog.info('MediaService: Found ${mediaItems.length} media items');
      return mediaItems;
    } on Exception catch (e) {
      SafeLog.error('MediaService: Error getting media for user: $e');
      rethrow;
    }
  }

  /// Получить медиафайлы по типу
  Future<List<MediaItem>> getMediaByType(String userId, MediaType type) async {
    try {
      SafeLog.info('MediaService: Getting $type media for user: $userId');

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type.value)
          .orderBy('createdAt', descending: true)
          .get();

      final mediaItems =
          querySnapshot.docs.map(MediaItem.fromDocument).toList();

      SafeLog.info('MediaService: Found ${mediaItems.length} $type items');
      return mediaItems;
    } on Exception catch (e) {
      SafeLog.error('MediaService: Error getting media by type: $e');
      rethrow;
    }
  }

  /// Обновить информацию о медиафайле
  Future<void> updateMedia(String mediaId,
      {String? title, String? description}) async {
    try {
      SafeLog.info('MediaService: Updating media: $mediaId');

      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;

      if (updateData.isNotEmpty) {
        await _firestore
            .collection(_collection)
            .doc(mediaId)
            .update(updateData);
      }

      SafeLog.info('MediaService: Media updated successfully: $mediaId');
    } on Exception catch (e) {
      SafeLog.error('MediaService: Error updating media: $e');
      rethrow;
    }
  }

  /// Создать превью для видео
  Future<String?> _createVideoThumbnail(String videoUrl) async {
    try {
      // В реальном приложении здесь бы использовался FFmpeg или другой инструмент
      // для создания превью видео. Для демонстрации возвращаем null.
      SafeLog.info('MediaService: Video thumbnail creation not implemented');
      return null;
    } on Exception catch (e) {
      SafeLog.error('MediaService: Error creating video thumbnail: $e');
      return null;
    }
  }

  /// Получить размеры изображения
  Future<Map<String, int?>> _getImageDimensions(File imageFile) async {
    try {
      // В реальном приложении здесь бы использовался image package
      // для получения размеров изображения. Для демонстрации возвращаем null.
      SafeLog.info('MediaService: Image dimensions extraction not implemented');
      return {'width': null, 'height': null};
    } on Exception catch (e) {
      SafeLog.error('MediaService: Error getting image dimensions: $e');
      return {'width': null, 'height': null};
    }
  }

  /// Извлечь путь в Storage из URL
  String? _extractStoragePathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Ищем путь после /o/
      final oIndex = pathSegments.indexOf('o');
      if (oIndex != -1 && oIndex + 1 < pathSegments.length) {
        return pathSegments.sublist(oIndex + 1).join('/');
      }

      return null;
    } on Exception catch (e) {
      SafeLog.error('MediaService: Error extracting storage path: $e');
      return null;
    }
  }

  /// Получить статистику медиафайлов пользователя
  Future<Map<String, int>> getMediaStats(String userId) async {
    try {
      SafeLog.info('MediaService: Getting media stats for user: $userId');

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      var photoCount = 0;
      var videoCount = 0;
      var totalSize = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String;
        final fileSize = data['fileSize'] as int? ?? 0;

        if (type == 'photo') {
          photoCount++;
        } else if (type == 'video') {
          videoCount++;
        }

        totalSize += fileSize;
      }

      final stats = {
        'total': photoCount + videoCount,
        'photos': photoCount,
        'videos': videoCount,
        'totalSize': totalSize,
      };

      SafeLog.info('MediaService: Media stats: $stats');
      return stats;
    } on Exception catch (e) {
      SafeLog.error('MediaService: Error getting media stats: $e');
      rethrow;
    }
  }
}
