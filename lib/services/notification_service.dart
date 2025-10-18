import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../models/advertisement.dart';
import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import 'package:flutter/foundation.dart';
import '../models/promotion_boost.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription_plan.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart' as transaction_model;

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// РРЅРёС†РёР°Р»РёР·Р°С†РёСЏ СЃРµСЂРІРёСЃР° СѓРІРµРґРѕРјР»РµРЅРёР№
  static Future<void> initialize() async {
    try {
      // Р—Р°РїСЂРѕСЃ СЂР°Р·СЂРµС€РµРЅРёР№ РЅР° СѓРІРµРґРѕРјР»РµРЅРёСЏ
      final NotificationSettings settings = await _messaging.requestPermission();

      debugPrint('INFO: [NotificationService] Permission status: ${settings.authorizationStatus}');

      // РџРѕР»СѓС‡РµРЅРёРµ FCM С‚РѕРєРµРЅР°
      final String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('INFO: [NotificationService] FCM Token: $token');
        await _saveFCMToken(token);
      }

      // РћР±СЂР°Р±РѕС‚РєР° СѓРІРµРґРѕРјР»РµРЅРёР№ РІ С„РѕРЅРµ
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // РћР±СЂР°Р±РѕС‚РєР° СѓРІРµРґРѕРјР»РµРЅРёР№ РІ foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // РћР±СЂР°Р±РѕС‚РєР° РЅР°Р¶Р°С‚РёР№ РЅР° СѓРІРµРґРѕРјР»РµРЅРёСЏ
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      debugPrint('INFO: [NotificationService] Initialized successfully');
    } catch (e) {
      debugPrint('ERROR: [NotificationService] Initialization failed: $e');
    }
  }

  /// РЎРѕС…СЂР°РЅРµРЅРёРµ FCM С‚РѕРєРµРЅР° РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  static Future<void> _saveFCMToken(String token) async {
    try {
      // Р—РґРµСЃСЊ РЅСѓР¶РЅРѕ РїРѕР»СѓС‡РёС‚СЊ ID С‚РµРєСѓС‰РµРіРѕ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
      // Р”Р»СЏ РґРµРјРѕРЅСЃС‚СЂР°С†РёРё РёСЃРїРѕР»СЊР·СѓРµРј С„РёРєСЃРёСЂРѕРІР°РЅРЅС‹Р№ ID
      const String userId = 'current_user_id'; // TODO: РџРѕР»СѓС‡РёС‚СЊ РёР· AuthService

      await _firestore.collection('user_tokens').doc(userId).set({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': 'android', // РёР»Рё 'ios'
      });
    } catch (e) {
      debugPrint('ERROR: [NotificationService] Failed to save FCM token: $e');
    }
  }

  /// РћР±СЂР°Р±РѕС‚РєР° СѓРІРµРґРѕРјР»РµРЅРёР№ РІ С„РѕРЅРµ
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    debugPrint('INFO: [NotificationService] Background message: ${message.messageId}');
    debugPrint('INFO: [NotificationService] Data: ${message.data}');
  }

  /// РћР±СЂР°Р±РѕС‚РєР° СѓРІРµРґРѕРјР»РµРЅРёР№ РІ foreground
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('INFO: [NotificationService] Foreground message: ${message.messageId}');
    debugPrint('INFO: [NotificationService] Title: ${message.notification?.title}');
    debugPrint('INFO: [NotificationService] Body: ${message.notification?.body}');
    debugPrint('INFO: [NotificationService] Data: ${message.data}');

    // Р—РґРµСЃСЊ РјРѕР¶РЅРѕ РїРѕРєР°Р·Р°С‚СЊ in-app СѓРІРµРґРѕРјР»РµРЅРёРµ
    _showInAppNotification(message);
  }

  /// РћР±СЂР°Р±РѕС‚РєР° РЅР°Р¶Р°С‚РёР№ РЅР° СѓРІРµРґРѕРјР»РµРЅРёСЏ
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('INFO: [NotificationService] Notification tapped: ${message.messageId}');
    debugPrint('INFO: [NotificationService] Data: ${message.data}');

    // РќР°РІРёРіР°С†РёСЏ РЅР° СЃРѕРѕС‚РІРµС‚СЃС‚РІСѓСЋС‰РёР№ СЌРєСЂР°РЅ
    _navigateFromNotification(message.data);
  }

  /// РџРѕРєР°Р· in-app СѓРІРµРґРѕРјР»РµРЅРёСЏ
  static void _showInAppNotification(RemoteMessage message) {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РїРѕРєР°Р· in-app СѓРІРµРґРѕРјР»РµРЅРёСЏ
    // РњРѕР¶РЅРѕ РёСЃРїРѕР»СЊР·РѕРІР°С‚СЊ Overlay РёР»Рё SnackBar
  }

  /// РќР°РІРёРіР°С†РёСЏ РЅР° РѕСЃРЅРѕРІРµ РґР°РЅРЅС‹С… СѓРІРµРґРѕРјР»РµРЅРёСЏ
  static void _navigateFromNotification(Map<String, dynamic> data) {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РЅР°РІРёРіР°С†РёСЋ РЅР° РѕСЃРЅРѕРІРµ С‚РёРїР° СѓРІРµРґРѕРјР»РµРЅРёСЏ
    final String? type = data['type'];
    final String? id = data['id'];

    switch (type) {
      case 'subscription':
        // РќР°РІРёРіР°С†РёСЏ Рє РїРѕРґРїРёСЃРєР°Рј
        break;
      case 'promotion':
        // РќР°РІРёРіР°С†РёСЏ Рє РїСЂРѕРґРІРёР¶РµРЅРёСЏРј
        break;
      case 'advertisement':
        // РќР°РІРёРіР°С†РёСЏ Рє СЂРµРєР»Р°РјРµ
        break;
      case 'payment':
        // РќР°РІРёРіР°С†РёСЏ Рє С‚СЂР°РЅР·Р°РєС†РёСЏРј
        break;
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ СѓСЃРїРµС€РЅРѕР№ РѕРїР»Р°С‚Рµ
  static Future<void> sendPaymentSuccessNotification({
    required String userId,
    required transaction_model.Transaction transaction,
  }) async {
    try {
      final AppNotification notification = AppNotification(
        id: 'payment_success_${transaction.id}',
        userId: userId,
        type: NotificationType.payment.toString(),
        title: 'РџР»Р°С‚РµР¶ СѓСЃРїРµС€РЅРѕ РѕР±СЂР°Р±РѕС‚Р°РЅ',
        body:
            'Р’Р°С€ РїР»Р°С‚РµР¶ РЅР° СЃСѓРјРјСѓ ${transaction.amount} ${transaction.currency} СѓСЃРїРµС€РЅРѕ РѕР±СЂР°Р±РѕС‚Р°РЅ.',
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

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ Р°РєС‚РёРІР°С†РёРё РїРѕРґРїРёСЃРєРё
  static Future<void> sendSubscriptionActivatedNotification({
    required String userId,
    required UserSubscription subscription,
  }) async {
    try {
      final AppNotification notification = AppNotification(
        id: 'subscription_activated_${subscription.id}',
        userId: userId,
        type: NotificationType.subscription.toString(),
        title: 'РџРѕРґРїРёСЃРєР° Р°РєС‚РёРІРёСЂРѕРІР°РЅР°',
        body:
            'Р’Р°С€Р° РїРѕРґРїРёСЃРєР° СѓСЃРїРµС€РЅРѕ Р°РєС‚РёРІРёСЂРѕРІР°РЅР° Рё РґРµР№СЃС‚РІСѓРµС‚ РґРѕ ${subscription.endDate.toLocal().toString().split(' ')[0]}.',
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
      debugPrint(
          'ERROR: [NotificationService] Failed to send subscription activated notification: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ РёСЃС‚РµС‡РµРЅРёРё РїРѕРґРїРёСЃРєРё
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
        title: 'РџРѕРґРїРёСЃРєР° РёСЃС‚РµРєР°РµС‚',
        body:
            'Р’Р°С€Р° РїРѕРґРїРёСЃРєР° РёСЃС‚РµРєР°РµС‚ С‡РµСЂРµР· $daysLeft ${_getDaysText(daysLeft)}. РџСЂРѕРґР»РёС‚Рµ РµС‘, С‡С‚РѕР±С‹ СЃРѕС…СЂР°РЅРёС‚СЊ РґРѕСЃС‚СѓРї Рє РїСЂРµРјРёСѓРј-С„СѓРЅРєС†РёСЏРј.',
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
      debugPrint(
          'ERROR: [NotificationService] Failed to send subscription expiring notification: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ Р°РєС‚РёРІР°С†РёРё РїСЂРѕРґРІРёР¶РµРЅРёСЏ
  static Future<void> sendPromotionActivatedNotification({
    required String userId,
    required PromotionBoost promotion,
  }) async {
    try {
      final AppNotification notification = AppNotification(
        id: 'promotion_activated_${promotion.id}',
        userId: userId,
        type: NotificationType.promotion.toString(),
        title: 'РџСЂРѕРґРІРёР¶РµРЅРёРµ Р°РєС‚РёРІРёСЂРѕРІР°РЅРѕ',
        body:
            'Р’Р°С€Рµ РїСЂРѕРґРІРёР¶РµРЅРёРµ СѓСЃРїРµС€РЅРѕ Р°РєС‚РёРІРёСЂРѕРІР°РЅРѕ Рё Р±СѓРґРµС‚ РґРµР№СЃС‚РІРѕРІР°С‚СЊ РґРѕ ${promotion.endDate.toLocal().toString().split(' ')[0]}.',
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
      debugPrint(
          'ERROR: [NotificationService] Failed to send promotion activated notification: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ РјРѕРґРµСЂР°С†РёРё СЂРµРєР»Р°РјС‹
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
          title = 'Р РµРєР»Р°РјР° РѕРґРѕР±СЂРµРЅР°';
          message =
              'Р’Р°С€Р° СЂРµРєР»Р°РјР° "${advertisement.title}" РѕРґРѕР±СЂРµРЅР° Рё С‚РµРїРµСЂСЊ РїРѕРєР°Р·С‹РІР°РµС‚СЃСЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏРј.';
          break;
        case AdStatus.rejected:
          title = 'Р РµРєР»Р°РјР° РѕС‚РєР»РѕРЅРµРЅР°';
          message =
              'Р’Р°С€Р° СЂРµРєР»Р°РјР° "${advertisement.title}" Р±С‹Р»Р° РѕС‚РєР»РѕРЅРµРЅР° РјРѕРґРµСЂР°С‚РѕСЂРѕРј. РџСЂРѕРІРµСЂСЊС‚Рµ СЃРѕРѕС‚РІРµС‚СЃС‚РІРёРµ РїСЂР°РІРёР»Р°Рј РїР»Р°С‚С„РѕСЂРјС‹.';
          break;
        default:
          title = 'РЎС‚Р°С‚СѓСЃ СЂРµРєР»Р°РјС‹ РёР·РјРµРЅРµРЅ';
          message =
              'РЎС‚Р°С‚СѓСЃ РІР°С€РµР№ СЂРµРєР»Р°РјС‹ "${advertisement.title}" РёР·РјРµРЅРµРЅ РЅР° ${status.toString().split('.').last}.';
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
      debugPrint(
          'ERROR: [NotificationService] Failed to send advertisement moderation notification: $e');
    }
  }

  /// РЎРѕР·РґР°РЅРёРµ СѓРІРµРґРѕРјР»РµРЅРёСЏ РІ Firestore
  static Future<void> _createNotification(AppNotification notification) async {
    try {
      await _firestore.collection('notifications').doc(notification.id).set(notification.toMap());
    } catch (e) {
      debugPrint('ERROR: [NotificationService] Failed to create notification: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° push СѓРІРµРґРѕРјР»РµРЅРёСЏ С‡РµСЂРµР· FCM
  static Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј FCM С‚РѕРєРµРЅ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
      final DocumentSnapshot tokenDoc =
          await _firestore.collection('user_tokens').doc(userId).get();

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

      // РћС‚РїСЂР°РІР»СЏРµРј СѓРІРµРґРѕРјР»РµРЅРёРµ С‡РµСЂРµР· Cloud Functions
      // Р’ СЂРµР°Р»СЊРЅРѕРј РїСЂРёР»РѕР¶РµРЅРёРё СЌС‚Рѕ РґРѕР»Р¶РЅРѕ Р±С‹С‚СЊ СЂРµР°Р»РёР·РѕРІР°РЅРѕ С‡РµСЂРµР· Cloud Functions
      debugPrint('INFO: [NotificationService] Would send push notification to token: $token');
      debugPrint('INFO: [NotificationService] Title: $title');
      debugPrint('INFO: [NotificationService] Body: $body');
      debugPrint('INFO: [NotificationService] Data: $data');
    } catch (e) {
      debugPrint('ERROR: [NotificationService] Failed to send push notification: $e');
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ СѓРІРµРґРѕРјР»РµРЅРёР№ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  static Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
            (snapshot) => snapshot.docs.map((doc) => AppNotification.fromMap(doc.data())).toList());
  }

  /// РћС‚РјРµС‚РєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ РєР°Рє РїСЂРѕС‡РёС‚Р°РЅРЅРѕРіРѕ
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

  /// РџРѕР»СѓС‡РёС‚СЊ РєРѕР»РёС‡РµСЃС‚РІРѕ РЅРµРїСЂРѕС‡РёС‚Р°РЅРЅС‹С… СѓРІРµРґРѕРјР»РµРЅРёР№
  static Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('ERROR: [NotificationService] Failed to get unread count: $e');
      return 0;
    }
  }

  /// РћС‚РјРµС‚РёС‚СЊ СѓРІРµРґРѕРјР»РµРЅРёРµ РєР°Рє РїСЂРѕС‡РёС‚Р°РЅРЅРѕРµ (Р°Р»РёР°СЃ)
  static Future<void> markAsRead(String notificationId) async {
    return markNotificationAsRead(notificationId);
  }

  /// РћС‚РјРµС‚РёС‚СЊ РІСЃРµ СѓРІРµРґРѕРјР»РµРЅРёСЏ РєР°Рє РїСЂРѕС‡РёС‚Р°РЅРЅС‹Рµ
  static Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('ERROR: [NotificationService] Failed to mark all as read: $e');
    }
  }

  /// РЈРґР°Р»РµРЅРёРµ СѓРІРµРґРѕРјР»РµРЅРёСЏ
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      debugPrint('ERROR: [NotificationService] Failed to delete notification: $e');
    }
  }

  /// Р’СЃРїРѕРјРѕРіР°С‚РµР»СЊРЅС‹Р№ РјРµС‚РѕРґ РґР»СЏ СЃРєР»РѕРЅРµРЅРёСЏ СЃР»РѕРІР° "РґРµРЅСЊ"
  static String _getDaysText(int days) {
    if (days == 1) return 'РґРµРЅСЊ';
    if (days >= 2 && days <= 4) return 'РґРЅСЏ';
    return 'РґРЅРµР№';
  }
}

