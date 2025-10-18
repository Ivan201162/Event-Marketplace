import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../models/advertisement.dart';
import 'package:flutter/foundation.dart';
import '../models/promotion_boost.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription_plan.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart' as transaction_model;

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// РРЅРёС†РёР°Р»РёР·Р°С†РёСЏ СЃРµСЂРІРёСЃР° Р°РЅР°Р»РёС‚РёРєРё
  static Future<void> initialize() async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      debugPrint('INFO: [AnalyticsService] Initialized successfully');
    } catch (e) {
      debugPrint('ERROR: [AnalyticsService] Initialization failed: $e');
    }
  }

  /// РћС‚СЃР»РµР¶РёРІР°РЅРёРµ СЃРѕР±С‹С‚РёСЏ РїРѕРєСѓРїРєРё РїРѕРґРїРёСЃРєРё
  static Future<void> trackSubscriptionPurchase({
    required String userId,
    required SubscriptionPlan plan,
    required transaction_model.Transaction transaction,
  }) async {
    try {
      // Firebase Analytics
      await _analytics.logPurchase(
        currency: transaction.currency,
        value: transaction.amount,
        parameters: {
          'item_id': plan.id,
          'item_name': plan.name,
          'item_category': 'subscription',
          'subscription_tier': plan.tier.toString(),
          'duration_days': plan.durationDays,
          'payment_method': transaction.paymentMethod,
          'payment_provider': transaction.paymentProvider,
        },
      );

      // Custom event
      await _analytics.logEvent(
        name: 'subscription_purchased',
        parameters: {
          'user_id': userId,
          'plan_id': plan.id,
          'plan_name': plan.name,
          'plan_tier': plan.tier.toString(),
          'amount': transaction.amount,
          'currency': transaction.currency,
          'duration_days': plan.durationDays,
          'payment_method': transaction.paymentMethod,
          'payment_provider': transaction.paymentProvider,
          'transaction_id': transaction.id,
        },
      );

      // РЎРѕС…СЂР°РЅРµРЅРёРµ РІ Firestore РґР»СЏ РґРµС‚Р°Р»СЊРЅРѕР№ Р°РЅР°Р»РёС‚РёРєРё
      await _saveAnalyticsEvent(
        userId: userId,
        eventType: 'subscription_purchased',
        eventData: {
          'plan_id': plan.id,
          'plan_name': plan.name,
          'plan_tier': plan.tier.toString(),
          'amount': transaction.amount,
          'currency': transaction.currency,
          'duration_days': plan.durationDays,
          'payment_method': transaction.paymentMethod,
          'payment_provider': transaction.paymentProvider,
          'transaction_id': transaction.id,
        },
      );

      debugPrint('INFO: [AnalyticsService] Subscription purchase tracked: ${plan.name}');
    } catch (e) {
      debugPrint('ERROR: [AnalyticsService] Failed to track subscription purchase: $e');
    }
  }

  /// РћС‚СЃР»РµР¶РёРІР°РЅРёРµ СЃРѕР±С‹С‚РёСЏ РїРѕРєСѓРїРєРё РїСЂРѕРґРІРёР¶РµРЅРёСЏ
  static Future<void> trackPromotionPurchase({
    required String userId,
    required PromotionBoost promotion,
    required transaction_model.Transaction transaction,
  }) async {
    try {
      // Firebase Analytics
      await _analytics.logEvent(
        name: 'promotion_purchased',
        parameters: {
          'user_id': userId,
          'promotion_id': promotion.id,
          'target_type': promotion.type.toString(),
          'priority_level': promotion.priorityLevel,
          'duration_days': promotion.endDate.difference(promotion.startDate).inDays,
          'amount': transaction.amount,
          'currency': transaction.currency,
          'payment_method': transaction.paymentMethod,
          'payment_provider': transaction.paymentProvider,
          'transaction_id': transaction.id,
        },
      );

      // РЎРѕС…СЂР°РЅРµРЅРёРµ РІ Firestore
      await _saveAnalyticsEvent(
        userId: userId,
        eventType: 'promotion_purchased',
        eventData: {
          'promotion_id': promotion.id,
          'target_type': promotion.type.toString(),
          'priority_level': promotion.priorityLevel,
          'duration_days': promotion.endDate.difference(promotion.startDate).inDays,
          'amount': transaction.amount,
          'currency': transaction.currency,
          'payment_method': transaction.paymentMethod,
          'payment_provider': transaction.paymentProvider,
          'transaction_id': transaction.id,
        },
      );

      debugPrint('INFO: [AnalyticsService] Promotion purchase tracked: ${promotion.type}');
    } catch (e) {
      debugPrint('ERROR: [AnalyticsService] Failed to track promotion purchase: $e');
    }
  }

  /// РћС‚СЃР»РµР¶РёРІР°РЅРёРµ СЃРѕР±С‹С‚РёСЏ СЃРѕР·РґР°РЅРёСЏ СЂРµРєР»Р°РјС‹
  static Future<void> trackAdvertisementCreated({
    required String userId,
    required Advertisement advertisement,
  }) async {
    try {
      // Firebase Analytics
      await _analytics.logEvent(
        name: 'advertisement_created',
        parameters: {
          'user_id': userId,
          'advertisement_id': advertisement.id,
          'advertisement_type': advertisement.type.toString(),
          'title': advertisement.title,
          'duration_days': advertisement.endDate.difference(advertisement.startDate).inDays,
          'target_audience': advertisement.targetAudience?.toString() ?? 'none',
        },
      );

      // РЎРѕС…СЂР°РЅРµРЅРёРµ РІ Firestore
      await _saveAnalyticsEvent(
        userId: userId,
        eventType: 'advertisement_created',
        eventData: {
          'advertisement_id': advertisement.id,
          'advertisement_type': advertisement.type.toString(),
          'title': advertisement.title,
          'duration_days': advertisement.endDate.difference(advertisement.startDate).inDays,
          'target_audience': advertisement.targetAudience,
        },
      );

      debugPrint('INFO: [AnalyticsService] Advertisement created tracked: ${advertisement.type}');
    } catch (e) {
      debugPrint('ERROR: [AnalyticsService] Failed to track advertisement created: $e');
    }
  }

  /// РћС‚СЃР»РµР¶РёРІР°РЅРёРµ СЃРѕР±С‹С‚РёСЏ СѓСЃРїРµС€РЅРѕР№ РѕРїР»Р°С‚С‹
  static Future<void> trackPaymentSuccess({
    required String userId,
    required transaction_model.Transaction transaction,
  }) async {
    try {
      // Firebase Analytics
      await _analytics.logEvent(
        name: 'payment_success',
        parameters: {
          'user_id': userId,
          'transaction_id': transaction.id,
          'amount': transaction.amount,
          'currency': transaction.currency,
          'type': transaction.type.toString(),
          'payment_method': transaction.paymentMethod,
          'payment_provider': transaction.paymentProvider,
        },
      );

      // РЎРѕС…СЂР°РЅРµРЅРёРµ РІ Firestore
      await _saveAnalyticsEvent(
        userId: userId,
        eventType: 'payment_success',
        eventData: {
          'transaction_id': transaction.id,
          'amount': transaction.amount,
          'currency': transaction.currency,
          'type': transaction.type.toString(),
          'payment_method': transaction.paymentMethod,
          'payment_provider': transaction.paymentProvider,
        },
      );

      debugPrint('INFO: [AnalyticsService] Payment success tracked: ${transaction.type}');
    } catch (e) {
      debugPrint('ERROR: [AnalyticsService] Failed to track payment success: $e');
    }
  }

  /// РћС‚СЃР»РµР¶РёРІР°РЅРёРµ СЃРѕР±С‹С‚РёСЏ РЅРµСѓРґР°С‡РЅРѕР№ РѕРїР»Р°С‚С‹
  static Future<void> trackPaymentFailed({
    required String userId,
    required transaction_model.Transaction transaction,
    required String errorMessage,
  }) async {
    try {
      // Firebase Analytics
      await _analytics.logEvent(
        name: 'payment_failed',
        parameters: {
          'user_id': userId,
          'transaction_id': transaction.id,
          'amount': transaction.amount,
          'currency': transaction.currency,
          'type': transaction.type.toString(),
          'payment_method': transaction.paymentMethod,
          'payment_provider': transaction.paymentProvider,
          'error_message': errorMessage,
        },
      );

      // РЎРѕС…СЂР°РЅРµРЅРёРµ РІ Firestore
      await _saveAnalyticsEvent(
        userId: userId,
        eventType: 'payment_failed',
        eventData: {
          'transaction_id': transaction.id,
          'amount': transaction.amount,
          'currency': transaction.currency,
          'type': transaction.type.toString(),
          'payment_method': transaction.paymentMethod,
          'payment_provider': transaction.paymentProvider,
          'error_message': errorMessage,
        },
      );

      debugPrint('INFO: [AnalyticsService] Payment failed tracked: ${transaction.type}');
    } catch (e) {
      debugPrint('ERROR: [AnalyticsService] Failed to track payment failed: $e');
    }
  }

  /// РћС‚СЃР»РµР¶РёРІР°РЅРёРµ РїСЂРѕСЃРјРѕС‚СЂР° СЂРµРєР»Р°РјС‹
  static Future<void> trackAdvertisementView({
    required String userId,
    required String advertisementId,
    required AdType type,
  }) async {
    try {
      // Firebase Analytics
      await _analytics.logEvent(
        name: 'advertisement_view',
        parameters: {
          'user_id': userId,
          'advertisement_id': advertisementId,
          'advertisement_type': type.toString(),
        },
      );

      // РЈРІРµР»РёС‡РёРІР°РµРј СЃС‡РµС‚С‡РёРє РїРѕРєР°Р·РѕРІ РІ Firestore
      await _firestore.collection('advertisements').doc(advertisementId).update({
        'impressions': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('INFO: [AnalyticsService] Advertisement view tracked: $advertisementId');
    } catch (e) {
      debugPrint('ERROR: [AnalyticsService] Failed to track advertisement view: $e');
    }
  }

  /// РћС‚СЃР»РµР¶РёРІР°РЅРёРµ РєР»РёРєР° РїРѕ СЂРµРєР»Р°РјРµ
  static Future<void> trackAdvertisementClick({
    required String userId,
    required String advertisementId,
    required AdType type,
  }) async {
    try {
      // Firebase Analytics
      await _analytics.logEvent(
        name: 'advertisement_click',
        parameters: {
          'user_id': userId,
          'advertisement_id': advertisementId,
          'advertisement_type': type.toString(),
        },
      );

      // РЈРІРµР»РёС‡РёРІР°РµРј СЃС‡РµС‚С‡РёРє РєР»РёРєРѕРІ РІ Firestore
      await _firestore.collection('advertisements').doc(advertisementId).update({
        'clicks': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('INFO: [AnalyticsService] Advertisement click tracked: $advertisementId');
    } catch (e) {
      debugPrint('ERROR: [AnalyticsService] Failed to track advertisement click: $e');
    }
  }

  /// РћС‚СЃР»РµР¶РёРІР°РЅРёРµ РІС…РѕРґР° РІ СЂР°Р·РґРµР» РјРѕРЅРµС‚РёР·Р°С†РёРё
  static Future<void> trackMonetizationHubView({
    required String userId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'monetization_hub_view',
        parameters: {
          'user_id': userId,
        },
      );

      debugPrint('INFO: [AnalyticsService] Monetization hub view tracked');
    } catch (e) {
      debugPrint('ERROR: [AnalyticsService] Failed to track monetization hub view: $e');
    }
  }

  /// РћС‚СЃР»РµР¶РёРІР°РЅРёРµ РїСЂРѕСЃРјРѕС‚СЂР° РїР»Р°РЅРѕРІ РїРѕРґРїРёСЃРєРё
  static Future<void> trackSubscriptionPlansView({
    required String userId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'subscription_plans_view',
        parameters: {
          'user_id': userId,
        },
      );

      debugPrint('INFO: [AnalyticsService] Subscription plans view tracked');
    } catch (e) {
      debugPrint('ERROR: [AnalyticsService] Failed to track subscription plans view: $e');
    }
  }

  /// РћС‚СЃР»РµР¶РёРІР°РЅРёРµ РїСЂРѕСЃРјРѕС‚СЂР° РїР°РєРµС‚РѕРІ РїСЂРѕРґРІРёР¶РµРЅРёСЏ
  static Future<void> trackPromotionPackagesView({
    required String userId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'promotion_packages_view',
        parameters: {
          'user_id': userId,
        },
      );

      debugPrint('INFO: [AnalyticsService] Promotion packages view tracked');
    } catch (e) {
      debugPrint('ERROR: [AnalyticsService] Failed to track promotion packages view: $e');
    }
  }

  /// РћС‚СЃР»РµР¶РёРІР°РЅРёРµ РїСЂРѕСЃРјРѕС‚СЂР° СЂРµРєР»Р°РјРЅС‹С… РєР°РјРїР°РЅРёР№
  static Future<void> trackAdvertisementCampaignsView({
    required String userId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'advertisement_campaigns_view',
        parameters: {
          'user_id': userId,
        },
      );

      debugPrint('INFO: [AnalyticsService] Advertisement campaigns view tracked');
    } catch (e) {
      debugPrint('ERROR: [AnalyticsService] Failed to track advertisement campaigns view: $e');
    }
  }

  /// РЎРѕС…СЂР°РЅРµРЅРёРµ СЃРѕР±С‹С‚РёСЏ Р°РЅР°Р»РёС‚РёРєРё РІ Firestore
  static Future<void> _saveAnalyticsEvent({
    required String userId,
    required String eventType,
    required Map<String, dynamic> eventData,
  }) async {
    try {
      await _firestore.collection('analytics_events').add({
        'userId': userId,
        'eventType': eventType,
        'eventData': eventData,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
      });
    } catch (e) {
      debugPrint('ERROR: [AnalyticsService] Failed to save analytics event: $e');
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ СЃС‚Р°С‚РёСЃС‚РёРєРё РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  static Future<Map<String, dynamic>> getUserAnalytics(String userId) async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('analytics_events').where('userId', isEqualTo: userId).get();

      final Map<String, int> eventCounts = {};
      double totalSpent = 0.0;
      int subscriptionPurchases = 0;
      int promotionPurchases = 0;
      int advertisementCreates = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final eventType = data['eventType'] as String;
        final eventData = data['eventData'] as Map<String, dynamic>;

        eventCounts[eventType] = (eventCounts[eventType] ?? 0) + 1;

        if (eventType == 'subscription_purchased' || eventType == 'promotion_purchased') {
          totalSpent += (eventData['amount'] as num).toDouble();
        }

        if (eventType == 'subscription_purchased') subscriptionPurchases++;
        if (eventType == 'promotion_purchased') promotionPurchases++;
        if (eventType == 'advertisement_created') advertisementCreates++;
      }

      return {
        'totalEvents': snapshot.docs.length,
        'eventCounts': eventCounts,
        'totalSpent': totalSpent,
        'subscriptionPurchases': subscriptionPurchases,
        'promotionPurchases': promotionPurchases,
        'advertisementCreates': advertisementCreates,
      };
    } catch (e) {
      debugPrint('ERROR: [AnalyticsService] Failed to get user analytics: $e');
      return {};
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РѕР±С‰РµР№ СЃС‚Р°С‚РёСЃС‚РёРєРё РїР»Р°С‚С„РѕСЂРјС‹
  static Future<Map<String, dynamic>> getPlatformAnalytics() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('analytics_events').get();

      final Map<String, int> eventCounts = {};
      double totalRevenue = 0.0;
      final int totalUsers = 0;
      final Set<String> uniqueUsers = {};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final eventType = data['eventType'] as String;
        final eventData = data['eventData'] as Map<String, dynamic>;
        final userId = data['userId'] as String;

        uniqueUsers.add(userId);
        eventCounts[eventType] = (eventCounts[eventType] ?? 0) + 1;

        if (eventType == 'subscription_purchased' || eventType == 'promotion_purchased') {
          totalRevenue += (eventData['amount'] as num).toDouble();
        }
      }

      return {
        'totalEvents': snapshot.docs.length,
        'totalUsers': uniqueUsers.length,
        'eventCounts': eventCounts,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      debugPrint('ERROR: [AnalyticsService] Failed to get platform analytics: $e');
      return {};
    }
  }

  /// Р›РѕРіРёСЂРѕРІР°РЅРёРµ РёР·РјРµРЅРµРЅРёСЏ С‚РµРјС‹
  static Future<void> logChangeTheme(String themeName) async {
    try {
      await _analytics.logEvent(
        name: 'theme_changed',
        parameters: {
          'theme_name': themeName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      debugPrint('INFO: [AnalyticsService] Theme change logged: $themeName');
    } catch (e) {
      debugPrint('ERROR: [AnalyticsService] Failed to log theme change: $e');
    }
  }
}

