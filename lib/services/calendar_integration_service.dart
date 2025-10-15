import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'error_logging_service.dart';

/// Сервис для интеграции с календарями Google/Apple
class CalendarIntegrationService {
  factory CalendarIntegrationService() => _instance;
  CalendarIntegrationService._internal();
  static final CalendarIntegrationService _instance =
      CalendarIntegrationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ErrorLoggingService _errorLogger = ErrorLoggingService();

  /// Создать событие в календаре
  Future<bool> createCalendarEvent({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    List<String>? attendees,
    String? userId,
    String? orderId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final eventId = _firestore.collection('calendar_events').doc().id;
      final now = DateTime.now();

      final event = {
        'id': eventId,
        'title': title,
        'description': description,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'location': location,
        'attendees': attendees ?? [],
        'userId': userId,
        'orderId': orderId,
        'metadata': metadata ?? {},
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'isSynced': false,
        'syncStatus': 'pending',
        'externalEventId': null,
        'platform': defaultTargetPlatform.name,
      };

      await _firestore.collection('calendar_events').doc(eventId).set(event);

      // Попытка синхронизации с внешним календарем
      await _syncWithExternalCalendar(eventId, event);

      await _errorLogger.logInfo(
        message: 'Calendar event created',
        userId: userId,
        action: 'create_calendar_event',
        additionalData: {
          'eventId': eventId,
          'orderId': orderId,
          'title': title,
        },
      );

      return true;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to create calendar event: $e',
        stackTrace: stackTrace.toString(),
        userId: userId,
        action: 'create_calendar_event',
        additionalData: {
          'orderId': orderId,
          'title': title,
        },
      );
      return false;
    }
  }

  /// Обновить событие в календаре
  Future<bool> updateCalendarEvent(
    String eventId, {
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    List<String>? attendees,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'isSynced': false,
        'syncStatus': 'pending',
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (startTime != null) {
        updates['startTime'] = Timestamp.fromDate(startTime);
      }
      if (endTime != null) updates['endTime'] = Timestamp.fromDate(endTime);
      if (location != null) updates['location'] = location;
      if (attendees != null) updates['attendees'] = attendees;
      if (metadata != null) updates['metadata'] = metadata;

      await _firestore
          .collection('calendar_events')
          .doc(eventId)
          .update(updates);

      // Попытка синхронизации с внешним календарем
      final eventDoc =
          await _firestore.collection('calendar_events').doc(eventId).get();

      if (eventDoc.exists) {
        await _syncWithExternalCalendar(eventId, eventDoc.data()!);
      }

      await _errorLogger.logInfo(
        message: 'Calendar event updated',
        action: 'update_calendar_event',
        additionalData: {'eventId': eventId},
      );

      return true;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to update calendar event: $e',
        stackTrace: stackTrace.toString(),
        action: 'update_calendar_event',
        additionalData: {'eventId': eventId},
      );
      return false;
    }
  }

  /// Удалить событие из календаря
  Future<bool> deleteCalendarEvent(String eventId) async {
    try {
      // Получаем событие для получения externalEventId
      final eventDoc =
          await _firestore.collection('calendar_events').doc(eventId).get();

      if (eventDoc.exists) {
        final eventData = eventDoc.data()!;
        final externalEventId = eventData['externalEventId'] as String?;

        // Удаляем из внешнего календаря, если есть
        if (externalEventId != null) {
          await _deleteFromExternalCalendar(externalEventId);
        }

        // Удаляем из нашей базы
        await _firestore.collection('calendar_events').doc(eventId).delete();

        await _errorLogger.logInfo(
          message: 'Calendar event deleted',
          action: 'delete_calendar_event',
          additionalData: {'eventId': eventId},
        );

        return true;
      }

      return false;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to delete calendar event: $e',
        stackTrace: stackTrace.toString(),
        action: 'delete_calendar_event',
        additionalData: {'eventId': eventId},
      );
      return false;
    }
  }

  /// Получить события календаря пользователя
  Future<List<Map<String, dynamic>>> getUserCalendarEvents(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('calendar_events')
          .where('userId', isEqualTo: userId);

      if (startDate != null) {
        query = query.where(
          'startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          'endTime',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      query = query.orderBy('startTime').limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data()! as Map<String, dynamic>)
          .toList();
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get user calendar events: $e',
        stackTrace: stackTrace.toString(),
        userId: userId,
        action: 'get_user_calendar_events',
      );
      return [];
    }
  }

  /// Получить события по заказу
  Future<List<Map<String, dynamic>>> getOrderCalendarEvents(
    String orderId,
  ) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('calendar_events')
          .where('orderId', isEqualTo: orderId)
          .orderBy('startTime')
          .get();

      return snapshot.docs
          .map((doc) => doc.data()! as Map<String, dynamic>)
          .toList();
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get order calendar events: $e',
        stackTrace: stackTrace.toString(),
        action: 'get_order_calendar_events',
        additionalData: {'orderId': orderId},
      );
      return [];
    }
  }

  /// Синхронизировать с внешним календарем
  Future<void> _syncWithExternalCalendar(
    String eventId,
    Map<String, dynamic> event,
  ) async {
    try {
      // Здесь должна быть интеграция с Google Calendar API или Apple EventKit
      // Пока что имитируем успешную синхронизацию

      if (kDebugMode) {
        developer.log('Syncing event with external calendar: $eventId');
      }

      // Имитируем задержку API
      await Future.delayed(const Duration(seconds: 1));

      // Обновляем статус синхронизации
      await _firestore.collection('calendar_events').doc(eventId).update({
        'isSynced': true,
        'syncStatus': 'success',
        'externalEventId':
            'ext_${eventId}_${DateTime.now().millisecondsSinceEpoch}',
        'lastSyncAt': FieldValue.serverTimestamp(),
      });

      await _errorLogger.logInfo(
        message: 'Event synced with external calendar',
        action: 'sync_with_external_calendar',
        additionalData: {'eventId': eventId},
      );
    } catch (e, stackTrace) {
      // Обновляем статус на ошибку
      await _firestore.collection('calendar_events').doc(eventId).update({
        'isSynced': false,
        'syncStatus': 'error',
        'syncError': e.toString(),
        'lastSyncAt': FieldValue.serverTimestamp(),
      });

      await _errorLogger.logError(
        error: 'Failed to sync with external calendar: $e',
        stackTrace: stackTrace.toString(),
        action: 'sync_with_external_calendar',
        additionalData: {'eventId': eventId},
      );
    }
  }

  /// Удалить из внешнего календаря
  Future<void> _deleteFromExternalCalendar(String externalEventId) async {
    try {
      // Здесь должна быть интеграция с Google Calendar API или Apple EventKit
      // Пока что имитируем успешное удаление

      if (kDebugMode) {
        developer
            .log('Deleting event from external calendar: $externalEventId');
      }

      // Имитируем задержку API
      await Future.delayed(const Duration(milliseconds: 500));

      await _errorLogger.logInfo(
        message: 'Event deleted from external calendar',
        action: 'delete_from_external_calendar',
        additionalData: {'externalEventId': externalEventId},
      );
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to delete from external calendar: $e',
        stackTrace: stackTrace.toString(),
        action: 'delete_from_external_calendar',
        additionalData: {'externalEventId': externalEventId},
      );
    }
  }

  /// Получить настройки календаря пользователя
  Future<Map<String, dynamic>> getCalendarSettings(String userId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('calendar_settings').doc(userId).get();

      if (doc.exists) {
        return doc.data()! as Map<String, dynamic>;
      }

      // Возвращаем настройки по умолчанию
      return {
        'userId': userId,
        'googleCalendarEnabled': false,
        'appleCalendarEnabled': false,
        'autoSync': false,
        'syncInterval': 30, // минуты
        'defaultReminderTime': 15, // минуты до события
        'workingHours': {
          'start': '09:00',
          'end': '18:00',
        },
        'workingDays': [1, 2, 3, 4, 5], // Пн-Пт
        'timezone': 'Europe/Moscow',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get calendar settings: $e',
        stackTrace: stackTrace.toString(),
        userId: userId,
        action: 'get_calendar_settings',
      );
      return {};
    }
  }

  /// Обновить настройки календаря
  Future<bool> updateCalendarSettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    try {
      await _firestore.collection('calendar_settings').doc(userId).set(
        {
          ...settings,
          'userId': userId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await _errorLogger.logInfo(
        message: 'Calendar settings updated',
        userId: userId,
        action: 'update_calendar_settings',
        additionalData: settings,
      );

      return true;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to update calendar settings: $e',
        stackTrace: stackTrace.toString(),
        userId: userId,
        action: 'update_calendar_settings',
      );
      return false;
    }
  }

  /// Создать напоминание
  Future<bool> createReminder({
    required String eventId,
    required String userId,
    required DateTime reminderTime,
    required String message,
    String? type,
  }) async {
    try {
      final reminderId = _firestore.collection('calendar_reminders').doc().id;
      final now = DateTime.now();

      final reminder = {
        'id': reminderId,
        'eventId': eventId,
        'userId': userId,
        'reminderTime': Timestamp.fromDate(reminderTime),
        'message': message,
        'type': type ?? 'notification',
        'isTriggered': false,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      await _firestore
          .collection('calendar_reminders')
          .doc(reminderId)
          .set(reminder);

      await _errorLogger.logInfo(
        message: 'Calendar reminder created',
        userId: userId,
        action: 'create_reminder',
        additionalData: {
          'reminderId': reminderId,
          'eventId': eventId,
          'reminderTime': reminderTime.toIso8601String(),
        },
      );

      return true;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to create reminder: $e',
        stackTrace: stackTrace.toString(),
        userId: userId,
        action: 'create_reminder',
        additionalData: {'eventId': eventId},
      );
      return false;
    }
  }

  /// Получить напоминания пользователя
  Future<List<Map<String, dynamic>>> getUserReminders(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    bool? isTriggered,
  }) async {
    try {
      Query query = _firestore
          .collection('calendar_reminders')
          .where('userId', isEqualTo: userId);

      if (startDate != null) {
        query = query.where(
          'reminderTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          'reminderTime',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }
      if (isTriggered != null) {
        query = query.where('isTriggered', isEqualTo: isTriggered);
      }

      query = query.orderBy('reminderTime');

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data()! as Map<String, dynamic>)
          .toList();
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get user reminders: $e',
        stackTrace: stackTrace.toString(),
        userId: userId,
        action: 'get_user_reminders',
      );
      return [];
    }
  }

  /// Проверить конфликты времени
  Future<List<Map<String, dynamic>>> checkTimeConflicts(
    String userId, {
    required DateTime startTime,
    required DateTime endTime,
    String? excludeEventId,
  }) async {
    try {
      Query query = _firestore
          .collection('calendar_events')
          .where('userId', isEqualTo: userId)
          .where('startTime', isLessThan: Timestamp.fromDate(endTime))
          .where('endTime', isGreaterThan: Timestamp.fromDate(startTime));

      if (excludeEventId != null) {
        query = query.where(FieldPath.documentId, isNotEqualTo: excludeEventId);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data()! as Map<String, dynamic>)
          .toList();
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to check time conflicts: $e',
        stackTrace: stackTrace.toString(),
        userId: userId,
        action: 'check_time_conflicts',
      );
      return [];
    }
  }

  /// Получить статистику календаря
  Future<Map<String, dynamic>> getCalendarStats(String userId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // События за месяц
      final monthlyEvents = await getUserCalendarEvents(
        userId,
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      // Все события пользователя
      final allEvents = await getUserCalendarEvents(userId);

      // Напоминания
      final reminders = await getUserReminders(userId);

      return {
        'totalEvents': allEvents.length,
        'monthlyEvents': monthlyEvents.length,
        'totalReminders': reminders.length,
        'pendingReminders': reminders.where((r) => !r['isTriggered']).length,
        'syncedEvents': allEvents.where((e) => e['isSynced'] == true).length,
        'syncRate': allEvents.isNotEmpty
            ? allEvents.where((e) => e['isSynced'] == true).length /
                allEvents.length
            : 0.0,
        'lastUpdated': now.toIso8601String(),
      };
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get calendar stats: $e',
        stackTrace: stackTrace.toString(),
        userId: userId,
        action: 'get_calendar_stats',
      );
      return {};
    }
  }
}
