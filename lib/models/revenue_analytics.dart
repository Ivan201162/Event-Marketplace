import 'package:cloud_firestore/cloud_firestore.dart';

enum RevenueSource {
  subscription,
  promotion,
  advertisement,
  referral,
  partnership,
  premiumFeature,
  donation,
}

enum RevenuePeriod {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
}

class RevenueStats {
  RevenueStats({
    required this.id,
    required this.date,
    required this.period,
    required this.sourceType,
    required this.amount,
    required this.currency,
    required this.region,
    required this.createdAt,
    this.userId,
    this.transactionId,
    this.metadata,
  });

  factory RevenueStats.fromMap(Map<String, dynamic> map) => RevenueStats(
        id: map['id'] ?? '',
        date: (map['date'] as Timestamp).toDate(),
        period: RevenuePeriod.values.firstWhere(
          (e) => e.toString() == 'RevenuePeriod.${map['period']}',
          orElse: () => RevenuePeriod.daily,
        ),
        sourceType: RevenueSource.values.firstWhere(
          (e) => e.toString() == 'RevenueSource.${map['sourceType']}',
          orElse: () => RevenueSource.subscription,
        ),
        amount: (map['amount'] ?? 0.0).toDouble(),
        currency: map['currency'] ?? 'RUB',
        region: map['region'] ?? '',
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        userId: map['userId'],
        transactionId: map['transactionId'],
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      );

  final String id;
  final DateTime date;
  final RevenuePeriod period;
  final RevenueSource sourceType;
  final double amount;
  final String currency;
  final String region;
  final DateTime createdAt;
  final String? userId;
  final String? transactionId;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': Timestamp.fromDate(date),
        'period': period.toString().split('.').last,
        'sourceType': sourceType.toString().split('.').last,
        'amount': amount,
        'currency': currency,
        'region': region,
        'createdAt': Timestamp.fromDate(createdAt),
        'userId': userId,
        'transactionId': transactionId,
        'metadata': metadata,
      };
}

class RevenueDashboard {
  RevenueDashboard({
    required this.period,
    required this.totalRevenue,
    required this.revenueBySource,
    required this.revenueByRegion,
    required this.dailyRevenue,
    required this.monthlyRevenue,
    required this.growthRate,
    required this.averageOrderValue,
    required this.totalTransactions,
    required this.conversionRate,
    required this.ltv,
    required this.cac,
    required this.roi,
    required this.generatedAt,
    this.metadata,
  });

  factory RevenueDashboard.fromMap(Map<String, dynamic> map) =>
      RevenueDashboard(
        period: RevenuePeriod.values.firstWhere(
          (e) => e.toString() == 'RevenuePeriod.${map['period']}',
          orElse: () => RevenuePeriod.monthly,
        ),
        totalRevenue: (map['totalRevenue'] ?? 0.0).toDouble(),
        revenueBySource: Map<String, double>.from(map['revenueBySource'] ?? {}),
        revenueByRegion: Map<String, double>.from(map['revenueByRegion'] ?? {}),
        dailyRevenue:
            List<Map<String, dynamic>>.from(map['dailyRevenue'] ?? []),
        monthlyRevenue:
            List<Map<String, dynamic>>.from(map['monthlyRevenue'] ?? []),
        growthRate: (map['growthRate'] ?? 0.0).toDouble(),
        averageOrderValue: (map['averageOrderValue'] ?? 0.0).toDouble(),
        totalTransactions: map['totalTransactions'] ?? 0,
        conversionRate: (map['conversionRate'] ?? 0.0).toDouble(),
        ltv: (map['ltv'] ?? 0.0).toDouble(),
        cac: (map['cac'] ?? 0.0).toDouble(),
        roi: (map['roi'] ?? 0.0).toDouble(),
        generatedAt: (map['generatedAt'] as Timestamp).toDate(),
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      );

  final RevenuePeriod period;
  final double totalRevenue;
  final Map<String, double> revenueBySource;
  final Map<String, double> revenueByRegion;
  final List<Map<String, dynamic>> dailyRevenue;
  final List<Map<String, dynamic>> monthlyRevenue;
  final double growthRate;
  final double averageOrderValue;
  final int totalTransactions;
  final double conversionRate;
  final double ltv; // Lifetime Value
  final double cac; // Customer Acquisition Cost
  final double roi; // Return on Investment
  final DateTime generatedAt;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() => {
        'period': period.toString().split('.').last,
        'totalRevenue': totalRevenue,
        'revenueBySource': revenueBySource,
        'revenueByRegion': revenueByRegion,
        'dailyRevenue': dailyRevenue,
        'monthlyRevenue': monthlyRevenue,
        'growthRate': growthRate,
        'averageOrderValue': averageOrderValue,
        'totalTransactions': totalTransactions,
        'conversionRate': conversionRate,
        'ltv': ltv,
        'cac': cac,
        'roi': roi,
        'generatedAt': Timestamp.fromDate(generatedAt),
        'metadata': metadata,
      };
}

class UserLifetimeValue {
  UserLifetimeValue({
    required this.userId,
    required this.totalSpent,
    required this.totalTransactions,
    required this.firstPurchaseDate,
    required this.lastPurchaseDate,
    required this.averageOrderValue,
    required this.purchaseFrequency,
    required this.retentionRate,
    required this.predictedLtv,
    required this.segment,
    required this.updatedAt,
    this.metadata,
  });

