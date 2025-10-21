import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

/// Сервис для работы с Firebase Cloud Messaging
class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Инициализация FCM
  static Future<void> initialize() async {
    // Настройка локальных уведомлений
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
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

    // Настройка обработчиков сообщений
    _setupMessageHandlers();

    // Получение токена
    await _getToken();
  }

  /// Запрос разрешений на уведомления
  static Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission();

    debugPrint('Разрешения на уведомления: ${settings.authorizationStatus}');
  }

  /// Настройка обработчиков сообщений
  static void _setupMessageHandlers() {
    // Обработка сообщений в foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Обработка сообщений в background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Обработка нажатий на уведомления (когда приложение в фоне)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Обработка нажатий на уведомления (когда приложение закрыто)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _saveNotificationToHistory(message);
        _handleNotificationTap(message);
      }
    });
  }

  /// Обработка сообщений в foreground
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint(
      '📬 Получено уведомление в foreground: ${message.notification?.title}',
    );

    // Сохраняем уведомление в историю
    await _saveNotificationToHistory(message);

    final notification = message.notification;
    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'event_channel',
            'Event Marketplace',
            channelDescription: 'Уведомления от Event Marketplace',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: _getNotificationColor(message.data['type'] ?? 'system'),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: _createPayload(message.data),
      );
    }
  }

  /// Обработка нажатий на уведомления
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Нажато на уведомление: ${message.notification?.title}');

    final data = message.data;
    if (data.containsKey('type')) {
      _navigateToScreen(data['type'], data);
    }
  }

  /// Обработка нажатий на локальные уведомления
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Нажато на локальное уведомление: ${response.payload}');

    if (response.payload != null) {
      _navigateToScreenFromPayload(response.payload!);
    }
  }

  /// Навигация к экрану на основе типа уведомления
  static void _navigateToScreen(String type, Map<String, dynamic> data) {
    debugPrint('Навигация к экрану типа: $type с данными: $data');

    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (type) {
      case 'chat':
        final chatId = data['id'] ?? data['chatId'];
        if (chatId != null) {
          context.push('/chat/$chatId');
        }
        break;
      case 'post':
        final postId = data['id'] ?? data['postId'];
        if (postId != null) {
          context.push('/post/$postId');
        }
        break;
      case 'request':
        final requestId = data['id'] ?? data['requestId'];
        if (requestId != null) {
          context.push('/request/$requestId');
        } else {
          context.go('/requests');
        }
        break;
      case 'profile':
        final userId = data['id'] ?? data['userId'];
        if (userId != null) {
          context.push('/profile/$userId');
        }
        break;
      case 'like':
      case 'comment':
        final postId = data['id'] ?? data['postId'];
        if (postId != null) {
          context.push('/post/$postId');
        }
        break;
      case 'follow':
        final userId = data['id'] ?? data['userId'];
        if (userId != null) {
          context.push('/profile/$userId');
        }
        break;
      default:
        context.go('/notifications');
    }
  }

  /// Навигация к экрану на основе payload
  static void _navigateToScreenFromPayload(String payload) {
    try {
      final data = <String, dynamic>{};
      final pairs = payload.split('&');
      for (final pair in pairs) {
        final keyValue = pair.split('=');
        if (keyValue.length == 2) {
          data[keyValue[0]] = keyValue[1];
        }
      }

      if (data.containsKey('type')) {
        _navigateToScreen(data['type'], data);
      }
    } on Exception catch (e) {
      debugPrint('Ошибка парсинга payload: $e');
    }
  }

  /// Получение FCM токена
  static Future<String?> _getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } on Exception catch (e) {
      debugPrint('Ошибка получения FCM токена: $e');
      return null;
    }
  }

  /// Сохранение токена пользователя в Firestore
  static Future<void> saveUserToken(String userId) async {
    try {
      final token = await _getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM токен сохранён для пользователя: $userId');
      }
    } on Exception catch (e) {
      debugPrint('Ошибка сохранения FCM токена: $e');
    }
  }

  /// Отправка уведомления пользователю
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Получаем токен пользователя
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken'];

      if (fcmToken != null) {
        // TODO: Отправка через Firebase Admin SDK или Cloud Functions
        debugPrint('Отправка уведомления пользователю $userId: $title');

        // Создаем уведомление в Firestore
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId,
          'title': title,
          'body': body,
          'type': type,
          'data': data,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on Exception catch (e) {
      debugPrint('Ошибка отправки уведомления: $e');
    }
  }

  /// Подписка на топик
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Подписались на топик: $topic');
    } on Exception catch (e) {
      debugPrint('Ошибка подписки на топик: $e');
    }
  }

  /// Отписка от топика
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Отписались от топика: $topic');
    } on Exception catch (e) {
      debugPrint('Ошибка отписки от топика: $e');
    }
  }

  /// Сохранение уведомления в историю
  static Future<void> _saveNotificationToHistory(RemoteMessage message) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final notification = message.notification;
      final data = message.data;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications_history')
          .add({
        'title': notification?.title ?? '',
        'body': notification?.body ?? '',
        'type': data['type'] ?? 'system',
        'targetId': data['id'] ?? data['targetId'] ?? '',
        'senderId': data['senderId'] ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'isPinned': false,
        'data': data,
      });

      debugPrint('Уведомление сохранено в историю для пользователя: $userId');
    } on Exception catch (e) {
      debugPrint('Ошибка сохранения уведомления в историю: $e');
    }
  }

  /// Создание payload для локальных уведомлений
  static String _createPayload(Map<String, dynamic> data) {
    final payload = <String>[];
    data.forEach((key, value) {
      payload.add('$key=$value');
    });
    return payload.join('&');
  }

  /// Получение цвета для типа уведомления
  static Color _getNotificationColor(String type) {
    switch (type) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.blue;
      case 'follow':
        return Colors.green;
      case 'request':
        return Colors.orange;
      case 'message':
        return Colors.purple;
      case 'booking':
        return Colors.teal;
      case 'system':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}

/// Обработчик фоновых сообщений
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Получено уведомление в фоне: ${message.notification?.title}');

  // Firebase initialization is handled in Bootstrap; avoid duplicate init here
  try {
    Firebase.app();
  } catch (_) {
    // As a last resort (isolates), initialize only if really missing
    await Firebase.initializeApp();
  }

  // Сохраняем уведомление в историю
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final notification = message.notification;
      final data = message.data;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications_history')
          .add({
        'title': notification?.title ?? '',
        'body': notification?.body ?? '',
        'type': data['type'] ?? 'system',
        'targetId': data['id'] ?? data['targetId'] ?? '',
        'senderId': data['senderId'] ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'isPinned': false,
        'data': data,
      });
    }
  } catch (e) {
    debugPrint('Ошибка сохранения фонового уведомления: $e');
  }
}
