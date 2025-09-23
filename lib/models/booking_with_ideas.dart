import 'package:cloud_firestore/cloud_firestore.dart';

import 'booking.dart';
import 'idea.dart';
import 'event_idea.dart';

/// Расширенная модель заявки с поддержкой идей
class BookingWithIdeas {
  const BookingWithIdeas({
    required this.booking,
    this.attachedIdeas = const [],
    this.attachedEventIdeas = const [],
    this.customerNotes = const [],
    this.specialistNotes = const [],
    this.inspirationBoard,
  });

  /// Создать из документа Firestore
  factory BookingWithIdeas.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return BookingWithIdeas(
      booking: Booking.fromDocument(doc),
      attachedIdeas: (data['attachedIdeas'] as List<dynamic>?)
              ?.map((ideaData) => Idea.fromMap(ideaData as Map<String, dynamic>))
              .toList() ??
          [],
      attachedEventIdeas: (data['attachedEventIdeas'] as List<dynamic>?)
              ?.map((ideaData) => EventIdea.fromMap(ideaData as Map<String, dynamic>))
              .toList() ??
          [],
      customerNotes: List<String>.from(data['customerNotes'] ?? []),
      specialistNotes: List<String>.from(data['specialistNotes'] ?? []),
      inspirationBoard: data['inspirationBoard'] as String?,
    );
  }

  /// Создать из Map
  factory BookingWithIdeas.fromMap(Map<String, dynamic> map) => BookingWithIdeas(
        booking: Booking.fromMap(map['booking'] as Map<String, dynamic>),
        attachedIdeas: (map['attachedIdeas'] as List<dynamic>?)
                ?.map((ideaData) => Idea.fromMap(ideaData as Map<String, dynamic>))
                .toList() ??
            [],
        attachedEventIdeas: (map['attachedEventIdeas'] as List<dynamic>?)
                ?.map((ideaData) => EventIdea.fromMap(ideaData as Map<String, dynamic>))
                .toList() ??
            [],
        customerNotes: List<String>.from(map['customerNotes'] ?? []),
        specialistNotes: List<String>.from(map['specialistNotes'] ?? []),
        inspirationBoard: map['inspirationBoard'] as String?,
      );

  final Booking booking;
  final List<Idea> attachedIdeas;
  final List<EventIdea> attachedEventIdeas;
  final List<String> customerNotes;
  final List<String> specialistNotes;
  final String? inspirationBoard;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'booking': booking.toMap(),
        'attachedIdeas': attachedIdeas.map((idea) => idea.toMap()).toList(),
        'attachedEventIdeas': attachedEventIdeas.map((idea) => idea.toMap()).toList(),
        'customerNotes': customerNotes,
        'specialistNotes': specialistNotes,
        'inspirationBoard': inspirationBoard,
      };

  /// Копировать с изменениями
  BookingWithIdeas copyWith({
    Booking? booking,
    List<Idea>? attachedIdeas,
    List<EventIdea>? attachedEventIdeas,
    List<String>? customerNotes,
    List<String>? specialistNotes,
    String? inspirationBoard,
  }) =>
      BookingWithIdeas(
        booking: booking ?? this.booking,
        attachedIdeas: attachedIdeas ?? this.attachedIdeas,
        attachedEventIdeas: attachedEventIdeas ?? this.attachedEventIdeas,
        customerNotes: customerNotes ?? this.customerNotes,
        specialistNotes: specialistNotes ?? this.specialistNotes,
        inspirationBoard: inspirationBoard ?? this.inspirationBoard,
      );

  /// Получить все идеи (обычные и идей мероприятий)
  List<dynamic> get allIdeas => [...attachedIdeas, ...attachedEventIdeas];

  /// Получить количество прикрепленных идей
  int get ideasCount => attachedIdeas.length + attachedEventIdeas.length;

  /// Проверить, есть ли прикрепленные идеи
  bool get hasIdeas => ideasCount > 0;

  /// Получить все теги из прикрепленных идей
  List<String> get allTags {
    final tags = <String>{};
    for (final idea in attachedIdeas) {
      tags.addAll(idea.tags);
    }
    for (final eventIdea in attachedEventIdeas) {
      tags.addAll(eventIdea.tags);
    }
    return tags.toList();
  }

  /// Получить все категории из прикрепленных идей
  List<String> get allCategories {
    final categories = <String>{};
    for (final idea in attachedIdeas) {
      categories.add(idea.category);
    }
    for (final eventIdea in attachedEventIdeas) {
      categories.add(eventIdea.categoryDisplayName);
    }
    return categories.toList();
  }

  /// Получить превью изображений из идей
  List<String> get ideaImages {
    final images = <String>[];
    for (final idea in attachedIdeas) {
      images.addAll(idea.images);
    }
    for (final eventIdea in attachedEventIdeas) {
      if (eventIdea.imageUrl.isNotEmpty) {
        images.add(eventIdea.imageUrl);
      }
    }
    return images;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookingWithIdeas && other.booking.id == booking.id;
  }

  @override
  int get hashCode => booking.id.hashCode;

  @override
  String toString() =>
      'BookingWithIdeas(bookingId: ${booking.id}, ideasCount: $ideasCount)';
}

