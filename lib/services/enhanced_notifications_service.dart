import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/enhanced_notification.dart';

/// Сервис для работы с расширенными уведомлениями
class EnhancedNotificationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Инициализация сервиса уведомлений
  Future<void> initialize() async {
    // Инициализация локальных уведомлений
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettingsIOS = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
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
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // iOS
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Firebase Messaging
    final settings = await _messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Уведомления разрешены');
    } else {
      debugPrint('Уведомления не разрешены');
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

  /// Обработка нажатия на уведомление
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Обработка нажатия на локальное уведомление
    debugPrint('Нажато на уведомление: ${response.payload}');
  }

  /// Обработка сообщения в foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Получено сообщение в foreground: ${message.messageId}');

    // Показать локальное уведомление
    _showLocalNotification(
      title: message.notification?.title ?? 'Новое уведомление',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// Обработка нажатия на уведомление
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Нажато на уведомление: ${message.messageId}');
    // TODO: Навигация к соответствующему экрану
  }

  /// Показать локальное уведомление
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'event_marketplace',
      'Event Marketplace',
      channelDescription: 'Уведомления Event Marketplace',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Получить уведомления пользователя
  Future<List<EnhancedNotification>> getNotifications({
    required String userId,
    int limit = 50,
    DocumentSnapshot? lastDocument,
    bool includeArchived = false,
  }) async {
    try {
      Query query = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (!includeArchived) {
        query = query.where('isArchived', isEqualTo: false);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final notifications = <EnhancedNotification>[];

      for (final doc in snapshot.docs) {
        final notification =
            EnhancedNotification.fromMap(doc.data()! as Map<String, dynamic>);
        notifications.add(notification);
      }

      return notifications;
    } catch (e) {
      throw Exception('Ошибка загрузки уведомлений: $e');
    }
  }

  /// Получить непрочитанные уведомления
  Future<List<EnhancedNotification>> getUnreadNotifications({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final notifications = <EnhancedNotification>[];

      for (final doc in snapshot.docs) {
        final notification =
            EnhancedNotification.fromMap(doc.data()! as Map<String, dynamic>);
        notifications.add(notification);
      }

      return notifications;
    } catch (e) {
      throw Exception('Ошибка загрузки непрочитанных уведомлений: $e');
    }
  }

  /// Получить уведомление по ID
  Future<EnhancedNotification?> getNotificationById(
    String notificationId,
  ) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (doc.exists) {
        return EnhancedNotification.fromMap(
          doc.data()! as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка загрузки уведомления: $e');
    }
  }

  /// Создать уведомление
  Future<EnhancedNotification> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    NotificationPriority priority = NotificationPriority.normal,
    String? category,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    DateTime? expiresAt,
  }) async {
    try {
      final notificationId = _firestore.collection('notifications').doc().id;
      final now = DateTime.now();

      final notification = EnhancedNotification(
        id: notificationId,
        userId: userId,
        title: title,
        body: body,
        type: type,
        createdAt: now,
        data: data ?? {},
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        priority: priority,
        category: category,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        expiresAt: expiresAt,
      );

      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .set(notification.toMap());

      // Отправить push-уведомление
      await _sendPushNotification(notification);

      return notification;
    } catch (e) {
      throw Exception('Ошибка создания уведомления: $e');
    }
  }

  /// Отправить push-уведомление
  Future<void> _sendPushNotification(EnhancedNotification notification) async {
    try {
      // Получить FCM токен пользователя
      final userDoc =
          await _firestore.collection('users').doc(notification.userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final fcmToken = userData['fcmToken'] as String?;

        if (fcmToken != null) {
          // Отправить уведомление через FCM
          await _messaging.sendMessage(
            to: fcmToken,
            data: {
              'notificationId': notification.id,
              'type': notification.type.value,
              'actionUrl': notification.actionUrl ?? '',
            },
            notification: RemoteNotification(
              title: notification.title,
              body: notification.body,
              imageUrl: notification.imageUrl,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Ошибка отправки push-уведомления: $e');
    }
  }

  /// Отметить уведомление как прочитанное
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка отметки уведомления как прочитанного: $e');
    }
  }

  /// Отметить все уведомления как прочитанные
  Future<void> markAllAsRead(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Ошибка отметки всех уведомлений как прочитанных: $e');
    }
  }

  /// Архивировать уведомление
  Future<void> archiveNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка архивирования уведомления: $e');
    }
  }

  /// Удалить уведомление
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления уведомления: $e');
    }
  }

  /// Очистить все уведомления
  Future<void> clearAllNotifications(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Ошибка очистки всех уведомлений: $e');
    }
  }

  /// Получить статистику уведомлений
  Future<NotificationStats> getNotificationStats(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      var total = 0;
      var unread = 0;
      var archived = 0;
      final byType = <NotificationType, int>{};
      final byPriority = <NotificationPriority, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        total++;

        if (data['isRead'] == false) unread++;
        if (data['isArchived'] == true) archived++;

        final type = NotificationType.fromString(data['type'] as String);
        byType[type] = (byType[type] ?? 0) + 1;

        final priority = NotificationPriority.fromString(
          data['priority'] as String? ?? 'normal',
        );
        byPriority[priority] = (byPriority[priority] ?? 0) + 1;
      }

      return NotificationStats(
        total: total,
        unread: unread,
        archived: archived,
        byType: byType,
        byPriority: byPriority,
      );
    } catch (e) {
      throw Exception('Ошибка получения статистики уведомлений: $e');
    }
  }

  /// Подписаться на топик
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      throw Exception('Ошибка подписки на топик: $e');
    }
  }

  /// Отписаться от топика
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      throw Exception('Ошибка отписки от топика: $e');
    }
  }

  /// Получить FCM токен
  Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      throw Exception('Ошибка получения FCM токена: $e');
    }
  }

  /// Сохранить FCM токен пользователя
  Future<void> saveFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка сохранения FCM токена: $e');
    }
  }
}

/// Обработчик сообщений в фоне
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Обработка сообщения в фоне: ${message.messageId}');
  // TODO: Обработка сообщения в фоне
}
