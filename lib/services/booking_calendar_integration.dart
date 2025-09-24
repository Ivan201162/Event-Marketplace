import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/calendar_event.dart';
import '../models/booking.dart';
import 'calendar_service.dart';

/// Сервис интеграции календаря с бронированиями
class BookingCalendarIntegration {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CalendarService _calendarService = CalendarService();

  /// Создать событие календаря при подтверждении бронирования
  Future<void> createCalendarEventFromBooking(Booking booking) async {
    try {
      // Создаем событие для специалиста
      await _calendarService.createEventFromBooking(
        userId: booking.specialistId,
        bookingId: booking.id,
        title: 'Бронирование: ${booking.eventTitle}',
        description: booking.notes ?? 'Бронирование от ${booking.customerName}',
        startDate: booking.eventDate,
        endDate: booking.eventDate.add(booking.duration),
        location: booking.location,
      );

      // Создаем событие для заказчика
      await _calendarService.createEventFromBooking(
        userId: booking.customerId,
        bookingId: booking.id,
        title: 'Мероприятие: ${booking.eventTitle}',
        description: 'Мероприятие с ${booking.specialistName}',
        startDate: booking.eventDate,
        endDate: booking.eventDate.add(booking.duration),
        location: booking.location,
      );

      debugPrint('События календаря созданы для бронирования: ${booking.id}');
    } catch (e) {
      debugPrint('Ошибка создания событий календаря из бронирования: $e');
      throw Exception('Не удалось создать события календаря: $e');
    }
  }

  /// Обновить событие календаря при изменении бронирования
  Future<void> updateCalendarEventFromBooking(Booking booking) async {
    try {
      // Находим существующие события календаря для этого бронирования
      final specialistEvents = await _findCalendarEventsByBooking(booking.id, booking.specialistId);
      final customerEvents = await _findCalendarEventsByBooking(booking.id, booking.customerId);

      // Обновляем событие специалиста
      if (specialistEvents.isNotEmpty) {
        final specialistEvent = specialistEvents.first;
        final updatedEvent = specialistEvent.copyWith(
          title: 'Бронирование: ${booking.eventTitle}',
          description: booking.notes ?? 'Бронирование от ${booking.customerName}',
          startDate: booking.eventDate,
          endDate: booking.eventDate.add(booking.duration),
          location: booking.location,
          updatedAt: DateTime.now(),
        );
        await _calendarService.updateEvent(updatedEvent);
      }

      // Обновляем событие заказчика
      if (customerEvents.isNotEmpty) {
        final customerEvent = customerEvents.first;
        final updatedEvent = customerEvent.copyWith(
          title: 'Мероприятие: ${booking.eventTitle}',
          description: 'Мероприятие с ${booking.specialistName}',
          startDate: booking.eventDate,
          endDate: booking.eventDate.add(booking.duration),
          location: booking.location,
          updatedAt: DateTime.now(),
        );
        await _calendarService.updateEvent(updatedEvent);
      }

      debugPrint('События календаря обновлены для бронирования: ${booking.id}');
    } catch (e) {
      debugPrint('Ошибка обновления событий календаря: $e');
      throw Exception('Не удалось обновить события календаря: $e');
    }
  }

  /// Удалить событие календаря при отмене бронирования
  Future<void> deleteCalendarEventFromBooking(String bookingId, String specialistId, String customerId) async {
    try {
      // Находим и удаляем события календаря
      final specialistEvents = await _findCalendarEventsByBooking(bookingId, specialistId);
      final customerEvents = await _findCalendarEventsByBooking(bookingId, customerId);

      for (final event in specialistEvents) {
        await _calendarService.deleteEvent(event.id);
      }

      for (final event in customerEvents) {
        await _calendarService.deleteEvent(event.id);
      }

      debugPrint('События календаря удалены для бронирования: $bookingId');
    } catch (e) {
      debugPrint('Ошибка удаления событий календаря: $e');
      throw Exception('Не удалось удалить события календаря: $e');
    }
  }

  /// Проверить доступность специалиста для бронирования
  Future<bool> isSpecialistAvailable({
    required String specialistId,
    required DateTime startDate,
    required DateTime endDate,
    String? excludeBookingId,
  }) async {
    try {
      return await _calendarService.isTimeAvailable(
        userId: specialistId,
        startDate: startDate,
        endDate: endDate,
        excludeEventId: excludeBookingId,
      );
    } catch (e) {
      debugPrint('Ошибка проверки доступности специалиста: $e');
      return false;
    }
  }

  /// Получить доступные слоты времени специалиста
  Future<List<TimeSlot>> getSpecialistAvailableSlots({
    required String specialistId,
    required DateTime date,
    Duration slotDuration = const Duration(hours: 1),
  }) async {
    try {
      return await _calendarService.getAvailableTimeSlots(
        userId: specialistId,
        date: date,
        slotDuration: slotDuration,
        workingHoursStart: const Duration(hours: 9),
        workingHoursEnd: const Duration(hours: 18),
      );
    } catch (e) {
      debugPrint('Ошибка получения доступных слотов: $e');
      return [];
    }
  }

