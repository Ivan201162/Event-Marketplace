import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

/// Сервис для управления уведомлениями
class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Создать уведомление
  Future<AppNotification> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? imageUrl,
  }) async {
    try {
      final notification = AppNotification(
        id: _generateNotificationId(),
        userId: userId,
        type: type,
        title: title,
        body: body,
        priority: priority,
        status: NotificationStatus.unread,
        createdAt: DateTime.now(),
        data: data,
        actionUrl: actionUrl,
        imageUrl: imageUrl,
      );

      await _db.collection('notifications').doc(notification.id).set(notification.toMap());
      return notification;
    } catch (e) {
      print('Ошибка создания уведомления: $e');
      throw Exception('Не удалось создать уведомление: $e');
    }
  }

  /// Получить уведомления пользователя
  Future<List<AppNotification>> getUserNotifications(
    String userId, {
    int limit = 50,
    NotificationStatus? status,
  }) async {
    try {
      Query query = _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => AppNotification.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Ошибка получения уведомлений: $e');
      return [];
    }
  }

  /// Поток уведомлений пользователя
  Stream<List<AppNotification>> getUserNotificationsStream(
    String userId, {
    int limit = 50,
    NotificationStatus? status,
  }) {
    Query query = _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => AppNotification.fromDocument(doc))
        .toList());
  }

  /// Отметить уведомление как прочитанное
  Future<void> markAsRead(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({
        'status': NotificationStatus.read.name,
        'readAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка отметки уведомления как прочитанного: $e');
    }
  }

  /// Отметить все уведомления как прочитанные
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _db.batch();
      
      final querySnapshot = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: NotificationStatus.unread.name)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'status': NotificationStatus.read.name,
          'readAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Ошибка отметки всех уведомлений как прочитанных: $e');
    }
  }

  /// Архивировать уведомление
  Future<void> archiveNotification(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({
        'status': NotificationStatus.archived.name,
        'archivedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка архивирования уведомления: $e');
    }
  }

  /// Удалить уведомление
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Ошибка удаления уведомления: $e');
      throw Exception('Не удалось удалить уведомление: $e');
    }
  }

  /// Получить статистику уведомлений
  Future<NotificationStatistics> getNotificationStatistics(String userId) async {
    try {
      final querySnapshot = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final notifications = querySnapshot.docs
          .map((doc) => AppNotification.fromDocument(doc))
          .toList();

      int totalCount = notifications.length;
      int unreadCount = 0;
      int readCount = 0;
      int archivedCount = 0;
      final typeCounts = <NotificationType, int>{};
      final priorityCounts = <NotificationPriority, int>{};

      for (final notification in notifications) {
        switch (notification.status) {
          case NotificationStatus.unread:
            unreadCount++;
            break;
          case NotificationStatus.read:
            readCount++;
            break;
          case NotificationStatus.archived:
            archivedCount++;
            break;
        }

        typeCounts[notification.type] = (typeCounts[notification.type] ?? 0) + 1;
        priorityCounts[notification.priority] = (priorityCounts[notification.priority] ?? 0) + 1;
      }

      return NotificationStatistics(
        totalCount: totalCount,
        unreadCount: unreadCount,
        readCount: readCount,
        archivedCount: archivedCount,
        typeCounts: typeCounts,
        priorityCounts: priorityCounts,
      );
    } catch (e) {
      print('Ошибка получения статистики уведомлений: $e');
      return NotificationStatistics.empty();
    }
  }

  /// Создать уведомление о заявке
  Future<void> createBookingNotification({
    required String userId,
    required NotificationType type,
    required String bookingId,
    required String specialistName,
    required String customerName,
    DateTime? eventDate,
  }) async {
    String title;
    String body;
    NotificationPriority priority = NotificationPriority.normal;

    switch (type) {
      case NotificationType.booking_created:
        title = 'Новая заявка';
        body = 'Получена новая заявка от $customerName';
        priority = NotificationPriority.high;
        break;
      case NotificationType.booking_confirmed:
        title = 'Заявка подтверждена';
        body = 'Ваша заявка подтверждена специалистом $specialistName';
        break;
      case NotificationType.booking_rejected:
        title = 'Заявка отклонена';
        body = 'Ваша заявка отклонена специалистом $specialistName';
        priority = NotificationPriority.high;
        break;
      case NotificationType.booking_cancelled:
        title = 'Заявка отменена';
        body = 'Заявка отменена';
        break;
      default:
        title = 'Обновление заявки';
        body = 'Статус заявки изменен';
    }

    if (eventDate != null) {
      body += ' на ${_formatDate(eventDate)}';
    }

    await createNotification(
      userId: userId,
      type: type,
      title: title,
      body: body,
      priority: priority,
      data: {
        'bookingId': bookingId,
        'type': 'booking',
      },
      actionUrl: '/booking/$bookingId',
    );
  }

  /// Создать уведомление о платеже
  Future<void> createPaymentNotification({
    required String userId,
    required NotificationType type,
    required String paymentId,
    required double amount,
    required String currency,
  }) async {
    String title;
    String body;
    NotificationPriority priority = NotificationPriority.normal;

    switch (type) {
      case NotificationType.payment_created:
        title = 'Новый платеж';
        body = 'Создан платеж на сумму $amount $currency';
        break;
      case NotificationType.payment_completed:
        title = 'Платеж завершен';
        body = 'Платеж на сумму $amount $currency успешно завершен';
        break;
      case NotificationType.payment_failed:
        title = 'Платеж неудачен';
        body = 'Платеж на сумму $amount $currency не удался';
        priority = NotificationPriority.high;
        break;
      default:
        title = 'Обновление платежа';
        body = 'Статус платежа изменен';
    }

    await createNotification(
      userId: userId,
      type: type,
      title: title,
      body: body,
      priority: priority,
      data: {
        'paymentId': paymentId,
        'amount': amount,
        'currency': currency,
        'type': 'payment',
      },
      actionUrl: '/payment/$paymentId',
    );
  }

  /// Создать уведомление о сообщении
  Future<void> createMessageNotification({
    required String userId,
    required String senderName,
    required String messagePreview,
    required String chatId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.message_received,
      title: 'Новое сообщение от $senderName',
      body: messagePreview,
      priority: NotificationPriority.normal,
      data: {
        'chatId': chatId,
        'senderName': senderName,
        'type': 'message',
      },
      actionUrl: '/chat/$chatId',
    );
  }

  /// Создать уведомление о расписании
  Future<void> createScheduleNotification({
    required String userId,
    required String title,
    required String body,
    DateTime? scheduleDate,
  }) async {
    if (scheduleDate != null) {
      body += ' на ${_formatDate(scheduleDate)}';
    }

    await createNotification(
      userId: userId,
      type: NotificationType.schedule_updated,
      title: title,
      body: body,
      priority: NotificationPriority.normal,
      data: {
        'type': 'schedule',
        'scheduleDate': scheduleDate?.toIso8601String(),
      },
      actionUrl: '/schedule',
    );
  }

  /// Создать системное объявление
  Future<void> createSystemAnnouncement({
    required String title,
    required String body,
    String? actionUrl,
    String? imageUrl,
  }) async {
    try {
      // Получаем всех активных пользователей
      final usersSnapshot = await _db
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _db.batch();
      final now = DateTime.now();

      for (final userDoc in usersSnapshot.docs) {
        final notification = AppNotification(
          id: _generateNotificationId(),
          userId: userDoc.id,
          type: NotificationType.system_announcement,
          title: title,
          body: body,
          priority: NotificationPriority.high,
          status: NotificationStatus.unread,
          createdAt: now,
          actionUrl: actionUrl,
          imageUrl: imageUrl,
          data: {
            'type': 'system_announcement',
            'isGlobal': true,
          },
        );

        batch.set(
          _db.collection('notifications').doc(notification.id),
          notification.toMap(),
        );
      }

      await batch.commit();
    } catch (e) {
      print('Ошибка создания системного объявления: $e');
      throw Exception('Не удалось создать системное объявление: $e');
    }
  }

  /// Очистить старые уведомления
  Future<void> cleanupOldNotifications({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      final querySnapshot = await _db
          .collection('notifications')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .where('status', isEqualTo: NotificationStatus.archived.name)
          .get();

      final batch = _db.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Ошибка очистки старых уведомлений: $e');
    }
  }

  /// Форматировать дату
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  /// Генерировать ID уведомления
  String _generateNotificationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'NOTIF_${timestamp}_$random';
  }
}
