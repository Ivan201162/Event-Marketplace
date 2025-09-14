import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель идеи для мероприятия
class EventIdea {
  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final String? authorId;
  final String? authorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final int likesCount;
  final int savesCount;
  final bool isPublic;
  final String? eventType; // свадьба, день рождения, корпоратив и т.д.
  final String? budget; // бюджетный, средний, премиум
  final String? season; // весна, лето, осень, зима
  final String? venue; // помещение, улица, смешанный

  EventIdea({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrls,
    required this.videoUrls,
    this.authorId,
    this.authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.tags,
    this.likesCount = 0,
    this.savesCount = 0,
    this.isPublic = true,
    this.eventType,
    this.budget,
    this.season,
    this.venue,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'likesCount': likesCount,
      'savesCount': savesCount,
      'isPublic': isPublic,
      'eventType': eventType,
      'budget': budget,
      'season': season,
      'venue': venue,
    };
  }

  /// Создание из документа Firestore
  factory EventIdea.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventIdea(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      videoUrls: List<String>.from(data['videoUrls'] ?? []),
      authorId: data['authorId'],
      authorName: data['authorName'],
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now(),
      tags: List<String>.from(data['tags'] ?? []),
      likesCount: data['likesCount'] ?? 0,
      savesCount: data['savesCount'] ?? 0,
      isPublic: data['isPublic'] ?? true,
      eventType: data['eventType'],
      budget: data['budget'],
      season: data['season'],
      venue: data['venue'],
    );
  }

  /// Копирование с изменениями
  EventIdea copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    List<String>? imageUrls,
    List<String>? videoUrls,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    int? likesCount,
    int? savesCount,
    bool? isPublic,
    String? eventType,
    String? budget,
    String? season,
    String? venue,
  }) {
    return EventIdea(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      likesCount: likesCount ?? this.likesCount,
      savesCount: savesCount ?? this.savesCount,
      isPublic: isPublic ?? this.isPublic,
      eventType: eventType ?? this.eventType,
      budget: budget ?? this.budget,
      season: season ?? this.season,
      venue: venue ?? this.venue,
    );
  }

  @override
  String toString() {
    return 'EventIdea(id: $id, title: $title, category: $category, authorId: $authorId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventIdea && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Категории идей для мероприятий
class EventIdeaCategories {
  static const List<String> categories = [
    'Свадьба',
    'День рождения',
    'Корпоратив',
    'Выпускной',
    'Новый год',
    '8 марта',
    '23 февраля',
    'День матери',
    'День отца',
    'Детский праздник',
    'Тимбилдинг',
    'Конференция',
    'Семинар',
    'Презентация',
    'Фестиваль',
    'Концерт',
    'Выставка',
    'Другое',
  ];

  static const List<String> eventTypes = [
    'Свадьба',
    'День рождения',
    'Корпоратив',
    'Выпускной',
    'Новый год',
    'Праздник',
    'Мероприятие',
    'Встреча',
    'Конференция',
    'Семинар',
    'Презентация',
    'Фестиваль',
    'Концерт',
    'Выставка',
    'Другое',
  ];

  static const List<String> budgets = [
    'Бюджетный',
    'Средний',
    'Премиум',
    'Люкс',
  ];

  static const List<String> seasons = [
    'Весна',
    'Лето',
    'Осень',
    'Зима',
    'Круглый год',
  ];

  static const List<String> venues = [
    'Помещение',
    'Улица',
    'Смешанный',
    'Любой',
  ];
}
