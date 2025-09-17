import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/price_history.dart';

/// Сервис для работы с историей цен
class PriceHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Добавить запись в историю цен
  Future<void> addPriceChange({
    required String bookingId,
    required double oldPrice,
    required double newPrice,
    required String reason,
    required String changedBy,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final now = DateTime.now();
      final discountPercent =
          newPrice < oldPrice ? ((oldPrice - newPrice) / oldPrice) * 100 : null;

      final priceHistory = PriceHistory(
        id: '', // Будет сгенерирован Firestore
        bookingId: bookingId,
        oldPrice: oldPrice,
        newPrice: newPrice,
        discountPercent: discountPercent,
        reason: reason,
        changedBy: changedBy,
        changedAt: now,
        metadata: metadata,
      );

      await _firestore.collection('priceHistory').add(priceHistory.toMap());
    } catch (e) {
      throw Exception('Ошибка добавления записи в историю цен: $e');
    }
  }

  /// Получить историю цен для бронирования
  Future<List<PriceHistory>> getBookingPriceHistory(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('priceHistory')
          .where('bookingId', isEqualTo: bookingId)
          .orderBy('changedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PriceHistory.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения истории цен: $e');
    }
  }

  /// Получить историю цен для специалиста
  Future<List<PriceHistory>> getSpecialistPriceHistory(
      String specialistId) async {
    try {
      // Получаем все бронирования специалиста
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final bookingIds = bookingsSnapshot.docs.map((doc) => doc.id).toList();

      if (bookingIds.isEmpty) return [];

      // Получаем историю цен для всех бронирований
      final snapshot = await _firestore
          .collection('priceHistory')
          .where('bookingId', whereIn: bookingIds)
          .orderBy('changedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PriceHistory.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения истории цен специалиста: $e');
    }
  }

  /// Получить статистику изменений цен
  Future<Map<String, dynamic>> getPriceChangeStats(String specialistId) async {
    try {
      final priceHistory = await getSpecialistPriceHistory(specialistId);

      int totalChanges = priceHistory.length;
      int discountOffers = priceHistory.where((p) => p.isDiscount).length;
      int priceIncreases = priceHistory.where((p) => !p.isDiscount).length;

      double totalSavings = priceHistory
          .where((p) => p.isDiscount)
          .fold(0.0, (sum, p) => sum + p.savings);

      double averageDiscount = discountOffers > 0
          ? priceHistory
                  .where((p) => p.isDiscount)
                  .fold(0.0, (sum, p) => sum + (p.discountPercent ?? 0)) /
              discountOffers
          : 0;

      return {
        'totalChanges': totalChanges,
        'discountOffers': discountOffers,
        'priceIncreases': priceIncreases,
        'totalSavings': totalSavings,
        'averageDiscount': averageDiscount,
        'discountRate':
            totalChanges > 0 ? (discountOffers / totalChanges) * 100 : 0,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики изменений цен: $e');
    }
  }

  /// Получить последние изменения цен
  Future<List<PriceHistory>> getRecentPriceChanges({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('priceHistory')
          .orderBy('changedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PriceHistory.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения последних изменений цен: $e');
    }
  }

  /// Получить изменения цен за период
  Future<List<PriceHistory>> getPriceChangesInPeriod({
    required DateTime startDate,
    required DateTime endDate,
    String? specialistId,
  }) async {
    try {
      Query query = _firestore
          .collection('priceHistory')
          .where('changedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('changedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      if (specialistId != null) {
        // Получаем бронирования специалиста
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('specialistId', isEqualTo: specialistId)
            .get();

        final bookingIds = bookingsSnapshot.docs.map((doc) => doc.id).toList();

        if (bookingIds.isEmpty) return [];

        query = query.where('bookingId', whereIn: bookingIds);
      }

      final snapshot = await query.orderBy('changedAt', descending: true).get();

      return snapshot.docs
          .map((doc) => PriceHistory.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения изменений цен за период: $e');
    }
  }

  /// Удалить старые записи истории (для очистки)
  Future<void> cleanupOldPriceHistory({int daysToKeep = 365}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final snapshot = await _firestore
          .collection('priceHistory')
          .where('changedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Ошибка очистки старой истории цен: $e');
    }
  }
}
