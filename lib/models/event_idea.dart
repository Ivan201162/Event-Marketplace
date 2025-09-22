import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип идеи мероприятия
enum EventIdeaType {
  wedding, // Свадьба
  birthday, // День рождения
  corporate, // Корпоратив
  anniversary, // Годовщина
  graduation, // Выпускной
  holiday, // Праздник
  private, // Частное мероприятие
  other, // Другое
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

/// Модель идеи мероприятия
class EventIdea {
  const EventIdea({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    this.authorId,
    this.authorName,
    this.tags = const [],
    this.budgetRange,
    this.duration,
    this.guestCount,
    this.location,
    this.season,
    this.style,
    this.colorScheme,
    this.isPublic = true,
    this.likesCount = 0,
    this.savesCount = 0,
    this.viewsCount = 0,
    this.isFeatured = false,
    this.relatedServices = const [],
    this.estimatedCost,
    this.difficultyLevel,
    this.timeToPrepare,
  });

  /// Создать из документа Firestore
  factory EventIdea.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return EventIdea(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: EventIdeaType.values.firstWhere(
        (e) => e.name == (data['type'] as String?),
        orElse: () => EventIdeaType.other,
      ),
      category: EventIdeaCategory.values.firstWhere(
        (e) => e.name == (data['category'] as String?),
        orElse: () => EventIdeaCategory.other,
      ),
      imageUrl: data['imageUrl'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      authorId: data['authorId'] as String?,
      authorName: data['authorName'] as String?,
      tags: List<String>.from(data['tags'] ?? []),
      budgetRange: data['budgetRange'] as String?,
      duration: data['duration'] as String?,
      guestCount: data['guestCount'] as String?,
      location: data['location'] as String?,
      season: data['season'] as String?,
      style: data['style'] as String?,
      colorScheme: data['colorScheme'] as String?,
      isPublic: data['isPublic'] ?? true,
      likesCount: data['likesCount'] ?? 0,
      savesCount: data['savesCount'] ?? 0,
      viewsCount: data['viewsCount'] ?? 0,
      isFeatured: data['isFeatured'] ?? false,
      relatedServices: List<String>.from(data['relatedServices'] ?? []),
      estimatedCost: (data['estimatedCost'] as num?)?.toDouble(),
      difficultyLevel: data['difficultyLevel'] as String?,
      timeToPrepare: data['timeToPrepare'] as String?,
    );
  }

  /// Создать из Map
  factory EventIdea.fromMap(Map<String, dynamic> map) => EventIdea(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        type: EventIdeaType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => EventIdeaType.other,
        ),
        category: EventIdeaCategory.values.firstWhere(
          (e) => e.name == map['category'],
          orElse: () => EventIdeaCategory.other,
        ),
        imageUrl: map['imageUrl'] ?? '',
        createdAt: map['createdAt'] != null
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null
            ? (map['updatedAt'] as Timestamp).toDate()
            : null,
        authorId: map['authorId'] as String?,
        authorName: map['authorName'] as String?,
        tags: List<String>.from(map['tags'] ?? []),
        budgetRange: map['budgetRange'] as String?,
        duration: map['duration'] as String?,
        guestCount: map['guestCount'] as String?,
        location: map['location'] as String?,
        season: map['season'] as String?,
        style: map['style'] as String?,
        colorScheme: map['colorScheme'] as String?,
        isPublic: map['isPublic'] ?? true,
        likesCount: map['likesCount'] ?? 0,
        savesCount: map['savesCount'] ?? 0,
        viewsCount: map['viewsCount'] ?? 0,
        isFeatured: map['isFeatured'] ?? false,
        relatedServices: List<String>.from(map['relatedServices'] ?? []),
        estimatedCost: (map['estimatedCost'] as num?)?.toDouble(),
        difficultyLevel: map['difficultyLevel'] as String?,
        timeToPrepare: map['timeToPrepare'] as String?,
      );

