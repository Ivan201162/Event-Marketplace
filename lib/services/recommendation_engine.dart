import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/feature_flags.dart';
import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/review.dart';
import '../models/specialist.dart';
import '../models/specialist_recommendation.dart';

/// Движок рекомендаций для специалистов
class RecommendationEngine {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить рекомендации для пользователя
  Future<List<SpecialistRecommendation>> getRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    if (!FeatureFlags.recommendationsEnabled) {
      return [];
    }

    try {
      // Получаем историю пользователя
      final userHistory = await _getUserHistory(userId);

      // Анализируем предпочтения
      final preferences = _analyzePreferences(userHistory);

      // Получаем рекомендации на основе предпочтений
      final specialists = await _getSpecialistsByPreferences(
        preferences: preferences,
        excludeIds: userHistory.bookedSpecialistIds,
        limit: limit,
      );

      // Преобразуем в SpecialistRecommendation
      return specialists.map((specialist) {
        return SpecialistRecommendation(
          id: '${userId}_${specialist.id}',
          specialistId: specialist.id,
          reason: 'Рекомендуется на основе ваших предпочтений',
          score: 0.8, // Заглушка
          timestamp: DateTime.now(),
          specialist: specialist,
        );
      }).toList();
    } catch (e) {
      throw Exception('Ошибка получения рекомендаций: $e');
    }
  }

  /// Получить историю пользователя
  Future<UserHistory> _getUserHistory(String userId) async {
    // Получаем бронирования пользователя
    final bookingsSnapshot = await _firestore
        .collection('bookings')
        .where('customerId', isEqualTo: userId)
        .get();

    final bookings = bookingsSnapshot.docs.map(Booking.fromDocument).toList();

    // Получаем отзывы пользователя
    final reviewsSnapshot = await _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .get();

    final reviews = reviewsSnapshot.docs.map(Review.fromDocument).toList();

    // Получаем просмотренные события
    final viewedEventsSnapshot = await _firestore
        .collection('user_activity')
        .doc(userId)
        .collection('viewed_events')
        .get();

    final viewedEventIds =
        viewedEventsSnapshot.docs.map((doc) => doc.id).toList();

    return UserHistory(
      bookings: bookings,
      reviews: reviews,
      viewedEventIds: viewedEventIds,
    );
  }

  /// Анализ предпочтений пользователя
  UserPreferences _analyzePreferences(UserHistory history) {
    final categoryCount = <String, int>{};
    final serviceCount = <String, int>{};
    final locationCount = <String, int>{};
    final priceRange = <int>[];
    final ratingPreferences = <double>[];

    // Анализируем бронирования
    for (final booking in history.bookings) {
      // TODO: Получить категории и услуги из события
      // Пока используем заглушку
      categoryCount['Свадьба'] = (categoryCount['Свадьба'] ?? 0) + 1;
      serviceCount['Фотограф'] = (serviceCount['Фотограф'] ?? 0) + 1;

      priceRange.add(booking.totalPrice.toInt());
    }

    // Анализируем отзывы
    for (final review in history.reviews) {
      ratingPreferences.add(review.rating.toDouble());
    }

    // Определяем предпочтительные категории
    final preferredCategories = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategories =
        preferredCategories.take(3).map((e) => e.key).toList();

    // Определяем предпочтительные услуги
    final preferredServices = serviceCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topServices = preferredServices.take(3).map((e) => e.key).toList();

    // Определяем предпочтительные локации
    final preferredLocations = locationCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topLocations = preferredLocations.take(3).map((e) => e.key).toList();

    // Вычисляем средний бюджет
    final avgBudget = priceRange.isNotEmpty
        ? priceRange.reduce((a, b) => a + b) / priceRange.length
        : 50000;

    // Вычисляем предпочтительный рейтинг
    final avgRating = ratingPreferences.isNotEmpty
        ? ratingPreferences.reduce((a, b) => a + b) / ratingPreferences.length
        : 4.0;

    return UserPreferences(
      preferredCategories: topCategories,
      preferredServices: topServices,
      preferredLocations: topLocations,
      averageBudget: avgBudget.round(),
      preferredRating: avgRating,
    );
  }

  /// Получить специалистов по предпочтениям
  Future<List<Specialist>> _getSpecialistsByPreferences({
    required UserPreferences preferences,
    required List<String> excludeIds,
    int limit = 10,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection('specialists');

    // Фильтр по категориям
    if (preferences.preferredCategories.isNotEmpty) {
      query = query.where(
        'categories',
        arrayContainsAny: preferences.preferredCategories,
      );
    }

    // Фильтр по услугам
    if (preferences.preferredServices.isNotEmpty) {
      query = query.where(
        'services',
        arrayContainsAny: preferences.preferredServices,
      );
    }

    // Фильтр по локациям
    if (preferences.preferredLocations.isNotEmpty) {
      query = query.where('location', whereIn: preferences.preferredLocations);
    }

    // Фильтр по рейтингу
    query = query.where(
      'rating',
      isGreaterThanOrEqualTo: preferences.preferredRating,
    );

    // Фильтр по цене (в пределах бюджета)
    final maxPrice = (preferences.averageBudget * 1.5).round();
    query = query.where('priceFrom', isLessThanOrEqualTo: maxPrice);

    // Сортировка по рейтингу
    query = query.orderBy('rating', descending: true);
    query = query
        .limit(limit * 2); // Берем больше, чтобы исключить уже забронированных

    final snapshot = await query.get();
    final specialists = <Specialist>[];

    for (final doc in snapshot.docs) {
      if (excludeIds.contains(doc.id)) continue;

      final data = doc.data() as Map<String, dynamic>;
      final specialist = Specialist.fromMap(data);
      specialists.add(specialist);

      if (specialists.length >= limit) break;
    }

    return specialists;
  }

  /// Получить популярных специалистов
  Future<List<Specialist>> getPopularSpecialists({
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('specialists')
          .orderBy('rating', descending: true)
          .orderBy('reviewCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Specialist.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения популярных специалистов: $e');
    }
  }

  /// Получить специалистов рядом с пользователем
  Future<List<Specialist>> getNearbySpecialists({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
    int limit = 10,
  }) async {
    try {
      // TODO: Реализовать геопространственный поиск
      // Пока возвращаем всех специалистов
      final snapshot =
          await _firestore.collection('specialists').limit(limit).get();

      return snapshot.docs
          .map((doc) => Specialist.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения ближайших специалистов: $e');
    }
  }
}

/// История пользователя
class UserHistory {
  const UserHistory({
    required this.bookings,
    required this.reviews,
    required this.viewedEventIds,
  });
  final List<Booking> bookings;
  final List<Review> reviews;
  final List<String> viewedEventIds;

  List<String> get bookedSpecialistIds => bookings
      .map((booking) => booking.specialistId)
      .where((id) => id != null)
      .cast<String>()
      .toList();
}

/// Предпочтения пользователя
class UserPreferences {
  const UserPreferences({
    required this.preferredCategories,
    required this.preferredServices,
    required this.preferredLocations,
    required this.averageBudget,
    required this.preferredRating,
  });
  final List<String> preferredCategories;
  final List<String> preferredServices;
  final List<String> preferredLocations;
  final int averageBudget;
  final double preferredRating;
}
