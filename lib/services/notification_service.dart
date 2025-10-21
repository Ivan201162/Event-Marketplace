import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/notification.dart';

/// Service for managing notifications
class NotificationService {
  static const String _collection = 'notifications';

  /// Get user's notifications
  static Future<List<AppNotification>> getUserNotifications(String userId, {int limit = 50}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user notifications: $e');
      return [];
    }
  }

  /// Get user's notifications stream
  static Stream<List<AppNotification>> getUserNotificationsStream(String userId, {int limit = 50}) {
    return FirebaseFirestore.instance
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList());
  }

  /// Get unread notifications
  static Future<List<AppNotification>> getUnreadNotifications(String userId,
      {int limit = 20}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting unread notifications: $e');
      return [];
    }
  }

  /// Get notifications by type
  Future<List<AppNotification>> getNotificationsByType(String userId, NotificationType type,
      {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting notifications by type: $e');
      return [];
    }
  }

  /// Create notification
  Future<String?> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? data,
    String? imageUrl,
    String? actionUrl,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
  }) async {
    try {
      final notification = AppNotification(
        id: '', // Will be set by Firestore
        userId: userId,
        type: type,
        title: title,
        body: body,
        data: data,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        senderId: senderId,
        senderName: senderName,
        senderAvatarUrl: senderAvatarUrl,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection(_collection).add(notification.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating notification: $e');
      return null;
    }
  }

  /// Mark notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance.collection(_collection).doc(notificationId).update({
        'read': true,
      });
      return true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  static Future<bool> markAllAsRead(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  /// Delete all notifications
  Future<bool> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot =
          await _firestore.collection(_collection).where('userId', isEqualTo: userId).get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      return false;
    }
  }

  /// Get notification by ID
  Future<AppNotification?> getNotificationById(String notificationId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(notificationId).get();
      if (doc.exists) {
        return AppNotification.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting notification by ID: $e');
      return null;
    }
  }

  /// Get unread count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Create request notification
  Future<String?> createRequestNotification({
    required String userId,
    required String fromUserName,
    required String category,
    required String city,
    required int budget,
    String? fromUserAvatarUrl,
  }) async {
    return createNotification(
      userId: userId,
      type: NotificationType.request,
      title: 'Новая заявка',
      body: '$fromUserName отправил заявку на $category в $city ($budget₽)',
      senderName: fromUserName,
      senderAvatarUrl: fromUserAvatarUrl,
      actionUrl: '/requests',
    );
  }

  /// Create message notification
  Future<String?> createMessageNotification({
    required String userId,
    required String fromUserName,
    required String messageText,
    String? fromUserAvatarUrl,
    String? chatId,
  }) async {
    return createNotification(
      userId: userId,
      type: NotificationType.message,
      title: 'Новое сообщение от $fromUserName',
      body: messageText.length > 50 ? '${messageText.substring(0, 50)}...' : messageText,
      senderName: fromUserName,
      senderAvatarUrl: fromUserAvatarUrl,
      actionUrl: chatId != null ? '/chat/$chatId' : '/chats',
    );
  }

  /// Create like notification
  Future<String?> createLikeNotification({
    required String userId,
    required String fromUserName,
    required String postType, // 'post' or 'idea'
    String? fromUserAvatarUrl,
    String? postId,
  }) async {
    return createNotification(
      userId: userId,
      type: NotificationType.like,
      title: 'Новый лайк',
      body: '$fromUserName поставил лайк вашему $postType',
      senderName: fromUserName,
      senderAvatarUrl: fromUserAvatarUrl,
      actionUrl: postId != null ? '/$postType/$postId' : '/feed',
    );
  }

  /// Create comment notification
  Future<String?> createCommentNotification({
    required String userId,
    required String fromUserName,
    required String commentText,
    required String postType, // 'post' or 'idea'
    String? fromUserAvatarUrl,
    String? postId,
  }) async {
    return createNotification(
      userId: userId,
      type: NotificationType.comment,
      title: 'Новый комментарий',
      body: '$fromUserName прокомментировал ваш $postType',
      senderName: fromUserName,
      senderAvatarUrl: fromUserAvatarUrl,
      actionUrl: postId != null ? '/$postType/$postId' : '/feed',
    );
  }

  /// Create system notification
  Future<String?> createSystemNotification({
    required String userId,
    required String title,
    required String body,
    String? actionUrl,
  }) async {
    return createNotification(
      userId: userId,
      type: NotificationType.system,
      title: title,
      body: body,
      actionUrl: actionUrl,
    );
  }

  /// Create reminder notification
  Future<String?> createReminderNotification({
    required String userId,
    required String title,
    required String body,
    String? actionUrl,
  }) async {
    return createNotification(
      userId: userId,
      type: NotificationType.reminder,
      title: title,
      body: body,
      actionUrl: actionUrl,
    );
  }

  /// Create promotion notification
  Future<String?> createPromotionNotification({
    required String userId,
    required String title,
    required String body,
    String? imageUrl,
    String? actionUrl,
  }) async {
    return createNotification(
      userId: userId,
      type: NotificationType.promotion,
      title: title,
      body: body,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
    );
  }

  /// Stream of user's notifications
  Stream<List<AppNotification>> getUserNotificationsStream(String userId, {int limit = 50}) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList());
  }

  /// Stream of unread notifications
  Stream<List<AppNotification>> getUnreadNotificationsStream(String userId, {int limit = 20}) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList());
  }

  /// Stream of unread count
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
