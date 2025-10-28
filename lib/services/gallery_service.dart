import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/gallery_item.dart';
import 'package:event_marketplace_app/utils/storage_guard.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Сервис для работы с галереей специалиста
class GalleryService {
  factory GalleryService() => _instance;
  GalleryService._internal();
  static final GalleryService _instance = GalleryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage? _storage = getStorage();
  final ImagePicker _imagePicker = ImagePicker();

  /// Загрузить изображение в галерею
  Future<String> uploadImage({
    required String specialistId,
    required XFile imageFile,
    required String title,
    String? description,
    List<String> tags = const [],
    bool isFeatured = false,
  }) async {
    try {
      // Генерируем уникальное имя файла
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final storagePath = 'gallery/$specialistId/images/$fileName';

      // Загружаем файл в Firebase Storage
      final storage = _storage;
      if (storage == null) {
        throw Exception('Firebase Storage is not available on web.');
      }
      final ref = storage.ref().child(storagePath);
      final uploadTask = ref.putFile(File(imageFile.path));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Создаем запись в Firestore
      final galleryItem = GalleryItem(
        id: '', // Будет сгенерирован Firestore
        specialistId: specialistId,
        type: GalleryItemType.image,
        url: downloadUrl,
        thumbnailUrl: downloadUrl, // Для изображений thumbnail = оригинал
        title: title,
        description: description,
        createdAt: DateTime.now(),
        tags: tags,
        isFeatured: isFeatured,
      );

      final docRef =
          await _firestore.collection('gallery').add(galleryItem.toMap());

      debugPrint('Image uploaded to gallery: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Ошибка загрузки изображения: $e');
    }
  }

  /// Загрузить видео в галерею
  Future<String> uploadVideo({
    required String specialistId,
    required XFile videoFile,
    required String title,
    String? description,
    List<String> tags = const [],
    bool isFeatured = false,
  }) async {
    try {
      // Генерируем уникальное имя файла
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${videoFile.name}';
      final storagePath = 'gallery/$specialistId/videos/$fileName';

      // Загружаем видео в Firebase Storage
      final storage = _storage;
      if (storage == null) {
        throw Exception('Firebase Storage is not available on web.');
      }
      final ref = storage.ref().child(storagePath);
      final uploadTask = ref.putFile(File(videoFile.path));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Создаем thumbnail для видео
      final thumbnailPath = await _generateVideoThumbnail(videoFile.path);
      String? thumbnailUrl;

      if (thumbnailPath != null) {
        final thumbnailRef = storage.ref().child(
              'gallery/$specialistId/thumbnails/${fileName}_thumb.jpg',
            );
        final thumbnailUploadTask = thumbnailRef.putFile(File(thumbnailPath));
        final thumbnailSnapshot = await thumbnailUploadTask;
        thumbnailUrl = await thumbnailSnapshot.ref.getDownloadURL();

        // Удаляем временный файл thumbnail
        await File(thumbnailPath).delete();
      }

      // Получаем информацию о видео
      final videoInfo = await _getVideoInfo(videoFile.path);

      // Создаем запись в Firestore
      final galleryItem = GalleryItem(
        id: '', // Будет сгенерирован Firestore
        specialistId: specialistId,
        type: GalleryItemType.video,
        url: downloadUrl,
        thumbnailUrl: thumbnailUrl ?? downloadUrl,
        title: title,
        description: description,
        createdAt: DateTime.now(),
        tags: tags,
        isFeatured: isFeatured,
        duration: videoInfo['duration'] as double?,
        width: videoInfo['width'] as int?,
        height: videoInfo['height'] as int?,
        fileSize: await File(videoFile.path).length(),
      );

      final docRef =
          await _firestore.collection('gallery').add(galleryItem.toMap());

      debugPrint('Video uploaded to gallery: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error uploading video: $e');
      throw Exception('Ошибка загрузки видео: $e');
    }
  }

  /// Получить элементы галереи специалиста
  Future<List<GalleryItem>> getSpecialistGallery(
    String specialistId, {
    int limit = 50,
    bool featuredOnly = false,
  }) async {
    try {
      Query query = _firestore
          .collection('gallery')
          .where('specialistId', isEqualTo: specialistId)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      if (featuredOnly) {
        query = query.where('isFeatured', isEqualTo: true);
      }

      final querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs.map(GalleryItem.fromDocument).toList();
    } catch (e) {
      debugPrint('Error getting specialist gallery: $e');
      throw Exception('Ошибка получения галереи: $e');
    }
  }

