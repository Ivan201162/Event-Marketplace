import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/logger.dart';
import '../models/event_calendar.dart';

/// Сервис для работы с календарем событий
class EventCalendarService {
  factory EventCalendarService() => _instance;
  EventCalendarService._internal();
  static final EventCalendarService _instance = EventCalendarService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить события для пользователя за период
  Future<List<CalendarEvent>> getEventsForPeriod({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      AppLogger.logI('Получение событий для пользователя $userId за период $startDate - $endDate', 'event_calendar_service');
      
      final snapshot = await _firestore
          .collection('calendar_events')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date')
          .get();

      final events = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CalendarEvent.fromMap(data);
      }).toList();

      // Добавляем повторяющиеся события
      final recurringEvents = await _getRecurringEvents(userId, startDate, endDate);
      events.addAll(recurringEvents);

      // Сортируем по дате
      events.sort((a, b) => a.date.compareTo(b.date));

      return events;
    } catch (e) {
      AppLogger.logE('Ошибка получения событий: $e', 'event_calendar_service');
      return [];
    }
  }

  /// Получить события на сегодня
  Future<List<CalendarEvent>> getTodayEvents(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return getEventsForPeriod(
      userId: userId,
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  /// Получить события на неделю
  Future<List<CalendarEvent>> getWeekEvents(String userId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return getEventsForPeriod(
      userId: userId,
      startDate: startOfWeek,
      endDate: endOfWeek,
    );
  }

  /// Получить события на месяц
  Future<List<CalendarEvent>> getMonthEvents(String userId, DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return getEventsForPeriod(
      userId: userId,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  /// Создать событие
  Future<String> createEvent(CalendarEvent event) async {
    try {
      AppLogger.logI('Создание события: ${event.title}', 'event_calendar_service');
      
      final docRef = await _firestore.collection('calendar_events').add({
        ...event.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Создаем напоминание если указано
      if (event.reminderTime != null) {
        await _createReminder(EventReminder(
          id: '',
          eventId: docRef.id,
          userId: event.userId,
          reminderTime: event.reminderTime!,
          message: 'Напоминание: ${event.title}',
        ));
      }

      AppLogger.logI('Событие создано с ID: ${docRef.id}', 'event_calendar_service');
      return docRef.id;
    } catch (e) {
      AppLogger.logE('Ошибка создания события: $e', 'event_calendar_service');
      rethrow;
    }
  }

  /// Обновить событие
  Future<void> updateEvent(CalendarEvent event) async {
    try {
      AppLogger.logI('Обновление события: ${event.id}', 'event_calendar_service');
      
      await _firestore.collection('calendar_events').doc(event.id).update({
        ...event.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.logI('Событие обновлено: ${event.id}', 'event_calendar_service');
    } catch (e) {
      AppLogger.logE('Ошибка обновления события: $e', 'event_calendar_service');
      rethrow;
    }
  }

  /// Удалить событие
  Future<void> deleteEvent(String eventId) async {
    try {
      AppLogger.logI('Удаление события: $eventId', 'event_calendar_service');
      
      await _firestore.collection('calendar_events').doc(eventId).delete();
      
      // Удаляем связанные напоминания
      await _deleteEventReminders(eventId);

      AppLogger.logI('Событие удалено: $eventId', 'event_calendar_service');
    } catch (e) {
      AppLogger.logE('Ошибка удаления события: $e', 'event_calendar_service');
      rethrow;
    }
  }

  /// Получить повторяющиеся события
  Future<List<CalendarEvent>> _getRecurringEvents(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('calendar_events')
          .where('userId', isEqualTo: userId)
          .where('isRecurring', isEqualTo: true)
          .get();

      final recurringEvents = <CalendarEvent>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final event = CalendarEvent.fromMap(data);

        if (event.recurringPattern != null) {
          final generatedEvents = _generateRecurringEvents(event, startDate, endDate);
          recurringEvents.addAll(generatedEvents);
        }
      }

      return recurringEvents;
    } catch (e) {
      AppLogger.logE('Ошибка получения повторяющихся событий: $e', 'event_calendar_service');
      return [];
    }
  }

  /// Генерировать повторяющиеся события
  List<CalendarEvent> _generateRecurringEvents(
    CalendarEvent event,
    DateTime startDate,
    DateTime endDate,
  ) {
    final events = <CalendarEvent>[];
    final pattern = event.recurringPattern!;
    
    var currentDate = event.date;
    
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      if (currentDate.isAfter(startDate) || currentDate.isAtSameMomentAs(startDate)) {
        events.add(event.copyWith(
          id: '${event.id}_${currentDate.millisecondsSinceEpoch}',
          date: currentDate,
        ));
      }

      currentDate = _getNextRecurringDate(currentDate, pattern);
      
      // Проверяем ограничение по дате окончания
      if (pattern.endDate != null && currentDate.isAfter(pattern.endDate!)) {
        break;
      }
    }

    return events;
  }

  /// Получить следующую дату повторения
  DateTime _getNextRecurringDate(DateTime currentDate, RecurringPattern pattern) {
    switch (pattern.frequency) {
      case RecurringFrequency.daily:
        return currentDate.add(Duration(days: pattern.interval));
      case RecurringFrequency.weekly:
        return currentDate.add(Duration(days: 7 * pattern.interval));
      case RecurringFrequency.monthly:
        return DateTime(
          currentDate.year,
          currentDate.month + pattern.interval,
          currentDate.day,
        );
      case RecurringFrequency.yearly:
        return DateTime(
          currentDate.year + pattern.interval,
          currentDate.month,
          currentDate.day,
        );
    }
  }

  /// Создать напоминание
  Future<void> _createReminder(EventReminder reminder) async {
    try {
      await _firestore.collection('event_reminders').add({
        ...reminder.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.logE('Ошибка создания напоминания: $e', 'event_calendar_service');
    }
  }

  /// Удалить напоминания события
  Future<void> _deleteEventReminders(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('event_reminders')
          .where('eventId', isEqualTo: eventId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      AppLogger.logE('Ошибка удаления напоминаний: $e', 'event_calendar_service');
    }
  }

  /// Получить предстоящие напоминания
  Future<List<EventReminder>> getUpcomingReminders(String userId) async {
    try {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('event_reminders')
          .where('userId', isEqualTo: userId)
          .where('isSent', isEqualTo: false)
          .where('reminderTime', isGreaterThanOrEqualTo: now)
          .where('reminderTime', isLessThanOrEqualTo: tomorrow)
          .orderBy('reminderTime')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return EventReminder.fromMap(data);
      }).toList();
    } catch (e) {
      AppLogger.logE('Ошибка получения напоминаний: $e', 'event_calendar_service');
      return [];
    }
  }

  /// Отметить напоминание как отправленное
  Future<void> markReminderAsSent(String reminderId) async {
    try {
      await _firestore.collection('event_reminders').doc(reminderId).update({
        'isSent': true,
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.logE('Ошибка обновления напоминания: $e', 'event_calendar_service');
    }
  }

  /// Создать событие из заявки
  Future<String> createEventFromBooking({
    required String userId,
    required String bookingId,
    required String title,
    required DateTime date,
    String? description,
    String? location,
  }) async {
    final event = CalendarEvent(
      id: '',
      userId: userId,
      title: title,
      date: date,
      type: EventType.booking,
      description: description,
      location: location,
      relatedBookingId: bookingId,
      createdAt: DateTime.now(),
    );

    return createEvent(event);
  }

  /// Получить статистику событий
  Future<EventStatistics> getEventStatistics(String userId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final events = await getEventsForPeriod(
        userId: userId,
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      final eventCounts = <EventType, int>{};
      for (final event in events) {
        eventCounts[event.type] = (eventCounts[event.type] ?? 0) + 1;
      }

      return EventStatistics(
        totalEvents: events.length,
        eventCounts: eventCounts,
        upcomingEvents: events.where((e) => e.date.isAfter(now)).length,
        pastEvents: events.where((e) => e.date.isBefore(now)).length,
      );
    } catch (e) {
      AppLogger.logE('Ошибка получения статистики событий: $e', 'event_calendar_service');
      return const EventStatistics(
        totalEvents: 0,
        eventCounts: {},
        upcomingEvents: 0,
        pastEvents: 0,
      );
    }
  }
}

/// Статистика событий
class EventStatistics {
  const EventStatistics({
    required this.totalEvents,
    required this.eventCounts,
    required this.upcomingEvents,
    required this.pastEvents,
  });

  final int totalEvents;
  final Map<EventType, int> eventCounts;
  final int upcomingEvents;
  final int pastEvents;
}
