import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/enhanced_specialist.dart';
import '../models/enhanced_specialist_category.dart';

/// Сервис AI-рекомендаций
class AIRecommendationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Получить персональные рекомендации на основе анализа заказов
  Future<List<SpecialistRecommendation>> getPersonalizedRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    try {
      // Получаем профиль пользователя и историю заказов
      final userProfile = await _getUserProfile(userId);
      final orderHistory = await _getUserOrderHistory(userId);
      final userPreferences = await _getUserPreferences(userId);

      // Анализируем поведение пользователя
      final behaviorAnalysis = _analyzeUserBehavior(orderHistory, userProfile);
      
      // Генерируем рекомендации
      final recommendations = await _generateRecommendations(
        userId: userId,
        behaviorAnalysis: behaviorAnalysis,
        userPreferences: userPreferences,
        limit: limit,
      );

      return recommendations;
    } catch (e) {
      debugPrint('Ошибка получения персональных рекомендаций: $e');
      return [];
    }
  }

  /// Получить рекомендации для конкретного события
  Future<List<SpecialistRecommendation>> getEventRecommendations({
    required String eventType,
    required String location,
    required DateTime eventDate,
    required double budget,
    Map<String, dynamic>? eventDetails,
  }) async {
    try {
      // Определяем необходимые категории для события
      final requiredCategories = _getRequiredCategoriesForEvent(eventType, eventDetails);
      
      // Ищем специалистов по категориям
      final specialists = await _searchSpecialistsForEvent(
        categories: requiredCategories,
        location: location,
        eventDate: eventDate,
        budget: budget,
      );

      // Ранжируем специалистов
      final rankedSpecialists = _rankSpecialistsForEvent(
        specialists: specialists,
        eventType: eventType,
        location: location,
        budget: budget,
        eventDetails: eventDetails,
      );

      return rankedSpecialists;
    } catch (e) {
      debugPrint('Ошибка получения рекомендаций для события: $e');
      return [];
    }
  }

  /// Smart Upsell - предложение дополнительных услуг
  Future<List<UpsellRecommendation>> getUpsellRecommendations({
    required String userId,
    required String currentServiceId,
    required double currentBudget,
  }) async {
    try {
      // Получаем информацию о текущем заказе
      final currentService = await _getServiceInfo(currentServiceId);
      if (currentService == null) return [];

      // Анализируем совместимые услуги
      final compatibleServices = await _findCompatibleServices(currentService);
      
      // Фильтруем по бюджету (предлагаем услуги в пределах 20-50% от текущего бюджета)
      final budgetRange = currentBudget * 0.2;
      final filteredServices = compatibleServices.where((service) {
        final servicePrice = service.averagePrice;
        return servicePrice <= budgetRange && servicePrice >= budgetRange * 0.5;
      }).toList();

      // Сортируем по популярности и совместимости
      filteredServices.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));

      return filteredServices.take(5).map((service) => UpsellRecommendation(
        service: service,
        reason: _generateUpsellReason(service, currentService),
        estimatedValue: _calculateEstimatedValue(service, currentService),
      )).toList();
    } catch (e) {
      debugPrint('Ошибка получения upsell рекомендаций: $e');
      return [];
    }
  }

  /// Получить профиль пользователя
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final doc = await _db.collection('customer_profiles').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('Ошибка получения профиля пользователя: $e');
      return null;
    }
  }

  /// Получить историю заказов пользователя
  Future<List<Map<String, dynamic>>> _getUserOrderHistory(String userId) async {
    try {
      final query = await _db
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      return query.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Ошибка получения истории заказов: $e');
      return [];
    }
  }

  /// Получить предпочтения пользователя
  Future<Map<String, dynamic>> _getUserPreferences(String userId) async {
    try {
      final doc = await _db.collection('user_preferences').doc(userId).get();
      return doc.exists ? doc.data()! : {};
    } catch (e) {
      debugPrint('Ошибка получения предпочтений пользователя: $e');
      return {};
    }
  }

  /// Анализ поведения пользователя
  UserBehaviorAnalysis _analyzeUserBehavior(
    List<Map<String, dynamic>> orderHistory,
    Map<String, dynamic>? userProfile,
  ) {
    final categoryFrequency = <EnhancedSpecialistCategory, int>{};
    final priceHistory = <double>[];
    final locationFrequency = <String, int>{};
    final seasonalPatterns = <int, int>{}; // месяц -> количество заказов
    final timePatterns = <int, int>{}; // час -> количество заказов

    for (final order in orderHistory) {
      // Анализ категорий
      final category = order['category'] as String?;
      if (category != null) {
        final categoryEnum = EnhancedSpecialistCategory.values.firstWhere(
          (cat) => cat.name == category,
          orElse: () => EnhancedSpecialistCategory.photography,
        );
        categoryFrequency[categoryEnum] = (categoryFrequency[categoryEnum] ?? 0) + 1;
      }

      // Анализ цен
      final price = (order['totalPrice'] as num?)?.toDouble();
      if (price != null) {
        priceHistory.add(price);
      }

      // Анализ местоположения
      final location = order['location'] as String?;
      if (location != null) {
        locationFrequency[location] = (locationFrequency[location] ?? 0) + 1;
      }

      // Анализ сезонности
      final createdAt = order['createdAt'] as Timestamp?;
      if (createdAt != null) {
        final month = createdAt.toDate().month;
        seasonalPatterns[month] = (seasonalPatterns[month] ?? 0) + 1;
      }
    }

    // Определяем предпочитаемые категории
    final sortedCategories = categoryFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(3).map((e) => e.key).toList();

    // Определяем предпочитаемое местоположение
    final sortedLocations = locationFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final preferredLocation = sortedLocations.isNotEmpty ? sortedLocations.first.key : null;

    // Рассчитываем средний бюджет
    final averageBudget = priceHistory.isNotEmpty 
        ? priceHistory.reduce((a, b) => a + b) / priceHistory.length 
        : 0.0;

    return UserBehaviorAnalysis(
      topCategories: topCategories,
      preferredLocation: preferredLocation,
      averageBudget: averageBudget,
      priceRange: priceHistory.isNotEmpty 
          ? PriceRange(
              min: priceHistory.reduce((a, b) => a < b ? a : b),
              max: priceHistory.reduce((a, b) => a > b ? a : b),
              currency: 'RUB',
            )
          : null,
      seasonalPatterns: seasonalPatterns,
      totalOrders: orderHistory.length,
      isNewUser: orderHistory.length < 3,
    );
  }

  /// Генерация рекомендаций
  Future<List<SpecialistRecommendation>> _generateRecommendations({
    required String userId,
    required UserBehaviorAnalysis behaviorAnalysis,
    required Map<String, dynamic> userPreferences,
    required int limit,
  }) async {
    final recommendations = <SpecialistRecommendation>[];

    // Рекомендации на основе предпочитаемых категорий
    for (final category in behaviorAnalysis.topCategories) {
      final specialists = await _searchSpecialistsByCategory(
        category: category,
        location: behaviorAnalysis.preferredLocation,
        minRating: 4.0,
        limit: 3,
      );

      for (final specialist in specialists) {
        final score = _calculateRecommendationScore(
          specialist: specialist,
          behaviorAnalysis: behaviorAnalysis,
          userPreferences: userPreferences,
        );

        recommendations.add(SpecialistRecommendation(
          specialist: specialist,
          score: score,
          reason: _generateRecommendationReason(specialist, behaviorAnalysis),
          category: category,
        ));
      }
    }

    // Рекомендации для новых пользователей (популярные специалисты)
    if (behaviorAnalysis.isNewUser) {
      final popularSpecialists = await _getPopularSpecialists(limit: 5);
      for (final specialist in popularSpecialists) {
        final score = 0.7; // Базовый балл для популярных специалистов
        recommendations.add(SpecialistRecommendation(
          specialist: specialist,
          score: score,
          reason: 'Популярный специалист в вашем регионе',
          category: specialist.categories.isNotEmpty ? specialist.categories.first : null,
        ));
      }
    }

    // Сортируем по баллу и возвращаем топ рекомендации
    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(limit).toList();
  }

  /// Определение необходимых категорий для события
  List<EnhancedSpecialistCategory> _getRequiredCategoriesForEvent(
    String eventType,
    Map<String, dynamic>? eventDetails,
  ) {
    final categories = <EnhancedSpecialistCategory>[];

    switch (eventType.toLowerCase()) {
      case 'wedding':
        categories.addAll([
          EnhancedSpecialistCategory.photography,
          EnhancedSpecialistCategory.videography,
          EnhancedSpecialistCategory.music,
          EnhancedSpecialistCategory.catering,
          EnhancedSpecialistCategory.decoration,
          EnhancedSpecialistCategory.florist,
          EnhancedSpecialistCategory.makeupArtist,
          EnhancedSpecialistCategory.stylist,
        ]);
        break;
      case 'corporate':
        categories.addAll([
          EnhancedSpecialistCategory.photography,
          EnhancedSpecialistCategory.videography,
          EnhancedSpecialistCategory.catering,
          EnhancedSpecialistCategory.equipment,
          EnhancedSpecialistCategory.transport,
        ]);
        break;
      case 'birthday':
        categories.addAll([
          EnhancedSpecialistCategory.photography,
          EnhancedSpecialistCategory.animator,
          EnhancedSpecialistCategory.catering,
          EnhancedSpecialistCategory.decoration,
          EnhancedSpecialistCategory.entertainment,
        ]);
        break;
      case 'conference':
        categories.addAll([
          EnhancedSpecialistCategory.photography,
          EnhancedSpecialistCategory.videography,
          EnhancedSpecialistCategory.equipment,
          EnhancedSpecialistCategory.catering,
        ]);
        break;
      default:
        categories.addAll([
          EnhancedSpecialistCategory.photography,
          EnhancedSpecialistCategory.videography,
          EnhancedSpecialistCategory.music,
        ]);
    }

    return categories;
  }

  /// Поиск специалистов для события
  Future<List<EnhancedSpecialist>> _searchSpecialistsForEvent({
    required List<EnhancedSpecialistCategory> categories,
    required String location,
    required DateTime eventDate,
    required double budget,
  }) async {
    // Здесь должна быть логика поиска специалистов
    // Для демонстрации возвращаем пустой список
    return [];
  }

  /// Ранжирование специалистов для события
  List<SpecialistRecommendation> _rankSpecialistsForEvent({
    required List<EnhancedSpecialist> specialists,
    required String eventType,
    required String location,
    required double budget,
    Map<String, dynamic>? eventDetails,
  }) {
    // Здесь должна быть логика ранжирования
    // Для демонстрации возвращаем пустой список
    return [];
  }

  /// Получение информации об услуге
  Future<Map<String, dynamic>?> _getServiceInfo(String serviceId) async {
    try {
      final doc = await _db.collection('services').doc(serviceId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('Ошибка получения информации об услуге: $e');
      return null;
    }
  }

  /// Поиск совместимых услуг
  Future<List<CompatibleService>> _findCompatibleServices(Map<String, dynamic> currentService) async {
    // Здесь должна быть логика поиска совместимых услуг
    // Для демонстрации возвращаем пустой список
    return [];
  }

  /// Генерация причины для upsell
  String _generateUpsellReason(CompatibleService service, Map<String, dynamic> currentService) {
    return 'Дополнительная услуга, которая отлично дополняет ваш заказ';
  }

  /// Расчет оценочной стоимости
  double _calculateEstimatedValue(CompatibleService service, Map<String, dynamic> currentService) {
    return service.averagePrice;
  }

  /// Поиск специалистов по категории
  Future<List<EnhancedSpecialist>> _searchSpecialistsByCategory({
    required EnhancedSpecialistCategory category,
    String? location,
    double? minRating,
    int limit = 10,
  }) async {
    // Здесь должна быть логика поиска специалистов
    // Для демонстрации возвращаем пустой список
    return [];
  }

  /// Получение популярных специалистов
  Future<List<EnhancedSpecialist>> _getPopularSpecialists({int limit = 10}) async {
    // Здесь должна быть логика получения популярных специалистов
    // Для демонстрации возвращаем пустой список
    return [];
  }

  /// Расчет балла рекомендации
  double _calculateRecommendationScore({
    required EnhancedSpecialist specialist,
    required UserBehaviorAnalysis behaviorAnalysis,
    required Map<String, dynamic> userPreferences,
  }) {
    double score = 0.0;

    // Балл за рейтинг
    score += specialist.rating * 0.3;

    // Балл за количество отзывов
    score += (specialist.reviewsCount / 100.0) * 0.2;

    // Балл за соответствие предпочитаемым категориям
    if (behaviorAnalysis.topCategories.contains(specialist.categories.first)) {
      score += 0.3;
    }

    // Балл за местоположение
    if (specialist.location == behaviorAnalysis.preferredLocation) {
      score += 0.2;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Генерация причины рекомендации
  String _generateRecommendationReason(
    EnhancedSpecialist specialist,
    UserBehaviorAnalysis behaviorAnalysis,
  ) {
    final reasons = <String>[];

    if (specialist.rating >= 4.5) {
      reasons.add('Высокий рейтинг');
    }

    if (specialist.reviewsCount > 50) {
      reasons.add('Много отзывов');
    }

    if (behaviorAnalysis.topCategories.contains(specialist.categories.first)) {
      reasons.add('Соответствует вашим предпочтениям');
    }

    if (specialist.location == behaviorAnalysis.preferredLocation) {
      reasons.add('В вашем регионе');
    }

    return reasons.isNotEmpty ? reasons.join(', ') : 'Рекомендуется для вас';
  }
}

/// Анализ поведения пользователя
class UserBehaviorAnalysis {
  const UserBehaviorAnalysis({
    required this.topCategories,
    this.preferredLocation,
    required this.averageBudget,
    this.priceRange,
    required this.seasonalPatterns,
    required this.totalOrders,
    required this.isNewUser,
  });

  final List<EnhancedSpecialistCategory> topCategories;
  final String? preferredLocation;
  final double averageBudget;
  final PriceRange? priceRange;
  final Map<int, int> seasonalPatterns;
  final int totalOrders;
  final bool isNewUser;
}

/// Рекомендация специалиста
class SpecialistRecommendation {
  const SpecialistRecommendation({
    required this.specialist,
    required this.score,
    required this.reason,
    this.category,
  });

  final EnhancedSpecialist specialist;
  final double score;
  final String reason;
  final EnhancedSpecialistCategory? category;
}

/// Совместимая услуга
class CompatibleService {
  const CompatibleService({
    required this.id,
    required this.name,
    required this.category,
    required this.averagePrice,
    required this.compatibilityScore,
  });

  final String id;
  final String name;
  final String category;
  final double averagePrice;
  final double compatibilityScore;
}

/// Upsell рекомендация
class UpsellRecommendation {
  const UpsellRecommendation({
    required this.service,
    required this.reason,
    required this.estimatedValue,
  });

  final CompatibleService service;
  final String reason;
  final double estimatedValue;
}
