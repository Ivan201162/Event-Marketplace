import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус календарного события
enum CalendarEventStatus {
  busy,      // Занят
  free,      // Свободен
  tentative, // Предварительно
  blocked,   // Заблокирован
  personal,  // Личное событие
}

/// Тип календарного события
enum CalendarEventType {
  booking,   // Бронирование
  personal,  // Личное событие
  blocked,   // Заблокированное время
  reminder,  // Напоминание
}

/// Модель календарного события
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.userId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.type,
    required this.createdAt,
    this.bookingId,
    this.description,
    this.location,
    this.color,
    this.isAllDay = false,
    this.reminderMinutes = const [60, 1440], // 1 час и 24 часа
    this.isRecurring = false,
    this.recurrenceRule,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String? bookingId;
  final String title;
  final String? description;
  final String? location;
  final DateTime startDate;
  final DateTime endDate;
  final CalendarEventStatus status;
  final CalendarEventType type;
  final String? color;
  final bool isAllDay;
  final List<int> reminderMinutes;
  final bool isRecurring;
  final String? recurrenceRule;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Создать из документа Firestore
  factory CalendarEvent.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return CalendarEvent(
      id: doc.id,
      userId: data['userId'] as String,
      bookingId: data['bookingId'] as String?,
      title: data['title'] as String,
      description: data['description'] as String?,
      location: data['location'] as String?,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: CalendarEventStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => CalendarEventStatus.busy,
      ),
      type: CalendarEventType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => CalendarEventType.personal,
      ),
      color: data['color'] as String?,
      isAllDay: data['isAllDay'] as bool? ?? false,
      reminderMinutes: List<int>.from(data['reminderMinutes'] ?? [60, 1440]),
      isRecurring: data['isRecurring'] as bool? ?? false,
      recurrenceRule: data['recurrenceRule'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'bookingId': bookingId,
    'title': title,
    'description': description,
    'location': location,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'status': status.name,
    'type': type.name,
    'color': color,
    'isAllDay': isAllDay,
    'reminderMinutes': reminderMinutes,
    'isRecurring': isRecurring,
    'recurrenceRule': recurrenceRule,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  /// Создать копию с изменениями
  CalendarEvent copyWith({
    String? id,
    String? userId,
    String? bookingId,
    String? title,
    String? description,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    CalendarEventStatus? status,
    CalendarEventType? type,
    String? color,
    bool? isAllDay,
    List<int>? reminderMinutes,
    bool? isRecurring,
    String? recurrenceRule,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      CalendarEvent(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        bookingId: bookingId ?? this.bookingId,
        title: title ?? this.title,
        description: description ?? this.description,
        location: location ?? this.location,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        status: status ?? this.status,
        type: type ?? this.type,
        color: color ?? this.color,
        isAllDay: isAllDay ?? this.isAllDay,
        reminderMinutes: reminderMinutes ?? this.reminderMinutes,
        isRecurring: isRecurring ?? this.isRecurring,
        recurrenceRule: recurrenceRule ?? this.recurrenceRule,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Проверить, пересекается ли событие с указанным временным интервалом
  bool overlapsWith(DateTime start, DateTime end) {
    return startDate.isBefore(end) && endDate.isAfter(start);
  }

  /// Проверить, происходит ли событие в указанную дату
  bool occursOnDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return overlapsWith(startOfDay, endOfDay);
  }

  /// Получить цвет события
  Color get eventColor {
    if (color != null) {
      return Color(int.parse(color!.replaceFirst('#', '0xff')));
    }
    
    switch (status) {
      case CalendarEventStatus.busy:
        return Colors.red;
      case CalendarEventStatus.free:
        return Colors.green;
      case CalendarEventStatus.tentative:
        return Colors.orange;
      case CalendarEventStatus.blocked:
        return Colors.grey;
      case CalendarEventStatus.personal:
        return Colors.blue;
    }
  }

  /// Получить иконку для события
  IconData get eventIcon {
    switch (type) {
      case CalendarEventType.booking:
        return Icons.event;
      case CalendarEventType.personal:
        return Icons.person;
      case CalendarEventType.blocked:
        return Icons.block;
      case CalendarEventType.reminder:
        return Icons.notifications;
    }
  }

  /// Получить длительность события в минутах
  int get durationInMinutes {
    return endDate.difference(startDate).inMinutes;
  }

  /// Проверить, является ли событие активным
  bool get isActive {
    final now = DateTime.now();
    return startDate.isBefore(now) && endDate.isAfter(now);
  }

  /// Проверить, является ли событие прошедшим
  bool get isPast {
    return endDate.isBefore(DateTime.now());
  }

  /// Проверить, является ли событие будущим
  bool get isFuture {
    return startDate.isAfter(DateTime.now());
  }
}

/// Правило повторения события
class RecurrenceRule {
  const RecurrenceRule({
    required this.frequency,
    required this.interval,
    this.count,
    this.until,
    this.byDay,
    this.byMonth,
    this.byMonthDay,
  });

  final RecurrenceFrequency frequency;
  final int interval;
  final int? count;
  final DateTime? until;
  final List<int>? byDay; // 0 = Sunday, 1 = Monday, etc.
  final List<int>? byMonth;
  final List<int>? byMonthDay;

  /// Создать из строки RRULE
  factory RecurrenceRule.fromString(String rrule) {
    // Простая реализация парсинга RRULE
    // В реальном приложении нужен более сложный парсер
    final parts = rrule.split(';');
    RecurrenceFrequency frequency = RecurrenceFrequency.daily;
    int interval = 1;
    int? count;
    DateTime? until;
    List<int>? byDay;
    List<int>? byMonth;
    List<int>? byMonthDay;

    for (final part in parts) {
      final keyValue = part.split('=');
      if (keyValue.length != 2) continue;

      final key = keyValue[0];
      final value = keyValue[1];

      switch (key) {
        case 'FREQ':
          frequency = RecurrenceFrequency.values.firstWhere(
            (f) => f.name.toUpperCase() == value,
            orElse: () => RecurrenceFrequency.daily,
          );
          break;
        case 'INTERVAL':
          interval = int.tryParse(value) ?? 1;
          break;
        case 'COUNT':
          count = int.tryParse(value);
          break;
        case 'UNTIL':
          until = DateTime.tryParse(value);
          break;
        case 'BYDAY':
          byDay = value.split(',').map((day) {
            switch (day) {
              case 'SU': return 0;
              case 'MO': return 1;
              case 'TU': return 2;
              case 'WE': return 3;
              case 'TH': return 4;
              case 'FR': return 5;
              case 'SA': return 6;
              default: return 0;
            }
          }).toList();
          break;
        case 'BYMONTH':
          byMonth = value.split(',').map(int.parse).toList();
          break;
        case 'BYMONTHDAY':
          byMonthDay = value.split(',').map(int.parse).toList();
          break;
      }
    }

    return RecurrenceRule(
      frequency: frequency,
      interval: interval,
      count: count,
      until: until,
      byDay: byDay,
      byMonth: byMonth,
      byMonthDay: byMonthDay,
    );
  }

  /// Преобразовать в строку RRULE
  String toString() {
    final parts = <String>[];
    parts.add('FREQ=${frequency.name.toUpperCase()}');
    parts.add('INTERVAL=$interval');
    
    if (count != null) parts.add('COUNT=$count');
    if (until != null) parts.add('UNTIL=${until!.toIso8601String()}');
    
    if (byDay != null) {
      final dayNames = byDay!.map((day) {
        switch (day) {
          case 0: return 'SU';
          case 1: return 'MO';
          case 2: return 'TU';
          case 3: return 'WE';
          case 4: return 'TH';
          case 5: return 'FR';
          case 6: return 'SA';
          default: return 'SU';
        }
      }).toList();
      parts.add('BYDAY=${dayNames.join(',')}');
    }
    
    if (byMonth != null) parts.add('BYMONTH=${byMonth!.join(',')}');
    if (byMonthDay != null) parts.add('BYMONTHDAY=${byMonthDay!.join(',')}');
    
    return parts.join(';');
  }
}

/// Частота повторения
enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly,
}

/// Напоминание о событии
class EventReminder {
  const EventReminder({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.reminderTime,
    required this.message,
    required this.isSent,
    this.sentAt,
    this.createdAt,
  });

  final String id;
  final String eventId;
  final String userId;
  final DateTime reminderTime;
  final String message;
  final bool isSent;
  final DateTime? sentAt;
  final DateTime? createdAt;

  /// Создать из документа Firestore
  factory EventReminder.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return EventReminder(
      id: doc.id,
      eventId: data['eventId'] as String,
      userId: data['userId'] as String,
      reminderTime: (data['reminderTime'] as Timestamp).toDate(),
      message: data['message'] as String,
      isSent: data['isSent'] as bool? ?? false,
      sentAt: data['sentAt'] != null
          ? (data['sentAt'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'eventId': eventId,
    'userId': userId,
    'reminderTime': Timestamp.fromDate(reminderTime),
    'message': message,
    'isSent': isSent,
    'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
  };
}