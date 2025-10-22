import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Сервис для работы с уведомлениями
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Создать уведомление
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'imageUrl': imageUrl,
        'data': data ?? {},
        'isRead': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow;
    }
  }

  /// Получить уведомления пользователя
  Stream<List<Notification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Notification(
          id: doc.id,
          userId: data['userId'] ?? '',
          title: data['title'] ?? '',
          body: data['body'] ?? '',
          type: NotificationType.values.firstWhere(
            (type) => type.name == data['type'],
            orElse: () => NotificationType.general,
          ),
          imageUrl: data['imageUrl'],
          data: Map<String, dynamic>.from(data['data'] ?? {}),
          isRead: data['isRead'] ?? false,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }

  /// Отметить уведомление как прочитанное
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Отметить все уведомления как прочитанные
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Получить количество непрочитанных уведомлений
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Удалить уведомление
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Удалить все уведомления пользователя
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      rethrow;
    }
  }

  /// Создать уведомление о лайке
  Future<void> createLikeNotification({
    required String postId,
    required String postAuthorId,
    required String likerId,
    required String likerName,
  }) async {
    if (postAuthorId == likerId) return; // Не уведомляем о собственном лайке

    await createNotification(
      userId: postAuthorId,
      title: 'Новый лайк',
      body: '$likerName поставил лайк вашему посту',
      type: NotificationType.like,
      data: {
        'postId': postId,
        'likerId': likerId,
        'likerName': likerName,
      },
    );
  }

  /// Создать уведомление о комментарии
  Future<void> createCommentNotification({
    required String postId,
    required String postAuthorId,
    required String commenterId,
    required String commenterName,
    required String commentText,
  }) async {
    if (postAuthorId == commenterId) return; // Не уведомляем о собственном комментарии

    await createNotification(
      userId: postAuthorId,
      title: 'Новый комментарий',
      body: '$commenterName прокомментировал ваш пост: ${commentText.length > 50 ? '${commentText.substring(0, 50)}...' : commentText}',
      type: NotificationType.comment,
      data: {
        'postId': postId,
        'commenterId': commenterId,
        'commenterName': commenterName,
        'commentText': commentText,
      },
    );
  }

  /// Создать уведомление о подписке
  Future<void> createFollowNotification({
    required String userId,
    required String followerId,
    required String followerName,
  }) async {
    if (userId == followerId) return; // Не уведомляем о собственной подписке

    await createNotification(
      userId: userId,
      title: 'Новая подписка',
      body: '$followerName подписался на вас',
      type: NotificationType.follow,
      data: {
        'followerId': followerId,
        'followerName': followerName,
      },
    );
  }

  /// Создать уведомление о сообщении
  Future<void> createMessageNotification({
    required String userId,
    required String senderId,
    required String senderName,
    required String messageText,
    required String chatId,
  }) async {
    if (userId == senderId) return; // Не уведомляем о собственном сообщении

    await createNotification(
      userId: userId,
      title: 'Новое сообщение',
      body: '$senderName: ${messageText.length > 50 ? '${messageText.substring(0, 50)}...' : messageText}',
      type: NotificationType.message,
      data: {
        'senderId': senderId,
        'senderName': senderName,
        'messageText': messageText,
        'chatId': chatId,
      },
    );
  }

  /// Создать уведомление об упоминании
  Future<void> createMentionNotification({
    required String userId,
    required String postId,
    required String mentionerId,
    required String mentionerName,
    required String postText,
  }) async {
    if (userId == mentionerId) return; // Не уведомляем о собственном упоминании

    await createNotification(
      userId: userId,
      title: 'Вас упомянули',
      body: '$mentionerName упомянул вас в посте',
      type: NotificationType.mention,
      data: {
        'postId': postId,
        'mentionerId': mentionerId,
        'mentionerName': mentionerName,
        'postText': postText,
      },
    );
  }
}

/// Типы уведомлений
enum NotificationType {
  general('general'),
  like('like'),
  comment('comment'),
  follow('follow'),
  message('message'),
  mention('mention'),
  system('system');

  const NotificationType(this.value);
  final String value;
}

/// Модель уведомления
class Notification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.imageUrl,
    required this.data,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать уведомление из Firestore документа
  factory Notification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Notification(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => NotificationType.general,
      ),
      imageUrl: data['imageUrl'],
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Конвертировать уведомление в Firestore документ
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'imageUrl': imageUrl,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Создать копию с обновленными полями
  Notification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    String? imageUrl,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Notification(id: $id, title: $title, type: $type, isRead: $isRead)';
  }
}