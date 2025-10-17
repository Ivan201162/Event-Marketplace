import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/specialist.dart';
import '../models/user_activity.dart';
import '../services/specialist_service.dart';

/// Сервис для работы с рекомендациями
class RecommendationService {
  static const String _activityCollection = 'userActivity';
  static const String _recommendationsCollection = 'recommendations';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SpecialistService _specialistService = SpecialistService();

  /// Записать активность пользователя
  Future<void> recordActivity({
    required String userId,
    required String category,
    required ActivityType activityType,
    String? specialistId,
    String? city,
    double? price,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection(_activityCollection).add({
        'userId': userId,
        'category': category,
        'specialistId': specialistId,
        'city': city,
        'price': price,
        'activityType': activityType.value,
        'timestamp': Timestamp.now(),
        'metadata': metadata,
      });
    } catch (e) {
      debugPrint('Ошибка записи активности: $e');
    }
  }

  /// Получить активность пользователя
  Future<List<UserActivity>> getUserActivity(
    String userId, {
    int limit = 100,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_activityCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map(UserActivity.fromFirestore).toList();
    } catch (e) {
      debugPrint('Ошибка получения активности пользователя: $e');
      return [];
    }
  }

  /// Получить рекомендации для пользователя
  Future<List<Recommendation>> getRecommendations(String userId) async {
    try {
      // Получаем активность пользователя
      final activities = await getUserActivity(userId);

      if (activities.isEmpty) {
        // Если нет активности, возвращаем популярных специалистов
        return await _getPopularSpecialists(userId);
      }

      // Анализируем активность и генерируем рекомендации
      final recommendations = await _generateRecommendations(userId, activities);

      // Сохраняем рекомендации
      await _saveRecommendations(userId, recommendations);

      return recommendations;
    } catch (e) {
      debugPrint('Ошибка получения рекомендаций: $e');
      return _getPopularSpecialists(userId);
    }
  }

  /// Генерация рекомендаций на основе активности
  Future<List<Recommendation>> _generateRecommendations(
    String userId,
    List<UserActivity> activities,
  ) async {
    // Анализируем категории
    final categoryStats = _analyzeCategories(activities);
    final cityStats = _analyzeCities(activities);
    final priceStats = _analyzePrices(activities);

    // Получаем всех специалистов
    final allSpecialists = await _specialistService.getAllSpecialists();

    // Фильтруем и ранжируем специалистов
    final recommendations = <Recommendation>[];
    final now = DateTime.now();

    for (final specialist in allSpecialists) {
      var score = 0;
      var reason = '';

      // Оценка по категории
      final categoryScore = categoryStats[specialist.category.name] ?? 0.0;
      if (categoryScore > 0) {
        score += (categoryScore * 0.4).round();
        reason += 'Интересуетесь ${specialist.category.displayName}. ';
      }

      // Оценка по городу
      if (cityStats.containsKey(specialist.city)) {
        score += (cityStats[specialist.city]! * 0.3).round();
        reason += 'В вашем городе. ';
      }

      // Оценка по цене
      if (priceStats['min'] != null && priceStats['max'] != null) {
        final avgPrice = (priceStats['min']! + priceStats['max']!) / 2;
        final priceDiff = (specialist.price - avgPrice).abs() / avgPrice;
        if (priceDiff < 0.3) {
          // В пределах 30% от среднего бюджета
          score += 1;
          reason += 'Подходящий ценовой диапазон. ';
        }
      }

      // Оценка по рейтингу
      if (specialist.rating >= 4.5) {
        score += 1;
        reason += 'Высокий рейтинг. ';
      }

      if (score > 0.1) {
        // Минимальный порог для рекомендации
        final confidence = (score * 100).clamp(0.0, 100.0);

        recommendations.add(
          Recommendation(
            id: '${userId}_${specialist.id}',
            userId: userId,
            specialistId: specialist.id,
            specialistName: specialist.name,
            category: specialist.category.name,
            city: specialist.city ?? '',
            price: specialist.price,
            rating: specialist.rating,
            photoUrl: specialist.photoUrl,
            reason: reason.trim(),
            confidence: confidence.toDouble(),
            createdAt: now,
          ),
        );
      }
    }

    // Сортируем по уверенности и возвращаем топ-5
    recommendations.sort((a, b) => b.confidence.compareTo(a.confidence));
    return recommendations.take(5).toList();
  }

  /// Анализ категорий в активности
  Map<String, double> _analyzeCategories(List<UserActivity> activities) {
    final categoryCount = <String, int>{};
    final categoryWeights = <String, double>{
      'booking': 3.0,
      'favorite': 2.5,
      'view': 1.0,
      'search': 0.5,
      'review': 2.0,
      'share': 1.5,
    };

    for (final activity in activities) {
      final weight = categoryWeights[activity.activityType] ?? 1.0;
      categoryCount[activity.category] = (categoryCount[activity.category] ?? 0) + weight.toInt();
    }

    // Нормализуем значения
    final total = categoryCount.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return {};

    return categoryCount.map(
      (category, count) => MapEntry(category, count / total),
    );
  }

