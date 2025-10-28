import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/dynamic_pricing.dart';
import 'package:uuid/uuid.dart';

class DynamicPricingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Получение актуальной цены для услуги
  Future<double> getCurrentPrice({
    required ServiceType serviceType,
    required String region,
    required String userTier,
    Map<String, dynamic>? additionalFactors,
  }) async {
    try {
      // Получаем правила ценообразования
      final rule = await _getPricingRule(serviceType);
      if (rule == null) {
        debugPrint(
            'WARNING: [DynamicPricingService] No pricing rule found for $serviceType',);
        return 0.0;
      }

      // Получаем метрики спроса
      final demandMetrics =
          await _getDemandMetrics(serviceType, region);

      // Получаем региональные настройки
      final regionalPricing =
          await _getRegionalPricing(region);

      // Рассчитываем факторы
      final factors = await _calculateFactors(
        serviceType: serviceType,
        region: region,
        userTier: userTier,
        demandMetrics: demandMetrics,
        regionalPricing: regionalPricing,
        additionalFactors: additionalFactors,
      );

      // Создаем обновленное правило с актуальными факторами
      final updatedRule = rule.copyWith(
        demandFactor: factors['demandFactor'] ?? rule.demandFactor,
        timeFactor: factors['timeFactor'] ?? rule.timeFactor,
        regionFactor: factors['regionFactor'] ?? rule.regionFactor,
        seasonFactor: factors['seasonFactor'] ?? rule.seasonFactor,
        userTierFactor: factors['userTierFactor'] ?? rule.userTierFactor,
        competitionFactor:
            factors['competitionFactor'] ?? rule.competitionFactor,
      );

      // Рассчитываем финальную цену
      final finalPrice = updatedRule.calculateFinalPrice(
        region: region,
        userTier: userTier,
        additionalFactors: factors,
      );

      // Сохраняем историю ценообразования
      await _savePricingHistory(
        serviceType: serviceType,
        region: region,
        basePrice: rule.basePrice,
        finalPrice: finalPrice,
        factors: factors,
        userId: additionalFactors?['userId'],
      );

      debugPrint(
        'INFO: [DynamicPricingService] Price calculated: $finalPrice for $serviceType in $region',
      );
      return finalPrice;
    } catch (e) {
      debugPrint(
          'ERROR: [DynamicPricingService] Failed to get current price: $e',);
      return 0.0;
    }
  }

  /// Получение правила ценообразования
  Future<PricingRule?> _getPricingRule(ServiceType serviceType) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('pricing_rules')
          .where('serviceType',
              isEqualTo: serviceType.toString().split('.').last,)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return PricingRule.fromMap(
            snapshot.docs.first.data()! as Map<String, dynamic>,);
      }
      return null;
    } catch (e) {
      debugPrint(
          'ERROR: [DynamicPricingService] Failed to get pricing rule: $e',);
      return null;
    }
  }

  /// Получение метрик спроса
  Future<DemandMetrics?> _getDemandMetrics(
      ServiceType serviceType, String region,) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('demand_metrics')
          .where('serviceType',
              isEqualTo: serviceType.toString().split('.').last,)
          .where('region', isEqualTo: region)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return DemandMetrics.fromMap(
            snapshot.docs.first.data()! as Map<String, dynamic>,);
      }
      return null;
    } catch (e) {
      debugPrint(
          'ERROR: [DynamicPricingService] Failed to get demand metrics: $e',);
      return null;
    }
  }

  /// Получение региональных настроек
  Future<RegionalPricing?> _getRegionalPricing(String region) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('regional_pricing')
          .where('region', isEqualTo: region)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return RegionalPricing.fromMap(
            snapshot.docs.first.data()! as Map<String, dynamic>,);
      }
      return null;
    } catch (e) {
      debugPrint(
          'ERROR: [DynamicPricingService] Failed to get regional pricing: $e',);
      return null;
    }
  }

  /// Расчет факторов ценообразования
  Future<Map<String, dynamic>> _calculateFactors({
    required ServiceType serviceType,
    required String region,
    required String userTier,
    DemandMetrics? demandMetrics,
    RegionalPricing? regionalPricing,
    Map<String, dynamic>? additionalFactors,
  }) async {
    final factors = <String, dynamic>{};

    // Фактор спроса
    if (demandMetrics != null) {
      factors['demandFactor'] = demandMetrics.calculatedDemandLevel;
    } else {
      factors['demandFactor'] = 1.0; // Средний спрос по умолчанию
    }

    // Временной фактор
    factors['timeFactor'] = _calculateTimeFactor();

    // Региональный фактор
    if (regionalPricing != null) {
      factors['regionFactor'] = regionalPricing.economicFactor;
    } else {
      factors['regionFactor'] = 1.0; // Базовый регион
    }

    // Сезонный фактор
    factors['seasonFactor'] = _calculateSeasonFactor();

    // Фактор пользователя
    factors['userTierFactor'] = _calculateUserTierFactor(userTier);

    // Фактор конкуренции
    factors['competitionFactor'] =
        _calculateCompetitionFactor(serviceType, region);

    // Дополнительные факторы
    if (additionalFactors != null) {
      factors.addAll(additionalFactors);
    }

    return factors;
  }

  /// Расчет временного фактора
  double _calculateTimeFactor() {
    final now = DateTime.now();
    final hour = now.hour;
    final dayOfWeek = now.weekday;

    // Пиковые часы (18:00-22:00) - +20%
    if (hour >= 18 && hour <= 22) {
      return 1.2;
    }

    // Выходные дни - +15%
    if (dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday) {
      return 1.15;
    }

    // Ночные часы (00:00-06:00) - -10%
    if (hour >= 0 && hour <= 6) {
      return 0.9;
    }

    return 1; // Стандартное время
  }

  /// Расчет сезонного фактора
  double _calculateSeasonFactor() {
    final now = DateTime.now();
    final month = now.month;

    // Летние месяцы (июнь-август) - +25%
    if (month >= 6 && month <= 8) {
      return 1.25;
    }

    // Зимние праздники (декабрь-январь) - +30%
    if (month == 12 || month == 1) {
      return 1.3;
    }

    // Весенние месяцы (март-май) - +10%
    if (month >= 3 && month <= 5) {
      return 1.1;
    }

    return 1; // Осень
  }

  /// Расчет фактора пользователя
  double _calculateUserTierFactor(String userTier) {
    switch (userTier.toLowerCase()) {
      case 'free':
        return 1; // Базовая цена
      case 'premium':
        return 0.9; // Скидка 10% для премиум
      case 'pro':
        return 0.8; // Скидка 20% для PRO
      default:
        return 1;
    }
  }

  /// Расчет фактора конкуренции
  double _calculateCompetitionFactor(ServiceType serviceType, String region) {
    // Упрощенная логика - в реальном приложении нужно анализировать конкурентов
    switch (serviceType) {
      case ServiceType.subscription:
        return 1; // Стабильная конкуренция
      case ServiceType.promotion:
        return 1.1; // Высокая конкуренция
      case ServiceType.advertisement:
        return 0.9; // Низкая конкуренция
      case ServiceType.premiumFeature:
        return 1;
    }
  }

  /// Сохранение истории ценообразования
  Future<void> _savePricingHistory({
    required ServiceType serviceType,
    required String region,
    required double basePrice,
    required double finalPrice,
    required Map<String, dynamic> factors,
    String? userId,
  }) async {
    try {
      final history = PricingHistory(
        id: _uuid.v4(),
        serviceType: serviceType,
        region: region,
        basePrice: basePrice,
        finalPrice: finalPrice,
        factors: factors,
        timestamp: DateTime.now(),
        userId: userId,
      );

      await _firestore
          .collection('pricing_history')
          .doc(history.id)
          .set(history.toMap());
    } catch (e) {
      debugPrint(
          'ERROR: [DynamicPricingService] Failed to save pricing history: $e',);
    }
  }

  /// Обновление метрик спроса
  Future<void> updateDemandMetrics({
    required ServiceType serviceType,
    required String region,
    required int activeUsers,
    required int requestsCount,
    required int availableSlots,
  }) async {
    try {
      final metrics = DemandMetrics(
        id: _uuid.v4(),
        region: region,
        serviceType: serviceType,
        activeUsers: activeUsers,
        requestsCount: requestsCount,
        availableSlots: availableSlots,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('demand_metrics')
          .doc(metrics.id)
          .set(metrics.toMap());

      debugPrint(
        'INFO: [DynamicPricingService] Demand metrics updated for $serviceType in $region',
      );
    } catch (e) {
      debugPrint(
          'ERROR: [DynamicPricingService] Failed to update demand metrics: $e',);
    }
  }

  /// Создание правила ценообразования
  Future<void> createPricingRule(PricingRule rule) async {
    try {
      await _firestore
          .collection('pricing_rules')
          .doc(rule.id)
          .set(rule.toMap());

      debugPrint(
          'INFO: [DynamicPricingService] Pricing rule created: ${rule.id}',);
    } catch (e) {
      debugPrint(
          'ERROR: [DynamicPricingService] Failed to create pricing rule: $e',);
      rethrow;
    }
  }

  /// Получение истории ценообразования
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
          .where('serviceType',
              isEqualTo: serviceType.toString().split('.').last,)
          .where('region', isEqualTo: region)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),);
      }
      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) =>
              PricingHistory.fromMap(doc.data()! as Map<String, dynamic>),)
          .toList();
    } catch (e) {
      debugPrint(
          'ERROR: [DynamicPricingService] Failed to get pricing history: $e',);
      return [];
    }
  }

  /// Получение статистики ценообразования
  Future<Map<String, dynamic>> getPricingStats({
    required ServiceType serviceType,
    required String region,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final history = await getPricingHistory(
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

      final prices = history.map((h) => h.finalPrice).toList();
      final averagePrice =
          prices.reduce((a, b) => a + b) / prices.length;
      final minPrice = prices.reduce((a, b) => a < b ? a : b);
      final maxPrice = prices.reduce((a, b) => a > b ? a : b);

      // Расчет волатильности (стандартное отклонение)
      final variance = prices
              .map((price) => (price - averagePrice) * (price - averagePrice))
              .reduce((a, b) => a + b) /
          prices.length;
      final priceVolatility = variance > 0 ? variance : 0.0;

      return {
        'averagePrice': averagePrice,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'priceVolatility': priceVolatility,
        'totalTransactions': history.length,
        'priceChangePercent':
            history.isNotEmpty ? history.first.priceChangePercent : 0.0,
      };
    } catch (e) {
      debugPrint(
          'ERROR: [DynamicPricingService] Failed to get pricing stats: $e',);
      return {};
    }
  }
}
