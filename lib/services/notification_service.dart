import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Сервис для работы с push-уведомлениями
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Инициализация сервиса уведомлений
  Future<void> initialize() async {
    // Запрашиваем разрешение на уведомления
    await _requestPermission();

    // Настраиваем обработчики уведомлений
    _setupMessageHandlers();
  }

  /// Запрос разрешения на уведомления
  Future<bool> _requestPermission() async {
    final settings = await _messaging.requestPermission();

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Настройка обработчиков сообщений
  void _setupMessageHandlers() {
    // Обработка уведомлений в фоновом режиме
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Обработка уведомлений в активном режиме
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Обработка нажатий на уведомления
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  /// Обработка сообщений в фоновом режиме
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    print('Обработка фонового сообщения: ${message.messageId}');
  }

  /// Обработка сообщений в активном режиме
  void _handleForegroundMessage(RemoteMessage message) {
    print('Получено сообщение в активном режиме: ${message.messageId}');
    // Здесь можно показать локальное уведомление
  }

  /// Обработка нажатий на уведомления
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Нажатие на уведомление: ${message.messageId}');
    // Здесь можно обработать навигацию
  }

  /// Отправить уведомление пользователю
  Future<void> sendNotification(
    String userId,
    String title,
    String body, {
    Map<String, String>? data,
  }) async {
    try {
      // Получаем FCM токен пользователя
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Пользователь не найден');
      }

      final userData = userDoc.data()!;
      final fcmToken = userData['fcmToken'] as String?;

      if (fcmToken == null) {
        throw Exception('FCM токен пользователя не найден');
      }

      // Вызываем Cloud Function для отправки уведомления
      await _functions.httpsCallable('sendNotification').call({
        'token': fcmToken,
        'title': title,
        'body': body,
        'data': data ?? {},
      });
    } catch (e) {
      throw Exception('Ошибка отправки уведомления: $e');
    }
  }

  /// Отправить уведомление о новой заявке
  Future<void> sendNewBookingNotification(
    String specialistId,
    String customerName,
  ) async {
    await sendNotification(
      specialistId,
      'Новая заявка',
      'У вас новая заявка от $customerName',
      data: {
        'type': 'new_booking',
        'customerName': customerName,
      },
    );
  }

  /// Отправить уведомление о подтверждении заявки
  Future<void> sendBookingConfirmedNotification(
    String customerId,
    String specialistName,
  ) async {
    await sendNotification(
      customerId,
      'Заявка подтверждена',
      'Ваша заявка подтверждена специалистом $specialistName',
      data: {
        'type': 'booking_confirmed',
        'specialistName': specialistName,
      },
    );
  }

  /// Отправить уведомление об отклонении заявки
  Future<void> sendBookingRejectedNotification(
    String customerId,
    String specialistName,
  ) async {
    await sendNotification(
      customerId,
      'Заявка отклонена',
      'К сожалению, ваша заявка отклонена специалистом $specialistName',
      data: {
        'type': 'booking_rejected',
        'specialistName': specialistName,
      },
    );
  }

  /// Отправить уведомление о новом сообщении в чате
  Future<void> sendChatMessageNotification(
    String receiverId,
    String senderName,
    String message,
  ) async {
    await sendNotification(
      receiverId,
      'Новое сообщение от $senderName',
      message.length > 50 ? '${message.substring(0, 50)}...' : message,
      data: {
        'type': 'chat_message',
        'senderName': senderName,
      },
    );
  }

  /// Сохранить FCM токен пользователя
  Future<void> saveUserFCMToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      throw Exception('Ошибка сохранения FCM токена: $e');
    }
  }

  /// Получить FCM токен пользователя
  Future<String?> getUserFCMToken(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return userData['fcmToken'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения FCM токена: $e');
    }
  }

  /// Обновить FCM токен при изменении
  void setupTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      // Здесь можно обновить токен в базе данных
      print('FCM токен обновлен: $newToken');
    });
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

  /// Отправить уведомление всем пользователям топика
  Future<void> sendTopicNotification(
    String topic,
    String title,
    String body, {
    Map<String, String>? data,
  }) async {
    try {
      await _functions.httpsCallable('sendTopicNotification').call({
        'topic': topic,
        'title': title,
        'body': body,
        'data': data ?? {},
      });
    } catch (e) {
      throw Exception('Ошибка отправки уведомления в топик: $e');
    }
  }

  /// Получить текущий FCM токен
  Future<String?> getCurrentToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      throw Exception('Ошибка получения текущего токена: $e');
    }
  }

  /// Проверить, разрешены ли уведомления
  Future<bool> isNotificationPermissionGranted() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Открыть настройки уведомлений
  Future<void> openNotificationSettings() async {
    // В Flutter можно использовать url_launcher для открытия настроек
    // await launch('app-settings:');
  }
}