  /// Получить избранные элементы галереи
  Future<List<GalleryItem>> getFeaturedGallery(String specialistId) async =>
      getSpecialistGallery(specialistId, featuredOnly: true);

  /// Обновить элемент галереи
  Future<void> updateGalleryItem(
    String itemId, {
    String? title,
    String? description,
    List<String>? tags,
    bool? isFeatured,
    bool? isPublic,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (tags != null) updateData['tags'] = tags;
      if (isFeatured != null) updateData['isFeatured'] = isFeatured;
      if (isPublic != null) updateData['isPublic'] = isPublic;

      await _firestore.collection('gallery').doc(itemId).update(updateData);

      debugPrint('Gallery item updated: $itemId');
    } catch (e) {
      debugPrint('Error updating gallery item: $e');
      throw Exception('Ошибка обновления элемента галереи: $e');
    }
  }

  /// Удалить элемент галереи
  Future<void> deleteGalleryItem(String itemId) async {
    try {
      // Получаем информацию об элементе
      final doc = await _firestore.collection('gallery').doc(itemId).get();
      if (!doc.exists) {
        throw Exception('Элемент галереи не найден');
      }

      final item = GalleryItem.fromDocument(doc);

      // Удаляем файлы из Storage
      try {
        final storage = _storage;
        if (storage != null) {
          await storage.refFromURL(item.url).delete();
        }
        if (item.thumbnailUrl != item.url) {
          if (storage != null) {
            await storage.refFromURL(item.thumbnailUrl).delete();
          }
        }
      } catch (e) {
        debugPrint('Error deleting files from storage: $e');
        // Продолжаем удаление записи даже если файлы не удалились
      }

      // Удаляем запись из Firestore
      await _firestore.collection('gallery').doc(itemId).delete();

      debugPrint('Gallery item deleted: $itemId');
    } catch (e) {
      debugPrint('Error deleting gallery item: $e');
      throw Exception('Ошибка удаления элемента галереи: $e');
    }
  }

  /// Увеличить счетчик просмотров
  Future<void> incrementViewCount(String itemId) async {
    try {
      await _firestore.collection('gallery').doc(itemId).update({
        'viewCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
      // Не выбрасываем исключение, так как это не критично
    }
  }

  /// Увеличить счетчик лайков
  Future<void> incrementLikeCount(String itemId) async {
    try {
      await _firestore.collection('gallery').doc(itemId).update({
        'likeCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error incrementing like count: $e');
      throw Exception('Ошибка добавления лайка: $e');
    }
  }

  /// Уменьшить счетчик лайков
  Future<void> decrementLikeCount(String itemId) async {
    try {
      await _firestore.collection('gallery').doc(itemId).update({
        'likeCount': FieldValue.increment(-1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error decrementing like count: $e');
      throw Exception('Ошибка удаления лайка: $e');
    }
  }

  /// Создать thumbnail для видео
  Future<String?> _generateVideoThumbnail(String videoPath) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: '/tmp',
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 75,
      );
      return thumbnailPath;
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
      return null;
    }
  }

  /// Получить информацию о видео
  Future<Map<String, dynamic>> _getVideoInfo(String videoPath) async {
    try {
      // Здесь можно использовать video_player или другие библиотеки
      // для получения информации о видео
      // Пока возвращаем базовую информацию
      final file = File(videoPath);
      final fileSize = await file.length();

      return {
        'duration': null, // Можно получить через video_player
        'width': null,
        'height': null,
        'fileSize': fileSize,
      };
    } catch (e) {
      debugPrint('Error getting video info: $e');
      return {
        'duration': null,
        'width': null,
        'height': null,
        'fileSize': null,
      };
    }
  }

  /// Выбрать изображение из галереи
  Future<XFile?> pickImage() async {
    try {
      return await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Сделать фото с камеры
  Future<XFile?> takePhoto() async {
    try {
      return await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  /// Выбрать видео из галереи
  Future<XFile?> pickVideo() async {
    try {
      return await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
    } catch (e) {
      debugPrint('Error picking video: $e');
      return null;
    }
  }

  /// Записать видео с камеры
  Future<XFile?> recordVideo() async {
    try {
      return await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
    } catch (e) {
      debugPrint('Error recording video: $e');
      return null;
    }
  }
}
