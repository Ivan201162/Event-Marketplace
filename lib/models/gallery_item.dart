import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип медиафайла в галерее
enum GalleryItemType {
  image,
  video,
}

/// Модель элемента галереи
class GalleryItem {
  const GalleryItem({
    required this.id,
    required this.specialistId,
    required this.type,
    required this.url,
    required this.thumbnailUrl,
    required this.title,
    this.description,
    required this.createdAt,
    this.updatedAt,
    this.tags = const [],
    this.isPublic = true,
    this.isFeatured = false,
    this.viewCount = 0,
    this.likeCount = 0,
    this.fileSize,
    this.duration, // для видео в секундах
    this.width,
    this.height,
  });

  /// Создать из документа Firestore
  factory GalleryItem.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return GalleryItem(
      id: doc.id,
      specialistId: data['specialistId']?.toString() ?? '',
      type: GalleryItemType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => GalleryItemType.image,
      ),
      url: data['url']?.toString() ?? '',
      thumbnailUrl: data['thumbnailUrl']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      tags:
          (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [],
      isPublic: data['isPublic'] != false,
      isFeatured: data['isFeatured'] == true,
      viewCount: (data['viewCount'] as num?)?.toInt() ?? 0,
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      fileSize: (data['fileSize'] as num?)?.toInt(),
      duration: (data['duration'] as num?)?.toDouble(),
      width: (data['width'] as num?)?.toInt(),
      height: (data['height'] as num?)?.toInt(),
    );
  }

  /// Создать из Map
  factory GalleryItem.fromMap(Map<String, dynamic> data) => GalleryItem(
        id: data['id']?.toString() ?? '',
        specialistId: data['specialistId']?.toString() ?? '',
        type: GalleryItemType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => GalleryItemType.image,
        ),
        url: data['url']?.toString() ?? '',
        thumbnailUrl: data['thumbnailUrl']?.toString() ?? '',
        title: data['title']?.toString() ?? '',
        description: data['description']?.toString(),
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] as Timestamp).toDate()
            : null,
        tags: (data['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        isPublic: data['isPublic'] != false,
        isFeatured: data['isFeatured'] == true,
        viewCount: (data['viewCount'] as num?)?.toInt() ?? 0,
        likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
        fileSize: (data['fileSize'] as num?)?.toInt(),
        duration: (data['duration'] as num?)?.toDouble(),
        width: (data['width'] as num?)?.toInt(),
        height: (data['height'] as num?)?.toInt(),
      );

  final String id;
  final String specialistId;
  final GalleryItemType type;
  final String url;
  final String thumbnailUrl;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> tags;
  final bool isPublic;
  final bool isFeatured;
  final int viewCount;
  final int likeCount;
  final int? fileSize;
  final double? duration;
  final int? width;
  final int? height;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'type': type.name,
        'url': url,
        'thumbnailUrl': thumbnailUrl,
        'title': title,
        'description': description,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'tags': tags,
        'isPublic': isPublic,
        'isFeatured': isFeatured,
        'viewCount': viewCount,
        'likeCount': likeCount,
        'fileSize': fileSize,
        'duration': duration,
        'width': width,
        'height': height,
      };

  /// Создать копию с изменениями
  GalleryItem copyWith({
    String? id,
    String? specialistId,
    GalleryItemType? type,
    String? url,
    String? thumbnailUrl,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    bool? isPublic,
    bool? isFeatured,
    int? viewCount,
    int? likeCount,
    int? fileSize,
    double? duration,
    int? width,
    int? height,
  }) =>
      GalleryItem(
        id: id ?? this.id,
        specialistId: specialistId ?? this.specialistId,
        type: type ?? this.type,
        url: url ?? this.url,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        title: title ?? this.title,
        description: description ?? this.description,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        tags: tags ?? this.tags,
        isPublic: isPublic ?? this.isPublic,
        isFeatured: isFeatured ?? this.isFeatured,
        viewCount: viewCount ?? this.viewCount,
        likeCount: likeCount ?? this.likeCount,
        fileSize: fileSize ?? this.fileSize,
        duration: duration ?? this.duration,
        width: width ?? this.width,
        height: height ?? this.height,
      );

  /// Проверить, является ли файл изображением
  bool get isImage => type == GalleryItemType.image;

  /// Проверить, является ли файл видео
  bool get isVideo => type == GalleryItemType.video;

  /// Получить размер файла в читаемом формате
  String get formattedFileSize {
    if (fileSize == null) return '';

    final bytes = fileSize!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Получить длительность видео в читаемом формате
  String get formattedDuration {
    if (duration == null) return '';

    final totalSeconds = duration!.toInt();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Получить разрешение в читаемом формате
  String get formattedResolution {
    if (width == null || height == null) return '';
    return '${width}x$height';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GalleryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'GalleryItem(id: $id, type: $type, title: $title, specialistId: $specialistId)';
}
