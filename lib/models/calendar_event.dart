import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Модель календарного события
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.specialistId,
    required this.specialistName,
    required this.customerId,
    required this.customerName,
    required this.bookingId,
    required this.status,
    required this.type,
    this.attendees = const [],
    this.metadata = const {},
    this.isAllDay = false,
    this.recurrenceRule,
    this.reminderTime,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CalendarEvent.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return CalendarEvent(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'] as String? ?? '',
      specialistId: data['specialistId'] as String? ?? '',
      specialistName: data['specialistName'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      bookingId: data['bookingId'] as String? ?? '',
      status: EventStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => EventStatus.scheduled,
      ),
      type: EventType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => EventType.booking,
      ),
      attendees: List<String>.from(data['attendees'] as List<dynamic>? ?? []),
      metadata: Map<String, dynamic>.from(
          data['metadata'] as Map<dynamic, dynamic>? ?? {}),
      isAllDay: data['isAllDay'] as bool? ?? false,
      recurrenceRule: data['recurrenceRule'] as String?,
      reminderTime: data['reminderTime'] as String?,
      color: data['color'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String specialistId;
  final String specialistName;
  final String customerId;
  final String customerName;
  final String bookingId;
  final EventStatus status;
  final EventType type;
  final List<String> attendees;
  final Map<String, dynamic> metadata;
  final bool isAllDay;
  final String? recurrenceRule;
  final String? reminderTime;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'location': location,
        'specialistId': specialistId,
        'specialistName': specialistName,
        'customerId': customerId,
        'customerName': customerName,
        'bookingId': bookingId,
        'status': status.name,
        'type': type.name,
        'attendees': attendees,
        'metadata': metadata,
        'isAllDay': isAllDay,
        'recurrenceRule': recurrenceRule,
        'reminderTime': reminderTime,
        'color': color,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? specialistId,
    String? specialistName,
    String? customerId,
    String? customerName,
    String? bookingId,
    EventStatus? status,
    EventType? type,
    List<String>? attendees,
    Map<String, dynamic>? metadata,
    bool? isAllDay,
    String? recurrenceRule,
    String? reminderTime,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      CalendarEvent(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        location: location ?? this.location,
        specialistId: specialistId ?? this.specialistId,
        specialistName: specialistName ?? this.specialistName,
        customerId: customerId ?? this.customerId,
        customerName: customerName ?? this.customerName,
        bookingId: bookingId ?? this.bookingId,
        status: status ?? this.status,
        type: type ?? this.type,
        attendees: attendees ?? this.attendees,
        metadata: metadata ?? this.metadata,
        isAllDay: isAllDay ?? this.isAllDay,
        recurrenceRule: recurrenceRule ?? this.recurrenceRule,
        reminderTime: reminderTime ?? this.reminderTime,
        color: color ?? this.color,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Получить длительность события
  Duration get duration => endTime.difference(startTime);

  /// Проверить, является ли событие сегодняшним
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(startTime.year, startTime.month, startTime.day);
    return today == eventDate;
  }

  /// Проверить, является ли событие завтрашним
  bool get isTomorrow {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final eventDate = DateTime(startTime.year, startTime.month, startTime.day);
    return tomorrow == eventDate;
  }

  /// Проверить, является ли событие вчерашним
  bool get isYesterday {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final eventDate = DateTime(startTime.year, startTime.month, startTime.day);
    return yesterday == eventDate;
  }

  /// Проверить, является ли событие прошедшим
  bool get isPast => endTime.isBefore(DateTime.now());

  /// Проверить, является ли событие текущим
  bool get isCurrent {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Проверить, является ли событие будущим
  bool get isFuture => startTime.isAfter(DateTime.now());

  /// Получить цвет события
  Color get eventColor {
    if (color != null) {
      return Color(int.parse(color!.replaceFirst('#', '0xff')));
    }

    switch (status) {
      case EventStatus.scheduled:
        return Colors.blue;
      case EventStatus.confirmed:
        return Colors.green;
      case EventStatus.cancelled:
        return Colors.red;
      case EventStatus.completed:
        return Colors.grey;
      case EventStatus.postponed:
        return Colors.orange;
    }
  }

  /// Получить иконку события
  IconData get eventIcon {
    switch (type) {
      case EventType.booking:
        return Icons.event;
      case EventType.consultation:
        return Icons.chat;
      case EventType.meeting:
        return Icons.people;
      case EventType.reminder:
        return Icons.notifications;
      case EventType.deadline:
        return Icons.schedule;
    }
  }
}

/// Статус события
enum EventStatus {
  scheduled,
  confirmed,
  cancelled,
  completed,
  postponed,
}

/// Тип события
enum EventType {
  booking,
  consultation,
  meeting,
  reminder,
  deadline,
}

/// Фильтр для календарных событий
class CalendarFilter {
  const CalendarFilter({
    this.startDate,
    this.endDate,
    this.statuses,
    this.types,
    this.specialistId,
    this.customerId,
    this.isAllDay,
    this.searchQuery,
  });
  final DateTime? startDate;
  final DateTime? endDate;
  final List<EventStatus>? statuses;
  final List<EventType>? types;
  final String? specialistId;
  final String? customerId;
  final bool? isAllDay;
  final String? searchQuery;

  CalendarFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<EventStatus>? statuses,
    List<EventType>? types,
    String? specialistId,
    String? customerId,
    bool? isAllDay,
    String? searchQuery,
  }) =>
      CalendarFilter(
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        statuses: statuses ?? this.statuses,
        types: types ?? this.types,
        specialistId: specialistId ?? this.specialistId,
        customerId: customerId ?? this.customerId,
        isAllDay: isAllDay ?? this.isAllDay,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

/// Настройки календаря
class CalendarSettings {
  const CalendarSettings({
    this.showWeekends = true,
    this.showAllDayEvents = true,
    this.showCompletedEvents = false,
    this.showCancelledEvents = false,
    this.defaultView = 'month',
    this.weekStartDay = 1,
    this.timeFormat = '24h',
    this.enableNotifications = true,
    this.defaultReminderTime = '15m',
    this.eventColors = const {},
  });
  final bool showWeekends;
  final bool showAllDayEvents;
  final bool showCompletedEvents;
  final bool showCancelledEvents;
  final String defaultView;
  final int weekStartDay;
  final String timeFormat;
  final bool enableNotifications;
  final String defaultReminderTime;
  final Map<String, String> eventColors;

  CalendarSettings copyWith({
    bool? showWeekends,
    bool? showAllDayEvents,
    bool? showCompletedEvents,
    bool? showCancelledEvents,
    String? defaultView,
    int? weekStartDay,
    String? timeFormat,
    bool? enableNotifications,
    String? defaultReminderTime,
    Map<String, String>? eventColors,
  }) =>
      CalendarSettings(
        showWeekends: showWeekends ?? this.showWeekends,
        showAllDayEvents: showAllDayEvents ?? this.showAllDayEvents,
        showCompletedEvents: showCompletedEvents ?? this.showCompletedEvents,
        showCancelledEvents: showCancelledEvents ?? this.showCancelledEvents,
        defaultView: defaultView ?? this.defaultView,
        weekStartDay: weekStartDay ?? this.weekStartDay,
        timeFormat: timeFormat ?? this.timeFormat,
        enableNotifications: enableNotifications ?? this.enableNotifications,
        defaultReminderTime: defaultReminderTime ?? this.defaultReminderTime,
        eventColors: eventColors ?? this.eventColors,
      );
}

/// Синхронизация с внешними календарями
class CalendarSync {
  const CalendarSync({
    required this.id,
    required this.userId,
    required this.provider,
    required this.providerId,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenExpiry,
    required this.isActive,
    required this.lastSync,
    this.settings = const {},
  });

  factory CalendarSync.fromMap(Map<String, dynamic> map) => CalendarSync(
        id: map['id'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        provider: map['provider'] as String? ?? '',
        providerId: map['providerId'] as String? ?? '',
        accessToken: map['accessToken'] as String? ?? '',
        refreshToken: map['refreshToken'] as String? ?? '',
        tokenExpiry:
            (map['tokenExpiry'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isActive: map['isActive'] as bool? ?? false,
        lastSync: (map['lastSync'] as Timestamp?)?.toDate() ?? DateTime.now(),
        settings: Map<String, dynamic>.from(
            map['settings'] as Map<dynamic, dynamic>? ?? {}),
      );
  final String id;
  final String userId;
  final String provider;
  final String providerId;
  final String accessToken;
  final String refreshToken;
  final DateTime tokenExpiry;
  final bool isActive;
  final DateTime lastSync;
  final Map<String, dynamic> settings;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'provider': provider,
        'providerId': providerId,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'tokenExpiry': Timestamp.fromDate(tokenExpiry),
        'isActive': isActive,
        'lastSync': Timestamp.fromDate(lastSync),
        'settings': settings,
      };
}

/// Провайдеры календаря
enum CalendarProvider {
  google,
  outlook,
  apple,
  local,
}

/// Статистика календаря
class CalendarStats {
  const CalendarStats({
    required this.totalEvents,
    required this.completedEvents,
    required this.cancelledEvents,
    required this.upcomingEvents,
    required this.averageEventDuration,
    required this.eventsByType,
    required this.eventsByStatus,
    required this.busiestDays,
  });

  factory CalendarStats.empty() => const CalendarStats(
        totalEvents: 0,
        completedEvents: 0,
        cancelledEvents: 0,
        upcomingEvents: 0,
        averageEventDuration: 0,
        eventsByType: {},
        eventsByStatus: {},
        busiestDays: [],
      );
  final int totalEvents;
  final int completedEvents;
  final int cancelledEvents;
  final int upcomingEvents;
  final double averageEventDuration;
  final Map<EventType, int> eventsByType;
  final Map<EventStatus, int> eventsByStatus;
  final List<DateTime> busiestDays;
}
