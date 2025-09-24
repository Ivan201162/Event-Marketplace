import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// Сервис для работы с Firebase Cloud Messaging
class FCMService {
  factory FCMService() => _instance;
  FCMService._internal();
  static final FCMService _instance = FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;

  /// Инициализация FCM
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Инициализация локальных уведомлений
      await _initializeLocalNotifications();

      // Запрос разрешений
      await _requestPermissions();

      // Получение FCM токена
      await _getFCMToken();

      // Настройка обработчиков сообщений
      _setupMessageHandlers();

      _isInitialized = true;
      print('FCM Service initialized successfully');
    } catch (e) {
      print('Error initializing FCM Service: $e');
    }
  }

  /// Инициализация локальных уведомлений
  Future<void> _initializeLocalNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Создание канала для Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Запрос разрешений
  Future<void> _requestPermissions() async {
    // Запрос разрешений для FCM
    final settings = await _firebaseMessaging.requestPermission();

    print('User granted permission: ${settings.authorizationStatus}');

    // Запрос разрешений для локальных уведомлений
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Получение FCM токена
  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $_fcmToken');

      // Сохранение токена в SharedPreferences
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }

      return _fcmToken;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Настройка обработчиков сообщений
  void _setupMessageHandlers() {
    // Обработка сообщений в foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Обработка сообщений при нажатии на уведомление
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Обработка сообщений при запуске приложения из уведомления
    _handleInitialMessage();
  }

  /// Обработка сообщений в foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');

    // Показать локальное уведомление
    await _showLocalNotification(message);
  }

  /// Обработка сообщений при нажатии на уведомление
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('Message opened app: ${message.messageId}');
    _handleNotificationTap(message);
  }

  /// Обработка сообщений при запуске приложения из уведомления
  Future<void> _handleInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('App launched from notification: ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage);
    }
  }

  /// Показать локальное уведомление
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    // final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Обработка нажатия на уведомление
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;

    // Обработка различных типов уведомлений
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'booking_confirmed':
          _navigateToBooking(data['bookingId']);
          break;
        case 'booking_rejected':
          _navigateToBooking(data['bookingId']);
          break;
        case 'payment_completed':
          _navigateToPayment(data['paymentId']);
          break;
        case 'chat_message':
          _navigateToChat(data['chatId']);
          break;
        default:
          _navigateToHome();
      }
    } else {
      _navigateToHome();
    }
  }

  /// Обработка нажатия на локальное уведомление
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Здесь можно добавить логику обработки нажатия на локальное уведомление
  }

  /// Навигация к заявке
  void _navigateToBooking(String? bookingId) {
    if (bookingId != null) {
      // TODO: Реализовать навигацию к заявке
      print('Navigate to booking: $bookingId');
    }
  }

  /// Навигация к платежу
  void _navigateToPayment(String? paymentId) {
    if (paymentId != null) {
      // TODO: Реализовать навигацию к платежу
      print('Navigate to payment: $paymentId');
    }
  }

  /// Навигация к чату
  void _navigateToChat(String? chatId) {
    if (chatId != null) {
      // TODO: Реализовать навигацию к чату
      print('Navigate to chat: $chatId');
    }
  }

  /// Навигация на главную
  void _navigateToHome() {
    // TODO: Реализовать навигацию на главную
    print('Navigate to home');
  }

  /// Получить FCM токен
  String? get fcmToken => _fcmToken;

  /// Обновить FCM токен
  Future<String?> refreshToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }
      return _fcmToken;
    } catch (e) {
      print('Error refreshing FCM token: $e');
      return null;
    }
  }

  /// Подписаться на топик
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  /// Отписаться от топика
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Показать локальное уведомление
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload ?? data?.toString(),
    );
  }

  /// Планировать локальное уведомление
  Future<void> scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_channel',
          'Scheduled Notifications',
          channelDescription:
              'This channel is used for scheduled notifications.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Отменить запланированное уведомление
  Future<void> cancelScheduledNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Отменить все запланированные уведомления
  Future<void> cancelAllScheduledNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Получить настройки уведомлений
  Future<NotificationSettings> getNotificationSettings() async =>
      _firebaseMessaging.getNotificationSettings();

  /// Проверить, включены ли уведомления
  Future<bool> areNotificationsEnabled() async {
    final settings = await getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Открыть настройки уведомлений
  Future<void> openNotificationSettings() async {
    // await _localNotifications
    //     .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    //     ?.openNotificationSettings();
    print('Notification settings opened');
  }

  /// Сохранить FCM токен пользователя в Firestore
  Future<void> saveUserFCMToken(String userId, String token) async {
    try {
      // TODO: Реализовать сохранение токена в Firestore
      // await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(userId)
      //     .update({'fcmToken': token});
      print('FCM token saved for user: $userId');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Отправить уведомление о бронировании
  Future<void> sendBookingNotification({
    required String userId,
    required String title,
    required String body,
    required String bookingId,
    required String
        type, // 'booking_created', 'booking_confirmed', 'booking_rejected', 'booking_cancelled'
  }) async {
    try {
      // В реальном приложении здесь был бы HTTP запрос к FCM API
      // Для демонстрации показываем локальное уведомление
      await showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        data: {
          'type': type,
          'bookingId': bookingId,
          'userId': userId,
        },
      );
    } catch (e) {
      print('Error sending booking notification: $e');
    }
  }

  /// Подписаться на уведомления о бронированиях
  Future<void> subscribeToBookingNotifications(String userId) async {
    try {
      await subscribeToTopic('bookings_$userId');
      await subscribeToTopic('bookings_all');
    } catch (e) {
      print('Error subscribing to booking notifications: $e');
    }
  }

  /// Отписаться от уведомлений о бронированиях
  Future<void> unsubscribeFromBookingNotifications(String userId) async {
    try {
      await unsubscribeFromTopic('bookings_$userId');
      await unsubscribeFromTopic('bookings_all');
    } catch (e) {
      print('Error unsubscribing from booking notifications: $e');
    }
  }
}
