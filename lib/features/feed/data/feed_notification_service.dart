import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/utils/debug_utils.dart';

/// Сервис уведомлений для ленты
class FeedNotificationService {
  factory FeedNotificationService() => _instance;
  FeedNotificationService._internal();
  static final FeedNotificationService _instance = FeedNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Инициализация сервиса уведомлений
  Future<void> initialize() async {
    // Инициализация локальных уведомлений
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Запрос разрешений
    await _requestPermissions();

    // Настройка обработчиков сообщений
    _setupMessageHandlers();
  }

  /// Запрос разрешений на уведомления
  Future<void> _requestPermissions() async {
    // Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // iOS
    await _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Firebase Messaging
    final settings = await _messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Пользователь предоставил разрешение на уведомления');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('Пользователь предоставил временное разрешение на уведомления');
    } else {
      debugPrint('Пользователь отклонил или не предоставил разрешение на уведомления');
    }
  }

  /// Настройка обработчиков сообщений
  void _setupMessageHandlers() {
    // Обработка сообщений в фоне
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Обработка сообщений в foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Обработка нажатий на уведомления
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Обработка нажатия на локальное уведомление
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      _handleNotificationPayload(payload);
    }
  }

  /// Обработка сообщения в foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Получено сообщение в foreground: ${message.messageId}');

    // Показываем локальное уведомление
    await _showLocalNotification(
      title: message.notification?.title ?? 'Новое уведомление',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// Обработка нажатия на уведомление
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    debugPrint('Нажатие на уведомление: ${message.messageId}');
    _handleNotificationPayload(message.data.toString());
  }

  /// Обработка данных уведомления
  void _handleNotificationPayload(String payload) {
    // TODO(developer): Реализовать навигацию к соответствующему экрану
    debugPrint('Обработка payload: $payload');
  }

  /// Показать локальное уведомление
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'feed_channel',
      'Лента активности',
      channelDescription: 'Уведомления о новых постах в ленте',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Отправить уведомление о новом посте
  Future<void> sendNewPostNotification({
    required String postId,
    required String authorId,
    required String authorName,
    required String postDescription,
  }) async {
    try {
      // Получаем подписчиков автора
      final followers = await _getUserFollowers(authorId);

      if (followers.isEmpty) {
        return;
      }

      // Отправляем уведомления каждому подписчику
      for (final followerId in followers) {
        await _sendNotificationToUser(
          userId: followerId,
          title: 'Новый пост от $authorName',
          body: postDescription.length > 100
              ? '${postDescription.substring(0, 100)}...'
              : postDescription,
          data: {'type': 'new_post', 'postId': postId, 'authorId': authorId},
        );
      }
    } catch (e) {
      debugPrint('Ошибка отправки уведомления о новом посте: $e');
    }
  }

  /// Отправить уведомление о новом лайке
  Future<void> sendLikeNotification({
    required String postId,
    required String postAuthorId,
    required String likerId,
    required String likerName,
  }) async {
    try {
      // Не отправляем уведомление, если пользователь лайкнул свой пост
      if (postAuthorId == likerId) {
        return;
      }

      await _sendNotificationToUser(
        userId: postAuthorId,
        title: 'Новый лайк',
        body: '$likerName поставил лайк вашему посту',
        data: {'type': 'like', 'postId': postId, 'likerId': likerId},
      );
    } catch (e) {
      debugPrint('Ошибка отправки уведомления о лайке: $e');
    }
  }

  /// Отправить уведомление о новом комментарии
  Future<void> sendCommentNotification({
    required String postId,
    required String postAuthorId,
    required String commenterId,
    required String commenterName,
    required String commentText,
  }) async {
    try {
      // Не отправляем уведомление, если пользователь прокомментировал свой пост
      if (postAuthorId == commenterId) {
        return;
      }

      await _sendNotificationToUser(
        userId: postAuthorId,
        title: 'Новый комментарий',
        body:
            '$commenterName: ${commentText.length > 50 ? '${commentText.substring(0, 50)}...' : commentText}',
        data: {'type': 'comment', 'postId': postId, 'commenterId': commenterId},
      );
    } catch (e) {
      debugPrint('Ошибка отправки уведомления о комментарии: $e');
    }
  }

  /// Получить подписчиков пользователя
  Future<List<String>> _getUserFollowers(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return List<String>.from((userData['followers'] as List<dynamic>?) ?? []);
      }

      return [];
    } catch (e) {
      debugPrint('Ошибка получения подписчиков: $e');
      return [];
    }
  }

  /// Отправить уведомление конкретному пользователю
  Future<void> _sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Получаем FCM токен пользователя
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return;
      }

      final userData = userDoc.data()!;
      final fcmToken = userData['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        return;
      }

      // Отправляем уведомление через Cloud Functions
      await _firestore.collection('notifications').add({
        'userId': userId,
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'data': data,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      debugPrint('Ошибка отправки уведомления пользователю: $e');
    }
  }

  /// Сохранить FCM токен пользователя
  Future<void> saveUserFCMToken(String userId) async {
    try {
      final token = await _messaging.getToken();

      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Ошибка сохранения FCM токена: $e');
    }
  }

  /// Обновить FCM токен при изменении
  Future<void> setupTokenRefresh() async {
    _messaging.onTokenRefresh.listen((token) async {
      // TODO(developer): Обновить токен в базе данных для текущего пользователя
      debugPrint('FCM токен обновлен: $token');
    });
  }
}

/// Обработчик фоновых сообщений
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Обработка фонового сообщения: ${message.messageId}');
}
