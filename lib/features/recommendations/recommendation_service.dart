import 'package:cloud_firestore/cloud_firestore.dart';

import '../bookings/data/models/booking.dart';
import '../specialists/data/models/specialist.dart';

/// Сервис рекомендаций специалистов
class RecommendationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Получить рекомендации для заказчика
  Future<List<Specialist>> getRecommendations({
    required String customerId,
    String? city,
    double? budget,
    String? category,
    int limit = 10,
  }) async {
    try {
      // Получаем историю заказов пользователя для анализа предпочтений
      final userPreferences = await _getUserPreferences(customerId);

      // Базовые рекомендации по категории и городу
      var recommendations = await _getBaseRecommendations(
        city: city ?? userPreferences['city'],
        category: category ?? userPreferences['category'],
        budget: budget ?? userPreferences['budget'],
        limit: limit,
      );

      // Применяем алгоритмы рекомендаций
      recommendations = await _applyRecommendationAlgorithms(
        recommendations,
        userPreferences,
        customerId,
      );

      // Сортируем по релевантности
      recommendations.sort((a, b) {
        final scoreA = _calculateRelevanceScore(a, userPreferences);
        final scoreB = _calculateRelevanceScore(b, userPreferences);
        return scoreB.compareTo(scoreA);
      });

      return recommendations.take(limit).toList();
    } catch (e) {
      throw Exception('Ошибка получения рекомендаций: $e');
    }
  }

  /// Получить похожих специалистов
  Future<List<Specialist>> getSimilarSpecialists({
    required String specialistId,
    int limit = 5,
  }) async {
    try {
      // Получаем данные специалиста
      final specialistDoc =
          await _db.collection('specialists').doc(specialistId).get();
      if (!specialistDoc.exists) {
        return [];
      }

      final specialist = Specialist.fromDocument(specialistDoc);

      // Ищем специалистов с похожими характеристиками
      final similarSpecialists = await _db
          .collection('specialists')
          .where('category', isEqualTo: specialist.category)
          .where('isAvailable', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .limit(limit + 1) // +1 чтобы исключить самого специалиста
          .get();

      final specialists = similarSpecialists.docs
          .map(Specialist.fromDocument)
          .where((s) => s.id != specialistId) // Исключаем самого специалиста
          .toList();

      // Сортируем по рейтингу и цене
      specialists.sort((a, b) {
        // Приоритет: рейтинг, затем цена
        final ratingComparison = b.avgRating.compareTo(a.avgRating);
        if (ratingComparison != 0) return ratingComparison;
        return a.price.compareTo(b.price);
      });

      return specialists.take(limit).toList();
    } catch (e) {
      throw Exception('Ошибка получения похожих специалистов: $e');
    }
  }

  /// Получить топ специалистов по городу
  Future<List<Specialist>> getTopSpecialistsByCity({
    required String city,
    String? category,
    int limit = 10,
  }) async {
    try {
      Query query = _db
          .collection('specialists')
          .where('isAvailable', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .orderBy('avgRating', descending: true)
          .orderBy('reviewsCount', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map(Specialist.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения топ специалистов: $e');
    }
  }

  /// Получить рекомендации по бюджету
  Future<List<Specialist>> getRecommendationsByBudget({
    required double budget,
    String? city,
    String? category,
    int limit = 10,
  }) async {
    try {
      Query query = _db
          .collection('specialists')
          .where('isAvailable', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .where('price', isLessThanOrEqualTo: budget)
          .orderBy('price', descending: true)
          .orderBy('avgRating', descending: true);

      if (city != null) {
        query = query.where('city', isEqualTo: city);
      }

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map(Specialist.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения рекомендаций по бюджету: $e');
    }
  }

  /// Получить предпочтения пользователя на основе истории
  Future<Map<String, dynamic>> _getUserPreferences(String customerId) async {
    try {
      // Получаем завершенные заказы пользователя
      final bookingsSnapshot = await _db
          .collection('bookings')
          .where('customerId', isEqualTo: customerId)
          .where('status', isEqualTo: 'completed')
          .orderBy('eventDate', descending: true)
          .limit(20)
          .get();

      if (bookingsSnapshot.docs.isEmpty) {
        return {
          'city': null,
          'category': null,
          'budget': null,
          'avgPrice': 0.0,
          'preferredSpecialists': <String>[],
        };
      }

      final bookings = bookingsSnapshot.docs.map(Booking.fromDocument).toList();

      // Анализируем предпочтения
      final cities = <String, int>{};
      final categories = <String, int>{};
      final prices = <double>[];
      final specialistIds = <String, int>{};

      for (final booking in bookings) {
        // Получаем данные специалиста
        final specialistDoc =
            await _db.collection('specialists').doc(booking.specialistId).get();
        if (specialistDoc.exists) {
          final specialist = Specialist.fromDocument(specialistDoc);

          // Город
          if (specialist.city != null) {
            cities[specialist.city!] = (cities[specialist.city!] ?? 0) + 1;
          }

          // Категория
          categories[specialist.category] =
              (categories[specialist.category] ?? 0) + 1;

          // Цены
          prices.add(booking.totalPrice);

          // Специалисты
          specialistIds[booking.specialistId] =
              (specialistIds[booking.specialistId] ?? 0) + 1;
        }
      }

      // Определяем наиболее предпочитаемые
      final preferredCity = cities.isNotEmpty
          ? cities.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null;

      final preferredCategory = categories.isNotEmpty
          ? categories.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null;

      final avgPrice = prices.isNotEmpty
          ? prices.reduce((a, b) => a + b) / prices.length
          : 0.0;

      final preferredSpecialists = specialistIds.entries
          .where(
            (entry) => entry.value > 1,
          ) // Специалисты, которых выбирали больше 1 раза
          .map((entry) => entry.key)
          .toList();

      return {
        'city': preferredCity,
        'category': preferredCategory,
        'budget': avgPrice,
        'avgPrice': avgPrice,
        'preferredSpecialists': preferredSpecialists,
        'bookingHistory': bookings.length,
      };
    } catch (e) {
      return {
        'city': null,
        'category': null,
        'budget': null,
        'avgPrice': 0.0,
        'preferredSpecialists': <String>[],
      };
    }
  }

  /// Получить базовые рекомендации
  Future<List<Specialist>> _getBaseRecommendations({
    String? city,
    String? category,
    double? budget,
    int limit = 20,
  }) async {
    Query query = _db
        .collection('specialists')
        .where('isAvailable', isEqualTo: true)
        .where('isVerified', isEqualTo: true);

    if (city != null) {
      query = query.where('city', isEqualTo: city);
    }

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    if (budget != null) {
      query = query.where(
        'price',
        isLessThanOrEqualTo: budget * 1.2,
      ); // +20% к бюджету
    }

    // Сортируем по рейтингу и количеству отзывов
    query = query
        .orderBy('avgRating', descending: true)
        .orderBy('reviewsCount', descending: true);

    final snapshot = await query.limit(limit).get();

    return snapshot.docs.map(Specialist.fromDocument).toList();
  }

  /// Применить алгоритмы рекомендаций
  Future<List<Specialist>> _applyRecommendationAlgorithms(
    List<Specialist> specialists,
    Map<String, dynamic> userPreferences,
    String customerId,
  ) async {
    // Content-based рекомендации
    specialists = _applyContentBasedFiltering(specialists, userPreferences);

    // Collaborative filtering (если есть история)
    if (userPreferences['bookingHistory'] > 0) {
      specialists = await _applyCollaborativeFiltering(specialists, customerId);
    }

    // Популярность и качество
    specialists = _applyPopularityBoost(specialists);

    return specialists;
  }

  /// Content-based фильтрация
  List<Specialist> _applyContentBasedFiltering(
    List<Specialist> specialists,
    Map<String, dynamic> userPreferences,
  ) =>
      specialists.where((specialist) {
        // Проверяем соответствие предпочтениям
        final matchesCity = userPreferences['city'] == null ||
            specialist.city == userPreferences['city'];

        final matchesCategory = userPreferences['category'] == null ||
            specialist.category == userPreferences['category'];

        final matchesBudget = userPreferences['budget'] == null ||
            specialist.price <= userPreferences['budget'] * 1.2;

        return matchesCity && matchesCategory && matchesBudget;
      }).toList();

  /// Collaborative filtering
  Future<List<Specialist>> _applyCollaborativeFiltering(
    List<Specialist> specialists,
    String customerId,
  ) async {
    try {
      // Получаем пользователей с похожими предпочтениями
      final similarUsers = await _findSimilarUsers(customerId);

      if (similarUsers.isEmpty) {
        return specialists;
      }

      // Получаем специалистов, которых выбирали похожие пользователи
      final recommendedSpecialistIds = <String, int>{};

      for (final userId in similarUsers) {
        final userBookings = await _db
            .collection('bookings')
            .where('customerId', isEqualTo: userId)
            .where('status', isEqualTo: 'completed')
            .get();

        for (final doc in userBookings.docs) {
          final booking = Booking.fromDocument(doc);
          recommendedSpecialistIds[booking.specialistId] =
              (recommendedSpecialistIds[booking.specialistId] ?? 0) + 1;
        }
      }

      // Усиливаем рейтинг специалистов, которых выбирали похожие пользователи
      for (final specialist in specialists) {
        final boost = recommendedSpecialistIds[specialist.id] ?? 0;
        if (boost > 0) {
          // Добавляем метаданные для сортировки
          specialist.metadata?['collaborativeBoost'] = boost;
        }
      }

      return specialists;
    } catch (e) {
      return specialists;
    }
  }

  /// Найти похожих пользователей
  Future<List<String>> _findSimilarUsers(String customerId) async {
    try {
      // Получаем предпочтения текущего пользователя
      final currentPreferences = await _getUserPreferences(customerId);

      if (currentPreferences['bookingHistory'] < 3) {
        return []; // Недостаточно данных для поиска похожих пользователей
      }

      // Получаем других пользователей с похожими предпочтениями
      final similarUsers = <String>[];

      // Простая эвристика: пользователи с похожими категориями и городами
      final otherUsers = await _db
          .collection('bookings')
          .where('status', isEqualTo: 'completed')
          .limit(1000)
          .get();

      final userSimilarities = <String, int>{};

      for (final doc in otherUsers.docs) {
        final booking = Booking.fromDocument(doc);
        if (booking.customerId == customerId) continue;

        final otherPreferences = await _getUserPreferences(booking.customerId);

        // Вычисляем схожесть
        var similarity = 0;
        if (currentPreferences['category'] == otherPreferences['category']) {
          similarity += 2;
        }
        if (currentPreferences['city'] == otherPreferences['city']) {
          similarity += 1;
        }

        if (similarity > 0) {
          userSimilarities[booking.customerId] =
              (userSimilarities[booking.customerId] ?? 0) + similarity;
        }
      }

      // Возвращаем топ-5 похожих пользователей
      return userSimilarities.entries
          .where((entry) => entry.value >= 2)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5).map((entry) => entry.key).toList();
    } catch (e) {
      return [];
    }
  }

  /// Усиление по популярности
  List<Specialist> _applyPopularityBoost(List<Specialist> specialists) =>
      specialists.map((specialist) {
        // Усиливаем специалистов с высоким рейтингом и большим количеством отзывов
        var popularityBoost = 0;

        if (specialist.avgRating >= 4.5) {
          popularityBoost += 0.2;
        }

        if (specialist.reviewsCount >= 10) {
          popularityBoost += 0.1;
        }

        if (specialist.isVerified) {
          popularityBoost += 0.1;
        }

        // Добавляем метаданные для сортировки
        specialist.metadata?['popularityBoost'] = popularityBoost;

        return specialist;
      }).toList();

  /// Вычислить релевантность специалиста
  double _calculateRelevanceScore(
    Specialist specialist,
    Map<String, dynamic> preferences,
  ) {
    var score = 0;

    // Базовый рейтинг
    score += specialist.avgRating * 0.3;

    // Количество отзывов (нормализованное)
    score += (specialist.reviewsCount / 100.0).clamp(0.0, 1.0) * 0.2;

    // Соответствие предпочтениям
    if (preferences['city'] == specialist.city) {
      score += 0.2;
    }

    if (preferences['category'] == specialist.category) {
      score += 0.2;
    }

    // Ценовое соответствие
    if (preferences['budget'] != null) {
      final priceRatio = specialist.price / preferences['budget'];
      if (priceRatio <= 1.0) {
        score += 0.1;
      } else if (priceRatio <= 1.2) {
        score += 0.05;
      }
    }

    // Популярность
    score += (specialist.metadata?['popularityBoost'] ?? 0.0) * 0.1;

    // Collaborative boost
    score += (specialist.metadata?['collaborativeBoost'] ?? 0) * 0.05;

    return score;
  }

  /// Получить объяснение рекомендации
  String getRecommendationExplanation(
    Specialist specialist,
    Map<String, dynamic> preferences,
  ) {
    final reasons = <String>[];

    if (specialist.avgRating >= 4.5) {
      reasons.add('высокий рейтинг (${specialist.avgRating})');
    }

    if (specialist.reviewsCount >= 10) {
      reasons.add('много отзывов (${specialist.reviewsCount})');
    }

    if (preferences['city'] == specialist.city) {
      reasons.add('работает в вашем городе');
    }

    if (preferences['category'] == specialist.category) {
      reasons.add('специализируется в нужной категории');
    }

    if (specialist.isVerified) {
      reasons.add('верифицированный специалист');
    }

    if (reasons.isEmpty) {
      return 'Рекомендуется на основе популярности';
    }

    return 'Рекомендуется: ${reasons.join(', ')}';
  }
}
