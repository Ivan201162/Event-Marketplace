import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../core/feature_flags.dart';
import '../core/safe_log.dart';

/// Типы файлов для загрузки
enum FileType {
  image,
  video,
  audio,
  document,
  archive,
  other,
}

/// Результат загрузки файла
class UploadResult {
  final String url;
  final String fileName;
  final String filePath;
  final int fileSize;
  final FileType fileType;
  final String? thumbnailUrl;
  final Map<String, dynamic>? metadata;

  const UploadResult({
    required this.url,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.fileType,
    this.thumbnailUrl,
    this.metadata,
  });

  @override
  String toString() {
    return 'UploadResult(url: $url, fileName: $fileName, size: $fileSize, type: $fileType)';
  }
}

/// Ошибки загрузки
class UploadException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const UploadException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'UploadException: $message';
}

/// Сервис для загрузки файлов
class UploadService {
  static const String _imagesPath = 'uploads/images';
  static const String _videosPath = 'uploads/videos';
  static const String _audioPath = 'uploads/audio';
  static const String _documentsPath = 'uploads/documents';
  static const String _archivesPath = 'uploads/archives';
  static const String _otherPath = 'uploads/other';

  /// Проверить доступность сервиса загрузки
  bool get isAvailable => FeatureFlags.uploadEnabled;

  // Лимиты размеров файлов (в байтах)
  static const int _maxImageSize = 10 * 1024 * 1024; // 10 MB
  static const int _maxVideoSize = 100 * 1024 * 1024; // 100 MB
  static const int _maxAudioSize = 50 * 1024 * 1024; // 50 MB
  static const int _maxDocumentSize = 25 * 1024 * 1024; // 25 MB
  static const int _maxArchiveSize = 50 * 1024 * 1024; // 50 MB
  static const int _maxOtherSize = 10 * 1024 * 1024; // 10 MB

