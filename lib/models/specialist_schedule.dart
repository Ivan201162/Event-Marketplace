import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/booking.dart';

/// Расписание специалиста
class SpecialistSchedule {
  final String specialistId;
  final DateTime startDate;
  final DateTime endDate;
  final List<Booking> bookings;
  final Map<int, WorkingHours> workingHours;
  final List<ScheduleException> exceptions;
  final Map<DateTime, AvailabilityStatus> availability;

  const SpecialistSchedule({
    required this.specialistId,
    required this.startDate,
    required this.endDate,
    required this.bookings,
    required this.workingHours,
    required this.exceptions,
    required this.availability,
  });
}

/// Рабочие часы
class WorkingHours {
  final bool isWorking;
  final double startHour; // В часах (например, 9.5 = 9:30)
  final double endHour; // В часах (например, 18.0 = 18:00)

  const WorkingHours({
    required this.isWorking,
    required this.startHour,
    required this.endHour,
  });

  Map<String, dynamic> toMap() {
    return {
      'isWorking': isWorking,
      'startHour': startHour,
      'endHour': endHour,
    };
  }

  factory WorkingHours.fromMap(Map<String, dynamic> map) {
    return WorkingHours(
      isWorking: map['isWorking'] ?? false,
      startHour: (map['startHour'] as num?)?.toDouble() ?? 0.0,
      endHour: (map['endHour'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Исключение в расписании
class ScheduleException {
  final String id;
  final String specialistId;
  final ScheduleExceptionType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String? description;
  final DateTime createdAt;

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

  Map<String, dynamic> toMap() {
    return {
      'specialistId': specialistId,
      'type': type.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'reason': reason,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
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
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });
}

/// Статус доступности
enum AvailabilityStatus {
  available, // Доступен
  partiallyAvailable, // Частично занят
  unavailable, // Недоступен
  blocked, // Заблокирован
}
