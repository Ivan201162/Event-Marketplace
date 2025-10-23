import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/feature_flags.dart';

/// Сервис аналитики трендов
class TrendsAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить тренды по категориям мероприятий
  Future<List<CategoryTrend>> getCategoryTrends({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    if (!FeatureFlags.trendsAnalyticsEnabled) {
      throw Exception('Аналитика трендов отключена');
    }

    try {
      // Получаем события за период
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();

      final events = eventsSnapshot.docs.map((doc) => doc.data()).toList();

      // Анализируем категории
      final categoryCounts = <String, int>{};
      for (final event in events) {
        final category = event['category'] as String? ?? 'general';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      // Сортируем по популярности
      final sortedCategories = categoryCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedCategories
          .take(limit)
          .map(
            (entry) => CategoryTrend(
              category: entry.key,
              count: entry.value,
              percentage: (entry.value / events.length * 100).round(),
              growth: _calculateGrowth(entry.key, startDate, endDate),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения трендов по категориям: $e');
    }
  }

  /// Получить тренды по популярным услугам
  Future<List<ServiceTrend>> getServiceTrends({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    try {
      // Получаем бронирования за период
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('eventDate', isGreaterThanOrEqualTo: startDate)
          .where('eventDate', isLessThanOrEqualTo: endDate)
          .where('status', whereIn: ['confirmed', 'paid', 'completed']).get();

      final bookings = bookingsSnapshot.docs.map((doc) => doc.data()).toList();

      // Анализируем услуги
      final serviceCounts = <String, int>{};
      for (final booking in bookings) {
        final services = List<String>.from(booking['requiredServices'] ?? []);
        for (final service in services) {
          serviceCounts[service] = (serviceCounts[service] ?? 0) + 1;
        }
      }

      // Сортируем по популярности
      final sortedServices = serviceCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedServices
          .take(limit)
          .map(
            (entry) => ServiceTrend(
              service: entry.key,
              count: entry.value,
              percentage: (entry.value / bookings.length * 100).round(),
              growth: _calculateServiceGrowth(entry.key, startDate, endDate),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения трендов по услугам: $e');
    }
  }

  /// Получить тренды по сезонности
  Future<SeasonalityTrends> getSeasonalityTrends({required int year}) async {
    try {
      final startDate = DateTime(year);
      final endDate = DateTime(year, 12, 31);

      final eventsSnapshot = await _firestore
          .collection('events')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();

      final events = eventsSnapshot.docs.map((doc) => doc.data()).toList();

      // Группируем по месяцам
      final monthlyCounts = <int, int>{};
      for (final event in events) {
        final eventDate = (event['date'] as Timestamp).toDate();
        final month = eventDate.month;
        monthlyCounts[month] = (monthlyCounts[month] ?? 0) + 1;
      }

      // Группируем по дням недели
      final weeklyCounts = <int, int>{};
      for (final event in events) {
        final eventDate = (event['date'] as Timestamp).toDate();
        final weekday = eventDate.weekday;
        weeklyCounts[weekday] = (weeklyCounts[weekday] ?? 0) + 1;
      }

      return SeasonalityTrends(
        year: year,
        monthlyTrends: monthlyCounts,
        weeklyTrends: weeklyCounts,
        totalEvents: events.length,
        peakMonth: monthlyCounts.entries.isNotEmpty
            ? monthlyCounts.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key
            : null,
        peakWeekday: weeklyCounts.entries.isNotEmpty
            ? weeklyCounts.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key
            : null,
      );
    } catch (e) {
      throw Exception('Ошибка получения сезонных трендов: $e');
    }
  }

  /// Получить тренды по географии
  Future<List<GeographicTrend>> getGeographicTrends({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    try {
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();

      final events = eventsSnapshot.docs.map((doc) => doc.data()).toList();

      // Анализируем локации
      final locationCounts = <String, int>{};
      for (final event in events) {
        final location = event['location'] as String? ?? 'Не указано';
        locationCounts[location] = (locationCounts[location] ?? 0) + 1;
      }

      // Сортируем по популярности
      final sortedLocations = locationCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedLocations
          .take(limit)
          .map(
            (entry) => GeographicTrend(
              location: entry.key,
              count: entry.value,
              percentage: (entry.value / events.length * 100).round(),
              averagePrice:
                  _calculateAveragePrice(entry.key, startDate, endDate),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения географических трендов: $e');
    }
  }

  /// Получить тренды по ценам
  Future<PriceTrends> getPriceTrends({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('eventDate', isGreaterThanOrEqualTo: startDate)
          .where('eventDate', isLessThanOrEqualTo: endDate)
          .where('status', whereIn: ['confirmed', 'paid', 'completed']).get();

      final bookings = bookingsSnapshot.docs.map((doc) => doc.data()).toList();

      if (bookings.isEmpty) {
        return const PriceTrends(
          averagePrice: 0,
          medianPrice: 0,
          minPrice: 0,
          maxPrice: 0,
          priceRanges: {},
        );
      }

      final prices = bookings
          .map((booking) => (booking['totalPrice'] as num?)?.toDouble() ?? 0.0)
          .where((price) => price > 0)
          .toList();

      prices.sort();

      final averagePrice = prices.reduce((a, b) => a + b) / prices.length;
      final medianPrice = prices.length % 2 == 0
          ? (prices[prices.length ~/ 2 - 1] + prices[prices.length ~/ 2]) / 2
          : prices[prices.length ~/ 2];

      // Группируем по диапазонам цен
      final priceRanges = <String, int>{};
      for (final price in prices) {
        String range;
        if (price < 10000) {
          range = 'До 10,000 ₽';
        } else if (price < 50000) {
          range = '10,000 - 50,000 ₽';
        } else if (price < 100000) {
          range = '50,000 - 100,000 ₽';
        } else if (price < 500000) {
          range = '100,000 - 500,000 ₽';
        } else {
          range = 'Свыше 500,000 ₽';
        }
        priceRanges[range] = (priceRanges[range] ?? 0) + 1;
      }

      return PriceTrends(
        averagePrice: averagePrice,
        medianPrice: medianPrice,
        minPrice: prices.first,
        maxPrice: prices.last,
        priceRanges: priceRanges,
      );
    } catch (e) {
      throw Exception('Ошибка получения трендов по ценам: $e');
    }
  }

  /// Получить общую аналитику трендов
  Future<TrendsAnalytics> getTrendsAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final categoryTrends =
          await getCategoryTrends(startDate: startDate, endDate: endDate);
      final serviceTrends =
          await getServiceTrends(startDate: startDate, endDate: endDate);
      final geographicTrends =
          await getGeographicTrends(startDate: startDate, endDate: endDate);
      final priceTrends =
          await getPriceTrends(startDate: startDate, endDate: endDate);

      return TrendsAnalytics(
        period: AnalyticsPeriod(startDate: startDate, endDate: endDate),
        categoryTrends: categoryTrends,
        serviceTrends: serviceTrends,
        geographicTrends: geographicTrends,
        priceTrends: priceTrends,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Ошибка получения аналитики трендов: $e');
    }
  }

  // Приватные методы

  double _calculateGrowth(
      String category, DateTime startDate, DateTime endDate) {
    // TODO(developer): Реализовать расчет роста по сравнению с предыдущим периодом
    return 0;
  }

  double _calculateServiceGrowth(
      String service, DateTime startDate, DateTime endDate) {
    // TODO(developer): Реализовать расчет роста услуги по сравнению с предыдущим периодом
    return 0;
  }

  double _calculateAveragePrice(
      String location, DateTime startDate, DateTime endDate) {
    // TODO(developer): Реализовать расчет средней цены для локации
    return 0;
  }
}

/// Тренд по категории
class CategoryTrend {
  const CategoryTrend({
    required this.category,
    required this.count,
    required this.percentage,
    required this.growth,
  });
  final String category;
  final int count;
  final int percentage;
  final double growth;
}

/// Тренд по услуге
class ServiceTrend {
  const ServiceTrend({
    required this.service,
    required this.count,
    required this.percentage,
    required this.growth,
  });
  final String service;
  final int count;
  final int percentage;
  final double growth;
}

/// Географический тренд
class GeographicTrend {
  const GeographicTrend({
    required this.location,
    required this.count,
    required this.percentage,
    required this.averagePrice,
  });
  final String location;
  final int count;
  final int percentage;
  final double averagePrice;
}

/// Сезонные тренды
class SeasonalityTrends {
  const SeasonalityTrends({
    required this.year,
    required this.monthlyTrends,
    required this.weeklyTrends,
    required this.totalEvents,
    this.peakMonth,
    this.peakWeekday,
  });
  final int year;
  final Map<int, int> monthlyTrends;
  final Map<int, int> weeklyTrends;
  final int totalEvents;
  final int? peakMonth;
  final int? peakWeekday;
}

/// Тренды по ценам
class PriceTrends {
  const PriceTrends({
    required this.averagePrice,
    required this.medianPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.priceRanges,
  });
  final double averagePrice;
  final double medianPrice;
  final double minPrice;
  final double maxPrice;
  final Map<String, int> priceRanges;
}

/// Период аналитики
class AnalyticsPeriod {
  const AnalyticsPeriod({required this.startDate, required this.endDate});
  final DateTime startDate;
  final DateTime endDate;
}

/// Общая аналитика трендов
class TrendsAnalytics {
  const TrendsAnalytics({
    required this.period,
    required this.categoryTrends,
    required this.serviceTrends,
    required this.geographicTrends,
    required this.priceTrends,
    required this.generatedAt,
  });
  final AnalyticsPeriod period;
  final List<CategoryTrend> categoryTrends;
  final List<ServiceTrend> serviceTrends;
  final List<GeographicTrend> geographicTrends;
  final PriceTrends priceTrends;
  final DateTime generatedAt;
}
