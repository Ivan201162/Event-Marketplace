/// Событие в календаре
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    required this.type,
    this.description,
    this.location,
    this.reminderTime,
    this.isRecurring = false,
    this.recurringPattern,
    this.relatedBookingId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final DateTime date;
  final EventType type;
  final String? description;
  final String? location;
  final DateTime? reminderTime;
  final bool isRecurring;
  final RecurringPattern? recurringPattern;
  final String? relatedBookingId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      date: (map['date'] as DateTime),
      type: EventType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => EventType.other,
      ),
      description: map['description'] as String?,
      location: map['location'] as String?,
      reminderTime: map['reminderTime'] != null 
          ? (map['reminderTime'] as DateTime)
          : null,
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurringPattern: map['recurringPattern'] != null
          ? RecurringPattern.fromMap(map['recurringPattern'] as Map<String, dynamic>)
          : null,
      relatedBookingId: map['relatedBookingId'] as String?,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as DateTime)
          : null,
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as DateTime)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'date': date,
      'type': type.name,
      'description': description,
      'location': location,
      'reminderTime': reminderTime,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern?.toMap(),
      'relatedBookingId': relatedBookingId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  CalendarEvent copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? date,
    EventType? type,
    String? description,
    String? location,
    DateTime? reminderTime,
    bool? isRecurring,
    RecurringPattern? recurringPattern,
    String? relatedBookingId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      date: date ?? this.date,
      type: type ?? this.type,
      description: description ?? this.description,
      location: location ?? this.location,
      reminderTime: reminderTime ?? this.reminderTime,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      relatedBookingId: relatedBookingId ?? this.relatedBookingId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Тип события
enum EventType {
  anniversary, // Годовщина
  birthday, // День рождения
  wedding, // Свадьба
  corporate, // Корпоративное мероприятие
  holiday, // Праздник
  reminder, // Напоминание
  booking, // Связанное с заявкой
  other, // Другое
}

/// Паттерн повторения
class RecurringPattern {
  const RecurringPattern({
    required this.frequency,
    required this.interval,
    this.endDate,
    this.daysOfWeek,
    this.dayOfMonth,
  });

  final RecurringFrequency frequency;
  final int interval;
  final DateTime? endDate;
  final List<int>? daysOfWeek; // 1-7 (понедельник-воскресенье)
  final int? dayOfMonth; // 1-31

  factory RecurringPattern.fromMap(Map<String, dynamic> map) {
    return RecurringPattern(
      frequency: RecurringFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => RecurringFrequency.yearly,
      ),
      interval: map['interval'] as int,
      endDate: map['endDate'] != null 
          ? (map['endDate'] as DateTime)
          : null,
      daysOfWeek: map['daysOfWeek'] != null 
          ? List<int>.from(map['daysOfWeek'] as List)
          : null,
      dayOfMonth: map['dayOfMonth'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency.name,
      'interval': interval,
      'endDate': endDate,
      'daysOfWeek': daysOfWeek,
      'dayOfMonth': dayOfMonth,
    };
  }
}

/// Частота повторения
enum RecurringFrequency {
  daily, // Ежедневно
  weekly, // Еженедельно
  monthly, // Ежемесячно
  yearly, // Ежегодно
}

/// Напоминание
class EventReminder {
  const EventReminder({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.reminderTime,
    required this.message,
    this.isSent = false,
    this.sentAt,
  });

  final String id;
  final String eventId;
  final String userId;
  final DateTime reminderTime;
  final String message;
  final bool isSent;
  final DateTime? sentAt;

  factory EventReminder.fromMap(Map<String, dynamic> map) {
    return EventReminder(
      id: map['id'] as String,
      eventId: map['eventId'] as String,
      userId: map['userId'] as String,
      reminderTime: (map['reminderTime'] as DateTime),
      message: map['message'] as String,
      isSent: map['isSent'] as bool? ?? false,
      sentAt: map['sentAt'] != null 
          ? (map['sentAt'] as DateTime)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'reminderTime': reminderTime,
      'message': message,
      'isSent': isSent,
      'sentAt': sentAt,
    };
  }
}

/// Расширение для EventType
extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.anniversary:
        return 'Годовщина';
      case EventType.birthday:
        return 'День рождения';
      case EventType.wedding:
        return 'Свадьба';
      case EventType.corporate:
        return 'Корпоративное мероприятие';
      case EventType.holiday:
        return 'Праздник';
      case EventType.reminder:
        return 'Напоминание';
      case EventType.booking:
        return 'Связанное с заявкой';
      case EventType.other:
        return 'Другое';
    }
  }

  String get icon {
    switch (this) {
      case EventType.anniversary:
        return '🎉';
      case EventType.birthday:
        return '🎂';
      case EventType.wedding:
        return '💒';
      case EventType.corporate:
        return '🏢';
      case EventType.holiday:
        return '🎊';
      case EventType.reminder:
        return '⏰';
      case EventType.booking:
        return '📅';
      case EventType.other:
        return '📌';
    }
  }
}
