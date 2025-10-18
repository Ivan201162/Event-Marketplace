import 'dart:math';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import '../models/smart_advertising.dart';
import 'package:flutter/foundation.dart';

class SmartAdvertisingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  /// РџРѕР»СѓС‡РµРЅРёРµ СЂРµР»РµРІР°РЅС‚РЅРѕР№ СЂРµРєР»Р°РјС‹ РґР»СЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<List<SmartAdvertisement>> getRelevantAds({
    required String userId,
    required String placement,
    required Map<String, dynamic> userProfile,
    required Map<String, dynamic> userBehavior,
    int limit = 5,
  }) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј Р°РєС‚РёРІРЅСѓСЋ СЂРµРєР»Р°РјСѓ РґР»СЏ РґР°РЅРЅРѕРіРѕ СЂР°Р·РјРµС‰РµРЅРёСЏ
      final QuerySnapshot snapshot = await _firestore
          .collection('smart_advertisements')
          .where('status', isEqualTo: 'active')
          .where('placements', arrayContains: placement)
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      // РџСЂРµРѕР±СЂР°Р·СѓРµРј РІ РѕР±СЉРµРєС‚С‹ Рё СЂР°СЃСЃС‡РёС‚С‹РІР°РµРј СЂРµР»РµРІР°РЅС‚РЅРѕСЃС‚СЊ
      final List<SmartAdvertisement> ads = snapshot.docs
          .map((doc) => SmartAdvertisement.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Р Р°СЃСЃС‡РёС‚С‹РІР°РµРј СЂРµР»РµРІР°РЅС‚РЅРѕСЃС‚СЊ РґР»СЏ РєР°Р¶РґРѕРіРѕ РѕР±СЉСЏРІР»РµРЅРёСЏ
      final List<MapEntry<SmartAdvertisement, double>> adsWithRelevance = ads
          .map((ad) => MapEntry(
                ad,
                ad.calculateRelevanceForUser(
                  userId: userId,
                  userProfile: userProfile,
                  userBehavior: userBehavior,
                ),
              ))
          .toList();

      // РЎРѕСЂС‚РёСЂСѓРµРј РїРѕ СЂРµР»РµРІР°РЅС‚РЅРѕСЃС‚Рё
      adsWithRelevance.sort((a, b) => b.value.compareTo(a.value));

      // Р¤РёР»СЊС‚СЂСѓРµРј РїРѕ РјРёРЅРёРјР°Р»СЊРЅРѕР№ СЂРµР»РµРІР°РЅС‚РЅРѕСЃС‚Рё Рё РѕРіСЂР°РЅРёС‡РёРІР°РµРј РєРѕР»РёС‡РµСЃС‚РІРѕ
      final List<SmartAdvertisement> relevantAds = adsWithRelevance
          .where((entry) => entry.value >= 0.3) // РњРёРЅРёРјР°Р»СЊРЅР°СЏ СЂРµР»РµРІР°РЅС‚РЅРѕСЃС‚СЊ 30%
          .take(limit)
          .map((entry) => entry.key)
          .toList();

      // Р—Р°РїРёСЃС‹РІР°РµРј РїРѕРєР°Р·С‹
      for (final ad in relevantAds) {
        await _recordImpression(
          adId: ad.id,
          userId: userId,
          placement: placement,
          relevanceScore: adsWithRelevance.firstWhere((entry) => entry.key.id == ad.id).value,
          userContext: {
            'userProfile': userProfile,
            'userBehavior': userBehavior,
          },
        );
      }

      debugPrint(
          'INFO: [SmartAdvertisingService] Found ${relevantAds.length} relevant ads for user $userId');
      return relevantAds;
    } catch (e) {
      debugPrint('ERROR: [SmartAdvertisingService] Failed to get relevant ads: $e');
      return [];
    }
  }

  /// Р—Р°РїРёСЃСЊ РїРѕРєР°Р·Р° СЂРµРєР»Р°РјС‹
  Future<void> _recordImpression({
    required String adId,
    required String userId,
    required String placement,
    required double relevanceScore,
    Map<String, dynamic>? userContext,
  }) async {
    try {
      final AdImpression impression = AdImpression(
        id: _uuid.v4(),
        adId: adId,
        userId: userId,
        placement: placement,
        timestamp: DateTime.now(),
        relevanceScore: relevanceScore,
        userContext: userContext,
      );

      await _firestore.collection('ad_impressions').doc(impression.id).set(impression.toMap());

      // РћР±РЅРѕРІР»СЏРµРј СЃС‡РµС‚С‡РёРєРё РІ РѕР±СЉСЏРІР»РµРЅРёРё
      await _firestore.collection('smart_advertisements').doc(adId).update({
        'impressions': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('INFO: [SmartAdvertisingService] Impression recorded for ad $adId');
    } catch (e) {
      debugPrint('ERROR: [SmartAdvertisingService] Failed to record impression: $e');
    }
  }

  /// Р—Р°РїРёСЃСЊ РєР»РёРєР° РїРѕ СЂРµРєР»Р°РјРµ
  Future<void> recordClick({
    required String adId,
    required String userId,
    required String placement,
  }) async {
    try {
      // РќР°С…РѕРґРёРј РїРѕСЃР»РµРґРЅРёР№ РїРѕРєР°Р· СЌС‚РѕРіРѕ РѕР±СЉСЏРІР»РµРЅРёСЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЋ
      final QuerySnapshot impressionSnapshot = await _firestore
          .collection('ad_impressions')
          .where('adId', isEqualTo: adId)
          .where('userId', isEqualTo: userId)
          .where('placement', isEqualTo: placement)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (impressionSnapshot.docs.isNotEmpty) {
        final String impressionId = impressionSnapshot.docs.first.id;
        await _firestore.collection('ad_impressions').doc(impressionId).update({
          'isClicked': true,
        });
      }

      // РћР±РЅРѕРІР»СЏРµРј СЃС‡РµС‚С‡РёРєРё РІ РѕР±СЉСЏРІР»РµРЅРёРё
      await _firestore.collection('smart_advertisements').doc(adId).update({
        'clicks': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // РџРµСЂРµСЃС‡РёС‚С‹РІР°РµРј CTR
      await _updateAdMetrics(adId);

      debugPrint('INFO: [SmartAdvertisingService] Click recorded for ad $adId');
    } catch (e) {
      debugPrint('ERROR: [SmartAdvertisingService] Failed to record click: $e');
    }
  }

  /// Р—Р°РїРёСЃСЊ РєРѕРЅРІРµСЂСЃРёРё
  Future<void> recordConversion({
    required String adId,
    required String userId,
    required String conversionType,
    required double conversionValue,
  }) async {
    try {
      // РќР°С…РѕРґРёРј РїРѕСЃР»РµРґРЅРёР№ РєР»РёРє РїРѕ СЌС‚РѕРјСѓ РѕР±СЉСЏРІР»РµРЅРёСЋ
      final QuerySnapshot clickSnapshot = await _firestore
          .collection('ad_impressions')
          .where('adId', isEqualTo: adId)
          .where('userId', isEqualTo: userId)
          .where('isClicked', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (clickSnapshot.docs.isNotEmpty) {
        final String impressionId = clickSnapshot.docs.first.id;
        await _firestore.collection('ad_impressions').doc(impressionId).update({
          'isConverted': true,
        });
      }

      // РћР±РЅРѕРІР»СЏРµРј СЃС‡РµС‚С‡РёРєРё РІ РѕР±СЉСЏРІР»РµРЅРёРё
      await _firestore.collection('smart_advertisements').doc(adId).update({
        'conversions': FieldValue.increment(1),
        'spentAmount': FieldValue.increment(conversionValue),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // РџРµСЂРµСЃС‡РёС‚С‹РІР°РµРј РјРµС‚СЂРёРєРё
      await _updateAdMetrics(adId);

      debugPrint('INFO: [SmartAdvertisingService] Conversion recorded for ad $adId');
    } catch (e) {
      debugPrint('ERROR: [SmartAdvertisingService] Failed to record conversion: $e');
    }
  }

  /// РћР±РЅРѕРІР»РµРЅРёРµ РјРµС‚СЂРёРє РѕР±СЉСЏРІР»РµРЅРёСЏ
  Future<void> _updateAdMetrics(String adId) async {
    try {
      final DocumentSnapshot adDoc =
          await _firestore.collection('smart_advertisements').doc(adId).get();

      if (!adDoc.exists) return;

      final SmartAdvertisement ad =
          SmartAdvertisement.fromMap(adDoc.data() as Map<String, dynamic>);

      // Р Р°СЃСЃС‡РёС‚С‹РІР°РµРј CTR
      final double ctr = ad.impressions > 0 ? (ad.clicks / ad.impressions) * 100 : 0.0;

      // Р Р°СЃСЃС‡РёС‚С‹РІР°РµРј CPC
      final double cpc = ad.clicks > 0 ? ad.spentAmount / ad.clicks : 0.0;

      // Р Р°СЃСЃС‡РёС‚С‹РІР°РµРј CPM
      final double cpm = ad.impressions > 0 ? (ad.spentAmount / ad.impressions) * 1000 : 0.0;

      // РћР±РЅРѕРІР»СЏРµРј РјРµС‚СЂРёРєРё
      await _firestore.collection('smart_advertisements').doc(adId).update({
        'ctr': ctr,
        'cpc': cpc,
        'cpm': cpm,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('INFO: [SmartAdvertisingService] Metrics updated for ad $adId');
    } catch (e) {
      debugPrint('ERROR: [SmartAdvertisingService] Failed to update ad metrics: $e');
    }
  }

  /// РЎРѕР·РґР°РЅРёРµ СѓРјРЅРѕРіРѕ РѕР±СЉСЏРІР»РµРЅРёСЏ
  Future<String> createSmartAd(SmartAdvertisement ad) async {
    try {
      final String adId = _uuid.v4();
      final SmartAdvertisement newAd = SmartAdvertisement(
        id: adId,
        userId: ad.userId,
        title: ad.title,
        content: ad.content,
        type: ad.type,
        budget: ad.budget,
        startDate: ad.startDate,
        endDate: ad.endDate,
        status: ad.status,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        description: ad.description,
        imageUrl: ad.imageUrl,
        videoUrl: ad.videoUrl,
        targetUrl: ad.targetUrl,
        region: ad.region,
        category: ad.category,
        targetAudience: ad.targetAudience,
        placements: ad.placements,
        targeting: ad.targeting,
        bidAmount: ad.bidAmount,
        maxBid: ad.maxBid,
        dailyBudget: ad.dailyBudget,
        isAutoOptimized: ad.isAutoOptimized,
        optimizationSettings: ad.optimizationSettings,
        metadata: ad.metadata,
      );

      await _firestore.collection('smart_advertisements').doc(adId).set(newAd.toMap());

      debugPrint('INFO: [SmartAdvertisingService] Smart ad created: $adId');
      return adId;
    } catch (e) {
      debugPrint('ERROR: [SmartAdvertisingService] Failed to create smart ad: $e');
      rethrow;
    }
  }

  /// РђРІС‚РѕРјР°С‚РёС‡РµСЃРєР°СЏ РѕРїС‚РёРјРёР·Р°С†РёСЏ РѕР±СЉСЏРІР»РµРЅРёСЏ
  Future<void> optimizeAd(String adId) async {
    try {
      final DocumentSnapshot adDoc =
          await _firestore.collection('smart_advertisements').doc(adId).get();

      if (!adDoc.exists) return;

      final SmartAdvertisement ad =
          SmartAdvertisement.fromMap(adDoc.data() as Map<String, dynamic>);

      if (!ad.isAutoOptimized) return;

      // РђРЅР°Р»РёР·РёСЂСѓРµРј РїСЂРѕРёР·РІРѕРґРёС‚РµР»СЊРЅРѕСЃС‚СЊ
      final Map<String, dynamic> performance = await _analyzeAdPerformance(adId);

      // РџСЂРёРјРµРЅСЏРµРј РѕРїС‚РёРјРёР·Р°С†РёРё
      final Map<String, dynamic> optimizations = await _applyOptimizations(ad, performance);

      // РЎРѕС…СЂР°РЅСЏРµРј СЂРµР·СѓР»СЊС‚Р°С‚С‹ РѕРїС‚РёРјРёР·Р°С†РёРё
      final AdOptimization optimization = AdOptimization(
        id: _uuid.v4(),
        adId: adId,
        optimizationType: 'auto_optimization',
        parameters: performance,
        results: optimizations,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('ad_optimizations')
          .doc(optimization.id)
          .set(optimization.toMap());

      // РџСЂРёРјРµРЅСЏРµРј РёР·РјРµРЅРµРЅРёСЏ Рє РѕР±СЉСЏРІР»РµРЅРёСЋ
      await _firestore.collection('smart_advertisements').doc(adId).update({
        'optimizationSettings': optimizations,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('INFO: [SmartAdvertisingService] Ad optimized: $adId');
    } catch (e) {
      debugPrint('ERROR: [SmartAdvertisingService] Failed to optimize ad: $e');
    }
  }

  /// РђРЅР°Р»РёР· РїСЂРѕРёР·РІРѕРґРёС‚РµР»СЊРЅРѕСЃС‚Рё РѕР±СЉСЏРІР»РµРЅРёСЏ
  Future<Map<String, dynamic>> _analyzeAdPerformance(String adId) async {
    try {
      final QuerySnapshot impressionsSnapshot =
          await _firestore.collection('ad_impressions').where('adId', isEqualTo: adId).get();

      if (impressionsSnapshot.docs.isEmpty) {
        return {'status': 'insufficient_data'};
      }

      final List<AdImpression> impressions = impressionsSnapshot.docs
          .map((doc) => AdImpression.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      final int totalImpressions = impressions.length;
      final int totalClicks = impressions.where((i) => i.isClicked).length;
      final int totalConversions = impressions.where((i) => i.isConverted).length;

      final double ctr = totalImpressions > 0 ? (totalClicks / totalImpressions) * 100 : 0.0;
      final double conversionRate = totalClicks > 0 ? (totalConversions / totalClicks) * 100 : 0.0;

      // РђРЅР°Р»РёР· РїРѕ СЂР°Р·РјРµС‰РµРЅРёСЏРј
      final Map<String, int> placementImpressions = {};
      final Map<String, int> placementClicks = {};

      for (final impression in impressions) {
        placementImpressions[impression.placement] =
            (placementImpressions[impression.placement] ?? 0) + 1;
        if (impression.isClicked) {
          placementClicks[impression.placement] = (placementClicks[impression.placement] ?? 0) + 1;
        }
      }

      return {
        'totalImpressions': totalImpressions,
        'totalClicks': totalClicks,
        'totalConversions': totalConversions,
        'ctr': ctr,
        'conversionRate': conversionRate,
        'placementPerformance':
            placementImpressions.map((placement, impressions) => MapEntry(placement, {
                  'impressions': impressions,
                  'clicks': placementClicks[placement] ?? 0,
                  'ctr': impressions > 0
                      ? ((placementClicks[placement] ?? 0) / impressions) * 100
                      : 0.0,
                })),
        'status': 'analyzed',
      };
    } catch (e) {
      debugPrint('ERROR: [SmartAdvertisingService] Failed to analyze ad performance: $e');
      return {'status': 'error'};
    }
  }

  /// РџСЂРёРјРµРЅРµРЅРёРµ РѕРїС‚РёРјРёР·Р°С†РёР№
  Future<Map<String, dynamic>> _applyOptimizations(
    SmartAdvertisement ad,
    Map<String, dynamic> performance,
  ) async {
    final Map<String, dynamic> optimizations = {};

    if (performance['status'] != 'analyzed') {
      return optimizations;
    }

    final double ctr = performance['ctr'] ?? 0.0;
    final double conversionRate = performance['conversionRate'] ?? 0.0;

    // РћРїС‚РёРјРёР·Р°С†РёСЏ СЃС‚Р°РІРєРё
    if (ctr < 1.0) {
      // РќРёР·РєРёР№ CTR - СЃРЅРёР¶Р°РµРј СЃС‚Р°РІРєСѓ
      optimizations['bidAdjustment'] = -0.1; // РЎРЅРёР¶Р°РµРј РЅР° 10%
    } else if (ctr > 3.0) {
      // Р’С‹СЃРѕРєРёР№ CTR - РїРѕРІС‹С€Р°РµРј СЃС‚Р°РІРєСѓ
      optimizations['bidAdjustment'] = 0.1; // РџРѕРІС‹С€Р°РµРј РЅР° 10%
    }

    // РћРїС‚РёРјРёР·Р°С†РёСЏ СЂР°Р·РјРµС‰РµРЅРёР№
    final Map<String, dynamic> placementPerformance = performance['placementPerformance'] ?? {};

    final List<String> bestPlacements = [];
    final List<String> worstPlacements = [];

    for (final entry in placementPerformance.entries) {
      final String placement = entry.key;
      final Map<String, dynamic> stats = entry.value;
      final double placementCtr = stats['ctr'] ?? 0.0;

      if (placementCtr > 2.0) {
        bestPlacements.add(placement);
      } else if (placementCtr < 0.5) {
        worstPlacements.add(placement);
      }
    }

    if (bestPlacements.isNotEmpty) {
      optimizations['focusPlacements'] = bestPlacements;
    }
    if (worstPlacements.isNotEmpty) {
      optimizations['excludePlacements'] = worstPlacements;
    }

    // РћРїС‚РёРјРёР·Р°С†РёСЏ С‚Р°СЂРіРµС‚РёРЅРіР°
    if (conversionRate < 5.0) {
      optimizations['targetingAdjustment'] = 'broaden';
    } else if (conversionRate > 15.0) {
      optimizations['targetingAdjustment'] = 'narrow';
    }

    return optimizations;
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ СЃС‚Р°С‚РёСЃС‚РёРєРё РѕР±СЉСЏРІР»РµРЅРёСЏ
  Future<Map<String, dynamic>> getAdStats(String adId) async {
    try {
      final DocumentSnapshot adDoc =
          await _firestore.collection('smart_advertisements').doc(adId).get();

      if (!adDoc.exists) {
        return {};
      }

      final SmartAdvertisement ad =
          SmartAdvertisement.fromMap(adDoc.data() as Map<String, dynamic>);

      // РџРѕР»СѓС‡Р°РµРј РґРѕРїРѕР»РЅРёС‚РµР»СЊРЅС‹Рµ РјРµС‚СЂРёРєРё
      final QuerySnapshot impressionsSnapshot =
          await _firestore.collection('ad_impressions').where('adId', isEqualTo: adId).get();

      final List<AdImpression> impressions = impressionsSnapshot.docs
          .map((doc) => AdImpression.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Р Р°СЃСЃС‡РёС‚С‹РІР°РµРј РґРѕРїРѕР»РЅРёС‚РµР»СЊРЅС‹Рµ РјРµС‚СЂРёРєРё
      final double averageRelevance = impressions.isNotEmpty
          ? impressions.map((i) => i.relevanceScore).reduce((a, b) => a + b) / impressions.length
          : 0.0;

      final Map<String, int> dailyImpressions = {};
      for (final impression in impressions) {
        final String date = impression.timestamp.toIso8601String().split('T')[0];
        dailyImpressions[date] = (dailyImpressions[date] ?? 0) + 1;
      }

      return {
        'adId': adId,
        'title': ad.title,
        'impressions': ad.impressions,
        'clicks': ad.clicks,
        'conversions': ad.conversions,
        'spentAmount': ad.spentAmount,
        'ctr': ad.ctr,
        'cpc': ad.cpc,
        'cpm': ad.cpm,
        'averageRelevance': averageRelevance,
        'dailyImpressions': dailyImpressions,
        'status': ad.status,
        'isActive': ad.isActive,
        'budgetRemaining': ad.budget - ad.spentAmount,
        'daysRemaining': ad.endDate.difference(DateTime.now()).inDays,
      };
    } catch (e) {
      debugPrint('ERROR: [SmartAdvertisingService] Failed to get ad stats: $e');
      return {};
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РѕР±СЉСЏРІР»РµРЅРёР№ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<List<SmartAdvertisement>> getUserAds(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('smart_advertisements')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SmartAdvertisement.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ERROR: [SmartAdvertisingService] Failed to get user ads: $e');
      return [];
    }
  }
}

