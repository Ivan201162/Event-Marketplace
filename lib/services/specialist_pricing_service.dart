import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/specialist.dart';

/// Сервис для расчета цен специалиста
class SpecialistPricingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Рассчитать средний прайс по прошлым заказам
  Future<Map<String, double>> calculateAveragePrices(String specialistId) async {
    try {
      // Получаем завершенные заказы за последние 6 месяцев
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      
      final query = await _db
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('status', isEqualTo: BookingStatus.completed.name)
          .where('completedAt', isGreaterThan: Timestamp.fromDate(sixMonthsAgo))
          .get();

      final bookings = query.docs.map((doc) => Booking.fromDocument(doc)).toList();
      
      if (bookings.isEmpty) {
        return {};
      }

      // Группируем заказы по типам услуг
      final Map<String, List<double>> pricesByService = {};
      
      for (final booking in bookings) {
        final serviceType = booking.eventType ?? 'general';
        final price = booking.totalPrice;
        
        if (!pricesByService.containsKey(serviceType)) {
          pricesByService[serviceType] = [];
        }
        pricesByService[serviceType]!.add(price);
      }

      // Рассчитываем средние цены
      final Map<String, double> averagePrices = {};
      
      for (final entry in pricesByService.entries) {
        final prices = entry.value;
        final average = prices.reduce((a, b) => a + b) / prices.length;
        averagePrices[entry.key] = average;
      }

      return averagePrices;
    } catch (e) {
      debugPrint('Ошибка расчета средних цен: $e');
      return {};
    }
  }

  /// Получить рекомендации по ценам
  Future<Map<String, PriceRecommendation>> getPriceRecommendations(String specialistId) async {
    try {
      final averagePrices = await calculateAveragePrices(specialistId);
      final specialist = await _getSpecialist(specialistId);
      
      if (specialist == null) {
        return {};
      }

      final recommendations = <String, PriceRecommendation>{};
      
      for (final entry in averagePrices.entries) {
        final serviceType = entry.key;
        final currentAverage = entry.value;
        
        // Получаем рыночные цены для сравнения
        final marketPrices = await _getMarketPrices(serviceType, specialist.location);
        
        if (marketPrices.isNotEmpty) {
          final marketAverage = marketPrices.reduce((a, b) => a + b) / marketPrices.length;
          final marketMin = marketPrices.reduce((a, b) => a < b ? a : b);
          final marketMax = marketPrices.reduce((a, b) => a > b ? a : b);
          
          final recommendation = _generateRecommendation(
            currentAverage,
            marketAverage,
            marketMin,
            marketMax,
            specialist.rating,
          );
          
          recommendations[serviceType] = recommendation;
        }
      }

      return recommendations;
    } catch (e) {
      debugPrint('Ошибка получения рекомендаций по ценам: $e');
      return {};
    }
  }

  /// Обновить цены услуг на основе рекомендаций
  Future<void> updateServicePrices({
    required String specialistId,
    required Map<String, double> newPrices,
  }) async {
    try {
      final specialist = await _getSpecialist(specialistId);
      if (specialist == null) return;

      final updatedServices = specialist.services?.map((service) {
        final newPrice = newPrices[service.name];
        if (newPrice != null) {
          return service.copyWith(price: newPrice);
        }
        return service;
      }).toList();

      if (updatedServices != null) {
        await _db.collection('specialists').doc(specialistId).update({
          'services': updatedServices.map((s) => s.toMap()).toList(),
          'lastPriceUpdate': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      debugPrint('Ошибка обновления цен услуг: $e');
      throw Exception('Не удалось обновить цены: $e');
    }
  }

  /// Получить историю изменения цен
  Future<List<PriceHistoryEntry>> getPriceHistory(String specialistId) async {
    try {
      final query = await _db
          .collection('price_history')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('updatedAt', descending: true)
          .limit(50)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return PriceHistoryEntry(
          id: doc.id,
          specialistId: data['specialistId'] as String,
          serviceName: data['serviceName'] as String,
          oldPrice: (data['oldPrice'] as num).toDouble(),
          newPrice: (data['newPrice'] as num).toDouble(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
          reason: data['reason'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('Ошибка получения истории цен: $e');
      return [];
    }
  }

  /// Сохранить изменение цены в историю
  Future<void> savePriceChange({
    required String specialistId,
    required String serviceName,
    required double oldPrice,
    required double newPrice,
    String? reason,
  }) async {
    try {
      await _db.collection('price_history').add({
        'specialistId': specialistId,
        'serviceName': serviceName,
        'oldPrice': oldPrice,
        'newPrice': newPrice,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'reason': reason,
      });
    } catch (e) {
      debugPrint('Ошибка сохранения изменения цены: $e');
    }
  }

  /// Получить специалиста
  Future<Specialist?> _getSpecialist(String specialistId) async {
    try {
      final doc = await _db.collection('specialists').doc(specialistId).get();
      if (doc.exists) {
        return Specialist.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка получения специалиста: $e');
      return null;
    }
  }

  /// Получить рыночные цены
  Future<List<double>> _getMarketPrices(String serviceType, String? location) async {
    try {
      Query<Map<String, dynamic>> query = _db
          .collection('bookings')
          .where('eventType', isEqualTo: serviceType)
          .where('status', isEqualTo: BookingStatus.completed.name);

      if (location != null) {
        query = query.where('eventLocation', isEqualTo: location);
      }

      final querySnapshot = await query.limit(100).get();
      
      return querySnapshot.docs
          .map((doc) => (doc.data()['totalPrice'] as num).toDouble())
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения рыночных цен: $e');
      return [];
    }
  }

  /// Сгенерировать рекомендацию по цене
  PriceRecommendation _generateRecommendation(
    double currentPrice,
    double marketAverage,
    double marketMin,
    double marketMax,
    double rating,
  ) {
    final priceDifference = currentPrice - marketAverage;
    final priceDifferencePercent = (priceDifference / marketAverage) * 100;
    
    PriceRecommendationType type;
    String message;
    double? suggestedPrice;
    
    if (priceDifferencePercent > 20) {
      // Цена слишком высокая
      type = PriceRecommendationType.decrease;
      message = 'Ваша цена на ${priceDifferencePercent.toStringAsFixed(1)}% выше рыночной';
      suggestedPrice = marketAverage * 1.1; // На 10% выше рыночной
    } else if (priceDifferencePercent < -20) {
      // Цена слишком низкая
      type = PriceRecommendationType.increase;
      message = 'Ваша цена на ${(-priceDifferencePercent).toStringAsFixed(1)}% ниже рыночной';
      suggestedPrice = marketAverage * 0.9; // На 10% ниже рыночной
    } else {
      // Цена в норме
      type = PriceRecommendationType.maintain;
      message = 'Ваша цена соответствует рыночной';
    }

    // Учитываем рейтинг при рекомендации
    if (rating >= 4.5 && type == PriceRecommendationType.increase) {
      suggestedPrice = suggestedPrice! * 1.15; // Высокий рейтинг позволяет поднять цену
      message += ' (высокий рейтинг позволяет увеличить цену)';
    } else if (rating < 3.5 && type == PriceRecommendationType.decrease) {
      suggestedPrice = suggestedPrice! * 0.9; // Низкий рейтинг требует снижения цены
      message += ' (рекомендуется снизить цену для привлечения клиентов)';
    }

    return PriceRecommendation(
      type: type,
      message: message,
      currentPrice: currentPrice,
      marketAverage: marketAverage,
      suggestedPrice: suggestedPrice,
      confidence: _calculateConfidence(marketMin, marketMax, currentPrice),
    );
  }

  /// Рассчитать уверенность в рекомендации
  double _calculateConfidence(double marketMin, double marketMax, double currentPrice) {
    final marketRange = marketMax - marketMin;
    if (marketRange == 0) return 0.5;
    
    final pricePosition = (currentPrice - marketMin) / marketRange;
    
    // Уверенность выше, если цена сильно отклоняется от нормы
    if (pricePosition < 0.2 || pricePosition > 0.8) {
      return 0.9;
    } else if (pricePosition < 0.3 || pricePosition > 0.7) {
      return 0.7;
    } else {
      return 0.5;
    }
  }
}

/// Тип рекомендации по цене
enum PriceRecommendationType {
  increase,   // Увеличить цену
  decrease,   // Снизить цену
  maintain,   // Оставить как есть
}

/// Рекомендация по цене
class PriceRecommendation {
  const PriceRecommendation({
    required this.type,
    required this.message,
    required this.currentPrice,
    required this.marketAverage,
    this.suggestedPrice,
    required this.confidence,
  });

  final PriceRecommendationType type;
  final String message;
  final double currentPrice;
  final double marketAverage;
  final double? suggestedPrice;
  final double confidence; // 0.0 - 1.0

  /// Получить цвет для отображения
  String get color {
    switch (type) {
      case PriceRecommendationType.increase:
        return 'green';
      case PriceRecommendationType.decrease:
        return 'red';
      case PriceRecommendationType.maintain:
        return 'blue';
    }
  }

  /// Получить иконку
  String get icon {
    switch (type) {
      case PriceRecommendationType.increase:
        return 'trending_up';
      case PriceRecommendationType.decrease:
        return 'trending_down';
      case PriceRecommendationType.maintain:
        return 'trending_flat';
    }
  }
}

/// Запись истории изменения цены
class PriceHistoryEntry {
  const PriceHistoryEntry({
    required this.id,
    required this.specialistId,
    required this.serviceName,
    required this.oldPrice,
    required this.newPrice,
    required this.updatedAt,
    this.reason,
  });

  final String id;
  final String specialistId;
  final String serviceName;
  final double oldPrice;
  final double newPrice;
  final DateTime updatedAt;
  final String? reason;

  /// Рассчитать изменение в процентах
  double get changePercent => ((newPrice - oldPrice) / oldPrice) * 100;

  /// Проверить, увеличилась ли цена
  bool get isIncrease => newPrice > oldPrice;

  /// Проверить, снизилась ли цена
  bool get isDecrease => newPrice < oldPrice;
}
