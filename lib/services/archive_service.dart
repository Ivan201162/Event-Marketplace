import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../core/feature_flags.dart';
import '../core/safe_log.dart';
import '../models/event_archive.dart';
import 'upload_service.dart';

/// Сервис для работы с архивами мероприятий
class ArchiveService {
  static const String _collection = 'event_archives';
  static const String _storagePath = 'event_archives';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final UploadService _uploadService = UploadService();
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// Загрузить архив из галереи
  Future<EventArchive?> uploadArchiveFromGallery({
    required String bookingId,
    required String uploadedBy,
    String? description,
  }) async {
    if (!FeatureFlags.fileUploadEnabled) {
      throw Exception('Загрузка архивов отключена');
    }

    try {
      SafeLog.info('ArchiveService: Starting archive upload from gallery');

      // Выбираем файл из галереи
      final pickedFile = await _imagePicker.pickMedia(
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        SafeLog.info('ArchiveService: No file selected');
        return null;
      }

      return await _uploadArchive(
        file: File(pickedFile.path),
        bookingId: bookingId,
        uploadedBy: uploadedBy,
        description: description,
      );
    } on Exception catch (e) {
      SafeLog.error('ArchiveService: Error uploading archive from gallery: $e');
      rethrow;
    }
  }

  /// Загрузить архив из камеры
  Future<EventArchive?> uploadArchiveFromCamera({
    required String bookingId,
    required String uploadedBy,
    String? description,
  }) async {
    if (!FeatureFlags.fileUploadEnabled) {
      throw Exception('Загрузка архивов отключена');
    }

    try {
      SafeLog.info('ArchiveService: Starting archive upload from camera');

      // Выбираем файл из камеры
      final pickedFile = await _imagePicker.pickMedia(
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        SafeLog.info('ArchiveService: No file captured');
        return null;
      }

      return await _uploadArchive(
        file: File(pickedFile.path),
        bookingId: bookingId,
        uploadedBy: uploadedBy,
        description: description,
      );
    } on Exception catch (e) {
      SafeLog.error('ArchiveService: Error uploading archive from camera: $e');
      rethrow;
    }
  }

