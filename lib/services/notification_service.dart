import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'fcm_service.dart';

/// Сервис для отправки уведомлений между пользователями
class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Отправка уведомления пользователю
  static Future<void> sendUserNotification({
    required String receiverId,
    required String title,
    required String body,
    required String type,
    required String targetId,
    String? senderId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid ?? senderId;
      if (currentUserId == null) return;

      // Создаем уведомление в Firestore
      final notificationData = {
        'receiverId': receiverId,
        'senderId': currentUserId,
        'title': title,
        'body': body,
        'type': type,
        'targetId': targetId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'isPinned': false,
        'data': additionalData ?? {},
      };

      // Сохраняем в коллекцию исходящих уведомлений
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('outgoing_notifications')
          .add(notificationData);

      // Сохраняем в коллекцию входящих уведомлений получателя
      await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications_history')
          .add(notificationData);

      // Отправляем через FCM
      await FCMService.sendNotification(
        userId: receiverId,
        title: title,
        body: body,
        type: type,
        data: {
          'id': targetId,
          'type': type,
          'senderId': currentUserId,
          ...?additionalData,
        },
      );

      print('Уведомление отправлено пользователю $receiverId: $title');
    } on Exception catch (e) {
      print('Ошибка отправки уведомления: $e');
    }
  }

  /// Отправка уведомления о лайке
  static Future<void> sendLikeNotification({
    required String receiverId,
    required String postId,
    required String postTitle,
  }) async {
    await sendUserNotification(
      receiverId: receiverId,
      title: 'Новый лайк!',
      body: 'Кто-то поставил лайк вашему посту "$postTitle"',
      type: 'like',
      targetId: postId,
      additionalData: {'postTitle': postTitle},
    );
  }

  /// Отправка уведомления о комментарии
  static Future<void> sendCommentNotification({
    required String receiverId,
    required String postId,
    required String postTitle,
    required String commentText,
  }) async {
    await sendUserNotification(
      receiverId: receiverId,
      title: 'Новый комментарий',
      body: 'Кто-то прокомментировал ваш пост "$postTitle": "$commentText"',
      type: 'comment',
      targetId: postId,
      additionalData: {
        'postTitle': postTitle,
        'commentText': commentText,
      },
    );
  }

  /// Отправка уведомления о подписке
  static Future<void> sendFollowNotification({
    required String receiverId,
    required String followerName,
  }) async {
    await sendUserNotification(
      receiverId: receiverId,
      title: 'Новая подписка',
      body: '$followerName подписался на вас',
      type: 'follow',
      targetId: receiverId,
      additionalData: {'followerName': followerName},
    );
  }

  /// Отправка уведомления о сообщении
  static Future<void> sendMessageNotification({
    required String receiverId,
    required String chatId,
    required String senderName,
    required String messageText,
  }) async {
    await sendUserNotification(
      receiverId: receiverId,
      title: 'Новое сообщение от $senderName',
      body: messageText,
      type: 'message',
      targetId: chatId,
      additionalData: {
        'senderName': senderName,
        'messageText': messageText,
        'chatId': chatId,
      },
    );
  }

  /// Отправка уведомления о заявке
  static Future<void> sendRequestNotification({
    required String receiverId,
    required String requestId,
    required String requestTitle,
    required String requesterName,
  }) async {
    await sendUserNotification(
      receiverId: receiverId,
      title: 'Новая заявка',
      body: '$requesterName отправил заявку "$requestTitle"',
      type: 'request',
      targetId: requestId,
      additionalData: {
        'requestTitle': requestTitle,
        'requesterName': requesterName,
      },
    );
  }

  /// Отправка уведомления о бронировании
  static Future<void> sendBookingNotification({
    required String receiverId,
    required String bookingId,
    required String bookingTitle,
    required String status,
  }) async {
    String title;
    String body;

    switch (status) {
      case 'confirmed':
        title = 'Бронирование подтверждено';
        body = 'Ваше бронирование "$bookingTitle" подтверждено';
        break;
      case 'rejected':
        title = 'Бронирование отклонено';
        body = 'Ваше бронирование "$bookingTitle" отклонено';
        break;
      case 'cancelled':
        title = 'Бронирование отменено';
        body = 'Бронирование "$bookingTitle" отменено';
        break;
      default:
        title = 'Обновление бронирования';
        body = 'Статус бронирования "$bookingTitle" изменен на $status';
    }

    await sendUserNotification(
      receiverId: receiverId,
      title: title,
      body: body,
      type: 'booking',
      targetId: bookingId,
      additionalData: {
        'bookingTitle': bookingTitle,
        'status': status,
      },
    );
  }

  /// Отправка системного уведомления
  static Future<void> sendSystemNotification({
    required String receiverId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await sendUserNotification(
      receiverId: receiverId,
      title: title,
      body: body,
      type: 'system',
      targetId: '',
      additionalData: data,
    );
  }

  /// Получение истории уведомлений пользователя
  static Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) => _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications_history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList(),);

  /// Отметить уведомление как прочитанное
  static Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications_history')
          .doc(notificationId)
          .update({'isRead': true});
    } on Exception catch (e) {
      print('Ошибка отметки уведомления как прочитанного: $e');
    }
  }

  /// Отметить все уведомления как прочитанные
  static Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications_history')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } on Exception catch (e) {
      print('Ошибка отметки всех уведомлений как прочитанных: $e');
    }
  }

  /// Закрепить уведомление
  static Future<void> pinNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications_history')
          .doc(notificationId)
          .update({'isPinned': true});
    } on Exception catch (e) {
      print('Ошибка закрепления уведомления: $e');
    }
  }

  /// Открепить уведомление
  static Future<void> unpinNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications_history')
          .doc(notificationId)
          .update({'isPinned': false});
    } on Exception catch (e) {
      print('Ошибка открепления уведомления: $e');
    }
  }

  /// Удалить уведомление
  static Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications_history')
          .doc(notificationId)
          .delete();
    } on Exception catch (e) {
      print('Ошибка удаления уведомления: $e');
    }
  }

  /// Получить количество непрочитанных уведомлений
  static Stream<int> getUnreadCount(String userId) => _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications_history')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);

  /// Очистить все уведомления пользователя
  static Future<void> clearAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications_history')
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } on Exception catch (e) {
      print('Ошибка очистки всех уведомлений: $e');
    }
  }

  /// Отметить уведомление как прочитанное (новая модель)
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      print('Ошибка отметки уведомления как прочитанного: $e');
    }
  }

  /// Создать тестовые уведомления
  static Future<void> createTestNotifications(String userId) async {
    try {
      final testNotifications = [
        {
          'userId': userId,
          'title': 'Новое сообщение',
          'body': 'У вас новое сообщение от специалиста',
          'type': 'message',
          'data': {'chatId': 'chat_1'},
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': userId,
          'title': 'Заявка подтверждена',
          'body': 'Ваша заявка на мероприятие подтверждена',
          'type': 'booking',
          'data': {'bookingId': 'booking_1'},
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': userId,
          'title': 'Новый отзыв',
          'body': 'Кто-то оставил отзыв о вашей работе',
          'type': 'review',
          'data': {'reviewId': 'review_1'},
          'isRead': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': userId,
          'title': 'Системное уведомление',
          'body': 'Приложение обновлено до версии 1.0.0',
          'type': 'system',
          'data': {},
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      final batch = _firestore.batch();
      for (final notification in testNotifications) {
        final docRef = _firestore.collection('notifications').doc();
        batch.set(docRef, notification);
      }
      await batch.commit();
    } on Exception catch (e) {
      print('Ошибка создания тестовых уведомлений: $e');
    }
  }
}