import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Сервис для управления пуш-уведомлениями
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Инициализация пуш-уведомлений
  static Future<void> initialize() async {
    try {
      // Запрашиваем разрешения
      await _requestPermissions();

      // Настраиваем обработчики
      _setupMessageHandlers();

      // Получаем и сохраняем токен
      await _updateToken();

      debugPrint('✅ PushNotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing PushNotificationService: $e');
    }
  }

  /// Запрос разрешений на уведомления
  static Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('📱 Notification permission status: ${settings.authorizationStatus}');
    } else if (Platform.isAndroid) {
      final settings = await _messaging.requestPermission();
      debugPrint('📱 Notification permission status: ${settings.authorizationStatus}');
    }
  }

  /// Настройка обработчиков сообщений
  static void _setupMessageHandlers() {
    // Обработка уведомлений когда приложение в фоне
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Обработка уведомлений когда приложение в переднем плане
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Обработка нажатий на уведомления
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Обработка уведомлений при запуске приложения
    _handleInitialMessage();
  }

  /// Обработка уведомлений в фоне
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    debugPrint('📱 Background message received: ${message.messageId}');
    debugPrint('📱 Title: ${message.notification?.title}');
    debugPrint('📱 Body: ${message.notification?.body}');
    debugPrint('📱 Data: ${message.data}');
  }

  /// Обработка уведомлений в переднем плане
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Foreground message received: ${message.messageId}');
    debugPrint('📱 Title: ${message.notification?.title}');
    debugPrint('📱 Body: ${message.notification?.body}');
    debugPrint('📱 Data: ${message.data}');

    // Здесь можно показать локальное уведомление или обновить UI
    _showLocalNotification(message);
  }

  /// Обработка нажатий на уведомления
  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('📱 Message opened app: ${message.messageId}');
    debugPrint('📱 Data: ${message.data}');

    // Навигация на основе данных уведомления
    _handleNotificationNavigation(message.data);
  }

  /// Обработка уведомлений при запуске приложения
  static Future<void> _handleInitialMessage() async {
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('📱 Initial message: ${initialMessage.messageId}');
      _handleNotificationNavigation(initialMessage.data);
    }
  }

  /// Показать локальное уведомление
  static void _showLocalNotification(RemoteMessage message) {
    // TODO: Реализовать показ локального уведомления
    // Можно использовать flutter_local_notifications
  }

  /// Обработка навигации по уведомлениям
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    final String? type = data['type'];
    final String? targetId = data['targetId'];

    debugPrint('📱 Navigation: type=$type, targetId=$targetId');

    // TODO: Реализовать навигацию на основе типа уведомления
    switch (type) {
      case 'new_application':
        // Навигация к заявке
        break;
      case 'new_message':
        // Навигация к чату
        break;
      case 'new_idea':
        // Навигация к идее
        break;
      case 'booking_update':
        // Навигация к бронированию
        break;
    }
  }

  /// Обновление FCM токена
  static Future<void> _updateToken() async {
    try {
      final String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('📱 FCM Token: $token');
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  /// Сохранение токена в Firestore
  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      // TODO: Получить ID текущего пользователя
      // final user = FirebaseAuth.instance.currentUser;
      // if (user != null) {
      //   await _firestore.collection('users').doc(user.uid).update({
      //     'fcmToken': token,
      //     'fcmTokenUpdatedAt': Timestamp.now(),
      //   });
      // }
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Отправка уведомления пользователю
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Получаем FCM токен пользователя
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final String? fcmToken = userDoc.data()?['fcmToken'];
      if (fcmToken == null) return;

      // TODO: Отправить уведомление через Firebase Admin SDK
      // Это должно быть реализовано на сервере
      debugPrint('📱 Would send notification to user $userId: $title');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  /// Создание уведомления в Firestore
  static Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? targetId,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'targetId': targetId,
        'data': data ?? {},
        'read': false,
        'createdAt': Timestamp.now(),
      });

      debugPrint('📱 Notification created for user $userId');
    } catch (e) {
      debugPrint('❌ Error creating notification: $e');
    }
  }

  /// Подписка на топик
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('📱 Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Отписка от топика
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('📱 Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Получение текущего токена
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('❌ Error getting token: $e');
      return null;
    }
  }

  /// Удаление токена
  static Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      debugPrint('📱 FCM token deleted');
    } catch (e) {
      debugPrint('❌ Error deleting token: $e');
    }
  }
}

/// Обработчик уведомлений в фоне (должен быть глобальной функцией)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService._firebaseMessagingBackgroundHandler(message);
}