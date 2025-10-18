import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import '../models/automated_promotions.dart';
import 'package:flutter/foundation.dart';

class AutomatedPromotionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// РЎРѕР·РґР°РЅРёРµ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРѕР№ РїСЂРѕРјРѕ-РєР°РјРїР°РЅРёРё
  Future<String> createAutomatedPromotion({
    required String name,
    required String description,
    required PromotionTrigger trigger,
    required Map<String, dynamic> conditions,
    required Map<String, dynamic> actions,
    required DateTime startDate,
    required DateTime endDate,
    String? targetAudience,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final AutomatedPromotion promotion = AutomatedPromotion(
        id: _uuid.v4(),
        name: name,
        description: description,
        trigger: trigger,
        conditions: conditions,
        actions: actions,
        status: PromotionStatus.draft,
        startDate: startDate,
        endDate: endDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        targetAudience: targetAudience,
        metadata: metadata,
      );

      await _firestore.collection('automated_promotions').doc(promotion.id).set(promotion.toMap());

      debugPrint('INFO: [AutomatedPromotionsService] Automated promotion created: ${promotion.id}');
      return promotion.id;
    } catch (e) {
      debugPrint('ERROR: [AutomatedPromotionsService] Failed to create automated promotion: $e');
      rethrow;
    }
  }

  /// РђРєС‚РёРІР°С†РёСЏ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРѕР№ РїСЂРѕРјРѕ-РєР°РјРїР°РЅРёРё
  Future<void> activatePromotion(String promotionId) async {
    try {
      await _firestore.collection('automated_promotions').doc(promotionId).update({
        'isActive': true,
        'status': PromotionStatus.active.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('INFO: [AutomatedPromotionsService] Automated promotion activated: $promotionId');
    } catch (e) {
      debugPrint('ERROR: [AutomatedPromotionsService] Failed to activate promotion: $e');
    }
  }

  /// Р”РµР°РєС‚РёРІР°С†РёСЏ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРѕР№ РїСЂРѕРјРѕ-РєР°РјРїР°РЅРёРё
  Future<void> deactivatePromotion(String promotionId) async {
    try {
      await _firestore.collection('automated_promotions').doc(promotionId).update({
        'isActive': false,
        'status': PromotionStatus.completed.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
          'INFO: [AutomatedPromotionsService] Automated promotion deactivated: $promotionId');
    } catch (e) {
      debugPrint('ERROR: [AutomatedPromotionsService] Failed to deactivate promotion: $e');
    }
  }

  /// РџСЂРѕРІРµСЂРєР° Рё РІС‹РїРѕР»РЅРµРЅРёРµ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРёС… РїСЂРѕРјРѕ-РєР°РјРїР°РЅРёР№
  Future<void> checkAndExecutePromotions(
      String userId, String eventType, Map<String, dynamic> eventData) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј РІСЃРµ Р°РєС‚РёРІРЅС‹Рµ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРёРµ РїСЂРѕРјРѕ-РєР°РјРїР°РЅРёРё
      final QuerySnapshot promotionsSnapshot = await _firestore
          .collection('automated_promotions')
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: FieldValue.serverTimestamp())
          .where('endDate', isGreaterThanOrEqualTo: FieldValue.serverTimestamp())
          .get();

      for (final doc in promotionsSnapshot.docs) {
        final AutomatedPromotion promotion =
            AutomatedPromotion.fromMap(doc.data() as Map<String, dynamic>);

        // РџСЂРѕРІРµСЂСЏРµРј, СЃРѕРѕС‚РІРµС‚СЃС‚РІСѓРµС‚ Р»Рё СЃРѕР±С‹С‚РёРµ С‚СЂРёРіРіРµСЂСѓ
        if (_matchesTrigger(promotion.trigger, eventType, eventData)) {
          // РџСЂРѕРІРµСЂСЏРµРј СѓСЃР»РѕРІРёСЏ
          if (await _checkConditions(userId, promotion.conditions)) {
            // РџСЂРѕРІРµСЂСЏРµРј, РЅРµ Р±С‹Р»Р° Р»Рё СѓР¶Рµ РїСЂРёРјРµРЅРµРЅР° СЌС‚Р° РїСЂРѕРјРѕ-РєР°РјРїР°РЅРёСЏ Рє РїРѕР»СЊР·РѕРІР°С‚РµР»СЋ
            if (!await _isPromotionAppliedToUser(userId, promotion.id)) {
              await _executePromotion(userId, promotion);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('ERROR: [AutomatedPromotionsService] Failed to check and execute promotions: $e');
    }
  }

  /// РџСЂРѕРІРµСЂРєР° СЃРѕРѕС‚РІРµС‚СЃС‚РІРёСЏ СЃРѕР±С‹С‚РёСЏ С‚СЂРёРіРіРµСЂСѓ
  bool _matchesTrigger(PromotionTrigger trigger, String eventType, Map<String, dynamic> eventData) {
    switch (trigger) {
      case PromotionTrigger.userRegistration:
        return eventType == 'user_registration';
      case PromotionTrigger.firstPurchase:
        return eventType == 'first_purchase';
      case PromotionTrigger.subscriptionExpiry:
        return eventType == 'subscription_expiry';
      case PromotionTrigger.inactivity:
        return eventType == 'user_inactivity';
      case PromotionTrigger.holiday:
        return eventType == 'holiday' && _isHoliday(eventData['date']);
      case PromotionTrigger.seasonal:
        return eventType == 'seasonal' && _isSeasonalPeriod(eventData['date']);
      case PromotionTrigger.milestone:
        return eventType == 'milestone' && _matchesMilestone(eventData);
      case PromotionTrigger.custom:
        return eventType == eventData['custom_trigger'];
      default:
        return false;
    }
  }

  /// РџСЂРѕРІРµСЂРєР° СѓСЃР»РѕРІРёР№ РїСЂРѕРјРѕ-РєР°РјРїР°РЅРёРё
  Future<bool> _checkConditions(String userId, Map<String, dynamic> conditions) async {
    try {
      for (final condition in conditions.entries) {
        final String conditionType = condition.key;
        final dynamic conditionValue = condition.value;

        switch (conditionType) {
          case 'user_level':
            final int userLevel = await _getUserLevel(userId);
            if (userLevel < (conditionValue as int)) return false;
            break;

          case 'subscription_type':
            final String subscriptionType = await _getUserSubscriptionType(userId);
            if (subscriptionType != conditionValue) return false;
            break;

          case 'region':
            final String userRegion = await _getUserRegion(userId);
            if (userRegion != conditionValue) return false;
            break;

          case 'registration_date':
            final DateTime registrationDate = await _getUserRegistrationDate(userId);
            final DateTime cutoffDate = DateTime.parse(conditionValue as String);
            if (registrationDate.isAfter(cutoffDate)) return false;
            break;

          case 'total_spent':
            final double totalSpent = await _getUserTotalSpent(userId);
            if (totalSpent < (conditionValue as double)) return false;
            break;

          case 'referral_count':
            final int referralCount = await _getUserReferralCount(userId);
            if (referralCount < (conditionValue as int)) return false;
            break;

          case 'inactivity_days':
            final int inactivityDays = await _getUserInactivityDays(userId);
            if (inactivityDays < (conditionValue as int)) return false;
            break;
        }
      }

      return true;
    } catch (e) {
      debugPrint('ERROR: [AutomatedPromotionsService] Failed to check conditions: $e');
      return false;
    }
  }

  /// Р’С‹РїРѕР»РЅРµРЅРёРµ РїСЂРѕРјРѕ-РєР°РјРїР°РЅРёРё
  Future<void> _executePromotion(String userId, AutomatedPromotion promotion) async {
    try {
      // Р’С‹РїРѕР»РЅСЏРµРј РґРµР№СЃС‚РІРёСЏ РїСЂРѕРјРѕ-РєР°РјРїР°РЅРёРё
      for (final action in promotion.actions.entries) {
        final String actionType = action.key;
        final dynamic actionValue = action.value;

        switch (actionType) {
          case 'send_notification':
            await _sendPromotionNotification(userId, promotion, actionValue);
            break;

          case 'apply_discount':
            await _applyDiscount(userId, actionValue);
            break;

          case 'add_premium_days':
            await _addPremiumDays(userId, actionValue as int);
            break;

          case 'give_bonus':
            await _giveBonus(userId, actionValue);
            break;

          case 'unlock_feature':
            await _unlockFeature(userId, actionValue as String);
            break;

          case 'send_email':
            await _sendPromotionEmail(userId, promotion, actionValue);
            break;
        }
      }

      // Р—Р°РїРёСЃС‹РІР°РµРј, С‡С‚Рѕ РїСЂРѕРјРѕ-РєР°РјРїР°РЅРёСЏ Р±С‹Р»Р° РїСЂРёРјРµРЅРµРЅР° Рє РїРѕР»СЊР·РѕРІР°С‚РµР»СЋ
      await _recordPromotionApplication(userId, promotion.id);

      debugPrint(
          'INFO: [AutomatedPromotionsService] Promotion executed: ${promotion.name} for user $userId');
    } catch (e) {
      debugPrint('ERROR: [AutomatedPromotionsService] Failed to execute promotion: $e');
    }
  }

  /// РЎРѕР·РґР°РЅРёРµ РїСЂРµРґСѓСЃС‚Р°РЅРѕРІР»РµРЅРЅС‹С… Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРёС… РїСЂРѕРјРѕ-РєР°РјРїР°РЅРёР№
  Future<void> createDefaultPromotions() async {
    try {
      // РџСЂРѕРјРѕ-РєР°РјРїР°РЅРёСЏ РґР»СЏ РЅРѕРІС‹С… РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№
      await createAutomatedPromotion(
        name: 'Р”РѕР±СЂРѕ РїРѕР¶Р°Р»РѕРІР°С‚СЊ!',
        description: 'РџСЂРёРІРµС‚СЃС‚РІРµРЅРЅС‹Р№ Р±РѕРЅСѓСЃ РґР»СЏ РЅРѕРІС‹С… РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№',
        trigger: PromotionTrigger.userRegistration,
        conditions: {},
        actions: {
          'send_notification': {
            'title': 'Р”РѕР±СЂРѕ РїРѕР¶Р°Р»РѕРІР°С‚СЊ РІ Event Marketplace!',
            'message': 'РџРѕР»СѓС‡РёС‚Рµ 3 РґРЅСЏ Premium Р±РµСЃРїР»Р°С‚РЅРѕ!',
          },
          'add_premium_days': 3,
        },
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        targetAudience: 'new_users',
      );

      // РџСЂРѕРјРѕ-РєР°РјРїР°РЅРёСЏ РґР»СЏ РЅРµР°РєС‚РёРІРЅС‹С… РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№
      await createAutomatedPromotion(
        name: 'Р’РµСЂРЅРёСЃСЊ Рє РЅР°Рј!',
        description: 'РЎРїРµС†РёР°Р»СЊРЅРѕРµ РїСЂРµРґР»РѕР¶РµРЅРёРµ РґР»СЏ РЅРµР°РєС‚РёРІРЅС‹С… РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№',
        trigger: PromotionTrigger.inactivity,
        conditions: {
          'inactivity_days': 7,
        },
        actions: {
          'send_notification': {
            'title': 'РњС‹ СЃРєСѓС‡Р°РµРј!',
            'message': 'Р’РµСЂРЅРёСЃСЊ Рё РїРѕР»СѓС‡Рё СЃРєРёРґРєСѓ 50% РЅР° Premium!',
          },
          'apply_discount': {
            'type': 'percentage',
            'value': 50.0,
            'duration_days': 7,
          },
        },
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        targetAudience: 'inactive_users',
      );

      // РџСЂРѕРјРѕ-РєР°РјРїР°РЅРёСЏ РґР»СЏ РёСЃС‚РµРєР°СЋС‰РёС… РїРѕРґРїРёСЃРѕРє
      await createAutomatedPromotion(
        name: 'РџСЂРѕРґР»Рё РїРѕРґРїРёСЃРєСѓ!',
        description: 'РЎРїРµС†РёР°Р»СЊРЅРѕРµ РїСЂРµРґР»РѕР¶РµРЅРёРµ РїРµСЂРµРґ РёСЃС‚РµС‡РµРЅРёРµРј РїРѕРґРїРёСЃРєРё',
        trigger: PromotionTrigger.subscriptionExpiry,
        conditions: {
          'subscription_type': 'premium',
        },
        actions: {
          'send_notification': {
            'title': 'РџРѕРґРїРёСЃРєР° РёСЃС‚РµРєР°РµС‚!',
            'message': 'РџСЂРѕРґР»Рё Premium СЃРѕ СЃРєРёРґРєРѕР№ 30%!',
          },
          'apply_discount': {
            'type': 'percentage',
            'value': 30.0,
            'duration_days': 3,
          },
        },
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        targetAudience: 'premium_users',
      );

      // РџСЂРѕРјРѕ-РєР°РјРїР°РЅРёСЏ РґР»СЏ РїСЂР°Р·РґРЅРёРєРѕРІ
      await createAutomatedPromotion(
        name: 'РџСЂР°Р·РґРЅРёС‡РЅР°СЏ СЃРєРёРґРєР°',
        description: 'РЎРїРµС†РёР°Р»СЊРЅС‹Рµ РїСЂРµРґР»РѕР¶РµРЅРёСЏ РЅР° РїСЂР°Р·РґРЅРёРєРё',
        trigger: PromotionTrigger.holiday,
        conditions: {},
        actions: {
          'send_notification': {
            'title': 'РџСЂР°Р·РґРЅРёС‡РЅР°СЏ СЃРєРёРґРєР°!',
            'message': 'РџРѕР»СѓС‡РёС‚Рµ СЃРєРёРґРєСѓ 25% РЅР° РІСЃРµ С‚Р°СЂРёС„С‹!',
          },
          'apply_discount': {
            'type': 'percentage',
            'value': 25.0,
            'duration_days': 7,
          },
        },
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        targetAudience: 'all_users',
      );

      // РџСЂРѕРјРѕ-РєР°РјРїР°РЅРёСЏ РґР»СЏ РґРѕСЃС‚РёР¶РµРЅРёСЏ 10 СЂРµС„РµСЂР°Р»РѕРІ
      await createAutomatedPromotion(
        name: 'РњР°СЃС‚РµСЂ СЂРµС„РµСЂР°Р»РѕРІ',
        description: 'Р‘РѕРЅСѓСЃ Р·Р° РїСЂРёРіР»Р°С€РµРЅРёРµ 10 РґСЂСѓР·РµР№',
        trigger: PromotionTrigger.milestone,
        conditions: {
          'referral_count': 10,
        },
        actions: {
          'send_notification': {
            'title': 'РџРѕР·РґСЂР°РІР»СЏРµРј!',
            'message': 'Р’С‹ РїСЂРёРіР»Р°СЃРёР»Рё 10 РґСЂСѓР·РµР№! РџРѕР»СѓС‡РёС‚Рµ РјРµСЃСЏС† PRO Р±РµСЃРїР»Р°С‚РЅРѕ!',
          },
          'add_premium_days': 30,
          'unlock_feature': 'pro_features',
        },
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        targetAudience: 'active_users',
      );

      debugPrint('INFO: [AutomatedPromotionsService] Default automated promotions created');
    } catch (e) {
      debugPrint('ERROR: [AutomatedPromotionsService] Failed to create default promotions: $e');
    }
  }

  /// Р’СЃРїРѕРјРѕРіР°С‚РµР»СЊРЅС‹Рµ РјРµС‚РѕРґС‹ РґР»СЏ РїСЂРѕРІРµСЂРєРё СѓСЃР»РѕРІРёР№
  Future<int> _getUserLevel(String userId) async {
    final DocumentSnapshot doc = await _firestore.collection('user_levels').doc(userId).get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['level'] ?? 1;
    }
    return 1;
  }

  Future<String> _getUserSubscriptionType(String userId) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('user_subscriptions')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      return data['planType'] ?? 'free';
    }
    return 'free';
  }

  Future<String> _getUserRegion(String userId) async {
    final DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['region'] ?? 'unknown';
    }
    return 'unknown';
  }

  Future<DateTime> _getUserRegistrationDate(String userId) async {
    final DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['createdAt'] as Timestamp?;
      return timestamp?.toDate() ?? DateTime.now();
    }
    return DateTime.now();
  }

  Future<double> _getUserTotalSpent(String userId) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .get();

    double total = 0.0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['amount'] ?? 0.0).toDouble();
    }
    return total;
  }

  Future<int> _getUserReferralCount(String userId) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('referrals')
        .where('referrerId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getUserInactivityDays(String userId) async {
    final DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final lastActivity = data['lastActivityAt'] as Timestamp?;
      if (lastActivity != null) {
        return DateTime.now().difference(lastActivity.toDate()).inDays;
      }
    }
    return 0;
  }

  /// Р’СЃРїРѕРјРѕРіР°С‚РµР»СЊРЅС‹Рµ РјРµС‚РѕРґС‹ РґР»СЏ РІС‹РїРѕР»РЅРµРЅРёСЏ РґРµР№СЃС‚РІРёР№
  Future<void> _sendPromotionNotification(
      String userId, AutomatedPromotion promotion, Map<String, dynamic> notificationData) async {
    // Р›РѕРіРёРєР° РѕС‚РїСЂР°РІРєРё СѓРІРµРґРѕРјР»РµРЅРёСЏ
    debugPrint('INFO: [AutomatedPromotionsService] Sending promotion notification to user $userId');
  }

  Future<void> _applyDiscount(String userId, Map<String, dynamic> discountData) async {
    // Р›РѕРіРёРєР° РїСЂРёРјРµРЅРµРЅРёСЏ СЃРєРёРґРєРё
    debugPrint('INFO: [AutomatedPromotionsService] Applying discount to user $userId');
  }

  Future<void> _addPremiumDays(String userId, int days) async {
    // Р›РѕРіРёРєР° РґРѕР±Р°РІР»РµРЅРёСЏ РїСЂРµРјРёСѓРј РґРЅРµР№
    debugPrint('INFO: [AutomatedPromotionsService] Adding $days premium days to user $userId');
  }

  Future<void> _giveBonus(String userId, Map<String, dynamic> bonusData) async {
    // Р›РѕРіРёРєР° РІС‹РґР°С‡Рё Р±РѕРЅСѓСЃР°
    debugPrint('INFO: [AutomatedPromotionsService] Giving bonus to user $userId');
  }

  Future<void> _unlockFeature(String userId, String feature) async {
    // Р›РѕРіРёРєР° СЂР°Р·Р±Р»РѕРєРёСЂРѕРІРєРё С„СѓРЅРєС†РёРё
    debugPrint('INFO: [AutomatedPromotionsService] Unlocking feature $feature for user $userId');
  }

  Future<void> _sendPromotionEmail(
      String userId, AutomatedPromotion promotion, Map<String, dynamic> emailData) async {
    // Р›РѕРіРёРєР° РѕС‚РїСЂР°РІРєРё email
    debugPrint('INFO: [AutomatedPromotionsService] Sending promotion email to user $userId');
  }

  /// Р’СЃРїРѕРјРѕРіР°С‚РµР»СЊРЅС‹Рµ РјРµС‚РѕРґС‹ РґР»СЏ РїСЂРѕРІРµСЂРєРё РґР°С‚ Рё СЃРѕР±С‹С‚РёР№
  bool _isHoliday(DateTime date) {
    // РЈРїСЂРѕС‰РµРЅРЅР°СЏ Р»РѕРіРёРєР° РїСЂРѕРІРµСЂРєРё РїСЂР°Р·РґРЅРёРєРѕРІ
    // Р’ СЂРµР°Р»СЊРЅРѕРј РїСЂРёР»РѕР¶РµРЅРёРё РЅСѓР¶РЅР° Р±РѕР»РµРµ СЃР»РѕР¶РЅР°СЏ СЃРёСЃС‚РµРјР°
    return false;
  }

  bool _isSeasonalPeriod(DateTime date) {
    // РџСЂРѕРІРµСЂРєР° СЃРµР·РѕРЅРЅС‹С… РїРµСЂРёРѕРґРѕРІ (РЅР°РїСЂРёРјРµСЂ, Р»РµС‚Рѕ, Р·РёРјР°)
    final month = date.month;
    return month >= 6 && month <= 8; // Р›РµС‚Рѕ
  }

  bool _matchesMilestone(Map<String, dynamic> eventData) {
    // РџСЂРѕРІРµСЂРєР° СЃРѕРѕС‚РІРµС‚СЃС‚РІРёСЏ РґРѕСЃС‚РёР¶РµРЅРёСЋ
    return eventData['milestone_type'] == 'referral_count' && eventData['count'] >= 10;
  }

  Future<bool> _isPromotionAppliedToUser(String userId, String promotionId) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('promotion_applications')
        .where('userId', isEqualTo: userId)
        .where('promotionId', isEqualTo: promotionId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> _recordPromotionApplication(String userId, String promotionId) async {
    await _firestore.collection('promotion_applications').add({
      'userId': userId,
      'promotionId': promotionId,
      'appliedAt': FieldValue.serverTimestamp(),
    });
  }
}

