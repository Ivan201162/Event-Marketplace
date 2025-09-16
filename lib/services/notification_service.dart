import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;

/// Сервис для управления уведомлениями
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;

  /// Инициализация сервиса уведомлений
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Инициализация локальных уведомлений
      await _initializeLocalNotifications();

      // Инициализация Firebase Messaging
      await _initializeFirebaseMessaging();

      // Запрос разрешений
      await _requestPermissions();

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Инициализация локальных уведомлений
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Инициализация Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Обработка сообщений в фоне
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Обработка сообщений в foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Обработка нажатий на уведомления
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Запрос разрешений
  Future<void> _requestPermissions() async {
    // Локальные уведомления
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Firebase Messaging
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  /// Обработчик нажатия на локальное уведомление
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    _handleNotificationPayload(response.payload);
  }

  /// Обработчик сообщений в foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');

    // Показываем локальное уведомление
    _showLocalNotification(
      title: message.notification?.title ?? 'Event Marketplace',
      body: message.notification?.body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  /// Обработчик нажатия на Firebase уведомление
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Firebase notification tapped: ${message.messageId}');
    _handleNotificationPayload(jsonEncode(message.data));
  }

  /// Обработка данных уведомления
  void _handleNotificationPayload(String? payload) {
    if (payload == null) return;

    try {
      final data = jsonDecode(payload);
      final type = data['type'] as String?;

      switch (type) {
        case 'review':
          _handleReviewNotification(data);
          break;
        case 'booking':
          _handleBookingNotification(data);
          break;
        case 'payment':
          _handlePaymentNotification(data);
          break;
        case 'reminder':
          _handleReminderNotification(data);
          break;
        default:
          debugPrint('Unknown notification type: $type');
      }
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
    }
  }

  /// Обработка уведомления о новом отзыве
  void _handleReviewNotification(Map<String, dynamic> data) {
    // final specialistId = data['specialistId'] as String?;
    final customerName = data['customerName'] as String?;
    final rating = data['rating'] as int?;

    debugPrint('Review notification: $customerName rated $rating stars');
    // Здесь можно добавить навигацию к отзыву
  }

  /// Обработка уведомления о бронировании
  void _handleBookingNotification(Map<String, dynamic> data) {
    final bookingId = data['bookingId'] as String?;
    final status = data['status'] as String?;

    debugPrint('Booking notification: $bookingId status changed to $status');
    // Здесь можно добавить навигацию к бронированию
  }

  /// Обработка уведомления об оплате
  void _handlePaymentNotification(Map<String, dynamic> data) {
    final paymentId = data['paymentId'] as String?;
    final amount = data['amount'] as double?;

    debugPrint('Payment notification: $paymentId amount $amount');
    // Здесь можно добавить навигацию к платежу
  }

  /// Обработка напоминания
  void _handleReminderNotification(Map<String, dynamic> data) {
    // final eventId = data['eventId'] as String?;
    final eventName = data['eventName'] as String?;

    debugPrint('Reminder notification: $eventName');
    // Здесь можно добавить навигацию к событию
  }

  /// Показать локальное уведомление
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'event_marketplace',
      'Event Marketplace Notifications',
      channelDescription: 'Уведомления Event Marketplace',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Отправить уведомление о новом отзыве специалисту
  Future<void> sendReviewNotification({
    required String specialistId,
    required String customerName,
    required int rating,
    required String reviewText,
  }) async {
    try {
      // Получаем FCM токен специалиста
      final specialistDoc =
          await _firestore.collection('users').doc(specialistId).get();

      if (!specialistDoc.exists) return;

      final fcmToken = specialistDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null) return;

      // Отправляем уведомление через Firebase Functions
      await _firestore.collection('notifications').add({
        'type': 'review',
        'specialistId': specialistId,
        'customerName': customerName,
        'rating': rating,
        'reviewText': reviewText,
        'fcmToken': fcmToken,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      debugPrint('Review notification sent to specialist: $specialistId');
    } catch (e) {
      debugPrint('Error sending review notification: $e');
    }
  }

  /// Отправить напоминание о неоплаченном бронировании
  Future<void> sendPaymentReminder({
    required String customerId,
    required String bookingId,
    required String eventName,
    required double amount,
    required DateTime dueDate,
  }) async {
    try {
      // Планируем локальное уведомление
      await _scheduleLocalNotification(
        id: bookingId.hashCode,
        title: 'Напоминание об оплате',
        body:
            'Не забудьте оплатить бронирование "$eventName" на сумму ${amount.toStringAsFixed(0)} ₽',
        scheduledDate:
            dueDate.subtract(const Duration(hours: 24)), // За 24 часа
        payload: jsonEncode({
          'type': 'reminder',
          'bookingId': bookingId,
          'eventName': eventName,
          'amount': amount,
        }),
      );

      debugPrint('Payment reminder scheduled for booking: $bookingId');
    } catch (e) {
      debugPrint('Error scheduling payment reminder: $e');
    }
  }

  /// Запланировать локальное уведомление
  Future<void> _scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'event_marketplace_reminders',
      'Event Marketplace Reminders',
      channelDescription: 'Напоминания Event Marketplace',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Отменить запланированное уведомление
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Отменить все уведомления
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Получить FCM токен
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Сохранить FCM токен пользователя
  Future<void> saveFCMToken(String userId) async {
    try {
      final token = await getFCMToken();
      if (token == null) return;

      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });

      debugPrint('FCM token saved for user: $userId');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Подписаться на топик
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Отписаться от топика
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }
}

/// Обработчик фоновых сообщений Firebase
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
  // Здесь можно добавить обработку фоновых сообщений
}