  /// Внутренний метод загрузки архива
  Future<EventArchive> _uploadArchive({
    required File file,
    required String bookingId,
    required String uploadedBy,
    String? description,
  }) async {
    try {
      SafeLog.info('ArchiveService: Uploading archive file: ${file.path}');

      // Получаем информацию о файле
      final fileStat = await file.stat();
      final fileName = path.basename(file.path);
      final fileExtension = path.extension(fileName).toLowerCase();

      // Генерируем уникальное имя файла
      final uniqueFileName = '${_uuid.v4()}_$fileName';
      final storagePath = '$_storagePath/$bookingId/$uniqueFileName';

      // Определяем тип файла
      FileType fileType;
      if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(fileExtension)) {
        fileType = FileType.image;
      } else if (['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm']
          .contains(fileExtension)) {
        fileType = FileType.video;
      } else {
        fileType = FileType.other;
      }

      // Загружаем файл в Firebase Storage
      final uploadResult = await _uploadService.uploadFile(
        file,
        fileType: fileType,
        customPath: storagePath,
        metadata: {
          'bookingId': bookingId,
          'uploadedBy': uploadedBy,
          'type': 'event_archive',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Создаем запись об архиве
      final archive = EventArchive(
        id: _uuid.v4(),
        bookingId: bookingId,
        fileUrl: uploadResult.url,
        uploadedAt: DateTime.now(),
        fileName: fileName,
        fileSize: fileStat.size,
        description: description,
        uploadedBy: uploadedBy,
        metadata: {
          'originalFileName': fileName,
          'fileExtension': fileExtension,
          'storagePath': storagePath,
        },
      );

      await _firestore
          .collection(_collection)
          .doc(archive.id)
          .set(archive.toMap());

      SafeLog.info(
          'ArchiveService: Archive uploaded successfully: ${archive.id}');
      return archive;
    } on Exception catch (e) {
      SafeLog.error('ArchiveService: Error uploading archive file: $e');
      rethrow;
    }
  }

  /// Получить архивы по ID бронирования
  Future<List<EventArchive>> getArchivesByBooking(String bookingId) async {
    try {
      SafeLog.info('ArchiveService: Getting archives for booking: $bookingId');

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('uploadedAt', descending: true)
          .get();

      final archives =
          querySnapshot.docs.map(EventArchive.fromDocument).toList();

      SafeLog.info('ArchiveService: Found ${archives.length} archives');
      return archives;
    } on Exception catch (e) {
      SafeLog.error('ArchiveService: Error getting archives: $e');
      rethrow;
    }
  }

  /// Получить архивы по ID бронирования (Stream)
  Stream<List<EventArchive>> getArchivesByBookingStream(String bookingId) {
    try {
      SafeLog.info(
          'ArchiveService: Getting archives stream for booking: $bookingId');

      return _firestore
          .collection(_collection)
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('uploadedAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map(EventArchive.fromDocument).toList());
    } on Exception catch (e) {
      SafeLog.error('ArchiveService: Error getting archives stream: $e');
      rethrow;
    }
  }

  /// Удалить архив
  Future<void> deleteArchive(String archiveId) async {
    try {
      SafeLog.info('ArchiveService: Deleting archive: $archiveId');

      // Получаем информацию об архиве
      final doc = await _firestore.collection(_collection).doc(archiveId).get();
      if (!doc.exists) {
        throw Exception('Архив не найден');
      }

      final archive = EventArchive.fromDocument(doc);

      // Удаляем файл из Firebase Storage
      final storagePath = archive.metadata['storagePath'] as String?;
      if (storagePath != null) {
        try {
          await _storage.ref().child(storagePath).delete();
        } on Exception catch (e) {
          SafeLog.warning(
              'ArchiveService: Error deleting file from storage: $e');
        }
      }

      // Удаляем запись из Firestore
      await _firestore.collection(_collection).doc(archiveId).delete();

      SafeLog.info('ArchiveService: Archive deleted successfully: $archiveId');
    } on Exception catch (e) {
      SafeLog.error('ArchiveService: Error deleting archive: $e');
      rethrow;
    }
  }

  /// Обновить описание архива
  Future<void> updateArchiveDescription(
      String archiveId, String description) async {
    try {
      SafeLog.info('ArchiveService: Updating archive description: $archiveId');

      await _firestore
          .collection(_collection)
          .doc(archiveId)
          .update({'description': description});

      SafeLog.info('ArchiveService: Archive description updated successfully');
    } on Exception catch (e) {
      SafeLog.error('ArchiveService: Error updating archive description: $e');
      rethrow;
    }
  }

  /// Получить статистику архивов для бронирования
  Future<Map<String, int>> getArchiveStats(String bookingId) async {
    try {
      SafeLog.info(
          'ArchiveService: Getting archive stats for booking: $bookingId');

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('bookingId', isEqualTo: bookingId)
          .get();

      var totalArchives = 0;
      var totalSize = 0;
      var imageCount = 0;
      var videoCount = 0;
      var archiveCount = 0;

      for (final doc in querySnapshot.docs) {
        final archive = EventArchive.fromDocument(doc);
        totalArchives++;
        totalSize += archive.fileSize ?? 0;

        if (archive.isImage) {
          imageCount++;
        } else if (archive.isVideo) {
          videoCount++;
        } else if (archive.isArchive) {
          archiveCount++;
        }
      }

      final stats = {
        'total': totalArchives,
        'totalSize': totalSize,
        'images': imageCount,
        'videos': videoCount,
        'archives': archiveCount,
      };

      SafeLog.info('ArchiveService: Archive stats: $stats');
      return stats;
    } on Exception catch (e) {
      SafeLog.error('ArchiveService: Error getting archive stats: $e');
      rethrow;
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
      SafeLog.error('ArchiveService: Error extracting storage path: $e');
      return null;
    }
  }
}
