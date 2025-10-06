import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/logger.dart';
import '../models/booking.dart';
import '../models/specialist.dart';

/// Сервис для работы с ценами и расчетом средних значений
class PricingService {
  factory PricingService() => _instance;
  PricingService._internal();
  static final PricingService _instance = PricingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Рассчитать среднюю цену по услугам для специалиста
  Future<Map<String, double>> calculateAveragePricesByService(
    String specialistId,
  ) async {
    try {
      AppLogger.logI(
        'Расчет средних цен для специалиста: $specialistId',
        'pricing_service',
      );

      // Получаем все завершенные бронирования специалиста
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: BookingStatus.completed.name)
          .get();

      if (bookingsSnapshot.docs.isEmpty) {
        AppLogger.logI(
          'Нет завершенных бронирований для расчета',
          'pricing_service',
        );
        return {};
      }

      // Группируем по категориям услуг
      final pricesByCategory = <String, List<double>>{};

      for (final doc in bookingsSnapshot.docs) {
        final booking = Booking.fromDocument(doc);
        final category = booking.eventType ?? 'other';

        if (!pricesByCategory.containsKey(category)) {
          pricesByCategory[category] = [];
        }
        pricesByCategory[category]!.add(booking.totalPrice);
      }

      // Рассчитываем средние цены
      final averagePrices = <String, double>{};
      pricesByCategory.forEach((category, prices) {
        if (prices.isNotEmpty) {
          averagePrices[category] =
              prices.reduce((a, b) => a + b) / prices.length;
        }
      });

      AppLogger.logI(
        'Средние цены рассчитаны: $averagePrices',
        'pricing_service',
      );
      return averagePrices;
    } catch (e, stackTrace) {
      AppLogger.logE(
        'Ошибка расчета средних цен',
        'pricing_service',
        e,
        stackTrace,
      );
      return {};
    }
  }

  /// Обновить средние цены специалиста
  Future<void> updateSpecialistAveragePrices(String specialistId) async {
    try {
      AppLogger.logI(
        'Обновление средних цен специалиста: $specialistId',
        'pricing_service',
      );

      final averagePrices = await calculateAveragePricesByService(specialistId);

      await _firestore.collection('specialists').doc(specialistId).update({
        'avgPriceByService': averagePrices,
        'lastPriceUpdateAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.logI(
        'Средние цены обновлены для специалиста: $specialistId',
        'pricing_service',
      );
    } catch (e, stackTrace) {
      AppLogger.logE(
        'Ошибка обновления средних цен',
        'pricing_service',
        e,
        stackTrace,
      );
    }
  }

  /// Получить среднюю цену по категории специалистов
  Future<double> getAveragePriceByCategory(SpecialistCategory category) async {
    try {
      AppLogger.logI(
        'Получение средней цены по категории: ${category.name}',
        'pricing_service',
      );

      final specialistsSnapshot = await _firestore
          .collection('specialists')
          .where('category', isEqualTo: category.name)
          .where('isAvailable', isEqualTo: true)
          .get();

      if (specialistsSnapshot.docs.isEmpty) {
        return 0.0;
      }

      final prices = specialistsSnapshot.docs
          .map(Specialist.fromDocument)
          .map((specialist) => specialist.price)
          .where((price) => price > 0)
          .toList();

      if (prices.isEmpty) {
        return 0.0;
      }

      final averagePrice = prices.reduce((a, b) => a + b) / prices.length;
      AppLogger.logI(
        'Средняя цена по категории ${category.name}: $averagePrice',
        'pricing_service',
      );
      return averagePrice;
    } catch (e, stackTrace) {
      AppLogger.logE(
        'Ошибка получения средней цены по категории',
        'pricing_service',
        e,
        stackTrace,
      );
      return 0.0;
    }
  }

  /// Получить диапазон цен по категории
  Future<Map<String, double>> getPriceRangeByCategory(
    SpecialistCategory category,
  ) async {
    try {
      AppLogger.logI(
        'Получение диапазона цен по категории: ${category.name}',
        'pricing_service',
      );

      final specialistsSnapshot = await _firestore
          .collection('specialists')
          .where('category', isEqualTo: category.name)
          .where('isAvailable', isEqualTo: true)
          .get();

      if (specialistsSnapshot.docs.isEmpty) {
        return {'min': 0.0, 'max': 0.0, 'avg': 0.0};
      }

      final prices = specialistsSnapshot.docs
          .map(Specialist.fromDocument)
          .map((specialist) => specialist.price)
          .where((price) => price > 0)
          .toList();

      if (prices.isEmpty) {
        return {'min': 0.0, 'max': 0.0, 'avg': 0.0};
      }

      prices.sort();
      final minPrice = prices.first;
      final maxPrice = prices.last;
      final avgPrice = prices.reduce((a, b) => a + b) / prices.length;

      AppLogger.logI(
        'Диапазон цен по категории ${category.name}: min=$minPrice, max=$maxPrice, avg=$avgPrice',
        'pricing_service',
      );
      return {
        'min': minPrice,
        'max': maxPrice,
        'avg': avgPrice,
      };
    } catch (e, stackTrace) {
      AppLogger.logE(
        'Ошибка получения диапазона цен',
        'pricing_service',
        e,
        stackTrace,
      );
      return {'min': 0.0, 'max': 0.0, 'avg': 0.0};
    }
  }

  /// Получить рекомендуемую цену для нового специалиста
  Future<double> getRecommendedPrice(
    SpecialistCategory category,
    ExperienceLevel experienceLevel,
  ) async {
    try {
      AppLogger.logI(
        'Получение рекомендуемой цены для ${category.name} с уровнем ${experienceLevel.name}',
        'pricing_service',
      );

      final priceRange = await getPriceRangeByCategory(category);
      final basePrice = priceRange['avg'] ?? 0.0;

      // Корректируем цену в зависимости от уровня опыта
      var experienceMultiplier = 1;
      switch (experienceLevel) {
        case ExperienceLevel.beginner:
          experienceMultiplier = 0.7;
          break;
        case ExperienceLevel.intermediate:
          experienceMultiplier = 0.9;
          break;
        case ExperienceLevel.advanced:
          experienceMultiplier = 1.1;
          break;
        case ExperienceLevel.expert:
          experienceMultiplier = 1.3;
          break;
      }

      final recommendedPrice = basePrice * experienceMultiplier;
      AppLogger.logI(
        'Рекомендуемая цена: $recommendedPrice',
        'pricing_service',
      );
      return recommendedPrice;
    } catch (e, stackTrace) {
      AppLogger.logE(
        'Ошибка получения рекомендуемой цены',
        'pricing_service',
        e,
        stackTrace,
      );
      return 0.0;
    }
  }

  /// Обновить цены всех специалистов (для batch операций)
  Future<void> updateAllSpecialistsAveragePrices() async {
    try {
      AppLogger.logI(
        'Обновление средних цен всех специалистов',
        'pricing_service',
      );

      final specialistsSnapshot =
          await _firestore.collection('specialists').get();

      final batch = _firestore.batch();
      var updatedCount = 0;

      for (final doc in specialistsSnapshot.docs) {
        final specialistId = doc.id;
        final averagePrices =
            await calculateAveragePricesByService(specialistId);

        if (averagePrices.isNotEmpty) {
          batch.update(doc.reference, {
            'avgPriceByService': averagePrices,
            'lastPriceUpdateAt': Timestamp.fromDate(DateTime.now()),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
          updatedCount++;
        }
      }

      await batch.commit();
      AppLogger.logI(
        'Обновлено средних цен для $updatedCount специалистов',
        'pricing_service',
      );
    } catch (e, stackTrace) {
      AppLogger.logE(
        'Ошибка обновления средних цен всех специалистов',
        'pricing_service',
        e,
        stackTrace,
      );
    }
  }

  /// Получить статистику цен по всем категориям
  Future<Map<String, Map<String, double>>> getAllCategoriesPriceStats() async {
    try {
      AppLogger.logI(
        'Получение статистики цен по всем категориям',
        'pricing_service',
      );

      final stats = <String, Map<String, double>>{};

      for (final category in SpecialistCategory.values) {
        final priceRange = await getPriceRangeByCategory(category);
        stats[category.name] = priceRange;
      }

      AppLogger.logI(
        'Статистика цен получена для ${stats.length} категорий',
        'pricing_service',
      );
      return stats;
    } catch (e, stackTrace) {
      AppLogger.logE(
        'Ошибка получения статистики цен',
        'pricing_service',
        e,
        stackTrace,
      );
      return {};
    }
  }
}
