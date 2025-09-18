import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import '../models/content_management.dart';

/// Сервис управления контентом и медиа
class ContentManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  static final ContentManagementService _instance =
      ContentManagementService._internal();
  factory ContentManagementService() => _instance;
  ContentManagementService._internal();

  final Map<String, MediaContent> _mediaCache = {};
  final Map<String, ContentGallery> _galleryCache = {};
  final Map<String, MediaProcessing> _processingCache = {};

  /// Инициализация сервиса
  Future<void> initialize() async {
    try {
      await _loadMediaCache();
      await _loadGalleryCache();
      await _loadProcessingCache();

      if (kDebugMode) {
        print('Content management service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка инициализации сервиса управления контентом: $e');
      }
    }
  }

  /// Загрузить медиа файл
  Future<String> uploadMedia({
    required String filePath,
    required String title,
    String? description,
    required MediaType type,
    String? specialistId,
    String? eventId,
    String? uploadedBy,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Файл не найден: $filePath');
      }

      final fileSize = await file.length();
      final fileName = file.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();

      // Определяем MIME тип
      final mimeType = _getMimeType(fileExtension);

      // Проверяем поддержку типа файла
      if (!_isSupportedFileType(type, mimeType)) {
        throw Exception('Неподдерживаемый тип файла: $mimeType');
      }

      // Генерируем уникальное имя файла
      final mediaId = _uuid.v4();
      final storagePath = 'media/$mediaId/$fileName';

      // Загружаем файл в Firebase Storage
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(file);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Создаем запись в Firestore
      final mediaContent = MediaContent(
        id: mediaId,
        title: title,
        description: description,
        type: type,
        url: downloadUrl,
        fileSize: fileSize,
        mimeType: mimeType,
        metadata: metadata ?? {},
        uploadedBy: uploadedBy,
        specialistId: specialistId,
        eventId: eventId,
        tags: tags ?? [],
        uploadedAt: DateTime.now(),
      );

      await _firestore
          .collection('mediaContent')
          .doc(mediaId)
          .set(mediaContent.toMap());
      _mediaCache[mediaId] = mediaContent;

      // Запускаем обработку медиа
      await _startMediaProcessing(mediaContent);

      if (kDebugMode) {
        print('Media uploaded: $title');
      }

      return mediaId;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки медиа: $e');
      }
      rethrow;
    }
  }

  /// Загрузить медиа из байтов
  Future<String> uploadMediaFromBytes({
    required Uint8List bytes,
    required String fileName,
    required String title,
    String? description,
    required MediaType type,
    String? specialistId,
    String? eventId,
    String? uploadedBy,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final fileExtension = fileName.split('.').last.toLowerCase();
      final mimeType = _getMimeType(fileExtension);

      if (!_isSupportedFileType(type, mimeType)) {
        throw Exception('Неподдерживаемый тип файла: $mimeType');
      }

      final mediaId = _uuid.v4();
      final storagePath = 'media/$mediaId/$fileName';

      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putData(bytes);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final mediaContent = MediaContent(
        id: mediaId,
        title: title,
        description: description,
        type: type,
        url: downloadUrl,
        fileSize: bytes.length,
        mimeType: mimeType,
        metadata: metadata ?? {},
        uploadedBy: uploadedBy,
        specialistId: specialistId,
        eventId: eventId,
        tags: tags ?? [],
        uploadedAt: DateTime.now(),
      );

      await _firestore
          .collection('mediaContent')
          .doc(mediaId)
          .set(mediaContent.toMap());
      _mediaCache[mediaId] = mediaContent;

      await _startMediaProcessing(mediaContent);

      if (kDebugMode) {
        print('Media uploaded from bytes: $title');
      }

      return mediaId;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки медиа из байтов: $e');
      }
      rethrow;
    }
  }

  /// Запустить обработку медиа
  Future<void> _startMediaProcessing(MediaContent mediaContent) async {
    try {
      // Обновляем статус на "обрабатывается"
      await _firestore.collection('mediaContent').doc(mediaContent.id).update({
        'status': ContentStatus.processing.toString().split('.').last,
      });

      _mediaCache[mediaContent.id] = mediaContent.copyWith(
        status: ContentStatus.processing,
      );

      // Создаем задачи обработки в зависимости от типа
      final processingTasks = <ProcessingType>[];

      switch (mediaContent.type) {
        case MediaType.image:
          processingTasks.addAll([
            ProcessingType.thumbnail,
            ProcessingType.resize,
            ProcessingType.compress,
          ]);
          break;
        case MediaType.video:
          processingTasks.addAll([
            ProcessingType.thumbnail,
            ProcessingType.compress,
          ]);
          break;
        case MediaType.audio:
          processingTasks.add(ProcessingType.compress);
          break;
        case MediaType.document:
        case MediaType.other:
          // Для документов и других типов обработка не требуется
          break;
      }

      // Создаем задачи обработки
      for (final taskType in processingTasks) {
        await _createProcessingTask(mediaContent.id, taskType);
      }

      // Если нет задач обработки, сразу помечаем как обработанное
      if (processingTasks.isEmpty) {
        await _completeMediaProcessing(mediaContent.id);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка запуска обработки медиа: $e');
      }

      // Помечаем как ошибку
      await _firestore.collection('mediaContent').doc(mediaContent.id).update({
        'status': ContentStatus.error.toString().split('.').last,
      });

      _mediaCache[mediaContent.id] = mediaContent.copyWith(
        status: ContentStatus.error,
      );
    }
  }

  /// Создать задачу обработки
  Future<void> _createProcessingTask(
      String mediaId, ProcessingType type) async {
    try {
      final processingId = _uuid.v4();
      final processing = MediaProcessing(
        id: processingId,
        mediaId: mediaId,
        type: type,
        startedAt: DateTime.now(),
      );

      await _firestore
          .collection('mediaProcessing')
          .doc(processingId)
          .set(processing.toMap());
      _processingCache[processingId] = processing;

      // Запускаем обработку
      await _processMedia(processing);
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка создания задачи обработки: $e');
      }
    }
  }

  /// Обработать медиа
  Future<void> _processMedia(MediaProcessing processing) async {
    try {
      // Обновляем статус на "в процессе"
      await _firestore.collection('mediaProcessing').doc(processing.id).update({
        'status': ProcessingStatus.inProgress.toString().split('.').last,
      });

      _processingCache[processing.id] = processing.copyWith(
        status: ProcessingStatus.inProgress,
      );

      // Получаем медиа контент
      final mediaContent = _mediaCache[processing.mediaId];
      if (mediaContent == null) {
        throw Exception('Медиа контент не найден');
      }

      String? resultUrl;

      switch (processing.type) {
        case ProcessingType.thumbnail:
          resultUrl = await _generateThumbnail(mediaContent);
          break;
        case ProcessingType.resize:
          resultUrl = await _resizeImage(mediaContent, processing.parameters);
          break;
        case ProcessingType.compress:
          resultUrl = await _compressMedia(mediaContent, processing.parameters);
          break;
        case ProcessingType.watermark:
          resultUrl = await _addWatermark(mediaContent, processing.parameters);
          break;
        case ProcessingType.filter:
          resultUrl = await _applyFilter(mediaContent, processing.parameters);
          break;
        case ProcessingType.crop:
          resultUrl = await _cropImage(mediaContent, processing.parameters);
          break;
        case ProcessingType.rotate:
          resultUrl = await _rotateImage(mediaContent, processing.parameters);
          break;
        case ProcessingType.convert:
          resultUrl = await _convertMedia(mediaContent, processing.parameters);
          break;
      }

      // Обновляем статус на "завершено"
      await _firestore.collection('mediaProcessing').doc(processing.id).update({
        'status': ProcessingStatus.completed.toString().split('.').last,
        'resultUrl': resultUrl,
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });

      _processingCache[processing.id] = processing.copyWith(
        status: ProcessingStatus.completed,
        resultUrl: resultUrl,
        completedAt: DateTime.now(),
      );

      // Проверяем, завершены ли все задачи обработки
      await _checkProcessingCompletion(processing.mediaId);
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка обработки медиа: $e');
      }

      // Обновляем статус на "ошибка"
      await _firestore.collection('mediaProcessing').doc(processing.id).update({
        'status': ProcessingStatus.failed.toString().split('.').last,
        'errorMessage': e.toString(),
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });

      _processingCache[processing.id] = processing.copyWith(
        status: ProcessingStatus.failed,
        errorMessage: e.toString(),
        completedAt: DateTime.now(),
      );
    }
  }

  /// Генерировать миниатюру
  Future<String?> _generateThumbnail(MediaContent mediaContent) async {
    try {
      if (mediaContent.type != MediaType.image &&
          mediaContent.type != MediaType.video) {
        return null;
      }

      // Для изображений создаем миниатюру
      if (mediaContent.type == MediaType.image) {
        final thumbnailUrl = await _createImageThumbnail(mediaContent.url);

        // Обновляем медиа контент с URL миниатюры
        await _firestore
            .collection('mediaContent')
            .doc(mediaContent.id)
            .update({
          'thumbnailUrl': thumbnailUrl,
        });

        _mediaCache[mediaContent.id] = mediaContent.copyWith(
          thumbnailUrl: thumbnailUrl,
        );

        return thumbnailUrl;
      }

      // Для видео создаем кадр
      if (mediaContent.type == MediaType.video) {
        // TODO: Реализовать извлечение кадра из видео
        return null;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка генерации миниатюры: $e');
      }
      return null;
    }
  }

  /// Создать миниатюру изображения
  Future<String> _createImageThumbnail(String imageUrl) async {
    try {
      // TODO: Реализовать создание миниатюры изображения
      // Здесь должна быть логика загрузки изображения, изменения размера и загрузки обратно
      return imageUrl; // Временная заглушка
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка создания миниатюры изображения: $e');
      }
      rethrow;
    }
  }

  /// Изменить размер изображения
  Future<String?> _resizeImage(
      MediaContent mediaContent, Map<String, dynamic> parameters) async {
    try {
      if (mediaContent.type != MediaType.image) return null;

      final width = parameters['width'] as int? ?? 800;
      final height = parameters['height'] as int? ?? 600;

      // TODO: Реализовать изменение размера изображения
      return mediaContent.url; // Временная заглушка
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка изменения размера изображения: $e');
      }
      return null;
    }
  }

  /// Сжать медиа
  Future<String?> _compressMedia(
      MediaContent mediaContent, Map<String, dynamic> parameters) async {
    try {
      final quality = parameters['quality'] as int? ?? 80;

      // TODO: Реализовать сжатие медиа
      return mediaContent.url; // Временная заглушка
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка сжатия медиа: $e');
      }
      return null;
    }
  }

  /// Добавить водяной знак
  Future<String?> _addWatermark(
      MediaContent mediaContent, Map<String, dynamic> parameters) async {
    try {
      if (mediaContent.type != MediaType.image) return null;

      // TODO: Реализовать добавление водяного знака
      return mediaContent.url; // Временная заглушка
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка добавления водяного знака: $e');
      }
      return null;
    }
  }

  /// Применить фильтр
  Future<String?> _applyFilter(
      MediaContent mediaContent, Map<String, dynamic> parameters) async {
    try {
      if (mediaContent.type != MediaType.image) return null;

      // TODO: Реализовать применение фильтров
      return mediaContent.url; // Временная заглушка
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка применения фильтра: $e');
      }
      return null;
    }
  }

  /// Обрезать изображение
  Future<String?> _cropImage(
      MediaContent mediaContent, Map<String, dynamic> parameters) async {
    try {
      if (mediaContent.type != MediaType.image) return null;

      // TODO: Реализовать обрезку изображения
      return mediaContent.url; // Временная заглушка
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка обрезки изображения: $e');
      }
      return null;
    }
  }

  /// Повернуть изображение
  Future<String?> _rotateImage(
      MediaContent mediaContent, Map<String, dynamic> parameters) async {
    try {
      if (mediaContent.type != MediaType.image) return null;

      // TODO: Реализовать поворот изображения
      return mediaContent.url; // Временная заглушка
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка поворота изображения: $e');
      }
      return null;
    }
  }

  /// Конвертировать медиа
  Future<String?> _convertMedia(
      MediaContent mediaContent, Map<String, dynamic> parameters) async {
    try {
      // TODO: Реализовать конвертацию медиа
      return mediaContent.url; // Временная заглушка
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка конвертации медиа: $e');
      }
      return null;
    }
  }

  /// Проверить завершение обработки
  Future<void> _checkProcessingCompletion(String mediaId) async {
    try {
      final processingTasks =
          _processingCache.values.where((p) => p.mediaId == mediaId).toList();

      final completedTasks = processingTasks.where((p) => p.isCompleted).length;

      final failedTasks = processingTasks.where((p) => p.hasError).length;

      if (failedTasks > 0) {
        // Есть ошибки обработки
        await _firestore.collection('mediaContent').doc(mediaId).update({
          'status': ContentStatus.error.toString().split('.').last,
        });

        _mediaCache[mediaId] = _mediaCache[mediaId]!.copyWith(
          status: ContentStatus.error,
        );
      } else if (completedTasks == processingTasks.length) {
        // Все задачи завершены
        await _completeMediaProcessing(mediaId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка проверки завершения обработки: $e');
      }
    }
  }

  /// Завершить обработку медиа
  Future<void> _completeMediaProcessing(String mediaId) async {
    try {
      await _firestore.collection('mediaContent').doc(mediaId).update({
        'status': ContentStatus.processed.toString().split('.').last,
        'processedAt': Timestamp.fromDate(DateTime.now()),
      });

      _mediaCache[mediaId] = _mediaCache[mediaId]!.copyWith(
        status: ContentStatus.processed,
        processedAt: DateTime.now(),
      );

      if (kDebugMode) {
        print('Media processing completed: $mediaId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка завершения обработки медиа: $e');
      }
    }
  }

  /// Создать галерею
  Future<String> createGallery({
    required String name,
    String? description,
    String? specialistId,
    String? eventId,
    GalleryType type = GalleryType.portfolio,
    bool isPublic = false,
    String? createdBy,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final galleryId = _uuid.v4();
      final now = DateTime.now();

      final gallery = ContentGallery(
        id: galleryId,
        name: name,
        description: description,
        specialistId: specialistId,
        eventId: eventId,
        type: type,
        isPublic: isPublic,
        createdBy: createdBy,
        settings: settings ?? {},
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('contentGalleries')
          .doc(galleryId)
          .set(gallery.toMap());
      _galleryCache[galleryId] = gallery;

      if (kDebugMode) {
        print('Gallery created: $name');
      }

      return galleryId;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка создания галереи: $e');
      }
      rethrow;
    }
  }

  /// Добавить медиа в галерею
  Future<void> addMediaToGallery(String galleryId, String mediaId) async {
    try {
      final gallery = _galleryCache[galleryId];
      if (gallery == null) {
        throw Exception('Галерея не найдена');
      }

      if (gallery.mediaIds.contains(mediaId)) {
        return; // Медиа уже в галерее
      }

      final updatedMediaIds = [...gallery.mediaIds, mediaId];

      await _firestore.collection('contentGalleries').doc(galleryId).update({
        'mediaIds': updatedMediaIds,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      _galleryCache[galleryId] = gallery.copyWith(
        mediaIds: updatedMediaIds,
        updatedAt: DateTime.now(),
      );

      if (kDebugMode) {
        print('Media added to gallery: $mediaId -> $galleryId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка добавления медиа в галерею: $e');
      }
      rethrow;
    }
  }

  /// Удалить медиа из галереи
  Future<void> removeMediaFromGallery(String galleryId, String mediaId) async {
    try {
      final gallery = _galleryCache[galleryId];
      if (gallery == null) {
        throw Exception('Галерея не найдена');
      }

      final updatedMediaIds =
          gallery.mediaIds.where((id) => id != mediaId).toList();

      await _firestore.collection('contentGalleries').doc(galleryId).update({
        'mediaIds': updatedMediaIds,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      _galleryCache[galleryId] = gallery.copyWith(
        mediaIds: updatedMediaIds,
        updatedAt: DateTime.now(),
      );

      if (kDebugMode) {
        print('Media removed from gallery: $mediaId <- $galleryId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка удаления медиа из галереи: $e');
      }
      rethrow;
    }
  }

  /// Получить медиа контент
  MediaContent? getMediaContent(String mediaId) {
    return _mediaCache[mediaId];
  }

  /// Получить галерею
  ContentGallery? getGallery(String galleryId) {
    return _galleryCache[galleryId];
  }

  /// Получить медиа по специалисту
  Future<List<MediaContent>> getMediaBySpecialist(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('mediaContent')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MediaContent.fromDocument(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения медиа по специалисту: $e');
      }
      return [];
    }
  }

  /// Получить галереи по специалисту
  Future<List<ContentGallery>> getGalleriesBySpecialist(
      String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('contentGalleries')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ContentGallery.fromDocument(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения галерей по специалисту: $e');
      }
      return [];
    }
  }

  /// Удалить медиа
  Future<void> deleteMedia(String mediaId) async {
    try {
      final mediaContent = _mediaCache[mediaId];
      if (mediaContent == null) {
        throw Exception('Медиа контент не найден');
      }

      // Удаляем файл из Storage
      final ref = _storage.refFromURL(mediaContent.url);
      await ref.delete();

      // Удаляем из Firestore
      await _firestore.collection('mediaContent').doc(mediaId).delete();

      // Удаляем из кэша
      _mediaCache.remove(mediaId);

      if (kDebugMode) {
        print('Media deleted: $mediaId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка удаления медиа: $e');
      }
      rethrow;
    }
  }

  /// Удалить галерею
  Future<void> deleteGallery(String galleryId) async {
    try {
      final gallery = _galleryCache[galleryId];
      if (gallery == null) {
        throw Exception('Галерея не найдена');
      }

      // Удаляем из Firestore
      await _firestore.collection('contentGalleries').doc(galleryId).delete();

      // Удаляем из кэша
      _galleryCache.remove(galleryId);

      if (kDebugMode) {
        print('Gallery deleted: $galleryId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка удаления галереи: $e');
      }
      rethrow;
    }
  }

  /// Получить MIME тип по расширению
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/avi';
      case 'mov':
        return 'video/mov';
      case 'webm':
        return 'video/webm';
      case 'mp3':
        return 'audio/mp3';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      case 'm4a':
        return 'audio/m4a';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  /// Проверить поддержку типа файла
  bool _isSupportedFileType(MediaType type, String mimeType) {
    return type.supportedMimeTypes.contains(mimeType);
  }

  /// Загрузить кэш медиа
  Future<void> _loadMediaCache() async {
    try {
      final snapshot =
          await _firestore.collection('mediaContent').limit(100).get();

      for (final doc in snapshot.docs) {
        final mediaContent = MediaContent.fromDocument(doc);
        _mediaCache[mediaContent.id] = mediaContent;
      }

      if (kDebugMode) {
        print('Loaded ${_mediaCache.length} media items');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки кэша медиа: $e');
      }
    }
  }

  /// Загрузить кэш галерей
  Future<void> _loadGalleryCache() async {
    try {
      final snapshot =
          await _firestore.collection('contentGalleries').limit(100).get();

      for (final doc in snapshot.docs) {
        final gallery = ContentGallery.fromDocument(doc);
        _galleryCache[gallery.id] = gallery;
      }

      if (kDebugMode) {
        print('Loaded ${_galleryCache.length} galleries');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки кэша галерей: $e');
      }
    }
  }

  /// Загрузить кэш обработки
  Future<void> _loadProcessingCache() async {
    try {
      final snapshot =
          await _firestore.collection('mediaProcessing').limit(100).get();

      for (final doc in snapshot.docs) {
        final processing = MediaProcessing.fromDocument(doc);
        _processingCache[processing.id] = processing;
      }

      if (kDebugMode) {
        print('Loaded ${_processingCache.length} processing tasks');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки кэша обработки: $e');
      }
    }
  }

  /// Закрыть сервис
  void dispose() {
    _mediaCache.clear();
    _galleryCache.clear();
    _processingCache.clear();
  }
}
