import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ РґР»СЏ СЂР°Р±РѕС‚С‹ СЃ Firebase Cloud Messaging
class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// РРЅРёС†РёР°Р»РёР·Р°С†РёСЏ FCM
  static Future<void> initialize() async {
    // РќР°СЃС‚СЂРѕР№РєР° Р»РѕРєР°Р»СЊРЅС‹С… СѓРІРµРґРѕРјР»РµРЅРёР№
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Р—Р°РїСЂРѕСЃ СЂР°Р·СЂРµС€РµРЅРёР№
    await _requestPermissions();

    // РќР°СЃС‚СЂРѕР№РєР° РѕР±СЂР°Р±РѕС‚С‡РёРєРѕРІ СЃРѕРѕР±С‰РµРЅРёР№
    _setupMessageHandlers();

    // РџРѕР»СѓС‡РµРЅРёРµ С‚РѕРєРµРЅР°
    await _getToken();
  }

  /// Р—Р°РїСЂРѕСЃ СЂР°Р·СЂРµС€РµРЅРёР№ РЅР° СѓРІРµРґРѕРјР»РµРЅРёСЏ
  static Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission();

    debugPrint('Р Р°Р·СЂРµС€РµРЅРёСЏ РЅР° СѓРІРµРґРѕРјР»РµРЅРёСЏ: ${settings.authorizationStatus}');
  }

  /// РќР°СЃС‚СЂРѕР№РєР° РѕР±СЂР°Р±РѕС‚С‡РёРєРѕРІ СЃРѕРѕР±С‰РµРЅРёР№
  static void _setupMessageHandlers() {
    // РћР±СЂР°Р±РѕС‚РєР° СЃРѕРѕР±С‰РµРЅРёР№ РІ foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // РћР±СЂР°Р±РѕС‚РєР° СЃРѕРѕР±С‰РµРЅРёР№ РІ background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // РћР±СЂР°Р±РѕС‚РєР° РЅР°Р¶Р°С‚РёР№ РЅР° СѓРІРµРґРѕРјР»РµРЅРёСЏ (РєРѕРіРґР° РїСЂРёР»РѕР¶РµРЅРёРµ РІ С„РѕРЅРµ)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // РћР±СЂР°Р±РѕС‚РєР° РЅР°Р¶Р°С‚РёР№ РЅР° СѓРІРµРґРѕРјР»РµРЅРёСЏ (РєРѕРіРґР° РїСЂРёР»РѕР¶РµРЅРёРµ Р·Р°РєСЂС‹С‚Рѕ)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _saveNotificationToHistory(message);
        _handleNotificationTap(message);
      }
    });
  }

  /// РћР±СЂР°Р±РѕС‚РєР° СЃРѕРѕР±С‰РµРЅРёР№ РІ foreground
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint(
      'рџ“¬ РџРѕР»СѓС‡РµРЅРѕ СѓРІРµРґРѕРјР»РµРЅРёРµ РІ foreground: ${message.notification?.title}',
    );

    // РЎРѕС…СЂР°РЅСЏРµРј СѓРІРµРґРѕРјР»РµРЅРёРµ РІ РёСЃС‚РѕСЂРёСЋ
    await _saveNotificationToHistory(message);

    final notification = message.notification;
    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'event_channel',
            'Event Marketplace',
            channelDescription: 'РЈРІРµРґРѕРјР»РµРЅРёСЏ РѕС‚ Event Marketplace',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: _getNotificationColor(message.data['type'] ?? 'system'),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: _createPayload(message.data),
      );
    }
  }

  /// РћР±СЂР°Р±РѕС‚РєР° РЅР°Р¶Р°С‚РёР№ РЅР° СѓРІРµРґРѕРјР»РµРЅРёСЏ
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('рџ”” РќР°Р¶Р°С‚Рѕ РЅР° СѓРІРµРґРѕРјР»РµРЅРёРµ: ${message.notification?.title}');

    final data = message.data;
    if (data.containsKey('type')) {
      _navigateToScreen(data['type'], data);
    }
  }

  /// РћР±СЂР°Р±РѕС‚РєР° РЅР°Р¶Р°С‚РёР№ РЅР° Р»РѕРєР°Р»СЊРЅС‹Рµ СѓРІРµРґРѕРјР»РµРЅРёСЏ
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('рџ”” РќР°Р¶Р°С‚Рѕ РЅР° Р»РѕРєР°Р»СЊРЅРѕРµ СѓРІРµРґРѕРјР»РµРЅРёРµ: ${response.payload}');

    if (response.payload != null) {
      _navigateToScreenFromPayload(response.payload!);
    }
  }

  /// РќР°РІРёРіР°С†РёСЏ Рє СЌРєСЂР°РЅСѓ РЅР° РѕСЃРЅРѕРІРµ С‚РёРїР° СѓРІРµРґРѕРјР»РµРЅРёСЏ
  static void _navigateToScreen(String type, Map<String, dynamic> data) {
    debugPrint('РќР°РІРёРіР°С†РёСЏ Рє СЌРєСЂР°РЅСѓ С‚РёРїР°: $type СЃ РґР°РЅРЅС‹РјРё: $data');

    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (type) {
      case 'chat':
        final chatId = data['id'] ?? data['chatId'];
        if (chatId != null) {
          context.push('/chat/$chatId');
        }
        break;
      case 'post':
        final postId = data['id'] ?? data['postId'];
        if (postId != null) {
          context.push('/post/$postId');
        }
        break;
      case 'request':
        final requestId = data['id'] ?? data['requestId'];
        if (requestId != null) {
          context.push('/request/$requestId');
        } else {
          context.go('/requests');
        }
        break;
      case 'profile':
        final userId = data['id'] ?? data['userId'];
        if (userId != null) {
          context.push('/profile/$userId');
        }
        break;
      case 'like':
      case 'comment':
        final postId = data['id'] ?? data['postId'];
        if (postId != null) {
          context.push('/post/$postId');
        }
        break;
      case 'follow':
        final userId = data['id'] ?? data['userId'];
        if (userId != null) {
          context.push('/profile/$userId');
        }
        break;
      default:
        context.go('/notifications');
    }
  }

  /// РќР°РІРёРіР°С†РёСЏ Рє СЌРєСЂР°РЅСѓ РЅР° РѕСЃРЅРѕРІРµ payload
  static void _navigateToScreenFromPayload(String payload) {
    try {
      final data = <String, dynamic>{};
      final pairs = payload.split('&');
      for (final pair in pairs) {
        final keyValue = pair.split('=');
        if (keyValue.length == 2) {
          data[keyValue[0]] = keyValue[1];
        }
      }

      if (data.containsKey('type')) {
        _navigateToScreen(data['type'], data);
      }
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїР°СЂСЃРёРЅРіР° payload: $e');
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ FCM С‚РѕРєРµРЅР°
  static Future<String?> _getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ FCM С‚РѕРєРµРЅР°: $e');
      return null;
    }
  }

  /// РЎРѕС…СЂР°РЅРµРЅРёРµ С‚РѕРєРµРЅР° РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ РІ Firestore
  static Future<void> saveUserToken(String userId) async {
    try {
      final token = await _getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM С‚РѕРєРµРЅ СЃРѕС…СЂР°РЅС‘РЅ РґР»СЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ: $userId');
      }
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕС…СЂР°РЅРµРЅРёСЏ FCM С‚РѕРєРµРЅР°: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЋ
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј С‚РѕРєРµРЅ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken'];

      if (fcmToken != null) {
        // TODO: РћС‚РїСЂР°РІРєР° С‡РµСЂРµР· Firebase Admin SDK РёР»Рё Cloud Functions
        debugPrint('РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЋ $userId: $title');

        // РЎРѕР·РґР°РµРј СѓРІРµРґРѕРјР»РµРЅРёРµ РІ Firestore
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId,
          'title': title,
          'body': body,
          'type': type,
          'data': data,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‚РїСЂР°РІРєРё СѓРІРµРґРѕРјР»РµРЅРёСЏ: $e');
    }
  }

  /// РџРѕРґРїРёСЃРєР° РЅР° С‚РѕРїРёРє
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('РџРѕРґРїРёСЃР°Р»РёСЃСЊ РЅР° С‚РѕРїРёРє: $topic');
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕРґРїРёСЃРєРё РЅР° С‚РѕРїРёРє: $e');
    }
  }

  /// РћС‚РїРёСЃРєР° РѕС‚ С‚РѕРїРёРєР°
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('РћС‚РїРёСЃР°Р»РёСЃСЊ РѕС‚ С‚РѕРїРёРєР°: $topic');
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‚РїРёСЃРєРё РѕС‚ С‚РѕРїРёРєР°: $e');
    }
  }

  /// РЎРѕС…СЂР°РЅРµРЅРёРµ СѓРІРµРґРѕРјР»РµРЅРёСЏ РІ РёСЃС‚РѕСЂРёСЋ
  static Future<void> _saveNotificationToHistory(RemoteMessage message) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final notification = message.notification;
      final data = message.data;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications_history')
          .add({
        'title': notification?.title ?? '',
        'body': notification?.body ?? '',
        'type': data['type'] ?? 'system',
        'targetId': data['id'] ?? data['targetId'] ?? '',
        'senderId': data['senderId'] ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'isPinned': false,
        'data': data,
      });

      debugPrint('РЈРІРµРґРѕРјР»РµРЅРёРµ СЃРѕС…СЂР°РЅРµРЅРѕ РІ РёСЃС‚РѕСЂРёСЋ РґР»СЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ: $userId');
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕС…СЂР°РЅРµРЅРёСЏ СѓРІРµРґРѕРјР»РµРЅРёСЏ РІ РёСЃС‚РѕСЂРёСЋ: $e');
    }
  }

  /// РЎРѕР·РґР°РЅРёРµ payload РґР»СЏ Р»РѕРєР°Р»СЊРЅС‹С… СѓРІРµРґРѕРјР»РµРЅРёР№
  static String _createPayload(Map<String, dynamic> data) {
    final payload = <String>[];
    data.forEach((key, value) {
      payload.add('$key=$value');
    });
    return payload.join('&');
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ С†РІРµС‚Р° РґР»СЏ С‚РёРїР° СѓРІРµРґРѕРјР»РµРЅРёСЏ
  static Color _getNotificationColor(String type) {
    switch (type) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.blue;
      case 'follow':
        return Colors.green;
      case 'request':
        return Colors.orange;
      case 'message':
        return Colors.purple;
      case 'booking':
        return Colors.teal;
      case 'system':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}

/// РћР±СЂР°Р±РѕС‚С‡РёРє С„РѕРЅРѕРІС‹С… СЃРѕРѕР±С‰РµРЅРёР№
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('рџ“¬ РџРѕР»СѓС‡РµРЅРѕ СѓРІРµРґРѕРјР»РµРЅРёРµ РІ С„РѕРЅРµ: ${message.notification?.title}');

  // РРЅРёС†РёР°Р»РёР·РёСЂСѓРµРј Firebase
  await Firebase.initializeApp();

  // РЎРѕС…СЂР°РЅСЏРµРј СѓРІРµРґРѕРјР»РµРЅРёРµ РІ РёСЃС‚РѕСЂРёСЋ
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final notification = message.notification;
      final data = message.data;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications_history')
          .add({
        'title': notification?.title ?? '',
        'body': notification?.body ?? '',
        'type': data['type'] ?? 'system',
        'targetId': data['id'] ?? data['targetId'] ?? '',
        'senderId': data['senderId'] ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'isPinned': false,
        'data': data,
      });
    }
  } catch (e) {
    debugPrint('РћС€РёР±РєР° СЃРѕС…СЂР°РЅРµРЅРёСЏ С„РѕРЅРѕРІРѕРіРѕ СѓРІРµРґРѕРјР»РµРЅРёСЏ: $e');
  }
}

