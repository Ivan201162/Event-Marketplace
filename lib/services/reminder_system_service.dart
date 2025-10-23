import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'error_logging_service.dart';

/// Сервис системы напоминаний
class ReminderSystemService {
  factory ReminderSystemService() => _instance;
  ReminderSystemService._internal();
  static final ReminderSystemService _instance =
      ReminderSystemService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ErrorLoggingService _errorLogger = ErrorLoggingService();

  Timer? _reminderCheckTimer;
  final Map<String, Timer> _activeReminders = {};

  /// Инициализировать систему напоминаний
  Future<void> initialize() async {
    try {
      // Запускаем проверку напоминаний каждую минуту
      _reminderCheckTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _checkPendingReminders(),
      );

      await _errorLogger.logInfo(
        message: 'Reminder system initialized',
        action: 'initialize_reminder_system',
      );
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to initialize reminder system: $e',
        stackTrace: stackTrace.toString(),
        action: 'initialize_reminder_system',
      );
    }
  }

  /// Остановить систему напоминаний
  void dispose() {
    _reminderCheckTimer?.cancel();
    for (final timer in _activeReminders.values) {
      timer.cancel();
    }
    _activeReminders.clear();
  }

  /// Создать напоминание
  Future<String?> createReminder({
    required String userId,
    required String title,
    required String message,
    required DateTime reminderTime,
    ReminderType type = ReminderType.notification,
    String? orderId,
    String? eventId,
    Map<String, dynamic>? metadata,
    List<int>?
        repeatDays, // Дни недели для повторения (1-7, где 1 = понедельник)
    Duration? repeatInterval,
  }) async {
    try {
      final reminderId = _firestore.collection('reminders').doc().id;
      final now = DateTime.now();

      final reminder = {
        'id': reminderId,
        'userId': userId,
        'title': title,
        'message': message,
        'reminderTime': Timestamp.fromDate(reminderTime),
        'type': type.name,
        'orderId': orderId,
        'eventId': eventId,
        'metadata': metadata ?? {},
        'isTriggered': false,
        'isActive': true,
        'repeatDays': repeatDays ?? [],
        'repeatInterval': repeatInterval?.inMinutes,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'lastTriggered': null,
        'nextReminderTime': Timestamp.fromDate(reminderTime),
      };

      await _firestore.collection('reminders').doc(reminderId).set(reminder);

      // Планируем напоминание
      await _scheduleReminder(reminderId, reminder);

      await _errorLogger.logInfo(
        message: 'Reminder created',
        userId: userId,
        action: 'create_reminder',
        additionalData: {
          'reminderId': reminderId,
          'reminderTime': reminderTime.toIso8601String(),
          'type': type.name,
        },
      );

      return reminderId;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to create reminder: $e',
        stackTrace: stackTrace.toString(),
        userId: userId,
        action: 'create_reminder',
        additionalData: {
          'title': title,
          'reminderTime': reminderTime.toIso8601String()
        },
      );
      return null;
    }
  }

  /// Обновить напоминание
  Future<bool> updateReminder(
    String reminderId, {
    String? title,
    String? message,
    DateTime? reminderTime,
    ReminderType? type,
    Map<String, dynamic>? metadata,
    List<int>? repeatDays,
    Duration? repeatInterval,
  }) async {
    try {
      // Отменяем текущее напоминание
      _activeReminders[reminderId]?.cancel();
      _activeReminders.remove(reminderId);

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp()
      };

      if (title != null) updates['title'] = title;
      if (message != null) updates['message'] = message;
      if (reminderTime != null) {
        updates['reminderTime'] = Timestamp.fromDate(reminderTime);
        updates['nextReminderTime'] = Timestamp.fromDate(reminderTime);
      }
      if (type != null) updates['type'] = type.name;
      if (metadata != null) updates['metadata'] = metadata;
      if (repeatDays != null) updates['repeatDays'] = repeatDays;
      if (repeatInterval != null) {
        updates['repeatInterval'] = repeatInterval.inMinutes;
      }

      await _firestore.collection('reminders').doc(reminderId).update(updates);

      // Получаем обновленные данные и планируем заново
      final doc =
          await _firestore.collection('reminders').doc(reminderId).get();

      if (doc.exists) {
        await _scheduleReminder(reminderId, doc.data()!);
      }

      await _errorLogger.logInfo(
        message: 'Reminder updated',
        action: 'update_reminder',
        additionalData: {'reminderId': reminderId},
      );

      return true;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to update reminder: $e',
        stackTrace: stackTrace.toString(),
        action: 'update_reminder',
        additionalData: {'reminderId': reminderId},
      );
      return false;
    }
  }

  /// Удалить напоминание
  Future<bool> deleteReminder(String reminderId) async {
    try {
      // Отменяем активное напоминание
      _activeReminders[reminderId]?.cancel();
      _activeReminders.remove(reminderId);

      await _firestore.collection('reminders').doc(reminderId).delete();

      await _errorLogger.logInfo(
        message: 'Reminder deleted',
        action: 'delete_reminder',
        additionalData: {'reminderId': reminderId},
      );

      return true;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to delete reminder: $e',
        stackTrace: stackTrace.toString(),
        action: 'delete_reminder',
        additionalData: {'reminderId': reminderId},
      );
      return false;
    }
  }

  /// Получить напоминания пользователя
  Future<List<Map<String, dynamic>>> getUserReminders(
    String userId, {
    bool? isActive,
    bool? isTriggered,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      Query query =
          _firestore.collection('reminders').where('userId', isEqualTo: userId);

      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }
      if (isTriggered != null) {
        query = query.where('isTriggered', isEqualTo: isTriggered);
      }
      if (startDate != null) {
        query = query.where(
          'nextReminderTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        query = query.where('nextReminderTime',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      query = query.orderBy('nextReminderTime').limit(limit);

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

  /// Получить напоминания по заказу
  Future<List<Map<String, dynamic>>> getOrderReminders(String orderId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('reminders')
          .where('orderId', isEqualTo: orderId)
          .orderBy('nextReminderTime')
          .get();

      return snapshot.docs
          .map((doc) => doc.data()! as Map<String, dynamic>)
          .toList();
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get order reminders: $e',
        stackTrace: stackTrace.toString(),
        action: 'get_order_reminders',
        additionalData: {'orderId': orderId},
      );
      return [];
    }
  }

  /// Планировать напоминание
  Future<void> _scheduleReminder(
      String reminderId, Map<String, dynamic> reminder) async {
    try {
      final reminderTime = (reminder['nextReminderTime'] as Timestamp).toDate();
      final now = DateTime.now();

      if (reminderTime.isBefore(now)) {
        // Напоминание уже должно было сработать
        await _triggerReminder(reminderId, reminder);
        return;
      }

      final delay = reminderTime.difference(now);

      final timer = Timer(delay, () async {
        await _triggerReminder(reminderId, reminder);
      });

      _activeReminders[reminderId] = timer;

      if (kDebugMode) {
        developer.log(
            'Reminder scheduled: $reminderId at ${reminderTime.toIso8601String()}');
      }
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to schedule reminder: $e',
        stackTrace: stackTrace.toString(),
        action: 'schedule_reminder',
        additionalData: {'reminderId': reminderId},
      );
    }
  }

  /// Сработать напоминание
  Future<void> _triggerReminder(
      String reminderId, Map<String, dynamic> reminder) async {
    try {
      final type = ReminderType.values.firstWhere(
        (t) => t.name == reminder['type'],
        orElse: () => ReminderType.notification,
      );

      // Отправляем напоминание
      await _sendReminder(reminderId, reminder, type);

      // Обновляем статус
      await _firestore.collection('reminders').doc(reminderId).update({
        'isTriggered': true,
        'lastTriggered': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Проверяем, нужно ли повторить напоминание
      await _handleReminderRepeat(reminderId, reminder);

      // Удаляем из активных напоминаний
      _activeReminders.remove(reminderId);

      await _errorLogger.logInfo(
        message: 'Reminder triggered',
        action: 'trigger_reminder',
        additionalData: {'reminderId': reminderId, 'type': type.name},
      );
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to trigger reminder: $e',
        stackTrace: stackTrace.toString(),
        action: 'trigger_reminder',
        additionalData: {'reminderId': reminderId},
      );
    }
  }

  /// Отправить напоминание
  Future<void> _sendReminder(
    String reminderId,
    Map<String, dynamic> reminder,
    ReminderType type,
  ) async {
    try {
      switch (type) {
        case ReminderType.notification:
          await _sendNotificationReminder(reminder);
          break;
        case ReminderType.email:
          await _sendEmailReminder(reminder);
          break;
        case ReminderType.sms:
          await _sendSmsReminder(reminder);
          break;
        case ReminderType.push:
          await _sendPushReminder(reminder);
          break;
      }
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to send reminder: $e',
        stackTrace: stackTrace.toString(),
        action: 'send_reminder',
        additionalData: {'reminderId': reminderId, 'type': type.name},
      );
    }
  }

  /// Отправить уведомление
  Future<void> _sendNotificationReminder(Map<String, dynamic> reminder) async {
    // Здесь должна быть интеграция с системой уведомлений
    if (kDebugMode) {
      developer
          .log('NOTIFICATION: ${reminder['title']} - ${reminder['message']}');
    }
  }

  /// Отправить email
  Future<void> _sendEmailReminder(Map<String, dynamic> reminder) async {
    // Здесь должна быть интеграция с email сервисом
    if (kDebugMode) {
      developer.log('EMAIL: ${reminder['title']} - ${reminder['message']}');
    }
  }

  /// Отправить SMS
  Future<void> _sendSmsReminder(Map<String, dynamic> reminder) async {
    // Здесь должна быть интеграция с SMS сервисом
    if (kDebugMode) {
      developer.log('SMS: ${reminder['title']} - ${reminder['message']}');
    }
  }

  /// Отправить push уведомление
  Future<void> _sendPushReminder(Map<String, dynamic> reminder) async {
    // Здесь должна быть интеграция с FCM
    if (kDebugMode) {
      developer.log('PUSH: ${reminder['title']} - ${reminder['message']}');
    }
  }

  /// Обработать повторение напоминания
  Future<void> _handleReminderRepeat(
      String reminderId, Map<String, dynamic> reminder) async {
    try {
      final repeatDays = List<int>.from(reminder['repeatDays'] ?? []);
      final repeatInterval = reminder['repeatInterval'] as int?;

      if (repeatDays.isNotEmpty) {
        // Повторение по дням недели
        final now = DateTime.now();
        final nextReminderTime = _getNextRepeatTime(now, repeatDays);

        if (nextReminderTime != null) {
          await _firestore.collection('reminders').doc(reminderId).update({
            'nextReminderTime': Timestamp.fromDate(nextReminderTime),
            'isTriggered': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Планируем следующее напоминание
          final updatedReminder = reminder;
          updatedReminder['nextReminderTime'] =
              Timestamp.fromDate(nextReminderTime);
          updatedReminder['isTriggered'] = false;

          await _scheduleReminder(reminderId, updatedReminder);
        }
      } else if (repeatInterval != null && repeatInterval > 0) {
        // Повторение по интервалу
        final now = DateTime.now();
        final nextReminderTime = now.add(Duration(minutes: repeatInterval));

        await _firestore.collection('reminders').doc(reminderId).update({
          'nextReminderTime': Timestamp.fromDate(nextReminderTime),
          'isTriggered': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Планируем следующее напоминание
        final updatedReminder = reminder;
        updatedReminder['nextReminderTime'] =
            Timestamp.fromDate(nextReminderTime);
        updatedReminder['isTriggered'] = false;

        await _scheduleReminder(reminderId, updatedReminder);
      }
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to handle reminder repeat: $e',
        stackTrace: stackTrace.toString(),
        action: 'handle_reminder_repeat',
        additionalData: {'reminderId': reminderId},
      );
    }
  }

  /// Получить следующее время повторения
  DateTime? _getNextRepeatTime(DateTime from, List<int> repeatDays) {
    for (var i = 1; i <= 7; i++) {
      final nextDay = from.add(Duration(days: i));
      if (repeatDays.contains(nextDay.weekday)) {
        return DateTime(
            nextDay.year, nextDay.month, nextDay.day, from.hour, from.minute);
      }
    }
    return null;
  }

  /// Проверить ожидающие напоминания
  Future<void> _checkPendingReminders() async {
    try {
      final now = DateTime.now();
      final fiveMinutesFromNow = now.add(const Duration(minutes: 5));

      final QuerySnapshot snapshot = await _firestore
          .collection('reminders')
          .where('isActive', isEqualTo: true)
          .where('isTriggered', isEqualTo: false)
          .where('nextReminderTime',
              isLessThanOrEqualTo: Timestamp.fromDate(fiveMinutesFromNow))
          .get();

      for (final doc in snapshot.docs) {
        final reminder = doc.data()! as Map<String, dynamic>;
        final reminderId = doc.id;

        // Планируем напоминание, если оно еще не запланировано
        if (!_activeReminders.containsKey(reminderId)) {
          await _scheduleReminder(reminderId, reminder);
        }
      }
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to check pending reminders: $e',
        stackTrace: stackTrace.toString(),
        action: 'check_pending_reminders',
      );
    }
  }

  /// Получить статистику напоминаний
  Future<Map<String, dynamic>> getReminderStats(String userId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Напоминания за месяц
      final monthlyReminders = await getUserReminders(
        userId,
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      // Все напоминания пользователя
      final allReminders = await getUserReminders(userId);

      // Активные напоминания
      final activeReminders = await getUserReminders(userId, isActive: true);

      return {
        'totalReminders': allReminders.length,
        'monthlyReminders': monthlyReminders.length,
        'activeReminders': activeReminders.length,
        'triggeredReminders':
            allReminders.where((r) => r['isTriggered'] == true).length,
        'pendingReminders':
            allReminders.where((r) => r['isTriggered'] == false).length,
        'repeatingReminders': allReminders
            .where((r) =>
                (r['repeatDays'] as List).isNotEmpty ||
                r['repeatInterval'] != null)
            .length,
        'lastUpdated': now.toIso8601String(),
      };
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get reminder stats: $e',
        stackTrace: stackTrace.toString(),
        userId: userId,
        action: 'get_reminder_stats',
      );
      return {};
    }
  }
}

/// Типы напоминаний
enum ReminderType {
  notification('Уведомление'),
  email('Email'),
  sms('SMS'),
  push('Push уведомление');

  const ReminderType(this.displayName);
  final String displayName;
}
