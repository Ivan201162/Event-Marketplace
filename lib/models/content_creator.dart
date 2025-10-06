import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель контент-мейкера
class ContentCreator {
  const ContentCreator({
    required this.id,
    required this.name,
    required this.description,
    required this.categories,
    required this.formats,
    required this.mediaShowcase,
    this.pricing,
    this.location,
    this.rating,
    this.reviewCount,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать из документа Firestore
  factory ContentCreator.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ContentCreator(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      categories: List<String>.from(data['categories'] as List<dynamic>? ?? []),
      formats: (data['formats'] as List<dynamic>?)
              ?.map((f) => ContentFormat.fromMap(f as Map<String, dynamic>))
              .toList() ??
          [],
      mediaShowcase: (data['mediaShowcase'] as List<dynamic>?)
              ?.map((m) => MediaShowcase.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      pricing: data['pricing'] != null
          ? Map<String, dynamic>.from(data['pricing'] as Map<dynamic, dynamic>)
          : null,
      location: data['location'] as String?,
      rating: data['rating'] as double?,
      reviewCount: data['reviewCount'] as int?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Создать из Map
  factory ContentCreator.fromMap(Map<String, dynamic> data) => ContentCreator(
        id: data['id'] as String? ?? '',
        name: data['name'] as String? ?? '',
        description: data['description'] as String? ?? '',
        categories:
            List<String>.from(data['categories'] as List<dynamic>? ?? []),
        formats: (data['formats'] as List<dynamic>?)
                ?.map((f) => ContentFormat.fromMap(f as Map<String, dynamic>))
                .toList() ??
            [],
        mediaShowcase: (data['mediaShowcase'] as List<dynamic>?)
                ?.map((m) => MediaShowcase.fromMap(m as Map<String, dynamic>))
                .toList() ??
            [],
        pricing: data['pricing'] != null
            ? Map<String, dynamic>.from(
                data['pricing'] as Map<dynamic, dynamic>,
              )
            : null,
        location: data['location'] as String?,
        rating: data['rating'] as double?,
        reviewCount: data['reviewCount'] as int?,
        isActive: data['isActive'] as bool? ?? true,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
  final String id;
  final String name;
  final String description;
  final List<String> categories;
  final List<ContentFormat> formats;
  final List<MediaShowcase> mediaShowcase;
  final Map<String, dynamic>? pricing;
  final String? location;
  final double? rating;
  final int? reviewCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'categories': categories,
        'formats': formats.map((f) => f.toMap()).toList(),
        'mediaShowcase': mediaShowcase.map((m) => m.toMap()).toList(),
        'pricing': pricing,
        'location': location,
        'rating': rating,
        'reviewCount': reviewCount,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// Создать копию с изменениями
  ContentCreator copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? categories,
    List<ContentFormat>? formats,
    List<MediaShowcase>? mediaShowcase,
    Map<String, dynamic>? pricing,
    String? location,
    double? rating,
    int? reviewCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ContentCreator(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        categories: categories ?? this.categories,
        formats: formats ?? this.formats,
        mediaShowcase: mediaShowcase ?? this.mediaShowcase,
        pricing: pricing ?? this.pricing,
        location: location ?? this.location,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Получить диапазон цен
  String? get priceRange {
    if (pricing == null) return null;

    final minPrice = pricing!['minPrice']?.toDouble();
    final maxPrice = pricing!['maxPrice']?.toDouble();

    if (minPrice == null || maxPrice == null) return null;

    if (minPrice == maxPrice) {
      return '${minPrice.toStringAsFixed(0)} ₽';
    }
    return '${minPrice.toStringAsFixed(0)} - ${maxPrice.toStringAsFixed(0)} ₽';
  }

  /// Получить поддерживаемые форматы
  List<String> get supportedFormats => formats.map((f) => f.name).toList();

  /// Получить количество медиа в портфолио
  int get portfolioSize => mediaShowcase.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentCreator &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.categories == categories &&
        other.formats == formats &&
        other.mediaShowcase == mediaShowcase &&
        other.pricing == pricing &&
        other.location == location &&
        other.rating == rating &&
        other.reviewCount == reviewCount &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        categories,
        formats,
        mediaShowcase,
        pricing,
        location,
        rating,
        reviewCount,
        isActive,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'ContentCreator(id: $id, name: $name, formats: ${supportedFormats.length})';
}

/// Формат контента
class ContentFormat {
  const ContentFormat({
    required this.name,
    required this.description,
    required this.platforms,
    this.specifications,
  });

  /// Создать из Map
  factory ContentFormat.fromMap(Map<String, dynamic> data) => ContentFormat(
        name: data['name'] as String? ?? '',
        description: data['description'] as String? ?? '',
        platforms: List<String>.from(data['platforms'] as List<dynamic>? ?? []),
        specifications: data['specifications'] != null
            ? Map<String, dynamic>.from(
                data['specifications'] as Map<dynamic, dynamic>,
              )
            : null,
      );
  final String name;
  final String description;
  final List<String> platforms;
  final Map<String, dynamic>? specifications;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'platforms': platforms,
        'specifications': specifications,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentFormat &&
        other.name == name &&
        other.description == description &&
        other.platforms == platforms &&
        other.specifications == specifications;
  }

  @override
  int get hashCode => Object.hash(name, description, platforms, specifications);

  @override
  String toString() => 'ContentFormat(name: $name, platforms: $platforms)';
}

/// Медиа в портфолио
class MediaShowcase {
  const MediaShowcase({
    required this.id,
    required this.type,
    required this.url,
    this.coverUrl,
    this.title,
    this.description,
    this.metadata,
    required this.createdAt,
  });

  /// Создать из Map
  factory MediaShowcase.fromMap(Map<String, dynamic> data) => MediaShowcase(
        id: data['id'] as String? ?? '',
        type: MediaType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => MediaType.image,
        ),
        url: data['url'] as String? ?? '',
        coverUrl: data['coverUrl'] as String?,
        title: data['title'] as String?,
        description: data['description'] as String?,
        metadata: data['metadata'] != null
            ? Map<String, dynamic>.from(
                data['metadata'] as Map<dynamic, dynamic>,
              )
            : null,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
  final String id;
  final MediaType type;
  final String url;
  final String? coverUrl;
  final String? title;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'url': url,
        'coverUrl': coverUrl,
        'title': title,
        'description': description,
        'metadata': metadata,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaShowcase &&
        other.id == id &&
        other.type == type &&
        other.url == url &&
        other.coverUrl == coverUrl &&
        other.title == title &&
        other.description == description &&
        other.metadata == metadata &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        type,
        url,
        coverUrl,
        title,
        description,
        metadata,
        createdAt,
      );

  @override
  String toString() => 'MediaShowcase(id: $id, type: $type, title: $title)';
}

/// Тип медиа
enum MediaType {
  image,
  video,
  gif,
  story,
  reel,
  tiktok,
  youtube,
  instagram,
  other,
}

/// Расширение для типа медиа
extension MediaTypeExtension on MediaType {
  String get displayName {
    switch (this) {
      case MediaType.image:
        return 'Изображение';
      case MediaType.video:
        return 'Видео';
      case MediaType.gif:
        return 'GIF';
      case MediaType.story:
        return 'Сторис';
      case MediaType.reel:
        return 'Reels';
      case MediaType.tiktok:
        return 'TikTok';
      case MediaType.youtube:
        return 'YouTube';
      case MediaType.instagram:
        return 'Instagram';
      case MediaType.other:
        return 'Другое';
    }
  }

  String get icon {
    switch (this) {
      case MediaType.image:
        return '🖼️';
      case MediaType.video:
        return '🎥';
      case MediaType.gif:
        return '🎞️';
      case MediaType.story:
        return '📱';
      case MediaType.reel:
        return '🎬';
      case MediaType.tiktok:
        return '🎵';
      case MediaType.youtube:
        return '📺';
      case MediaType.instagram:
        return '📷';
      case MediaType.other:
        return '📄';
    }
  }
}
