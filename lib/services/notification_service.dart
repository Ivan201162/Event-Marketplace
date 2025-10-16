import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';
import '../models/transaction.dart' as transaction_model;
import '../models/subscription_plan.dart';
import '../models/promotion_boost.dart';
import '../models/advertisement.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Инициализация сервиса уведомлений
  static Future<void> initialize() async {
    try {
      // Запрос разрешений на уведомления
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('INFO: [NotificationService] Permission status: ${settings.authorizationStatus}');

      // Получение FCM токена
      final String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('INFO: [NotificationService] FCM Token: $token');
        await _saveFCMToken(token);
      }

      // Обработка уведомлений в фоне
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Обработка уведомлений в foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Обработка нажатий на уведомления
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      debugPrint('INFO: [NotificationService] Initialized successfully');
    } catch (e) {
      debugPrint('ERROR: [NotificationService] Initialization failed: $e');
    }
  }

  /// Сохранение FCM токена пользователя
  static Future<void> _saveFCMToken(String token) async {
    try {
      // Здесь нужно получить ID текущего пользователя
      // Для демонстрации используем фиксированный ID
      const String userId = 'current_user_id'; // TODO: Получить из AuthService
      
      await _firestore.collection('user_tokens').doc(userId).set({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': 'android', // или 'ios'
      });
    } catch (e) {
      debugPrint('ERROR: [NotificationService] Failed to save FCM token: $e');
    }
  }

  /// Обработка уведомлений в фоне
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    debugPrint('INFO: [NotificationService] Background message: ${message.messageId}');
    debugPrint('INFO: [NotificationService] Data: ${message.data}');
  }

  /// Обработка уведомлений в foreground
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('INFO: [NotificationService] Foreground message: ${message.messageId}');
    debugPrint('INFO: [NotificationService] Title: ${message.notification?.title}');
    debugPrint('INFO: [NotificationService] Body: ${message.notification?.body}');
    debugPrint('INFO: [NotificationService] Data: ${message.data}');

    // Здесь можно показать in-app уведомление
    _showInAppNotification(message);
  }

  /// Обработка нажатий на уведомления
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('INFO: [NotificationService] Notification tapped: ${message.messageId}');
    debugPrint('INFO: [NotificationService] Data: ${message.data}');

    // Навигация на соответствующий экран
    _navigateFromNotification(message.data);
  }

  /// Показ in-app уведомления
  static void _showInAppNotification(RemoteMessage message) {
    // TODO: Реализовать показ in-app уведомления
    // Можно использовать Overlay или SnackBar
  }

  /// Навигация на основе данных уведомления
  static void _navigateFromNotification(Map<String, dynamic> data) {
    // TODO: Реализовать навигацию на основе типа уведомления
    final String? type = data['type'];
    final String? id = data['id'];

    switch (type) {
      case 'subscription':
        // Навигация к подпискам
        break;
      case 'promotion':
        // Навигация к продвижениям
        break;
      case 'advertisement':
        // Навигация к рекламе
        break;
      case 'payment':
        // Навигация к транзакциям
        break;
    }
  }

  /// Отправка уведомления о успешной оплате
  static Future<void> sendPaymentSuccessNotification({
    required String userId,
    required transaction_model.Transaction transaction,
  }) async {
    try {
      final AppNotification notification = AppNotification(
        id: 'payment_success_${transaction.id}',
        userId: userId,
        type: NotificationType.payment.toString(),
        title: 'Платеж успешно обработан',
        body: 'Ваш платеж на сумму ${transaction.amount} ${transaction.currency} успешно обработан.',
        data: {
          'transactionId': transaction.id,
          'amount': transaction.amount,
          'currency': transaction.currency,
          'type': transaction.type.toString(),
        },
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _createNotification(notification);
      await _sendPushNotification(
        userId: userId,
        title: notification.title,
        body: notification.body,
        data: notification.data,
      );
    } catch (e) {
      debugPrint('ERROR: [NotificationService] Failed to send payment success notification: $e');
    }
  }

  /// Отправка уведомления о активации подписки
  static Future<void> sendSubscriptionActivatedNotification({
    required String userId,
    required UserSubscription subscription,
  }) async {
    try {
      final AppNotification notification = AppNotification(
        id: 'subscription_activated_${subscription.id}',
        userId: userId,
        type: NotificationType.subscription.toString(),
        title: 'Подписка активирована',
        body: 'Ваша подписка успешно активирована и действует до ${subscription.endDate.toLocal().toString().split(' ')[0]}.',
        data: {
          'subscriptionId': subscription.id,
          'planId': subscription.planId,
          'endDate': subscription.endDate.toIso8601String(),
        },
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _createNotification(notification);
      await _sendPushNotification(
        userId: userId,
        title: notification.title,
        body: notification.body,
        data: notification.data,
      );
    } catch (e) {
      debugPrint('ERROR: [NotificationService] Failed to send subscription activated notification: $e');
    }
  }

  /// Отправка уведомления о истечении подписки
  static Future<void> sendSubscriptionExpiringNotification({
    required String userId,
    required UserSubscription subscription,
    required int daysLeft,
  }) async {
    try {
      final AppNotification notification = AppNotification(
        id: 'subscription_expiring_${subscription.id}',
        userId: userId,
        type: NotificationType.subscription.toString(),
        title: 'Подписка истекает',
        body: 'Ваша подписка истекает через $daysLeft ${_getDaysText(daysLeft)}. Продлите её, чтобы сохранить доступ к премиум-функциям.',
        data: {
          'subscriptionId': subscription.id,
          'planId': subscription.planId,
          'daysLeft': daysLeft,
          'endDate': subscription.endDate.toIso8601String(),
        },
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _createNotification(notification);
      await _sendPushNotification(
        userId: userId,
        title: notification.title,
        body: notification.body,
        data: notification.data,
      );
    } catch (e) {
      debugPrint('ERROR: [NotificationService] Failed to send subscription expiring notification: $e');
    }
  }

  /// Отправка уведомления о активации продвижения
  static Future<void> sendPromotionActivatedNotification({
    required String userId,
    required PromotionBoost promotion,
  }) async {
    try {
      final AppNotification notification = AppNotification(
        id: 'promotion_activated_${promotion.id}',
        userId: userId,
        type: NotificationType.promotion.toString(),
        title: 'Продвижение активировано',
        body: 'Ваше продвижение успешно активировано и будет действовать до ${promotion.endDate.toLocal().toString().split(' ')[0]}.',
        data: {
          'promotionId': promotion.id,
          'targetType': promotion.type.toString(),
          'priorityLevel': promotion.priorityLevel,
          'endDate': promotion.endDate.toIso8601String(),
        },
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _createNotification(notification);
      await _sendPushNotification(
        userId: userId,
        title: notification.title,
        body: notification.body,
        data: notification.data,
      );
    } catch (e) {
      debugPrint('ERROR: [NotificationService] Failed to send promotion activated notification: $e');
    }
  }

  /// Отправка уведомления о модерации рекламы
  static Future<void> sendAdvertisementModerationNotification({
    required String userId,
    required Advertisement advertisement,
    required AdStatus status,
  }) async {
    try {
      String title;
      String message;

      switch (status) {
        case AdStatus.active:
          title = 'Реклама одобрена';
          message = 'Ваша реклама "${advertisement.title}" одобрена и теперь показывается пользователям.';
          break;
        case AdStatus.rejected:
          title = 'Реклама отклонена';
          message = 'Ваша реклама "${advertisement.title}" была отклонена модератором. Проверьте соответствие правилам платформы.';
          break;
        default:
          title = 'Статус рекламы изменен';
          message = 'Статус вашей рекламы "${advertisement.title}" изменен на ${status.toString().split('.').last}.';
      }

      final AppNotification notification = AppNotification(
        id: 'advertisement_moderation_${advertisement.id}',
        userId: userId,
        type: NotificationType.advertisement.toString(),
        title: title,
        body: message,
        data: {
          'advertisementId': advertisement.id,
          'title': advertisement.title,
          'status': status.toString(),
          'type': advertisement.type.toString(),
        },
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _createNotification(notification);
      await _sendPushNotification(
        userId: userId,
        title: notification.title,
        body: notification.body,
        data: notification.data,
      );
    } catch (e) {
      debugPrint('ERROR: [NotificationService] Failed to send advertisement moderation notification: $e');
    }
  }

  /// Создание уведомления в Firestore
  static Future<void> _createNotification(AppNotification notification) async {
    try {
      await _firestore.collection('notifications').doc(notification.id).set(notification.toMap());
    } catch (e) {
      debugPrint('ERROR: [NotificationService] Failed to create notification: $e');
    }
  }

  /// Отправка push уведомления через FCM
  static Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Получаем FCM токен пользователя
      final DocumentSnapshot tokenDoc = await _firestore.collection('user_tokens').doc(userId).get();
      
      if (!tokenDoc.exists) {
        debugPrint('WARNING: [NotificationService] No FCM token found for user $userId');
        return;
      }

      final Map<String, dynamic>? data = tokenDoc.data() as Map<String, dynamic>?;
      final String? token = data?['token'] as String?;
      if (token == null) {
        debugPrint('WARNING: [NotificationService] Invalid FCM token for user $userId');
        return;
      }

      // Отправляем уведомление через Cloud Functions
      // В реальном приложении это должно быть реализовано через Cloud Functions
      debugPrint('INFO: [NotificationService] Would send push notification to token: $token');
      debugPrint('INFO: [NotificationService] Title: $title');
      debugPrint('INFO: [NotificationService] Body: $body');
      debugPrint('INFO: [NotificationService] Data: $data');
    } catch (e) {
      debugPrint('ERROR: [NotificationService] Failed to send push notification: $e');
    }
  }

  /// Получение уведомлений пользователя
  static Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromMap(doc.data()))
            .toList());
  }

  /// Отметка уведомления как прочитанного
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('ERROR: [NotificationService] Failed to mark notification as read: $e');
    }
  }

  /// Удаление уведомления
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      debugPrint('ERROR: [NotificationService] Failed to delete notification: $e');
    }
  }

  /// Вспомогательный метод для склонения слова "день"
  static String _getDaysText(int days) {
    if (days == 1) return 'день';
    if (days >= 2 && days <= 4) return 'дня';
    return 'дней';
  }
}