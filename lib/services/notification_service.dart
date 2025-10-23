import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Сервис для работы с уведомлениями
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Инициализация сервиса уведомлений
  Future<void> initialize() async {
    try {
      // Инициализация локальных уведомлений
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(initSettings);

      // Запрос разрешений
      await _requestPermissions();

      // Настройка обработчиков
      await _setupMessageHandlers();

      // Получение токена
      await _getFCMToken();
    } catch (e) {
      print('Ошибка инициализации уведомлений: $e');
    }
  }

  /// Запрос разрешений на уведомления
  Future<void> _requestPermissions() async {
    try {
      // Запрос разрешений для FCM
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('Статус разрешений: ${settings.authorizationStatus}');

      // Запрос разрешений для локальных уведомлений
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      print('Ошибка запроса разрешений: $e');
    }
  }

  /// Настройка обработчиков сообщений
  Future<void> _setupMessageHandlers() async {
    try {
      // Обработка сообщений в фоне
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Обработка сообщений в активном состоянии
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Обработка нажатий на уведомления
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    } catch (e) {
      print('Ошибка настройки обработчиков: $e');
    }
  }

  /// Получение FCM токена
  Future<String?> _getFCMToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
      return token;
    } catch (e) {
      print('Ошибка получения FCM токена: $e');
      return null;
    }
  }

  /// Сохранение токена в Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Ошибка сохранения токена: $e');
    }
  }

  /// Обработка сообщений в активном состоянии
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      print(
          'Получено сообщение в активном состоянии: ${message.notification?.title}');

      // Показ локального уведомления
      await _showLocalNotification(message);
    } catch (e) {
      print('Ошибка обработки сообщения в активном состоянии: $e');
    }
  }

  /// Обработка нажатий на уведомления
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    try {
      print('Нажато на уведомление: ${message.notification?.title}');

      // Обработка навигации в зависимости от типа уведомления
      final data = message.data;
      if (data['type'] == 'chat') {
        // Навигация к чату
        print('Навигация к чату: ${data['chatId']}');
      } else if (data['type'] == 'request') {
        // Навигация к заявке
        print('Навигация к заявке: ${data['requestId']}');
      }
    } catch (e) {
      print('Ошибка обработки нажатия на уведомление: $e');
    }
  }

  /// Показ локального уведомления
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'event_marketplace_channel',
        'Event Marketplace Notifications',
        channelDescription: 'Уведомления от Event Marketplace',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Event Marketplace',
        message.notification?.body ?? '',
        details,
        payload: message.data.toString(),
      );
    } catch (e) {
      print('Ошибка показа локального уведомления: $e');
    }
  }

  /// Отправка уведомления пользователю
  Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Получение токена пользователя
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final fcmToken = userData['fcmToken'] as String?;
      if (fcmToken == null) return false;

      // Отправка уведомления через Cloud Functions
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'fcmToken': fcmToken,
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });

      return true;
    } catch (e) {
      print('Ошибка отправки уведомления: $e');
      return false;
    }
  }

  /// Отправка уведомления о новом сообщении
  Future<bool> sendChatNotification({
    required String chatId,
    required String senderId,
    required String message,
  }) async {
    try {
      // Получение информации о чате
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) return false;

      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants'] ?? []);

      // Найти получателя (не отправителя)
      final recipientId = participants.firstWhere(
        (id) => id != senderId,
        orElse: () => '',
      );

      if (recipientId.isEmpty) return false;

      return await sendNotificationToUser(
        userId: recipientId,
        title: 'Новое сообщение',
        body: message,
        data: {
          'type': 'chat',
          'chatId': chatId,
          'senderId': senderId,
        },
      );
    } catch (e) {
      print('Ошибка отправки уведомления о сообщении: $e');
      return false;
    }
  }

  /// Отправка уведомления о новой заявке
  Future<bool> sendRequestNotification({
    required String requestId,
    required String specialistId,
    required String title,
  }) async {
    try {
      return await sendNotificationToUser(
        userId: specialistId,
        title: 'Новая заявка',
        body: title,
        data: {
          'type': 'request',
          'requestId': requestId,
        },
      );
    } catch (e) {
      print('Ошибка отправки уведомления о заявке: $e');
      return false;
    }
  }

  /// Отправка уведомления о новом отзыве
  Future<bool> sendReviewNotification({
    required String specialistId,
    required String reviewerName,
    required double rating,
  }) async {
    try {
      return await sendNotificationToUser(
        userId: specialistId,
        title: 'Новый отзыв',
        body: '$reviewerName поставил оценку $rating',
        data: {
          'type': 'review',
          'specialistId': specialistId,
        },
      );
    } catch (e) {
      print('Ошибка отправки уведомления об отзыве: $e');
      return false;
    }
  }

  /// Получение истории уведомлений
  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Ошибка получения истории уведомлений: $e');
      return [];
    }
  }

  /// Отметка уведомления как прочитанного
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Ошибка отметки уведомления как прочитанного: $e');
      return false;
    }
  }

  /// Очистка старых уведомлений
  Future<void> clearOldNotifications() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));

      final querySnapshot = await _firestore
          .collection('notifications')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Ошибка очистки старых уведомлений: $e');
    }
  }

  /// Получение уведомлений для пользователя
  Future<List<Map<String, dynamic>>> getNotificationsForUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Ошибка получения уведомлений: $e');
      return [];
    }
  }

  /// Получение количества непрочитанных уведомлений
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Ошибка получения количества непрочитанных: $e');
      return 0;
    }
  }

  /// Удаление уведомления
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Ошибка удаления уведомления: $e');
    }
  }

  /// Отметить все уведомления как прочитанные
  Future<void> markAllNotificationsAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Ошибка отметки уведомлений как прочитанных: $e');
    }
  }

  /// Получить поток уведомлений для пользователя
  Stream<List<AppNotification>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromMap(doc.data()))
            .toList());
  }

  /// Отметить уведомление как прочитанное
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Ошибка отметки уведомления как прочитанного: $e');
    }
  }

  /// Отметить все уведомления как прочитанные для пользователя
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Ошибка отметки всех уведомлений как прочитанных: $e');
    }
  }
}

/// Обработчик сообщений в фоне
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    print('Получено сообщение в фоне: ${message.notification?.title}');

    // Обработка фоновых сообщений
    // Здесь можно добавить логику для обработки данных
  } catch (e) {
    print('Ошибка обработки фонового сообщения: $e');
  }
}
