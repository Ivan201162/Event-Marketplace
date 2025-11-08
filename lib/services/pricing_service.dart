import 'dart:async';
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
  /// Возвращает цену с пометкой "estimated" (все цены являются ориентировочными)
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
            'isEstimated': true, // Все цены являются ориентировочными
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
            'isEstimated': true, // Все цены являются ориентировочными
            'roleId': price['roleId'] as String?, // Добавляем roleId для расчета рейтинга
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
      final priceId = _firestore
          .collection('specialist_pricing')
          .doc(specialistId)
          .collection('base')
          .doc()
          .id;

      await _firestore
          .collection('specialist_pricing')
          .doc(specialistId)
          .collection('base')
          .doc(priceId)
          .set({
        'roleId': roleId,
        'title': eventType,
        'baseHours': hours,
        'priceFrom': priceFrom,
        'hidden': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Сохранение услуги превысило таймаут');
        },
      );

      debugLog("PRICE_ADDED:$priceId");
      return priceId;
    } catch (e) {
      final errorCode = e is TimeoutException ? 'timeout' : (e is Exception ? e.toString() : 'unknown');
      debugLog("PRICE_ERR:$errorCode");
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
          'hidden': archived, // Помечаем как скрытые при архивации
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugLog("PRICE_ARCHIVE:$roleId:$archived");
      debugLog("PRICE_HIDDEN_TOGGLED:$roleId:$archived");
    } catch (e) {
      debugPrint('Error archiving prices by role: $e');
      rethrow;
    }
  }

  /// Скрыть/показать прайсы по роли (v2: используем hidden вместо удаления)
  Future<void> togglePricesHiddenByRole(String specialistId, String roleId, bool hidden) async {
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
          'hidden': hidden,
          'archived': hidden, // Также архивируем при скрытии
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugLog("PRICE_HIDDEN_TOGGLED:$roleId:$hidden");
    } catch (e) {
      debugPrint('Error toggling prices hidden: $e');
      rethrow;
    }
  }

  /// Рассчитать медиану и перцентили цены по городу и роли
  Future<Map<String, double>?> calculatePriceStatsForCityRole(String city, String roleId) async {
    try {
      // Получаем всех специалистов в городе с активной ролью
      final specialistsSnapshot = await _firestore
          .collection('users')
          .where('city', isEqualTo: city)
          .where('isSpecialist', isEqualTo: true)
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
      
      // Медиана (50 перцентиль)
      final median = _calculatePercentile(prices, 50);
      
      // 25 и 75 перцентили
      final p25 = _calculatePercentile(prices, 25);
      final p75 = _calculatePercentile(prices, 75);

      return {
        'median': median,
        'p25': p25,
        'p75': p75,
      };
    } catch (e) {
      debugPrint('Error calculating price stats: $e');
      return null;
    }
  }

  double _calculatePercentile(List<int> sortedPrices, int percentile) {
    if (sortedPrices.isEmpty) return 0.0;
    final index = (sortedPrices.length * percentile / 100).ceil() - 1;
    return sortedPrices[index.clamp(0, sortedPrices.length - 1)].toDouble();
  }

  /// Рассчитать медиану цены по городу и роли (устаревший метод, используйте calculatePriceStatsForCityRole)
  Future<double?> calculateMedianForCityRole(String city, String roleId) async {
    final stats = await calculatePriceStatsForCityRole(city, roleId);
    return stats?['median'];
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
        'roleId': FieldValue.delete(), // Сохраняем существующий roleId
        'title': eventType,
        'baseHours': hours,
        'priceFrom': priceFrom,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugLog("PRICE_UPDATED:$priceId");
    } catch (e) {
      final errorCode = e is Exception ? e.toString() : 'unknown';
      debugLog("PRICE_ERR:$errorCode");
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

  /// Рассчитать рыночную оценку цены (используя перцентили)
  /// Возвращает: 'excellent' | 'average' | 'high' | null (если данных недостаточно)
  Future<String?> calculatePriceRating({
    required String specialistId,
    required String roleId,
    required int price,
    required String? city,
  }) async {
    try {
      if (city == null || city.isEmpty) return null;

      final stats = await calculatePriceStatsForCityRole(city, roleId);
      if (stats == null) return null;

      final p25 = stats['p25']!;
      final p75 = stats['p75']!;

      String rating;
      if (price <= p25) {
        rating = 'excellent';
      } else if (price >= p75) {
        rating = 'high';
      } else {
        rating = 'average';
      }

      debugLog("PRICE_RATING:$specialistId:$roleId:$rating");
      return rating;
    } catch (e) {
      debugPrint('Error calculating price rating: $e');
      return null;
    }
  }
}
