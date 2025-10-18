import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import '../models/dynamic_pricing.dart';
import 'package:flutter/foundation.dart';

class DynamicPricingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// РџРѕР»СѓС‡РµРЅРёРµ Р°РєС‚СѓР°Р»СЊРЅРѕР№ С†РµРЅС‹ РґР»СЏ СѓСЃР»СѓРіРё
  Future<double> getCurrentPrice({
    required ServiceType serviceType,
    required String region,
    required String userTier,
    Map<String, dynamic>? additionalFactors,
  }) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј РїСЂР°РІРёР»Р° С†РµРЅРѕРѕР±СЂР°Р·РѕРІР°РЅРёСЏ
      final PricingRule? rule = await _getPricingRule(serviceType);
      if (rule == null) {
        debugPrint('WARNING: [DynamicPricingService] No pricing rule found for $serviceType');
        return 0.0;
      }

      // РџРѕР»СѓС‡Р°РµРј РјРµС‚СЂРёРєРё СЃРїСЂРѕСЃР°
      final DemandMetrics? demandMetrics = await _getDemandMetrics(serviceType, region);

      // РџРѕР»СѓС‡Р°РµРј СЂРµРіРёРѕРЅР°Р»СЊРЅС‹Рµ РЅР°СЃС‚СЂРѕР№РєРё
      final RegionalPricing? regionalPricing = await _getRegionalPricing(region);

      // Р Р°СЃСЃС‡РёС‚С‹РІР°РµРј С„Р°РєС‚РѕСЂС‹
      final Map<String, dynamic> factors = await _calculateFactors(
        serviceType: serviceType,
        region: region,
        userTier: userTier,
        demandMetrics: demandMetrics,
        regionalPricing: regionalPricing,
        additionalFactors: additionalFactors,
      );

      // РЎРѕР·РґР°РµРј РѕР±РЅРѕРІР»РµРЅРЅРѕРµ РїСЂР°РІРёР»Рѕ СЃ Р°РєС‚СѓР°Р»СЊРЅС‹РјРё С„Р°РєС‚РѕСЂР°РјРё
      final PricingRule updatedRule = rule.copyWith(
        demandFactor: factors['demandFactor'] ?? rule.demandFactor,
        timeFactor: factors['timeFactor'] ?? rule.timeFactor,
        regionFactor: factors['regionFactor'] ?? rule.regionFactor,
        seasonFactor: factors['seasonFactor'] ?? rule.seasonFactor,
        userTierFactor: factors['userTierFactor'] ?? rule.userTierFactor,
        competitionFactor: factors['competitionFactor'] ?? rule.competitionFactor,
      );

      // Р Р°СЃСЃС‡РёС‚С‹РІР°РµРј С„РёРЅР°Р»СЊРЅСѓСЋ С†РµРЅСѓ
      final double finalPrice = updatedRule.calculateFinalPrice(
        region: region,
        userTier: userTier,
        additionalFactors: factors,
      );

      // РЎРѕС…СЂР°РЅСЏРµРј РёСЃС‚РѕСЂРёСЋ С†РµРЅРѕРѕР±СЂР°Р·РѕРІР°РЅРёСЏ
      await _savePricingHistory(
        serviceType: serviceType,
        region: region,
        basePrice: rule.basePrice,
        finalPrice: finalPrice,
        factors: factors,
        userId: additionalFactors?['userId'],
      );

      debugPrint(
          'INFO: [DynamicPricingService] Price calculated: $finalPrice for $serviceType in $region');
      return finalPrice;
    } catch (e) {
      debugPrint('ERROR: [DynamicPricingService] Failed to get current price: $e');
      return 0.0;
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РїСЂР°РІРёР»Р° С†РµРЅРѕРѕР±СЂР°Р·РѕРІР°РЅРёСЏ
  Future<PricingRule?> _getPricingRule(ServiceType serviceType) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('pricing_rules')
          .where('serviceType', isEqualTo: serviceType.toString().split('.').last)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return PricingRule.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('ERROR: [DynamicPricingService] Failed to get pricing rule: $e');
      return null;
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РјРµС‚СЂРёРє СЃРїСЂРѕСЃР°
  Future<DemandMetrics?> _getDemandMetrics(ServiceType serviceType, String region) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('demand_metrics')
          .where('serviceType', isEqualTo: serviceType.toString().split('.').last)
          .where('region', isEqualTo: region)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return DemandMetrics.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('ERROR: [DynamicPricingService] Failed to get demand metrics: $e');
      return null;
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ СЂРµРіРёРѕРЅР°Р»СЊРЅС‹С… РЅР°СЃС‚СЂРѕРµРє
  Future<RegionalPricing?> _getRegionalPricing(String region) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('regional_pricing')
          .where('region', isEqualTo: region)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return RegionalPricing.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('ERROR: [DynamicPricingService] Failed to get regional pricing: $e');
      return null;
    }
  }

  /// Р Р°СЃС‡РµС‚ С„Р°РєС‚РѕСЂРѕРІ С†РµРЅРѕРѕР±СЂР°Р·РѕРІР°РЅРёСЏ
  Future<Map<String, dynamic>> _calculateFactors({
    required ServiceType serviceType,
    required String region,
    required String userTier,
    DemandMetrics? demandMetrics,
    RegionalPricing? regionalPricing,
    Map<String, dynamic>? additionalFactors,
  }) async {
    final Map<String, dynamic> factors = {};

    // Р¤Р°РєС‚РѕСЂ СЃРїСЂРѕСЃР°
    if (demandMetrics != null) {
      factors['demandFactor'] = demandMetrics.calculatedDemandLevel;
    } else {
      factors['demandFactor'] = 1.0; // РЎСЂРµРґРЅРёР№ СЃРїСЂРѕСЃ РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ
    }

    // Р’СЂРµРјРµРЅРЅРѕР№ С„Р°РєС‚РѕСЂ
    factors['timeFactor'] = _calculateTimeFactor();

    // Р РµРіРёРѕРЅР°Р»СЊРЅС‹Р№ С„Р°РєС‚РѕСЂ
    if (regionalPricing != null) {
      factors['regionFactor'] = regionalPricing.economicFactor;
    } else {
      factors['regionFactor'] = 1.0; // Р‘Р°Р·РѕРІС‹Р№ СЂРµРіРёРѕРЅ
    }

    // РЎРµР·РѕРЅРЅС‹Р№ С„Р°РєС‚РѕСЂ
    factors['seasonFactor'] = _calculateSeasonFactor();

    // Р¤Р°РєС‚РѕСЂ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
    factors['userTierFactor'] = _calculateUserTierFactor(userTier);

    // Р¤Р°РєС‚РѕСЂ РєРѕРЅРєСѓСЂРµРЅС†РёРё
    factors['competitionFactor'] = _calculateCompetitionFactor(serviceType, region);

    // Р”РѕРїРѕР»РЅРёС‚РµР»СЊРЅС‹Рµ С„Р°РєС‚РѕСЂС‹
    if (additionalFactors != null) {
      factors.addAll(additionalFactors);
    }

    return factors;
  }

  /// Р Р°СЃС‡РµС‚ РІСЂРµРјРµРЅРЅРѕРіРѕ С„Р°РєС‚РѕСЂР°
  double _calculateTimeFactor() {
    final DateTime now = DateTime.now();
    final int hour = now.hour;
    final int dayOfWeek = now.weekday;

    // РџРёРєРѕРІС‹Рµ С‡Р°СЃС‹ (18:00-22:00) - +20%
    if (hour >= 18 && hour <= 22) {
      return 1.2;
    }

    // Р’С‹С…РѕРґРЅС‹Рµ РґРЅРё - +15%
    if (dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday) {
      return 1.15;
    }

    // РќРѕС‡РЅС‹Рµ С‡Р°СЃС‹ (00:00-06:00) - -10%
    if (hour >= 0 && hour <= 6) {
      return 0.9;
    }

    return 1.0; // РЎС‚Р°РЅРґР°СЂС‚РЅРѕРµ РІСЂРµРјСЏ
  }

  /// Р Р°СЃС‡РµС‚ СЃРµР·РѕРЅРЅРѕРіРѕ С„Р°РєС‚РѕСЂР°
  double _calculateSeasonFactor() {
    final DateTime now = DateTime.now();
    final int month = now.month;

    // Р›РµС‚РЅРёРµ РјРµСЃСЏС†С‹ (РёСЋРЅСЊ-Р°РІРіСѓСЃС‚) - +25%
    if (month >= 6 && month <= 8) {
      return 1.25;
    }

    // Р—РёРјРЅРёРµ РїСЂР°Р·РґРЅРёРєРё (РґРµРєР°Р±СЂСЊ-СЏРЅРІР°СЂСЊ) - +30%
    if (month == 12 || month == 1) {
      return 1.3;
    }

    // Р’РµСЃРµРЅРЅРёРµ РјРµСЃСЏС†С‹ (РјР°СЂС‚-РјР°Р№) - +10%
    if (month >= 3 && month <= 5) {
      return 1.1;
    }

    return 1.0; // РћСЃРµРЅСЊ
  }

  /// Р Р°СЃС‡РµС‚ С„Р°РєС‚РѕСЂР° РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  double _calculateUserTierFactor(String userTier) {
    switch (userTier.toLowerCase()) {
      case 'free':
        return 1.0; // Р‘Р°Р·РѕРІР°СЏ С†РµРЅР°
      case 'premium':
        return 0.9; // РЎРєРёРґРєР° 10% РґР»СЏ РїСЂРµРјРёСѓРј
      case 'pro':
        return 0.8; // РЎРєРёРґРєР° 20% РґР»СЏ PRO
      default:
        return 1.0;
    }
  }

  /// Р Р°СЃС‡РµС‚ С„Р°РєС‚РѕСЂР° РєРѕРЅРєСѓСЂРµРЅС†РёРё
  double _calculateCompetitionFactor(ServiceType serviceType, String region) {
    // РЈРїСЂРѕС‰РµРЅРЅР°СЏ Р»РѕРіРёРєР° - РІ СЂРµР°Р»СЊРЅРѕРј РїСЂРёР»РѕР¶РµРЅРёРё РЅСѓР¶РЅРѕ Р°РЅР°Р»РёР·РёСЂРѕРІР°С‚СЊ РєРѕРЅРєСѓСЂРµРЅС‚РѕРІ
    switch (serviceType) {
      case ServiceType.subscription:
        return 1.0; // РЎС‚Р°Р±РёР»СЊРЅР°СЏ РєРѕРЅРєСѓСЂРµРЅС†РёСЏ
      case ServiceType.promotion:
        return 1.1; // Р’С‹СЃРѕРєР°СЏ РєРѕРЅРєСѓСЂРµРЅС†РёСЏ
      case ServiceType.advertisement:
        return 0.9; // РќРёР·РєР°СЏ РєРѕРЅРєСѓСЂРµРЅС†РёСЏ
      case ServiceType.premiumFeature:
        return 1.0;
    }
  }

  /// РЎРѕС…СЂР°РЅРµРЅРёРµ РёСЃС‚РѕСЂРёРё С†РµРЅРѕРѕР±СЂР°Р·РѕРІР°РЅРёСЏ
  Future<void> _savePricingHistory({
    required ServiceType serviceType,
    required String region,
    required double basePrice,
    required double finalPrice,
    required Map<String, dynamic> factors,
    String? userId,
  }) async {
    try {
      final PricingHistory history = PricingHistory(
        id: _uuid.v4(),
        serviceType: serviceType,
        region: region,
        basePrice: basePrice,
        finalPrice: finalPrice,
        factors: factors,
        timestamp: DateTime.now(),
        userId: userId,
      );

      await _firestore.collection('pricing_history').doc(history.id).set(history.toMap());
    } catch (e) {
      debugPrint('ERROR: [DynamicPricingService] Failed to save pricing history: $e');
    }
  }

  /// РћР±РЅРѕРІР»РµРЅРёРµ РјРµС‚СЂРёРє СЃРїСЂРѕСЃР°
  Future<void> updateDemandMetrics({
    required ServiceType serviceType,
    required String region,
    required int activeUsers,
    required int requestsCount,
    required int availableSlots,
  }) async {
    try {
      final DemandMetrics metrics = DemandMetrics(
        id: _uuid.v4(),
        region: region,
        serviceType: serviceType,
        activeUsers: activeUsers,
        requestsCount: requestsCount,
        availableSlots: availableSlots,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('demand_metrics').doc(metrics.id).set(metrics.toMap());

      debugPrint(
          'INFO: [DynamicPricingService] Demand metrics updated for $serviceType in $region');
    } catch (e) {
      debugPrint('ERROR: [DynamicPricingService] Failed to update demand metrics: $e');
    }
  }

  /// РЎРѕР·РґР°РЅРёРµ РїСЂР°РІРёР»Р° С†РµРЅРѕРѕР±СЂР°Р·РѕРІР°РЅРёСЏ
  Future<void> createPricingRule(PricingRule rule) async {
    try {
      await _firestore.collection('pricing_rules').doc(rule.id).set(rule.toMap());

      debugPrint('INFO: [DynamicPricingService] Pricing rule created: ${rule.id}');
    } catch (e) {
      debugPrint('ERROR: [DynamicPricingService] Failed to create pricing rule: $e');
      rethrow;
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РёСЃС‚РѕСЂРёРё С†РµРЅРѕРѕР±СЂР°Р·РѕРІР°РЅРёСЏ
  Future<List<PricingHistory>> getPricingHistory({
    required ServiceType serviceType,
    required String region,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore
          .collection('pricing_history')
          .where('serviceType', isEqualTo: serviceType.toString().split('.').last)
          .where('region', isEqualTo: region)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final QuerySnapshot snapshot = await query.get();
      return snapshot.docs
          .map((doc) => PricingHistory.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ERROR: [DynamicPricingService] Failed to get pricing history: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ СЃС‚Р°С‚РёСЃС‚РёРєРё С†РµРЅРѕРѕР±СЂР°Р·РѕРІР°РЅРёСЏ
  Future<Map<String, dynamic>> getPricingStats({
    required ServiceType serviceType,
    required String region,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final List<PricingHistory> history = await getPricingHistory(
        serviceType: serviceType,
        region: region,
        startDate: startDate,
        endDate: endDate,
      );

      if (history.isEmpty) {
        return {
          'averagePrice': 0.0,
          'minPrice': 0.0,
          'maxPrice': 0.0,
          'priceVolatility': 0.0,
          'totalTransactions': 0,
        };
      }

      final List<double> prices = history.map((h) => h.finalPrice).toList();
      final double averagePrice = prices.reduce((a, b) => a + b) / prices.length;
      final double minPrice = prices.reduce((a, b) => a < b ? a : b);
      final double maxPrice = prices.reduce((a, b) => a > b ? a : b);

      // Р Р°СЃС‡РµС‚ РІРѕР»Р°С‚РёР»СЊРЅРѕСЃС‚Рё (СЃС‚Р°РЅРґР°СЂС‚РЅРѕРµ РѕС‚РєР»РѕРЅРµРЅРёРµ)
      final double variance = prices
              .map((price) => (price - averagePrice) * (price - averagePrice))
              .reduce((a, b) => a + b) /
          prices.length;
      final double priceVolatility = variance > 0 ? variance : 0.0;

      return {
        'averagePrice': averagePrice,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'priceVolatility': priceVolatility,
        'totalTransactions': history.length,
        'priceChangePercent': history.isNotEmpty ? history.first.priceChangePercent : 0.0,
      };
    } catch (e) {
      debugPrint('ERROR: [DynamicPricingService] Failed to get pricing stats: $e');
      return {};
    }
  }
}

