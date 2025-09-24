import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/specialist.dart';
import '../models/booking.dart';

/// Сервис для автоматического расчета цен специалистов
class PriceCalculationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Рассчитать среднюю цену по услугам на основе прошлых заказов
  Future<Map<String, double>> calculateAveragePricesByService(String specialistId) async {
    try {
      // Получаем все завершенные заказы специалиста
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: BookingStatus.completed.name)
          .get();

      if (bookingsQuery.docs.isEmpty) {
        return {};
      }

      final servicePrices = <String, List<double>>{};
      
      for (final doc in bookingsQuery.docs) {
        final booking = Booking.fromDocument(doc);
        
        // Извлекаем информацию об услугах из заказа
        final services = _extractServicesFromBooking(booking);
        
        for (final service in services.entries) {
          final serviceName = service.key;
          final price = service.value;
          
          servicePrices.putIfAbsent(serviceName, () => []).add(price);
        }
      }

      // Рассчитываем средние цены
      final averagePrices = <String, double>{};
      for (final entry in servicePrices.entries) {
        final serviceName = entry.key;
        final prices = entry.value;
        
        if (prices.isNotEmpty) {
          final average = prices.reduce((a, b) => a + b) / prices.length;
          averagePrices[serviceName] = average;
        }
      }

      // Обновляем средние цены в профиле специалиста
      await _updateSpecialistAveragePrices(specialistId, averagePrices);

      debugPrint('Calculated average prices for specialist $specialistId: $averagePrices');
      return averagePrices;
    } catch (e) {
      debugPrint('Error calculating average prices: $e');
      return {};
    }
  }

  /// Рассчитать рекомендуемые цены на основе рыночных данных
  Future<Map<String, double>> calculateRecommendedPrices(String specialistId) async {
    try {
      final specialistDoc = await _firestore.collection('specialists').doc(specialistId).get();
      if (!specialistDoc.exists) return {};

      final specialist = Specialist.fromDocument(specialistDoc);
      final category = specialist.category;
      
      // Получаем рыночные данные по категории
      final marketPrices = await _getMarketPricesForCategory(category);
      
      // Получаем опыт специалиста
      final experienceLevel = specialist.experienceLevel;
      final yearsOfExperience = specialist.yearsOfExperience;
      
      // Рассчитываем коэффициенты на основе опыта
      final experienceMultiplier = _getExperienceMultiplier(experienceLevel, yearsOfExperience);
      
      // Рассчитываем рекомендуемые цены
      final recommendedPrices = <String, double>{};
      for (final entry in marketPrices.entries) {
        final serviceName = entry.key;
        final marketPrice = entry.value;
        
        // Применяем коэффициент опыта
        final recommendedPrice = marketPrice * experienceMultiplier;
        recommendedPrices[serviceName] = recommendedPrice;
      }

      debugPrint('Calculated recommended prices for specialist $specialistId: $recommendedPrices');
      return recommendedPrices;
    } catch (e) {
      debugPrint('Error calculating recommended prices: $e');
      return {};
    }
  }

  /// Рассчитать динамические цены на основе спроса
  Future<Map<String, double>> calculateDynamicPrices(String specialistId) async {
    try {
      final specialistDoc = await _firestore.collection('specialists').doc(specialistId).get();
      if (!specialistDoc.exists) return {};

      final specialist = Specialist.fromDocument(specialistDoc);
      final currentPrices = specialist.avgPriceByService ?? {};
      
      // Получаем данные о спросе
      final demandData = await _getDemandData(specialist.category);
      
      // Получаем данные о загруженности специалиста
      final workloadData = await _getWorkloadData(specialistId);
      
      // Рассчитываем динамические цены
      final dynamicPrices = <String, double>{};
      for (final entry in currentPrices.entries) {
        final serviceName = entry.key;
        final basePrice = entry.value;
        
        // Коэффициент спроса
        final demandMultiplier = demandData[serviceName] ?? 1.0;
        
        // Коэффициент загруженности
        final workloadMultiplier = workloadData['multiplier'] ?? 1.0;
        
        // Рассчитываем динамическую цену
        final dynamicPrice = basePrice * demandMultiplier * workloadMultiplier;
        dynamicPrices[serviceName] = dynamicPrice;
      }

      debugPrint('Calculated dynamic prices for specialist $specialistId: $dynamicPrices');
      return dynamicPrices;
    } catch (e) {
      debugPrint('Error calculating dynamic prices: $e');
      return {};
    }
  }

  /// Получить анализ цен конкурентов
  Future<Map<String, dynamic>> getCompetitorPriceAnalysis(String specialistId) async {
    try {
      final specialistDoc = await _firestore.collection('specialists').doc(specialistId).get();
      if (!specialistDoc.exists) return {};

      final specialist = Specialist.fromDocument(specialistDoc);
      final category = specialist.category;
      final location = specialist.location;
      
      // Получаем цены конкурентов в той же категории и регионе
      final competitorsQuery = await _firestore
          .collection('specialists')
          .where('category', isEqualTo: category.name)
          .where('location', isEqualTo: location)
          .where('isAvailable', isEqualTo: true)
          .limit(20)
          .get();

      if (competitorsQuery.docs.isEmpty) return {};

      final competitorPrices = <String, List<double>>{};
      
      for (final doc in competitorsQuery.docs) {
        if (doc.id == specialistId) continue; // Исключаем самого специалиста
        
        final competitor = Specialist.fromDocument(doc);
        final prices = competitor.avgPriceByService ?? {};
        
        for (final entry in prices.entries) {
          final serviceName = entry.key;
          final price = entry.value;
          
          competitorPrices.putIfAbsent(serviceName, () => []).add(price);
        }
      }

      // Анализируем цены конкурентов
      final analysis = <String, dynamic>{};
      for (final entry in competitorPrices.entries) {
        final serviceName = entry.key;
        final prices = entry.value;
        
        if (prices.isNotEmpty) {
          prices.sort();
          
          final minPrice = prices.first;
          final maxPrice = prices.last;
          final medianPrice = prices[prices.length ~/ 2];
          final averagePrice = prices.reduce((a, b) => a + b) / prices.length;
          
          analysis[serviceName] = {
            'min': minPrice,
            'max': maxPrice,
            'median': medianPrice,
            'average': averagePrice,
            'competitorCount': prices.length,
          };
        }
      }

      debugPrint('Competitor price analysis for specialist $specialistId: $analysis');
      return analysis;
    } catch (e) {
      debugPrint('Error getting competitor price analysis: $e');
      return {};
    }
  }

  /// Получить рекомендации по ценообразованию
  Future<Map<String, dynamic>> getPricingRecommendations(String specialistId) async {
    try {
      final specialistDoc = await _firestore.collection('specialists').doc(specialistId).get();
      if (!specialistDoc.exists) return {};

      final specialist = Specialist.fromDocument(specialistDoc);
      final currentPrices = specialist.avgPriceByService ?? {};
      
      // Получаем различные виды анализа
      final averagePrices = await calculateAveragePricesByService(specialistId);
      final recommendedPrices = await calculateRecommendedPrices(specialistId);
      final competitorAnalysis = await getCompetitorPriceAnalysis(specialistId);
      
      // Формируем рекомендации
      final recommendations = <String, dynamic>{};
      
      for (final entry in currentPrices.entries) {
        final serviceName = entry.key;
        final currentPrice = entry.value;
        final averagePrice = averagePrices[serviceName] ?? currentPrice;
        final recommendedPrice = recommendedPrices[serviceName] ?? currentPrice;
        final competitorData = competitorAnalysis[serviceName];
        
        // Определяем рекомендацию
        String recommendation;
        String reason;
        
        if (currentPrice < recommendedPrice * 0.8) {
          recommendation = 'increase';
          reason = 'Ваша цена ниже рекомендуемой на ${((recommendedPrice - currentPrice) / currentPrice * 100).toStringAsFixed(1)}%';
        } else if (currentPrice > recommendedPrice * 1.2) {
          recommendation = 'decrease';
          reason = 'Ваша цена выше рекомендуемой на ${((currentPrice - recommendedPrice) / recommendedPrice * 100).toStringAsFixed(1)}%';
        } else {
          recommendation = 'maintain';
          reason = 'Ваша цена находится в оптимальном диапазоне';
        }
        
        recommendations[serviceName] = {
          'currentPrice': currentPrice,
          'averagePrice': averagePrice,
          'recommendedPrice': recommendedPrice,
          'recommendation': recommendation,
          'reason': reason,
          'competitorData': competitorData,
        };
      }

      debugPrint('Pricing recommendations for specialist $specialistId: $recommendations');
      return recommendations;
    } catch (e) {
      debugPrint('Error getting pricing recommendations: $e');
      return {};
    }
  }

  /// Обновить средние цены специалиста
  Future<void> _updateSpecialistAveragePrices(String specialistId, Map<String, double> averagePrices) async {
    try {
      await _firestore.collection('specialists').doc(specialistId).update({
        'avgPriceByService': averagePrices,
        'lastPriceUpdateAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error updating specialist average prices: $e');
    }
  }

  /// Извлечь услуги из заказа
  Map<String, double> _extractServicesFromBooking(Booking booking) {
    // Здесь должна быть логика извлечения услуг из заказа
    // Пока возвращаем базовую информацию
    return {
      'Основная услуга': booking.totalPrice,
    };
  }

  /// Получить рыночные цены по категории
  Future<Map<String, double>> _getMarketPricesForCategory(SpecialistCategory category) async {
    // Базовые рыночные цены по категориям
    final marketPrices = <SpecialistCategory, Map<String, double>>{
      SpecialistCategory.photographer: {
        'Свадебная фотосъемка': 25000.0,
        'Портретная съемка': 8000.0,
        'Семейная фотосъемка': 12000.0,
        'Корпоративная съемка': 15000.0,
      },
      SpecialistCategory.videographer: {
        'Свадебная видеосъемка': 35000.0,
        'Корпоративное видео': 20000.0,
        'Промо-ролик': 15000.0,
      },
      SpecialistCategory.dj: {
        'Свадебный DJ': 15000.0,
        'Корпоративный DJ': 10000.0,
        'Детский праздник': 8000.0,
      },
      SpecialistCategory.host: {
        'Свадебный ведущий': 20000.0,
        'Корпоративный ведущий': 15000.0,
        'Детский аниматор': 5000.0,
      },
      SpecialistCategory.decorator: {
        'Свадебное оформление': 30000.0,
        'Корпоративное оформление': 15000.0,
        'Детский праздник': 8000.0,
      },
    };

    return marketPrices[category] ?? {};
  }

  /// Получить коэффициент опыта
  double _getExperienceMultiplier(ExperienceLevel level, int years) {
    double baseMultiplier;
    
    switch (level) {
      case ExperienceLevel.beginner:
        baseMultiplier = 0.7;
        break;
      case ExperienceLevel.intermediate:
        baseMultiplier = 0.9;
        break;
      case ExperienceLevel.advanced:
        baseMultiplier = 1.2;
        break;
      case ExperienceLevel.expert:
        baseMultiplier = 1.5;
        break;
    }
    
    // Дополнительный бонус за годы опыта
    final yearsBonus = (years * 0.05).clamp(0.0, 0.5);
    
    return baseMultiplier + yearsBonus;
  }

  /// Получить данные о спросе
  Future<Map<String, double>> _getDemandData(SpecialistCategory category) async {
    // Здесь должна быть логика получения данных о спросе
    // Пока возвращаем базовые значения
    return {
      'Основная услуга': 1.0,
    };
  }

  /// Получить данные о загруженности
  Future<Map<String, dynamic>> _getWorkloadData(String specialistId) async {
    try {
      // Получаем количество активных заказов
      final activeBookingsQuery = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', whereIn: [
            BookingStatus.confirmed.name,
            BookingStatus.inProgress.name,
          ])
          .get();

      final activeBookingsCount = activeBookingsQuery.docs.length;
      
      // Рассчитываем коэффициент загруженности
      double multiplier = 1.0;
      if (activeBookingsCount > 10) {
        multiplier = 1.3; // Высокая загруженность - повышаем цены
      } else if (activeBookingsCount < 3) {
        multiplier = 0.9; // Низкая загруженность - снижаем цены
      }

      return {
        'activeBookings': activeBookingsCount,
        'multiplier': multiplier,
      };
    } catch (e) {
      debugPrint('Error getting workload data: $e');
      return {'multiplier': 1.0};
    }
  }

  /// Получить историю изменения цен
  Future<List<Map<String, dynamic>>> getPriceHistory(String specialistId) async {
    try {
      final priceHistoryQuery = await _firestore
          .collection('price_history')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('updatedAt', descending: true)
          .limit(50)
          .get();

      return priceHistoryQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'updatedAt': (data['updatedAt'] as Timestamp).toDate(),
          'prices': data['prices'],
          'reason': data['reason'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting price history: $e');
      return [];
    }
  }

  /// Сохранить историю изменения цен
  Future<void> savePriceHistory(String specialistId, Map<String, double> prices, String reason) async {
    try {
      await _firestore.collection('price_history').add({
        'specialistId': specialistId,
        'prices': prices,
        'reason': reason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error saving price history: $e');
    }
  }
}
