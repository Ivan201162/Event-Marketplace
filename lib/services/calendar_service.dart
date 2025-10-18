import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

import '../core/stubs/stubs.dart';
import 'package:flutter/foundation.dart';
import '../models/calendar_event.dart';
import 'package:flutter/foundation.dart';
import '../models/specialist_schedule.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ РґР»СЏ СЂР°Р±РѕС‚С‹ СЃ РєР°Р»РµРЅРґР°СЂРµРј
class CalendarService {
  factory CalendarService() => _instance;
  CalendarService._internal();
  static final CalendarService _instance = CalendarService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// РЎРѕР·РґР°С‚СЊ РєР°Р»РµРЅРґР°СЂРЅРѕРµ СЃРѕР±С‹С‚РёРµ
  Future<String?> createEvent(CalendarEvent event) async {
    try {
      final eventRef = _firestore.collection('calendar_events').doc();
      final eventWithId = event.copyWith(id: eventRef.id);

      await eventRef.set(eventWithId.toMap());
      return eventRef.id;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ СЃРѕР±С‹С‚РёСЏ: $e');
      return null;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРѕР±С‹С‚РёСЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Stream<List<CalendarEvent>> getUserEvents(
    String userId,
    CalendarFilter filter,
  ) {
    Query<Map<String, dynamic>> query = _firestore.collection('calendar_events');

    // Р¤РёР»СЊС‚СЂ РїРѕ РїРѕР»СЊР·РѕРІР°С‚РµР»СЋ
    query = query.where('customerId', isEqualTo: userId);

    // РџСЂРёРјРµРЅСЏРµРј С„РёР»СЊС‚СЂС‹
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

    // РЎРѕСЂС‚РёСЂРѕРІРєР° РїРѕ РІСЂРµРјРµРЅРё РЅР°С‡Р°Р»Р°
    query = query.orderBy('startTime', descending: false);

    // Р”РѕР±Р°РІР»СЏРµРј Р»РёРјРёС‚ РґР»СЏ РѕРїС‚РёРјРёР·Р°С†РёРё
    query = query.limit(50);

    return query.snapshots().map((snapshot) {
      var events = snapshot.docs.map(CalendarEvent.fromDocument).toList();

      // РџСЂРёРјРµРЅСЏРµРј С„РёР»СЊС‚СЂС‹, РєРѕС‚РѕСЂС‹Рµ РЅРµР»СЊР·СЏ РїСЂРёРјРµРЅРёС‚СЊ РІ Firestore
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

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРѕР±С‹С‚РёСЏ СЃРїРµС†РёР°Р»РёСЃС‚Р°
  Stream<List<CalendarEvent>> getSpecialistEvents(
    String specialistId,
    CalendarFilter filter,
  ) {
    Query<Map<String, dynamic>> query = _firestore.collection('calendar_events');

    // Р¤РёР»СЊС‚СЂ РїРѕ СЃРїРµС†РёР°Р»РёСЃС‚Сѓ
    query = query.where('specialistId', isEqualTo: specialistId);

    // РџСЂРёРјРµРЅСЏРµРј РѕСЃС‚Р°Р»СЊРЅС‹Рµ С„РёР»СЊС‚СЂС‹ Р°РЅР°Р»РѕРіРёС‡РЅРѕ getUserEvents
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

  /// РћР±РЅРѕРІРёС‚СЊ СЃРѕР±С‹С‚РёРµ
  Future<bool> updateEvent(CalendarEvent event) async {
    try {
      await _firestore.collection('calendar_events').doc(event.id).update(event.toMap());
      return true;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ СЃРѕР±С‹С‚РёСЏ: $e');
      return false;
    }
  }

  /// РЈРґР°Р»РёС‚СЊ СЃРѕР±С‹С‚РёРµ
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('calendar_events').doc(eventId).delete();
      return true;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ СЃРѕР±С‹С‚РёСЏ: $e');
      return false;
    }
  }

  /// Р­РєСЃРїРѕСЂС‚РёСЂРѕРІР°С‚СЊ СЃРѕР±С‹С‚РёСЏ РІ ICS С„Р°Р№Р»
  Future<String?> exportToICS(List<CalendarEvent> events) async {
    try {
      // TODO(developer): Implement proper calendar export
      // Р’СЂРµРјРµРЅРЅР°СЏ Р·Р°РіР»СѓС€РєР° - РІРѕР·РІСЂР°С‰Р°РµРј РїСѓСЃС‚СѓСЋ СЃС‚СЂРѕРєСѓ
      return '';
      // final calendar = ical.ICalendar(
      //   headData: ical.ICalendarHeadData(
      //     prodId: 'Event Marketplace App',
      //     version: '2.0',
      //   ),
      // );

      // TODO(developer): Implement event export
      // Р’СЂРµРјРµРЅРЅР°СЏ Р·Р°РіР»СѓС€РєР° - РІРѕР·РІСЂР°С‰Р°РµРј РїСѓСЃС‚СѓСЋ СЃС‚СЂРѕРєСѓ
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
      debugPrint('РћС€РёР±РєР° СЌРєСЃРїРѕСЂС‚Р° РІ ICS: $e');
      return null;
    }
  }

  /// РџРѕРґРµР»РёС‚СЊСЃСЏ СЃРѕР±С‹С‚РёСЏРјРё
  Future<void> shareEvents(List<CalendarEvent> events) async {
    try {
      final icsContent = await exportToICS(events);
      if (icsContent != null) {
        // РЎРѕР·РґР°РµРј РІСЂРµРјРµРЅРЅС‹Р№ С„Р°Р№Р»
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/events.ics');
        await file.writeAsString(icsContent);

        // Р”РµР»РёРјСЃСЏ С„Р°Р№Р»РѕРј
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'РљР°Р»РµРЅРґР°СЂРЅС‹Рµ СЃРѕР±С‹С‚РёСЏ',
        );
      }
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° С€Р°СЂРёРЅРіР° СЃРѕР±С‹С‚РёР№: $e');
    }
  }

  /// РћС‚РєСЂС‹С‚СЊ РІ Google Calendar
  Future<void> openInGoogleCalendar(CalendarEvent event) async {
    try {
      final startTime =
          '${event.startTime.toUtc().toIso8601String().replaceAll(':', '').split('.')[0]}Z';
      final endTime =
          '${event.endTime.toUtc().toIso8601String().replaceAll(':', '').split('.')[0]}Z';

      final url = Uri.parse('https://calendar.google.com/calendar/render?action=TEMPLATE'
          '&text=${Uri.encodeComponent(event.title)}'
          '&dates=$startTime/$endTime'
          '&details=${Uri.encodeComponent(event.description)}'
          '&location=${Uri.encodeComponent(event.location)}');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‚РєСЂС‹С‚РёСЏ РІ Google Calendar: $e');
    }
  }

  /// РћС‚РєСЂС‹С‚СЊ РІ Outlook Calendar
  Future<void> openInOutlookCalendar(CalendarEvent event) async {
    try {
      final startTime = event.startTime.toUtc().toIso8601String();
      final endTime = event.endTime.toUtc().toIso8601String();

      final url = Uri.parse('https://outlook.live.com/calendar/0/deeplink/compose?'
          'subject=${Uri.encodeComponent(event.title)}'
          '&startdt=$startTime'
          '&enddt=$endTime'
          '&body=${Uri.encodeComponent(event.description)}'
          '&location=${Uri.encodeComponent(event.location)}');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‚РєСЂС‹С‚РёСЏ РІ Outlook Calendar: $e');
    }
  }

  /// РЎРёРЅС…СЂРѕРЅРёР·РёСЂРѕРІР°С‚СЊ СЃ Google Calendar
  Future<bool> syncWithGoogleCalendar(String userId, String accessToken) async {
    try {
      // TODO(developer): Р РµР°Р»РёР·РѕРІР°С‚СЊ СЃРёРЅС…СЂРѕРЅРёР·Р°С†РёСЋ СЃ Google Calendar API
      debugPrint('РЎРёРЅС…СЂРѕРЅРёР·Р°С†РёСЏ СЃ Google Calendar РґР»СЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ: $userId');
      return true;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРёРЅС…СЂРѕРЅРёР·Р°С†РёРё СЃ Google Calendar: $e');
      return false;
    }
  }

  /// РЎРёРЅС…СЂРѕРЅРёР·РёСЂРѕРІР°С‚СЊ СЃ Outlook Calendar
  Future<bool> syncWithOutlookCalendar(
    String userId,
    String accessToken,
  ) async {
    try {
      // TODO(developer): Р РµР°Р»РёР·РѕРІР°С‚СЊ СЃРёРЅС…СЂРѕРЅРёР·Р°С†РёСЋ СЃ Outlook Calendar API
      debugPrint('РЎРёРЅС…СЂРѕРЅРёР·Р°С†РёСЏ СЃ Outlook Calendar РґР»СЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ: $userId');
      return true;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРёРЅС…СЂРѕРЅРёР·Р°С†РёРё СЃ Outlook Calendar: $e');
      return false;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃС‚Р°С‚РёСЃС‚РёРєСѓ РєР°Р»РµРЅРґР°СЂСЏ
  Future<CalendarStats> getCalendarStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('calendar_events')
          .where('customerId', isEqualTo: userId)
          .get();

      final events = snapshot.docs.map(CalendarEvent.fromDocument).toList();

      return _calculateStats(events);
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃС‚Р°С‚РёСЃС‚РёРєРё РєР°Р»РµРЅРґР°СЂСЏ: $e');
      return CalendarStats.empty();
    }
  }

  /// РЎРѕР·РґР°С‚СЊ СЃРѕР±С‹С‚РёРµ РёР· Р±СЂРѕРЅРёСЂРѕРІР°РЅРёСЏ
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
      debugPrint('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ СЃРѕР±С‹С‚РёСЏ РёР· Р±СЂРѕРЅРёСЂРѕРІР°РЅРёСЏ: $e');
      return null;
    }
  }

  /// РћР±РЅРѕРІРёС‚СЊ СЃС‚Р°С‚СѓСЃ СЃРѕР±С‹С‚РёСЏ
  Future<bool> updateEventStatus(String eventId, EventStatus status) async {
    try {
      await _firestore.collection('calendar_events').doc(eventId).update({
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ СЃС‚Р°С‚СѓСЃР° СЃРѕР±С‹С‚РёСЏ: $e');
      return false;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРѕР±С‹С‚РёСЏ РЅР° СЃРµРіРѕРґРЅСЏ
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

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРѕР±С‹С‚РёСЏ РЅР° Р·Р°РІС‚СЂР°
  Stream<List<CalendarEvent>> getTomorrowEvents(String userId) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final startOfDay = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final endOfDay = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59);

    final filter = CalendarFilter(
      startDate: startOfDay,
      endDate: endOfDay,
    );

    return getUserEvents(userId, filter);
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРѕР±С‹С‚РёСЏ РЅР° РЅРµРґРµР»СЋ
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

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРѕР±С‹С‚РёСЏ РЅР° РјРµСЃСЏС†
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
    final completedEvents = events.where((e) => e.status == EventStatus.completed).length;
    final cancelledEvents = events.where((e) => e.status == EventStatus.cancelled).length;
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

    final averageEventDuration = totalEvents > 0 ? totalDuration / totalEvents : 0.0;

    final sortedDays = dayEventCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
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

  /// РџСЂРѕРІРµСЂРёС‚СЊ РґРѕСЃС‚СѓРїРЅРѕСЃС‚СЊ РґР°С‚С‹
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
      debugPrint('РћС€РёР±РєР° РїСЂРѕРІРµСЂРєРё РґРѕСЃС‚СѓРїРЅРѕСЃС‚Рё РґР°С‚С‹: $e');
      return false;
    }
  }

  /// РџСЂРѕРІРµСЂРёС‚СЊ РґРѕСЃС‚СѓРїРЅРѕСЃС‚СЊ РґР°С‚С‹ Рё РІСЂРµРјРµРЅРё
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

      final events = querySnapshot.docs.map(CalendarEvent.fromDocument).toList();

      // РџСЂРѕРІРµСЂСЏРµРј, РµСЃС‚СЊ Р»Рё РєРѕРЅС„Р»РёРєС‚СѓСЋС‰РёРµ СЃРѕР±С‹С‚РёСЏ
      for (final event in events) {
        if (dateTime.isAfter(event.startTime) && dateTime.isBefore(event.endTime)) {
          return false;
        }
      }
      return true;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїСЂРѕРІРµСЂРєРё РґРѕСЃС‚СѓРїРЅРѕСЃС‚Рё РґР°С‚С‹ Рё РІСЂРµРјРµРЅРё: $e');
      return false;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РґРѕСЃС‚СѓРїРЅС‹Рµ РІСЂРµРјРµРЅРЅС‹Рµ СЃР»РѕС‚С‹
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

      final events = querySnapshot.docs.map(CalendarEvent.fromDocument).toList();

      final availableSlots = <DateTime>[];

      // Р“РµРЅРµСЂРёСЂСѓРµРј СЃР»РѕС‚С‹ СЃ 9:00 РґРѕ 18:00
      const startHour = 9;
      const endHour = 18;

      for (var hour = startHour; hour < endHour; hour++) {
        for (var minute = 0; minute < 60; minute += slotDuration.inMinutes) {
          final slotTime = DateTime(date.year, date.month, date.day, hour, minute);

          // РџСЂРѕРІРµСЂСЏРµРј, РЅРµ РєРѕРЅС„Р»РёРєС‚СѓРµС‚ Р»Рё СЃР»РѕС‚ СЃ СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёРјРё СЃРѕР±С‹С‚РёСЏРјРё
          var isAvailable = true;
          for (final event in events) {
            if (slotTime.isAfter(event.startTime) && slotTime.isBefore(event.endTime)) {
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
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РґРѕСЃС‚СѓРїРЅС‹С… СЃР»РѕС‚РѕРІ: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РґРѕСЃС‚СѓРїРЅС‹Рµ РґР°С‚С‹
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
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РґРѕСЃС‚СѓРїРЅС‹С… РґР°С‚: $e');
      return [];
    }
  }

  /// Р”РѕР±Р°РІРёС‚СЊ СЃРѕР±С‹С‚РёРµ
  Future<void> addEvent(String specialistId, CalendarEvent event) async {
    await createEvent(event);
  }

  /// РЈРґР°Р»РёС‚СЊ СЃРѕР±С‹С‚РёРµ
  Future<void> removeEvent(String specialistId, String eventId) async {
    await deleteEvent(eventId);
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРѕР±С‹С‚РёСЏ РЅР° РґР°С‚Сѓ
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
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃРѕР±С‹С‚РёР№ РЅР° РґР°С‚Сѓ: $e');
      return [];
    }
  }

  /// РЎРѕР·РґР°С‚СЊ СЃРѕР±С‹С‚РёРµ Р±СЂРѕРЅРёСЂРѕРІР°РЅРёСЏ
  Future<String?> createBookingEvent(CalendarEvent event) async => createEvent(event);

  /// РЈРґР°Р»РёС‚СЊ СЃРѕР±С‹С‚РёРµ Р±СЂРѕРЅРёСЂРѕРІР°РЅРёСЏ
  Future<void> removeBookingEvent(String eventId) async {
    await deleteEvent(eventId);
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЂР°СЃРїРёСЃР°РЅРёРµ СЃРїРµС†РёР°Р»РёСЃС‚Р°
  Stream<SpecialistSchedule?> getSpecialistSchedule(String specialistId) =>
      _firestore.collection('specialist_schedules').doc(specialistId).snapshots().map((doc) {
        if (!doc.exists) return null;
        return SpecialistSchedule.fromMap(doc.data()!);
      });

  /// РџРѕР»СѓС‡РёС‚СЊ РІСЃРµ СЂР°СЃРїРёСЃР°РЅРёСЏ
  Stream<List<SpecialistSchedule>> getAllSchedules() =>
      _firestore.collection('specialist_schedules').snapshots().map(
            (snapshot) =>
                snapshot.docs.map((doc) => SpecialistSchedule.fromMap(doc.data())).toList(),
          );

  /// РЎРѕР·РґР°С‚СЊ СЃРѕР±С‹С‚РёРµ РЅРµРґРѕСЃС‚СѓРїРЅРѕСЃС‚Рё
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
        'reason': reason ?? 'РќРµРґРѕСЃС‚СѓРїРµРЅ',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await eventRef.set(eventData);
      return eventRef.id;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ СЃРѕР±С‹С‚РёСЏ РЅРµРґРѕСЃС‚СѓРїРЅРѕСЃС‚Рё: $e');
      return null;
    }
  }

  /// РЎРѕР·РґР°С‚СЊ СЃРѕР±С‹С‚РёРµ РѕС‚РїСѓСЃРєР°
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
        'reason': reason ?? 'РћС‚РїСѓСЃРє',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await eventRef.set(eventData);
      return eventRef.id;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ СЃРѕР±С‹С‚РёСЏ РѕС‚РїСѓСЃРєР°: $e');
      return null;
    }
  }

