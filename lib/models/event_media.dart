import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип медиафайла
enum MediaType {
  image,
  video,
  audio,
  document,
}

/// Статус медиафайла
enum MediaStatus {
  uploading,
  processing,
  ready,
  failed,
  deleted,
}

/// Медиафайл мероприятия
class EventMedia {
  const EventMedia({
    required this.id,
    required this.eventId,
    required this.uploadedBy,
    required this.uploadedByName,
    this.uploadedByPhoto,
    required this.fileName,
    required this.fileUrl,
    this.thumbnailUrl,
    required this.type,
    required this.status,
    required this.fileSize,
    this.mimeType,
    this.duration,
    this.metadata,
    this.tags = const [],
    this.isPublic = true,
    this.isFeatured = false,
    this.likesCount = 0,
    this.likedBy = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать из Map
  factory EventMedia.fromMap(Map<String, dynamic> data) => EventMedia(
        id: data['id'] as String? ?? '',
        eventId: data['eventId'] as String? ?? '',
        uploadedBy: data['uploadedBy'] as String? ?? '',
        uploadedByName: data['uploadedByName'] as String? ?? '',
        uploadedByPhoto: data['uploadedByPhoto'] as String?,
        fileName: data['fileName'] as String? ?? '',
        fileUrl: data['fileUrl'] as String? ?? '',
        thumbnailUrl: data['thumbnailUrl'] as String?,
        type: MediaType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => MediaType.image,
        ),
        status: MediaStatus.values.firstWhere(
          (e) => e.name == data['status'],
          orElse: () => MediaStatus.ready,
        ),
        fileSize: data['fileSize'] as int? ?? 0,
        mimeType: data['mimeType'] as String?,
        duration: data['duration'] != null ? Duration(milliseconds: data['duration'] as int) : null,
        metadata: data['metadata'] as Map<String, dynamic>?,
        tags: List<String>.from((data['tags'] as List<dynamic>?) ?? []),
        isPublic: data['isPublic'] as bool? ?? true,
        isFeatured: data['isFeatured'] as bool? ?? false,
        likesCount: data['likesCount'] as int? ?? 0,
        likedBy: List<String>.from((data['likedBy'] as List<dynamic>?) ?? []),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
  final String id;
  final String eventId;
  final String uploadedBy;
  final String uploadedByName;
  final String? uploadedByPhoto;
  final String fileName;
  final String fileUrl;
  final String? thumbnailUrl;
  final MediaType type;
  final MediaStatus status;
  final int fileSize;
  final String? mimeType;
  final Duration? duration; // Для видео/аудио
  final Map<String, dynamic>? metadata;
  final List<String> tags;
  final bool isPublic;
  final bool isFeatured;
  final int likesCount;
  final List<String> likedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'eventId': eventId,
        'uploadedBy': uploadedBy,
        'uploadedByName': uploadedByName,
        'uploadedByPhoto': uploadedByPhoto,
        'fileName': fileName,
        'fileUrl': fileUrl,
        'thumbnailUrl': thumbnailUrl,
        'type': type.name,
        'status': status.name,
        'fileSize': fileSize,
        'mimeType': mimeType,
        'duration': duration?.inMilliseconds,
        'metadata': metadata,
        'tags': tags,
        'isPublic': isPublic,
        'isFeatured': isFeatured,
        'likesCount': likesCount,
        'likedBy': likedBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// Создать копию с изменениями
  EventMedia copyWith({
    String? id,
    String? eventId,
    String? uploadedBy,
    String? uploadedByName,
    String? uploadedByPhoto,
    String? fileName,
    String? fileUrl,
    String? thumbnailUrl,
    MediaType? type,
    MediaStatus? status,
    int? fileSize,
    String? mimeType,
    Duration? duration,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    bool? isPublic,
    bool? isFeatured,
    int? likesCount,
    List<String>? likedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      EventMedia(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        uploadedBy: uploadedBy ?? this.uploadedBy,
        uploadedByName: uploadedByName ?? this.uploadedByName,
        uploadedByPhoto: uploadedByPhoto ?? this.uploadedByPhoto,
        fileName: fileName ?? this.fileName,
        fileUrl: fileUrl ?? this.fileUrl,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        type: type ?? this.type,
        status: status ?? this.status,
        fileSize: fileSize ?? this.fileSize,
        mimeType: mimeType ?? this.mimeType,
        duration: duration ?? this.duration,
        metadata: metadata ?? this.metadata,
        tags: tags ?? this.tags,
        isPublic: isPublic ?? this.isPublic,
        isFeatured: isFeatured ?? this.isFeatured,
        likesCount: likesCount ?? this.likesCount,
        likedBy: likedBy ?? this.likedBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Проверить, лайкнул ли пользователь файл
  bool isLikedBy(String userId) => likedBy.contains(userId);

  /// Получить размер файла в читаемом формате
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Получить длительность в читаемом формате
  String get durationFormatted {
    if (duration == null) return '';

    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;

    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '0:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Проверить, является ли файл изображением
  bool get isImage => type == MediaType.image;

  /// Проверить, является ли файл видео
  bool get isVideo => type == MediaType.video;

  /// Проверить, является ли файл аудио
  bool get isAudio => type == MediaType.audio;

  /// Проверить, является ли файл документом
  bool get isDocument => type == MediaType.document;
}

/// Коллекция медиафайлов мероприятия
class EventMediaCollection {
  const EventMediaCollection({
    required this.eventId,
    required this.media,
    required this.totalCount,
    required this.publicCount,
    required this.featuredCount,
    required this.typeCounts,
    required this.lastUpdated,
  });
  final String eventId;
  final List<EventMedia> media;
  final int totalCount;
  final int publicCount;
  final int featuredCount;
  final Map<MediaType, int> typeCounts;
  final DateTime lastUpdated;

  /// Получить медиафайлы по типу
  List<EventMedia> getMediaByType(MediaType type) => media.where((m) => m.type == type).toList();

  /// Получить публичные медиафайлы
  List<EventMedia> get publicMedia => media.where((m) => m.isPublic).toList();

  /// Получить рекомендуемые медиафайлы
  List<EventMedia> get featuredMedia => media.where((m) => m.isFeatured).toList();

  /// Получить медиафайлы пользователя
  List<EventMedia> getUserMedia(String userId) =>
      media.where((m) => m.uploadedBy == userId).toList();

  /// Получить общий размер всех файлов
  int get totalSize => media.fold(0, (total, m) => total + m.fileSize);

  /// Получить общий размер в читаемом формате
  String get totalSizeFormatted {
    final size = totalSize;
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
