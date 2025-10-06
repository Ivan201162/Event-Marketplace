import 'package:cloud_firestore/cloud_firestore.dart';

/// Типы напоминаний
enum ReminderType {
  eventWeekBefore, // За неделю до события
  eventDayBefore, // За день до события
  anniversary, // Годовщина
  custom, // Пользовательское напоминание
}

/// Статус напоминания
enum ReminderStatus {
  scheduled, // Запланировано
  sent, // Отправлено
  cancelled, // Отменено
  failed, // Ошибка отправки
}

/// Модель напоминания
class Reminder {
  const Reminder({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.scheduledTime,
    required this.status,
    this.eventId,
    this.bookingId,
    this.anniversaryDate,
    this.isRecurring = false,
    this.recurrenceInterval,
    this.metadata,
    required this.createdAt,
    this.sentAt,
    this.cancelledAt,
  });

  /// Создать напоминание из документа Firestore
  factory Reminder.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return Reminder(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      type: ReminderType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ReminderType.custom,
      ),
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
      status: ReminderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ReminderStatus.scheduled,
      ),
      eventId: data['eventId'] as String?,
      bookingId: data['bookingId'] as String?,
      anniversaryDate: data['anniversaryDate'] != null
          ? (data['anniversaryDate'] as Timestamp).toDate()
          : null,
      isRecurring: data['isRecurring'] as bool? ?? false,
      recurrenceInterval: data['recurrenceInterval'] as int?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      sentAt: data['sentAt'] != null
          ? (data['sentAt'] as Timestamp).toDate()
          : null,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
    );
  }

  final String id;
  final String userId;
  final ReminderType type;
  final String title;
  final String message;
  final DateTime scheduledTime;
  final ReminderStatus status;
  final String? eventId;
  final String? bookingId;
  final DateTime? anniversaryDate;
  final bool isRecurring;
  final int? recurrenceInterval; // в днях
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? cancelledAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type.name,
        'title': title,
        'message': message,
        'scheduledTime': Timestamp.fromDate(scheduledTime),
        'status': status.name,
        'eventId': eventId,
        'bookingId': bookingId,
        'anniversaryDate': anniversaryDate != null
            ? Timestamp.fromDate(anniversaryDate!)
            : null,
        'isRecurring': isRecurring,
        'recurrenceInterval': recurrenceInterval,
        'metadata': metadata,
        'createdAt': Timestamp.fromDate(createdAt),
        'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
        'cancelledAt':
            cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      };

  /// Создать копию с изменениями
  Reminder copyWith({
    String? id,
    String? userId,
    ReminderType? type,
    String? title,
    String? message,
    DateTime? scheduledTime,
    ReminderStatus? status,
    String? eventId,
    String? bookingId,
    DateTime? anniversaryDate,
    bool? isRecurring,
    int? recurrenceInterval,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? sentAt,
    DateTime? cancelledAt,
  }) =>
      Reminder(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        title: title ?? this.title,
        message: message ?? this.message,
        scheduledTime: scheduledTime ?? this.scheduledTime,
        status: status ?? this.status,
        eventId: eventId ?? this.eventId,
        bookingId: bookingId ?? this.bookingId,
        anniversaryDate: anniversaryDate ?? this.anniversaryDate,
        isRecurring: isRecurring ?? this.isRecurring,
        recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        sentAt: sentAt ?? this.sentAt,
        cancelledAt: cancelledAt ?? this.cancelledAt,
      );

  /// Проверить, является ли напоминание активным
  bool get isActive => status == ReminderStatus.scheduled;

  /// Проверить, является ли напоминание просроченным
  bool get isOverdue =>
      status == ReminderStatus.scheduled &&
      scheduledTime.isBefore(DateTime.now());

  /// Получить иконку для типа напоминания
  String get typeIcon {
    switch (type) {
      case ReminderType.eventWeekBefore:
        return '📅';
      case ReminderType.eventDayBefore:
        return '⏰';
      case ReminderType.anniversary:
        return '🎉';
      case ReminderType.custom:
        return '🔔';
    }
  }

  /// Получить название типа напоминания
  String get typeName {
    switch (type) {
      case ReminderType.eventWeekBefore:
        return 'За неделю до события';
      case ReminderType.eventDayBefore:
        return 'За день до события';
      case ReminderType.anniversary:
        return 'Годовщина';
      case ReminderType.custom:
        return 'Пользовательское';
    }
  }

  /// Получить цвет для статуса
  String get statusColor {
    switch (status) {
      case ReminderStatus.scheduled:
        return 'blue';
      case ReminderStatus.sent:
        return 'green';
      case ReminderStatus.cancelled:
        return 'grey';
      case ReminderStatus.failed:
        return 'red';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reminder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Reminder(id: $id, type: $type, title: $title, scheduledTime: $scheduledTime)';
}

/// Модель настроек напоминаний пользователя
class ReminderSettings {
  const ReminderSettings({
    required this.userId,
    this.eventRemindersEnabled = true,
    this.anniversaryRemindersEnabled = true,
    this.weekBeforeReminder = true,
    this.dayBeforeReminder = true,
    this.customRemindersEnabled = true,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.timezone = 'Europe/Moscow',
    this.language = 'ru',
    required this.updatedAt,
  });

  /// Создать настройки из документа Firestore
  factory ReminderSettings.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    return ReminderSettings(
      userId: doc.id,
      eventRemindersEnabled: data['eventRemindersEnabled'] as bool? ?? true,
      anniversaryRemindersEnabled:
          data['anniversaryRemindersEnabled'] as bool? ?? true,
      weekBeforeReminder: data['weekBeforeReminder'] as bool? ?? true,
      dayBeforeReminder: data['dayBeforeReminder'] as bool? ?? true,
      customRemindersEnabled: data['customRemindersEnabled'] as bool? ?? true,
      quietHoursStart: data['quietHoursStart'] != null
          ? (data['quietHoursStart'] as Timestamp).toDate()
          : null,
      quietHoursEnd: data['quietHoursEnd'] != null
          ? (data['quietHoursEnd'] as Timestamp).toDate()
          : null,
      timezone: data['timezone'] as String? ?? 'Europe/Moscow',
      language: data['language'] as String? ?? 'ru',
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  final String userId;
  final bool eventRemindersEnabled;
  final bool anniversaryRemindersEnabled;
  final bool weekBeforeReminder;
  final bool dayBeforeReminder;
  final bool customRemindersEnabled;
  final DateTime? quietHoursStart;
  final DateTime? quietHoursEnd;
  final String timezone;
  final String language;
  final DateTime updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'eventRemindersEnabled': eventRemindersEnabled,
        'anniversaryRemindersEnabled': anniversaryRemindersEnabled,
        'weekBeforeReminder': weekBeforeReminder,
        'dayBeforeReminder': dayBeforeReminder,
        'customRemindersEnabled': customRemindersEnabled,
        'quietHoursStart': quietHoursStart != null
            ? Timestamp.fromDate(quietHoursStart!)
            : null,
        'quietHoursEnd':
            quietHoursEnd != null ? Timestamp.fromDate(quietHoursEnd!) : null,
        'timezone': timezone,
        'language': language,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// Создать копию с изменениями
  ReminderSettings copyWith({
    String? userId,
    bool? eventRemindersEnabled,
    bool? anniversaryRemindersEnabled,
    bool? weekBeforeReminder,
    bool? dayBeforeReminder,
    bool? customRemindersEnabled,
    DateTime? quietHoursStart,
    DateTime? quietHoursEnd,
    String? timezone,
    String? language,
    DateTime? updatedAt,
  }) =>
      ReminderSettings(
        userId: userId ?? this.userId,
        eventRemindersEnabled:
            eventRemindersEnabled ?? this.eventRemindersEnabled,
        anniversaryRemindersEnabled:
            anniversaryRemindersEnabled ?? this.anniversaryRemindersEnabled,
        weekBeforeReminder: weekBeforeReminder ?? this.weekBeforeReminder,
        dayBeforeReminder: dayBeforeReminder ?? this.dayBeforeReminder,
        customRemindersEnabled:
            customRemindersEnabled ?? this.customRemindersEnabled,
        quietHoursStart: quietHoursStart ?? this.quietHoursStart,
        quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
        timezone: timezone ?? this.timezone,
        language: language ?? this.language,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Проверить, разрешены ли напоминания в текущее время
  bool isReminderAllowed(DateTime time) {
    if (quietHoursStart == null || quietHoursEnd == null) return true;

    final currentTime = TimeOfDay.fromDateTime(time);
    final startTime = TimeOfDay.fromDateTime(quietHoursStart!);
    final endTime = TimeOfDay.fromDateTime(quietHoursEnd!);

    // Простая проверка: если текущее время между quiet hours
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (startMinutes <= endMinutes) {
      // Обычный случай: quiet hours в пределах одного дня
      return currentMinutes < startMinutes || currentMinutes > endMinutes;
    } else {
      // Quiet hours переходят через полночь
      return currentMinutes < startMinutes && currentMinutes > endMinutes;
    }
  }
}
