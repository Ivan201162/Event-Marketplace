import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      // Request permission for iOS
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('Permission granted: ${settings.authorizationStatus}');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle notification tap when app is terminated
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');

      // Save token to Firestore
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);

    } catch (e) {
      debugPrint('Error initializing push notifications: $e');
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'chat_notifications',
      'Chat Notifications',
      description: 'Notifications for new messages',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');
    
    // Show local notification
    await _showLocalNotification(message);
  }

  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    debugPrint('Notification tapped: ${message.messageId}');
    
    // Navigate to chat screen
    final chatId = message.data['chatId'];
    if (chatId != null) {
      // Navigate to chat screen
      // This would typically use a navigation service
      debugPrint('Navigate to chat: $chatId');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    
    // Handle local notification tap
    final chatId = response.payload;
    if (chatId != null) {
      // Navigate to chat screen
      debugPrint('Navigate to chat: $chatId');
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_notifications',
            'Chat Notifications',
            channelDescription: 'Notifications for new messages',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: data['chatId'],
      );
    }
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('user_tokens')
            .doc(userId)
            .set({
          'token': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        debugPrint('Token saved to Firestore for user: $userId');
      }
    } catch (e) {
      debugPrint('Error saving token to Firestore: $e');
    }
  }

  static Future<String?> _getCurrentUserId() async {
    // This should return the current user ID
    // Implementation depends on your auth system
    return null; // Placeholder
  }

  static Future<void> sendMessageNotification({
    required String chatId,
    required String senderId,
    required String recipientId,
    required String messageText,
    required String senderName,
  }) async {
    try {
      // Get recipient's FCM token
      final tokenDoc = await FirebaseFirestore.instance
          .collection('user_tokens')
          .doc(recipientId)
          .get();

      if (!tokenDoc.exists) {
        debugPrint('No FCM token found for user: $recipientId');
        return;
      }

      final token = tokenDoc.data()?['token'] as String?;
      if (token == null) {
        debugPrint('Invalid FCM token for user: $recipientId');
        return;
      }

      // Send notification via Cloud Functions
      // This would typically call a Cloud Function
      debugPrint('Sending notification to user: $recipientId');
      
    } catch (e) {
      debugPrint('Error sending message notification: $e');
    }
  }

  static Future<void> sendBotNotification({
    required String chatId,
    required String userId,
    required String messageText,
  }) async {
    try {
      await sendMessageNotification(
        chatId: chatId,
        senderId: 'bot',
        recipientId: userId,
        messageText: messageText,
        senderName: 'Бот-помощник',
      );
    } catch (e) {
      debugPrint('Error sending bot notification: $e');
    }
  }

  static Future<void> sendSupportNotification({
    required String chatId,
    required String userId,
    required String messageText,
  }) async {
    try {
      await sendMessageNotification(
        chatId: chatId,
        senderId: 'support',
        recipientId: userId,
        messageText: messageText,
        senderName: 'Техподдержка',
      );
    } catch (e) {
      debugPrint('Error sending support notification: $e');
    }
  }

  static Future<void> sendBookingNotification({
    required String userId,
    required String bookingId,
    required String messageText,
  }) async {
    try {
      // Get user's FCM token
      final tokenDoc = await FirebaseFirestore.instance
          .collection('user_tokens')
          .doc(userId)
          .get();

      if (!tokenDoc.exists) return;

      final token = tokenDoc.data()?['token'] as String?;
      if (token == null) return;

      // Send booking notification
      debugPrint('Sending booking notification to user: $userId');
      
    } catch (e) {
      debugPrint('Error sending booking notification: $e');
    }
  }

  static Future<void> sendReminderNotification({
    required String userId,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      await _localNotifications.zonedSchedule(
        scheduledTime.millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminders',
            'Reminders',
            channelDescription: 'Scheduled reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Error scheduling reminder notification: $e');
    }
  }

  static Future<void> cancelNotification(int notificationId) async {
    await _localNotifications.cancel(notificationId);
  }

  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  static Future<void> updateBadgeCount(int count) async {
    // Update app badge count
    // Implementation depends on platform
  }

  static Future<void> clearBadge() async {
    // Clear app badge
    // Implementation depends on platform
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  
  // Handle background message
  // This function must be top-level
}
