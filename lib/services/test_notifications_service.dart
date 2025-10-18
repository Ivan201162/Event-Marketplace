import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ РґР»СЏ СЃРѕР·РґР°РЅРёСЏ С‚РµСЃС‚РѕРІС‹С… СѓРІРµРґРѕРјР»РµРЅРёР№
class TestNotificationsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// РЎРѕР·РґР°С‚СЊ С‚РµСЃС‚РѕРІС‹Рµ СѓРІРµРґРѕРјР»РµРЅРёСЏ РґР»СЏ С‚РµРєСѓС‰РµРіРѕ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  static Future<void> createTestNotificationsForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await createTestNotifications(user.uid);
  }

  /// РЎРѕР·РґР°С‚СЊ С‚РµСЃС‚РѕРІС‹Рµ СѓРІРµРґРѕРјР»РµРЅРёСЏ РґР»СЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  static Future<void> createTestNotifications(String userId) async {
    try {
      // РџСЂРѕРІРµСЂСЏРµРј, РµСЃС‚СЊ Р»Рё СѓР¶Рµ СѓРІРµРґРѕРјР»РµРЅРёСЏ
      final existingNotifications =
          await _firestore.collection('notifications').where('userId', isEqualTo: userId).get();

      if (existingNotifications.docs.isNotEmpty) {
        debugPrint(
          'РўРµСЃС‚РѕРІС‹Рµ СѓРІРµРґРѕРјР»РµРЅРёСЏ СѓР¶Рµ СЃСѓС‰РµСЃС‚РІСѓСЋС‚ РґР»СЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ $userId',
        );
        return;
      }

      final testNotifications = [
        {
          'userId': userId,
          'title': 'РќРѕРІРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ',
          'body': 'РЈ РІР°СЃ РЅРѕРІРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ РѕС‚ СЃРїРµС†РёР°Р»РёСЃС‚Р° РђРЅРЅС‹ Р›РµР±РµРґРµРІРѕР№',
          'type': 'message',
          'data': {
            'chatId': 'chat_1',
            'senderId': 'specialist_2',
            'senderName': 'РђРЅРЅР° Р›РµР±РµРґРµРІР°',
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': userId,
          'title': 'Р—Р°СЏРІРєР° РїРѕРґС‚РІРµСЂР¶РґРµРЅР°',
          'body': 'Р’Р°С€Р° Р·Р°СЏРІРєР° РЅР° С„РѕС‚РѕСЃРµСЃСЃРёСЋ РїРѕРґС‚РІРµСЂР¶РґРµРЅР° СЃРїРµС†РёР°Р»РёСЃС‚РѕРј',
          'type': 'booking',
          'data': {
            'bookingId': 'booking_1',
            'specialistId': 'specialist_2',
            'specialistName': 'РђРЅРЅР° Р›РµР±РµРґРµРІР°',
            'service': 'Р¤РѕС‚РѕСЃРµСЃСЃРёСЏ',
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': userId,
          'title': 'РќРѕРІС‹Р№ РѕС‚Р·С‹РІ',
          'body': 'РљС‚Рѕ-С‚Рѕ РѕСЃС‚Р°РІРёР» РѕС‚Р·С‹РІ Рѕ РІР°С€РµР№ СЂР°Р±РѕС‚Рµ - "РћС‚Р»РёС‡РЅР°СЏ РѕСЂРіР°РЅРёР·Р°С†РёСЏ!"',
          'type': 'review',
          'data': {
            'reviewId': 'review_1',
            'rating': 5,
            'comment': 'РћС‚Р»РёС‡РЅР°СЏ РѕСЂРіР°РЅРёР·Р°С†РёСЏ!',
          },
          'isRead': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': userId,
          'title': 'РЎРёСЃС‚РµРјРЅРѕРµ СѓРІРµРґРѕРјР»РµРЅРёРµ',
          'body': 'РџСЂРёР»РѕР¶РµРЅРёРµ РѕР±РЅРѕРІР»РµРЅРѕ РґРѕ РІРµСЂСЃРёРё 1.0.0. Р”РѕР±Р°РІР»РµРЅС‹ РЅРѕРІС‹Рµ С„СѓРЅРєС†РёРё!',
          'type': 'system',
          'data': {
            'version': '1.0.0',
            'features': ['РќР°СЃС‚СЂРѕР№РєРё', 'РЈРІРµРґРѕРјР»РµРЅРёСЏ', 'РўРµРјС‹'],
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': userId,
          'title': 'РќР°РїРѕРјРёРЅР°РЅРёРµ Рѕ РІСЃС‚СЂРµС‡Рµ',
          'body': 'Р§РµСЂРµР· 2 С‡Р°СЃР° Сѓ РІР°СЃ РІСЃС‚СЂРµС‡Р° СЃ С„РѕС‚РѕРіСЂР°С„РѕРј',
          'type': 'system',
          'data': {
            'reminderType': 'meeting',
            'time': '14:00',
            'specialist': 'РђРЅРЅР° Р›РµР±РµРґРµРІР°',
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': userId,
          'title': 'РќРѕРІРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ',
          'body': 'РђР»РµРєСЃРµР№ РЎРјРёСЂРЅРѕРІ: "Р“РѕС‚РѕРІ РѕР±СЃСѓРґРёС‚СЊ РґРµС‚Р°Р»Рё РІР°С€РµРіРѕ РјРµСЂРѕРїСЂРёСЏС‚РёСЏ"',
          'type': 'message',
          'data': {
            'chatId': 'chat_2',
            'senderId': 'specialist_1',
            'senderName': 'РђР»РµРєСЃРµР№ РЎРјРёСЂРЅРѕРІ',
            'messagePreview': 'Р“РѕС‚РѕРІ РѕР±СЃСѓРґРёС‚СЊ РґРµС‚Р°Р»Рё РІР°С€РµРіРѕ РјРµСЂРѕРїСЂРёСЏС‚РёСЏ',
          },
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

      debugPrint(
        'РЎРѕР·РґР°РЅРѕ ${testNotifications.length} С‚РµСЃС‚РѕРІС‹С… СѓРІРµРґРѕРјР»РµРЅРёР№ РґР»СЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ $userId',
      );
    } catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ С‚РµСЃС‚РѕРІС‹С… СѓРІРµРґРѕРјР»РµРЅРёР№: $e');
    }
  }

  /// РЎРѕР·РґР°С‚СЊ С‚РµСЃС‚РѕРІС‹Рµ СѓРІРµРґРѕРјР»РµРЅРёСЏ РґР»СЏ РІСЃРµС… РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№
  static Future<void> createTestNotificationsForAllUsers() async {
    try {
      // РџРѕР»СѓС‡Р°РµРј РІСЃРµС… РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№
      final usersSnapshot = await _firestore.collection('users').get();

      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        await createTestNotifications(userId);
      }

      debugPrint(
        'РЎРѕР·РґР°РЅС‹ С‚РµСЃС‚РѕРІС‹Рµ СѓРІРµРґРѕРјР»РµРЅРёСЏ РґР»СЏ ${usersSnapshot.docs.length} РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№',
      );
    } catch (e) {
      debugPrint(
        'РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ С‚РµСЃС‚РѕРІС‹С… СѓРІРµРґРѕРјР»РµРЅРёР№ РґР»СЏ РІСЃРµС… РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№: $e',
      );
    }
  }

  /// РћС‡РёСЃС‚РёС‚СЊ РІСЃРµ С‚РµСЃС‚РѕРІС‹Рµ СѓРІРµРґРѕРјР»РµРЅРёСЏ
  static Future<void> clearAllTestNotifications() async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore.collection('notifications').get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('РћС‡РёС‰РµРЅС‹ РІСЃРµ С‚РµСЃС‚РѕРІС‹Рµ СѓРІРµРґРѕРјР»РµРЅРёСЏ');
    } catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‡РёСЃС‚РєРё С‚РµСЃС‚РѕРІС‹С… СѓРІРµРґРѕРјР»РµРЅРёР№: $e');
    }
  }

  /// РћС‡РёСЃС‚РёС‚СЊ С‚РµСЃС‚РѕРІС‹Рµ СѓРІРµРґРѕРјР»РµРЅРёСЏ РґР»СЏ РєРѕРЅРєСЂРµС‚РЅРѕРіРѕ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  static Future<void> clearTestNotificationsForUser(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications =
          await _firestore.collection('notifications').where('userId', isEqualTo: userId).get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('РћС‡РёС‰РµРЅС‹ С‚РµСЃС‚РѕРІС‹Рµ СѓРІРµРґРѕРјР»РµРЅРёСЏ РґР»СЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ $userId');
    } catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‡РёСЃС‚РєРё С‚РµСЃС‚РѕРІС‹С… СѓРІРµРґРѕРјР»РµРЅРёР№ РґР»СЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ: $e');
    }
  }
}

