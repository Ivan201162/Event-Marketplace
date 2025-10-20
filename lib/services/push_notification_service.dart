import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/push_notification.dart';

/// Service for managing push notifications
class PushNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize push notifications
  Future<void> initialize() async {
    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        
      );

      debugPrint('Push notification permission: ${settings.authorizationStatus}');

      // Get FCM token
      final token = await _messaging.getToken();
      debugPrint('FCM Token: $token');

      // Listen to token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        // TODO: Update token in user profile
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle notification tap when app is terminated
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      debugPrint('✅ Push notifications initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing push notifications: $e');
    }
  }

  /// Send push notification to user
  Future<bool> sendNotification({
    required String userId,
    required String title,
    required String body,
    required PushNotificationType type,
    PushNotificationPriority priority = PushNotificationPriority.normal,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    DateTime? scheduledAt,
    DateTime? expiresAt,
  }) async {
    try {
      // Create notification record
      final notification = PushNotification(
        id: '', // Will be set by Firestore
        userId: userId,
        title: title,
        body: body,
        type: type,
        priority: priority,
        data: data,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        senderId: senderId,
        senderName: senderName,
        senderAvatarUrl: senderAvatarUrl,
        read: false,
        delivered: false,
        createdAt: DateTime.now(),
        scheduledAt: scheduledAt,
        expiresAt: expiresAt,
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection('push_notifications')
          .add(notification.toFirestore());

      final notificationId = docRef.id;
      debugPrint('Push notification created with ID: $notificationId');

      // Send via FCM (in real app, this would be done via backend)
      final success = await _sendFCMNotification(
        userId: userId,
        title: title,
        body: body,
        data: {
          'notificationId': notificationId,
          'type': type.name,
          'priority': priority.name,
          ...?data,
        },
        imageUrl: imageUrl,
      );

      // Update delivery status
      if (success) {
        await _firestore
            .collection('push_notifications')
            .doc(notificationId)
            .update({
          'delivered': true,
          'deliveredAt': Timestamp.now(),
        });
      }

      return success;
    } catch (e) {
      debugPrint('Error sending push notification: $e');
      return false;
    }
  }

  /// Send notification to multiple users
  Future<Map<String, bool>> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    required PushNotificationType type,
    PushNotificationPriority priority = PushNotificationPriority.normal,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    DateTime? scheduledAt,
    DateTime? expiresAt,
  }) async {
    final results = <String, bool>{};

    for (final userId in userIds) {
      final success = await sendNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        priority: priority,
        data: data,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        senderId: senderId,
        senderName: senderName,
        senderAvatarUrl: senderAvatarUrl,
        scheduledAt: scheduledAt,
        expiresAt: expiresAt,
      );
      results[userId] = success;
    }

    return results;
  }

  /// Get user notifications
  Future<List<PushNotification>> getUserNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('push_notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PushNotification.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user notifications: $e');
      return [];
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('push_notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('push_notifications')
          .doc(notificationId)
          .update({
        'read': true,
        'readAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('push_notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': Timestamp.now(),
        });
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
      await _firestore
          .collection('push_notifications')
          .doc(notificationId)
          .delete();

      return true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  /// Delete all notifications
  Future<bool> deleteAllNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('push_notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      return false;
    }
  }

  /// Get notifications stream
  Stream<List<PushNotification>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('push_notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PushNotification.fromFirestore(doc))
            .toList());
  }

  /// Get unread count stream
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('push_notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Send FCM notification (mock implementation)
  Future<bool> _sendFCMNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      // In real app, this would call your backend API
      // which would then send the notification via FCM
      debugPrint('Sending FCM notification to user: $userId');
      debugPrint('Title: $title');
      debugPrint('Body: $body');
      debugPrint('Data: $data');
      debugPrint('Image: $imageUrl');

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Simulate success
      return true;
    } catch (e) {
      debugPrint('Error sending FCM notification: $e');
      return false;
    }
  }

  /// Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // TODO: Show in-app notification
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    debugPrint('Data: ${message.data}');

    // TODO: Navigate to appropriate screen
    final notificationId = message.data['notificationId'];
    if (notificationId != null) {
      // Mark as read
      markAsRead(notificationId);
    }
  }

  /// Create specialized notifications
  Future<bool> sendBookingNotification({
    required String userId,
    required String specialistName,
    required String serviceName,
    required DateTime bookingTime,
    required String bookingId,
  }) async {
    return sendNotification(
      userId: userId,
      title: 'Новое бронирование',
      body: '$specialistName подтвердил бронирование "$serviceName" на ${_formatDateTime(bookingTime)}',
      type: PushNotificationType.booking,
      priority: PushNotificationPriority.high,
      data: {
        'bookingId': bookingId,
        'specialistName': specialistName,
        'serviceName': serviceName,
        'bookingTime': bookingTime.toIso8601String(),
      },
      actionUrl: '/bookings/$bookingId',
    );
  }

  Future<bool> sendPaymentNotification({
    required String userId,
    required String amount,
    required String serviceName,
    required String paymentId,
  }) async {
    return sendNotification(
      userId: userId,
      title: 'Платеж обработан',
      body: 'Платеж $amount за "$serviceName" успешно обработан',
      type: PushNotificationType.payment,
      priority: PushNotificationPriority.high,
      data: {
        'paymentId': paymentId,
        'amount': amount,
        'serviceName': serviceName,
      },
      actionUrl: '/payments/$paymentId',
    );
  }

  Future<bool> sendMessageNotification({
    required String userId,
    required String senderName,
    required String messageText,
    required String chatId,
  }) async {
    return sendNotification(
      userId: userId,
      title: 'Новое сообщение от $senderName',
      body: messageText,
      type: PushNotificationType.message,
      data: {
        'chatId': chatId,
        'senderName': senderName,
        'messageText': messageText,
      },
      actionUrl: '/chats/$chatId',
    );
  }

  Future<bool> sendReviewNotification({
    required String userId,
    required String reviewerName,
    required int rating,
    required String reviewId,
  }) async {
    return sendNotification(
      userId: userId,
      title: 'Новый отзыв',
      body: '$reviewerName оставил отзыв с оценкой $rating ⭐',
      type: PushNotificationType.review,
      data: {
        'reviewId': reviewId,
        'reviewerName': reviewerName,
        'rating': rating,
      },
      actionUrl: '/reviews/$reviewId',
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} в ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}
