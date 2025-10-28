import 'package:cloud_firestore/cloud_firestore.dart';

/// Статистика цен специалиста по категориям
class SpecialistPriceStats {
  const SpecialistPriceStats({
    required this.specialistId,
    required this.categoryId,
    required this.categoryName,
    required this.minPrice,
    required this.maxPrice,
    required this.averagePrice,
    required this.completedBookings,
    required this.totalRevenue,
    required this.lastUpdated,
    this.additionalStats,
  });

  /// Создать из документа Firestore
  factory SpecialistPriceStats.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SpecialistPriceStats(
      specialistId: data['specialistId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      minPrice: (data['minPrice'] as num).toDouble(),
      maxPrice: (data['maxPrice'] as num).toDouble(),
      averagePrice: (data['averagePrice'] as num).toDouble(),
      completedBookings: data['completedBookings'] as int? ?? 0,
      totalRevenue: (data['totalRevenue'] as num).toDouble(),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      additionalStats: data['additionalStats'] != null
          ? Map<String, dynamic>.from(data['additionalStats'])
          : null,
    );
  }

  /// Создать из Map
  factory SpecialistPriceStats.fromMap(Map<String, dynamic> data) =>
      SpecialistPriceStats(
        specialistId: data['specialistId'] ?? '',
        categoryId: data['categoryId'] ?? '',
        categoryName: data['categoryName'] ?? '',
        minPrice: (data['minPrice'] as num).toDouble(),
        maxPrice: (data['maxPrice'] as num).toDouble(),
        averagePrice: (data['averagePrice'] as num).toDouble(),
        completedBookings: data['completedBookings'] as int? ?? 0,
        totalRevenue: (data['totalRevenue'] as num).toDouble(),
        lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
        additionalStats: data['additionalStats'] != null
            ? Map<String, dynamic>.from(data['additionalStats'])
            : null,
      );
  final String specialistId;
  final String categoryId;
  final String categoryName;
  final double minPrice;
  final double maxPrice;
  final double averagePrice;
  final int completedBookings;
  final double totalRevenue;
  final DateTime lastUpdated;
  final Map<String, dynamic>? additionalStats;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'averagePrice': averagePrice,
        'completedBookings': completedBookings,
        'totalRevenue': totalRevenue,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
        'additionalStats': additionalStats,
      };

  /// Создать копию с изменениями
  SpecialistPriceStats copyWith({
    String? specialistId,
    String? categoryId,
    String? categoryName,
    double? minPrice,
    double? maxPrice,
    double? averagePrice,
    int? completedBookings,
    double? totalRevenue,
    DateTime? lastUpdated,
    Map<String, dynamic>? additionalStats,
  }) =>
      SpecialistPriceStats(
        specialistId: specialistId ?? this.specialistId,
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        averagePrice: averagePrice ?? this.averagePrice,
        completedBookings: completedBookings ?? this.completedBookings,
        totalRevenue: totalRevenue ?? this.totalRevenue,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        additionalStats: additionalStats ?? this.additionalStats,
      );

  /// Получить диапазон цен в читаемом виде
  String get priceRange {
    if (minPrice == maxPrice) {
      return '${minPrice.toStringAsFixed(0)} ₽';
    }
    return '${minPrice.toStringAsFixed(0)} - ${maxPrice.toStringAsFixed(0)} ₽';
  }

  /// Получить средний чек
  double get averageCheck =>
      completedBookings > 0 ? totalRevenue / completedBookings : 0;

  /// Получить коэффициент вариации цен
  double get priceVariation {
    if (minPrice == maxPrice) return 0;
    return ((maxPrice - minPrice) / averagePrice) * 100;
  }

  /// Проверить, актуальны ли данные
  bool get isUpToDate {
    final daysSinceUpdate = DateTime.now().difference(lastUpdated).inDays;
    return daysSinceUpdate <= 7; // Данные актуальны в течение недели
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpecialistPriceStats &&
        other.specialistId == specialistId &&
        other.categoryId == categoryId &&
        other.categoryName == categoryName &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        other.averagePrice == averagePrice &&
        other.completedBookings == completedBookings &&
        other.totalRevenue == totalRevenue &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode => Object.hash(
        specialistId,
        categoryId,
        categoryName,
        minPrice,
        maxPrice,
        averagePrice,
        completedBookings,
        totalRevenue,
        lastUpdated,
      );

  @override
  String toString() =>
      'SpecialistPriceStats(specialistId: $specialistId, categoryName: $categoryName, averagePrice: $averagePrice)';
}

/// Агрегированная статистика цен специалиста
class SpecialistPriceAggregate {
  const SpecialistPriceAggregate({
    required this.specialistId,
    required this.categoryStats,
    required this.overallAveragePrice,
    required this.totalCompletedBookings,
    required this.totalRevenue,
    required this.lastUpdated,
  });
  final String specialistId;
  final Map<String, SpecialistPriceStats> categoryStats;
  final double overallAveragePrice;
  final int totalCompletedBookings;
  final double totalRevenue;
  final DateTime lastUpdated;

  /// Получить статистику по категории
  SpecialistPriceStats? getCategoryStats(String categoryId) =>
      categoryStats[categoryId];

  /// Получить все категории
  List<String> get categories => categoryStats.keys.toList();

  /// Получить средний чек по всем категориям
  double get overallAverageCheck =>
      totalCompletedBookings > 0 ? totalRevenue / totalCompletedBookings : 0;

  /// Получить самую популярную категорию
  String? get mostPopularCategory {
    if (categoryStats.isEmpty) return null;

    return categoryStats.entries
        .reduce((a, b) =>
            a.value.completedBookings > b.value.completedBookings ? a : b,)
        .key;
  }

  /// Получить категорию с самой высокой средней ценой
  String? get highestPricedCategory {
    if (categoryStats.isEmpty) return null;

    return categoryStats.entries
        .reduce((a, b) => a.value.averagePrice > b.value.averagePrice ? a : b)
        .key;
  }

  /// Получить категорию с самой низкой средней ценой
  String? get lowestPricedCategory {
    if (categoryStats.isEmpty) return null;

    return categoryStats.entries
        .reduce((a, b) => a.value.averagePrice < b.value.averagePrice ? a : b)
        .key;
  }

  @override
  String toString() =>
      'SpecialistPriceAggregate(specialistId: $specialistId, categories: ${categories.length}, overallAveragePrice: $overallAveragePrice)';
}
