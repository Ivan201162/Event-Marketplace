import 'package:cloud_firestore/cloud_firestore.dart';

/// Типы идей мероприятий
enum EventIdeaType {
  wedding, // Свадьба
  birthday, // День рождения
  corporate, // Корпоратив
  graduation, // Выпускной
  anniversary, // Годовщина
  holiday, // Праздник
  conference, // Конференция
  exhibition, // Выставка
  concert, // Концерт
  festival, // Фестиваль
  other, // Другое
}

extension EventIdeaTypeExtension on EventIdeaType {
  String get displayName {
    switch (this) {
      case EventIdeaType.wedding:
        return 'Свадьба';
      case EventIdeaType.birthday:
        return 'День рождения';
      case EventIdeaType.corporate:
        return 'Корпоратив';
      case EventIdeaType.anniversary:
        return 'Годовщина';
      case EventIdeaType.graduation:
        return 'Выпускной';
      case EventIdeaType.holiday:
        return 'Праздник';
      case EventIdeaType.conference:
        return 'Конференция';
      case EventIdeaType.exhibition:
        return 'Выставка';
      case EventIdeaType.concert:
        return 'Концерт';
      case EventIdeaType.festival:
        return 'Фестиваль';
      case EventIdeaType.other:
        return 'Другое';
    }
  }
}

/// Категория идеи
enum EventIdeaCategory {
  decoration, // Оформление
  entertainment, // Развлечения
  catering, // Кейтеринг
  photography, // Фотография
  music, // Музыка
  venue, // Площадка
  planning, // Планирование
  other, // Другое
}

extension EventIdeaCategoryExtension on EventIdeaCategory {
  String get displayName {
    switch (this) {
      case EventIdeaCategory.decoration:
        return 'Оформление';
      case EventIdeaCategory.entertainment:
        return 'Развлечения';
      case EventIdeaCategory.catering:
        return 'Кейтеринг';
      case EventIdeaCategory.photography:
        return 'Фотография';
      case EventIdeaCategory.music:
        return 'Музыка';
      case EventIdeaCategory.venue:
        return 'Площадка';
      case EventIdeaCategory.planning:
        return 'Планирование';
      case EventIdeaCategory.other:
        return 'Другое';
    }
  }
}

/// Модель идеи мероприятия
class EventIdea {
  final String id;
  final String title;
  final String description;
  final List<String> images;
  final List<String> tags;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final EventIdeaType type;
  final String? location;
  final int? budget;
  final int? guestCount;
  final String? colorScheme;
  final String? style;
  final List<String> savedBy; // Пользователи, сохранившие идею
  final List<String> likedBy; // Пользователи, лайкнувшие идею
  final int likesCount;
  final int savesCount;
  final int viewsCount;
  final bool isPublic;
  final bool isFeatured; // Рекомендуемая идея
  final double? rating;
  final int ratingCount;
  final Map<String, dynamic>? metadata;

  const EventIdea({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.tags,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    this.location,
    this.budget,
    this.guestCount,
    this.colorScheme,
    this.style,
    this.savedBy = const [],
    this.likedBy = const [],
    this.likesCount = 0,
    this.savesCount = 0,
    this.viewsCount = 0,
    this.isPublic = true,
    this.isFeatured = false,
    this.rating,
    this.ratingCount = 0,
    this.metadata,
  });

  /// Создать из Map
  factory EventIdea.fromMap(Map<String, dynamic> data) => EventIdea(
        id: data['id'] as String? ?? '',
        title: data['title'] as String? ?? '',
        description: data['description'] as String? ?? '',
        images: (data['images'] as List<dynamic>?)?.cast<String>() ?? [],
        tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        createdBy: data['createdBy'] as String? ?? '',
        createdAt: data['createdAt'] != null 
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null 
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
        type: EventIdeaType.values.firstWhere(
          (e) => e.name == (data['type'] as String?),
          orElse: () => EventIdeaType.other,
        ),
        location: data['location'] as String?,
        budget: data['budget'] as int?,
        guestCount: data['guestCount'] as int?,
        colorScheme: data['colorScheme'] as String?,
        style: data['style'] as String?,
        savedBy: (data['savedBy'] as List<dynamic>?)?.cast<String>() ?? [],
        likedBy: (data['likedBy'] as List<dynamic>?)?.cast<String>() ?? [],
        likesCount: data['likesCount'] as int? ?? 0,
        savesCount: data['savesCount'] as int? ?? 0,
        viewsCount: data['viewsCount'] as int? ?? 0,
        isPublic: data['isPublic'] as bool? ?? true,
        isFeatured: data['isFeatured'] as bool? ?? false,
        rating: (data['rating'] as num?)?.toDouble(),
        ratingCount: data['ratingCount'] as int? ?? 0,
        metadata: data['metadata'] != null 
            ? Map<String, dynamic>.from(data['metadata'] as Map)
            : null,
      );

