import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking.dart';
import '../models/specialist.dart';

/// Сервис для работы с ценами специалистов
class SpecialistPricingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить средний прайс специалиста на основе завершенных заказов
  Future<double> getAveragePriceForSpecialist(String specialistId) async {
    try {
      // Получаем все завершенные заказы специалиста
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: 'completed')
          .orderBy('eventDate', descending: true)
          .limit(50) // Берем последние 50 заказов для расчета
          .get();

      if (bookingsSnapshot.docs.isEmpty) {
        return 0.0;
      }

      final bookings = bookingsSnapshot.docs.map(Booking.fromDocument).toList();

      // Рассчитываем среднюю цену
      final totalPrice =
          bookings.fold<double>(0, (sum, booking) => sum + booking.totalPrice);
      final averagePrice = totalPrice / bookings.length;

      return averagePrice;
    } on Exception catch (e) {
      debugPrint('Ошибка получения среднего прайса специалиста: $e');
      return 0.0;
    }
  }

  /// Получить средний прайс по категории специалистов
  Future<double> getAveragePriceForCategory(SpecialistCategory category) async {
    try {
      // Получаем всех специалистов категории
      final specialistsSnapshot = await _firestore
          .collection('specialists')
          .where('category', isEqualTo: category.name)
          .where('isAvailable', isEqualTo: true)
          .limit(20)
          .get();

      if (specialistsSnapshot.docs.isEmpty) {
        return 0.0;
      }

      final specialists =
          specialistsSnapshot.docs.map(Specialist.fromDocument).toList();

      // Рассчитываем среднюю цену
      final totalPrice = specialists.fold<double>(
          0, (sum, specialist) => sum + specialist.price);
      final averagePrice = totalPrice / specialists.length;

      return averagePrice;
    } on Exception catch (e) {
      debugPrint('Ошибка получения среднего прайса по категории: $e');
      return 0.0;
    }
  }

  /// Получить статистику цен специалиста
  Future<SpecialistPricingStats> getSpecialistPricingStats(
      String specialistId) async {
    try {
      // Получаем все завершенные заказы специалиста
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: 'completed')
          .orderBy('eventDate', descending: true)
          .get();

      if (bookingsSnapshot.docs.isEmpty) {
        return SpecialistPricingStats.empty();
      }

      final bookings = bookingsSnapshot.docs.map(Booking.fromDocument).toList();

      final prices = bookings.map((booking) => booking.totalPrice).toList();
      prices.sort();

      final totalPrice = prices.fold<double>(0, (sum, price) => sum + price);
      final averagePrice = totalPrice / prices.length;
      final minPrice = prices.first;
      final maxPrice = prices.last;
      final medianPrice = _calculateMedian(prices);

      return SpecialistPricingStats(
        specialistId: specialistId,
        totalOrders: bookings.length,
        averagePrice: averagePrice,
        minPrice: minPrice,
        maxPrice: maxPrice,
        medianPrice: medianPrice,
        lastUpdated: DateTime.now(),
      );
    } on Exception catch (e) {
      debugPrint('Ошибка получения статистики цен специалиста: $e');
      return SpecialistPricingStats.empty();
    }
  }

  /// Обновить средний прайс специалиста в профиле
  Future<void> updateSpecialistAveragePrice(String specialistId) async {
    try {
      final averagePrice = await getAveragePriceForSpecialist(specialistId);

      if (averagePrice > 0) {
        await _firestore.collection('specialists').doc(specialistId).update({
          'avgPriceByService': averagePrice,
          'lastPriceUpdateAt': FieldValue.serverTimestamp(),
        });
      }
    } on Exception catch (e) {
      debugPrint('Ошибка обновления среднего прайса специалиста: $e');
    }
  }

  /// Получить историю цен специалиста
  Future<List<PriceHistoryEntry>> getSpecialistPriceHistory(
      String specialistId) async {
    try {
      // Получаем все завершенные заказы специалиста с датами
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: 'completed')
          .orderBy('eventDate', descending: true)
          .limit(100)
          .get();

      if (bookingsSnapshot.docs.isEmpty) {
        return [];
      }

      final bookings = bookingsSnapshot.docs.map(Booking.fromDocument).toList();

      // Группируем по месяцам для создания истории
      final monthlyPrices = <String, List<double>>{};

      for (final booking in bookings) {
        final monthKey =
            '${booking.eventDate.year}-${booking.eventDate.month.toString().padLeft(2, '0')}';
        monthlyPrices.putIfAbsent(monthKey, () => []).add(booking.totalPrice);
      }

      final history = <PriceHistoryEntry>[];

      for (final entry in monthlyPrices.entries) {
        final prices = entry.value;
        final averagePrice =
            prices.fold<double>(0, (sum, price) => sum + price) / prices.length;

        history.add(
          PriceHistoryEntry(
            month: entry.key,
            averagePrice: averagePrice,
            orderCount: prices.length,
          ),
        );
      }

      // Сортируем по дате
      history.sort((a, b) => b.month.compareTo(a.month));

      return history.take(12).toList(); // Последние 12 месяцев
    } on Exception catch (e) {
      debugPrint('Ошибка получения истории цен специалиста: $e');
      return [];
    }
  }

  // ========== ПРИВАТНЫЕ МЕТОДЫ ==========

  /// Рассчитать медиану
  double _calculateMedian(List<double> prices) {
    if (prices.isEmpty) return 0;

    final sortedPrices = List<double>.from(prices)..sort();
    final middle = sortedPrices.length ~/ 2;

    if (sortedPrices.length % 2 == 1) {
      return sortedPrices[middle];
    } else {
      return (sortedPrices[middle - 1] + sortedPrices[middle]) / 2;
    }
  }
}

