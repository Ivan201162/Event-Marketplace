import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/specialist_calendar.dart';
import '../models/booking.dart';

/// Сервис для работы с календарем специалиста
class SpecialistCalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать временной слот
  Future<String> createTimeSlot(TimeSlot timeSlot) async {
    try {
      final docRef = await _firestore.collection('time_slots').add(timeSlot.toMap());
      
      debugPrint('Time slot created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating time slot: $e');
      throw Exception('Ошибка создания временного слота: $e');
    }
  }

  /// Обновить временной слот
  Future<void> updateTimeSlot(TimeSlot timeSlot) async {
    try {
      await _firestore.collection('time_slots').doc(timeSlot.id).update({
        ...timeSlot.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Time slot updated: ${timeSlot.id}');
    } catch (e) {
      debugPrint('Error updating time slot: $e');
      throw Exception('Ошибка обновления временного слота: $e');
    }
  }

  /// Удалить временной слот
  Future<void> deleteTimeSlot(String timeSlotId) async {
    try {
      await _firestore.collection('time_slots').doc(timeSlotId).delete();
      
      debugPrint('Time slot deleted: $timeSlotId');
    } catch (e) {
      debugPrint('Error deleting time slot: $e');
      throw Exception('Ошибка удаления временного слота: $e');
    }
  }

  /// Заблокировать временной слот
  Future<void> blockTimeSlot(String timeSlotId, BlockType blockType, String reason) async {
    try {
      await _firestore.collection('time_slots').doc(timeSlotId).update({
        'status': TimeSlotStatus.blocked.name,
        'blockType': blockType.name,
        'blockReason': reason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Time slot blocked: $timeSlotId');
    } catch (e) {
      debugPrint('Error blocking time slot: $e');
      throw Exception('Ошибка блокировки временного слота: $e');
    }
  }

  /// Разблокировать временной слот
  Future<void> unblockTimeSlot(String timeSlotId) async {
    try {
      await _firestore.collection('time_slots').doc(timeSlotId).update({
        'status': TimeSlotStatus.available.name,
        'blockType': null,
        'blockReason': null,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Time slot unblocked: $timeSlotId');
    } catch (e) {
      debugPrint('Error unblocking time slot: $e');
      throw Exception('Ошибка разблокировки временного слота: $e');
    }
  }

  /// Забронировать временной слот
  Future<void> bookTimeSlot(String timeSlotId, String bookingId) async {
    try {
      await _firestore.collection('time_slots').doc(timeSlotId).update({
        'status': TimeSlotStatus.booked.name,
        'bookingId': bookingId,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Time slot booked: $timeSlotId');
    } catch (e) {
      debugPrint('Error booking time slot: $e');
      throw Exception('Ошибка бронирования временного слота: $e');
    }
  }

  /// Отменить бронирование временного слота
  Future<void> cancelBooking(String timeSlotId) async {
    try {
      await _firestore.collection('time_slots').doc(timeSlotId).update({
        'status': TimeSlotStatus.available.name,
        'bookingId': null,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Time slot booking cancelled: $timeSlotId');
    } catch (e) {
      debugPrint('Error cancelling time slot booking: $e');
      throw Exception('Ошибка отмены бронирования временного слота: $e');
    }
  }

  /// Получить временные слоты специалиста на дату
  Stream<List<TimeSlot>> getSpecialistTimeSlots(String specialistId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return _firestore
        .collection('time_slots')
        .where('specialistId', isEqualTo: specialistId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TimeSlot.fromDocument(doc)).toList();
    });
  }

  /// Получить доступные временные слоты специалиста на дату
  Stream<List<TimeSlot>> getAvailableTimeSlots(String specialistId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return _firestore
        .collection('time_slots')
        .where('specialistId', isEqualTo: specialistId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .where('status', isEqualTo: TimeSlotStatus.available.name)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TimeSlot.fromDocument(doc)).toList();
    });
  }

  /// Получить забронированные временные слоты специалиста на дату
  Stream<List<TimeSlot>> getBookedTimeSlots(String specialistId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return _firestore
        .collection('time_slots')
        .where('specialistId', isEqualTo: specialistId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .where('status', isEqualTo: TimeSlotStatus.booked.name)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TimeSlot.fromDocument(doc)).toList();
    });
  }

  /// Получить заблокированные временные слоты специалиста на дату
  Stream<List<TimeSlot>> getBlockedTimeSlots(String specialistId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return _firestore
        .collection('time_slots')
        .where('specialistId', isEqualTo: specialistId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .where('status', isEqualTo: TimeSlotStatus.blocked.name)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TimeSlot.fromDocument(doc)).toList();
    });
  }

  /// Получить временные слоты специалиста в диапазоне дат
  Stream<List<TimeSlot>> getSpecialistTimeSlotsInRange(
    String specialistId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection('time_slots')
        .where('specialistId', isEqualTo: specialistId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date')
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TimeSlot.fromDocument(doc)).toList();
    });
  }

  /// Создать рабочее расписание
  Future<String> createSchedule(SpecialistSchedule schedule) async {
    try {
      final docRef = await _firestore.collection('specialist_schedules').add(schedule.toMap());
      
      debugPrint('Schedule created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating schedule: $e');
      throw Exception('Ошибка создания расписания: $e');
    }
  }

  /// Обновить рабочее расписание
  Future<void> updateSchedule(SpecialistSchedule schedule) async {
    try {
      await _firestore.collection('specialist_schedules').doc(schedule.id).update({
        ...schedule.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Schedule updated: ${schedule.id}');
    } catch (e) {
      debugPrint('Error updating schedule: $e');
      throw Exception('Ошибка обновления расписания: $e');
    }
  }

  /// Удалить рабочее расписание
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _firestore.collection('specialist_schedules').doc(scheduleId).delete();
      
      debugPrint('Schedule deleted: $scheduleId');
    } catch (e) {
      debugPrint('Error deleting schedule: $e');
      throw Exception('Ошибка удаления расписания: $e');
    }
  }

  /// Получить рабочее расписание специалиста
  Stream<List<SpecialistSchedule>> getSpecialistSchedule(String specialistId) {
    return _firestore
        .collection('specialist_schedules')
        .where('specialistId', isEqualTo: specialistId)
        .where('isActive', isEqualTo: true)
        .orderBy('dayOfWeek')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SpecialistSchedule.fromDocument(doc)).toList();
    });
  }

  /// Получить рабочее расписание на конкретный день недели
  Future<SpecialistSchedule?> getScheduleForDay(String specialistId, int dayOfWeek) async {
    try {
      final scheduleQuery = await _firestore
          .collection('specialist_schedules')
          .where('specialistId', isEqualTo: specialistId)
          .where('dayOfWeek', isEqualTo: dayOfWeek)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (scheduleQuery.docs.isEmpty) return null;
      
      return SpecialistSchedule.fromDocument(scheduleQuery.docs.first);
    } catch (e) {
      debugPrint('Error getting schedule for day: $e');
      return null;
    }
  }

  /// Создать временные слоты на основе расписания
  Future<void> generateTimeSlotsFromSchedule(String specialistId, DateTime date) async {
    try {
      final dayOfWeek = date.weekday;
      final schedule = await getScheduleForDay(specialistId, dayOfWeek);
      
      if (schedule == null) {
        debugPrint('No schedule found for day $dayOfWeek');
        return;
      }

      // Проверяем, не созданы ли уже слоты на эту дату
      final existingSlotsQuery = await _firestore
          .collection('time_slots')
          .where('specialistId', isEqualTo: specialistId)
          .where('date', isEqualTo: Timestamp.fromDate(date))
          .get();

      if (existingSlotsQuery.docs.isNotEmpty) {
        debugPrint('Time slots already exist for date $date');
        return;
      }

      // Создаем слоты на основе расписания
      final slots = <TimeSlot>[];
      final startTime = DateTime(date.year, date.month, date.day, schedule.startTime.hour, schedule.startTime.minute);
      final endTime = DateTime(date.year, date.month, date.day, schedule.endTime.hour, schedule.endTime.minute);
      
      // Создаем слоты по 1 часу
      DateTime currentTime = startTime;
      while (currentTime.isBefore(endTime)) {
        final slotEndTime = currentTime.add(const Duration(hours: 1));
        
        // Проверяем, не попадает ли слот в перерыв
        if (schedule.breakStartTime != null && schedule.breakEndTime != null) {
          final breakStart = DateTime(date.year, date.month, date.day, schedule.breakStartTime!.hour, schedule.breakStartTime!.minute);
          final breakEnd = DateTime(date.year, date.month, date.day, schedule.breakEndTime!.hour, schedule.breakEndTime!.minute);
          
          if (currentTime.isBefore(breakEnd) && slotEndTime.isAfter(breakStart)) {
            // Слот пересекается с перерывом, пропускаем
            currentTime = slotEndTime;
            continue;
          }
        }
        
        final slot = TimeSlot(
          id: '', // Будет установлен Firestore
          specialistId: specialistId,
          date: date,
          startTime: currentTime,
          endTime: slotEndTime,
          status: TimeSlotStatus.available,
          createdAt: DateTime.now(),
        );
        
        slots.add(slot);
        currentTime = slotEndTime;
      }

      // Сохраняем слоты в Firestore
      for (final slot in slots) {
        await _firestore.collection('time_slots').add(slot.toMap());
      }
      
      debugPrint('Generated ${slots.length} time slots for date $date');
    } catch (e) {
      debugPrint('Error generating time slots from schedule: $e');
      throw Exception('Ошибка создания временных слотов: $e');
    }
  }

  /// Создать временные слоты на диапазон дат
  Future<void> generateTimeSlotsForDateRange(
    String specialistId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      DateTime currentDate = startDate;
      while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
        await generateTimeSlotsFromSchedule(specialistId, currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      debugPrint('Generated time slots for date range: $startDate - $endDate');
    } catch (e) {
      debugPrint('Error generating time slots for date range: $e');
      throw Exception('Ошибка создания временных слотов для диапазона дат: $e');
    }
  }

  /// Получить статистику календаря специалиста
  Future<Map<String, dynamic>> getCalendarStats(String specialistId, DateTime startDate, DateTime endDate) async {
    try {
      final timeSlotsQuery = await _firestore
          .collection('time_slots')
          .where('specialistId', isEqualTo: specialistId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      if (timeSlotsQuery.docs.isEmpty) {
        return {
          'totalSlots': 0,
          'availableSlots': 0,
          'bookedSlots': 0,
          'blockedSlots': 0,
          'occupancyRate': 0.0,
          'totalHours': 0.0,
          'bookedHours': 0.0,
        };
      }

      int totalSlots = 0;
      int availableSlots = 0;
      int bookedSlots = 0;
      int blockedSlots = 0;
      double totalHours = 0.0;
      double bookedHours = 0.0;

      for (final doc in timeSlotsQuery.docs) {
        final slot = TimeSlot.fromDocument(doc);
        
        totalSlots++;
        totalHours += slot.durationInHours;
        
        switch (slot.status) {
          case TimeSlotStatus.available:
            availableSlots++;
            break;
          case TimeSlotStatus.booked:
            bookedSlots++;
            bookedHours += slot.durationInHours;
            break;
          case TimeSlotStatus.blocked:
            blockedSlots++;
            break;
          case TimeSlotStatus.unavailable:
            break;
        }
      }

      final occupancyRate = totalSlots > 0 ? (bookedSlots / totalSlots) * 100 : 0.0;

      return {
        'totalSlots': totalSlots,
        'availableSlots': availableSlots,
        'bookedSlots': bookedSlots,
        'blockedSlots': blockedSlots,
        'occupancyRate': occupancyRate,
        'totalHours': totalHours,
        'bookedHours': bookedHours,
      };
    } catch (e) {
      debugPrint('Error getting calendar stats: $e');
      return {};
    }
  }

  /// Получить доступные даты для бронирования
  Future<List<DateTime>> getAvailableDates(String specialistId, DateTime startDate, DateTime endDate) async {
    try {
      final availableDates = <DateTime>[];
      DateTime currentDate = startDate;
      
      while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
        final availableSlotsQuery = await _firestore
            .collection('time_slots')
            .where('specialistId', isEqualTo: specialistId)
            .where('date', isEqualTo: Timestamp.fromDate(currentDate))
            .where('status', isEqualTo: TimeSlotStatus.available.name)
            .get();

        if (availableSlotsQuery.docs.isNotEmpty) {
          availableDates.add(currentDate);
        }
        
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      return availableDates;
    } catch (e) {
      debugPrint('Error getting available dates: $e');
      return [];
    }
  }

  /// Проверить доступность временного слота
  Future<bool> isTimeSlotAvailable(String timeSlotId) async {
    try {
      final doc = await _firestore.collection('time_slots').doc(timeSlotId).get();
      if (!doc.exists) return false;
      
      final slot = TimeSlot.fromDocument(doc);
      return slot.isAvailable;
    } catch (e) {
      debugPrint('Error checking time slot availability: $e');
      return false;
    }
  }

  /// Получить временной слот по ID
  Future<TimeSlot?> getTimeSlotById(String timeSlotId) async {
    try {
      final doc = await _firestore.collection('time_slots').doc(timeSlotId).get();
      if (!doc.exists) return null;
      
      return TimeSlot.fromDocument(doc);
    } catch (e) {
      debugPrint('Error getting time slot by ID: $e');
      return null;
    }
  }

  /// Получить календарь специалиста на месяц
  Future<Map<DateTime, List<TimeSlot>>> getMonthlyCalendar(String specialistId, DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      
      final timeSlotsQuery = await _firestore
          .collection('time_slots')
          .where('specialistId', isEqualTo: specialistId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('date')
          .orderBy('startTime')
          .get();

      final calendar = <DateTime, List<TimeSlot>>{};
      
      for (final doc in timeSlotsQuery.docs) {
        final slot = TimeSlot.fromDocument(doc);
        final date = DateTime(slot.date.year, slot.date.month, slot.date.day);
        
        calendar.putIfAbsent(date, () => []).add(slot);
      }
      
      return calendar;
    } catch (e) {
      debugPrint('Error getting monthly calendar: $e');
      return {};
    }
  }
}