  /// Создать из документа Firestore
  factory EventIdea.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return EventIdea(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      images: (data['images'] as List<dynamic>?)?.cast<String>() ?? [],
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdBy: (data['createdBy'] as String?) ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      type: EventIdeaType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => EventIdeaType.other,
      ),
      location: data['location'] as String?,
      budget: data['budget'] as int?,
      guestCount: data['guestCount'] as int?,
      colorScheme: data['colorScheme'] as String?,
      style: data['style'] as String?,
      savedBy: (data['savedBy'] as List<dynamic>?)?.cast<String>() ?? [],
      likedBy: (data['likedBy'] as List<dynamic>?)?.cast<String>() ?? [],
      likesCount: (data['likesCount'] as int?) ?? 0,
      savesCount: (data['savesCount'] as int?) ?? 0,
      viewsCount: (data['viewsCount'] as int?) ?? 0,
      isPublic: (data['isPublic'] as bool?) ?? true,
      isFeatured: (data['isFeatured'] as bool?) ?? false,
      rating: (data['rating'] as num?)?.toDouble(),
      ratingCount: (data['ratingCount'] as int?) ?? 0,
      metadata: data['metadata'] != null 
          ? Map<String, dynamic>.from(data['metadata'] as Map)
          : null,
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'images': images,
        'tags': tags,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'type': type.name,
        'location': location,
        'budget': budget,
        'guestCount': guestCount,
        'colorScheme': colorScheme,
        'style': style,
        'savedBy': savedBy,
        'likedBy': likedBy,
        'likesCount': likesCount,
        'savesCount': savesCount,
        'viewsCount': viewsCount,
        'isPublic': isPublic,
        'isFeatured': isFeatured,
        'rating': rating,
        'ratingCount': ratingCount,
        'metadata': metadata,
      };

  /// Копировать с изменениями
  EventIdea copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? images,
    List<String>? tags,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    EventIdeaType? type,
    String? location,
    int? budget,
    int? guestCount,
    String? colorScheme,
    String? style,
    List<String>? savedBy,
    List<String>? likedBy,
    int? likesCount,
    int? savesCount,
    int? viewsCount,
    bool? isPublic,
    bool? isFeatured,
    double? rating,
    int? ratingCount,
    Map<String, dynamic>? metadata,
  }) =>
      EventIdea(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        images: images ?? this.images,
        tags: tags ?? this.tags,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        type: type ?? this.type,
        location: location ?? this.location,
        budget: budget ?? this.budget,
        guestCount: guestCount ?? this.guestCount,
        colorScheme: colorScheme ?? this.colorScheme,
        style: style ?? this.style,
        savedBy: savedBy ?? this.savedBy,
        likedBy: likedBy ?? this.likedBy,
        likesCount: likesCount ?? this.likesCount,
        savesCount: savesCount ?? this.savesCount,
        viewsCount: viewsCount ?? this.viewsCount,
        isPublic: isPublic ?? this.isPublic,
        isFeatured: isFeatured ?? this.isFeatured,
        rating: rating ?? this.rating,
        ratingCount: ratingCount ?? this.ratingCount,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, лайкнул ли пользователь
  bool isLikedBy(String userId) => likedBy.contains(userId);

  /// Проверить, сохранил ли пользователь
  bool isSavedBy(String userId) => savedBy.contains(userId);

  /// Получить основное изображение
  String? get mainImage => images.isNotEmpty ? images.first : null;

  /// Получить отображаемый бюджет
  String get budgetDisplay {
    if (budget == null) return 'Не указан';
    if (budget! < 1000) return '${budget} ₽';
    if (budget! < 1000000) return '${(budget! / 1000).toStringAsFixed(0)}K ₽';
    return '${(budget! / 1000000).toStringAsFixed(1)}M ₽';
  }

  /// Получить отображаемое количество гостей
  String get guestCountDisplay {
    if (guestCount == null) return 'Не указано';
    return '$guestCount гостей';
  }

  /// Получить время создания в читаемом формате
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${_pluralize(years, 'год', 'года', 'лет')} назад';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${_pluralize(months, 'месяц', 'месяца', 'месяцев')} назад';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${_pluralize(difference.inDays, 'день', 'дня', 'дней')} назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${_pluralize(difference.inHours, 'час', 'часа', 'часов')} назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${_pluralize(difference.inMinutes, 'минуту', 'минуты', 'минут')} назад';
    } else {
      return 'Только что';
    }
  }

  /// Склонение слов
  String _pluralize(int count, String one, String few, String many) {
    if (count % 10 == 1 && count % 100 != 11) {
      return one;
    } else if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return few;
    } else {
      return many;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventIdea &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EventIdea{id: $id, title: $title, type: $type, likesCount: $likesCount, savesCount: $savesCount}';
  }
}