  /// Анализ городов в активности
  Map<String, double> _analyzeCities(List<UserActivity> activities) {
    final cityCount = <String, int>{};

    for (final activity in activities) {
      if (activity.city != null) {
        cityCount[activity.city!] = (cityCount[activity.city!] ?? 0) + 1;
      }
    }

    // Нормализуем значения
    final total = cityCount.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return {};

    return cityCount.map(
      (city, count) => MapEntry(city, count / total),
    );
  }

  /// Анализ цен в активности
  Map<String, double> _analyzePrices(List<UserActivity> activities) {
    final prices = activities
        .where((activity) => activity.price != null)
        .map((activity) => activity.price!)
        .toList();

    if (prices.isEmpty) return {};

    prices.sort();
    return {
      'min': prices.first,
      'max': prices.last,
      'avg': prices.reduce((a, b) => a + b) / prices.length,
    };
  }

  /// Получить популярных специалистов
  Future<List<Recommendation>> _getPopularSpecialists(String userId) async {
    try {
      final specialists = await _specialistService.getAllSpecialists();
      final now = DateTime.now();

      // Сортируем по рейтингу и количеству отзывов
      specialists.sort((a, b) {
        final scoreA = a.rating * a.reviewCount;
        final scoreB = b.rating * b.reviewCount;
        return scoreB.compareTo(scoreA);
      });

      return specialists
          .take(5)
          .map(
            (specialist) => Recommendation(
              id: '${userId}_${specialist.id}',
              userId: userId,
              specialistId: specialist.id,
              specialistName: specialist.name,
              category: specialist.category.name,
              city: specialist.city ?? '',
              price: specialist.price,
              rating: specialist.rating,
              photoUrl: specialist.photoUrl,
              reason: 'Популярный специалист с высоким рейтингом',
              confidence: 70,
              createdAt: now,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения популярных специалистов: $e');
      return [];
    }
  }

  /// Сохранить рекомендации
  Future<void> _saveRecommendations(
    String userId,
    List<Recommendation> recommendations,
  ) async {
    try {
      // Удаляем старые рекомендации
      final oldRecommendations = await _firestore
          .collection(_recommendationsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in oldRecommendations.docs) {
        batch.delete(doc.reference);
      }

      // Добавляем новые рекомендации
      for (final recommendation in recommendations) {
        final docRef = _firestore.collection(_recommendationsCollection).doc(recommendation.id);
        batch.set(docRef, recommendation.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Ошибка сохранения рекомендаций: $e');
    }
  }

  /// Получить сохраненные рекомендации
  Future<List<Recommendation>> getSavedRecommendations(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_recommendationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('confidence', descending: true)
          .get();

      return querySnapshot.docs.map(Recommendation.fromFirestore).toList();
    } catch (e) {
      debugPrint('Ошибка получения сохраненных рекомендаций: $e');
      return [];
    }
  }

  /// Очистить старые рекомендации
  Future<void> clearOldRecommendations() async {
    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final querySnapshot = await _firestore
          .collection(_recommendationsCollection)
          .where('createdAt', isLessThan: Timestamp.fromDate(weekAgo))
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      if (querySnapshot.docs.isNotEmpty) {
        await batch.commit();
        debugPrint('Удалено ${querySnapshot.docs.length} старых рекомендаций');
      }
    } catch (e) {
      debugPrint('Ошибка очистки старых рекомендаций: $e');
    }
  }

  /// Получить статистику активности пользователя
  Future<Map<String, dynamic>> getUserActivityStats(String userId) async {
    try {
      final activities = await getUserActivity(userId);

      if (activities.isEmpty) {
        return {
          'totalActivities': 0,
          'categories': {},
          'cities': {},
          'activityTypes': {},
        };
      }

      final categoryStats = <String, int>{};
      final cityStats = <String, int>{};
      final activityTypeStats = <String, int>{};

      for (final activity in activities) {
        categoryStats[activity.category] = (categoryStats[activity.category] ?? 0) + 1;
        if (activity.city != null) {
          cityStats[activity.city!] = (cityStats[activity.city!] ?? 0) + 1;
        }
        activityTypeStats[activity.activityType] =
            (activityTypeStats[activity.activityType] ?? 0) + 1;
      }

      return {
        'totalActivities': activities.length,
        'categories': categoryStats,
        'cities': cityStats,
        'activityTypes': activityTypeStats,
        'lastActivity': activities.isNotEmpty ? activities.first.timestamp : null,
      };
    } catch (e) {
      debugPrint('Ошибка получения статистики активности: $e');
      return {};
    }
  }
}
