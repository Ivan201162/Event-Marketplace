import 'package:cloud_firestore/cloud_firestore.dart';

enum ServiceType { subscription, promotion, advertisement, premiumFeature }

enum PricingFactor { demand, time, region, season, userTier, competition }

class PricingRule {
  PricingRule({
    required this.id,
    required this.serviceType,
    required this.basePrice,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.demandFactor = 1.0,
    this.timeFactor = 1.0,
    this.regionFactor = 1.0,
    this.seasonFactor = 1.0,
    this.userTierFactor = 1.0,
    this.competitionFactor = 1.0,
    this.minPrice,
    this.maxPrice,
    this.description,
    this.conditions,
  });

  factory PricingRule.fromMap(Map<String, dynamic> map) => PricingRule(
        id: map['id'] ?? '',
        serviceType: ServiceType.values.firstWhere(
          (e) => e.toString() == 'ServiceType.${map['serviceType']}',
          orElse: () => ServiceType.subscription,
        ),
        basePrice: (map['basePrice'] ?? 0.0).toDouble(),
        isActive: map['isActive'] ?? true,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        demandFactor: (map['demandFactor'] ?? 1.0).toDouble(),
        timeFactor: (map['timeFactor'] ?? 1.0).toDouble(),
        regionFactor: (map['regionFactor'] ?? 1.0).toDouble(),
        seasonFactor: (map['seasonFactor'] ?? 1.0).toDouble(),
        userTierFactor: (map['userTierFactor'] ?? 1.0).toDouble(),
        competitionFactor: (map['competitionFactor'] ?? 1.0).toDouble(),
        minPrice: map['minPrice']?.toDouble(),
        maxPrice: map['maxPrice']?.toDouble(),
        description: map['description'],
        conditions: Map<String, dynamic>.from(map['conditions'] ?? {}),
      );

  final String id;
  final ServiceType serviceType;
  final double basePrice;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double demandFactor;
  final double timeFactor;
  final double regionFactor;
  final double seasonFactor;
  final double userTierFactor;
  final double competitionFactor;
  final double? minPrice;
  final double? maxPrice;
  final String? description;
  final Map<String, dynamic>? conditions;

  /// Расчет финальной цены
  double calculateFinalPrice({
    required String region,
    required String userTier,
    Map<String, dynamic>? additionalFactors,
  }) {
    double finalPrice = basePrice;

    // Применяем факторы
    finalPrice *= demandFactor;
    finalPrice *= timeFactor;
    finalPrice *= regionFactor;
    finalPrice *= seasonFactor;
    finalPrice *= userTierFactor;
    finalPrice *= competitionFactor;

    // Применяем дополнительные факторы
    if (additionalFactors != null) {
      for (final factor in additionalFactors.entries) {
        if (factor.value is double) {
          finalPrice *= factor.value as double;
        }
      }
    }

    // Применяем ограничения
    if (minPrice != null && finalPrice < minPrice!) {
      finalPrice = minPrice!;
    }
    if (maxPrice != null && finalPrice > maxPrice!) {
      finalPrice = maxPrice!;
    }

    return finalPrice;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'serviceType': serviceType.toString().split('.').last,
        'basePrice': basePrice,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'demandFactor': demandFactor,
        'timeFactor': timeFactor,
        'regionFactor': regionFactor,
        'seasonFactor': seasonFactor,
        'userTierFactor': userTierFactor,
        'competitionFactor': competitionFactor,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'description': description,
        'conditions': conditions,
      };

  PricingRule copyWith({
    String? id,
    ServiceType? serviceType,
    double? basePrice,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? demandFactor,
    double? timeFactor,
    double? regionFactor,
    double? seasonFactor,
    double? userTierFactor,
    double? competitionFactor,
    double? minPrice,
    double? maxPrice,
    String? description,
    Map<String, dynamic>? conditions,
  }) =>
      PricingRule(
        id: id ?? this.id,
        serviceType: serviceType ?? this.serviceType,
        basePrice: basePrice ?? this.basePrice,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        demandFactor: demandFactor ?? this.demandFactor,
        timeFactor: timeFactor ?? this.timeFactor,
        regionFactor: regionFactor ?? this.regionFactor,
        seasonFactor: seasonFactor ?? this.seasonFactor,
        userTierFactor: userTierFactor ?? this.userTierFactor,
        competitionFactor: competitionFactor ?? this.competitionFactor,
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        description: description ?? this.description,
        conditions: conditions ?? this.conditions,
      );
}