  /// Синхронизировать календарь с бронированиями
  Future<void> syncCalendarWithBookings(String userId) async {
    try {
      // Получаем все активные бронирования пользователя
      final bookingsQuery = await _db
          .collection('bookings')
          .where('status', whereIn: ['confirmed', 'in_progress'])
          .where('specialistId', isEqualTo: userId)
          .get();

      final customerBookingsQuery = await _db
          .collection('bookings')
          .where('status', whereIn: ['confirmed', 'in_progress'])
          .where('customerId', isEqualTo: userId)
          .get();

      final allBookings = [...bookingsQuery.docs, ...customerBookingsQuery.docs];

      // Создаем события календаря для всех активных бронирований
      for (final doc in allBookings) {
        final booking = Booking.fromDocument(doc);
        await createCalendarEventFromBooking(booking);
      }

      debugPrint('Календарь синхронизирован с бронированиями для пользователя: $userId');
    } catch (e) {
      debugPrint('Ошибка синхронизации календаря: $e');
      throw Exception('Не удалось синхронизировать календарь: $e');
    }
  }

  /// Найти события календаря по ID бронирования
  Future<List<CalendarEvent>> _findCalendarEventsByBooking(String bookingId, String userId) async {
    try {
      final query = await _db
          .collection('calendarEvents')
          .where('userId', isEqualTo: userId)
          .where('bookingId', isEqualTo: bookingId)
          .get();

      return query.docs
          .map((doc) => CalendarEvent.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Ошибка поиска событий календаря по бронированию: $e');
      return [];
    }
  }

  /// Получить статистику занятости специалиста
  Future<SpecialistAvailabilityStats> getSpecialistAvailabilityStats({
    required String specialistId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final events = await _calendarService.getEventsForPeriod(
        userId: specialistId,
        startDate: startDate,
        endDate: endDate,
      );

      int totalHours = 0;
      int busyHours = 0;
      int freeHours = 0;
      int personalHours = 0;

      for (final event in events) {
        final eventHours = event.durationInMinutes / 60.0;
        totalHours += eventHours.toInt();

        switch (event.status) {
          case CalendarEventStatus.busy:
            busyHours += eventHours.toInt();
            break;
          case CalendarEventStatus.free:
            freeHours += eventHours.toInt();
            break;
          case CalendarEventStatus.personal:
            personalHours += eventHours.toInt();
            break;
          default:
            break;
        }
      }

      final availabilityPercentage = totalHours > 0 ? (freeHours / totalHours * 100) : 0.0;

      return SpecialistAvailabilityStats(
        totalHours: totalHours,
        busyHours: busyHours,
        freeHours: freeHours,
        personalHours: personalHours,
        availabilityPercentage: availabilityPercentage,
        period: DatePeriod(startDate: startDate, endDate: endDate),
      );
    } catch (e) {
      debugPrint('Ошибка получения статистики доступности: $e');
      return SpecialistAvailabilityStats(
        totalHours: 0,
        busyHours: 0,
        freeHours: 0,
        personalHours: 0,
        availabilityPercentage: 0.0,
        period: DatePeriod(startDate: startDate, endDate: endDate),
      );
    }
  }

  /// Автоматически заблокировать время для специалиста
  Future<void> autoBlockTimeForSpecialist({
    required String specialistId,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    try {
      await _calendarService.blockTime(
        userId: specialistId,
        title: reason ?? 'Автоматическая блокировка',
        startDate: startDate,
        endDate: endDate,
        description: 'Время автоматически заблокировано системой',
      );

      debugPrint('Время автоматически заблокировано для специалиста: $specialistId');
    } catch (e) {
      debugPrint('Ошибка автоматической блокировки времени: $e');
    }
  }

  /// Получить конфликты в расписании
  Future<List<ScheduleConflict>> getScheduleConflicts({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final events = await _calendarService.getEventsForPeriod(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      final conflicts = <ScheduleConflict>[];

      // Проверяем пересечения событий
      for (int i = 0; i < events.length; i++) {
        for (int j = i + 1; j < events.length; j++) {
          final event1 = events[i];
          final event2 = events[j];

          if (event1.overlapsWith(event2.startDate, event2.endDate)) {
            conflicts.add(ScheduleConflict(
              event1: event1,
              event2: event2,
              conflictType: ConflictType.overlap,
              conflictStart: event1.startDate.isAfter(event2.startDate) ? event1.startDate : event2.startDate,
              conflictEnd: event1.endDate.isBefore(event2.endDate) ? event1.endDate : event2.endDate,
            ));
          }
        }
      }

      return conflicts;
    } catch (e) {
      debugPrint('Ошибка получения конфликтов расписания: $e');
      return [];
    }
  }
}

/// Статистика доступности специалиста
class SpecialistAvailabilityStats {
  const SpecialistAvailabilityStats({
    required this.totalHours,
    required this.busyHours,
    required this.freeHours,
    required this.personalHours,
    required this.availabilityPercentage,
    required this.period,
  });

  final int totalHours;
  final int busyHours;
  final int freeHours;
  final int personalHours;
  final double availabilityPercentage;
  final DatePeriod period;
}

/// Конфликт в расписании
class ScheduleConflict {
  const ScheduleConflict({
    required this.event1,
    required this.event2,
    required this.conflictType,
    required this.conflictStart,
    required this.conflictEnd,
  });

  final CalendarEvent event1;
  final CalendarEvent event2;
  final ConflictType conflictType;
  final DateTime conflictStart;
  final DateTime conflictEnd;
}

/// Тип конфликта
enum ConflictType {
  overlap,    // Пересечение
  gap,        // Промежуток
  tooShort,   // Слишком короткий
  tooLong,    // Слишком длинный
}
