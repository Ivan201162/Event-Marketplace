import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/feature_flags.dart';
import '../models/booking.dart';
import '../models/specialist_schedule.dart';

/// Сервис для управления календарем занятости специалистов
class SpecialistScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить расписание специалиста
  Future<SpecialistSchedule> getSpecialistSchedule({
    required String specialistId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!FeatureFlags.specialistScheduleEnabled) {
      throw Exception('Календарь занятости специалистов отключен');
    }

    try {
      // Получаем бронирования специалиста
      final bookings =
          await _getSpecialistBookings(specialistId, startDate, endDate);

      // Получаем рабочие часы специалиста
      final workingHours = await _getSpecialistWorkingHours(specialistId);

      // Получаем исключения (отпуска, больничные и т.д.)
      final exceptions =
          await _getSpecialistExceptions(specialistId, startDate, endDate);

      return SpecialistSchedule(
        specialistId: specialistId,
        startDate: startDate,
        endDate: endDate,
        bookings: bookings,
        workingHours: workingHours,
        exceptions: exceptions,
        availability: _calculateAvailability(
          startDate: startDate,
          endDate: endDate,
          bookings: bookings,
          workingHours: workingHours,
          exceptions: exceptions,
        ),
      );
    } catch (e) {
      throw Exception('Ошибка получения расписания специалиста: $e');
    }
  }

  /// Проверить доступность специалиста
  Future<bool> isSpecialistAvailable({
    required String specialistId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      // Получаем расписание на период
      final schedule = await getSpecialistSchedule(
        specialistId: specialistId,
        startDate: startTime,
        endDate: endTime,
      );

      // Проверяем пересечения с существующими бронированиями
      for (final booking in schedule.bookings) {
        if (_isTimeOverlapping(
          start1: startTime,
          end1: endTime,
          start2: booking.eventDate,
          end2: booking.endDate ??
              booking.eventDate.add(const Duration(hours: 2)),
        )) {
          return false;
        }
      }

      // Проверяем рабочие часы
      final dayOfWeek = startTime.weekday;
      final workingHours = schedule.workingHours[dayOfWeek];
      if (workingHours == null || !workingHours.isWorking) {
        return false;
      }

      final startHour = startTime.hour + startTime.minute / 60.0;
      final endHour = endTime.hour + endTime.minute / 60.0;

      if (startHour < workingHours.startHour ||
          endHour > workingHours.endHour) {
        return false;
      }

      // Проверяем исключения
      for (final exception in schedule.exceptions) {
        if (_isTimeOverlapping(
          start1: startTime,
          end1: endTime,
          start2: exception.startDate,
          end2: exception.endDate,
        )) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Заблокировать время в расписании
  Future<void> blockTime({
    required String specialistId,
    required DateTime startTime,
    required DateTime endTime,
    required String reason,
    String? description,
  }) async {
    try {
      final exception = ScheduleException(
        id: '',
        specialistId: specialistId,
        type: ScheduleExceptionType.blocked,
        startDate: startTime,
        endDate: endTime,
        reason: reason,
        description: description,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('schedule_exceptions').add(exception.toMap());
    } catch (e) {
      throw Exception('Ошибка блокировки времени: $e');
    }
  }

  /// Установить рабочие часы
  Future<void> setWorkingHours({
    required String specialistId,
    required Map<int, WorkingHours> workingHours,
  }) async {
    try {
      await _firestore
          .collection('specialist_working_hours')
          .doc(specialistId)
          .set({
        'specialistId': specialistId,
        'workingHours': workingHours
            .map((key, value) => MapEntry(key.toString(), value.toMap())),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Ошибка установки рабочих часов: $e');
    }
  }

  // Приватные методы

  Future<List<Booking>> _getSpecialistBookings(
    String specialistId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('eventDate', isGreaterThanOrEqualTo: startDate)
          .where('eventDate', isLessThanOrEqualTo: endDate)
          .where(
        'status',
        whereIn: ['confirmed', 'paid', 'advance_paid'],
      ).get();

      return snapshot.docs.map(Booking.fromDocument).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<int, WorkingHours>> _getSpecialistWorkingHours(
    String specialistId,
  ) async {
    try {
      final doc = await _firestore
          .collection('specialist_working_hours')
          .doc(specialistId)
          .get();
      if (doc.exists) {
        final data = doc.data();
        final workingHoursData = data['workingHours'] as Map<String, dynamic>;

        return workingHoursData.map(
          (key, value) => MapEntry(
            int.parse(key),
            WorkingHours.fromMap(Map<String, dynamic>.from(value)),
          ),
        );
      }

      // Возвращаем стандартные рабочие часы (пн-пт 9:00-18:00)
      return _getDefaultWorkingHours();
    } catch (e) {
      return _getDefaultWorkingHours();
    }
  }

  Future<List<ScheduleException>> _getSpecialistExceptions(
    String specialistId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('schedule_exceptions')
          .where('specialistId', isEqualTo: specialistId)
          .where('startDate', isGreaterThanOrEqualTo: startDate)
          .where('endDate', isLessThanOrEqualTo: endDate)
          .get();

      return snapshot.docs.map(ScheduleException.fromDocument).toList();
    } catch (e) {
      return [];
    }
  }

  Map<int, WorkingHours> _getDefaultWorkingHours() => {
        1: const WorkingHours(
          isWorking: true,
          startHour: 9,
          endHour: 18,
        ), // Понедельник
        2: const WorkingHours(
          isWorking: true,
          startHour: 9,
          endHour: 18,
        ), // Вторник
        3: const WorkingHours(
          isWorking: true,
          startHour: 9,
          endHour: 18,
        ), // Среда
        4: const WorkingHours(
          isWorking: true,
          startHour: 9,
          endHour: 18,
        ), // Четверг
        5: const WorkingHours(
          isWorking: true,
          startHour: 9,
          endHour: 18,
        ), // Пятница
        6: const WorkingHours(
          isWorking: false,
          startHour: 0,
          endHour: 0,
        ), // Суббота
        7: const WorkingHours(
          isWorking: false,
          startHour: 0,
          endHour: 0,
        ), // Воскресенье
      };

  bool _isTimeOverlapping({
    required DateTime start1,
    required DateTime end1,
    required DateTime start2,
    required DateTime end2,
  }) =>
      start1.isBefore(end2) && end1.isAfter(start2);

  Map<DateTime, AvailabilityStatus> _calculateAvailability({
    required DateTime startDate,
    required DateTime endDate,
    required List<Booking> bookings,
    required Map<int, WorkingHours> workingHours,
    required List<ScheduleException> exceptions,
  }) {
    final availability = <DateTime, AvailabilityStatus>{};
    final currentDate = startDate;

    while (currentDate.isBefore(endDate)) {
      final dayOfWeek = currentDate.weekday;
      final workingHoursForDay = workingHours[dayOfWeek];

      if (workingHoursForDay == null || !workingHoursForDay.isWorking) {
        availability[currentDate] = AvailabilityStatus.unavailable;
      } else {
        // Проверяем исключения
        var hasException = false;
        for (final exception in exceptions) {
          if (currentDate.isAfter(
                exception.startDate.subtract(const Duration(days: 1)),
              ) &&
              currentDate
                  .isBefore(exception.endDate.add(const Duration(days: 1)))) {
            availability[currentDate] = AvailabilityStatus.blocked;
            hasException = true;
            break;
          }
        }

        if (!hasException) {
          // Проверяем бронирования
          final dayBookings = bookings
              .where(
                (b) =>
                    b.eventDate.year == currentDate.year &&
                    b.eventDate.month == currentDate.month &&
                    b.eventDate.day == currentDate.day,
              )
              .toList();

          if (dayBookings.isNotEmpty) {
            availability[currentDate] = AvailabilityStatus.partiallyAvailable;
          } else {
            availability[currentDate] = AvailabilityStatus.available;
          }
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return availability;
  }
}