class DemandMetrics {
  DemandMetrics({
    required this.id,
    required this.region,
    required this.serviceType,
    required this.activeUsers,
    required this.requestsCount,
    required this.availableSlots,
    required this.timestamp,
    this.demandLevel = 1.0,
    this.competitionLevel = 1.0,
  });

  factory DemandMetrics.fromMap(Map<String, dynamic> map) => DemandMetrics(
        id: map['id'] ?? '',
        region: map['region'] ?? '',
        serviceType: ServiceType.values.firstWhere(
          (e) => e.toString() == 'ServiceType.${map['serviceType']}',
          orElse: () => ServiceType.subscription,
        ),
        activeUsers: map['activeUsers'] ?? 0,
        requestsCount: map['requestsCount'] ?? 0,
        availableSlots: map['availableSlots'] ?? 0,
        timestamp: (map['timestamp'] as Timestamp).toDate(),
        demandLevel: (map['demandLevel'] ?? 1.0).toDouble(),
        competitionLevel: (map['competitionLevel'] ?? 1.0).toDouble(),
      );

  final String id;
  final String region;
  final ServiceType serviceType;
  final int activeUsers;
  final int requestsCount;
  final int availableSlots;
  final DateTime timestamp;
  final double demandLevel;
  final double competitionLevel;

  /// Расчет уровня спроса (0.5 - низкий, 1.0 - средний, 2.0 - высокий)
  double get calculatedDemandLevel {
    if (availableSlots == 0) return 2.0; // Максимальный спрос

    final double utilizationRate = requestsCount / availableSlots;
    if (utilizationRate > 0.8) return 2.0;
    if (utilizationRate > 0.5) return 1.5;
    if (utilizationRate > 0.2) return 1.0;
    return 0.5;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'region': region,
        'serviceType': serviceType.toString().split('.').last,
        'activeUsers': activeUsers,
        'requestsCount': requestsCount,
        'availableSlots': availableSlots,
        'timestamp': Timestamp.fromDate(timestamp),
        'demandLevel': demandLevel,
        'competitionLevel': competitionLevel,
      };
}

class PricingHistory {
  PricingHistory({
    required this.id,
    required this.serviceType,
    required this.region,
    required this.basePrice,
    required this.finalPrice,
    required this.factors,
    required this.timestamp,
    this.userId,
    this.transactionId,
  });

  factory PricingHistory.fromMap(Map<String, dynamic> map) => PricingHistory(
        id: map['id'] ?? '',
        serviceType: ServiceType.values.firstWhere(
          (e) => e.toString() == 'ServiceType.${map['serviceType']}',
          orElse: () => ServiceType.subscription,
        ),
        region: map['region'] ?? '',
        basePrice: (map['basePrice'] ?? 0.0).toDouble(),
        finalPrice: (map['finalPrice'] ?? 0.0).toDouble(),
        factors: Map<String, dynamic>.from(map['factors'] ?? {}),
        timestamp: (map['timestamp'] as Timestamp).toDate(),
        userId: map['userId'],
        transactionId: map['transactionId'],
      );

  final String id;
  final ServiceType serviceType;
  final String region;
  final double basePrice;
  final double finalPrice;
  final Map<String, dynamic> factors;
  final DateTime timestamp;
  final String? userId;
  final String? transactionId;

  /// Процент изменения цены
  double get priceChangePercent {
    if (basePrice == 0) return 0.0;
    return ((finalPrice - basePrice) / basePrice) * 100;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'serviceType': serviceType.toString().split('.').last,
        'region': region,
        'basePrice': basePrice,
        'finalPrice': finalPrice,
        'factors': factors,
        'timestamp': Timestamp.fromDate(timestamp),
        'userId': userId,
        'transactionId': transactionId,
      };
}

class RegionalPricing {
  RegionalPricing({
    required this.id,
    required this.region,
    required this.country,
    required this.currency,
    required this.exchangeRate,
    required this.economicFactor,
    required this.isActive,
    required this.updatedAt,
  });

  factory RegionalPricing.fromMap(Map<String, dynamic> map) => RegionalPricing(
        id: map['id'] ?? '',
        region: map['region'] ?? '',
        country: map['country'] ?? '',
        currency: map['currency'] ?? 'RUB',
        exchangeRate: (map['exchangeRate'] ?? 1.0).toDouble(),
        economicFactor: (map['economicFactor'] ?? 1.0).toDouble(),
        isActive: map['isActive'] ?? true,
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      );

  final String id;
  final String region;
  final String country;
  final String currency;
  final double exchangeRate;
  final double economicFactor;
  final bool isActive;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'region': region,
        'country': country,
        'currency': currency,
        'exchangeRate': exchangeRate,
        'economicFactor': economicFactor,
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
