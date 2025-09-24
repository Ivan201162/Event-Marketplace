import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/calendar_event.dart';

/// Сервис для работы с напоминаниями
class ReminderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Инициализация сервиса напоминаний
  Future<void> initialize() async {
    // Инициализация локальных уведомлений
    await _initializeLocalNotifications();
    
    // Инициализация FCM
    await _initializeFCM();
    
    // Запуск фоновой задачи для проверки напоминаний
    _startReminderChecker();
  }

  /// Инициализация локальных уведомлений
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Запрос разрешений
    await _requestPermissions();
  }

  /// Инициализация FCM
  Future<void> _initializeFCM() async {
    // Запрос разрешений
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('FCM разрешения получены');
    } else {
      debugPrint('FCM разрешения отклонены');
    }

    // Получение токена
    final token = await _messaging.getToken();
    debugPrint('FCM токен: $token');

    // Обработка сообщений в фоне
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Запрос разрешений на уведомления
  Future<void> _requestPermissions() async {
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  /// Создать напоминание для события
  Future<void> createEventReminder({
    required String eventId,
    required String userId,
    required DateTime reminderTime,
    required String message,
  }) async {
    try {
      final reminder = EventReminder(
        id: '', // Будет установлен при создании
        eventId: eventId,
        userId: userId,
        reminderTime: reminderTime,
        message: message,
        isSent: false,
        createdAt: DateTime.now(),
      );

      await _db.collection('eventReminders').add(reminder.toMap());
      
      // Создаем локальное уведомление
      await _scheduleLocalNotification(reminder);
      
      debugPrint('Напоминание создано для события: $eventId');
    } catch (e) {
      debugPrint('Ошибка создания напоминания: $e');
      throw Exception('Не удалось создать напоминание: $e');
    }
  }

  /// Создать напоминания для события
  Future<void> createEventReminders(CalendarEvent event) async {
    try {
      for (final minutes in event.reminderMinutes) {
        final reminderTime = event.startDate.subtract(Duration(minutes: minutes));
        
        // Создаем напоминание только если оно в будущем
        if (reminderTime.isAfter(DateTime.now())) {
          await createEventReminder(
            eventId: event.id,
            userId: event.userId,
            reminderTime: reminderTime,
            message: 'Напоминание: ${event.title}',
          );
        }
      }
    } catch (e) {
      debugPrint('Ошибка создания напоминаний для события: $e');
    }
  }

  /// Запланировать локальное уведомление
  Future<void> _scheduleLocalNotification(EventReminder reminder) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'event_reminders',
        'Напоминания о событиях',
        channelDescription: 'Уведомления о предстоящих событиях',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        reminder.id.hashCode,
        'Напоминание',
        reminder.message,
        TZDateTime.from(reminder.reminderTime, getLocation('Europe/Moscow')),
        notificationDetails,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Ошибка планирования локального уведомления: $e');
    }
  }

  /// Отправить push-уведомление
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Получаем FCM токен пользователя
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final fcmToken = userData['fcmToken'] as String?;
      
      if (fcmToken == null) return;

      // Отправляем уведомление через Cloud Functions
      await _db.collection('notifications').add({
        'userId': userId,
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'sent': false,
      });

      debugPrint('Push-уведомление отправлено пользователю: $userId');
    } catch (e) {
      debugPrint('Ошибка отправки push-уведомления: $e');
    }
  }

  /// Отправить напоминание о предстоящем событии
  Future<void> sendEventReminder(CalendarEvent event, int minutesBefore) async {
    try {
      final title = 'Напоминание о событии';
      final body = 'Через $minutesBefore мин: ${event.title}';
      
      await sendPushNotification(
        userId: event.userId,
        title: title,
        body: body,
        data: {
          'eventId': event.id,
          'type': 'event_reminder',
          'minutesBefore': minutesBefore.toString(),
        },
      );
    } catch (e) {
      debugPrint('Ошибка отправки напоминания о событии: $e');
    }
  }

  /// Отправить напоминание об обновлении календаря
  Future<void> sendCalendarUpdateReminder(String userId) async {
    try {
      const title = 'Обновите календарь';
      const body = 'Не забудьте обновить свой календарь на следующую неделю';
      
      await sendPushNotification(
        userId: userId,
        title: title,
        body: body,
        data: {
          'type': 'calendar_update_reminder',
        },
      );
    } catch (e) {
      debugPrint('Ошибка отправки напоминания об обновлении календаря: $e');
    }
  }

  /// Запустить проверку напоминаний
  void _startReminderChecker() {
    // Проверяем напоминания каждые 5 минут
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkPendingReminders();
    });
  }

  /// Проверить ожидающие напоминания
  Future<void> _checkPendingReminders() async {
    try {
      final now = DateTime.now();
      final query = await _db
          .collection('eventReminders')
          .where('isSent', isEqualTo: false)
          .where('reminderTime', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      for (final doc in query.docs) {
        final reminder = EventReminder.fromDocument(doc);
        await _processReminder(reminder);
      }
    } catch (e) {
      debugPrint('Ошибка проверки напоминаний: $e');
    }
  }

  /// Обработать напоминание
  Future<void> _processReminder(EventReminder reminder) async {
    try {
      // Получаем информацию о событии
      final eventDoc = await _db.collection('calendarEvents').doc(reminder.eventId).get();
      if (!eventDoc.exists) return;

      final event = CalendarEvent.fromDocument(eventDoc);
      
      // Отправляем уведомление
      await sendEventReminder(event, _calculateMinutesBefore(event.startDate));
      
      // Отмечаем напоминание как отправленное
      await _db.collection('eventReminders').doc(reminder.id).update({
        'isSent': true,
        'sentAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('Напоминание обработано: ${reminder.id}');
    } catch (e) {
      debugPrint('Ошибка обработки напоминания: $e');
    }
  }

  /// Рассчитать количество минут до события
  int _calculateMinutesBefore(DateTime eventTime) {
    final now = DateTime.now();
    final difference = eventTime.difference(now);
    return difference.inMinutes;
  }

  /// Обработчик нажатия на уведомление
  void _onNotificationTapped(NotificationResponse response) {
    // Обработка нажатия на уведомление
    debugPrint('Уведомление нажато: ${response.payload}');
  }

  /// Получить предстоящие напоминания
  Future<List<EventReminder>> getUpcomingReminders(String userId) async {
    try {
      final now = DateTime.now();
      final query = await _db
          .collection('eventReminders')
          .where('userId', isEqualTo: userId)
          .where('isSent', isEqualTo: false)
          .where('reminderTime', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('reminderTime')
          .limit(10)
          .get();

      return query.docs
          .map((doc) => EventReminder.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения предстоящих напоминаний: $e');
      return [];
    }
  }

  /// Удалить напоминание
  Future<void> deleteReminder(String reminderId) async {
    try {
      await _db.collection('eventReminders').doc(reminderId).delete();
      
      // Отменяем локальное уведомление
      await _localNotifications.cancel(reminderId.hashCode);
      
      debugPrint('Напоминание удалено: $reminderId');
    } catch (e) {
      debugPrint('Ошибка удаления напоминания: $e');
      throw Exception('Не удалось удалить напоминание: $e');
    }
  }

  /// Обновить FCM токен пользователя
  Future<void> updateUserFCMToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _db.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': Timestamp.fromDate(DateTime.now()),
        });
        
        debugPrint('FCM токен обновлен для пользователя: $userId');
      }
    } catch (e) {
      debugPrint('Ошибка обновления FCM токена: $e');
    }
  }

  /// Отправить еженедельное напоминание об обновлении календаря
  Future<void> sendWeeklyCalendarReminders() async {
    try {
      // Получаем всех активных специалистов
      final specialistsQuery = await _db
          .collection('users')
          .where('role', isEqualTo: 'specialist')
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in specialistsQuery.docs) {
        final userId = doc.id;
        await sendCalendarUpdateReminder(userId);
      }
      
      debugPrint('Еженедельные напоминания отправлены');
    } catch (e) {
      debugPrint('Ошибка отправки еженедельных напоминаний: $e');
    }
  }
}

/// Фоновый обработчик FCM сообщений
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Фоновое FCM сообщение: ${message.messageId}');
  debugPrint('Данные: ${message.data}');
}

/// Импорт для работы с временными зонами
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Инициализация временных зон
void initializeTimeZones() {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Moscow'));
}