/// Модель заметки к заявке
class BookingNote {
  const BookingNote({
    required this.id,
    required this.bookingId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.isPrivate = false,
    this.noteType = BookingNoteType.general,
  });

  /// Создать из документа Firestore
  factory BookingNote.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return BookingNote(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isPrivate: data['isPrivate'] ?? false,
      noteType: BookingNoteType.values.firstWhere(
        (e) => e.name == (data['noteType'] as String?),
        orElse: () => BookingNoteType.general,
      ),
    );
  }

  /// Создать из Map
  factory BookingNote.fromMap(Map<String, dynamic> map) => BookingNote(
        id: map['id'] ?? '',
        bookingId: map['bookingId'] ?? '',
        authorId: map['authorId'] ?? '',
        authorName: map['authorName'] ?? '',
        content: map['content'] ?? '',
        createdAt: map['createdAt'] != null
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null
            ? (map['updatedAt'] as Timestamp).toDate()
            : null,
        isPrivate: map['isPrivate'] ?? false,
        noteType: BookingNoteType.values.firstWhere(
          (e) => e.name == map['noteType'],
          orElse: () => BookingNoteType.general,
        ),
      );

  final String id;
  final String bookingId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPrivate;
  final BookingNoteType noteType;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'bookingId': bookingId,
        'authorId': authorId,
        'authorName': authorName,
        'content': content,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'isPrivate': isPrivate,
        'noteType': noteType.name,
      };

  /// Копировать с изменениями
  BookingNote copyWith({
    String? id,
    String? bookingId,
    String? authorId,
    String? authorName,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPrivate,
    BookingNoteType? noteType,
  }) =>
      BookingNote(
        id: id ?? this.id,
        bookingId: bookingId ?? this.bookingId,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isPrivate: isPrivate ?? this.isPrivate,
        noteType: noteType ?? this.noteType,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookingNote && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BookingNote(id: $id, bookingId: $bookingId, author: $authorName)';
}

/// Тип заметки к заявке
enum BookingNoteType {
  general, // Общая заметка
  inspiration, // Заметка об идеях
  requirements, // Требования
  feedback, // Обратная связь
  reminder, // Напоминание
  issue, // Проблема
  solution, // Решение
}

/// Расширение для BookingNoteType
extension BookingNoteTypeExtension on BookingNoteType {
  String get displayName {
    switch (this) {
      case BookingNoteType.general:
        return 'Общая заметка';
      case BookingNoteType.inspiration:
        return 'Идеи и вдохновение';
      case BookingNoteType.requirements:
        return 'Требования';
      case BookingNoteType.feedback:
        return 'Обратная связь';
      case BookingNoteType.reminder:
        return 'Напоминание';
      case BookingNoteType.issue:
        return 'Проблема';
      case BookingNoteType.solution:
        return 'Решение';
    }
  }

  String get icon {
    switch (this) {
      case BookingNoteType.general:
        return '📝';
      case BookingNoteType.inspiration:
        return '💡';
      case BookingNoteType.requirements:
        return '📋';
      case BookingNoteType.feedback:
        return '💬';
      case BookingNoteType.reminder:
        return '⏰';
      case BookingNoteType.issue:
        return '⚠️';
      case BookingNoteType.solution:
        return '✅';
    }
  }

  String get color {
    switch (this) {
      case BookingNoteType.general:
        return 'grey';
      case BookingNoteType.inspiration:
        return 'purple';
      case BookingNoteType.requirements:
        return 'blue';
      case BookingNoteType.feedback:
        return 'green';
      case BookingNoteType.reminder:
        return 'orange';
      case BookingNoteType.issue:
        return 'red';
      case BookingNoteType.solution:
        return 'green';
    }
  }
}
