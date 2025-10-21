import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Тип медиафайла
enum MediaType { photo, video }

/// Расширение для MediaType
extension MediaTypeExtension on MediaType {
  String get displayName {
    switch (this) {
      case MediaType.photo:
        return 'Фото';
      case MediaType.video:
        return 'Видео';
    }
  }

  String get value {
    switch (this) {
      case MediaType.photo:
        return 'photo';
      case MediaType.video:
        return 'video';
    }
  }

  static MediaType fromString(String value) {
    switch (value) {
      case 'photo':
        return MediaType.photo;
      case 'video':
        return MediaType.video;
      default:
        return MediaType.photo;
    }
  }
}

/// Модель медиафайла в профиле специалиста
@immutable
class MediaItem {
  const MediaItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.url,
    required this.createdAt,
    this.thumbnailUrl,
    this.title,
    this.description,
    this.fileSize,
    this.duration,
    this.width,
    this.height,
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory MediaItem.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return MediaItem(
      id: doc.id,
      userId: data['userId'] as String,
      type: MediaTypeExtension.fromString(data['type'] as String),
      url: data['url'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      thumbnailUrl: data['thumbnailUrl'] as String?,
      title: data['title'] as String?,
      description: data['description'] as String?,
      fileSize: data['fileSize'] as int?,
      duration: data['duration'] as int?,
      width: data['width'] as int?,
      height: data['height'] as int?,
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  /// Создать из Map
  factory MediaItem.fromMap(Map<String, dynamic> data) => MediaItem(
    id: data['id'] as String,
    userId: data['userId'] as String,
    type: MediaTypeExtension.fromString(data['type'] as String),
    url: data['url'] as String,
    createdAt: (data['createdAt'] as Timestamp).toDate(),
    thumbnailUrl: data['thumbnailUrl'] as String?,
    title: data['title'] as String?,
    description: data['description'] as String?,
    fileSize: data['fileSize'] as int?,
    duration: data['duration'] as int?,
    width: data['width'] as int?,
    height: data['height'] as int?,
    metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
  );

  final String id;
  final String userId;
  final MediaType type;
  final String url;
  final DateTime createdAt;
  final String? thumbnailUrl;
  final String? title;
  final String? description;
  final int? fileSize;
  final int? duration; // в секундах для видео
  final int? width;
  final int? height;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'type': type.value,
    'url': url,
    'createdAt': Timestamp.fromDate(createdAt),
    'thumbnailUrl': thumbnailUrl,
    'title': title,
    'description': description,
    'fileSize': fileSize,
    'duration': duration,
    'width': width,
    'height': height,
    'metadata': metadata,
  };

  /// Создать копию с изменениями
  MediaItem copyWith({
    String? id,
    String? userId,
    MediaType? type,
    String? url,
    DateTime? createdAt,
    String? thumbnailUrl,
    String? title,
    String? description,
    int? fileSize,
    int? duration,
    int? width,
    int? height,
    Map<String, dynamic>? metadata,
  }) => MediaItem(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    url: url ?? this.url,
    createdAt: createdAt ?? this.createdAt,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    title: title ?? this.title,
    description: description ?? this.description,
    fileSize: fileSize ?? this.fileSize,
    duration: duration ?? this.duration,
    width: width ?? this.width,
    height: height ?? this.height,
    metadata: metadata ?? this.metadata,
  );

  /// Получить размер файла в читаемом формате
  String get formattedFileSize {
    if (fileSize == null) {
      return 'Неизвестно';
    }

    final bytes = fileSize!;
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Получить длительность видео в читаемом формате
  String get formattedDuration {
    if (duration == null) {
      return '';
    }

    final seconds = duration!;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes > 0) {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '0:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Получить разрешение медиафайла
  String get resolution {
    if (width == null || height == null) {
      return '';
    }
    return '${width}x$height';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MediaItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'MediaItem(id: $id, userId: $userId, type: $type, url: $url, createdAt: $createdAt)';
}
