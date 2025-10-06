import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Сервис для работы с напоминаниями
class ReminderService {
  factory ReminderService() => _instance;
  ReminderService._internal();
  static final ReminderService _instance = ReminderService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Инициализация сервиса напоминаний
  Future<void> initialize() async {
    try {
      // Инициализация timezone
      tz.initializeTimeZones();

      // Инициализация локальных уведомлений
      await _initializeLocalNotifications();

      print('ReminderService initialized successfully');
    } catch (e) {
      print('Error initializing ReminderService: $e');
    }
  }

  /// Инициализация локальных уведомлений
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Обработка нажатия на уведомление
  void _onNotificationTapped(NotificationResponse response) {
    print('Reminder notification tapped: ${response.payload}');
    // Здесь можно добавить навигацию к событию
  }

  /// Планирование напоминания о событии
  Future<void> scheduleEventReminder({
    required String bookingId,
    required String eventTitle,
    required String specialistName,
    required DateTime eventDateTime,
    required String customerId,
  }) async {
    try {
      // Напоминание за 24 часа
      await _scheduleReminder(
        id: bookingId.hashCode,
        title: 'Напоминание о событии',
        body:
            'Завтра в ${_formatTime(eventDateTime)}: $eventTitle с $specialistName',
        scheduledTime: eventDateTime.subtract(const Duration(hours: 24)),
        payload: 'booking_24h_$bookingId',
      );

      // Напоминание за 1 час
      await _scheduleReminder(
        id: bookingId.hashCode + 1,
        title: 'Скоро событие',
        body: 'Через час: $eventTitle с $specialistName',
        scheduledTime: eventDateTime.subtract(const Duration(hours: 1)),
        payload: 'booking_1h_$bookingId',
      );

      // Сохранение информации о напоминаниях в Firestore
      await _saveReminderInfo(bookingId, eventDateTime, customerId);

      print('Event reminders scheduled for booking: $bookingId');
    } catch (e) {
      print('Error scheduling event reminder: $e');
    }
  }

  /// Планирование напоминания
  Future<void> _scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    // Проверяем, что время в будущем
    if (scheduledTime.isBefore(DateTime.now())) {
      print('Cannot schedule reminder in the past: $scheduledTime');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'event_reminders_channel',
      'Event Reminders',
      channelDescription: 'Reminders for upcoming events',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.aiff',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// Сохранение информации о напоминаниях
  Future<void> _saveReminderInfo(
    String bookingId,
    DateTime eventDateTime,
    String customerId,
  ) async {
    try {
      await _firestore.collection('reminders').doc(bookingId).set({
        'bookingId': bookingId,
        'customerId': customerId,
        'eventDateTime': Timestamp.fromDate(eventDateTime),
        'reminder24hScheduled': true,
        'reminder1hScheduled': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving reminder info: $e');
    }
  }

  /// Отмена напоминаний для события
  Future<void> cancelEventReminders(String bookingId) async {
    try {
      // Отменяем оба напоминания
      await _localNotifications.cancel(bookingId.hashCode);
      await _localNotifications.cancel(bookingId.hashCode + 1);

      // Удаляем информацию из Firestore
      await _firestore.collection('reminders').doc(bookingId).delete();

      print('Event reminders cancelled for booking: $bookingId');
    } catch (e) {
      print('Error cancelling event reminders: $e');
    }
  }

  /// Отмена всех напоминаний пользователя
  Future<void> cancelAllUserReminders() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Получаем все напоминания пользователя
      final remindersSnapshot = await _firestore
          .collection('reminders')
          .where('customerId', isEqualTo: user.uid)
          .get();

      // Отменяем все напоминания
      for (final doc in remindersSnapshot.docs) {
        final bookingId = doc.id;
        await _localNotifications.cancel(bookingId.hashCode);
        await _localNotifications.cancel(bookingId.hashCode + 1);
      }

      // Удаляем все записи из Firestore
      final batch = _firestore.batch();
      for (final doc in remindersSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('All user reminders cancelled');
    } catch (e) {
      print('Error cancelling all user reminders: $e');
    }
  }

  /// Получение активных напоминаний пользователя
  Future<List<Map<String, dynamic>>> getActiveReminders() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final remindersSnapshot = await _firestore
          .collection('reminders')
          .where('customerId', isEqualTo: user.uid)
          .get();

      return remindersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting active reminders: $e');
      return [];
    }
  }

  /// Планирование тестовых напоминаний
  Future<void> scheduleTestReminders() async {
    final now = DateTime.now();

    // Напоминание через 5 минут
    await _scheduleReminder(
      id: 9999,
      title: 'Тестовое напоминание',
      body: 'Это тестовое напоминание через 5 минут',
      scheduledTime: now.add(const Duration(minutes: 5)),
      payload: 'test_5min',
    );

    // Напоминание через 1 час
    await _scheduleReminder(
      id: 9998,
      title: 'Тестовое напоминание',
      body: 'Это тестовое напоминание через 1 час',
      scheduledTime: now.add(const Duration(hours: 1)),
      payload: 'test_1hour',
    );

    print('Test reminders scheduled');
  }

  /// Форматирование времени
  String _formatTime(DateTime dateTime) =>
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

  /// Получение запланированных уведомлений
  Future<List<PendingNotificationRequest>> getPendingNotifications() async =>
      _localNotifications.pendingNotificationRequests();

  /// Очистка всех напоминаний
  Future<void> clearAllReminders() async {
    await _localNotifications.cancelAll();
    print('All reminders cleared');
  }
}
