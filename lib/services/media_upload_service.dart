import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

/// Сервис для загрузки медиафайлов в Firebase Storage
class MediaUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const int _maxFileSize = 200 * 1024 * 1024; // 200 МБ
  static const List<String> _allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> _allowedVideoTypes = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'];
  static const List<String> _allowedAudioTypes = ['mp3', 'wav', 'aac', 'ogg', 'm4a'];
  static const List<String> _allowedDocumentTypes = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'rtf',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
  ];

  /// Загрузить изображение из галереи
  static Future<MediaUploadResult?> pickAndUploadImage({
    required String chatId,
    required String userId,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      final file = File(image.path);
      final fileSize = await file.length();

      if (fileSize > _maxFileSize) {
        throw Exception('Размер файла превышает 200 МБ');
      }

      return await _uploadFile(
        file: file,
        chatId: chatId,
        userId: userId,
        mediaType: MediaType.image,
      );
    } catch (e) {
      throw Exception('Ошибка загрузки изображения: $e');
    }
  }

  /// Загрузить видео из галереи
  static Future<MediaUploadResult?> pickAndUploadVideo({
    required String chatId,
    required String userId,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 10),
      );

      if (video == null) return null;

      final file = File(video.path);
      final fileSize = await file.length();

      if (fileSize > _maxFileSize) {
        throw Exception('Размер файла превышает 200 МБ');
      }

      return await _uploadFile(
        file: file,
        chatId: chatId,
        userId: userId,
        mediaType: MediaType.video,
      );
    } catch (e) {
      throw Exception('Ошибка загрузки видео: $e');
    }
  }

  /// Загрузить аудиофайл
  static Future<MediaUploadResult?> pickAndUploadAudio({
    required String chatId,
    required String userId,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);

      if (result == null || result.files.isEmpty) return null;

      final file = File(result.files.first.path!);
      final fileSize = await file.length();

      if (fileSize > _maxFileSize) {
        throw Exception('Размер файла превышает 200 МБ');
      }

      return await _uploadFile(
        file: file,
        chatId: chatId,
        userId: userId,
        mediaType: MediaType.audio,
      );
    } catch (e) {
      throw Exception('Ошибка загрузки аудио: $e');
    }
  }

  /// Загрузить документ
  static Future<MediaUploadResult?> pickAndUploadDocument({
    required String chatId,
    required String userId,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedDocumentTypes,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = File(result.files.first.path!);
      final fileSize = await file.length();

      if (fileSize > _maxFileSize) {
        throw Exception('Размер файла превышает 200 МБ');
      }

      return await _uploadFile(
        file: file,
        chatId: chatId,
        userId: userId,
        mediaType: MediaType.document,
      );
    } catch (e) {
      throw Exception('Ошибка загрузки документа: $e');
    }
  }

  /// Загрузить любой файл
  static Future<MediaUploadResult?> pickAndUploadFile({
    required String chatId,
    required String userId,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles();

      if (result == null || result.files.isEmpty) return null;

      final file = File(result.files.first.path!);
      final fileSize = await file.length();

      if (fileSize > _maxFileSize) {
        throw Exception('Размер файла превышает 200 МБ');
      }

      final extension = path.extension(file.path).toLowerCase().substring(1);
      final mediaType = _getMediaTypeFromExtension(extension);

      return await _uploadFile(file: file, chatId: chatId, userId: userId, mediaType: mediaType);
    } catch (e) {
      throw Exception('Ошибка загрузки файла: $e');
    }
  }

  /// Загрузить файл в Firebase Storage
  static Future<MediaUploadResult> _uploadFile({
    required File file,
    required String chatId,
    required String userId,
    required MediaType mediaType,
  }) async {
    try {
      final fileName = path.basename(file.path);
      final fileExtension = path.extension(fileName).toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';

      final storagePath = 'chat_media/$chatId/$userId/$uniqueFileName';
      final ref = _storage.ref().child(storagePath);

      // Загружаем файл
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Получаем метаданные
      final metadata = await snapshot.ref.getMetadata();
      final fileSize = metadata.size ?? 0;

      // Создаем превью для изображений
      String? thumbnailUrl;
      if (mediaType == MediaType.image) {
        thumbnailUrl = await _createThumbnail(file, ref);
      }

      return MediaUploadResult(
        fileUrl: downloadUrl,
        fileName: fileName,
        fileType: fileExtension,
        fileSize: fileSize,
        mediaType: mediaType,
        thumbnailUrl: thumbnailUrl,
        storagePath: storagePath,
      );
    } catch (e) {
      throw Exception('Ошибка загрузки файла: $e');
    }
  }

  /// Создать превью для изображения
  static Future<String?> _createThumbnail(File imageFile, Reference ref) async {
    try {
      // Для простоты используем то же изображение как превью
      // В реальном приложении здесь должна быть логика создания миниатюры
      return null;
    } catch (e) {
      debugPrint('Ошибка создания превью: $e');
      return null;
    }
  }

  /// Определить тип медиа по расширению файла
  static MediaType _getMediaTypeFromExtension(String extension) {
    if (_allowedImageTypes.contains(extension)) {
      return MediaType.image;
    } else if (_allowedVideoTypes.contains(extension)) {
      return MediaType.video;
    } else if (_allowedAudioTypes.contains(extension)) {
      return MediaType.audio;
    } else if (_allowedDocumentTypes.contains(extension)) {
      return MediaType.document;
    } else {
      return MediaType.file;
    }
  }

  /// Удалить файл из Firebase Storage
  static Future<void> deleteFile(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.delete();
    } catch (e) {
      debugPrint('Ошибка удаления файла: $e');
    }
  }

  /// Получить размер файла в читаемом формате
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Проверить, поддерживается ли тип файла
  static bool isFileTypeSupported(String extension) {
    final allAllowedTypes = [
      ..._allowedImageTypes,
      ..._allowedVideoTypes,
      ..._allowedAudioTypes,
      ..._allowedDocumentTypes,
    ];
    return allAllowedTypes.contains(extension.toLowerCase());
  }
}

/// Типы медиафайлов
enum MediaType { image, video, audio, document, file }

/// Результат загрузки медиафайла
class MediaUploadResult {
  const MediaUploadResult({
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.mediaType,
    this.thumbnailUrl,
    required this.storagePath,
  });

  final String fileUrl;
  final String fileName;
  final String fileType;
  final int fileSize;
  final MediaType mediaType;
  final String? thumbnailUrl;
  final String storagePath;

  /// Получить размер файла в читаемом формате
  String get formattedFileSize => MediaUploadService.formatFileSize(fileSize);

  /// Получить иконку для типа файла
  String get typeIcon {
    switch (mediaType) {
      case MediaType.image:
        return '🖼️';
      case MediaType.video:
        return '🎥';
      case MediaType.audio:
        return '🎵';
      case MediaType.document:
        return '📄';
      case MediaType.file:
        return '📎';
    }
  }

  /// Получить название типа файла
  String get typeName {
    switch (mediaType) {
      case MediaType.image:
        return 'Изображение';
      case MediaType.video:
        return 'Видео';
      case MediaType.audio:
        return 'Аудио';
      case MediaType.document:
        return 'Документ';
      case MediaType.file:
        return 'Файл';
    }
  }
}
