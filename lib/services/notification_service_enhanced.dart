import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Улучшенный сервис уведомлений
class NotificationServiceEnhanced {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;
  static String? _fcmToken;
  
  /// Инициализировать сервис уведомлений
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Настройка локальных уведомлений
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
      
      // Получение FCM токена
      await _getFCMToken();
      
      // Настройка обработчиков сообщений
      _setupMessageHandlers();
      
      _isInitialized = true;
      debugPrint('✅ Notification service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
    }
  }
  
  /// Запросить разрешения на уведомления
  static Future<void> _requestPermissions() async {
    try {
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
    } catch (e) {
      debugPrint('❌ Error requesting notification permissions: $e');
    }
  }
  
  /// Получить FCM токен
  static Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        await _saveFCMToken(_fcmToken!);
        debugPrint('✅ FCM token obtained: ${_fcmToken!.substring(0, 20)}...');
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }
  
  /// Сохранить FCM токен
  static Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }
  
  /// Получить сохраненный FCM токен
  static Future<String?> getSavedFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      debugPrint('❌ Error getting saved FCM token: $e');
      return null;
    }
  }
  
  /// Настроить обработчики сообщений
  static void _setupMessageHandlers() {
    // Обработка сообщений в фоне
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Обработка сообщений в foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Обработка нажатий на уведомления
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }
  
  /// Обработать сообщение в foreground
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      debugPrint('📱 Received foreground message: ${message.messageId}');
      
      // Показать локальное уведомление
      await _showLocalNotification(message);
    } catch (e) {
      debugPrint('❌ Error handling foreground message: $e');
    }
  }
  
  /// Обработать нажатие на уведомление
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    try {
      debugPrint('📱 Notification tapped: ${message.messageId}');
      
      // Здесь можно добавить навигацию к соответствующему экрану
      final data = message.data;
      if (data.containsKey('route')) {
        // NavigationService.safeGo(context, data['route']);
      }
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
  }
  
  /// Показать локальное уведомление
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'event_marketplace_channel',
        'Event Marketplace Notifications',
        channelDescription: 'Уведомления от Event Marketplace',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Event Marketplace',
        message.notification?.body ?? 'Новое уведомление',
        notificationDetails,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }
  
  /// Обработать нажатие на локальное уведомление
  static void _onNotificationTapped(NotificationResponse response) {
    try {
      debugPrint('📱 Local notification tapped: ${response.payload}');
      
      if (response.payload != null) {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        if (data.containsKey('route')) {
          // NavigationService.safeGo(context, data['route']);
        }
      }
    } catch (e) {
      debugPrint('❌ Error handling local notification tap: $e');
    }
  }
  
  /// Показать локальное уведомление
  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
    String? channelName,
    String? channelDescription,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId ?? 'default_channel',
        channelName ?? 'Default Notifications',
        channelDescription: channelDescription ?? 'Default notification channel',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }
  
  /// Показать уведомление о новом сообщении
  static Future<void> showMessageNotification({
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    await showLocalNotification(
      id: chatId.hashCode,
      title: 'Новое сообщение от $senderName',
      body: message,
      payload: jsonEncode({'route': '/chat/$chatId', 'type': 'message'}),
      channelId: 'messages',
      channelName: 'Сообщения',
      channelDescription: 'Уведомления о новых сообщениях',
    );
  }
  
  /// Показать уведомление о новой заявке
  static Future<void> showRequestNotification({
    required String requestTitle,
    required String requestId,
  }) async {
    await showLocalNotification(
      id: requestId.hashCode,
      title: 'Новая заявка',
      body: requestTitle,
      payload: jsonEncode({'route': '/requests/$requestId', 'type': 'request'}),
      channelId: 'requests',
      channelName: 'Заявки',
      channelDescription: 'Уведомления о заявках',
    );
  }
  
  /// Показать уведомление о новой идее
  static Future<void> showIdeaNotification({
    required String ideaTitle,
    required String ideaId,
  }) async {
    await showLocalNotification(
      id: ideaId.hashCode,
      title: 'Новая идея',
      body: ideaTitle,
      payload: jsonEncode({'route': '/ideas/$ideaId', 'type': 'idea'}),
      channelId: 'ideas',
      channelName: 'Идеи',
      channelDescription: 'Уведомления о новых идеях',
    );
  }
  
  /// Показать системное уведомление
  static Future<void> showSystemNotification({
    required String title,
    required String body,
    String? route,
  }) async {
    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      payload: route != null ? jsonEncode({'route': route, 'type': 'system'}) : null,
      channelId: 'system',
      channelName: 'Системные уведомления',
      channelDescription: 'Системные уведомления приложения',
    );
  }
  
  /// Отменить уведомление
  static Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
    } catch (e) {
      debugPrint('❌ Error canceling notification: $e');
    }
  }
  
  /// Отменить все уведомления
  static Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      debugPrint('❌ Error canceling all notifications: $e');
    }
  }
  
  /// Получить количество непрочитанных уведомлений
  static Future<int> getUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('unread_notifications_count') ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting unread count: $e');
      return 0;
    }
  }
  
  /// Установить количество непрочитанных уведомлений
  static Future<void> setUnreadCount(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('unread_notifications_count', count);
    } catch (e) {
      debugPrint('❌ Error setting unread count: $e');
    }
  }
  
  /// Увеличить количество непрочитанных уведомлений
  static Future<void> incrementUnreadCount() async {
    try {
      final currentCount = await getUnreadCount();
      await setUnreadCount(currentCount + 1);
    } catch (e) {
      debugPrint('❌ Error incrementing unread count: $e');
    }
  }
  
  /// Сбросить количество непрочитанных уведомлений
  static Future<void> resetUnreadCount() async {
    try {
      await setUnreadCount(0);
    } catch (e) {
      debugPrint('❌ Error resetting unread count: $e');
    }
  }
  
  /// Проверить, включены ли уведомления
  static Future<bool> areNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('notifications_enabled') ?? true;
    } catch (e) {
      debugPrint('❌ Error checking notification settings: $e');
      return true;
    }
  }
  
  /// Включить/выключить уведомления
  static Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', enabled);
    } catch (e) {
      debugPrint('❌ Error setting notification settings: $e');
    }
  }
  
  /// Получить FCM токен
  static String? getFCMToken() {
    return _fcmToken;
  }
  
  /// Обновить FCM токен
  static Future<void> refreshFCMToken() async {
    try {
      await _getFCMToken();
    } catch (e) {
      debugPrint('❌ Error refreshing FCM token: $e');
    }
  }
}

/// Обработчик сообщений в фоне
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 Background message received: ${message.messageId}');
  // Здесь можно добавить обработку фоновых сообщений
}
