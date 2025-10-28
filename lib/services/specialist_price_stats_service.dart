import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:event_marketplace_app/models/booking.dart';
import 'package:event_marketplace_app/models/specialist_price_stats.dart';

/// Сервис для работы со статистикой цен специалистов
class SpecialistPriceStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Обновить статистику цен для специалиста
  Future<void> updateSpecialistPriceStats(String specialistId) async {
    try {
      // Получаем все завершенные бронирования специалиста
      final completedBookings = await _getCompletedBookings(specialistId);

      if (completedBookings.isEmpty) return;

      // Группируем по категориям
      final categoryGroups = <String, List<Booking>>{};
      for (final booking in completedBookings) {
        final categoryId = booking.categoryId;
        if (categoryId != null) {
          categoryGroups.putIfAbsent(categoryId, () => []).add(booking);
        }
      }

      // Вычисляем статистику для каждой категории
      for (final entry in categoryGroups.entries) {
        final categoryId = entry.key;
        final bookings = entry.value;

        await _updateCategoryStats(specialistId, categoryId, bookings);
      }

      // Обновляем общую статистику
      await _updateOverallStats(specialistId, categoryGroups);
    } catch (e) {
      throw Exception('Ошибка обновления статистики цен: $e');
    }
  }

  /// Получить статистику цен специалиста
  Future<SpecialistPriceAggregate?> getSpecialistPriceStats(
      String specialistId,) async {
    try {
      final snapshot = await _firestore
          .collection('specialistPriceStats')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final categoryStats = <String, SpecialistPriceStats>{};
      double totalRevenue = 0;
      var totalBookings = 0;
      var lastUpdated = DateTime.now();

      for (final doc in snapshot.docs) {
        final stats = SpecialistPriceStats.fromDocument(doc);
        categoryStats[stats.categoryId] = stats;
        totalRevenue += stats.totalRevenue;
        totalBookings += stats.completedBookings;

        if (stats.lastUpdated.isAfter(lastUpdated)) {
          lastUpdated = stats.lastUpdated;
        }
      }

      final overallAveragePrice =
          totalBookings > 0 ? totalRevenue / totalBookings : 0;

      return SpecialistPriceAggregate(
        specialistId: specialistId,
        categoryStats: categoryStats,
        overallAveragePrice: overallAveragePrice,
        totalCompletedBookings: totalBookings,
        totalRevenue: totalRevenue,
        lastUpdated: lastUpdated,
      );
    } catch (e) {
      throw Exception('Ошибка получения статистики цен: $e');
    }
  }

  /// Получить статистику по категории
  Future<SpecialistPriceStats?> getCategoryStats(
      String specialistId, String categoryId,) async {
    try {
      final snapshot = await _firestore
          .collection('specialistPriceStats')
          .where('specialistId', isEqualTo: specialistId)
          .where('categoryId', isEqualTo: categoryId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return SpecialistPriceStats.fromDocument(snapshot.docs.first);
    } catch (e) {
      throw Exception('Ошибка получения статистики по категории: $e');
    }
  }

  /// Получить топ специалистов по средней цене в категории
  Future<List<SpecialistPriceStats>> getTopSpecialistsByPrice(
    String categoryId, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('specialistPriceStats')
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('averagePrice', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(SpecialistPriceStats.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения топ специалистов: $e');
    }
  }

  /// Получить статистику по всем категориям
  Future<Map<String, Map<String, dynamic>>> getCategoryPriceStats() async {
    try {
      final snapshot =
          await _firestore.collection('specialistPriceStats').get();

      final categoryStats = <String, Map<String, dynamic>>{};

      for (final doc in snapshot.docs) {
        final stats = SpecialistPriceStats.fromDocument(doc);
        final categoryId = stats.categoryId;

        if (!categoryStats.containsKey(categoryId)) {
          categoryStats[categoryId] = {
            'categoryName': stats.categoryName,
            'minPrice': double.infinity,
            'maxPrice': 0.0,
            'totalRevenue': 0.0,
            'totalBookings': 0,
            'specialistCount': 0,
          };
        }

        final current = categoryStats[categoryId]!;
        current['minPrice'] = (current['minPrice'] as double) < stats.minPrice
            ? current['minPrice']
            : stats.minPrice;
        current['maxPrice'] = (current['maxPrice'] as double) > stats.maxPrice
            ? current['maxPrice']
            : stats.maxPrice;
        current['totalRevenue'] =
            (current['totalRevenue'] as double) + stats.totalRevenue;
        current['totalBookings'] =
            (current['totalBookings'] as int) + stats.completedBookings;
        current['specialistCount'] = (current['specialistCount'] as int) + 1;
      }

      // Вычисляем средние значения
      for (final entry in categoryStats.entries) {
        final stats = entry.value;
        final totalBookings = stats['totalBookings'] as int;
        stats['averagePrice'] = totalBookings > 0
            ? (stats['totalRevenue'] as double) / totalBookings
            : 0.0;
      }

      return categoryStats;
    } catch (e) {
      throw Exception('Ошибка получения статистики по категориям: $e');
    }
  }

  /// Получить завершенные бронирования специалиста
  Future<List<Booking>> _getCompletedBookings(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: BookingStatus.completed.name)
          .get();

      return snapshot.docs.map(Booking.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения завершенных бронирований: $e');
    }
  }

  /// Обновить статистику по категории
  Future<void> _updateCategoryStats(
    String specialistId,
    String categoryId,
    List<Booking> bookings,
  ) async {
    try {
      if (bookings.isEmpty) return;

      // Получаем название категории
      final categoryDoc =
          await _firestore.collection('categories').doc(categoryId).get();
      final categoryName =
          categoryDoc.data()?['name'] ?? 'Неизвестная категория';

      // Вычисляем статистику
      final prices = bookings
          .map((b) => b.totalPrice)
          .where((p) => p != null)
          .cast<double>()
          .toList();

      if (prices.isEmpty) return;

      final minPrice = prices.reduce((a, b) => a < b ? a : b);
      final maxPrice = prices.reduce((a, b) => a > b ? a : b);
      final averagePrice = prices.reduce((a, b) => a + b) / prices.length;
      final totalRevenue = prices.reduce((a, b) => a + b);

      final stats = SpecialistPriceStats(
        specialistId: specialistId,
        categoryId: categoryId,
        categoryName: categoryName,
        minPrice: minPrice,
        maxPrice: maxPrice,
        averagePrice: averagePrice,
        completedBookings: bookings.length,
        totalRevenue: totalRevenue,
        lastUpdated: DateTime.now(),
        additionalStats: {
          'priceDistribution': _calculatePriceDistribution(prices),
          'monthlyTrend':
              await _calculateMonthlyTrend(specialistId, categoryId),
        },
      );

      // Сохраняем или обновляем статистику
      final docRef = _firestore
          .collection('specialistPriceStats')
          .doc('${specialistId}_$categoryId');

      await docRef.set(stats.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Ошибка обновления статистики категории: $e');
    }
  }

  /// Обновить общую статистику
  Future<void> _updateOverallStats(
    String specialistId,
    Map<String, List<Booking>> categoryGroups,
  ) async {
    try {
      double totalRevenue = 0;
      var totalBookings = 0;
      final allPrices = <double>[];

      for (final bookings in categoryGroups.values) {
        totalBookings += bookings.length;
        for (final booking in bookings) {
          totalRevenue += booking.totalPrice;
          allPrices.add(booking.totalPrice);
        }
      }

      if (allPrices.isEmpty) return;

      final overallStats = {
        'specialistId': specialistId,
        'categoryId': 'overall',
        'categoryName': 'Общая статистика',
        'minPrice': allPrices.reduce((a, b) => a < b ? a : b),
        'maxPrice': allPrices.reduce((a, b) => a > b ? a : b),
        'averagePrice': totalRevenue / totalBookings,
        'completedBookings': totalBookings,
        'totalRevenue': totalRevenue,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
        'additionalStats': {
          'categoryCount': categoryGroups.length,
          'priceDistribution': _calculatePriceDistribution(allPrices),
        },
      };

      await _firestore
          .collection('specialistPriceStats')
          .doc('${specialistId}_overall')
          .set(overallStats, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Ошибка обновления общей статистики: $e');
    }
  }

  /// Вычислить распределение цен
  Map<String, int> _calculatePriceDistribution(List<double> prices) {
    final distribution = <String, int>{
      '0-5000': 0,
      '5000-10000': 0,
      '10000-25000': 0,
      '25000-50000': 0,
      '50000+': 0,
    };

    for (final price in prices) {
      if (price < 5000) {
        distribution['0-5000'] = distribution['0-5000']! + 1;
      } else if (price < 10000) {
        distribution['5000-10000'] = distribution['5000-10000']! + 1;
      } else if (price < 25000) {
        distribution['10000-25000'] = distribution['10000-25000']! + 1;
      } else if (price < 50000) {
        distribution['25000-50000'] = distribution['25000-50000']! + 1;
      } else {
        distribution['50000+'] = distribution['50000+']! + 1;
      }
    }

    return distribution;
  }

  /// Вычислить месячный тренд
  Future<Map<String, double>> _calculateMonthlyTrend(
      String specialistId, String categoryId,) async {
    try {
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);

      final snapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('categoryId', isEqualTo: categoryId)
          .where('status', isEqualTo: BookingStatus.completed.name)
          .where('completedAt', isGreaterThan: Timestamp.fromDate(sixMonthsAgo))
          .get();

      final monthlyRevenue = <String, double>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final completedAt = (data['completedAt'] as Timestamp).toDate();
        final monthKey =
            '${completedAt.year}-${completedAt.month.toString().padLeft(2, '0')}';
        final price = (data['totalPrice'] as num?)?.toDouble() ?? 0;

        monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0) + price;
      }

      return monthlyRevenue;
    } catch (e) {
      return {};
    }
  }

  /// Очистить старые данные статистики
  Future<void> cleanupOldStats({int daysToKeep = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final snapshot = await _firestore
          .collection('specialistPriceStats')
          .where('lastUpdated', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Ошибка очистки старых данных статистики: $e');
    }
  }
}
