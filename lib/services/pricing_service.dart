import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Сервис для работы с прайсами специалистов
class PricingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить базовые прайсы специалиста (для клиента - только неархивные)
  Stream<List<Map<String, dynamic>>> streamBasePrices(String specialistId, {bool forOwner = false}) {
    Query query = _firestore
        .collection('specialist_pricing')
        .doc(specialistId)
        .collection('base')
        .orderBy('eventType');

    if (!forOwner) {
      // Для клиента показываем только неархивные прайсы с активными ролями
      query = query.where('archived', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  /// Получить базовые прайсы специалиста (устаревший метод, используйте streamBasePrices)
  Future<List<Map<String, dynamic>>> getBasePrices(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('specialist_pricing')
          .doc(specialistId)
          .collection('base')
          .where('archived', isEqualTo: false)
          .orderBy('eventType')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting base prices: $e');
      return [];
    }
  }

  /// Получить спец-даты специалиста
  Future<List<Map<String, dynamic>>> getSpecialDates(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('specialist_pricing')
          .doc(specialistId)
          .collection('special_dates')
          .orderBy('date')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting special dates: $e');
      return [];
    }
  }

  /// Получить цену для конкретной даты и типа мероприятия
  Future<Map<String, dynamic>?> getPriceForDate(
    String specialistId,
    String date, // YYYY-MM-DD
    String eventType,
  ) async {
    try {
      // Сначала проверяем спец-дату
      final specialDateDoc = await _firestore
          .collection('specialist_pricing')
          .doc(specialistId)
          .collection('special_dates')
          .doc(date)
          .get();

      if (specialDateDoc.exists) {
        final data = specialDateDoc.data()!;
        // Если есть цена для конкретного типа или общая цена
        if (data['eventType'] == eventType || data['eventType'] == null) {
          return {
            'priceFrom': data['priceFrom'] as num?,
            'hours': data['hours'] as num?,
            'isSpecial': true,
            'date': date,
          };
        }
      }

      // Иначе берём базовую цену
      final basePrices = await getBasePrices(specialistId);
      for (final price in basePrices) {
        if (price['eventType'] == eventType) {
          return {
            'priceFrom': price['priceFrom'] as num?,
            'hours': price['hours'] as num?,
            'isSpecial': false,
          };
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting price for date: $e');
      return null;
    }
  }

  /// Добавить базовую цену
  Future<String> addBasePrice({
    required String specialistId,
    required String roleId,
    required String roleLabel,
    required String eventType,
    required int priceFrom,
    required int hours,
    String? description,
    String currency = 'RUB',
  }) async {
    try {
      final docRef = await _firestore
          .collection('specialist_pricing')
          .doc(specialistId)
          .collection('base')
          .add({
        'roleId': roleId,
        'roleLabel': roleLabel,
        'title': eventType,
        'eventType': eventType, // Для обратной совместимости
        'priceFrom': priceFrom,
        'hours': hours,
        'currency': currency,
        'archived': false,
        'notes': description,
        'description': description, // Для обратной совместимости
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugLog("PRICE_ADDED:${docRef.id}");
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding base price: $e');
      rethrow;
    }
  }

  /// Архивировать прайсы по роли
  Future<void> archivePricesByRole(String specialistId, String roleId, bool archived) async {
    try {
      final snapshot = await _firestore
          .collection('specialist_pricing')
          .doc(specialistId)
          .collection('base')
          .where('roleId', isEqualTo: roleId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'archived': archived,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugLog("PRICE_ARCHIVE:$roleId:$archived");
    } catch (e) {
      debugPrint('Error archiving prices by role: $e');
      rethrow;
    }
  }

  /// Рассчитать медиану цены по городу и роли
  Future<double?> calculateMedianForCityRole(String city, String roleId) async {
    try {
      // Получаем всех специалистов в городе с активной ролью
      final specialistsSnapshot = await _firestore
          .collection('users')
          .where('city', isEqualTo: city)
          .where('role', isEqualTo: 'specialist')
          .get();

      final prices = <int>[];

      for (final specialistDoc in specialistsSnapshot.docs) {
        final specialistId = specialistDoc.id;
        final roles = (specialistDoc.data()['roles'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        
        // Проверяем, что у специалиста есть активная роль
        final hasActiveRole = roles.any((role) => role['id'] == roleId);
        if (!hasActiveRole) continue;

        // Получаем прайсы для этой роли
        final pricesSnapshot = await _firestore
            .collection('specialist_pricing')
            .doc(specialistId)
            .collection('base')
            .where('roleId', isEqualTo: roleId)
            .where('archived', isEqualTo: false)
            .get();

        for (final priceDoc in pricesSnapshot.docs) {
          final priceFrom = priceDoc.data()['priceFrom'] as num?;
          if (priceFrom != null) {
            prices.add(priceFrom.toInt());
          }
        }
      }

      if (prices.length < 3) {
        return null; // Недостаточно данных
      }

      prices.sort();
      final middle = prices.length ~/ 2;
      if (prices.length % 2 == 0) {
        return (prices[middle - 1] + prices[middle]) / 2.0;
      } else {
        return prices[middle].toDouble();
      }
    } catch (e) {
      debugPrint('Error calculating median: $e');
      return null;
    }
  }

  /// Обновить базовую цену
  Future<void> updateBasePrice({
    required String specialistId,
    required String priceId,
    required String eventType,
    required int priceFrom,
    required int hours,
    String? description,
  }) async {
    try {
      await _firestore
          .collection('specialist_pricing')
          .doc(specialistId)
          .collection('base')
          .doc(priceId)
          .update({
        'eventType': eventType,
        'priceFrom': priceFrom,
        'hours': hours,
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugLog("PRICE_UPDATED:$priceId");
    } catch (e) {
      debugPrint('Error updating base price: $e');
      rethrow;
    }
  }

  /// Удалить базовую цену
  Future<void> deleteBasePrice(String specialistId, String priceId) async {
    try {
      await _firestore
          .collection('specialist_pricing')
          .doc(specialistId)
          .collection('base')
          .doc(priceId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting base price: $e');
      rethrow;
    }
  }

  /// Добавить спец-дату
  Future<String> addSpecialDate({
    required String specialistId,
    required String date, // YYYY-MM-DD
    String? eventType,
    required int priceFrom,
    required int hours,
    String? description,
  }) async {
    try {
      final docRef = await _firestore
          .collection('specialist_pricing')
          .doc(specialistId)
          .collection('special_dates')
          .doc(date)
          .set({
        'date': date,
        'eventType': eventType,
        'priceFrom': priceFrom,
        'hours': hours,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugLog("SPECIAL_PRICE_ADDED:$date");
      return date;
    } catch (e) {
      debugPrint('Error adding special date: $e');
      rethrow;
    }
  }

  /// Удалить спец-дату
  Future<void> deleteSpecialDate(String specialistId, String date) async {
    try {
      await _firestore
          .collection('specialist_pricing')
          .doc(specialistId)
          .collection('special_dates')
          .doc(date)
          .delete();
    } catch (e) {
      debugPrint('Error deleting special date: $e');
      rethrow;
    }
  }

  /// Рассчитать рыночную оценку цены (используя медиану)
  /// Возвращает: 'excellent' | 'average' | 'high' | null (если данных недостаточно)
  Future<String?> calculatePriceRating({
    required String specialistId,
    required String roleId,
    required int price,
    required String? city,
  }) async {
    try {
      if (city == null || city.isEmpty) return null;

      final median = await calculateMedianForCityRole(city, roleId);
      if (median == null) return null;

      final threshold15 = median * 0.15;

      if (price <= median - threshold15) {
        debugLog("PRICE_RATING:$specialistId:$roleId:excellent");
        return 'excellent';
      } else if (price >= median + threshold15) {
        debugLog("PRICE_RATING:$specialistId:$roleId:high");
        return 'high';
      } else {
        debugLog("PRICE_RATING:$specialistId:$roleId:average");
        return 'average';
      }
    } catch (e) {
      debugPrint('Error calculating price rating: $e');
      return null;
    }
  }
}
