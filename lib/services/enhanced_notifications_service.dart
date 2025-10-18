import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

import '../models/enhanced_notification.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ РґР»СЏ СЂР°Р±РѕС‚С‹ СЃ СЂР°СЃС€РёСЂРµРЅРЅС‹РјРё СѓРІРµРґРѕРјР»РµРЅРёСЏРјРё
class EnhancedNotificationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// РРЅРёС†РёР°Р»РёР·Р°С†РёСЏ СЃРµСЂРІРёСЃР° СѓРІРµРґРѕРјР»РµРЅРёР№
  Future<void> initialize() async {
    // РРЅРёС†РёР°Р»РёР·Р°С†РёСЏ Р»РѕРєР°Р»СЊРЅС‹С… СѓРІРµРґРѕРјР»РµРЅРёР№
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettingsIOS = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Р—Р°РїСЂРѕСЃ СЂР°Р·СЂРµС€РµРЅРёР№
    await _requestPermissions();

    // РќР°СЃС‚СЂРѕР№РєР° РѕР±СЂР°Р±РѕС‚С‡РёРєРѕРІ СЃРѕРѕР±С‰РµРЅРёР№
    _setupMessageHandlers();
  }

  /// Р—Р°РїСЂРѕСЃ СЂР°Р·СЂРµС€РµРЅРёР№ РЅР° СѓРІРµРґРѕРјР»РµРЅРёСЏ
  Future<void> _requestPermissions() async {
    // Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // iOS
    await _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Firebase Messaging
    final settings = await _messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('РЈРІРµРґРѕРјР»РµРЅРёСЏ СЂР°Р·СЂРµС€РµРЅС‹');
    } else {
      debugPrint('РЈРІРµРґРѕРјР»РµРЅРёСЏ РЅРµ СЂР°Р·СЂРµС€РµРЅС‹');
    }
  }

  /// РќР°СЃС‚СЂРѕР№РєР° РѕР±СЂР°Р±РѕС‚С‡РёРєРѕРІ СЃРѕРѕР±С‰РµРЅРёР№
  void _setupMessageHandlers() {
    // РћР±СЂР°Р±РѕС‚РєР° СЃРѕРѕР±С‰РµРЅРёР№ РІ С„РѕРЅРµ
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // РћР±СЂР°Р±РѕС‚РєР° СЃРѕРѕР±С‰РµРЅРёР№ РІ foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // РћР±СЂР°Р±РѕС‚РєР° РЅР°Р¶Р°С‚РёР№ РЅР° СѓРІРµРґРѕРјР»РµРЅРёСЏ
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// РћР±СЂР°Р±РѕС‚РєР° РЅР°Р¶Р°С‚РёСЏ РЅР° СѓРІРµРґРѕРјР»РµРЅРёРµ
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: РћР±СЂР°Р±РѕС‚РєР° РЅР°Р¶Р°С‚РёСЏ РЅР° Р»РѕРєР°Р»СЊРЅРѕРµ СѓРІРµРґРѕРјР»РµРЅРёРµ
    debugPrint('РќР°Р¶Р°С‚Рѕ РЅР° СѓРІРµРґРѕРјР»РµРЅРёРµ: ${response.payload}');
  }

  /// РћР±СЂР°Р±РѕС‚РєР° СЃРѕРѕР±С‰РµРЅРёСЏ РІ foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('РџРѕР»СѓС‡РµРЅРѕ СЃРѕРѕР±С‰РµРЅРёРµ РІ foreground: ${message.messageId}');

    // РџРѕРєР°Р·Р°С‚СЊ Р»РѕРєР°Р»СЊРЅРѕРµ СѓРІРµРґРѕРјР»РµРЅРёРµ
    _showLocalNotification(
      title: message.notification?.title ?? 'РќРѕРІРѕРµ СѓРІРµРґРѕРјР»РµРЅРёРµ',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// РћР±СЂР°Р±РѕС‚РєР° РЅР°Р¶Р°С‚РёСЏ РЅР° СѓРІРµРґРѕРјР»РµРЅРёРµ
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('РќР°Р¶Р°С‚Рѕ РЅР° СѓРІРµРґРѕРјР»РµРЅРёРµ: ${message.messageId}');
    // TODO: РќР°РІРёРіР°С†РёСЏ Рє СЃРѕРѕС‚РІРµС‚СЃС‚РІСѓСЋС‰РµРјСѓ СЌРєСЂР°РЅСѓ
  }

  /// РџРѕРєР°Р·Р°С‚СЊ Р»РѕРєР°Р»СЊРЅРѕРµ СѓРІРµРґРѕРјР»РµРЅРёРµ
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'event_marketplace',
      'Event Marketplace',
      channelDescription: 'РЈРІРµРґРѕРјР»РµРЅРёСЏ Event Marketplace',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СѓРІРµРґРѕРјР»РµРЅРёСЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<List<EnhancedNotification>> getNotifications({
    required String userId,
    int limit = 50,
    DocumentSnapshot? lastDocument,
    bool includeArchived = false,
  }) async {
    try {
      Query query = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (!includeArchived) {
        query = query.where('isArchived', isEqualTo: false);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final notifications = <EnhancedNotification>[];

      for (final doc in snapshot.docs) {
        final notification = EnhancedNotification.fromMap(doc.data()! as Map<String, dynamic>);
        notifications.add(notification);
      }

      return notifications;
    } catch (e) {
      throw Exception('РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё СѓРІРµРґРѕРјР»РµРЅРёР№: $e');
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РЅРµРїСЂРѕС‡РёС‚Р°РЅРЅС‹Рµ СѓРІРµРґРѕРјР»РµРЅРёСЏ
  Future<List<EnhancedNotification>> getUnreadNotifications({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final notifications = <EnhancedNotification>[];

      for (final doc in snapshot.docs) {
        final notification = EnhancedNotification.fromMap(doc.data()! as Map<String, dynamic>);
        notifications.add(notification);
      }

      return notifications;
    } catch (e) {
      throw Exception('РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё РЅРµРїСЂРѕС‡РёС‚Р°РЅРЅС‹С… СѓРІРµРґРѕРјР»РµРЅРёР№: $e');
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СѓРІРµРґРѕРјР»РµРЅРёРµ РїРѕ ID
  Future<EnhancedNotification?> getNotificationById(
    String notificationId,
  ) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('notifications').doc(notificationId).get();

      if (doc.exists) {
        return EnhancedNotification.fromMap(
          doc.data()! as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception('РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё СѓРІРµРґРѕРјР»РµРЅРёСЏ: $e');
    }
  }

  /// РЎРѕР·РґР°С‚СЊ СѓРІРµРґРѕРјР»РµРЅРёРµ
  Future<EnhancedNotification> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
    NotificationPriority priority = NotificationPriority.normal,
    String? category,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    DateTime? expiresAt,
  }) async {
    try {
      final notificationId = _firestore.collection('notifications').doc().id;
      final now = DateTime.now();

      final notification = EnhancedNotification(
        id: notificationId,
        userId: userId,
        title: title,
        body: body,
        type: type,
        createdAt: now,
        data: data ?? {},
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        priority: priority,
        category: category,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        expiresAt: expiresAt,
      );

      await _firestore.collection('notifications').doc(notificationId).set(notification.toMap());

      // РћС‚РїСЂР°РІРёС‚СЊ push-СѓРІРµРґРѕРјР»РµРЅРёРµ
      await _sendPushNotification(notification);

      return notification;
    } catch (e) {
      throw Exception('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ СѓРІРµРґРѕРјР»РµРЅРёСЏ: $e');
    }
  }

  /// РћС‚РїСЂР°РІРёС‚СЊ push-СѓРІРµРґРѕРјР»РµРЅРёРµ
  Future<void> _sendPushNotification(EnhancedNotification notification) async {
    try {
      // РџРѕР»СѓС‡РёС‚СЊ FCM С‚РѕРєРµРЅ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
      final userDoc = await _firestore.collection('users').doc(notification.userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final fcmToken = userData['fcmToken'] as String?;

        if (fcmToken != null) {
          // РћС‚РїСЂР°РІРёС‚СЊ СѓРІРµРґРѕРјР»РµРЅРёРµ С‡РµСЂРµР· FCM
          await _messaging.sendMessage(
            to: fcmToken,
            data: {
              'notificationId': notification.id,
              'type': notification.type.value,
              'actionUrl': notification.actionUrl ?? '',
            },
            notification: RemoteNotification(
              title: notification.title,
              body: notification.body,
              imageUrl: notification.imageUrl,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‚РїСЂР°РІРєРё push-СѓРІРµРґРѕРјР»РµРЅРёСЏ: $e');
    }
  }

  /// РћС‚РјРµС‚РёС‚СЊ СѓРІРµРґРѕРјР»РµРЅРёРµ РєР°Рє РїСЂРѕС‡РёС‚Р°РЅРЅРѕРµ
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('РћС€РёР±РєР° РѕС‚РјРµС‚РєРё СѓРІРµРґРѕРјР»РµРЅРёСЏ РєР°Рє РїСЂРѕС‡РёС‚Р°РЅРЅРѕРіРѕ: $e');
    }
  }

  /// РћС‚РјРµС‚РёС‚СЊ РІСЃРµ СѓРІРµРґРѕРјР»РµРЅРёСЏ РєР°Рє РїСЂРѕС‡РёС‚Р°РЅРЅС‹Рµ
  Future<void> markAllAsRead(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('РћС€РёР±РєР° РѕС‚РјРµС‚РєРё РІСЃРµС… СѓРІРµРґРѕРјР»РµРЅРёР№ РєР°Рє РїСЂРѕС‡РёС‚Р°РЅРЅС‹С…: $e');
    }
  }

  /// РђСЂС…РёРІРёСЂРѕРІР°С‚СЊ СѓРІРµРґРѕРјР»РµРЅРёРµ
  Future<void> archiveNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('РћС€РёР±РєР° Р°СЂС…РёРІРёСЂРѕРІР°РЅРёСЏ СѓРІРµРґРѕРјР»РµРЅРёСЏ: $e');
    }
  }

  /// РЈРґР°Р»РёС‚СЊ СѓРІРµРґРѕРјР»РµРЅРёРµ
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ СѓРІРµРґРѕРјР»РµРЅРёСЏ: $e');
    }
  }

  /// РћС‡РёСЃС‚РёС‚СЊ РІСЃРµ СѓРІРµРґРѕРјР»РµРЅРёСЏ
  Future<void> clearAllNotifications(String userId) async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('notifications').where('userId', isEqualTo: userId).get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('РћС€РёР±РєР° РѕС‡РёСЃС‚РєРё РІСЃРµС… СѓРІРµРґРѕРјР»РµРЅРёР№: $e');
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃС‚Р°С‚РёСЃС‚РёРєСѓ СѓРІРµРґРѕРјР»РµРЅРёР№
  Future<NotificationStats> getNotificationStats(String userId) async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('notifications').where('userId', isEqualTo: userId).get();

      var total = 0;
      var unread = 0;
      var archived = 0;
      final byType = <NotificationType, int>{};
      final byPriority = <NotificationPriority, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        total++;

        if (data['isRead'] == false) unread++;
        if (data['isArchived'] == true) archived++;

        final type = NotificationType.fromString(data['type'] as String);
        byType[type] = (byType[type] ?? 0) + 1;

        final priority = NotificationPriority.fromString(
          data['priority'] as String? ?? 'normal',
        );
        byPriority[priority] = (byPriority[priority] ?? 0) + 1;
      }

      return NotificationStats(
        total: total,
        unread: unread,
        archived: archived,
        byType: byType,
        byPriority: byPriority,
      );
    } catch (e) {
      throw Exception('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃС‚Р°С‚РёСЃС‚РёРєРё СѓРІРµРґРѕРјР»РµРЅРёР№: $e');
    }
  }

  /// РџРѕРґРїРёСЃР°С‚СЊСЃСЏ РЅР° С‚РѕРїРёРє
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      throw Exception('РћС€РёР±РєР° РїРѕРґРїРёСЃРєРё РЅР° С‚РѕРїРёРє: $e');
    }
  }

  /// РћС‚РїРёСЃР°С‚СЊСЃСЏ РѕС‚ С‚РѕРїРёРєР°
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      throw Exception('РћС€РёР±РєР° РѕС‚РїРёСЃРєРё РѕС‚ С‚РѕРїРёРєР°: $e');
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ FCM С‚РѕРєРµРЅ
  Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      throw Exception('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ FCM С‚РѕРєРµРЅР°: $e');
    }
  }

  /// РЎРѕС…СЂР°РЅРёС‚СЊ FCM С‚РѕРєРµРЅ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<void> saveFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('РћС€РёР±РєР° СЃРѕС…СЂР°РЅРµРЅРёСЏ FCM С‚РѕРєРµРЅР°: $e');
    }
  }
}

/// РћР±СЂР°Р±РѕС‚С‡РёРє СЃРѕРѕР±С‰РµРЅРёР№ РІ С„РѕРЅРµ
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('РћР±СЂР°Р±РѕС‚РєР° СЃРѕРѕР±С‰РµРЅРёСЏ РІ С„РѕРЅРµ: ${message.messageId}');
  // TODO: РћР±СЂР°Р±РѕС‚РєР° СЃРѕРѕР±С‰РµРЅРёСЏ РІ С„РѕРЅРµ
}