  /// Р”РѕР±Р°РІРёС‚СЊ С‚РµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ
  Future<void> addTestData(String specialistId) async {
    try {
      // Р”РѕР±Р°РІР»СЏРµРј С‚РµСЃС‚РѕРІС‹Рµ СЃРѕР±С‹С‚РёСЏ
      final now = DateTime.now();
      final testEvents = [
        {
          'specialistId': specialistId,
          'title': 'РўРµСЃС‚РѕРІРѕРµ СЃРѕР±С‹С‚РёРµ 1',
          'startDate': Timestamp.fromDate(now.add(const Duration(days: 1))),
          'endDate': Timestamp.fromDate(now.add(const Duration(days: 1, hours: 2))),
          'type': 'booking',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'specialistId': specialistId,
          'title': 'РўРµСЃС‚РѕРІРѕРµ СЃРѕР±С‹С‚РёРµ 2',
          'startDate': Timestamp.fromDate(now.add(const Duration(days: 2))),
          'endDate': Timestamp.fromDate(now.add(const Duration(days: 2, hours: 1))),
          'type': 'unavailable',
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      for (final eventData in testEvents) {
        await _firestore.collection('calendar_events').add(eventData);
      }
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ С‚РµСЃС‚РѕРІС‹С… РґР°РЅРЅС‹С…: $e');
    }
  }

  /// РџРѕРјРµС‚РёС‚СЊ РґР°С‚Сѓ РєР°Рє Р·Р°РЅСЏС‚СѓСЋ
  Future<bool> markDateBusy(String specialistId, DateTime date) async {
    try {
      final specialistRef = _firestore.collection('specialists').doc(specialistId);
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // РџРѕР»СѓС‡Р°РµРј С‚РµРєСѓС‰РёРµ Р·Р°РЅСЏС‚С‹Рµ РґР°С‚С‹
      final doc = await specialistRef.get();
      if (!doc.exists) {
        throw Exception('РЎРїРµС†РёР°Р»РёСЃС‚ РЅРµ РЅР°Р№РґРµРЅ');
      }

      final data = doc.data()!;
      final busyDates =
          (data['busyDates'] as List<dynamic>?)?.map((e) => (e as Timestamp).toDate()).toList() ??
              [];

      // РџСЂРѕРІРµСЂСЏРµРј, РЅРµ Р·Р°РЅСЏС‚Р° Р»Рё СѓР¶Рµ СЌС‚Р° РґР°С‚Р°
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
      debugPrint('РћС€РёР±РєР° РїРѕРјРµС‚РєРё РґР°С‚С‹ РєР°Рє Р·Р°РЅСЏС‚РѕР№: $e');
      return false;
    }
  }

  /// РџРѕРјРµС‚РёС‚СЊ РґР°С‚Сѓ РєР°Рє СЃРІРѕР±РѕРґРЅСѓСЋ
  Future<bool> markDateFree(String specialistId, DateTime date) async {
    try {
      final specialistRef = _firestore.collection('specialists').doc(specialistId);
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // РџРѕР»СѓС‡Р°РµРј С‚РµРєСѓС‰РёРµ Р·Р°РЅСЏС‚С‹Рµ РґР°С‚С‹
      final doc = await specialistRef.get();
      if (!doc.exists) {
        throw Exception('РЎРїРµС†РёР°Р»РёСЃС‚ РЅРµ РЅР°Р№РґРµРЅ');
      }

      final data = doc.data()!;
      final busyDates =
          (data['busyDates'] as List<dynamic>?)?.map((e) => (e as Timestamp).toDate()).toList() ??
              [];

      // РЈРґР°Р»СЏРµРј РґР°С‚Сѓ РёР· СЃРїРёСЃРєР° Р·Р°РЅСЏС‚С‹С…
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
      debugPrint('РћС€РёР±РєР° РїРѕРјРµС‚РєРё РґР°С‚С‹ РєР°Рє СЃРІРѕР±РѕРґРЅРѕР№: $e');
      return false;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ Р·Р°РЅСЏС‚С‹Рµ РґР°С‚С‹ СЃРїРµС†РёР°Р»РёСЃС‚Р°
  Future<List<DateTime>> getBusyDates(String specialistId) async {
    try {
      final doc = await _firestore.collection('specialists').doc(specialistId).get();
      if (!doc.exists) {
        return [];
      }

      final data = doc.data()!;
      final busyDates =
          (data['busyDates'] as List<dynamic>?)?.map((e) => (e as Timestamp).toDate()).toList() ??
              [];

      return busyDates;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ Р·Р°РЅСЏС‚С‹С… РґР°С‚: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРІРѕР±РѕРґРЅС‹Рµ РґР°С‚С‹ СЃРїРµС†РёР°Р»РёСЃС‚Р° РІ РґРёР°РїР°Р·РѕРЅРµ
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
          availableDates.add(DateTime(current.year, current.month, current.day));
        }

        current = current.add(const Duration(days: 1));
      }

      return availableDates;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃРІРѕР±РѕРґРЅС‹С… РґР°С‚: $e');
      return [];
    }
  }

  /// РЎРёРЅС…СЂРѕРЅРёР·РёСЂРѕРІР°С‚СЊ Р·Р°РЅСЏС‚С‹Рµ РґР°С‚С‹ СЃ Р±СЂРѕРЅРёСЂРѕРІР°РЅРёСЏРјРё
  Future<void> syncBusyDatesWithBookings(String specialistId) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј РІСЃРµ РїРѕРґС‚РІРµСЂР¶РґРµРЅРЅС‹Рµ Р±СЂРѕРЅРёСЂРѕРІР°РЅРёСЏ СЃРїРµС†РёР°Р»РёСЃС‚Р°
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: 'confirmed')
          .get();

      final busyDates = <DateTime>[];

      for (final doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final eventDate = (data['eventDate'] as Timestamp).toDate();
        final normalizedDate = DateTime(eventDate.year, eventDate.month, eventDate.day);

        if (!busyDates.any(
          (date) =>
              date.year == normalizedDate.year &&
              date.month == normalizedDate.month &&
              date.day == normalizedDate.day,
        )) {
          busyDates.add(normalizedDate);
        }
      }

      // РћР±РЅРѕРІР»СЏРµРј Р·Р°РЅСЏС‚С‹Рµ РґР°С‚С‹ РІ РїСЂРѕС„РёР»Рµ СЃРїРµС†РёР°Р»РёСЃС‚Р°
      await _firestore.collection('specialists').doc(specialistId).update({
        'busyDates': busyDates.map(Timestamp.fromDate).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРёРЅС…СЂРѕРЅРёР·Р°С†РёРё Р·Р°РЅСЏС‚С‹С… РґР°С‚: $e');
    }
  }
}

