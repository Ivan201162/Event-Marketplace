import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Сервис для работы с push-уведомлениями
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Инициализация сервиса уведомлений
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Запрашиваем разрешения
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
          '✅ Push notification permission status: ${settings.authorizationStatus}');

      // Инициализируем локальные уведомления
      await _initializeLocalNotifications();

      // Настраиваем обработчики сообщений
      _setupMessageHandlers();

      _isInitialized = true;
      debugPrint('✅ Push notification service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing push notification service: $e');
      rethrow;
    }
  }

  /// Инициализация локальных уведомлений
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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

    // Создаем канал для Android
    const androidChannel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Notifications for new chat messages',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Настройка обработчиков сообщений
  static void _setupMessageHandlers() {
    // Обработчик сообщений в foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Обработчик нажатий на уведомления
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Обработчик сообщений в background
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  /// Обработка сообщений в foreground
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📱 Received foreground message: ${message.messageId}');

    // Показываем локальное уведомление
    await _showLocalNotification(message);
  }

  /// Обработка нажатий на уведомления
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('📱 Notification tapped: ${message.messageId}');

    // TODO: Navigate to specific chat
    final chatId = message.data['chatId'];
    if (chatId != null) {
      // Navigate to chat screen
      debugPrint('📱 Navigating to chat: $chatId');
    }
  }

  /// Обработка сообщений в background
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('📱 Received background message: ${message.messageId}');

    // В background мы не можем показать UI, только обработать данные
    // Здесь можно сохранить данные в локальную базу или отправить аналитику
  }

  /// Показать локальное уведомление
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Обработчик нажатий на локальные уведомления
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Local notification tapped: ${response.payload}');

    // TODO: Parse payload and navigate to specific chat
    if (response.payload != null) {
      // Parse payload and navigate
    }
  }

  /// Получить FCM токен
  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('📱 FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Подписаться на топик
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Отписаться от топика
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Отправить уведомление о новом сообщении
  static Future<void> sendChatNotification({
    required String chatId,
    required String senderName,
    required String messageContent,
    required String receiverToken,
  }) async {
    try {
      // В реальном приложении это должно отправляться через Cloud Functions
      // или серверный API, а не из клиентского приложения
      debugPrint(
          '📱 Would send notification to $receiverToken: $messageContent');
    } catch (e) {
      debugPrint('❌ Error sending chat notification: $e');
    }
  }

  /// Очистить все уведомления
  static Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      debugPrint('✅ All notifications cleared');
    } catch (e) {
      debugPrint('❌ Error clearing notifications: $e');
    }
  }

  /// Очистить уведомления для конкретного чата
  static Future<void> clearChatNotifications(String chatId) async {
    try {
      // В реальном приложении нужно отслеживать ID уведомлений для каждого чата
      await _localNotifications.cancel(chatId.hashCode);
      debugPrint('✅ Notifications cleared for chat: $chatId');
    } catch (e) {
      debugPrint('❌ Error clearing chat notifications: $e');
    }
  }
}

/// Обработчик сообщений в background (должен быть top-level функцией)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('📱 Background message received: ${message.messageId}');

  // Здесь можно обработать сообщение в background
  // Например, сохранить в локальную базу данных
}