  // Разрешенные расширения файлов
  static const List<String> _allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'svg'
  ];
  static const List<String> _allowedVideoExtensions = [
    'mp4',
    'avi',
    'mov',
    'wmv',
    'flv',
    'webm',
    'mkv'
  ];
  static const List<String> _allowedAudioExtensions = [
    'mp3',
    'wav',
    'aac',
    'flac',
    'ogg',
    'm4a'
  ];
  static const List<String> _allowedDocumentExtensions = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'rtf'
  ];
  static const List<String> _allowedArchiveExtensions = [
    'zip',
    'rar',
    '7z',
    'tar',
    'gz'
  ];

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// Загрузить изображение из галереи
  Future<UploadResult?> pickAndUploadImage({
    ImageSource source = ImageSource.gallery,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    if (!FeatureFlags.fileUploadEnabled) {
      SafeLog.info('UploadService: File upload disabled via feature flag');
      return null;
    }

    try {
      SafeLog.info('UploadService: Picking image from ${source.name}');

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality ?? 85,
      );

      if (image == null) {
        SafeLog.info('UploadService: No image selected');
        return null;
      }

      return await uploadFile(
        File(image.path),
        fileType: FileType.image,
      );
    } catch (e, stackTrace) {
      SafeLog.error('UploadService: Error picking image', e, stackTrace);
      throw UploadException('Ошибка выбора изображения: $e');
    }
  }

  /// Загрузить видео из галереи
  Future<UploadResult?> pickAndUploadVideo({
    ImageSource source = ImageSource.gallery,
    Duration? maxDuration,
  }) async {
    if (!FeatureFlags.fileUploadEnabled) {
      SafeLog.info('UploadService: File upload disabled via feature flag');
      return null;
    }

    try {
      SafeLog.info('UploadService: Picking video from ${source.name}');

      final XFile? video = await _imagePicker.pickVideo(
        source: source,
        maxDuration: maxDuration,
      );

      if (video == null) {
        SafeLog.info('UploadService: No video selected');
        return null;
      }

      return await uploadFile(
        File(video.path),
        fileType: FileType.video,
      );
    } catch (e, stackTrace) {
      SafeLog.error('UploadService: Error picking video', e, stackTrace);
      throw UploadException('Ошибка выбора видео: $e');
    }
  }

  /// Выбрать и загрузить файл
  Future<UploadResult?> pickAndUploadFile({
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    if (!FeatureFlags.fileUploadEnabled) {
      SafeLog.info('UploadService: File upload disabled via feature flag');
      return null;
    }

    try {
      SafeLog.info(
          'UploadService: Picking file with extensions: $allowedExtensions');

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
      );

      if (result == null || result.files.isEmpty) {
        SafeLog.info('UploadService: No file selected');
        return null;
      }

      final file = result.files.first;
      if (file.path == null) {
        throw UploadException('Файл не найден');
      }

      return await uploadFile(
        File(file.path!),
        fileType: _getFileTypeFromExtension(file.extension ?? ''),
      );
    } catch (e, stackTrace) {
      SafeLog.error('UploadService: Error picking file', e, stackTrace);
      throw UploadException('Ошибка выбора файла: $e');
    }
  }

  /// Загрузить файл
  Future<UploadResult> uploadFile(
    File file, {
    required FileType fileType,
    String? customPath,
    Map<String, String>? metadata,
  }) async {
    if (!FeatureFlags.fileUploadEnabled) {
      throw UploadException('Загрузка файлов отключена');
    }

    try {
      SafeLog.info('UploadService: Uploading file: ${file.path}');

      // Проверяем существование файла
      if (!await file.exists()) {
        throw UploadException('Файл не существует');
      }

      // Получаем информацию о файле
      final fileStat = await file.stat();
      final fileName = path.basename(file.path);
      final fileExtension =
          path.extension(fileName).toLowerCase().replaceFirst('.', '');

      // Валидация размера файла
      _validateFileSize(fileStat.size, fileType);

      // Валидация расширения файла
      _validateFileExtension(fileExtension, fileType);

      // Генерируем уникальное имя файла
      final uniqueFileName = '${_uuid.v4()}_$fileName';

      // Определяем путь для загрузки
      final uploadPath = customPath ?? _getUploadPath(fileType, uniqueFileName);

      // Создаем референс в Firebase Storage
      final Reference ref = _storage.ref().child(uploadPath);

      // Загружаем файл
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(fileExtension),
          customMetadata: metadata,
        ),
      );

      // Отслеживаем прогресс загрузки
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        SafeLog.info(
            'UploadService: Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // Ждем завершения загрузки
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      SafeLog.info('UploadService: File uploaded successfully: $downloadUrl');

      // Создаем превью для изображений
      String? thumbnailUrl;
      if (fileType == FileType.image) {
        thumbnailUrl = await _createThumbnail(snapshot.ref, fileExtension);
      }

      return UploadResult(
        url: downloadUrl,
        fileName: fileName,
        filePath: uploadPath,
        fileSize: fileStat.size,
        fileType: fileType,
        thumbnailUrl: thumbnailUrl,
        metadata: {
          'originalName': fileName,
          'extension': fileExtension,
          'uploadedAt': DateTime.now().toIso8601String(),
          'contentType': _getContentType(fileExtension),
          ...?metadata,
        },
      );
    } catch (e, stackTrace) {
      SafeLog.error('UploadService: Error uploading file', e, stackTrace);

      if (e is UploadException) {
        rethrow;
      }

      throw UploadException('Ошибка загрузки файла: $e');
    }
  }

  /// Загрузить файл из байтов
  Future<UploadResult> uploadFileFromBytes(
    Uint8List bytes,
    String fileName,
    FileType fileType, {
    String? customPath,
    Map<String, String>? metadata,
  }) async {
    if (!FeatureFlags.fileUploadEnabled) {
      throw UploadException('Загрузка файлов отключена');
    }

    try {
      SafeLog.info('UploadService: Uploading file from bytes: $fileName');

      // Валидация размера файла
      _validateFileSize(bytes.length, fileType);

      // Валидация расширения файла
      final fileExtension =
          path.extension(fileName).toLowerCase().replaceFirst('.', '');
      _validateFileExtension(fileExtension, fileType);

      // Генерируем уникальное имя файла
      final uniqueFileName = '${_uuid.v4()}_$fileName';

      // Определяем путь для загрузки
      final uploadPath = customPath ?? _getUploadPath(fileType, uniqueFileName);

      // Создаем референс в Firebase Storage
      final Reference ref = _storage.ref().child(uploadPath);

      // Загружаем файл
      final UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(
          contentType: _getContentType(fileExtension),
          customMetadata: metadata,
        ),
      );

      // Ждем завершения загрузки
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      SafeLog.info(
          'UploadService: File uploaded successfully from bytes: $downloadUrl');

      // Создаем превью для изображений
      String? thumbnailUrl;
      if (fileType == FileType.image) {
        thumbnailUrl = await _createThumbnail(snapshot.ref, fileExtension);
      }

      return UploadResult(
        url: downloadUrl,
        fileName: fileName,
        filePath: uploadPath,
        fileSize: bytes.length,
        fileType: fileType,
        thumbnailUrl: thumbnailUrl,
        metadata: {
          'originalName': fileName,
          'extension': fileExtension,
          'uploadedAt': DateTime.now().toIso8601String(),
          'contentType': _getContentType(fileExtension),
          ...?metadata,
        },
      );
    } catch (e, stackTrace) {
      SafeLog.error(
          'UploadService: Error uploading file from bytes', e, stackTrace);

      if (e is UploadException) {
        rethrow;
      }

      throw UploadException('Ошибка загрузки файла: $e');
    }
  }

  /// Удалить файл
  Future<void> deleteFile(String filePath) async {
    if (!FeatureFlags.fileUploadEnabled) {
      SafeLog.info('UploadService: File deletion disabled via feature flag');
      return;
    }

    try {
      SafeLog.info('UploadService: Deleting file: $filePath');

      final Reference ref = _storage.ref().child(filePath);
      await ref.delete();

      SafeLog.info('UploadService: File deleted successfully: $filePath');
    } catch (e, stackTrace) {
      SafeLog.error('UploadService: Error deleting file', e, stackTrace);
      throw UploadException('Ошибка удаления файла: $e');
    }
  }

  /// Получить URL файла
  Future<String> getFileUrl(String filePath) async {
    try {
      final Reference ref = _storage.ref().child(filePath);
      return await ref.getDownloadURL();
    } catch (e, stackTrace) {
      SafeLog.error('UploadService: Error getting file URL', e, stackTrace);
      throw UploadException('Ошибка получения URL файла: $e');
    }
  }

  /// Получить метаданные файла
  Future<FullMetadata> getFileMetadata(String filePath) async {
    try {
      final Reference ref = _storage.ref().child(filePath);
      return await ref.getMetadata();
    } catch (e, stackTrace) {
      SafeLog.error(
          'UploadService: Error getting file metadata', e, stackTrace);
      throw UploadException('Ошибка получения метаданных файла: $e');
    }
  }

  /// Валидация размера файла
  void _validateFileSize(int fileSize, FileType fileType) {
    int maxSize;

    switch (fileType) {
      case FileType.image:
        maxSize = _maxImageSize;
        break;
      case FileType.video:
        maxSize = _maxVideoSize;
        break;
      case FileType.audio:
        maxSize = _maxAudioSize;
        break;
      case FileType.document:
        maxSize = _maxDocumentSize;
        break;
      case FileType.archive:
        maxSize = _maxArchiveSize;
        break;
      case FileType.other:
        maxSize = _maxOtherSize;
        break;
    }

    if (fileSize > maxSize) {
      throw UploadException(
        'Размер файла превышает максимально допустимый (${_formatFileSize(maxSize)})',
        code: 'FILE_TOO_LARGE',
      );
    }
  }

  /// Валидация расширения файла
  void _validateFileExtension(String extension, FileType fileType) {
    List<String> allowedExtensions;

    switch (fileType) {
      case FileType.image:
        allowedExtensions = _allowedImageExtensions;
        break;
      case FileType.video:
        allowedExtensions = _allowedVideoExtensions;
        break;
      case FileType.audio:
        allowedExtensions = _allowedAudioExtensions;
        break;
      case FileType.document:
        allowedExtensions = _allowedDocumentExtensions;
        break;
      case FileType.archive:
        allowedExtensions = _allowedArchiveExtensions;
        break;
      case FileType.other:
        allowedExtensions = [
          ..._allowedImageExtensions,
          ..._allowedVideoExtensions,
          ..._allowedAudioExtensions,
          ..._allowedDocumentExtensions,
          ..._allowedArchiveExtensions,
        ];
        break;
    }

    if (!allowedExtensions.contains(extension.toLowerCase())) {
      throw UploadException(
        'Неподдерживаемый тип файла: $extension. Разрешенные типы: ${allowedExtensions.join(', ')}',
        code: 'INVALID_FILE_TYPE',
      );
    }
  }

  /// Определить тип файла по расширению
  FileType _getFileTypeFromExtension(String extension) {
    final ext = extension.toLowerCase();

    if (_allowedImageExtensions.contains(ext)) return FileType.image;
    if (_allowedVideoExtensions.contains(ext)) return FileType.video;
    if (_allowedAudioExtensions.contains(ext)) return FileType.audio;
    if (_allowedDocumentExtensions.contains(ext)) return FileType.document;
    if (_allowedArchiveExtensions.contains(ext)) return FileType.archive;

    return FileType.other;
  }

  /// Получить путь для загрузки
  String _getUploadPath(FileType fileType, String fileName) {
    final timestamp =
        DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD

    switch (fileType) {
      case FileType.image:
        return '$_imagesPath/$timestamp/$fileName';
      case FileType.video:
        return '$_videosPath/$timestamp/$fileName';
      case FileType.audio:
        return '$_audioPath/$timestamp/$fileName';
      case FileType.document:
        return '$_documentsPath/$timestamp/$fileName';
      case FileType.archive:
        return '$_archivesPath/$timestamp/$fileName';
      case FileType.other:
        return '$_otherPath/$timestamp/$fileName';
    }
  }

  /// Получить MIME-тип файла
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      // Изображения
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'svg':
        return 'image/svg+xml';

      // Видео
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mov':
        return 'video/quicktime';
      case 'wmv':
        return 'video/x-ms-wmv';
      case 'flv':
        return 'video/x-flv';
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';

      // Аудио
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'flac':
        return 'audio/flac';
      case 'ogg':
        return 'audio/ogg';
      case 'm4a':
        return 'audio/mp4';

      // Документы
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'rtf':
        return 'application/rtf';

      // Архивы
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case '7z':
        return 'application/x-7z-compressed';
      case 'tar':
        return 'application/x-tar';
      case 'gz':
        return 'application/gzip';

      default:
        return 'application/octet-stream';
    }
  }

  /// Создать превью для изображения
  Future<String?> _createThumbnail(Reference imageRef, String extension) async {
    try {
      // Для простоты возвращаем тот же URL
      // В реальном приложении здесь можно создать уменьшенную копию
      return await imageRef.getDownloadURL();
    } catch (e) {
      SafeLog.warning('UploadService: Could not create thumbnail: $e');
      return null;
    }
  }

  /// Форматировать размер файла
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Получить максимальный размер файла для типа
  int getMaxFileSize(FileType fileType) {
    switch (fileType) {
      case FileType.image:
        return _maxImageSize;
      case FileType.video:
        return _maxVideoSize;
      case FileType.audio:
        return _maxAudioSize;
      case FileType.document:
        return _maxDocumentSize;
      case FileType.archive:
        return _maxArchiveSize;
      case FileType.other:
        return _maxOtherSize;
    }
  }

  /// Получить разрешенные расширения для типа
  List<String> getAllowedExtensions(FileType fileType) {
    switch (fileType) {
      case FileType.image:
        return _allowedImageExtensions;
      case FileType.video:
        return _allowedVideoExtensions;
      case FileType.audio:
        return _allowedAudioExtensions;
      case FileType.document:
        return _allowedDocumentExtensions;
      case FileType.archive:
        return _allowedArchiveExtensions;
      case FileType.other:
        return [
          ..._allowedImageExtensions,
          ..._allowedVideoExtensions,
          ..._allowedAudioExtensions,
          ..._allowedDocumentExtensions,
          ..._allowedArchiveExtensions,
        ];
    }
  }
}
