import 'package:cloud_firestore/cloud_firestore.dart';

/// Категории идей для мероприятий
enum EventIdeaCategory {
  wedding, // Свадьба
  birthday, // День рождения
  corporate, // Корпоратив
  graduation, // Выпускной
  anniversary, // Годовщина
  holiday, // Праздник
  conference, // Конференция
  exhibition, // Выставка
  party, // Вечеринка
  ceremony, // Церемония
  other, // Другое
}

/// Типы идей для мероприятий
enum EventIdeaType {
  decoration, // Оформление
  entertainment, // Развлечения
  catering, // Кейтеринг
  photography, // Фотография
  music, // Музыка
  venue, // Площадка
  planning, // Планирование
  other, // Другое
}

/// Статус идеи
enum EventIdeaStatus {
  draft, // Черновик
  published, // Опубликована
  archived, // Архивирована
  reported, // Пожаловались
}

/// Модель идеи для мероприятия
class EventIdea {
  const EventIdea({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.type,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.status = EventIdeaStatus.published,
    this.likes = 0,
    this.commentsCount = 0,
    this.views = 0,
    this.tags = const [],
    this.location,
    this.budget,
    this.duration,
    this.guestCount,
    this.season,
    this.style,
    this.colorScheme,
    this.inspiration,
    this.similarIdeas = const [],
    this.attachedBookings = const [],
    this.isPublic = true,
    this.metadata = const {},
  });

  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final EventIdeaCategory category;
  final EventIdeaType type;
  final String createdBy; // ID пользователя
  final DateTime createdAt;
  final DateTime? updatedAt;
  final EventIdeaStatus status;
  final int likes;
  final int commentsCount;
  final int views;
  final List<String> tags;
  final String? location;
  final double? budget;
  final int? duration; // в часах
  final int? guestCount;
  final String? season; // весна, лето, осень, зима
  final String? style; // классический, современный, винтаж и т.д.
  final List<String>? colorScheme;
  final String? inspiration; // источник вдохновения
  final List<String> similarIdeas; // ID похожих идей
  final List<String> attachedBookings; // ID прикрепленных бронирований
  final bool isPublic;
  final Map<String, dynamic> metadata;

  /// Создать из Map (Firestore)
  factory EventIdea.fromMap(Map<String, dynamic> map) =>
    EventIdea(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      imageUrl: map['imageUrl'] as String,
      category: EventIdeaCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => EventIdeaCategory.other,
      ),
      type: EventIdeaType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => EventIdeaType.other,
      ),
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
      status: EventIdeaStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => EventIdeaStatus.published,
      ),
      likes: (map['likes'] ?? 0) as int,
      commentsCount: (map['commentsCount'] ?? 0) as int,
      views: (map['views'] ?? 0) as int,
      tags: List<String>.from((map['tags'] ?? <String>[]) as List),
      location: map['location'] as String?,
      budget: (map['budget'] as num?)?.toDouble(),
      duration: map['duration'] as int?,
      guestCount: map['guestCount'] as int?,
      season: map['season'] as String?,
      style: map['style'] as String?,
      colorScheme: map['colorScheme'] != null 
          ? List<String>.from(map['colorScheme'] as List) 
          : null,
      inspiration: map['inspiration'] as String?,
      similarIdeas: List<String>.from((map['similarIdeas'] ?? <String>[]) as List),
      attachedBookings: List<String>.from((map['attachedBookings'] ?? <String>[]) as List),
      isPublic: (map['isPublic'] ?? true) as bool,
      metadata: Map<String, dynamic>.from((map['metadata'] ?? <String, dynamic>{}) as Map),
    );

  /// Создать из Firestore DocumentSnapshot
  factory EventIdea.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventIdea.fromMap(data);
  }

  /// Преобразовать в Map (Firestore)
  Map<String, dynamic> toMap() => {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category.name,
      'type': type.name,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'status': status.name,
      'likes': likes,
      'commentsCount': commentsCount,
      'views': views,
      'tags': tags,
      'location': location,
      'budget': budget,
      'duration': duration,
      'guestCount': guestCount,
      'season': season,
      'style': style,
      'colorScheme': colorScheme,
      'inspiration': inspiration,
      'similarIdeas': similarIdeas,
      'attachedBookings': attachedBookings,
      'isPublic': isPublic,
      'metadata': metadata,
    };

  /// Создать копию с изменениями
  EventIdea copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    EventIdeaCategory? category,
    EventIdeaType? type,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    EventIdeaStatus? status,
    int? likes,
    int? commentsCount,
    int? views,
    List<String>? tags,
    String? location,
    double? budget,
    int? duration,
    int? guestCount,
    String? season,
    String? style,
    List<String>? colorScheme,
    String? inspiration,
    List<String>? similarIdeas,
    List<String>? attachedBookings,
    bool? isPublic,
    Map<String, dynamic>? metadata,
  }) =>
    EventIdea(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      type: type ?? this.type,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      views: views ?? this.views,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      budget: budget ?? this.budget,
      duration: duration ?? this.duration,
      guestCount: guestCount ?? this.guestCount,
      season: season ?? this.season,
      style: style ?? this.style,
      colorScheme: colorScheme ?? this.colorScheme,
      inspiration: inspiration ?? this.inspiration,
      similarIdeas: similarIdeas ?? this.similarIdeas,
      attachedBookings: attachedBookings ?? this.attachedBookings,
      isPublic: isPublic ?? this.isPublic,
      metadata: metadata ?? this.metadata,
    );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is EventIdea && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
    'EventIdea(id: $id, title: $title, category: $category, createdBy: $createdBy)';
}