/// Статистика цен специалиста
class SpecialistPricingStats {
  const SpecialistPricingStats({
    required this.specialistId,
    required this.totalOrders,
    required this.averagePrice,
    required this.minPrice,
    required this.maxPrice,
    required this.medianPrice,
    required this.lastUpdated,
  });

  factory SpecialistPricingStats.empty() => SpecialistPricingStats(
        specialistId: '',
        totalOrders: 0,
        averagePrice: 0,
        minPrice: 0,
        maxPrice: 0,
        medianPrice: 0,
        lastUpdated: DateTime.now(),
      );

  factory SpecialistPricingStats.fromMap(Map<String, dynamic> data) =>
      SpecialistPricingStats(
        specialistId: data['specialistId'] as String? ?? '',
        totalOrders: data['totalOrders'] as int? ?? 0,
        averagePrice: (data['averagePrice'] as num?)?.toDouble() ?? 0.0,
        minPrice: (data['minPrice'] as num?)?.toDouble() ?? 0.0,
        maxPrice: (data['maxPrice'] as num?)?.toDouble() ?? 0.0,
        medianPrice: (data['medianPrice'] as num?)?.toDouble() ?? 0.0,
        lastUpdated: data['lastUpdated'] != null
            ? (data['lastUpdated'] as Timestamp).toDate()
            : DateTime.now(),
      );

  final String specialistId;
  final int totalOrders;
  final double averagePrice;
  final double minPrice;
  final double maxPrice;
  final double medianPrice;
  final DateTime lastUpdated;

  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'totalOrders': totalOrders,
        'averagePrice': averagePrice,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'medianPrice': medianPrice,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
      };
}

/// Запись истории цен
class PriceHistoryEntry {
  const PriceHistoryEntry({
    required this.month,
    required this.averagePrice,
    required this.orderCount,
  });

  factory PriceHistoryEntry.fromMap(Map<String, dynamic> data) =>
      PriceHistoryEntry(
        month: data['month'] as String? ?? '',
        averagePrice: (data['averagePrice'] as num?)?.toDouble() ?? 0.0,
        orderCount: data['orderCount'] as int? ?? 0,
      );

  final String month;
  final double averagePrice;
  final int orderCount;

  Map<String, dynamic> toMap() => {
        'month': month,
        'averagePrice': averagePrice,
        'orderCount': orderCount,
      };
}
