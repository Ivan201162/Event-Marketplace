import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'ab_testing_service.dart';
import 'package:flutter/foundation.dart';
import 'automated_promotions_service.dart';
import 'package:flutter/foundation.dart';
import 'dynamic_pricing_service.dart';
import 'package:flutter/foundation.dart';
import 'growth_mechanics_service.dart';
import 'package:flutter/foundation.dart';
import 'growth_notifications_service.dart';
import 'package:flutter/foundation.dart';
import 'partnership_service.dart';
import 'package:flutter/foundation.dart';
import 'receipt_service.dart';
import 'package:flutter/foundation.dart';
import 'referral_service.dart';
import 'package:flutter/foundation.dart';
import 'revenue_analytics_service.dart';
import 'package:flutter/foundation.dart';
import 'smart_advertising_service.dart';
import 'package:flutter/foundation.dart';

class GrowthPackIntegrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // РЎРµСЂРІРёСЃС‹ Growth Pack
  final ReferralService _referralService = ReferralService();
  final DynamicPricingService _dynamicPricingService = DynamicPricingService();
  final SmartAdvertisingService _smartAdvertisingService = SmartAdvertisingService();
  final RevenueAnalyticsService _revenueAnalyticsService = RevenueAnalyticsService();
  final ReceiptService _receiptService = ReceiptService();
  final PartnershipService _partnershipService = PartnershipService();
  final GrowthMechanicsService _growthMechanicsService = GrowthMechanicsService();
  final ABTestingService _abTestingService = ABTestingService();
  final AutomatedPromotionsService _automatedPromotionsService = AutomatedPromotionsService();
  final GrowthNotificationsService _growthNotificationsService = GrowthNotificationsService();

  /// РРЅРёС†РёР°Р»РёР·Р°С†РёСЏ РІСЃРµС… СЃРµСЂРІРёСЃРѕРІ Growth Pack
  Future<void> initializeGrowthPack() async {
    try {
      debugPrint('INFO: [GrowthPackIntegrationService] Initializing Growth Pack...');

      // РЎРѕР·РґР°РµРј РїСЂРµРґСѓСЃС‚Р°РЅРѕРІР»РµРЅРЅС‹Рµ РґР°РЅРЅС‹Рµ
      await _createDefaultData();

      // РЎРѕР·РґР°РµРј РїСЂРµРґСѓСЃС‚Р°РЅРѕРІР»РµРЅРЅС‹Рµ A/B С‚РµСЃС‚С‹
      await _abTestingService.createMonetizationABTests();

      // РЎРѕР·РґР°РµРј Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРёРµ РїСЂРѕРјРѕ-РєР°РјРїР°РЅРёРё
      await _automatedPromotionsService.createDefaultPromotions();

      debugPrint('INFO: [GrowthPackIntegrationService] Growth Pack initialized successfully');
    } catch (e) {
      debugPrint('ERROR: [GrowthPackIntegrationService] Failed to initialize Growth Pack: $e');
    }
  }

  /// РЎРѕР·РґР°РЅРёРµ РїСЂРµРґСѓСЃС‚Р°РЅРѕРІР»РµРЅРЅС‹С… РґР°РЅРЅС‹С…
  Future<void> _createDefaultData() async {
    try {
      // РЎРѕР·РґР°РµРј РґРѕСЃС‚РёР¶РµРЅРёСЏ
      await _createDefaultAchievements();

      // РЎРѕР·РґР°РµРј Р·РЅР°С‡РєРё
      await _createDefaultBadges();

      // РЎРѕР·РґР°РµРј С‡РµР»Р»РµРЅРґР¶Рё
      await _createDefaultChallenges();

      // РЎРѕР·РґР°РµРј РїСЂР°РІРёР»Р° РґРёРЅР°РјРёС‡РµСЃРєРѕРіРѕ С†РµРЅРѕРѕР±СЂР°Р·РѕРІР°РЅРёСЏ
      await _createDefaultPricingRules();

      // РЎРѕР·РґР°РµРј РїСЂР°РІРёР»Р° СѓРјРЅРѕР№ СЂРµРєР»Р°РјС‹
      await _createDefaultSmartAdRules();

      debugPrint('INFO: [GrowthPackIntegrationService] Default data created');
    } catch (e) {
      debugPrint('ERROR: [GrowthPackIntegrationService] Failed to create default data: $e');
    }
  }

  /// РЎРѕР·РґР°РЅРёРµ РїСЂРµРґСѓСЃС‚Р°РЅРѕРІР»РµРЅРЅС‹С… РґРѕСЃС‚РёР¶РµРЅРёР№
  Future<void> _createDefaultAchievements() async {
    try {
      final List<Map<String, dynamic>> achievements = [
        {
          'id': 'first_referral',
          'name': 'РџРµСЂРІС‹Р№ СЂРµС„РµСЂР°Р»',
          'description': 'РџСЂРёРіР»Р°СЃРёС‚Рµ РїРµСЂРІРѕРіРѕ РґСЂСѓРіР°',
          'type': 'referral',
          'condition': {'type': 'referral_count', 'count': 1},
          'reward': {'type': 'premium_days', 'days': 3},
          'points': 100,
          'isActive': true,
          'createdAt': DateTime.now(),
        },
        {
          'id': 'referral_master',
          'name': 'РњР°СЃС‚РµСЂ СЂРµС„РµСЂР°Р»РѕРІ',
          'description': 'РџСЂРёРіР»Р°СЃРёС‚Рµ 10 РґСЂСѓР·РµР№',
          'type': 'referral',
          'condition': {'type': 'referral_count', 'count': 10},
          'reward': {'type': 'premium_days', 'days': 30},
          'points': 500,
          'isActive': true,
          'createdAt': DateTime.now(),
        },
        {
          'id': 'first_purchase',
          'name': 'РџРµСЂРІС‹Р№ РїРѕРєСѓРїР°С‚РµР»СЊ',
          'description': 'РЎРѕРІРµСЂС€РёС‚Рµ РїРµСЂРІСѓСЋ РїРѕРєСѓРїРєСѓ',
          'type': 'purchase',
          'condition': {'type': 'purchase_count', 'count': 1},
          'reward': {'type': 'badge', 'badgeId': 'first_buyer'},
          'points': 200,
          'isActive': true,
          'createdAt': DateTime.now(),
        },
        {
          'id': 'big_spender',
          'name': 'Р‘РѕР»СЊС€РѕР№ С‚СЂР°С‚С‡РёРє',
          'description': 'РџРѕС‚СЂР°С‚СЊС‚Рµ 10,000 СЂСѓР±Р»РµР№',
          'type': 'purchase',
          'condition': {'type': 'total_spent', 'amount': 10000.0},
          'reward': {'type': 'discount', 'value': 0.15},
          'points': 1000,
          'isActive': true,
          'createdAt': DateTime.now(),
        },
        {
          'id': 'level_10',
          'name': 'РЈСЂРѕРІРµРЅСЊ 10',
          'description': 'Р”РѕСЃС‚РёРіРЅРёС‚Рµ 10 СѓСЂРѕРІРЅСЏ',
          'type': 'level',
          'condition': {'type': 'level_reached', 'level': 10},
          'reward': {'type': 'premium_days', 'days': 7},
          'points': 300,
          'isActive': true,
          'createdAt': DateTime.now(),
        },
      ];

      for (final achievement in achievements) {
        await _firestore.collection('achievements').doc(achievement['id']).set(achievement);
      }

      debugPrint('INFO: [GrowthPackIntegrationService] Default achievements created');
    } catch (e) {
      debugPrint('ERROR: [GrowthPackIntegrationService] Failed to create default achievements: $e');
    }
  }

  /// РЎРѕР·РґР°РЅРёРµ РїСЂРµРґСѓСЃС‚Р°РЅРѕРІР»РµРЅРЅС‹С… Р·РЅР°С‡РєРѕРІ
  Future<void> _createDefaultBadges() async {
    try {
      final List<Map<String, dynamic>> badges = [
        {
          'id': 'first_buyer',
          'name': 'РџРµСЂРІС‹Р№ РїРѕРєСѓРїР°С‚РµР»СЊ',
          'description': 'РЎРѕРІРµСЂС€РёР» РїРµСЂРІСѓСЋ РїРѕРєСѓРїРєСѓ',
          'type': 'purchase',
          'category': 'monetization',
          'icon': 'shopping_cart',
          'color': 'blue',
          'isActive': true,
          'createdAt': DateTime.now(),
        },
        {
          'id': 'referral_champion',
          'name': 'Р§РµРјРїРёРѕРЅ СЂРµС„РµСЂР°Р»РѕРІ',
          'description': 'РџСЂРёРіР»Р°СЃРёР» 10+ РґСЂСѓР·РµР№',
          'type': 'referral',
          'category': 'social',
          'icon': 'people',
          'color': 'gold',
          'isActive': true,
          'createdAt': DateTime.now(),
        },
        {
          'id': 'level_master',
          'name': 'РњР°СЃС‚РµСЂ СѓСЂРѕРІРЅРµР№',
          'description': 'Р”РѕСЃС‚РёРі РІС‹СЃРѕРєРѕРіРѕ СѓСЂРѕРІРЅСЏ',
          'type': 'level',
          'category': 'progress',
          'icon': 'star',
          'color': 'purple',
          'isActive': true,
          'createdAt': DateTime.now(),
        },
        {
          'id': 'challenge_completer',
          'name': 'Р—Р°РІРµСЂС€РёС‚РµР»СЊ С‡РµР»Р»РµРЅРґР¶РµР№',
          'description': 'Р—Р°РІРµСЂС€РёР» 5+ С‡РµР»Р»РµРЅРґР¶РµР№',
          'type': 'challenge',
          'category': 'achievement',
          'icon': 'emoji_events',
          'color': 'green',
          'isActive': true,
          'createdAt': DateTime.now(),
        },
      ];

      for (final badge in badges) {
        await _firestore.collection('badges').doc(badge['id']).set(badge);
      }

      debugPrint('INFO: [GrowthPackIntegrationService] Default badges created');
    } catch (e) {
      debugPrint('ERROR: [GrowthPackIntegrationService] Failed to create default badges: $e');
    }
  }

  /// РЎРѕР·РґР°РЅРёРµ РїСЂРµРґСѓСЃС‚Р°РЅРѕРІР»РµРЅРЅС‹С… С‡РµР»Р»РµРЅРґР¶РµР№
  Future<void> _createDefaultChallenges() async {
    try {
      // Р§РµР»Р»РµРЅРґР¶ "РџСЂРёРіР»Р°СЃРё 5 РґСЂСѓР·РµР№"
      await _growthMechanicsService.createChallenge(
        name: 'РџСЂРёРіР»Р°СЃРё 5 РґСЂСѓР·РµР№',
        description: 'РџСЂРёРіР»Р°СЃРёС‚Рµ 5 РґСЂСѓР·РµР№ Рё РїРѕР»СѓС‡РёС‚Рµ РјРµСЃСЏС† Premium Р±РµСЃРїР»Р°С‚РЅРѕ!',
        type: 'referral',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        conditions: {
          'referral_count': 5,
        },
        rewards: {
          'experience': 500,
          'premium_days': 30,
          'badge': 'referral_champion',
        },
        icon: 'people',
        category: 'social',
      );

      // Р§РµР»Р»РµРЅРґР¶ "РџРѕС‚СЂР°С‚СЊ 5,000 СЂСѓР±Р»РµР№"
      await _growthMechanicsService.createChallenge(
        name: 'РџРѕС‚СЂР°С‚СЊ 5,000 СЂСѓР±Р»РµР№',
        description: 'РџРѕС‚СЂР°С‚СЊС‚Рµ 5,000 СЂСѓР±Р»РµР№ Рё РїРѕР»СѓС‡РёС‚Рµ СЃРєРёРґРєСѓ 20%!',
        type: 'purchase',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 60)),
        conditions: {
          'total_spent': 5000.0,
        },
        rewards: {
          'experience': 300,
          'discount': 0.20,
        },
        icon: 'shopping_cart',
        category: 'monetization',
      );

      // Р§РµР»Р»РµРЅРґР¶ "Р”РѕСЃС‚РёРіРЅРё 5 СѓСЂРѕРІРЅСЏ"
      await _growthMechanicsService.createChallenge(
        name: 'Р”РѕСЃС‚РёРіРЅРё 5 СѓСЂРѕРІРЅСЏ',
        description: 'Р”РѕСЃС‚РёРіРЅРёС‚Рµ 5 СѓСЂРѕРІРЅСЏ Рё РїРѕР»СѓС‡РёС‚Рµ СЌРєСЃРєР»СЋР·РёРІРЅС‹Р№ Р·РЅР°С‡РѕРє!',
        type: 'level',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 90)),
        conditions: {
          'level': 5,
        },
        rewards: {
          'experience': 200,
          'badge': 'level_master',
        },
        icon: 'star',
        category: 'progress',
      );

      debugPrint('INFO: [GrowthPackIntegrationService] Default challenges created');
    } catch (e) {
      debugPrint('ERROR: [GrowthPackIntegrationService] Failed to create default challenges: $e');
    }
  }

  /// РЎРѕР·РґР°РЅРёРµ РїСЂР°РІРёР» РґРёРЅР°РјРёС‡РµСЃРєРѕРіРѕ С†РµРЅРѕРѕР±СЂР°Р·РѕРІР°РЅРёСЏ
  Future<void> _createDefaultPricingRules() async {
    try {
      // РџСЂР°РІРёР»Рѕ РґР»СЏ РїРѕРґРїРёСЃРѕРє
      await _firestore.collection('pricing_rules').doc('subscription_pricing').set({
        'id': 'subscription_pricing',
        'serviceType': 'subscription',
        'basePrice': 499.0,
        'demandFactor': 1.0,
        'timeFactor': 1.0,
        'regionFactor': 1.0,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'metadata': {
          'regionFactors': {
            'Moscow': 1.2,
            'SPb': 1.1,
            'other': 1.0,
          },
          'timeFactors': {
            'peak_hours': 1.1,
            'off_peak': 0.9,
          },
        },
      });

      // РџСЂР°РІРёР»Рѕ РґР»СЏ РїСЂРѕРґРІРёР¶РµРЅРёР№
      await _firestore.collection('pricing_rules').doc('promotion_pricing').set({
        'id': 'promotion_pricing',
        'serviceType': 'promotion',
        'basePrice': 299.0,
        'demandFactor': 1.0,
        'timeFactor': 1.0,
        'regionFactor': 1.0,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'metadata': {
          'regionFactors': {
            'Moscow': 1.3,
            'SPb': 1.2,
            'other': 1.0,
          },
        },
      });

      debugPrint('INFO: [GrowthPackIntegrationService] Default pricing rules created');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthPackIntegrationService] Failed to create default pricing rules: $e');
    }
  }

  /// РЎРѕР·РґР°РЅРёРµ РїСЂР°РІРёР» СѓРјРЅРѕР№ СЂРµРєР»Р°РјС‹
  Future<void> _createDefaultSmartAdRules() async {
    try {
      // РџСЂР°РІРёР»Рѕ РґР»СЏ РїРѕРєР°Р·Р° СЂРµРєР»Р°РјС‹ РїРѕ РёРЅС‚РµСЂРµСЃР°Рј
      await _firestore.collection('smart_ad_rules').doc('interest_based_ads').set({
        'id': 'interest_based_ads',
        'placementType': 'banner',
        'targetCriterion': 'user_interest',
        'criterionValue': 'music',
        'priority': 10,
        'maxImpressionsPerUser': 3,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'metadata': {
          'category': 'music',
          'targetAudience': 'music_lovers',
        },
      });

      // РџСЂР°РІРёР»Рѕ РґР»СЏ РїРѕРєР°Р·Р° СЂРµРєР»Р°РјС‹ РїРѕ РёСЃС‚РѕСЂРёРё РїСЂРѕСЃРјРѕС‚СЂРѕРІ
      await _firestore.collection('smart_ad_rules').doc('history_based_ads').set({
        'id': 'history_based_ads',
        'placementType': 'profileRecommendation',
        'targetCriterion': 'view_history',
        'criterionValue': 'specialist_profile_view',
        'priority': 8,
        'maxImpressionsPerUser': 5,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'metadata': {
          'category': 'specialists',
          'targetAudience': 'active_browsers',
        },
      });

      // РџСЂР°РІРёР»Рѕ РґР»СЏ РїРѕРєР°Р·Р° СЂРµРєР»Р°РјС‹ РїРѕ Р»РѕРєР°С†РёРё
      await _firestore.collection('smart_ad_rules').doc('location_based_ads').set({
        'id': 'location_based_ads',
        'placementType': 'feedInsertion',
        'targetCriterion': 'location',
        'criterionValue': 'Moscow',
        'priority': 6,
        'maxImpressionsPerUser': 4,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'metadata': {
          'region': 'Moscow',
          'targetAudience': 'moscow_users',
        },
      });

      debugPrint('INFO: [GrowthPackIntegrationService] Default smart ad rules created');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthPackIntegrationService] Failed to create default smart ad rules: $e');
    }
  }

  /// РћР±СЂР°Р±РѕС‚РєР° СЃРѕР±С‹С‚РёСЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ (РёРЅС‚РµРіСЂР°С†РёСЏ РІСЃРµС… СЃРµСЂРІРёСЃРѕРІ)
  Future<void> handleUserEvent(
      String userId, String eventType, Map<String, dynamic> eventData) async {
    try {
      debugPrint(
          'INFO: [GrowthPackIntegrationService] Handling user event: $eventType for user $userId');

      // РћР±СЂР°Р±РѕС‚РєР° РІ СЃРµСЂРІРёСЃРµ РіРµР№РјРёС„РёРєР°С†РёРё
      await _growthMechanicsService.checkAndAwardAchievements(userId, eventType, eventData);

      // РћР±СЂР°Р±РѕС‚РєР° РІ СЃРµСЂРІРёСЃРµ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРёС… РїСЂРѕРјРѕ-РєР°РјРїР°РЅРёР№
      await _automatedPromotionsService.checkAndExecutePromotions(userId, eventType, eventData);

      // РћР±СЂР°Р±РѕС‚РєР° РІ СЃРµСЂРІРёСЃРµ A/B С‚РµСЃС‚РёСЂРѕРІР°РЅРёСЏ
      await _abTestingService.logEvent(userId, 'general_test', eventType, eventData);

      // Р”РѕР±Р°РІР»РµРЅРёРµ РѕРїС‹С‚Р° Р·Р° Р°РєС‚РёРІРЅРѕСЃС‚СЊ
      await _addExperienceForEvent(userId, eventType, eventData);

      debugPrint('INFO: [GrowthPackIntegrationService] User event handled successfully');
    } catch (e) {
      debugPrint('ERROR: [GrowthPackIntegrationService] Failed to handle user event: $e');
    }
  }

  /// Р”РѕР±Р°РІР»РµРЅРёРµ РѕРїС‹С‚Р° Р·Р° СЃРѕР±С‹С‚РёРµ
  Future<void> _addExperienceForEvent(
      String userId, String eventType, Map<String, dynamic> eventData) async {
    try {
      int experience = 0;
      String reason = '';

      switch (eventType) {
        case 'user_registration':
          experience = 100;
          reason = 'Р РµРіРёСЃС‚СЂР°С†РёСЏ';
          break;
        case 'first_purchase':
          experience = 200;
          reason = 'РџРµСЂРІР°СЏ РїРѕРєСѓРїРєР°';
          break;
        case 'referral_completed':
          experience = 150;
          reason = 'Р РµС„РµСЂР°Р» Р·Р°СЂРµРіРёСЃС‚СЂРёСЂРѕРІР°РЅ';
          break;
        case 'challenge_completed':
          experience = 300;
          reason = 'Р§РµР»Р»РµРЅРґР¶ Р·Р°РІРµСЂС€РµРЅ';
          break;
        case 'achievement_earned':
          experience = 100;
          reason = 'Р”РѕСЃС‚РёР¶РµРЅРёРµ РїРѕР»СѓС‡РµРЅРѕ';
          break;
        case 'daily_login':
          experience = 10;
          reason = 'Р•Р¶РµРґРЅРµРІРЅС‹Р№ РІС…РѕРґ';
          break;
        case 'profile_view':
          experience = 5;
          reason = 'РџСЂРѕСЃРјРѕС‚СЂ РїСЂРѕС„РёР»СЏ';
          break;
        case 'message_sent':
          experience = 3;
          reason = 'РћС‚РїСЂР°РІР»РµРЅРѕ СЃРѕРѕР±С‰РµРЅРёРµ';
          break;
        case 'idea_created':
          experience = 20;
          reason = 'РЎРѕР·РґР°РЅР° РёРґРµСЏ';
          break;
        case 'request_created':
          experience = 15;
          reason = 'РЎРѕР·РґР°РЅ Р·Р°РїСЂРѕСЃ';
          break;
      }

      if (experience > 0) {
        await _growthMechanicsService.addExperience(userId, experience, reason);
      }
    } catch (e) {
      debugPrint('ERROR: [GrowthPackIntegrationService] Failed to add experience for event: $e');
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ СЃС‚Р°С‚РёСЃС‚РёРєРё Growth Pack РґР»СЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<Map<String, dynamic>> getUserGrowthStats(String userId) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј СѓСЂРѕРІРµРЅСЊ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
      final DocumentSnapshot levelDoc =
          await _firestore.collection('user_levels').doc(userId).get();

      // РџРѕР»СѓС‡Р°РµРј РґРѕСЃС‚РёР¶РµРЅРёСЏ
      final QuerySnapshot achievementsSnapshot =
          await _firestore.collection('user_achievements').where('userId', isEqualTo: userId).get();

      // РџРѕР»СѓС‡Р°РµРј Р·РЅР°С‡РєРё
      final QuerySnapshot badgesSnapshot =
          await _firestore.collection('user_badges').where('userId', isEqualTo: userId).get();

      // РџРѕР»СѓС‡Р°РµРј С‡РµР»Р»РµРЅРґР¶Рё
      final QuerySnapshot challengesSnapshot =
          await _firestore.collection('user_challenges').where('userId', isEqualTo: userId).get();

      // РџРѕР»СѓС‡Р°РµРј СЂРµС„РµСЂР°Р»РѕРІ
      final QuerySnapshot referralsSnapshot =
          await _firestore.collection('referrals').where('referrerId', isEqualTo: userId).get();

      return {
        'level': levelDoc.exists ? (levelDoc.data() as Map<String, dynamic>)['level'] : 1,
        'experience': levelDoc.exists ? (levelDoc.data() as Map<String, dynamic>)['experience'] : 0,
        'totalExperience':
            levelDoc.exists ? (levelDoc.data() as Map<String, dynamic>)['totalExperience'] : 0,
        'achievementsCount': achievementsSnapshot.docs.length,
        'badgesCount': badgesSnapshot.docs.length,
        'challengesCount': challengesSnapshot.docs.length,
        'referralsCount': referralsSnapshot.docs.length,
        'isActive': true,
      };
    } catch (e) {
      debugPrint('ERROR: [GrowthPackIntegrationService] Failed to get user growth stats: $e');
      return {
        'level': 1,
        'experience': 0,
        'totalExperience': 0,
        'achievementsCount': 0,
        'badgesCount': 0,
        'challengesCount': 0,
        'referralsCount': 0,
        'isActive': false,
      };
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ СЃС‚Р°С‚РёСЃС‚РёРєРё Growth Pack РґР»СЏ Р°РґРјРёРЅРёСЃС‚СЂР°С‚РѕСЂР°
  Future<Map<String, dynamic>> getAdminGrowthStats() async {
    try {
      // РџРѕР»СѓС‡Р°РµРј РѕР±С‰СѓСЋ СЃС‚Р°С‚РёСЃС‚РёРєСѓ РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№
      final QuerySnapshot usersSnapshot = await _firestore.collection('users').get();

      // РџРѕР»СѓС‡Р°РµРј СЃС‚Р°С‚РёСЃС‚РёРєСѓ СЂРµС„РµСЂР°Р»РѕРІ
      final QuerySnapshot referralsSnapshot = await _firestore.collection('referrals').get();

      // РџРѕР»СѓС‡Р°РµРј СЃС‚Р°С‚РёСЃС‚РёРєСѓ С‚СЂР°РЅР·Р°РєС†РёР№
      final QuerySnapshot transactionsSnapshot = await _firestore.collection('transactions').get();

      // РџРѕР»СѓС‡Р°РµРј СЃС‚Р°С‚РёСЃС‚РёРєСѓ РґРѕСЃС‚РёР¶РµРЅРёР№
      final QuerySnapshot achievementsSnapshot =
          await _firestore.collection('user_achievements').get();

      // РџРѕР»СѓС‡Р°РµРј СЃС‚Р°С‚РёСЃС‚РёРєСѓ С‡РµР»Р»РµРЅРґР¶РµР№
      final QuerySnapshot challengesSnapshot = await _firestore.collection('user_challenges').get();

      return {
        'totalUsers': usersSnapshot.docs.length,
        'totalReferrals': referralsSnapshot.docs.length,
        'totalTransactions': transactionsSnapshot.docs.length,
        'totalAchievements': achievementsSnapshot.docs.length,
        'totalChallenges': challengesSnapshot.docs.length,
        'referralRate': usersSnapshot.docs.isNotEmpty
            ? referralsSnapshot.docs.length / usersSnapshot.docs.length
            : 0.0,
        'achievementRate': usersSnapshot.docs.isNotEmpty
            ? achievementsSnapshot.docs.length / usersSnapshot.docs.length
            : 0.0,
        'challengeParticipationRate': usersSnapshot.docs.isNotEmpty
            ? challengesSnapshot.docs.length / usersSnapshot.docs.length
            : 0.0,
      };
    } catch (e) {
      debugPrint('ERROR: [GrowthPackIntegrationService] Failed to get admin growth stats: $e');
      return {
        'totalUsers': 0,
        'totalReferrals': 0,
        'totalTransactions': 0,
        'totalAchievements': 0,
        'totalChallenges': 0,
        'referralRate': 0.0,
        'achievementRate': 0.0,
        'challengeParticipationRate': 0.0,
      };
    }
  }
}

