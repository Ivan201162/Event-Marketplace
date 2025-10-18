import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import '../models/revenue_analytics.dart';
import 'package:flutter/foundation.dart';

class RevenueAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Р—Р°РїРёСЃСЊ СЃС‚Р°С‚РёСЃС‚РёРєРё РґРѕС…РѕРґР°
  Future<void> recordRevenue({
    required RevenueSource sourceType,
    required double amount,
    required String currency,
    required String region,
    String? userId,
    String? transactionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final RevenueStats stats = RevenueStats(
        id: _uuid.v4(),
        date: DateTime.now(),
        period: RevenuePeriod.daily,
        sourceType: sourceType,
        amount: amount,
        currency: currency,
        region: region,
        createdAt: DateTime.now(),
        userId: userId,
        transactionId: transactionId,
        metadata: metadata,
      );

      await _firestore.collection('revenue_stats').doc(stats.id).set(stats.toMap());

      // РћР±РЅРѕРІР»СЏРµРј Р°РіСЂРµРіРёСЂРѕРІР°РЅРЅСѓСЋ СЃС‚Р°С‚РёСЃС‚РёРєСѓ
      await _updateAggregatedStats(stats);

      debugPrint(
          'INFO: [RevenueAnalyticsService] Revenue recorded: $amount $currency from $sourceType');
    } catch (e) {
      debugPrint('ERROR: [RevenueAnalyticsService] Failed to record revenue: $e');
    }
  }

  /// РћР±РЅРѕРІР»РµРЅРёРµ Р°РіСЂРµРіРёСЂРѕРІР°РЅРЅРѕР№ СЃС‚Р°С‚РёСЃС‚РёРєРё
  Future<void> _updateAggregatedStats(RevenueStats stats) async {
    try {
      final String dateKey = _getDateKey(stats.date);

      // РћР±РЅРѕРІР»СЏРµРј РґРЅРµРІРЅСѓСЋ СЃС‚Р°С‚РёСЃС‚РёРєСѓ
      await _firestore.collection('revenue_aggregates').doc('daily_$dateKey').set({
        'date': dateKey,
        'totalRevenue': FieldValue.increment(stats.amount),
        'transactionCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // РћР±РЅРѕРІР»СЏРµРј СЃС‚Р°С‚РёСЃС‚РёРєСѓ РїРѕ РёСЃС‚РѕС‡РЅРёРєР°Рј
      await _firestore
          .collection('revenue_aggregates')
          .doc('source_${stats.sourceType.toString().split('.').last}')
          .set({
        'sourceType': stats.sourceType.toString().split('.').last,
        'totalRevenue': FieldValue.increment(stats.amount),
        'transactionCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // РћР±РЅРѕРІР»СЏРµРј СЃС‚Р°С‚РёСЃС‚РёРєСѓ РїРѕ СЂРµРіРёРѕРЅР°Рј
      await _firestore.collection('revenue_aggregates').doc('region_${stats.region}').set({
        'region': stats.region,
        'totalRevenue': FieldValue.increment(stats.amount),
        'transactionCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('ERROR: [RevenueAnalyticsService] Failed to update aggregated stats: $e');
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РґР°С€Р±РѕСЂРґР° РґРѕС…РѕРґРѕРІ
  Future<RevenueDashboard> getRevenueDashboard({
    required RevenuePeriod period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final DateTime now = DateTime.now();
      final DateTime periodStart = startDate ?? _getPeriodStart(now, period);
      final DateTime periodEnd = endDate ?? now;

      // РџРѕР»СѓС‡Р°РµРј СЃС‚Р°С‚РёСЃС‚РёРєСѓ РґРѕС…РѕРґРѕРІ Р·Р° РїРµСЂРёРѕРґ
      final QuerySnapshot revenueSnapshot = await _firestore
          .collection('revenue_stats')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(periodEnd))
          .get();

      // РџРѕР»СѓС‡Р°РµРј СЃС‚Р°С‚РёСЃС‚РёРєСѓ Р·Р° РїСЂРµРґС‹РґСѓС‰РёР№ РїРµСЂРёРѕРґ РґР»СЏ СЂР°СЃС‡РµС‚Р° СЂРѕСЃС‚Р°
      final DateTime prevPeriodStart =
          _getPeriodStart(periodStart.subtract(const Duration(days: 1)), period);
      final DateTime prevPeriodEnd = periodStart.subtract(const Duration(days: 1));

      final QuerySnapshot prevRevenueSnapshot = await _firestore
          .collection('revenue_stats')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(prevPeriodStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(prevPeriodEnd))
          .get();

      // Р Р°СЃСЃС‡РёС‚С‹РІР°РµРј РјРµС‚СЂРёРєРё
      final Map<String, double> revenueBySource = {};
      final Map<String, double> revenueByRegion = {};
      double totalRevenue = 0.0;
      int totalTransactions = 0;

      for (final doc in revenueSnapshot.docs) {
        final RevenueStats stats = RevenueStats.fromMap(doc.data() as Map<String, dynamic>);

        totalRevenue += stats.amount;
        totalTransactions++;

        // РџРѕ РёСЃС‚РѕС‡РЅРёРєР°Рј
        final String sourceKey = stats.sourceType.toString().split('.').last;
        revenueBySource[sourceKey] = (revenueBySource[sourceKey] ?? 0.0) + stats.amount;

        // РџРѕ СЂРµРіРёРѕРЅР°Рј
        revenueByRegion[stats.region] = (revenueByRegion[stats.region] ?? 0.0) + stats.amount;
      }

      // Р Р°СЃСЃС‡РёС‚С‹РІР°РµРј СЂРѕСЃС‚
      double prevTotalRevenue = 0.0;
      for (final doc in prevRevenueSnapshot.docs) {
        final RevenueStats stats = RevenueStats.fromMap(doc.data() as Map<String, dynamic>);
        prevTotalRevenue += stats.amount;
      }

      final double growthRate =
          prevTotalRevenue > 0 ? ((totalRevenue - prevTotalRevenue) / prevTotalRevenue) * 100 : 0.0;

      // Р Р°СЃСЃС‡РёС‚С‹РІР°РµРј СЃСЂРµРґРЅРёР№ С‡РµРє
      final double averageOrderValue =
          totalTransactions > 0 ? totalRevenue / totalTransactions : 0.0;

      // РџРѕР»СѓС‡Р°РµРј РґРЅРµРІРЅСѓСЋ СЃС‚Р°С‚РёСЃС‚РёРєСѓ
      final List<Map<String, dynamic>> dailyRevenue =
          await _getDailyRevenue(periodStart, periodEnd);

      // РџРѕР»СѓС‡Р°РµРј РјРµСЃСЏС‡РЅСѓСЋ СЃС‚Р°С‚РёСЃС‚РёРєСѓ
      final List<Map<String, dynamic>> monthlyRevenue =
          await _getMonthlyRevenue(periodStart, periodEnd);

      // Р Р°СЃСЃС‡РёС‚С‹РІР°РµРј LTV Рё CAC
      final double ltv = await _calculateLTV();
      final double cac = await _calculateCAC();
      final double roi = cac > 0 ? (ltv / cac) * 100 : 0.0;

      // Р Р°СЃСЃС‡РёС‚С‹РІР°РµРј РєРѕРЅРІРµСЂСЃРёСЋ
      final double conversionRate = await _calculateConversionRate(periodStart, periodEnd);

      final RevenueDashboard dashboard = RevenueDashboard(
        period: period,
        totalRevenue: totalRevenue,
        revenueBySource: revenueBySource,
        revenueByRegion: revenueByRegion,
        dailyRevenue: dailyRevenue,
        monthlyRevenue: monthlyRevenue,
        growthRate: growthRate,
        averageOrderValue: averageOrderValue,
        totalTransactions: totalTransactions,
        conversionRate: conversionRate,
        ltv: ltv,
        cac: cac,
        roi: roi,
        generatedAt: DateTime.now(),
        metadata: {
          'periodStart': periodStart.toIso8601String(),
          'periodEnd': periodEnd.toIso8601String(),
        },
      );

      // РЎРѕС…СЂР°РЅСЏРµРј РґР°С€Р±РѕСЂРґ
      await _firestore
          .collection('revenue_dashboards')
          .doc('${period.toString().split('.').last}_${_getDateKey(now)}')
          .set(dashboard.toMap());

      debugPrint('INFO: [RevenueAnalyticsService] Revenue dashboard generated for $period');
      return dashboard;
    } catch (e) {
      debugPrint('ERROR: [RevenueAnalyticsService] Failed to get revenue dashboard: $e');
      rethrow;
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РґРЅРµРІРЅРѕР№ СЃС‚Р°С‚РёСЃС‚РёРєРё РґРѕС…РѕРґРѕРІ
  Future<List<Map<String, dynamic>>> _getDailyRevenue(DateTime startDate, DateTime endDate) async {
    try {
      final List<Map<String, dynamic>> dailyRevenue = [];
      final DateTime current = startDate;

      while (current.isBefore(endDate)) {
        final String dateKey = _getDateKey(current);

        final QuerySnapshot daySnapshot = await _firestore
            .collection('revenue_stats')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(current))
            .where('date', isLessThan: Timestamp.fromDate(current.add(const Duration(days: 1))))
            .get();

        double dayRevenue = 0.0;
        for (final doc in daySnapshot.docs) {
          final RevenueStats stats = RevenueStats.fromMap(doc.data() as Map<String, dynamic>);
          dayRevenue += stats.amount;
        }

        dailyRevenue.add({
          'date': dateKey,
          'revenue': dayRevenue,
          'transactions': daySnapshot.docs.length,
        });

        current = DateTime(current.year, current.month, current.day + 1);
      }

      return dailyRevenue;
    } catch (e) {
      debugPrint('ERROR: [RevenueAnalyticsService] Failed to get daily revenue: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РјРµСЃСЏС‡РЅРѕР№ СЃС‚Р°С‚РёСЃС‚РёРєРё РґРѕС…РѕРґРѕРІ
  Future<List<Map<String, dynamic>>> _getMonthlyRevenue(
      DateTime startDate, DateTime endDate) async {
    try {
      final List<Map<String, dynamic>> monthlyRevenue = [];
      final DateTime current = DateTime(startDate.year, startDate.month);

      while (current.isBefore(endDate)) {
        final DateTime monthEnd = DateTime(current.year, current.month + 1, 0);
        final DateTime actualEnd = monthEnd.isAfter(endDate) ? endDate : monthEnd;

        final QuerySnapshot monthSnapshot = await _firestore
            .collection('revenue_stats')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(current))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(actualEnd))
            .get();

        double monthRevenue = 0.0;
        for (final doc in monthSnapshot.docs) {
          final RevenueStats stats = RevenueStats.fromMap(doc.data() as Map<String, dynamic>);
          monthRevenue += stats.amount;
        }

        monthlyRevenue.add({
          'month': '${current.year}-${current.month.toString().padLeft(2, '0')}',
          'revenue': monthRevenue,
          'transactions': monthSnapshot.docs.length,
        });

        current = DateTime(current.year, current.month + 1);
      }

      return monthlyRevenue;
    } catch (e) {
      debugPrint('ERROR: [RevenueAnalyticsService] Failed to get monthly revenue: $e');
      return [];
    }
  }

  /// Р Р°СЃС‡РµС‚ LTV (Lifetime Value)
  Future<double> _calculateLTV() async {
    try {
      // РџРѕР»СѓС‡Р°РµРј РІСЃРµС… РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№ СЃ РїРѕРєСѓРїРєР°РјРё
      final QuerySnapshot usersSnapshot = await _firestore.collection('user_lifetime_values').get();

      if (usersSnapshot.docs.isEmpty) return 0.0;

      double totalLtv = 0.0;
      for (final doc in usersSnapshot.docs) {
        final UserLifetimeValue ltv = UserLifetimeValue.fromMap(doc.data() as Map<String, dynamic>);
        totalLtv += ltv.predictedLtv;
      }

      return totalLtv / usersSnapshot.docs.length;
    } catch (e) {
      debugPrint('ERROR: [RevenueAnalyticsService] Failed to calculate LTV: $e');
      return 0.0;
    }
  }

  /// Р Р°СЃС‡РµС‚ CAC (Customer Acquisition Cost)
  Future<double> _calculateCAC() async {
    try {
      // РџРѕР»СѓС‡Р°РµРј СЃС‚Р°С‚РёСЃС‚РёРєСѓ РїРѕ СЂРµС„РµСЂР°Р»Р°Рј Рё РїР°СЂС‚РЅРµСЂСЃРєРёРј РїСЂРѕРіСЂР°РјРјР°Рј
      final QuerySnapshot referralsSnapshot = await _firestore.collection('referral_rewards').get();

      final QuerySnapshot partnershipsSnapshot =
          await _firestore.collection('partner_transactions').get();

      double totalAcquisitionCost = 0.0;
      int totalAcquisitions = 0;

      // РЎС‚РѕРёРјРѕСЃС‚СЊ СЂРµС„РµСЂР°Р»РѕРІ
      for (final doc in referralsSnapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalAcquisitionCost += (data['value'] ?? 0.0).toDouble();
        totalAcquisitions++;
      }

      // РЎС‚РѕРёРјРѕСЃС‚СЊ РїР°СЂС‚РЅРµСЂСЃРєРёС… РїСЂРѕРіСЂР°РјРј
      for (final doc in partnershipsSnapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalAcquisitionCost += (data['commission_amount'] ?? 0.0).toDouble();
        totalAcquisitions++;
      }

      return totalAcquisitions > 0 ? totalAcquisitionCost / totalAcquisitions : 0.0;
    } catch (e) {
      debugPrint('ERROR: [RevenueAnalyticsService] Failed to calculate CAC: $e');
      return 0.0;
    }
  }

  /// Р Р°СЃС‡РµС‚ РєРѕРЅРІРµСЂСЃРёРё
  Future<double> _calculateConversionRate(DateTime startDate, DateTime endDate) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј РєРѕР»РёС‡РµСЃС‚РІРѕ РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№ Р·Р° РїРµСЂРёРѕРґ
      final QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // РџРѕР»СѓС‡Р°РµРј РєРѕР»РёС‡РµСЃС‚РІРѕ РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№ СЃ РїРѕРєСѓРїРєР°РјРё
      final QuerySnapshot purchasesSnapshot = await _firestore
          .collection('revenue_stats')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final Set<String> usersWithPurchases = {};
      for (final doc in purchasesSnapshot.docs) {
        final RevenueStats stats = RevenueStats.fromMap(doc.data() as Map<String, dynamic>);
        if (stats.userId != null) {
          usersWithPurchases.add(stats.userId!);
        }
      }

      final int totalUsers = usersSnapshot.docs.length;
      final int convertedUsers = usersWithPurchases.length;

      return totalUsers > 0 ? (convertedUsers / totalUsers) * 100 : 0.0;
    } catch (e) {
      debugPrint('ERROR: [RevenueAnalyticsService] Failed to calculate conversion rate: $e');
      return 0.0;
    }
  }

  /// РћР±РЅРѕРІР»РµРЅРёРµ LTV РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<void> updateUserLTV(String userId) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј РІСЃРµ С‚СЂР°РЅР·Р°РєС†РёРё РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
      final QuerySnapshot transactionsSnapshot = await _firestore
          .collection('revenue_stats')
          .where('userId', isEqualTo: userId)
          .orderBy('date')
          .get();

      if (transactionsSnapshot.docs.isEmpty) return;

      final List<RevenueStats> transactions = transactionsSnapshot.docs
          .map((doc) => RevenueStats.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      final double totalSpent = transactions.map((t) => t.amount).reduce((a, b) => a + b);
      final int totalTransactions = transactions.length;
      final DateTime firstPurchaseDate = transactions.first.date;
      final DateTime lastPurchaseDate = transactions.last.date;
      final double averageOrderValue = totalSpent / totalTransactions;

      // Р Р°СЃСЃС‡РёС‚С‹РІР°РµРј С‡Р°СЃС‚РѕС‚Сѓ РїРѕРєСѓРїРѕРє (РїРѕРєСѓРїРѕРє РІ РјРµСЃСЏС†)
      final int daysSinceFirst = DateTime.now().difference(firstPurchaseDate).inDays;
      final double purchaseFrequency =
          daysSinceFirst > 0 ? (totalTransactions / daysSinceFirst) * 30 : 0.0;

      // Р Р°СЃСЃС‡РёС‚С‹РІР°РµРј retention rate (СѓРїСЂРѕС‰РµРЅРЅРѕ)
      final double retentionRate = _calculateRetentionRate(userId);

      // РџСЂРµРґСЃРєР°Р·С‹РІР°РµРј LTV
      final double predictedLtv = _predictLTV(
        totalSpent: totalSpent,
        purchaseFrequency: purchaseFrequency,
        retentionRate: retentionRate,
        daysSinceFirst: daysSinceFirst,
      );

      final UserLifetimeValue ltv = UserLifetimeValue(
        userId: userId,
        totalSpent: totalSpent,
        totalTransactions: totalTransactions,
        firstPurchaseDate: firstPurchaseDate,
        lastPurchaseDate: lastPurchaseDate,
        averageOrderValue: averageOrderValue,
        purchaseFrequency: purchaseFrequency,
        retentionRate: retentionRate,
        predictedLtv: predictedLtv,
        segment: _determineUserSegment(totalSpent, purchaseFrequency),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('user_lifetime_values').doc(userId).set(ltv.toMap());

      debugPrint('INFO: [RevenueAnalyticsService] User LTV updated: $userId');
    } catch (e) {
      debugPrint('ERROR: [RevenueAnalyticsService] Failed to update user LTV: $e');
    }
  }

  /// Р Р°СЃС‡РµС‚ retention rate
  double _calculateRetentionRate(String userId) {
    // РЈРїСЂРѕС‰РµРЅРЅС‹Р№ СЂР°СЃС‡РµС‚ - РІ СЂРµР°Р»СЊРЅРѕРј РїСЂРёР»РѕР¶РµРЅРёРё РЅСѓР¶РЅР° Р±РѕР»РµРµ СЃР»РѕР¶РЅР°СЏ Р»РѕРіРёРєР°
    return 0.7; // 70% РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ
  }

  /// РџСЂРµРґСЃРєР°Р·Р°РЅРёРµ LTV
  double _predictLTV({
    required double totalSpent,
    required double purchaseFrequency,
    required double retentionRate,
    required int daysSinceFirst,
  }) {
    // РЈРїСЂРѕС‰РµРЅРЅР°СЏ РјРѕРґРµР»СЊ РїСЂРµРґСЃРєР°Р·Р°РЅРёСЏ LTV
    final double monthlyValue = (totalSpent / daysSinceFirst) * 30;
    final double predictedMonths = 12 * retentionRate; // РџСЂРµРґСЃРєР°Р·С‹РІР°РµРј РЅР° РіРѕРґ СЃ СѓС‡РµС‚РѕРј retention
    return monthlyValue * predictedMonths;
  }

  /// РћРїСЂРµРґРµР»РµРЅРёРµ СЃРµРіРјРµРЅС‚Р° РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  String _determineUserSegment(double totalSpent, double purchaseFrequency) {
    if (totalSpent >= 10000 && purchaseFrequency >= 2) return 'vip';
    if (totalSpent >= 5000 && purchaseFrequency >= 1) return 'premium';
    if (totalSpent >= 1000 && purchaseFrequency >= 0.5) return 'regular';
    if (totalSpent >= 100) return 'active';
    return 'new';
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РЅР°С‡Р°Р»Р° РїРµСЂРёРѕРґР°
  DateTime _getPeriodStart(DateTime date, RevenuePeriod period) {
    switch (period) {
      case RevenuePeriod.daily:
        return DateTime(date.year, date.month, date.day);
      case RevenuePeriod.weekly:
        final int daysFromMonday = date.weekday - 1;
        return DateTime(date.year, date.month, date.day - daysFromMonday);
      case RevenuePeriod.monthly:
        return DateTime(date.year, date.month);
      case RevenuePeriod.quarterly:
        final int quarter = ((date.month - 1) / 3).floor();
        return DateTime(date.year, quarter * 3 + 1);
      case RevenuePeriod.yearly:
        return DateTime(date.year);
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РєР»СЋС‡Р° РґР°С‚С‹
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// РЎРѕР·РґР°РЅРёРµ РІРѕСЂРѕРЅРєРё РєРѕРЅРІРµСЂСЃРёРё
  Future<String> createConversionFunnel({
    required String name,
    required List<String> steps,
    required RevenuePeriod period,
  }) async {
    try {
      final ConversionFunnel funnel = ConversionFunnel(
        id: _uuid.v4(),
        name: name,
        steps: steps,
        conversionRates: {},
        totalUsers: 0,
        convertedUsers: 0,
        period: period,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('conversion_funnels').doc(funnel.id).set(funnel.toMap());

      debugPrint('INFO: [RevenueAnalyticsService] Conversion funnel created: ${funnel.id}');
      return funnel.id;
    } catch (e) {
      debugPrint('ERROR: [RevenueAnalyticsService] Failed to create conversion funnel: $e');
      rethrow;
    }
  }

  /// РЎРѕР·РґР°РЅРёРµ РїСЂРѕРіРЅРѕР·Р° РґРѕС…РѕРґРѕРІ
  Future<String> createRevenueForecast({
    required RevenuePeriod period,
    required DateTime forecastDate,
    required double predictedRevenue,
    required double confidenceLevel,
    required Map<String, dynamic> factors,
  }) async {
    try {
      final RevenueForecast forecast = RevenueForecast(
        id: _uuid.v4(),
        period: period,
        forecastDate: forecastDate,
        predictedRevenue: predictedRevenue,
        confidenceLevel: confidenceLevel,
        factors: factors,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('revenue_forecasts').doc(forecast.id).set(forecast.toMap());

      debugPrint('INFO: [RevenueAnalyticsService] Revenue forecast created: ${forecast.id}');
      return forecast.id;
    } catch (e) {
      debugPrint('ERROR: [RevenueAnalyticsService] Failed to create revenue forecast: $e');
      rethrow;
    }
  }
}

