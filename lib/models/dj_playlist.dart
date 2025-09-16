import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип медиафайла
enum MediaType {
  audio,
  video,
  image,
  playlist,
}

/// Статус медиафайла
enum MediaStatus {
  pending,
  processing,
  ready,
  error,
  deleted,
}

/// Модель медиафайла для диджея
class MediaFile {
  final String id;
  final String djId;
  final String fileName;
  final String originalName;
  final String filePath;
  final String? thumbnailPath;
  final MediaType type;
  final MediaStatus status;
  final int fileSize;
  final Duration? duration;
  final String? mimeType;
  final Map<String, dynamic> metadata;
  final DateTime uploadedAt;
  final DateTime updatedAt;

  const MediaFile({
    required this.id,
    required this.djId,
    required this.fileName,
    required this.originalName,
    required this.filePath,
    this.thumbnailPath,
    required this.type,
    required this.status,
    required this.fileSize,
    this.duration,
    this.mimeType,
    this.metadata = const {},
    required this.uploadedAt,
    required this.updatedAt,
  });

  /// Создать из Map
  factory MediaFile.fromMap(Map<String, dynamic> data) {
    return MediaFile(
      id: data['id'] ?? '',
      djId: data['djId'] ?? '',
      fileName: data['fileName'] ?? '',
      originalName: data['originalName'] ?? '',
      filePath: data['filePath'] ?? '',
      thumbnailPath: data['thumbnailPath'],
      type: MediaType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MediaType.audio,
      ),
      status: MediaStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MediaStatus.pending,
      ),
      fileSize: data['fileSize'] ?? 0,
      duration: data['duration'] != null
          ? Duration(milliseconds: data['duration'])
          : null,
      mimeType: data['mimeType'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'djId': djId,
      'fileName': fileName,
      'originalName': originalName,
      'filePath': filePath,
      'thumbnailPath': thumbnailPath,
      'type': type.name,
      'status': status.name,
      'fileSize': fileSize,
      'duration': duration?.inMilliseconds,
      'mimeType': mimeType,
      'metadata': metadata,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Копировать с изменениями
  MediaFile copyWith({
    String? id,
    String? djId,
    String? fileName,
    String? originalName,
    String? filePath,
    String? thumbnailPath,
    MediaType? type,
    MediaStatus? status,
    int? fileSize,
    Duration? duration,
    String? mimeType,
    Map<String, dynamic>? metadata,
    DateTime? uploadedAt,
    DateTime? updatedAt,
  }) {
    return MediaFile(
      id: id ?? this.id,
      djId: djId ?? this.djId,
      fileName: fileName ?? this.fileName,
      originalName: originalName ?? this.originalName,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      type: type ?? this.type,
      status: status ?? this.status,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      mimeType: mimeType ?? this.mimeType,
      metadata: metadata ?? this.metadata,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Получить размер файла в читаемом формате
  String get formattedFileSize {
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
  String get formattedDuration {
    if (duration == null) return 'Неизвестно';

    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Проверить, является ли файл аудио
  bool get isAudio => type == MediaType.audio;

  /// Проверить, является ли файл видео
  bool get isVideo => type == MediaType.video;

  /// Проверить, является ли файл изображением
  bool get isImage => type == MediaType.image;

  /// Проверить, готов ли файл к использованию
  bool get isReady => status == MediaStatus.ready;
}

/// Модель плейлиста диджея
class DJPlaylist {
  final String id;
  final String djId;
  final String name;
  final String? description;
  final String? coverImagePath;
  final List<String> mediaFileIds;
  final List<MediaFile> mediaFiles;
  final Map<String, dynamic> settings;
  final bool isPublic;
  final bool isDefault;
  final int playCount;
  final double? averageRating;
  final int ratingCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DJPlaylist({
    required this.id,
    required this.djId,
    required this.name,
    this.description,
    this.coverImagePath,
    required this.mediaFileIds,
    required this.mediaFiles,
    this.settings = const {},
    required this.isPublic,
    required this.isDefault,
    required this.playCount,
    this.averageRating,
    required this.ratingCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать из Map
  factory DJPlaylist.fromMap(Map<String, dynamic> data) {
    return DJPlaylist(
      id: data['id'] ?? '',
      djId: data['djId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      coverImagePath: data['coverImagePath'],
      mediaFileIds: List<String>.from(data['mediaFileIds'] ?? []),
      mediaFiles: [], // Будет заполнено отдельно
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      isPublic: data['isPublic'] ?? false,
      isDefault: data['isDefault'] ?? false,
      playCount: data['playCount'] ?? 0,
      averageRating: data['averageRating']?.toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'djId': djId,
      'name': name,
      'description': description,
      'coverImagePath': coverImagePath,
      'mediaFileIds': mediaFileIds,
      'settings': settings,
      'isPublic': isPublic,
      'isDefault': isDefault,
      'playCount': playCount,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Копировать с изменениями
  DJPlaylist copyWith({
    String? id,
    String? djId,
    String? name,
    String? description,
    String? coverImagePath,
    List<String>? mediaFileIds,
    List<MediaFile>? mediaFiles,
    Map<String, dynamic>? settings,
    bool? isPublic,
    bool? isDefault,
    int? playCount,
    double? averageRating,
    int? ratingCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DJPlaylist(
      id: id ?? this.id,
      djId: djId ?? this.djId,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      mediaFileIds: mediaFileIds ?? this.mediaFileIds,
      mediaFiles: mediaFiles ?? this.mediaFiles,
      settings: settings ?? this.settings,
      isPublic: isPublic ?? this.isPublic,
      isDefault: isDefault ?? this.isDefault,
      playCount: playCount ?? this.playCount,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Получить общую длительность плейлиста
  Duration get totalDuration {
    return mediaFiles.fold(
      Duration.zero,
      (total, file) => total + (file.duration ?? Duration.zero),
    );
  }

  /// Получить общий размер плейлиста
  int get totalSize {
    return mediaFiles.fold(0, (total, file) => total + file.fileSize);
  }

  /// Получить количество треков
  int get trackCount => mediaFiles.length;

  /// Получить длительность в читаемом формате
  String get formattedDuration {
    final total = totalDuration;
    final hours = total.inHours;
    final minutes = total.inMinutes % 60;

    if (hours > 0) {
      return '${hours}ч ${minutes}м';
    } else {
      return '${minutes}м';
    }
  }

  /// Получить размер в читаемом формате
  String get formattedSize {
    final size = totalSize;
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Получить рейтинг в виде строки
  String get ratingString {
    if (averageRating == null || ratingCount == 0) {
      return 'Нет оценок';
    }
    return '${averageRating!.toStringAsFixed(1)} (${ratingCount} оценок)';
  }
}

/// Модель VK плейлиста
class VKPlaylist {
  final String id;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final int trackCount;
  final String? ownerId;
  final String? ownerName;
  final DateTime? createdAt;
  final List<VKTrack> tracks;

  const VKPlaylist({
    required this.id,
    required this.title,
    this.description,
    this.coverImageUrl,
    required this.trackCount,
    this.ownerId,
    this.ownerName,
    this.createdAt,
    required this.tracks,
  });

  /// Создать из Map
  factory VKPlaylist.fromMap(Map<String, dynamic> data) {
    return VKPlaylist(
      id: data['id']?.toString() ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      coverImageUrl: data['cover_image']?[0]?['url'],
      trackCount: data['count'] ?? 0,
      ownerId: data['owner_id']?.toString(),
      ownerName: data['owner_name'],
      createdAt: data['create_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['create_time'] * 1000)
          : null,
      tracks: (data['tracks'] as List?)
              ?.map((track) => VKTrack.fromMap(track))
              .toList() ??
          [],
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cover_image': coverImageUrl != null
          ? [
              {'url': coverImageUrl}
            ]
          : null,
      'count': trackCount,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'create_time': createdAt?.millisecondsSinceEpoch ~/ 1000,
      'tracks': tracks.map((track) => track.toMap()).toList(),
    };
  }
}

/// Модель VK трека
class VKTrack {
  final String id;
  final String title;
  final String artist;
  final Duration duration;
  final String? url;
  final String? albumTitle;
  final String? albumCoverUrl;

  const VKTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    this.url,
    this.albumTitle,
    this.albumCoverUrl,
  });

  /// Создать из Map
  factory VKTrack.fromMap(Map<String, dynamic> data) {
    return VKTrack(
      id: data['id']?.toString() ?? '',
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      duration: Duration(seconds: data['duration'] ?? 0),
      url: data['url'],
      albumTitle: data['album']?['title'],
      albumCoverUrl: data['album']?['thumb']?['photo_300'],
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'duration': duration.inSeconds,
      'url': url,
      'album': albumTitle != null
          ? {
              'title': albumTitle,
              'thumb':
                  albumCoverUrl != null ? {'photo_300': albumCoverUrl} : null,
            }
          : null,
    };
  }

  /// Получить длительность в читаемом формате
  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
