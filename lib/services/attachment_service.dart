import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

import '../core/logger.dart';
import '../models/chat_attachment.dart';

/// Сервис для работы с вложениями в чатах
class AttachmentService {
  static final AttachmentService _instance = AttachmentService._internal();
  factory AttachmentService() => _instance;
  AttachmentService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Максимальный размер файла (10 MB)
  static const int maxFileSize = 10 * 1024 * 1024;

  /// Поддерживаемые типы файлов
  static const Map<String, List<String>> supportedFileTypes = {
    'image': ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    'video': ['mp4', 'avi', 'mov', 'wmv', 'flv'],
    'document': ['pdf', 'doc', 'docx', 'txt', 'rtf'],
    'audio': ['mp3', 'wav', 'aac', 'ogg', 'm4a'],
  };

  /// Загрузить файл
  Future<ChatAttachment?> uploadFile({
    required String messageId,
    required String userId,
    required String filePath,
    required String originalFileName,
    required Uint8List fileData,
    String? thumbnailPath,
  }) async {
    try {
      AppLogger.logI('Начало загрузки файла: $originalFileName', 'attachment_service');

      // Проверяем размер файла
      if (fileData.length > maxFileSize) {
        AppLogger.logE('Файл слишком большой: ${fileData.length} байт', 'attachment_service');
        throw Exception('Файл слишком большой. Максимальный размер: ${maxFileSize ~/ (1024 * 1024)} MB');
      }

      // Определяем тип файла
      final fileType = _getFileType(originalFileName);
      final mimeType = _getMimeType(originalFileName);

      // Генерируем уникальное имя файла
      final fileExtension = path.extension(originalFileName);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${userId}$fileExtension';

      // Загружаем основной файл
      final fileRef = _storage.ref().child('chat_attachments/$fileName');
      final uploadTask = fileRef.putData(fileData);
      final snapshot = await uploadTask;
      final fileUrl = await snapshot.ref.getDownloadURL();

      String? thumbnailUrl;

      // Если это изображение, создаем миниатюру
      if (fileType == AttachmentType.image) {
        thumbnailUrl = await _createThumbnail(fileData, fileName);
      }

      // Создаем запись в Firestore
      final attachmentId = 'attachment_${DateTime.now().millisecondsSinceEpoch}';
      final attachment = ChatAttachment(
        id: attachmentId,
        messageId: messageId,
        fileName: fileName,
        originalFileName: originalFileName,
        fileUrl: fileUrl,
        thumbnailUrl: thumbnailUrl,
        type: fileType,
        fileSize: fileData.length,
        mimeType: mimeType,
        uploadedAt: DateTime.now(),
        uploadedBy: userId,
        metadata: {
          'width': fileType == AttachmentType.image ? _getImageWidth(fileData) : null,
          'height': fileType == AttachmentType.image ? _getImageHeight(fileData) : null,
          'duration': fileType == AttachmentType.video ? null : null, // TODO: Получить длительность видео
        },
      );

      await _firestore
          .collection('chat_attachments')
          .doc(attachmentId)
          .set(attachment.toMap());

      AppLogger.logI('Файл успешно загружен: $fileName', 'attachment_service');
      return attachment;
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка загрузки файла', 'attachment_service', e, stackTrace);
      return null;
    }
  }

  /// Создать миниатюру изображения
  Future<String?> _createThumbnail(Uint8List imageData, String fileName) async {
    try {
      // Декодируем изображение
      final image = img.decodeImage(imageData);
      if (image == null) return null;

      // Создаем миниатюру (максимум 200x200)
      final thumbnail = img.copyResize(image, width: 200, height: 200);
      final thumbnailData = Uint8List.fromList(img.encodeJpg(thumbnail, quality: 80));

      // Загружаем миниатюру
      final thumbnailName = 'thumb_$fileName';
      final thumbnailRef = _storage.ref().child('chat_attachments/thumbnails/$thumbnailName');
      final uploadTask = thumbnailRef.putData(thumbnailData);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      AppLogger.logE('Ошибка создания миниатюры', 'attachment_service', e);
      return null;
    }
  }

  /// Получить вложения для сообщения
  Future<List<ChatAttachment>> getMessageAttachments(String messageId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chat_attachments')
          .where('messageId', isEqualTo: messageId)
          .orderBy('uploadedAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => ChatAttachment.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка получения вложений', 'attachment_service', e, stackTrace);
      return [];
    }
  }

  /// Удалить вложение
  Future<bool> deleteAttachment(String attachmentId) async {
    try {
      // Получаем информацию о вложении
      final doc = await _firestore.collection('chat_attachments').doc(attachmentId).get();
      if (!doc.exists) return false;

      final attachment = ChatAttachment.fromMap(doc.data()!, doc.id);

      // Удаляем файл из Storage
      final fileRef = _storage.ref().child('chat_attachments/${attachment.fileName}');
      await fileRef.delete();

      // Удаляем миниатюру, если есть
      if (attachment.thumbnailUrl != null) {
        final thumbnailRef = _storage.ref().child('chat_attachments/thumbnails/thumb_${attachment.fileName}');
        await thumbnailRef.delete();
      }

      // Удаляем запись из Firestore
      await _firestore.collection('chat_attachments').doc(attachmentId).delete();

      AppLogger.logI('Вложение удалено: $attachmentId', 'attachment_service');
      return true;
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка удаления вложения', 'attachment_service', e, stackTrace);
      return false;
    }
  }

  /// Определить тип файла по расширению
  AttachmentType _getFileType(String fileName) {
    final extension = path.extension(fileName).toLowerCase().substring(1);
    
    if (supportedFileTypes['image']!.contains(extension)) {
      return AttachmentType.image;
    } else if (supportedFileTypes['video']!.contains(extension)) {
      return AttachmentType.video;
    } else if (supportedFileTypes['document']!.contains(extension)) {
      return AttachmentType.document;
    } else if (supportedFileTypes['audio']!.contains(extension)) {
      return AttachmentType.audio;
    } else {
      return AttachmentType.other;
    }
  }

  /// Получить MIME тип файла
  String _getMimeType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.mp4':
        return 'video/mp4';
      case '.avi':
        return 'video/avi';
      case '.mov':
        return 'video/quicktime';
      case '.wmv':
        return 'video/x-ms-wmv';
      case '.flv':
        return 'video/x-flv';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.txt':
        return 'text/plain';
      case '.rtf':
        return 'application/rtf';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.aac':
        return 'audio/aac';
      case '.ogg':
        return 'audio/ogg';
      case '.m4a':
        return 'audio/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  /// Получить ширину изображения
  int? _getImageWidth(Uint8List imageData) {
    try {
      final image = img.decodeImage(imageData);
      return image?.width;
    } catch (e) {
      return null;
    }
  }

  /// Получить высоту изображения
  int? _getImageHeight(Uint8List imageData) {
    try {
      final image = img.decodeImage(imageData);
      return image?.height;
    } catch (e) {
      return null;
    }
  }

  /// Проверить, поддерживается ли тип файла
  bool isFileTypeSupported(String fileName) {
    final extension = path.extension(fileName).toLowerCase().substring(1);
    return supportedFileTypes.values.any((types) => types.contains(extension));
  }

  /// Получить список поддерживаемых расширений
  List<String> getSupportedExtensions() {
    return supportedFileTypes.values.expand((types) => types).toList();
  }
}
