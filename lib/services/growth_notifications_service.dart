import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class GrowthNotificationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ СЂРµС„РµСЂР°Р»Рµ
  Future<void> sendReferralNotification(String userId, Map<String, dynamic> referral) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'referral',
        'title': 'РќРѕРІС‹Р№ СЂРµС„РµСЂР°Р»!',
        'message': 'РџРѕР·РґСЂР°РІР»СЏРµРј! РљС‚Рѕ-С‚Рѕ Р·Р°СЂРµРіРёСЃС‚СЂРёСЂРѕРІР°Р»СЃСЏ РїРѕ РІР°С€РµР№ СЃСЃС‹Р»РєРµ',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/referral-program',
        'actionText': 'РџРѕСЃРјРѕС‚СЂРµС‚СЊ РїСЂРѕРіСЂР°РјРјСѓ',
        'data': {
          'referralId': referral['id'],
          'referralCode': referral['referralCode'],
          'bonusType': referral['bonusType'],
        },
      };

      await _firestore.collection('growth_notifications').doc(notification['id']).set(notification);

      debugPrint('INFO: [GrowthNotificationsService] Referral notification sent to user $userId');
    } catch (e) {
      debugPrint('ERROR: [GrowthNotificationsService] Failed to send referral notification: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ Р±РѕРЅСѓСЃРµ СЂРµС„РµСЂР°Р»Р°
  Future<void> sendReferralBonusNotification(
      String userId, String bonusType, Map<String, dynamic> bonusData) async {
    try {
      final String title = 'Р‘РѕРЅСѓСЃ РїРѕР»СѓС‡РµРЅ!';
      String message = '';

      switch (bonusType) {
        case 'freePromotion':
          message = 'Р’С‹ РїРѕР»СѓС‡РёР»Рё Р±РµСЃРїР»Р°С‚РЅРѕРµ РїСЂРѕРґРІРёР¶РµРЅРёРµ РїСЂРѕС„РёР»СЏ!';
          break;
        case 'discount':
          final double discount = (bonusData['discount'] ?? 0.0).toDouble();
          message = 'Р’С‹ РїРѕР»СѓС‡РёР»Рё СЃРєРёРґРєСѓ ${(discount * 100).toInt()}%!';
          break;
        case 'premiumTrial':
          final int days = bonusData['days'] ?? 0;
          message = 'Р’С‹ РїРѕР»СѓС‡РёР»Рё $days РґРЅРµР№ Premium Р±РµСЃРїР»Р°С‚РЅРѕ!';
          break;
        case 'proTrial':
          message = 'Р’С‹ РїРѕР»СѓС‡РёР»Рё РјРµСЃСЏС† PRO Р±РµСЃРїР»Р°С‚РЅРѕ!';
          break;
        case 'cashback':
          final double amount = (bonusData['amount'] ?? 0.0).toDouble();
          message = 'Р’С‹ РїРѕР»СѓС‡РёР»Рё РєСЌС€Р±СЌРє $amount СЂСѓР±Р»РµР№!';
          break;
        default:
          message = 'Р’С‹ РїРѕР»СѓС‡РёР»Рё Р±РѕРЅСѓСЃ!';
      }

      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'referral',
        'title': title,
        'message': message,
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/referral-program',
        'actionText': 'РџРѕСЃРјРѕС‚СЂРµС‚СЊ РїСЂРѕРіСЂР°РјРјСѓ',
        'data': {
          'bonusType': bonusType,
          'bonusData': bonusData,
        },
      };

      await _firestore.collection('growth_notifications').doc(notification['id']).set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] Referral bonus notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send referral bonus notification: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ РѕР± РёР·РјРµРЅРµРЅРёРё С†РµРЅС‹
  Future<void> sendPriceChangeNotification(
      String userId, Map<String, dynamic> pricingRule, double oldPrice, double newPrice) async {
    try {
      final double changePercent = ((newPrice - oldPrice) / oldPrice * 100);
      final String changeText = changePercent > 0 ? 'СѓРІРµР»РёС‡РёР»Р°СЃСЊ' : 'СѓРјРµРЅСЊС€РёР»Р°СЃСЊ';
      final String changeValue = changePercent.abs().toStringAsFixed(1);

      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'pricing',
        'title': 'РР·РјРµРЅРµРЅРёРµ С†РµРЅС‹',
        'message': 'Р¦РµРЅР° РЅР° ${pricingRule['serviceType']} $changeText РЅР° $changeValue%',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/monetization',
        'actionText': 'РџРѕСЃРјРѕС‚СЂРµС‚СЊ С‚Р°СЂРёС„С‹',
        'data': {
          'serviceType': pricingRule['serviceType'],
          'oldPrice': oldPrice,
          'newPrice': newPrice,
          'changePercent': changePercent,
        },
      };

      await _firestore.collection('growth_notifications').doc(notification['id']).set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] Price change notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send price change notification: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ РїР°СЂС‚РЅРµСЂСЃРєРѕР№ РєРѕРјРёСЃСЃРёРё
  Future<void> sendPartnerCommissionNotification(
      String userId, Map<String, dynamic> partnerTransaction) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'partnership',
        'title': 'РџР°СЂС‚РЅРµСЂСЃРєР°СЏ РєРѕРјРёСЃСЃРёСЏ',
        'message': 'Р’С‹ РїРѕР»СѓС‡РёР»Рё РєРѕРјРёСЃСЃРёСЋ ${partnerTransaction['commissionAmount']} СЂСѓР±.',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/partnership',
        'actionText': 'РџРѕСЃРјРѕС‚СЂРµС‚СЊ РїР°СЂС‚РЅРµСЂРєСѓ',
        'data': {
          'partnerTransactionId': partnerTransaction['id'],
          'commissionAmount': partnerTransaction['commissionAmount'],
          'transactionId': partnerTransaction['transactionId'],
        },
      };

      await _firestore.collection('growth_notifications').doc(notification['id']).set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] Partner commission notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send partner commission notification: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ РЅРѕРІРѕРј СЂРµРєР»Р°РјРЅРѕРј РїСЂРµРґР»РѕР¶РµРЅРёРё
  Future<void> sendNewAdOfferNotification(String userId, Map<String, dynamic> adOffer) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'advertisement',
        'title': 'РќРѕРІРѕРµ СЂРµРєР»Р°РјРЅРѕРµ РїСЂРµРґР»РѕР¶РµРЅРёРµ',
        'message': 'РЎРїРµС†РёР°Р»СЊРЅРѕРµ РїСЂРµРґР»РѕР¶РµРЅРёРµ РґР»СЏ РІР°С€РµР№ РєР°С‚РµРіРѕСЂРёРё!',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/monetization/advertisements',
        'actionText': 'РџРѕСЃРјРѕС‚СЂРµС‚СЊ РїСЂРµРґР»РѕР¶РµРЅРёСЏ',
        'data': {
          'adOffer': adOffer,
        },
      };

      await _firestore.collection('growth_notifications').doc(notification['id']).set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] New ad offer notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send new ad offer notification: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ РїСЂРѕРјРѕ-РєР°РјРїР°РЅРёРё
  Future<void> sendPromotionNotification(String userId, Map<String, dynamic> promotion) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'promotion',
        'title': 'РЎРїРµС†РёР°Р»СЊРЅРѕРµ РїСЂРµРґР»РѕР¶РµРЅРёРµ!',
        'message': promotion['description'],
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/monetization',
        'actionText': 'Р’РѕСЃРїРѕР»СЊР·РѕРІР°С‚СЊСЃСЏ',
        'data': {
          'promotionId': promotion['id'],
          'promotionName': promotion['name'],
          'trigger': promotion['trigger'],
        },
      };

      await _firestore.collection('growth_notifications').doc(notification['id']).set(notification);

      debugPrint('INFO: [GrowthNotificationsService] Promotion notification sent to user $userId');
    } catch (e) {
      debugPrint('ERROR: [GrowthNotificationsService] Failed to send promotion notification: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ С‡РµРєРµ
  Future<void> sendReceiptNotification(String userId, Map<String, dynamic> receipt) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'receipt',
        'title': 'Р§РµРє РіРѕС‚РѕРІ!',
        'message':
            'Р’Р°С€ С‡РµРє РЅР° СЃСѓРјРјСѓ ${receipt['amount']} ${receipt['currency']} РіРѕС‚РѕРІ Рє СЃРєР°С‡РёРІР°РЅРёСЋ',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/receipts/${receipt['id']}',
        'actionText': 'РЎРєР°С‡Р°С‚СЊ С‡РµРє',
        'data': {
          'receiptId': receipt['id'],
          'amount': receipt['amount'],
          'currency': receipt['currency'],
          'receiptUrl': receipt['receiptUrl'],
        },
      };

      await _firestore.collection('growth_notifications').doc(notification['id']).set(notification);

      debugPrint('INFO: [GrowthNotificationsService] Receipt notification sent to user $userId');
    } catch (e) {
      debugPrint('ERROR: [GrowthNotificationsService] Failed to send receipt notification: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ РЅРѕРІРѕРј С‡РµР»Р»РµРЅРґР¶Рµ
  Future<void> sendNewChallengeNotification(String userId, Map<String, dynamic> challenge) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'challenge',
        'title': 'РќРѕРІС‹Р№ С‡РµР»Р»РµРЅРґР¶!',
        'message': challenge['description'],
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/challenges/${challenge['id']}',
        'actionText': 'РџСЂРёРЅСЏС‚СЊ СѓС‡Р°СЃС‚РёРµ',
        'data': {
          'challengeId': challenge['id'],
          'challengeName': challenge['name'],
          'challengeType': challenge['type'],
          'endDate': challenge['endDate'],
        },
      };

      await _firestore.collection('growth_notifications').doc(notification['id']).set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] New challenge notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send new challenge notification: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ РїСЂРѕРіСЂРµСЃСЃРµ С‡РµР»Р»РµРЅРґР¶Р°
  Future<void> sendChallengeProgressNotification(
      String userId, Map<String, dynamic> challenge, Map<String, dynamic> progress) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'challenge',
        'title': 'РџСЂРѕРіСЂРµСЃСЃ РІ С‡РµР»Р»РµРЅРґР¶Рµ',
        'message': 'РћС‚Р»РёС‡РЅР°СЏ СЂР°Р±РѕС‚Р°! Р’С‹ РїСЂРёР±Р»РёР¶Р°РµС‚РµСЃСЊ Рє Р·Р°РІРµСЂС€РµРЅРёСЋ "${challenge['name']}"',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/challenges/${challenge['id']}',
        'actionText': 'РџРѕСЃРјРѕС‚СЂРµС‚СЊ РїСЂРѕРіСЂРµСЃСЃ',
        'data': {
          'challengeId': challenge['id'],
          'challengeName': challenge['name'],
          'progress': progress,
        },
      };

      await _firestore.collection('growth_notifications').doc(notification['id']).set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] Challenge progress notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send challenge progress notification: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ РЅРѕРІРѕРј РґРѕСЃС‚РёР¶РµРЅРёРё
  Future<void> sendNewAchievementNotification(
      String userId, Map<String, dynamic> achievement) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'achievement',
        'title': 'РќРѕРІРѕРµ РґРѕСЃС‚РёР¶РµРЅРёРµ!',
        'message': 'РџРѕР·РґСЂР°РІР»СЏРµРј! Р’С‹ РїРѕР»СѓС‡РёР»Рё РґРѕСЃС‚РёР¶РµРЅРёРµ "${achievement['name']}"',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/achievements',
        'actionText': 'РџРѕСЃРјРѕС‚СЂРµС‚СЊ РґРѕСЃС‚РёР¶РµРЅРёСЏ',
        'data': {
          'achievementId': achievement['id'],
          'achievementName': achievement['name'],
          'achievementType': achievement['type'],
          'points': achievement['points'],
        },
      };

      await _firestore.collection('growth_notifications').doc(notification['id']).set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] New achievement notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send new achievement notification: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ РЅРѕРІРѕРј Р·РЅР°С‡РєРµ
  Future<void> sendNewBadgeNotification(String userId, Map<String, dynamic> badge) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'badge',
        'title': 'РќРѕРІС‹Р№ Р·РЅР°С‡РѕРє!',
        'message': 'РџРѕР·РґСЂР°РІР»СЏРµРј! Р’С‹ РїРѕР»СѓС‡РёР»Рё Р·РЅР°С‡РѕРє "${badge['name']}"',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/profile/badges',
        'actionText': 'РџРѕСЃРјРѕС‚СЂРµС‚СЊ Р·РЅР°С‡РєРё',
        'data': {
          'badgeId': badge['id'],
          'badgeName': badge['name'],
          'badgeType': badge['type'],
          'badgeCategory': badge['category'],
        },
      };

      await _firestore.collection('growth_notifications').doc(notification['id']).set(notification);

      debugPrint('INFO: [GrowthNotificationsService] New badge notification sent to user $userId');
    } catch (e) {
      debugPrint('ERROR: [GrowthNotificationsService] Failed to send new badge notification: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ A/B С‚РµСЃС‚Рµ
  Future<void> sendABTestNotification(
      String userId, String testName, String variant, Map<String, dynamic> testData) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'abTest',
        'title': 'РЈС‡Р°СЃС‚РёРµ РІ С‚РµСЃС‚Рµ',
        'message': 'Р’С‹ СѓС‡Р°СЃС‚РІСѓРµС‚Рµ РІ С‚РµСЃС‚Рµ "$testName" (РІР°СЂРёР°РЅС‚: $variant)',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/ab-tests',
        'actionText': 'РџРѕСЃРјРѕС‚СЂРµС‚СЊ С‚РµСЃС‚С‹',
        'data': {
          'testName': testName,
          'variant': variant,
          'testData': testData,
        },
      };

      await _firestore.collection('growth_notifications').doc(notification['id']).set(notification);

      debugPrint('INFO: [GrowthNotificationsService] AB test notification sent to user $userId');
    } catch (e) {
      debugPrint('ERROR: [GrowthNotificationsService] Failed to send AB test notification: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ СЃРµР·РѕРЅРЅРѕР№ Р°РєС†РёРё
  Future<void> sendSeasonalPromotionNotification(
      String userId, String season, Map<String, dynamic> promotionData) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'seasonal',
        'title': 'РЎРµР·РѕРЅРЅР°СЏ Р°РєС†РёСЏ!',
        'message': 'РЎРїРµС†РёР°Р»СЊРЅС‹Рµ РїСЂРµРґР»РѕР¶РµРЅРёСЏ РґР»СЏ $season СЃРµР·РѕРЅР°!',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/monetization',
        'actionText': 'РџРѕСЃРјРѕС‚СЂРµС‚СЊ Р°РєС†РёРё',
        'data': {
          'season': season,
          'promotionData': promotionData,
        },
      };

      await _firestore.collection('growth_notifications').doc(notification['id']).set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] Seasonal promotion notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send seasonal promotion notification: $e');
    }
  }

  /// РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ Рѕ РїСЂР°Р·РґРЅРёС‡РЅРѕР№ Р°РєС†РёРё
  Future<void> sendHolidayPromotionNotification(
      String userId, String holiday, Map<String, dynamic> promotionData) async {
    try {
      final Map<String, dynamic> notification = {
        'id': _uuid.v4(),
        'userId': userId,
        'type': 'holiday',
        'title': 'РџСЂР°Р·РґРЅРёС‡РЅР°СЏ Р°РєС†РёСЏ!',
        'message': 'РЎРїРµС†РёР°Р»СЊРЅС‹Рµ РїСЂРµРґР»РѕР¶РµРЅРёСЏ Рє $holiday!',
        'isRead': false,
        'createdAt': DateTime.now(),
        'actionUrl': '/monetization',
        'actionText': 'РџРѕСЃРјРѕС‚СЂРµС‚СЊ Р°РєС†РёРё',
        'data': {
          'holiday': holiday,
          'promotionData': promotionData,
        },
      };

      await _firestore.collection('growth_notifications').doc(notification['id']).set(notification);

      debugPrint(
          'INFO: [GrowthNotificationsService] Holiday promotion notification sent to user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to send holiday promotion notification: $e');
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ СѓРІРµРґРѕРјР»РµРЅРёР№ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Stream<List<Map<String, dynamic>>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('growth_notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  /// РћС‚РјРµС‚РєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ РєР°Рє РїСЂРѕС‡РёС‚Р°РЅРЅРѕРіРѕ
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('growth_notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      debugPrint('INFO: [GrowthNotificationsService] Notification $notificationId marked as read');
    } catch (e) {
      debugPrint('ERROR: [GrowthNotificationsService] Failed to mark notification as read: $e');
    }
  }

  /// РћС‚РјРµС‚РєР° РІСЃРµС… СѓРІРµРґРѕРјР»РµРЅРёР№ РєР°Рє РїСЂРѕС‡РёС‚Р°РЅРЅС‹С…
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final QuerySnapshot unreadNotifications = await _firestore
          .collection('growth_notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final WriteBatch batch = _firestore.batch();
      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint(
          'INFO: [GrowthNotificationsService] All notifications marked as read for user $userId');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthNotificationsService] Failed to mark all notifications as read: $e');
    }
  }

  /// РЈРґР°Р»РµРЅРёРµ СѓРІРµРґРѕРјР»РµРЅРёСЏ
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('growth_notifications').doc(notificationId).delete();
      debugPrint('INFO: [GrowthNotificationsService] Notification $notificationId deleted');
    } catch (e) {
      debugPrint('ERROR: [GrowthNotificationsService] Failed to delete notification: $e');
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РєРѕР»РёС‡РµСЃС‚РІР° РЅРµРїСЂРѕС‡РёС‚Р°РЅРЅС‹С… СѓРІРµРґРѕРјР»РµРЅРёР№
  Stream<int> getUnreadNotificationsCountStream(String userId) {
    return _firestore
        .collection('growth_notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

