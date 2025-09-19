import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking.dart';

/// Расписание специалиста
class SpecialistSchedule {
  const SpecialistSchedule({
    required this.specialistId,
    required this.startDate,
    required this.endDate,
    required this.bookings,
    required this.workingHours,
    required this.exceptions,
    required this.availability,
  });

  /// Создать из Map
  factory SpecialistSchedule.fromMap(Map<String, dynamic> data) =>
      SpecialistSchedule(
        specialistId: data['specialistId'] ?? '',
        startDate: data['startDate'] != null
            ? (data['startDate'] as Timestamp).toDate()
            : DateTime.now(),
        endDate: data['endDate'] != null
            ? (data['endDate'] as Timestamp).toDate()
            : DateTime.now(),
        bookings: (data['bookings'] as List<dynamic>?)
                ?.map((e) => Booking.fromDocument(e as DocumentSnapshot))
                .toList() ??
            [],
        workingHours: (data['workingHours'] as Map<String, dynamic>?)
                ?.map(
                  (key, value) => MapEntry(
                    int.parse(key),
                    WorkingHours.fromMap(value as Map<String, dynamic>),
                  ),
                )
                .cast<int, WorkingHours>() ??
            {},
        exceptions: (data['exceptions'] as List<dynamic>?)
                ?.map(
                    (e) => ScheduleException.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        availability: (data['availability'] as Map<String, dynamic>?)
                ?.map(
                  (key, value) => MapEntry(
                    DateTime.parse(key),
                    AvailabilityStatus.values.firstWhere(
                      (status) => status.name == value,
                      orElse: () => AvailabilityStatus.available,
                    ),
                  ),
                )
                .cast<DateTime, AvailabilityStatus>() ??
            {},
      );
  final String specialistId;
  final DateTime startDate;
  final DateTime endDate;
  final List<Booking> bookings;
  final Map<int, WorkingHours> workingHours;
  final List<ScheduleException> exceptions;
  final Map<DateTime, AvailabilityStatus> availability;

  /// Получить события для конкретной даты
  List<ScheduleEvent> getEventsForDate(DateTime date) => bookings
      .where(
        (booking) =>
            booking.eventDate.year == date.year &&
            booking.eventDate.month == date.month &&
            booking.eventDate.day == date.day,
      )
      .map(
        (booking) => ScheduleEvent(
          id: booking.id,
          title: booking.eventTitle,
          startTime: booking.eventDate,
          endTime: booking.endDate ??
              booking.eventDate.add(const Duration(hours: 2)),
          type: ScheduleEventType.booking,
          bookingId: booking.id,
        ),
      )
      .toList();
}

/// Рабочие часы
class WorkingHours {
  // В часах (например, 18.0 = 18:00)

  const WorkingHours({
    required this.isWorking,
    required this.startHour,
    required this.endHour,
  });

  factory WorkingHours.fromMap(Map<String, dynamic> map) => WorkingHours(
        isWorking: map['isWorking'] ?? false,
        startHour: (map['startHour'] as num?)?.toDouble() ?? 0.0,
        endHour: (map['endHour'] as num?)?.toDouble() ?? 0.0,
      );
  final bool isWorking;
  final double startHour; // В часах (например, 9.5 = 9:30)
  final double endHour;

  Map<String, dynamic> toMap() => {
        'isWorking': isWorking,
        'startHour': startHour,
        'endHour': endHour,
      };
}

/// Исключение в расписании
class ScheduleException {
  const ScheduleException({
    required this.id,
    required this.specialistId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.description,
    required this.createdAt,
  });

  factory ScheduleException.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduleException(
      id: doc.id,
      specialistId: data['specialistId'] ?? '',
      type: ScheduleExceptionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ScheduleExceptionType.blocked,
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      reason: data['reason'] ?? '',
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
  final String id;
  final String specialistId;
  final ScheduleExceptionType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String? description;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'type': type.name,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'reason': reason,
        'description': description,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

/// Типы исключений в расписании
enum ScheduleExceptionType {
  blocked, // Заблокированное время
  vacation, // Отпуск
  sickLeave, // Больничный
  personal, // Личные дела
}

/// Временной слот
class TimeSlot {
  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
}

/// Статус доступности
enum AvailabilityStatus {
  available, // Доступен
  partiallyAvailable, // Частично занят
  unavailable, // Недоступен
  blocked, // Заблокирован
}

/// Типы событий в расписании
enum ScheduleEventType {
  booking, // Бронирование
  unavailable, // Недоступен
  vacation, // Отпуск
  maintenance, // Техническое обслуживание
}

/// Событие в расписании
class ScheduleEvent {
  const ScheduleEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.bookingId,
    this.description,
  });

  /// Создать из Map
  factory ScheduleEvent.fromMap(Map<String, dynamic> data) => ScheduleEvent(
        id: data['id'] ?? '',
        title: data['title'] ?? '',
        startTime: data['startTime'] != null
            ? (data['startTime'] as Timestamp).toDate()
            : DateTime.now(),
        endTime: data['endTime'] != null
            ? (data['endTime'] as Timestamp).toDate()
            : DateTime.now(),
        type: ScheduleEventType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => ScheduleEventType.booking,
        ),
        bookingId: data['bookingId'],
        description: data['description'],
      );
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final ScheduleEventType type;
  final String? bookingId;
  final String? description;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'type': type.name,
        'bookingId': bookingId,
        'description': description,
      };
}