/// Расширения для enum'ов
extension EventIdeaCategoryExtension on EventIdeaCategory {
  String get displayName {
    switch (this) {
      case EventIdeaCategory.wedding:
        return 'Свадьба';
      case EventIdeaCategory.birthday:
        return 'День рождения';
      case EventIdeaCategory.corporate:
        return 'Корпоратив';
      case EventIdeaCategory.graduation:
        return 'Выпускной';
      case EventIdeaCategory.anniversary:
        return 'Годовщина';
      case EventIdeaCategory.holiday:
        return 'Праздник';
      case EventIdeaCategory.conference:
        return 'Конференция';
      case EventIdeaCategory.exhibition:
        return 'Выставка';
      case EventIdeaCategory.party:
        return 'Вечеринка';
      case EventIdeaCategory.ceremony:
        return 'Церемония';
      case EventIdeaCategory.other:
        return 'Другое';
    }
  }

  String get emoji {
    switch (this) {
      case EventIdeaCategory.wedding:
        return '💒';
      case EventIdeaCategory.birthday:
        return '🎂';
      case EventIdeaCategory.corporate:
        return '🏢';
      case EventIdeaCategory.graduation:
        return '🎓';
      case EventIdeaCategory.anniversary:
        return '💕';
      case EventIdeaCategory.holiday:
        return '🎉';
      case EventIdeaCategory.conference:
        return '📊';
      case EventIdeaCategory.exhibition:
        return '🎨';
      case EventIdeaCategory.party:
        return '🎊';
      case EventIdeaCategory.ceremony:
        return '🏛️';
      case EventIdeaCategory.other:
        return '✨';
    }
  }
}

extension EventIdeaStatusExtension on EventIdeaStatus {
  String get displayName {
    switch (this) {
      case EventIdeaStatus.draft:
        return 'Черновик';
      case EventIdeaStatus.published:
        return 'Опубликована';
      case EventIdeaStatus.archived:
        return 'Архивирована';
      case EventIdeaStatus.reported:
        return 'На рассмотрении';
    }
  }
}

extension EventIdeaTypeExtension on EventIdeaType {
  String get displayName {
    switch (this) {
      case EventIdeaType.decoration:
        return 'Оформление';
      case EventIdeaType.entertainment:
        return 'Развлечения';
      case EventIdeaType.catering:
        return 'Кейтеринг';
      case EventIdeaType.photography:
        return 'Фотография';
      case EventIdeaType.music:
        return 'Музыка';
      case EventIdeaType.venue:
        return 'Площадка';
      case EventIdeaType.planning:
        return 'Планирование';
      case EventIdeaType.other:
        return 'Другое';
    }
  }
}