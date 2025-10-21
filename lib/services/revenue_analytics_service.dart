import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/revenue_analytics.dart';

class RevenueAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Запись статистики дохода
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

      // Обновляем агрегированную статистику
      await _updateAggregatedStats(stats);

      debugPrint(
        'INFO: [RevenueAnalyticsService] Revenue recorded: $amount $currency from $sourceType',
      );
    } catch (e) {
      debugPrint('ERROR: [RevenueAnalyticsService] Failed to record revenue: $e');
    }
  }

  /// Обновление агрегированной статистики
  Future<void> _updateAggregatedStats(RevenueStats stats) async {
    try {
      final String dateKey = _getDateKey(stats.date);

      // Обновляем дневную статистику
      await _firestore.collection('revenue_aggregates').doc('daily_$dateKey').set({
        'date': dateKey,
        'totalRevenue': FieldValue.increment(stats.amount),
        'transactionCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Обновляем статистику по источникам
      await _firestore
          .collection('revenue_aggregates')
          .doc('source_${stats.sourceType.toString().split('.').last}')
          .set({
            'sourceType': stats.sourceType.toString().split('.').last,
            'totalRevenue': FieldValue.increment(stats.amount),
            'transactionCount': FieldValue.increment(1),
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Обновляем статистику по регионам
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

  /// Получение дашборда доходов
  Future<RevenueDashboard> getRevenueDashboard({
    required RevenuePeriod period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final DateTime now = DateTime.now();
      final DateTime periodStart = startDate ?? _getPeriodStart(now, period);
      final DateTime periodEnd = endDate ?? now;

      // Получаем статистику доходов за период
      final QuerySnapshot revenueSnapshot = await _firestore
          .collection('revenue_stats')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(periodEnd))
          .get();

      // Получаем статистику за предыдущий период для расчета роста
      final DateTime prevPeriodStart = _getPeriodStart(
        periodStart.subtract(const Duration(days: 1)),
        period,
      );
      final DateTime prevPeriodEnd = periodStart.subtract(const Duration(days: 1));

      final QuerySnapshot prevRevenueSnapshot = await _firestore
          .collection('revenue_stats')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(prevPeriodStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(prevPeriodEnd))
          .get();

      // Рассчитываем метрики
      final Map<String, double> revenueBySource = {};
      final Map<String, double> revenueByRegion = {};
      double totalRevenue = 0.0;
      int totalTransactions = 0;

      for (final doc in revenueSnapshot.docs) {
        final RevenueStats stats = RevenueStats.fromMap(doc.data() as Map<String, dynamic>);

        totalRevenue += stats.amount;
        totalTransactions++;

        // По источникам
        final String sourceKey = stats.sourceType.toString().split('.').last;
        revenueBySource[sourceKey] = (revenueBySource[sourceKey] ?? 0.0) + stats.amount;

        // По регионам
        revenueByRegion[stats.region] = (revenueByRegion[stats.region] ?? 0.0) + stats.amount;
      }

      // Рассчитываем рост
      double prevTotalRevenue = 0.0;
      for (final doc in prevRevenueSnapshot.docs) {
        final RevenueStats stats = RevenueStats.fromMap(doc.data() as Map<String, dynamic>);
        prevTotalRevenue += stats.amount;
      }

      final double growthRate = prevTotalRevenue > 0
          ? ((totalRevenue - prevTotalRevenue) / prevTotalRevenue) * 100
          : 0.0;

      // Рассчитываем средний чек
      final double averageOrderValue = totalTransactions > 0
          ? totalRevenue / totalTransactions
          : 0.0;

      // Получаем дневную статистику
      final List<Map<String, dynamic>> dailyRevenue = await _getDailyRevenue(
        periodStart,
        periodEnd,
      );

      // Получаем месячную статистику
      final List<Map<String, dynamic>> monthlyRevenue = await _getMonthlyRevenue(
        periodStart,
        periodEnd,
      );

      // Рассчитываем LTV и CAC
      final double ltv = await _calculateLTV();
      final double cac = await _calculateCAC();
      final double roi = cac > 0 ? (ltv / cac) * 100 : 0.0;

      // Рассчитываем конверсию
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

      // Сохраняем дашборд
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

  /// Получение дневной статистики доходов
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

  /// Получение месячной статистики доходов
  Future<List<Map<String, dynamic>>> _getMonthlyRevenue(
    DateTime startDate,
    DateTime endDate,
  ) async {
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

  /// Расчет LTV (Lifetime Value)
  Future<double> _calculateLTV() async {
    try {
      // Получаем всех пользователей с покупками
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

  /// Расчет CAC (Customer Acquisition Cost)
  Future<double> _calculateCAC() async {
    try {
      // Получаем статистику по рефералам и партнерским программам
      final QuerySnapshot referralsSnapshot = await _firestore.collection('referral_rewards').get();

      final QuerySnapshot partnershipsSnapshot = await _firestore
          .collection('partner_transactions')
          .get();

      double totalAcquisitionCost = 0.0;
      int totalAcquisitions = 0;

      // Стоимость рефералов
      for (final doc in referralsSnapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalAcquisitionCost += (data['value'] ?? 0.0).toDouble();
        totalAcquisitions++;
      }

      // Стоимость партнерских программ
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

  /// Расчет конверсии
  Future<double> _calculateConversionRate(DateTime startDate, DateTime endDate) async {
    try {
      // Получаем количество пользователей за период
      final QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Получаем количество пользователей с покупками
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

  /// Обновление LTV пользователя
  Future<void> updateUserLTV(String userId) async {
    try {
      // Получаем все транзакции пользователя
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

      // Рассчитываем частоту покупок (покупок в месяц)
      final int daysSinceFirst = DateTime.now().difference(firstPurchaseDate).inDays;
      final double purchaseFrequency = daysSinceFirst > 0
          ? (totalTransactions / daysSinceFirst) * 30
          : 0.0;

      // Рассчитываем retention rate (упрощенно)
      final double retentionRate = _calculateRetentionRate(userId);

      // Предсказываем LTV
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

  /// Расчет retention rate
  double _calculateRetentionRate(String userId) {
    // Упрощенный расчет - в реальном приложении нужна более сложная логика
    return 0.7; // 70% по умолчанию
  }

  /// Предсказание LTV
  double _predictLTV({
    required double totalSpent,
    required double purchaseFrequency,
    required double retentionRate,
    required int daysSinceFirst,
  }) {
    // Упрощенная модель предсказания LTV
    final double monthlyValue = (totalSpent / daysSinceFirst) * 30;
    final double predictedMonths = 12 * retentionRate; // Предсказываем на год с учетом retention
    return monthlyValue * predictedMonths;
  }

  /// Определение сегмента пользователя
  String _determineUserSegment(double totalSpent, double purchaseFrequency) {
    if (totalSpent >= 10000 && purchaseFrequency >= 2) return 'vip';
    if (totalSpent >= 5000 && purchaseFrequency >= 1) return 'premium';
    if (totalSpent >= 1000 && purchaseFrequency >= 0.5) return 'regular';
    if (totalSpent >= 100) return 'active';
    return 'new';
  }

  /// Получение начала периода
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

  /// Получение ключа даты
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Создание воронки конверсии
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

  /// Создание прогноза доходов
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