  factory UserLifetimeValue.fromMap(Map<String, dynamic> map) =>
      UserLifetimeValue(
        userId: map['userId'] ?? '',
        totalSpent: (map['totalSpent'] ?? 0.0).toDouble(),
        totalTransactions: map['totalTransactions'] ?? 0,
        firstPurchaseDate: (map['firstPurchaseDate'] as Timestamp).toDate(),
        lastPurchaseDate: (map['lastPurchaseDate'] as Timestamp).toDate(),
        averageOrderValue: (map['averageOrderValue'] ?? 0.0).toDouble(),
        purchaseFrequency: (map['purchaseFrequency'] ?? 0.0).toDouble(),
        retentionRate: (map['retentionRate'] ?? 0.0).toDouble(),
        predictedLtv: (map['predictedLtv'] ?? 0.0).toDouble(),
        segment: map['segment'] ?? 'new',
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      );

  final String userId;
  final double totalSpent;
  final int totalTransactions;
  final DateTime firstPurchaseDate;
  final DateTime lastPurchaseDate;
  final double averageOrderValue;
  final double purchaseFrequency;
  final double retentionRate;
  final double predictedLtv;
  final String segment;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  /// Расчет дней с первой покупки
  int get daysSinceFirstPurchase =>
      DateTime.now().difference(firstPurchaseDate).inDays;

  /// Расчет дней с последней покупки
  int get daysSinceLastPurchase =>
      DateTime.now().difference(lastPurchaseDate).inDays;

  /// Определение сегмента пользователя
  String get calculatedSegment {
    if (totalSpent >= 10000) return 'vip';
    if (totalSpent >= 5000) return 'premium';
    if (totalSpent >= 1000) return 'regular';
    if (totalSpent >= 100) return 'active';
    return 'new';
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'totalSpent': totalSpent,
        'totalTransactions': totalTransactions,
        'firstPurchaseDate': Timestamp.fromDate(firstPurchaseDate),
        'lastPurchaseDate': Timestamp.fromDate(lastPurchaseDate),
        'averageOrderValue': averageOrderValue,
        'purchaseFrequency': purchaseFrequency,
        'retentionRate': retentionRate,
        'predictedLtv': predictedLtv,
        'segment': segment,
        'updatedAt': Timestamp.fromDate(updatedAt),
        'metadata': metadata,
      };
}

class ConversionFunnel {
  ConversionFunnel({
    required this.id,
    required this.name,
    required this.steps,
    required this.conversionRates,
    required this.totalUsers,
    required this.convertedUsers,
    required this.period,
    required this.createdAt,
    this.metadata,
  });

  factory ConversionFunnel.fromMap(Map<String, dynamic> map) =>
      ConversionFunnel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        steps: List<String>.from(map['steps'] ?? []),
        conversionRates: Map<String, double>.from(map['conversionRates'] ?? {}),
        totalUsers: map['totalUsers'] ?? 0,
        convertedUsers: map['convertedUsers'] ?? 0,
        period: RevenuePeriod.values.firstWhere(
          (e) => e.toString() == 'RevenuePeriod.${map['period']}',
          orElse: () => RevenuePeriod.monthly,
        ),
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      );

  final String id;
  final String name;
  final List<String> steps;
  final Map<String, double> conversionRates;
  final int totalUsers;
  final int convertedUsers;
  final RevenuePeriod period;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  /// Общий коэффициент конверсии
  double get overallConversionRate =>
      totalUsers > 0 ? (convertedUsers / totalUsers) * 100 : 0.0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'steps': steps,
        'conversionRates': conversionRates,
        'totalUsers': totalUsers,
        'convertedUsers': convertedUsers,
        'period': period.toString().split('.').last,
        'createdAt': Timestamp.fromDate(createdAt),
        'metadata': metadata,
      };
}

class RevenueForecast {
  RevenueForecast({
    required this.id,
    required this.period,
    required this.forecastDate,
    required this.predictedRevenue,
    required this.confidenceLevel,
    required this.factors,
    required this.createdAt,
    this.actualRevenue,
    this.accuracy,
  });

  factory RevenueForecast.fromMap(Map<String, dynamic> map) => RevenueForecast(
        id: map['id'] ?? '',
        period: RevenuePeriod.values.firstWhere(
          (e) => e.toString() == 'RevenuePeriod.${map['period']}',
          orElse: () => RevenuePeriod.monthly,
        ),
        forecastDate: (map['forecastDate'] as Timestamp).toDate(),
        predictedRevenue: (map['predictedRevenue'] ?? 0.0).toDouble(),
        confidenceLevel: (map['confidenceLevel'] ?? 0.0).toDouble(),
        factors: Map<String, dynamic>.from(map['factors'] ?? {}),
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        actualRevenue: map['actualRevenue']?.toDouble(),
        accuracy: map['accuracy']?.toDouble(),
      );

  final String id;
  final RevenuePeriod period;
  final DateTime forecastDate;
  final double predictedRevenue;
  final double confidenceLevel;
  final Map<String, dynamic> factors;
  final DateTime createdAt;
  final double? actualRevenue;
  final double? accuracy;

  /// Расчет точности прогноза
  double? get calculatedAccuracy {
    if (actualRevenue == null) return null;
    if (predictedRevenue == 0) return 0.0;

    final double error = (actualRevenue! - predictedRevenue).abs();
    return ((1 - (error / predictedRevenue)) * 100).clamp(0.0, 100.0);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'period': period.toString().split('.').last,
        'forecastDate': Timestamp.fromDate(forecastDate),
        'predictedRevenue': predictedRevenue,
        'confidenceLevel': confidenceLevel,
        'factors': factors,
        'createdAt': Timestamp.fromDate(createdAt),
        'actualRevenue': actualRevenue,
        'accuracy': accuracy,
      };
}
