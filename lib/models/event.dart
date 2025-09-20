import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Модель события/мероприятия
class Event {
  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.endDate,
    required this.location,
    required this.price,
    required this.organizerId,
    required this.organizerName,
    this.organizerPhoto,
    required this.category,
    required this.status,
    this.maxParticipants = 50,
    this.currentParticipants = 0,
    this.imageUrls = const [],
    this.tags = const [],
    this.additionalInfo = const {},
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = true,
    this.contactInfo,
    this.requirements,
    this.participantsCount,
    this.imageUrl,
    this.isHidden = false,
  });

  /// Создать событие из документа Firestore
  factory Event.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      location: data['location'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      organizerPhoto: data['organizerPhoto'],
      category: EventCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => EventCategory.other,
      ),
      status: EventStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => EventStatus.active,
      ),
      maxParticipants: data['maxParticipants'] ?? 50,
      currentParticipants: data['currentParticipants'] ?? 0,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      additionalInfo: Map<String, dynamic>.from(data['additionalInfo'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublic: data['isPublic'] ?? true,
      contactInfo: data['contactInfo'],
      requirements: data['requirements'],
      participantsCount: data['participantsCount'],
      imageUrl: data['imageUrl'],
      isHidden: data['isHidden'] ?? false,
    );
  }
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime? endDate;
  final String location;
  final double price;
  final String organizerId; // ID создателя события
  final String organizerName;
  final String? organizerPhoto;
  final EventCategory category;
  final EventStatus status;
  final int maxParticipants;
  final int currentParticipants;
  final List<String> imageUrls;
  final List<String> tags;
  final Map<String, dynamic> additionalInfo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic;
  final String? contactInfo;
  final String? requirements;
  final int? participantsCount;
  final String? imageUrl;
  final bool isHidden;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(date),
        'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
        'location': location,
        'price': price,
        'organizerId': organizerId,
        'organizerName': organizerName,
        'organizerPhoto': organizerPhoto,
        'category': category.name,
        'status': status.name,
        'maxParticipants': maxParticipants,
        'currentParticipants': currentParticipants,
        'imageUrls': imageUrls,
        'tags': tags,
        'additionalInfo': additionalInfo,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'isPublic': isPublic,
        'contactInfo': contactInfo,
        'requirements': requirements,
        'participantsCount': participantsCount,
        'imageUrl': imageUrl,
        'isHidden': isHidden,
      };

  /// Копировать с изменениями
  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    DateTime? endDate,
    String? location,
    double? price,
    String? organizerId,
    String? organizerName,
    String? organizerPhoto,
    EventCategory? category,
    EventStatus? status,
    int? maxParticipants,
    int? currentParticipants,
    List<String>? imageUrls,
    List<String>? tags,
    Map<String, dynamic>? additionalInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
    String? contactInfo,
    String? requirements,
    int? participantsCount,
  }) =>
      Event(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        date: date ?? this.date,
        endDate: endDate ?? this.endDate,
        location: location ?? this.location,
        price: price ?? this.price,
        organizerId: organizerId ?? this.organizerId,
        organizerName: organizerName ?? this.organizerName,
        organizerPhoto: organizerPhoto ?? this.organizerPhoto,
        category: category ?? this.category,
        status: status ?? this.status,
        maxParticipants: maxParticipants ?? this.maxParticipants,
        currentParticipants: currentParticipants ?? this.currentParticipants,
        imageUrls: imageUrls ?? this.imageUrls,
        tags: tags ?? this.tags,
        additionalInfo: additionalInfo ?? this.additionalInfo,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isPublic: isPublic ?? this.isPublic,
        contactInfo: contactInfo ?? this.contactInfo,
        requirements: requirements ?? this.requirements,
        participantsCount: participantsCount ?? this.participantsCount,
      );

  /// Проверить, является ли событие сегодняшним
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);
    return today == eventDate;
  }

  /// Проверить, является ли событие завтрашним
  bool get isTomorrow {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final eventDate = DateTime(date.year, date.month, date.day);
    return tomorrow == eventDate;
  }

  /// Проверить, является ли событие прошедшим
  bool get isPast {
    final eventEndDate = endDate ?? date;
    return eventEndDate.isBefore(DateTime.now());
  }

  /// Проверить, является ли событие будущим
  bool get isFuture => date.isAfter(DateTime.now());

  /// Проверить, есть ли свободные места
  bool get hasAvailableSpots => currentParticipants < maxParticipants;

  /// Получить количество свободных мест
  int get availableSpots => maxParticipants - currentParticipants;

  /// Получить отображаемую цену
  String get formattedPrice {
    if (price == 0) return 'Бесплатно';
    return '${price.toStringAsFixed(0)} ₽';
  }

  /// Получить отображаемую дату
  String get formattedDate {
    final now = DateTime.now();
    final eventDate = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (eventDate == today) return 'Сегодня';
    if (eventDate == tomorrow) return 'Завтра';
    if (eventDate == yesterday) return 'Вчера';

    return '${date.day}.${date.month}.${date.year}';
  }

  /// Получить отображаемое время
  String get formattedTime =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  /// Получить цвет статуса
  Color get statusColor {
    switch (status) {
      case EventStatus.active:
        return Colors.green;
      case EventStatus.cancelled:
        return Colors.red;
      case EventStatus.completed:
        return Colors.grey;
      case EventStatus.draft:
        return Colors.orange;
      case EventStatus.full:
        return Colors.purple;
    }
  }

  /// Получить текст статуса
  String get statusText {
    switch (status) {
      case EventStatus.active:
        return 'Активно';
      case EventStatus.cancelled:
        return 'Отменено';
      case EventStatus.completed:
        return 'Завершено';
      case EventStatus.draft:
        return 'Черновик';
      case EventStatus.full:
        return 'Заполнено';
    }
  }

  /// Получить иконку категории
  IconData get categoryIcon {
    switch (category) {
      case EventCategory.wedding:
        return Icons.favorite;
      case EventCategory.birthday:
        return Icons.cake;
      case EventCategory.corporate:
        return Icons.business;
      case EventCategory.conference:
        return Icons.people;
      case EventCategory.seminar:
        return Icons.school;
      case EventCategory.exhibition:
        return Icons.museum;
      case EventCategory.concert:
        return Icons.music_note;
      case EventCategory.sport:
        return Icons.sports;
      case EventCategory.travel:
        return Icons.travel_explore;
      case EventCategory.other:
        return Icons.event;
    }
  }

  /// Получить название категории
  String get categoryName {
    switch (category) {
      case EventCategory.wedding:
        return 'Свадьба';
      case EventCategory.birthday:
        return 'День рождения';
      case EventCategory.corporate:
        return 'Корпоратив';
      case EventCategory.conference:
        return 'Конференция';
      case EventCategory.seminar:
        return 'Семинар';
      case EventCategory.exhibition:
        return 'Выставка';
      case EventCategory.concert:
        return 'Концерт';
      case EventCategory.sport:
        return 'Спорт';
      case EventCategory.travel:
        return 'Путешествие';
      case EventCategory.other:
        return 'Другое';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Event(id: $id, title: $title, date: $date, status: $status)';
}

/// Категории событий
enum EventCategory {
  wedding,
  birthday,
  corporate,
  conference,
  seminar,
  exhibition,
  concert,
  sport,
  travel,
  other,
}

/// Статусы событий
enum EventStatus {
  draft, // Черновик
  active, // Активно
  full, // Заполнено
  cancelled, // Отменено
  completed, // Завершено
}

/// Extension для EventCategory
extension EventCategoryExtension on EventCategory {
  /// Получить название категории
  String get categoryName {
    switch (this) {
      case EventCategory.wedding:
        return 'Свадьба';
      case EventCategory.birthday:
        return 'День рождения';
      case EventCategory.corporate:
        return 'Корпоратив';
      case EventCategory.conference:
        return 'Конференция';
      case EventCategory.seminar:
        return 'Семинар';
      case EventCategory.exhibition:
        return 'Выставка';
      case EventCategory.concert:
        return 'Концерт';
      case EventCategory.sport:
        return 'Спорт';
      case EventCategory.travel:
        return 'Путешествие';
      case EventCategory.other:
        return 'Другое';
    }
  }

  /// Получить иконку категории
  IconData get categoryIcon {
    switch (this) {
      case EventCategory.wedding:
        return Icons.favorite;
      case EventCategory.birthday:
        return Icons.cake;
      case EventCategory.corporate:
        return Icons.business;
      case EventCategory.conference:
        return Icons.people;
      case EventCategory.seminar:
        return Icons.school;
      case EventCategory.exhibition:
        return Icons.museum;
      case EventCategory.concert:
        return Icons.music_note;
      case EventCategory.sport:
        return Icons.sports;
      case EventCategory.travel:
        return Icons.travel_explore;
      case EventCategory.other:
        return Icons.event;
    }
  }
}
