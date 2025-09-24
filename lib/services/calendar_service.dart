import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/calendar_event.dart';

/// Сервис для работы с календарными событиями
class CalendarService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Получить события пользователя за период
  Future<List<CalendarEvent>> getEventsForPeriod({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final query = await _db
          .collection('calendarEvents')
          .where('userId', isEqualTo: userId)
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('startDate')
          .get();

      return query.docs
          .map((doc) => CalendarEvent.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения событий календаря: $e');
      return [];
    }
  }

  /// Получить события пользователя (Stream)
  Stream<List<CalendarEvent>> getEventsStream({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _db
        .collection('calendarEvents')
        .where('userId', isEqualTo: userId)
        .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('startDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CalendarEvent.fromDocument(doc))
            .toList());
  }

  /// Создать новое событие
  Future<String> createEvent(CalendarEvent event) async {
    try {
      final docRef = await _db.collection('calendarEvents').add(event.toMap());
      
      // Создаем напоминания для события
      await _createEventReminders(event.copyWith(id: docRef.id));
      
      debugPrint('Событие календаря создано: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Ошибка создания события календаря: $e');
      throw Exception('Не удалось создать событие: $e');
    }
  }

  /// Обновить событие
  Future<void> updateEvent(CalendarEvent event) async {
    try {
      await _db.collection('calendarEvents').doc(event.id).update({
        ...event.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Обновляем напоминания
      await _updateEventReminders(event);
      
      debugPrint('Событие календаря обновлено: ${event.id}');
    } catch (e) {
      debugPrint('Ошибка обновления события календаря: $e');
      throw Exception('Не удалось обновить событие: $e');
    }
  }

  /// Удалить событие
  Future<void> deleteEvent(String eventId) async {
    try {
      // Удаляем напоминания
      await _deleteEventReminders(eventId);
      
      // Удаляем событие
      await _db.collection('calendarEvents').doc(eventId).delete();
      
      debugPrint('Событие календаря удалено: $eventId');
    } catch (e) {
      debugPrint('Ошибка удаления события календаря: $e');
      throw Exception('Не удалось удалить событие: $e');
    }
  }

  /// Создать событие из бронирования
  Future<String> createEventFromBooking({
    required String userId,
    required String bookingId,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    String? location,
  }) async {
    try {
      final event = CalendarEvent(
        id: '', // Будет установлен при создании
        userId: userId,
        bookingId: bookingId,
        title: title,
        description: description,
        location: location,
        startDate: startDate,
        endDate: endDate,
        status: CalendarEventStatus.busy,
        type: CalendarEventType.booking,
        createdAt: DateTime.now(),
        color: '#FF5722', // Оранжевый цвет для бронирований
      );

      return await createEvent(event);
    } catch (e) {
      debugPrint('Ошибка создания события из бронирования: $e');
      throw Exception('Не удалось создать событие из бронирования: $e');
    }
  }

  /// Заблокировать время
  Future<String> blockTime({
    required String userId,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
  }) async {
    try {
      final event = CalendarEvent(
        id: '', // Будет установлен при создании
        userId: userId,
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
        status: CalendarEventStatus.blocked,
        type: CalendarEventType.blocked,
        createdAt: DateTime.now(),
        color: '#9E9E9E', // Серый цвет для заблокированного времени
      );

      return await createEvent(event);
    } catch (e) {
      debugPrint('Ошибка блокировки времени: $e');
      throw Exception('Не удалось заблокировать время: $e');
    }
  }

  /// Проверить доступность времени
  Future<bool> isTimeAvailable({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? excludeEventId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _db
          .collection('calendarEvents')
          .where('userId', isEqualTo: userId)
          .where('startDate', isLessThan: Timestamp.fromDate(endDate))
          .where('endDate', isGreaterThan: Timestamp.fromDate(startDate));

      final querySnapshot = await query.get();
      
      for (final doc in querySnapshot.docs) {
        if (excludeEventId != null && doc.id == excludeEventId) continue;
        
        final event = CalendarEvent.fromDocument(doc);
        if (event.status == CalendarEventStatus.busy || 
            event.status == CalendarEventStatus.blocked) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Ошибка проверки доступности времени: $e');
      return false;
    }
  }

  /// Получить свободные слоты времени
  Future<List<TimeSlot>> getAvailableTimeSlots({
    required String userId,
    required DateTime date,
    required Duration slotDuration,
    required Duration workingHoursStart,
    required Duration workingHoursEnd,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final events = await getEventsForPeriod(
        userId: userId,
        startDate: startOfDay,
        endDate: endOfDay,
      );

      final busySlots = <TimeSlot>[];
      for (final event in events) {
        if (event.status == CalendarEventStatus.busy || 
            event.status == CalendarEventStatus.blocked) {
          busySlots.add(TimeSlot(
            startTime: event.startDate,
            endTime: event.endDate,
          ));
        }
      }

      final availableSlots = <TimeSlot>[];
      final workingStart = startOfDay.add(workingHoursStart);
      final workingEnd = startOfDay.add(workingHoursEnd);
      
      var currentTime = workingStart;
      while (currentTime.add(slotDuration).isBefore(workingEnd)) {
        final slotEnd = currentTime.add(slotDuration);
        final slot = TimeSlot(startTime: currentTime, endTime: slotEnd);
        
        // Проверяем, не пересекается ли слот с занятыми временами
        bool isAvailable = true;
        for (final busySlot in busySlots) {
          if (slot.overlapsWith(busySlot)) {
            isAvailable = false;
            break;
          }
        }
        
        if (isAvailable) {
          availableSlots.add(slot);
        }
        
        currentTime = currentTime.add(slotDuration);
      }
      
      return availableSlots;
    } catch (e) {
      debugPrint('Ошибка получения свободных слотов: $e');
      return [];
    }
  }

  /// Создать напоминания для события
  Future<void> _createEventReminders(CalendarEvent event) async {
    try {
      for (final minutes in event.reminderMinutes) {
        final reminderTime = event.startDate.subtract(Duration(minutes: minutes));
        
        // Создаем напоминание только если оно в будущем
        if (reminderTime.isAfter(DateTime.now())) {
          final reminder = EventReminder(
            id: '', // Будет установлен при создании
            eventId: event.id,
            userId: event.userId,
            reminderTime: reminderTime,
            message: 'Напоминание: ${event.title}',
            isSent: false,
            createdAt: DateTime.now(),
          );

          await _db.collection('eventReminders').add(reminder.toMap());
        }
      }
    } catch (e) {
      debugPrint('Ошибка создания напоминаний: $e');
    }
  }

  /// Обновить напоминания для события
  Future<void> _updateEventReminders(CalendarEvent event) async {
    try {
      // Удаляем старые напоминания
      await _deleteEventReminders(event.id);
      
      // Создаем новые напоминания
      await _createEventReminders(event);
    } catch (e) {
      debugPrint('Ошибка обновления напоминаний: $e');
    }
  }

  /// Удалить напоминания для события
  Future<void> _deleteEventReminders(String eventId) async {
    try {
      final query = await _db
          .collection('eventReminders')
          .where('eventId', isEqualTo: eventId)
          .get();

      final batch = _db.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Ошибка удаления напоминаний: $e');
    }
  }

  /// Получить предстоящие события
  Future<List<CalendarEvent>> getUpcomingEvents({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final now = DateTime.now();
      final query = await _db
          .collection('calendarEvents')
          .where('userId', isEqualTo: userId)
          .where('startDate', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('startDate')
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => CalendarEvent.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения предстоящих событий: $e');
      return [];
    }
  }

  /// Получить события на сегодня
  Future<List<CalendarEvent>> getTodayEvents(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      return await getEventsForPeriod(
        userId: userId,
        startDate: startOfDay,
        endDate: endOfDay,
      );
    } catch (e) {
      debugPrint('Ошибка получения событий на сегодня: $e');
      return [];
    }
  }

  /// Получить статистику календаря
  Future<CalendarStats> getCalendarStats({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final events = await getEventsForPeriod(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      int totalEvents = events.length;
      int busyEvents = events.where((e) => e.status == CalendarEventStatus.busy).length;
      int freeEvents = events.where((e) => e.status == CalendarEventStatus.free).length;
      int personalEvents = events.where((e) => e.status == CalendarEventStatus.personal).length;
      int blockedEvents = events.where((e) => e.status == CalendarEventStatus.blocked).length;

      double totalHours = events.fold(0.0, (sum, event) => 
          sum + event.durationInMinutes / 60.0);

      return CalendarStats(
        totalEvents: totalEvents,
        busyEvents: busyEvents,
        freeEvents: freeEvents,
        personalEvents: personalEvents,
        blockedEvents: blockedEvents,
        totalHours: totalHours,
        period: DatePeriod(startDate: startDate, endDate: endDate),
      );
    } catch (e) {
      debugPrint('Ошибка получения статистики календаря: $e');
      return CalendarStats(
        totalEvents: 0,
        busyEvents: 0,
        freeEvents: 0,
        personalEvents: 0,
        blockedEvents: 0,
        totalHours: 0.0,
        period: DatePeriod(startDate: startDate, endDate: endDate),
      );
    }
  }
}

/// Временной слот
class TimeSlot {
  const TimeSlot({
    required this.startTime,
    required this.endTime,
  });

  final DateTime startTime;
  final DateTime endTime;

  /// Проверить, пересекается ли слот с другим
  bool overlapsWith(TimeSlot other) {
    return startTime.isBefore(other.endTime) && endTime.isAfter(other.startTime);
  }

  /// Получить длительность слота
  Duration get duration => endTime.difference(startTime);
}

/// Статистика календаря
class CalendarStats {
  const CalendarStats({
    required this.totalEvents,
    required this.busyEvents,
    required this.freeEvents,
    required this.personalEvents,
    required this.blockedEvents,
    required this.totalHours,
    required this.period,
  });

  final int totalEvents;
  final int busyEvents;
  final int freeEvents;
  final int personalEvents;
  final int blockedEvents;
  final double totalHours;
  final DatePeriod period;
}

/// Период дат
class DatePeriod {
  const DatePeriod({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  /// Получить количество дней в периоде
  int get daysCount => endDate.difference(startDate).inDays + 1;
}