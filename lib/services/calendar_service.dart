import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/stubs/stubs.dart';
import '../models/calendar_event.dart';
import '../models/specialist_schedule.dart';

/// Сервис для работы с календарем
class CalendarService {
  factory CalendarService() => _instance;
  CalendarService._internal();
  static final CalendarService _instance = CalendarService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать календарное событие
  Future<String?> createEvent(CalendarEvent event) async {
    try {
      final eventRef = _firestore.collection('calendar_events').doc();
      final eventWithId = event.copyWith(id: eventRef.id);

      await eventRef.set(eventWithId.toMap());
      return eventRef.id;
    } on Exception catch (e) {
      print('Ошибка создания события: $e');
      return null;
    }
  }

  /// Получить события пользователя
  Stream<List<CalendarEvent>> getUserEvents(
    String userId,
    CalendarFilter filter,
  ) {
    Query<Map<String, dynamic>> query =
        _firestore.collection('calendar_events');

    // Фильтр по пользователю
    query = query.where('customerId', isEqualTo: userId);

    // Применяем фильтры
    if (filter.startDate != null) {
      query = query.where(
        'startTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!),
      );
    }

    if (filter.endDate != null) {
      query = query.where(
        'startTime',
        isLessThanOrEqualTo: Timestamp.fromDate(filter.endDate!),
      );
    }

    if (filter.statuses != null && filter.statuses!.isNotEmpty) {
      query = query.where(
        'status',
        whereIn: filter.statuses!.map((s) => s.name).toList(),
      );
    }

    if (filter.types != null && filter.types!.isNotEmpty) {
      query = query.where(
        'type',
        whereIn: filter.types!.map((t) => t.name).toList(),
      );
    }

    if (filter.specialistId != null) {
      query = query.where('specialistId', isEqualTo: filter.specialistId);
    }

    if (filter.isAllDay != null) {
      query = query.where('isAllDay', isEqualTo: filter.isAllDay);
    }

    // Сортировка по времени начала
    query = query.orderBy('startTime', descending: false);

    // Добавляем лимит для оптимизации
    query = query.limit(50);

    return query.snapshots().map((snapshot) {
      var events = snapshot.docs.map(CalendarEvent.fromDocument).toList();

      // Применяем фильтры, которые нельзя применить в Firestore
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        events = events
            .where(
              (event) =>
                  event.title.toLowerCase().contains(query) ||
                  event.description.toLowerCase().contains(query) ||
                  event.location.toLowerCase().contains(query),
            )
            .toList();
      }

      return events;
    });
  }

  /// Получить события специалиста
  Stream<List<CalendarEvent>> getSpecialistEvents(
    String specialistId,
    CalendarFilter filter,
  ) {
    Query<Map<String, dynamic>> query =
        _firestore.collection('calendar_events');

    // Фильтр по специалисту
    query = query.where('specialistId', isEqualTo: specialistId);

    // Применяем остальные фильтры аналогично getUserEvents
    if (filter.startDate != null) {
      query = query.where(
        'startTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(filter.startDate!),
      );
    }

    if (filter.endDate != null) {
      query = query.where(
        'startTime',
        isLessThanOrEqualTo: Timestamp.fromDate(filter.endDate!),
      );
    }

    if (filter.statuses != null && filter.statuses!.isNotEmpty) {
      query = query.where(
        'status',
        whereIn: filter.statuses!.map((s) => s.name).toList(),
      );
    }

    if (filter.types != null && filter.types!.isNotEmpty) {
      query = query.where(
        'type',
        whereIn: filter.types!.map((t) => t.name).toList(),
      );
    }

    if (filter.customerId != null) {
      query = query.where('customerId', isEqualTo: filter.customerId);
    }

    if (filter.isAllDay != null) {
      query = query.where('isAllDay', isEqualTo: filter.isAllDay);
    }

    query = query.orderBy('startTime', descending: false);

    return query.snapshots().map((snapshot) {
      var events = snapshot.docs.map(CalendarEvent.fromDocument).toList();

      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        events = events
            .where(
              (event) =>
                  event.title.toLowerCase().contains(query) ||
                  event.description.toLowerCase().contains(query) ||
                  event.location.toLowerCase().contains(query),
            )
            .toList();
      }

      return events;
    });
  }

  /// Обновить событие
  Future<bool> updateEvent(CalendarEvent event) async {
    try {
      await _firestore
          .collection('calendar_events')
          .doc(event.id)
          .update(event.toMap());
      return true;
    } on Exception catch (e) {
      print('Ошибка обновления события: $e');
      return false;
    }
  }

  /// Удалить событие
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('calendar_events').doc(eventId).delete();
      return true;
    } on Exception catch (e) {
      print('Ошибка удаления события: $e');
      return false;
    }
  }

  /// Экспортировать события в ICS файл
  Future<String?> exportToICS(List<CalendarEvent> events) async {
    try {
      // TODO(developer): Implement proper calendar export
      // Временная заглушка - возвращаем пустую строку
      return '';
      // final calendar = ical.ICalendar(
      //   headData: ical.ICalendarHeadData(
      //     prodId: 'Event Marketplace App',
      //     version: '2.0',
      //   ),
      // );

      // TODO(developer): Implement event export
      // Временная заглушка - возвращаем пустую строку
      return '';
      // for (final event in events) {
      //   final icsEvent = ical.IEventData(
      //     start: event.startTime,
      //     end: event.endTime,
      //     summary: event.title,
      //     description: event.description,
      //     location: event.location,
      //   );
      //   calendar.addEvent(icsEvent);
      // }

      // TODO(developer): Return proper ICS content
      return 'BEGIN:VCALENDAR\nVERSION:2.0\nEND:VCALENDAR';
    } on Exception catch (e) {
      print('Ошибка экспорта в ICS: $e');
      return null;
    }
  }

  /// Поделиться событиями
  Future<void> shareEvents(List<CalendarEvent> events) async {
    try {
      final icsContent = await exportToICS(events);
      if (icsContent != null) {
        // Создаем временный файл
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/events.ics');
        await file.writeAsString(icsContent);

        // Делимся файлом
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Календарные события',
        );
      }
    } on Exception catch (e) {
      print('Ошибка шаринга событий: $e');
    }
  }

  /// Открыть в Google Calendar
  Future<void> openInGoogleCalendar(CalendarEvent event) async {
    try {
      final startTime = '${event.startTime.toUtc().toIso8601String().replaceAll(':', '').split('.')[0]}Z';
      final endTime = '${event.endTime.toUtc().toIso8601String().replaceAll(':', '').split('.')[0]}Z';

      final url = Uri.parse(
          'https://calendar.google.com/calendar/render?action=TEMPLATE'
          '&text=${Uri.encodeComponent(event.title)}'
          '&dates=$startTime/$endTime'
          '&details=${Uri.encodeComponent(event.description)}'
          '&location=${Uri.encodeComponent(event.location)}');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } on Exception catch (e) {
      print('Ошибка открытия в Google Calendar: $e');
    }
  }

  /// Открыть в Outlook Calendar
  Future<void> openInOutlookCalendar(CalendarEvent event) async {
    try {
      final startTime = event.startTime.toUtc().toIso8601String();
      final endTime = event.endTime.toUtc().toIso8601String();

      final url =
          Uri.parse('https://outlook.live.com/calendar/0/deeplink/compose?'
              'subject=${Uri.encodeComponent(event.title)}'
              '&startdt=$startTime'
              '&enddt=$endTime'
              '&body=${Uri.encodeComponent(event.description)}'
              '&location=${Uri.encodeComponent(event.location)}');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } on Exception catch (e) {
      print('Ошибка открытия в Outlook Calendar: $e');
    }
  }

  /// Синхронизировать с Google Calendar
  Future<bool> syncWithGoogleCalendar(String userId, String accessToken) async {
    try {
      // TODO(developer): Реализовать синхронизацию с Google Calendar API
      print('Синхронизация с Google Calendar для пользователя: $userId');
      return true;
    } on Exception catch (e) {
      print('Ошибка синхронизации с Google Calendar: $e');
      return false;
    }
  }

  /// Синхронизировать с Outlook Calendar
  Future<bool> syncWithOutlookCalendar(
    String userId,
    String accessToken,
  ) async {
    try {
      // TODO(developer): Реализовать синхронизацию с Outlook Calendar API
      print('Синхронизация с Outlook Calendar для пользователя: $userId');
      return true;
    } on Exception catch (e) {
      print('Ошибка синхронизации с Outlook Calendar: $e');
      return false;
    }
  }

  /// Получить статистику календаря
  Future<CalendarStats> getCalendarStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('calendar_events')
          .where('customerId', isEqualTo: userId)
          .get();

      final events = snapshot.docs.map(CalendarEvent.fromDocument).toList();

      return _calculateStats(events);
    } on Exception catch (e) {
      print('Ошибка получения статистики календаря: $e');
      return CalendarStats.empty();
    }
  }

  /// Создать событие из бронирования
  Future<String?> createEventFromBooking({
    required String bookingId,
    required String specialistId,
    required String specialistName,
    required String customerId,
    required String customerName,
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
  }) async {
    try {
      final event = CalendarEvent(
        id: '',
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        location: location,
        specialistId: specialistId,
        specialistName: specialistName,
        customerId: customerId,
        customerName: customerName,
        bookingId: bookingId,
        status: EventStatus.scheduled,
        type: EventType.booking,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await createEvent(event);
    } on Exception catch (e) {
      print('Ошибка создания события из бронирования: $e');
      return null;
    }
  }

  /// Обновить статус события
  Future<bool> updateEventStatus(String eventId, EventStatus status) async {
    try {
      await _firestore.collection('calendar_events').doc(eventId).update({
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } on Exception catch (e) {
      print('Ошибка обновления статуса события: $e');
      return false;
    }
  }

  /// Получить события на сегодня
  Stream<List<CalendarEvent>> getTodayEvents(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final filter = CalendarFilter(
      startDate: startOfDay,
      endDate: endOfDay,
    );

    return getUserEvents(userId, filter);
  }

  /// Получить события на завтра
  Stream<List<CalendarEvent>> getTomorrowEvents(String userId) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final startOfDay = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final endOfDay =
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59);

    final filter = CalendarFilter(
      startDate: startOfDay,
      endDate: endOfDay,
    );

    return getUserEvents(userId, filter);
  }

  /// Получить события на неделю
  Stream<List<CalendarEvent>> getWeekEvents(String userId) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final filter = CalendarFilter(
      startDate: startOfWeek,
      endDate: endOfWeek,
    );

    return getUserEvents(userId, filter);
  }

  /// Получить события на месяц
  Stream<List<CalendarEvent>> getMonthEvents(String userId) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final filter = CalendarFilter(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );

    return getUserEvents(userId, filter);
  }

  String _getICSStatus(EventStatus status) {
    switch (status) {
      case EventStatus.scheduled:
        return 'TENTATIVE';
      case EventStatus.confirmed:
        return 'CONFIRMED';
      case EventStatus.cancelled:
        return 'CANCELLED';
      case EventStatus.completed:
        return 'CONFIRMED';
      case EventStatus.postponed:
        return 'TENTATIVE';
    }
  }

  CalendarStats _calculateStats(List<CalendarEvent> events) {
    final totalEvents = events.length;
    final completedEvents =
        events.where((e) => e.status == EventStatus.completed).length;
    final cancelledEvents =
        events.where((e) => e.status == EventStatus.cancelled).length;
    final upcomingEvents = events.where((e) => e.isFuture).length;

    double totalDuration = 0;
    final eventsByType = <EventType, int>{};
    final eventsByStatus = <EventStatus, int>{};
    final dayEventCounts = <DateTime, int>{};

    for (final event in events) {
      totalDuration += event.duration.inMinutes;

      eventsByType[event.type] = (eventsByType[event.type] ?? 0) + 1;
      eventsByStatus[event.status] = (eventsByStatus[event.status] ?? 0) + 1;

      final day = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      dayEventCounts[day] = (dayEventCounts[day] ?? 0) + 1;
    }

    final averageEventDuration =
        totalEvents > 0 ? totalDuration / totalEvents : 0.0;

    final sortedDays = dayEventCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final busiestDays = sortedDays.take(5).map((e) => e.key).toList();

    return CalendarStats(
      totalEvents: totalEvents,
      completedEvents: completedEvents,
      cancelledEvents: cancelledEvents,
      upcomingEvents: upcomingEvents,
      averageEventDuration: averageEventDuration,
      eventsByType: eventsByType,
      eventsByStatus: eventsByStatus,
      busiestDays: busiestDays,
    );
  }

  /// Проверить доступность даты
  Future<bool> isDateAvailable(String specialistId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('calendar_events')
          .where('specialistId', isEqualTo: specialistId)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      return querySnapshot.docs.isEmpty;
    } on Exception catch (e) {
      print('Ошибка проверки доступности даты: $e');
      return false;
    }
  }

  /// Проверить доступность даты и времени
  Future<bool> isDateTimeAvailable(
    String specialistId,
    DateTime dateTime,
  ) async {
    try {
      final startOfDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('calendar_events')
          .where('specialistId', isEqualTo: specialistId)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final events =
          querySnapshot.docs.map(CalendarEvent.fromDocument).toList();

      // Проверяем, есть ли конфликтующие события
      for (final event in events) {
        if (dateTime.isAfter(event.startTime) &&
            dateTime.isBefore(event.endTime)) {
          return false;
        }
      }
      return true;
    } on Exception catch (e) {
      print('Ошибка проверки доступности даты и времени: $e');
      return false;
    }
  }

  /// Получить доступные временные слоты
  Future<List<DateTime>> getAvailableTimeSlots(
    String specialistId,
    DateTime date,
    Duration slotDuration,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('calendar_events')
          .where('specialistId', isEqualTo: specialistId)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final events =
          querySnapshot.docs.map(CalendarEvent.fromDocument).toList();

      final availableSlots = <DateTime>[];

      // Генерируем слоты с 9:00 до 18:00
      const startHour = 9;
      const endHour = 18;

      for (var hour = startHour; hour < endHour; hour++) {
        for (var minute = 0; minute < 60; minute += slotDuration.inMinutes) {
          final slotTime =
              DateTime(date.year, date.month, date.day, hour, minute);

          // Проверяем, не конфликтует ли слот с существующими событиями
          var isAvailable = true;
          for (final event in events) {
            if (slotTime.isAfter(event.startTime) &&
                slotTime.isBefore(event.endTime)) {
              isAvailable = false;
              break;
            }
          }

          if (isAvailable) {
            availableSlots.add(slotTime);
          }
        }
      }

      return availableSlots;
    } on Exception catch (e) {
      print('Ошибка получения доступных слотов: $e');
      return [];
    }
  }

  /// Получить доступные даты
  Future<List<DateTime>> getAvailableDates(
    String specialistId,
    int daysAhead,
  ) async {
    try {
      final availableDates = <DateTime>[];
      final today = DateTime.now();

      for (var i = 0; i < daysAhead; i++) {
        final date = today.add(Duration(days: i));
        final isAvailable = await isDateAvailable(specialistId, date);
        if (isAvailable) {
          availableDates.add(date);
        }
      }

      return availableDates;
    } on Exception catch (e) {
      print('Ошибка получения доступных дат: $e');
      return [];
    }
  }

  /// Добавить событие
  Future<void> addEvent(String specialistId, CalendarEvent event) async {
    await createEvent(event);
  }

  /// Удалить событие
  Future<void> removeEvent(String specialistId, String eventId) async {
    await deleteEvent(eventId);
  }

  /// Получить события на дату
  Future<List<CalendarEvent>> getEventsForDate(
    String specialistId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final events = await _firestore
          .collection('calendar_events')
          .where('specialistId', isEqualTo: specialistId)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      return events.docs.map(CalendarEvent.fromDocument).toList();
    } on Exception catch (e) {
      print('Ошибка получения событий на дату: $e');
      return [];
    }
  }

  /// Создать событие бронирования
  Future<String?> createBookingEvent(CalendarEvent event) async =>
      createEvent(event);

  /// Удалить событие бронирования
  Future<void> removeBookingEvent(String eventId) async {
    await deleteEvent(eventId);
  }

  /// Получить расписание специалиста
  Stream<SpecialistSchedule?> getSpecialistSchedule(String specialistId) =>
      _firestore
          .collection('specialist_schedules')
          .doc(specialistId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return null;
        return SpecialistSchedule.fromMap(doc.data()!);
      });

  /// Получить все расписания
  Stream<List<SpecialistSchedule>> getAllSchedules() =>
      _firestore.collection('specialist_schedules').snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => SpecialistSchedule.fromMap(doc.data()))
                .toList(),
          );

  /// Создать событие недоступности
  Future<String?> createUnavailableEvent({
    required String specialistId,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    try {
      final eventRef = _firestore.collection('unavailable_events').doc();
      final eventData = {
        'id': eventRef.id,
        'specialistId': specialistId,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'reason': reason ?? 'Недоступен',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await eventRef.set(eventData);
      return eventRef.id;
    } on Exception catch (e) {
      print('Ошибка создания события недоступности: $e');
      return null;
    }
  }

  /// Создать событие отпуска
  Future<String?> createVacationEvent({
    required String specialistId,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    try {
      final eventRef = _firestore.collection('vacation_events').doc();
      final eventData = {
        'id': eventRef.id,
        'specialistId': specialistId,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'reason': reason ?? 'Отпуск',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await eventRef.set(eventData);
      return eventRef.id;
    } on Exception catch (e) {
      print('Ошибка создания события отпуска: $e');
      return null;
    }
  }

  /// Добавить тестовые данные
  Future<void> addTestData(String specialistId) async {
    try {
      // Добавляем тестовые события
      final now = DateTime.now();
      final testEvents = [
        {
          'specialistId': specialistId,
          'title': 'Тестовое событие 1',
          'startDate': Timestamp.fromDate(now.add(const Duration(days: 1))),
          'endDate':
              Timestamp.fromDate(now.add(const Duration(days: 1, hours: 2))),
          'type': 'booking',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'specialistId': specialistId,
          'title': 'Тестовое событие 2',
          'startDate': Timestamp.fromDate(now.add(const Duration(days: 2))),
          'endDate':
              Timestamp.fromDate(now.add(const Duration(days: 2, hours: 1))),
          'type': 'unavailable',
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      for (final eventData in testEvents) {
        await _firestore.collection('calendar_events').add(eventData);
      }
    } on Exception catch (e) {
      print('Ошибка добавления тестовых данных: $e');
    }
  }

  /// Пометить дату как занятую
  Future<bool> markDateBusy(String specialistId, DateTime date) async {
    try {
      final specialistRef =
          _firestore.collection('specialists').doc(specialistId);
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Получаем текущие занятые даты
      final doc = await specialistRef.get();
      if (!doc.exists) {
        throw Exception('Специалист не найден');
      }

      final data = doc.data()!;
      final busyDates = (data['busyDates'] as List<dynamic>?)
              ?.map((e) => (e as Timestamp).toDate())
              .toList() ??
          [];

      // Проверяем, не занята ли уже эта дата
      final isAlreadyBusy = busyDates.any(
        (busyDate) =>
            busyDate.year == normalizedDate.year &&
            busyDate.month == normalizedDate.month &&
            busyDate.day == normalizedDate.day,
      );

      if (!isAlreadyBusy) {
        busyDates.add(normalizedDate);
        await specialistRef.update({
          'busyDates': busyDates.map(Timestamp.fromDate).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } on Exception catch (e) {
      print('Ошибка пометки даты как занятой: $e');
      return false;
    }
  }

  /// Пометить дату как свободную
  Future<bool> markDateFree(String specialistId, DateTime date) async {
    try {
      final specialistRef =
          _firestore.collection('specialists').doc(specialistId);
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Получаем текущие занятые даты
      final doc = await specialistRef.get();
      if (!doc.exists) {
        throw Exception('Специалист не найден');
      }

      final data = doc.data()!;
      final busyDates = (data['busyDates'] as List<dynamic>?)
              ?.map((e) => (e as Timestamp).toDate())
              .toList() ??
          [];

      // Удаляем дату из списка занятых
      busyDates.removeWhere(
        (busyDate) =>
            busyDate.year == normalizedDate.year &&
            busyDate.month == normalizedDate.month &&
            busyDate.day == normalizedDate.day,
      );

      await specialistRef.update({
        'busyDates': busyDates.map(Timestamp.fromDate).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } on Exception catch (e) {
      print('Ошибка пометки даты как свободной: $e');
      return false;
    }
  }

  /// Получить занятые даты специалиста
  Future<List<DateTime>> getBusyDates(String specialistId) async {
    try {
      final doc =
          await _firestore.collection('specialists').doc(specialistId).get();
      if (!doc.exists) {
        return [];
      }

      final data = doc.data()!;
      final busyDates = (data['busyDates'] as List<dynamic>?)
              ?.map((e) => (e as Timestamp).toDate())
              .toList() ??
          [];

      return busyDates;
    } on Exception catch (e) {
      print('Ошибка получения занятых дат: $e');
      return [];
    }
  }

  /// Получить свободные даты специалиста в диапазоне
  Future<List<DateTime>> getAvailableDatesInRange(
    String specialistId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final busyDates = await getBusyDates(specialistId);
      final availableDates = <DateTime>[];

      var current = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        final isBusy = busyDates.any(
          (busyDate) =>
              busyDate.year == current.year &&
              busyDate.month == current.month &&
              busyDate.day == current.day,
        );

        if (!isBusy) {
          availableDates
              .add(DateTime(current.year, current.month, current.day));
        }

        current = current.add(const Duration(days: 1));
      }

      return availableDates;
    } on Exception catch (e) {
      print('Ошибка получения свободных дат: $e');
      return [];
    }
  }

  /// Синхронизировать занятые даты с бронированиями
  Future<void> syncBusyDatesWithBookings(String specialistId) async {
    try {
      // Получаем все подтвержденные бронирования специалиста
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: 'confirmed')
          .get();

      final busyDates = <DateTime>[];

      for (final doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final eventDate = (data['eventDate'] as Timestamp).toDate();
        final normalizedDate =
            DateTime(eventDate.year, eventDate.month, eventDate.day);

        if (!busyDates.any(
          (date) =>
              date.year == normalizedDate.year &&
              date.month == normalizedDate.month &&
              date.day == normalizedDate.day,
        )) {
          busyDates.add(normalizedDate);
        }
      }

      // Обновляем занятые даты в профиле специалиста
      await _firestore.collection('specialists').doc(specialistId).update({
        'busyDates': busyDates.map(Timestamp.fromDate).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      print('Ошибка синхронизации занятых дат: $e');
    }
  }
}
