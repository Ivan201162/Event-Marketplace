import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promotion.dart';

/// Сервис для работы с акциями и предложениями
class PromotionService {
  static const String _collection = 'promotions';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить все активные акции
  Future<List<Promotion>> getActivePromotions() async {
    try {
      final now = Timestamp.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: now)
          .where('endDate', isGreaterThan: now)
          .orderBy('endDate')
          .orderBy('discount', descending: true)
          .get();

      return querySnapshot.docs.map(Promotion.fromFirestore).toList();
    } catch (e) {
      print('Ошибка получения активных акций: $e');
      return [];
    }
  }

  /// Получить акции по категории
  Future<List<Promotion>> getPromotionsByCategory(String category) async {
    try {
      final now = Timestamp.now();
      Query query = _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: now)
          .where('endDate', isGreaterThan: now);

      if (category != 'all') {
        query = query.where('category', isEqualTo: category);
      }

      final querySnapshot = await query
          .orderBy('endDate')
          .orderBy('discount', descending: true)
          .get();

      return querySnapshot.docs.map(Promotion.fromFirestore).toList();
    } catch (e) {
      print('Ошибка получения акций по категории: $e');
      return [];
    }
  }

  /// Получить акции по городу
  Future<List<Promotion>> getPromotionsByCity(String city) async {
    try {
      final now = Timestamp.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: now)
          .where('endDate', isGreaterThan: now)
          .where('city', isEqualTo: city)
          .orderBy('endDate')
          .orderBy('discount', descending: true)
          .get();

      return querySnapshot.docs.map(Promotion.fromFirestore).toList();
    } catch (e) {
      print('Ошибка получения акций по городу: $e');
      return [];
    }
  }

  /// Получить акции специалиста
  Future<List<Promotion>> getSpecialistPromotions(String specialistId) async {
    try {
      final now = Timestamp.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('specialistId', isEqualTo: specialistId)
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: now)
          .where('endDate', isGreaterThan: now)
          .orderBy('endDate')
          .get();

      return querySnapshot.docs.map(Promotion.fromFirestore).toList();
    } catch (e) {
      print('Ошибка получения акций специалиста: $e');
      return [];
    }
  }

  /// Получить сезонные предложения
  Future<List<Promotion>> getSeasonalPromotions() async {
    try {
      final now = Timestamp.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: now)
          .where('endDate', isGreaterThan: now)
          .where('category', isEqualTo: 'seasonal')
          .orderBy('endDate')
          .get();

      return querySnapshot.docs.map(Promotion.fromFirestore).toList();
    } catch (e) {
      print('Ошибка получения сезонных предложений: $e');
      return [];
    }
  }

  /// Получить промокоды и подарки
  Future<List<Promotion>> getPromoCodesAndGifts() async {
    try {
      final now = Timestamp.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: now)
          .where('endDate', isGreaterThan: now)
          .where('category', whereIn: ['promoCode', 'gift'])
          .orderBy('endDate')
          .get();

      return querySnapshot.docs.map(Promotion.fromFirestore).toList();
    } catch (e) {
      print('Ошибка получения промокодов и подарков: $e');
      return [];
    }
  }

  /// Создать новую акцию
  Future<String?> createPromotion(Promotion promotion) async {
    try {
      final docRef =
          await _firestore.collection(_collection).add(promotion.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Ошибка создания акции: $e');
      return null;
    }
  }

  /// Обновить акцию
  Future<bool> updatePromotion(String id, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        ...updates,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Ошибка обновления акции: $e');
      return false;
    }
  }

  /// Удалить акцию
  Future<bool> deletePromotion(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Ошибка удаления акции: $e');
      return false;
    }
  }

  /// Деактивировать акцию
  Future<bool> deactivatePromotion(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Ошибка деактивации акции: $e');
      return false;
    }
  }

  /// Получить акции с фильтрацией
  Future<List<Promotion>> getFilteredPromotions({
    String? category,
    String? city,
    int? minDiscount,
    int? maxDiscount,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query =
          _firestore.collection(_collection).where('isActive', isEqualTo: true);

      if (category != null && category != 'all') {
        query = query.where('category', isEqualTo: category);
      }

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      if (minDiscount != null) {
        query = query.where('discount', isGreaterThanOrEqualTo: minDiscount);
      }

      if (maxDiscount != null) {
        query = query.where('discount', isLessThanOrEqualTo: maxDiscount);
      }

      if (startDate != null) {
        query = query.where('startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('endDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query
          .orderBy('endDate')
          .orderBy('discount', descending: true)
          .get();

      return querySnapshot.docs.map(Promotion.fromFirestore).toList();
    } catch (e) {
      print('Ошибка получения отфильтрованных акций: $e');
      return [];
    }
  }

  /// Получить статистику акций
  Future<Map<String, dynamic>> getPromotionStats() async {
    try {
      final now = Timestamp.now();

      // Активные акции
      final activeQuery = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: now)
          .where('endDate', isGreaterThan: now)
          .get();

      // Завершенные акции
      final completedQuery = await _firestore
          .collection(_collection)
          .where('endDate', isLessThan: now)
          .get();

      // Все акции
      final allQuery = await _firestore.collection(_collection).get();

      return {
        'active': activeQuery.docs.length,
        'completed': completedQuery.docs.length,
        'total': allQuery.docs.length,
        'categories': _getCategoryStats(allQuery.docs),
      };
    } catch (e) {
      print('Ошибка получения статистики акций: $e');
      return {};
    }
  }

  /// Получить статистику по категориям
  Map<String, int> _getCategoryStats(List<QueryDocumentSnapshot> docs) {
    final categoryStats = <String, int>{};

    for (final doc in docs) {
      final data = doc.data()! as Map<String, dynamic>;
      final category = data['category'] ?? 'other';
      categoryStats[category] = (categoryStats[category] ?? 0) + 1;
    }

    return categoryStats;
  }

  /// Автоматически деактивировать просроченные акции
  Future<int> deactivateExpiredPromotions() async {
    try {
      final now = Timestamp.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('endDate', isLessThan: now)
          .get();

      final batch = _firestore.batch();
      var deactivatedCount = 0;

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'isActive': false,
          'updatedAt': Timestamp.now(),
        });
        deactivatedCount++;
      }

      if (deactivatedCount > 0) {
        await batch.commit();
      }

      return deactivatedCount;
    } catch (e) {
      print('Ошибка деактивации просроченных акций: $e');
      return 0;
    }
  }
}