  final String id;
  final String title;
  final String description;
  final EventIdeaType type;
  final EventIdeaCategory category;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? authorId;
  final String? authorName;
  final List<String> tags;
  final String? budgetRange;
  final String? duration;
  final String? guestCount;
  final String? location;
  final String? season;
  final String? style;
  final String? colorScheme;
  final bool isPublic;
  final int likesCount;
  final int savesCount;
  final int viewsCount;
  final bool isFeatured;
  final List<String> relatedServices;
  final double? estimatedCost;
  final String? difficultyLevel;
  final String? timeToPrepare;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'type': type.name,
        'category': category.name,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'authorId': authorId,
        'authorName': authorName,
        'tags': tags,
        'budgetRange': budgetRange,
        'duration': duration,
        'guestCount': guestCount,
        'location': location,
        'season': season,
        'style': style,
        'colorScheme': colorScheme,
        'isPublic': isPublic,
        'likesCount': likesCount,
        'savesCount': savesCount,
        'viewsCount': viewsCount,
        'isFeatured': isFeatured,
        'relatedServices': relatedServices,
        'estimatedCost': estimatedCost,
        'difficultyLevel': difficultyLevel,
        'timeToPrepare': timeToPrepare,
      };

  /// Копировать с изменениями
  EventIdea copyWith({
    String? id,
    String? title,
    String? description,
    EventIdeaType? type,
    EventIdeaCategory? category,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorId,
    String? authorName,
    List<String>? tags,
    String? budgetRange,
    String? duration,
    String? guestCount,
    String? location,
    String? season,
    String? style,
    String? colorScheme,
    bool? isPublic,
    int? likesCount,
    int? savesCount,
    int? viewsCount,
    bool? isFeatured,
    List<String>? relatedServices,
    double? estimatedCost,
    String? difficultyLevel,
    String? timeToPrepare,
  }) =>
      EventIdea(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        type: type ?? this.type,
        category: category ?? this.category,
        imageUrl: imageUrl ?? this.imageUrl,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        tags: tags ?? this.tags,
        budgetRange: budgetRange ?? this.budgetRange,
        duration: duration ?? this.duration,
        guestCount: guestCount ?? this.guestCount,
        location: location ?? this.location,
        season: season ?? this.season,
        style: style ?? this.style,
        colorScheme: colorScheme ?? this.colorScheme,
        isPublic: isPublic ?? this.isPublic,
        likesCount: likesCount ?? this.likesCount,
        savesCount: savesCount ?? this.savesCount,
        viewsCount: viewsCount ?? this.viewsCount,
        isFeatured: isFeatured ?? this.isFeatured,
        relatedServices: relatedServices ?? this.relatedServices,
        estimatedCost: estimatedCost ?? this.estimatedCost,
        difficultyLevel: difficultyLevel ?? this.difficultyLevel,
        timeToPrepare: timeToPrepare ?? this.timeToPrepare,
      );

  /// Получить отображаемое название типа
  String get typeDisplayName {
    switch (type) {
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
      case EventIdeaType.private:
        return 'Частное мероприятие';
      case EventIdeaType.other:
        return 'Другое';
    }
  }

  /// Получить отображаемое название категории
  String get categoryDisplayName {
    switch (category) {
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

  /// Получить иконку типа
  String get typeIcon {
    switch (type) {
      case EventIdeaType.wedding:
        return '💒';
      case EventIdeaType.birthday:
        return '🎂';
      case EventIdeaType.corporate:
        return '🏢';
      case EventIdeaType.anniversary:
        return '💍';
      case EventIdeaType.graduation:
        return '🎓';
      case EventIdeaType.holiday:
        return '🎉';
      case EventIdeaType.private:
        return '🏠';
      case EventIdeaType.other:
        return '⭐';
    }
  }

  /// Получить цвет категории
  String get categoryColor {
    switch (category) {
      case EventIdeaCategory.decoration:
        return 'pink';
      case EventIdeaCategory.entertainment:
        return 'purple';
      case EventIdeaCategory.catering:
        return 'orange';
      case EventIdeaCategory.photography:
        return 'blue';
      case EventIdeaCategory.music:
        return 'green';
      case EventIdeaCategory.venue:
        return 'brown';
      case EventIdeaCategory.planning:
        return 'teal';
      case EventIdeaCategory.other:
        return 'grey';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventIdea && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'EventIdea(id: $id, title: $title, type: $type, category: $category)';
}