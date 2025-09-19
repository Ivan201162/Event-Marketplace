import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/notification_template.dart';

/// Сервис уведомлений
class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final Uuid _uuid = const Uuid();

  static final NotificationService _instance = NotificationService._internal();

  /// Получить FCM токен
  Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Ошибка получения FCM токена: $e');
      return null;
    }
  }

  /// Отправить уведомление о бронировании
  Future<String> sendBookingNotification({
    required String userId,
    required String eventTitle,
    required String specialistName,
    required DateTime bookingDate,
    required NotificationChannel channel,
  }) async {
    return await sendNotification(
      userId: userId,
      title: 'Новое бронирование',
      body:
          'Ваше бронирование на $eventTitle с $specialistName подтверждено на ${bookingDate.toString()}',
      type: NotificationType.booking,
      channel: channel,
    );
  }

  /// Отправить уведомление об отмене
  Future<String> sendCancellationNotification({
    required String userId,
    required String eventTitle,
    required String specialistName,
    required DateTime bookingDate,
    required NotificationChannel channel,
  }) async {
    return await sendNotification(
      userId: userId,
      title: 'Бронирование отменено',
      body:
          'Ваше бронирование на $eventTitle с $specialistName на ${bookingDate.toString()} было отменено',
      type: NotificationType.cancellation,
      channel: channel,
    );
  }

  final StreamController<SentNotification> _notificationController =
      StreamController<SentNotification>.broadcast();

  /// Поток уведомлений
  Stream<SentNotification> get notificationStream =>
      _notificationController.stream;

  /// Инициализация сервиса уведомлений
  Future<void> initialize() async {
    try {
      // Запрашиваем разрешения на уведомления
      await _requestPermissions();

      // Настраиваем обработчики уведомлений
      _setupNotificationHandlers();

      // Создаем базовые шаблоны уведомлений
      await _createDefaultTemplates();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка инициализации сервиса уведомлений: $e');
      }
    }
  }

  /// Запросить разрешения на уведомления
  Future<void> _requestPermissions() async {
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

      if (kDebugMode) {
        print('Разрешения на уведомления: ${settings.authorizationStatus}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка запроса разрешений: $e');
      }
    }
  }

  /// Настроить обработчики уведомлений
  void _setupNotificationHandlers() {
    // Обработчик уведомлений в foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print(
          'Получено уведомление в foreground: ${message.notification?.title}',
        );
      }
      _handleForegroundMessage(message);
    });

    // Обработчик нажатия на уведомление
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Нажато на уведомление: ${message.notification?.title}');
      }
      _handleNotificationTap(message);
    });

    // Обработчик уведомления при закрытом приложении
    FirebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('Уведомление при запуске: ${message.notification?.title}');
        }
        _handleNotificationTap(message);
      }
    });
  }

  /// Обработать уведомление в foreground
  void _handleForegroundMessage(RemoteMessage message) {
    // TODO: Показать локальное уведомление
    if (kDebugMode) {
      print('Foreground message: ${message.notification?.title}');
    }
  }

  /// Обработать нажатие на уведомление
  void _handleNotificationTap(RemoteMessage message) {
    // TODO: Навигация к соответствующему экрану
    if (kDebugMode) {
      print('Notification tap: ${message.data}');
    }
  }

  /// Создать базовые шаблоны уведомлений
  Future<void> _createDefaultTemplates() async {
    try {
      final templates = [
        NotificationTemplate(
          id: 'booking_created',
          name: 'Новое бронирование',
          title: 'Новое бронирование',
          body: 'У вас новое бронирование от {{customerName}} на {{date}}',
          type: NotificationType.booking,
          channel: NotificationChannel.push,
          variables: {
            'customerName': 'Имя клиента',
            'date': 'Дата бронирования',
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        NotificationTemplate(
          id: 'payment_received',
          name: 'Получен платеж',
          title: 'Получен платеж',
          body: 'Получен платеж {{amount}} ₽ за бронирование {{bookingId}}',
          type: NotificationType.payment,
          channel: NotificationChannel.push,
          variables: {'amount': 'Сумма', 'bookingId': 'ID бронирования'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        NotificationTemplate(
          id: 'message_received',
          name: 'Новое сообщение',
          title: 'Новое сообщение',
          body: '{{senderName}}: {{message}}',
          type: NotificationType.message,
          channel: NotificationChannel.push,
          variables: {
            'senderName': 'Имя отправителя',
            'message': 'Текст сообщения',
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        NotificationTemplate(
          id: 'review_received',
          name: 'Новый отзыв',
          title: 'Новый отзыв',
          body: '{{customerName}} оставил отзыв: {{rating}} звезд',
          type: NotificationType.review,
          channel: NotificationChannel.push,
          variables: {'customerName': 'Имя клиента', 'rating': 'Рейтинг'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        NotificationTemplate(
          id: 'reminder_booking',
          name: 'Напоминание о бронировании',
          title: 'Напоминание',
          body: 'Через {{hours}} часов у вас бронирование с {{customerName}}',
          type: NotificationType.reminder,
          channel: NotificationChannel.push,
          variables: {
            'hours': 'Количество часов',
            'customerName': 'Имя клиента',
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final template in templates) {
        await _firestore
            .collection('notificationTemplates')
            .doc(template.id)
            .set(template.toMap());
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка создания базовых шаблонов: $e');
      }
    }
  }

  /// Отправить уведомление по шаблону
  Future<String> sendNotificationByTemplate({
    required String templateId,
    required String userId,
    required Map<String, String> variables,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Получаем шаблон
      final templateDoc = await _firestore
          .collection('notificationTemplates')
          .doc(templateId)
          .get();

      if (!templateDoc.exists) {
        throw Exception('Шаблон уведомления не найден');
      }

      final template = NotificationTemplate.fromDocument(templateDoc);

      if (!template.isActive) {
        throw Exception('Шаблон уведомления неактивен');
      }

      // Заменяем переменные
      final title = template.replaceTitleVariables(variables);
      final body = template.replaceVariables(variables);

      // Отправляем уведомление
      return await _sendNotification(
        userId: userId,
        title: title,
        body: body,
        type: template.type,
        channel: template.channel,
        data: data ?? {},
        templateId: templateId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка отправки уведомления по шаблону: $e');
      }
      rethrow;
    }
  }

  /// Отправить уведомление
  Future<String> sendNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    required NotificationChannel channel,
    Map<String, dynamic>? data,
    String? recipientId,
  }) async =>
      _sendNotification(
        userId: recipientId ?? userId,
        title: title,
        body: body,
        type: type,
        channel: channel,
        data: data ?? {},
      );

  /// Внутренний метод отправки уведомления
  Future<String> _sendNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    required NotificationChannel channel,
    required Map<String, dynamic> data,
    String? templateId,
  }) async {
    try {
      final notificationId = _uuid.v4();
      final now = DateTime.now();

      // Создаем запись об отправленном уведомлении
      final sentNotification = SentNotification(
        id: notificationId,
        templateId: templateId ?? '',
        userId: userId,
        title: title,
        body: body,
        type: type,
        channel: channel,
        data: data,
        sentAt: now,
      );

      // Сохраняем в Firestore
      await _firestore
          .collection('sentNotifications')
          .doc(notificationId)
          .set(sentNotification.toMap());

      // Отправляем уведомление в зависимости от канала
      switch (channel) {
        case NotificationChannel.push:
          await _sendPushNotification(userId, title, body, data);
          break;
        case NotificationChannel.email:
          await _sendEmailNotification(userId, title, body, data);
          break;
        case NotificationChannel.sms:
          await _sendSmsNotification(userId, title, body, data);
          break;
        case NotificationChannel.inApp:
          await _sendInAppNotification(userId, title, body, data);
          break;
      }

      // Обновляем статус на "отправлено"
      await _updateNotificationStatus(notificationId, NotificationStatus.sent);

      // Отправляем в поток
      _notificationController
          .add(sentNotification.copyWith(status: NotificationStatus.sent));

      return notificationId;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка отправки уведомления: $e');
      }

      // Обновляем статус на "ошибка"
      if (notificationId != null) {
        await _updateNotificationStatus(
          notificationId,
          NotificationStatus.failed,
          e.toString(),
        );
      }

      rethrow;
    }
  }

  /// Отправить push-уведомление
  Future<void> _sendPushNotification(
    String userId,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      // Получаем FCM токены пользователя
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data();
      final fcmTokens = List<String>.from(userData['fcmTokens'] ?? []);

      if (fcmTokens.isEmpty) return;

      // Отправляем на каждый токен
      for (final token in fcmTokens) {
        try {
          await _messaging.sendMessage(
            to: token,
            data: {
              'title': title,
              'body': body,
              ...data.map((key, value) => MapEntry(key, value.toString())),
            },
          );
        } catch (e) {
          if (kDebugMode) {
            print('Ошибка отправки push на токен $token: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка отправки push-уведомления: $e');
      }
      rethrow;
    }
  }

  /// Отправить email-уведомление
  Future<void> _sendEmailNotification(
    String userId,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    // TODO: Реализовать отправку email через Cloud Functions
    if (kDebugMode) {
      print('Email notification: $title - $body');
    }
  }

  /// Отправить SMS-уведомление
  Future<void> _sendSmsNotification(
    String userId,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    // TODO: Реализовать отправку SMS через Cloud Functions
    if (kDebugMode) {
      print('SMS notification: $title - $body');
    }
  }

  /// Отправить внутриприложенческое уведомление
  Future<void> _sendInAppNotification(
    String userId,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    // TODO: Реализовать внутриприложенческие уведомления
    if (kDebugMode) {
      print('In-app notification: $title - $body');
    }
  }

  /// Обновить статус уведомления
  Future<void> _updateNotificationStatus(
    String notificationId,
    NotificationStatus status, [
    String? errorMessage,
  ]) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (status == NotificationStatus.delivered) {
        updateData['deliveredAt'] = Timestamp.fromDate(DateTime.now());
      } else if (status == NotificationStatus.read) {
        updateData['readAt'] = Timestamp.fromDate(DateTime.now());
      } else if (status == NotificationStatus.failed && errorMessage != null) {
        updateData['errorMessage'] = errorMessage;
      }

      await _firestore
          .collection('sentNotifications')
          .doc(notificationId)
          .update(updateData);
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка обновления статуса уведомления: $e');
      }
    }
  }

  /// Отметить уведомление как прочитанное
  Future<void> markAsRead(String notificationId) async {
    await _updateNotificationStatus(notificationId, NotificationStatus.read);
  }

  /// Отметить уведомление как доставленное
  Future<void> markAsDelivered(String notificationId) async {
    await _updateNotificationStatus(
      notificationId,
      NotificationStatus.delivered,
    );
  }

  /// Получить уведомления пользователя
  Future<List<SentNotification>> getUserNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('sentNotifications')
          .where('userId', isEqualTo: userId)
          .orderBy('sentAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map(SentNotification.fromDocument).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения уведомлений пользователя: $e');
      }
      return [];
    }
  }

  /// Получить шаблоны уведомлений
  Future<List<NotificationTemplate>> getNotificationTemplates() async {
    try {
      final snapshot = await _firestore
          .collection('notificationTemplates')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs.map(NotificationTemplate.fromDocument).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения шаблонов уведомлений: $e');
      }
      return [];
    }
  }

  /// Получить статистику уведомлений
  Future<NotificationStatistics> getNotificationStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? now.subtract(const Duration(days: 30));
      final end = endDate ?? now;

      final snapshot = await _firestore
          .collection('sentNotifications')
          .where('sentAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('sentAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final notifications =
          snapshot.docs.map(SentNotification.fromDocument).toList();

      var totalSent = 0;
      var totalDelivered = 0;
      var totalRead = 0;
      var totalFailed = 0;
      final sentByType = <String, int>{};
      final sentByChannel = <String, int>{};

      for (final notification in notifications) {
        totalSent++;

        switch (notification.status) {
          case NotificationStatus.delivered:
            totalDelivered++;
            break;
          case NotificationStatus.read:
            totalRead++;
            break;
          case NotificationStatus.failed:
            totalFailed++;
            break;
          default:
            break;
        }

        sentByType[notification.type.name] =
            (sentByType[notification.type.name] ?? 0) + 1;
        sentByChannel[notification.channel.name] =
            (sentByChannel[notification.channel.name] ?? 0) + 1;
      }

      final deliveryRate =
          totalSent > 0 ? (totalDelivered / totalSent) * 100 : 0.0;
      final readRate =
          totalDelivered > 0 ? (totalRead / totalDelivered) * 100 : 0.0;

      return NotificationStatistics(
        totalSent: totalSent,
        totalDelivered: totalDelivered,
        totalRead: totalRead,
        totalFailed: totalFailed,
        sentByType: sentByType,
        sentByChannel: sentByChannel,
        deliveryRate: deliveryRate,
        readRate: readRate,
        periodStart: start,
        periodEnd: end,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения статистики уведомлений: $e');
      }
      return NotificationStatistics(
        totalSent: 0,
        totalDelivered: 0,
        totalRead: 0,
        totalFailed: 0,
        sentByType: {},
        sentByChannel: {},
        deliveryRate: 0,
        readRate: 0,
        periodStart: DateTime.now().subtract(const Duration(days: 30)),
        periodEnd: DateTime.now(),
      );
    }
  }

  /// Очистить старые уведомления
  Future<void> cleanupOldNotifications({int daysToKeep = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final snapshot = await _firestore
          .collection('sentNotifications')
          .where('sentAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка очистки старых уведомлений: $e');
      }
    }
  }

  /// Отправить уведомление о напоминании об оплате
  Future<void> sendPaymentReminderNotification({
    required String customerId,
    required String bookingId,
    required String eventName,
    required double amount,
    required DateTime dueDate,
  }) async {
    try {
      await sendNotification(
        userId: customerId,
        title: 'Напоминание об оплате',
        body:
            'Не забудьте оплатить $eventName на сумму ${amount.toStringAsFixed(2)} руб. до ${dueDate.toString()}',
        type: NotificationType.payment,
        channel: NotificationChannel.push,
        data: {
          'bookingId': bookingId,
          'eventName': eventName,
          'amount': amount.toString(),
          'dueDate': dueDate.toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Ошибка отправки напоминания об оплате: $e');
    }
  }

  /// Отправить уведомление о новом отзыве
  Future<void> sendReviewNotification({
    required String specialistId,
    required String customerId,
    required String customerName,
    required String reviewId,
    required double rating,
    required String reviewText,
  }) async {
    try {
      await sendNotification(
        userId: specialistId,
        title: 'Новый отзыв',
        body: 'Вы получили новый отзыв с оценкой $rating',
        type: NotificationType.review,
        channel: NotificationChannel.push,
        data: {
          'reviewId': reviewId,
          'customerId': customerId,
          'rating': rating.toString(),
          'reviewText': reviewText,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка отправки уведомления о отзыве: $e');
      }
    }
  }

  /// Отправить напоминание об оплате
  Future<void> sendPaymentReminder({
    required String customerId,
    required String bookingId,
    required double amount,
    required DateTime dueDate,
  }) async {
    try {
      await sendNotification(
        userId: customerId,
        title: 'Напоминание об оплате',
        body:
            'Не забудьте оплатить заказ на сумму ${amount.toStringAsFixed(2)} руб.',
        type: NotificationType.payment,
        channel: NotificationChannel.push,
        data: {
          'bookingId': bookingId,
          'amount': amount.toString(),
          'dueDate': dueDate.toIso8601String(),
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка отправки напоминания об оплате: $e');
      }
    }
  }

  /// Закрыть сервис
  void dispose() {
    _notificationController.close();
  }
}
