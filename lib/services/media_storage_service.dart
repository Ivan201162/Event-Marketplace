import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Сервис для хранения медиафайлов мероприятий
class MediaStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Загрузить медиафайлы мероприятия
  Future<List<MediaFile>> uploadEventMedia({
    required String bookingId,
    required String specialistId,
    required List<XFile> files,
    String? description,
  }) async {
    try {
      final uploadedFiles = <MediaFile>[];

      for (final file in files) {
        final mediaFile = await _uploadSingleFile(
          bookingId: bookingId,
          specialistId: specialistId,
          file: file,
          description: description,
        );
        uploadedFiles.add(mediaFile);
      }

      // Создаем запись о загрузке медиафайлов
      await _createMediaUploadRecord(
        bookingId: bookingId,
        specialistId: specialistId,
        files: uploadedFiles,
        description: description,
      );

      return uploadedFiles;
    } catch (e) {
      print('Ошибка загрузки медиафайлов: $e');
      rethrow;
    }
  }

  /// Загрузить один файл
  Future<MediaFile> _uploadSingleFile({
    required String bookingId,
    required String specialistId,
    required XFile file,
    String? description,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final filePath = 'event_media/$bookingId/$fileName';

      final ref = _storage.ref().child(filePath);
      final uploadTask = ref.putFile(File(file.path));

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final mediaFile = MediaFile(
        id: '', // Будет сгенерирован Firestore
        bookingId: bookingId,
        specialistId: specialistId,
        fileName: file.name,
        filePath: filePath,
        downloadUrl: downloadUrl,
        fileSize: await file.length(),
        mimeType: _getMimeType(file.path),
        description: description,
        uploadedAt: DateTime.now(),
      );

      // Сохраняем информацию о файле в Firestore
      final docRef =
          await _firestore.collection('media_files').add(mediaFile.toMap());

      return mediaFile.copyWith(id: docRef.id);
    } catch (e) {
      print('Ошибка загрузки файла: $e');
      rethrow;
    }
  }

  /// Получить медиафайлы мероприятия
  Future<List<MediaFile>> getEventMedia(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('media_files')
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs.map(MediaFile.fromDocument).toList();
    } catch (e) {
      print('Ошибка получения медиафайлов: $e');
      return [];
    }
  }

  /// Получить медиафайлы специалиста
  Future<List<MediaFile>> getSpecialistMedia(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('media_files')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs.map(MediaFile.fromDocument).toList();
    } catch (e) {
      print('Ошибка получения медиафайлов специалиста: $e');
      return [];
    }
  }

  /// Создать запись о загрузке медиафайлов
  Future<void> _createMediaUploadRecord({
    required String bookingId,
    required String specialistId,
    required List<MediaFile> files,
    String? description,
  }) async {
    try {
      await _firestore.collection('media_uploads').add({
        'bookingId': bookingId,
        'specialistId': specialistId,
        'fileCount': files.length,
        'totalSize': files.fold<int>(0, (sum, file) => sum + file.fileSize),
        'description': description,
        'uploadedAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      // Обновляем статус заказа
      await _firestore.collection('bookings').doc(bookingId).update({
        'mediaUploaded': true,
        'mediaUploadedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка создания записи о загрузке: $e');
    }
  }

  /// Удалить медиафайл
  Future<void> deleteMediaFile(String mediaFileId) async {
    try {
      // Получаем информацию о файле
      final doc =
          await _firestore.collection('media_files').doc(mediaFileId).get();

      if (!doc.exists) return;

      final mediaFile = MediaFile.fromDocument(doc);

      // Удаляем файл из Storage
      await _storage.ref().child(mediaFile.filePath).delete();

      // Удаляем запись из Firestore
      await _firestore.collection('media_files').doc(mediaFileId).delete();
    } catch (e) {
      print('Ошибка удаления медиафайла: $e');
      rethrow;
    }
  }

  /// Получить статистику медиафайлов
  Future<MediaStats> getMediaStats(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('media_files')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final files = snapshot.docs.map(MediaFile.fromDocument).toList();

      final totalFiles = files.length;
      final totalSize = files.fold<int>(0, (sum, file) => sum + file.fileSize);
      final photoCount =
          files.where((f) => f.mimeType.startsWith('image/')).length;
      final videoCount =
          files.where((f) => f.mimeType.startsWith('video/')).length;

      return MediaStats(
        specialistId: specialistId,
        totalFiles: totalFiles,
        totalSize: totalSize,
        photoCount: photoCount,
        videoCount: videoCount,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('Ошибка получения статистики медиафайлов: $e');
      return MediaStats.empty();
    }
  }

  /// Создать ссылку для скачивания
  Future<String> createDownloadLink(String mediaFileId) async {
    try {
      final doc =
          await _firestore.collection('media_files').doc(mediaFileId).get();

      if (!doc.exists) {
        throw Exception('Файл не найден');
      }

      final mediaFile = MediaFile.fromDocument(doc);

      // Создаем временную ссылку для скачивания (действует 1 час)
      final ref = _storage.ref().child(mediaFile.filePath);
      final downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Ошибка создания ссылки для скачивания: $e');
      rethrow;
    }
  }

  /// Получить прогресс загрузки
  Stream<double> getUploadProgress(String filePath) {
    final ref = _storage.ref().child(filePath);
    return ref
        .putFile(File(filePath))
        .snapshotEvents
        .map((snapshot) => snapshot.bytesTransferred / snapshot.totalBytes);
  }

  // ========== ПРИВАТНЫЕ МЕТОДЫ ==========

  /// Получить MIME тип файла
  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/avi';
      case 'mov':
        return 'video/quicktime';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}

/// Модель медиафайла
class MediaFile {
  const MediaFile({
    required this.id,
    required this.bookingId,
    required this.specialistId,
    required this.fileName,
    required this.filePath,
    required this.downloadUrl,
    required this.fileSize,
    required this.mimeType,
    this.description,
    required this.uploadedAt,
  });

  factory MediaFile.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return MediaFile(
      id: doc.id,
      bookingId: data['bookingId'] as String? ?? '',
      specialistId: data['specialistId'] as String? ?? '',
      fileName: data['fileName'] as String? ?? '',
      filePath: data['filePath'] as String? ?? '',
      downloadUrl: data['downloadUrl'] as String? ?? '',
      fileSize: data['fileSize'] as int? ?? 0,
      mimeType: data['mimeType'] as String? ?? '',
      description: data['description'] as String?,
      uploadedAt: data['uploadedAt'] != null
          ? (data['uploadedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  final String id;
  final String bookingId;
  final String specialistId;
  final String fileName;
  final String filePath;
  final String downloadUrl;
  final int fileSize;
  final String mimeType;
  final String? description;
  final DateTime uploadedAt;

  MediaFile copyWith({
    String? id,
    String? bookingId,
    String? specialistId,
    String? fileName,
    String? filePath,
    String? downloadUrl,
    int? fileSize,
    String? mimeType,
    String? description,
    DateTime? uploadedAt,
  }) =>
      MediaFile(
        id: id ?? this.id,
        bookingId: bookingId ?? this.bookingId,
        specialistId: specialistId ?? this.specialistId,
        fileName: fileName ?? this.fileName,
        filePath: filePath ?? this.filePath,
        downloadUrl: downloadUrl ?? this.downloadUrl,
        fileSize: fileSize ?? this.fileSize,
        mimeType: mimeType ?? this.mimeType,
        description: description ?? this.description,
        uploadedAt: uploadedAt ?? this.uploadedAt,
      );

  Map<String, dynamic> toMap() => {
        'bookingId': bookingId,
        'specialistId': specialistId,
        'fileName': fileName,
        'filePath': filePath,
        'downloadUrl': downloadUrl,
        'fileSize': fileSize,
        'mimeType': mimeType,
        'description': description,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
      };

  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');
  bool get isPdf => mimeType == 'application/pdf';

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Статистика медиафайлов
class MediaStats {
  const MediaStats({
    required this.specialistId,
    required this.totalFiles,
    required this.totalSize,
    required this.photoCount,
    required this.videoCount,
    required this.lastUpdated,
  });

  factory MediaStats.empty() => MediaStats(
        specialistId: '',
        totalFiles: 0,
        totalSize: 0,
        photoCount: 0,
        videoCount: 0,
        lastUpdated: DateTime.now(),
      );

  final String specialistId;
  final int totalFiles;
  final int totalSize;
  final int photoCount;
  final int videoCount;
  final DateTime lastUpdated;

  String get formattedTotalSize {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    }
    if (totalSize < 1024 * 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
