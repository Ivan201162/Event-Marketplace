import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recommendation.dart';
import '../models/specialist.dart';
import '../models/user.dart';
import '../models/booking.dart';
import '../models/review.dart';

/// Сервис для генерации рекомендаций
class RecommendationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Получить рекомендации для пользователя
  Future<List<SpecialistRecommendation>> getRecommendations(
    String userId, {
    int limit = 10,
    List<RecommendationType>? types,
  }) async {
    try {
      // Получаем существующие рекомендации
      final existingRecommendations = await _getExistingRecommendations(
        userId,
        types: types,
        limit: limit,
      );

      // Если недостаточно рекомендаций, генерируем новые
      if (existingRecommendations.length < limit) {
        final newRecommendations = await _generateRecommendations(
          userId,
          limit: limit - existingRecommendations.length,
          excludeIds: existingRecommendations
              .map((rec) => rec.recommendation.specialistId)
              .toList(),
        );
        existingRecommendations.addAll(newRecommendations);
      }

      return existingRecommendations.take(limit).toList();
    } catch (e) {
      print('Error getting recommendations: $e');
      return [];
    }
  }

  /// Получить существующие рекомендации
  Future<List<SpecialistRecommendation>> _getExistingRecommendations(
    String userId, {
    List<RecommendationType>? types,
    int limit = 10,
  }) async {
    try {
      Query query = _db
          .collection('recommendations')
          .where('userId', isEqualTo: userId)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt')
          .orderBy('score', descending: true)
          .limit(limit);

      if (types != null && types.isNotEmpty) {
        query = query.where('type', whereIn: types.map((t) => t.name).toList());
      }

      final snapshot = await query.get();
      final recommendations = snapshot.docs
          .map((doc) => Recommendation.fromDocument(doc))
          .toList();

      // Получаем данные специалистов
      final specialistRecommendations = <SpecialistRecommendation>[];
      for (final recommendation in recommendations) {
        try {
          final specialistDoc = await _db
              .collection('specialists')
              .doc(recommendation.specialistId)
              .get();
          
          if (specialistDoc.exists) {
            final specialist = Specialist.fromDocument(specialistDoc);
            specialistRecommendations.add(
              SpecialistRecommendation.create(
                recommendation: recommendation,
                specialist: specialist,
              ),
            );
          }
        } catch (e) {
          print('Error getting specialist data: $e');
        }
      }

      return specialistRecommendations;
    } catch (e) {
      print('Error getting existing recommendations: $e');
      return [];
    }
  }

  /// Генерировать новые рекомендации
  Future<List<SpecialistRecommendation>> _generateRecommendations(
    String userId, {
    int limit = 10,
    List<String> excludeIds = const [],
  }) async {
    try {
      final user = await _getUser(userId);
      if (user == null) return [];

      final recommendations = <SpecialistRecommendation>[];

      // 1. Рекомендации на основе истории бронирований
      final historyRecommendations = await _getHistoryBasedRecommendations(
        userId,
        user,
        limit: (limit * 0.4).round(),
        excludeIds: excludeIds,
      );
      recommendations.addAll(historyRecommendations);

      // 2. Рекомендации похожих специалистов
      final similarRecommendations = await _getSimilarSpecialistRecommendations(
        userId,
        user,
        limit: (limit * 0.3).round(),
        excludeIds: excludeIds + recommendations
            .map((rec) => rec.recommendation.specialistId)
            .toList(),
      );
      recommendations.addAll(similarRecommendations);

      // 3. Популярные в категории
      final popularRecommendations = await _getPopularInCategoryRecommendations(
        userId,
        user,
        limit: (limit * 0.2).round(),
        excludeIds: excludeIds + recommendations
            .map((rec) => rec.recommendation.specialistId)
            .toList(),
      );
      recommendations.addAll(popularRecommendations);

      // 4. Рекомендации по местоположению
      final locationRecommendations = await _getLocationBasedRecommendations(
        userId,
        user,
        limit: (limit * 0.1).round(),
        excludeIds: excludeIds + recommendations
            .map((rec) => rec.recommendation.specialistId)
            .toList(),
      );
      recommendations.addAll(locationRecommendations);

      // Сохраняем новые рекомендации
      await _saveRecommendations(recommendations);

      return recommendations;
    } catch (e) {
      print('Error generating recommendations: $e');
      return [];
    }
  }

  /// Получить рекомендации на основе истории
  Future<List<SpecialistRecommendation>> _getHistoryBasedRecommendations(
    String userId,
    AppUser user, {
    int limit = 4,
    List<String> excludeIds = const [],
  }) async {
    try {
      // Получаем историю бронирований пользователя
      final bookingsSnapshot = await _db
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      if (bookingsSnapshot.docs.isEmpty) return [];

      // Анализируем предпочтения пользователя
      final preferences = await _analyzeUserPreferences(bookingsSnapshot.docs);

      // Ищем специалистов с похожими характеристиками
      final specialists = await _findSpecialistsByPreferences(
        preferences,
        excludeIds: excludeIds,
        limit: limit,
      );

      return specialists.map((specialist) {
        final recommendation = Recommendation(
          id: '',
          userId: userId,
          specialistId: specialist.id,
          type: RecommendationType.basedOnHistory,
          score: _calculateHistoryScore(specialist, preferences),
          reason: 'На основе ваших предыдущих заказов',
          metadata: preferences,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        return SpecialistRecommendation.create(
          recommendation: recommendation,
          specialist: specialist,
        );
      }).toList();
    } catch (e) {
      print('Error getting history-based recommendations: $e');
      return [];
    }
  }

  /// Получить рекомендации похожих специалистов
  Future<List<SpecialistRecommendation>> _getSimilarSpecialistRecommendations(
    String userId,
    AppUser user, {
    int limit = 3,
    List<String> excludeIds = const [],
  }) async {
    try {
      // Получаем последнего забронированного специалиста
      final lastBookingSnapshot = await _db
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (lastBookingSnapshot.docs.isEmpty) return [];

      final lastBooking = Booking.fromDocument(lastBookingSnapshot.docs.first);
      final lastSpecialistDoc = await _db
          .collection('specialists')
          .doc(lastBooking.specialistId)
          .get();

      if (!lastSpecialistDoc.exists) return [];

      final lastSpecialist = Specialist.fromDocument(lastSpecialistDoc);

      // Ищем похожих специалистов
      final similarSpecialists = await _findSimilarSpecialists(
        lastSpecialist,
        excludeIds: excludeIds,
        limit: limit,
      );

      return similarSpecialists.map((specialist) {
        final recommendation = Recommendation(
          id: '',
          userId: userId,
          specialistId: specialist.id,
          type: RecommendationType.similarSpecialists,
          score: _calculateSimilarityScore(specialist, lastSpecialist),
          reason: 'Похож на ${lastSpecialist.name}',
          metadata: {
            'similarTo': lastSpecialist.id,
            'similarity': _calculateSimilarityScore(specialist, lastSpecialist),
          },
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        return SpecialistRecommendation.create(
          recommendation: recommendation,
          specialist: specialist,
        );
      }).toList();
    } catch (e) {
      print('Error getting similar specialist recommendations: $e');
      return [];
    }
  }

  /// Получить популярных в категории
  Future<List<SpecialistRecommendation>> _getPopularInCategoryRecommendations(
    String userId,
    AppUser user, {
    int limit = 2,
    List<String> excludeIds = const [],
  }) async {
    try {
      // Получаем самую популярную категорию пользователя
      final popularCategory = await _getUserPopularCategory(userId);
      if (popularCategory == null) return [];

      // Ищем популярных специалистов в этой категории
      final popularSpecialists = await _db
          .collection('specialists')
          .where('category', isEqualTo: popularCategory.name)
          .where('isAvailable', isEqualTo: true)
          .orderBy('rating', descending: true)
          .orderBy('reviewCount', descending: true)
          .limit(limit)
          .get();

      return popularSpecialists.docs
          .where((doc) => !excludeIds.contains(doc.id))
          .map((doc) {
            final specialist = Specialist.fromDocument(doc);
            final recommendation = Recommendation(
              id: '',
              userId: userId,
              specialistId: specialist.id,
              type: RecommendationType.popularInCategory,
              score: specialist.rating * 0.8 + (specialist.reviewCount / 100) * 0.2,
              reason: 'Популярный в категории ${specialist.categoryDisplayName}',
              metadata: {
                'category': popularCategory.name,
                'rating': specialist.rating,
                'reviewCount': specialist.reviewCount,
              },
              createdAt: DateTime.now(),
              expiresAt: DateTime.now().add(const Duration(days: 7)),
            );

            return SpecialistRecommendation.create(
              recommendation: recommendation,
              specialist: specialist,
            );
          })
          .toList();
    } catch (e) {
      print('Error getting popular in category recommendations: $e');
      return [];
    }
  }

  /// Получить рекомендации по местоположению
  Future<List<SpecialistRecommendation>> _getLocationBasedRecommendations(
    String userId,
    AppUser user, {
    int limit = 1,
    List<String> excludeIds = const [],
  }) async {
    try {
      // Получаем местоположение пользователя (если доступно)
      final userLocation = user.location;
      if (userLocation == null) return [];

      // Ищем специалистов в том же городе
      final nearbySpecialists = await _db
          .collection('specialists')
          .where('serviceAreas', arrayContains: userLocation)
          .where('isAvailable', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return nearbySpecialists.docs
          .where((doc) => !excludeIds.contains(doc.id))
          .map((doc) {
            final specialist = Specialist.fromDocument(doc);
            final recommendation = Recommendation(
              id: '',
              userId: userId,
              specialistId: specialist.id,
              type: RecommendationType.nearby,
              score: specialist.rating * 0.9 + 0.1, // Бонус за близость
              reason: 'Работает в вашем городе',
              metadata: {
                'location': userLocation,
                'rating': specialist.rating,
              },
              createdAt: DateTime.now(),
              expiresAt: DateTime.now().add(const Duration(days: 7)),
            );

            return SpecialistRecommendation.create(
              recommendation: recommendation,
              specialist: specialist,
            );
          })
          .toList();
    } catch (e) {
      print('Error getting location-based recommendations: $e');
      return [];
    }
  }

  /// Анализировать предпочтения пользователя
  Future<Map<String, dynamic>> _analyzeUserPreferences(
    List<QueryDocumentSnapshot> bookings,
  ) async {
    final preferences = <String, dynamic>{
      'categories': <String, int>{},
      'priceRange': <double, int>{},
      'ratings': <double, int>{},
      'totalBookings': bookings.length,
    };

    for (final bookingDoc in bookings) {
      try {
        final specialistDoc = await _db
            .collection('specialists')
            .doc(bookingDoc.data()['specialistId'] as String)
            .get();

        if (specialistDoc.exists) {
          final specialist = Specialist.fromDocument(specialistDoc);
          
          // Анализируем категории
          final category = specialist.category.name;
          preferences['categories'][category] = 
              (preferences['categories'][category] ?? 0) + 1;

          // Анализируем ценовой диапазон
          final priceRange = (specialist.hourlyRate / 1000).floor() * 1000;
          preferences['priceRange'][priceRange.toDouble()] = 
              (preferences['priceRange'][priceRange.toDouble()] ?? 0) + 1;

          // Анализируем рейтинги
          final ratingRange = (specialist.rating / 0.5).floor() * 0.5;
          preferences['ratings'][ratingRange] = 
              (preferences['ratings'][ratingRange] ?? 0) + 1;
        }
      } catch (e) {
        print('Error analyzing booking: $e');
      }
    }

    return preferences;
  }

  /// Найти специалистов по предпочтениям
  Future<List<Specialist>> _findSpecialistsByPreferences(
    Map<String, dynamic> preferences, {
    List<String> excludeIds = const [],
    int limit = 10,
  }) async {
    try {
      // Получаем самую популярную категорию
      final categories = preferences['categories'] as Map<String, int>;
      if (categories.isEmpty) return [];

      final popularCategory = categories.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      // Получаем предпочтительный ценовой диапазон
      final priceRanges = preferences['priceRange'] as Map<double, int>;
      final popularPriceRange = priceRanges.isNotEmpty
          ? priceRanges.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 5000.0;

      // Ищем специалистов
      final specialistsSnapshot = await _db
          .collection('specialists')
          .where('category', isEqualTo: popularCategory)
          .where('isAvailable', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit * 2) // Берём больше, чтобы отфильтровать
          .get();

      return specialistsSnapshot.docs
          .where((doc) => !excludeIds.contains(doc.id))
          .map((doc) => Specialist.fromDocument(doc))
          .where((specialist) {
            // Фильтруем по ценовому диапазону (±50%)
            final priceDiff = (specialist.hourlyRate - popularPriceRange).abs();
            return priceDiff <= popularPriceRange * 0.5;
          })
          .take(limit)
          .toList();
    } catch (e) {
      print('Error finding specialists by preferences: $e');
      return [];
    }
  }

  /// Найти похожих специалистов
  Future<List<Specialist>> _findSimilarSpecialists(
    Specialist referenceSpecialist, {
    List<String> excludeIds = const [],
    int limit = 10,
  }) async {
    try {
      final specialistsSnapshot = await _db
          .collection('specialists')
          .where('category', isEqualTo: referenceSpecialist.category.name)
          .where('isAvailable', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit * 2)
          .get();

      return specialistsSnapshot.docs
          .where((doc) => !excludeIds.contains(doc.id))
          .map((doc) => Specialist.fromDocument(doc))
          .where((specialist) => specialist.id != referenceSpecialist.id)
          .take(limit)
          .toList();
    } catch (e) {
      print('Error finding similar specialists: $e');
      return [];
    }
  }

  /// Получить самую популярную категорию пользователя
  Future<SpecialistCategory?> _getUserPopularCategory(String userId) async {
    try {
      final bookingsSnapshot = await _db
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      if (bookingsSnapshot.docs.isEmpty) return null;

      final categoryCounts = <String, int>{};

      for (final bookingDoc in bookingsSnapshot.docs) {
        try {
          final specialistDoc = await _db
              .collection('specialists')
              .doc(bookingDoc.data()['specialistId'] as String)
              .get();

          if (specialistDoc.exists) {
            final category = specialistDoc.data()?['category'] as String?;
            if (category != null) {
              categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
            }
          }
        } catch (e) {
          print('Error getting specialist category: $e');
        }
      }

      if (categoryCounts.isEmpty) return null;

      final popularCategoryName = categoryCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      return SpecialistCategory.values.firstWhere(
        (cat) => cat.name == popularCategoryName,
        orElse: () => SpecialistCategory.other,
      );
    } catch (e) {
      print('Error getting user popular category: $e');
      return null;
    }
  }

  /// Вычислить оценку на основе истории
  double _calculateHistoryScore(Specialist specialist, Map<String, dynamic> preferences) {
    double score = specialist.rating * 0.4;

    // Бонус за популярную категорию
    final categories = preferences['categories'] as Map<String, int>;
    if (categories.containsKey(specialist.category.name)) {
      score += 0.3;
    }

    // Бонус за подходящий ценовой диапазон
    final priceRanges = preferences['priceRange'] as Map<double, int>;
    if (priceRanges.isNotEmpty) {
      final popularPriceRange = priceRanges.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      final priceDiff = (specialist.hourlyRate - popularPriceRange).abs();
      if (priceDiff <= popularPriceRange * 0.3) {
        score += 0.3;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  /// Вычислить оценку схожести
  double _calculateSimilarityScore(Specialist specialist1, Specialist specialist2) {
    double score = 0.0;

    // Схожесть категории
    if (specialist1.category == specialist2.category) {
      score += 0.4;
    }

    // Схожесть уровня опыта
    if (specialist1.experienceLevel == specialist2.experienceLevel) {
      score += 0.2;
    }

    // Схожесть ценового диапазона
    final priceDiff = (specialist1.hourlyRate - specialist2.hourlyRate).abs();
    final avgPrice = (specialist1.hourlyRate + specialist2.hourlyRate) / 2;
    if (priceDiff <= avgPrice * 0.3) {
      score += 0.2;
    }

    // Схожесть рейтинга
    final ratingDiff = (specialist1.rating - specialist2.rating).abs();
    if (ratingDiff <= 0.5) {
      score += 0.2;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Сохранить рекомендации
  Future<void> _saveRecommendations(List<SpecialistRecommendation> recommendations) async {
    try {
      final batch = _db.batch();
      
      for (final recommendation in recommendations) {
        final docRef = _db.collection('recommendations').doc();
        batch.set(docRef, recommendation.recommendation.toMap());
      }
      
      await batch.commit();
    } catch (e) {
      print('Error saving recommendations: $e');
    }
  }

  /// Получить пользователя
  Future<AppUser?> _getUser(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return AppUser.fromDocument(userDoc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  /// Обновить рекомендации для пользователя
  Future<void> refreshRecommendations(String userId) async {
    try {
      // Удаляем старые рекомендации
      await _db
          .collection('recommendations')
          .where('userId', isEqualTo: userId)
          .get()
          .then((snapshot) {
        final batch = _db.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        return batch.commit();
      });

      // Генерируем новые рекомендации
      await getRecommendations(userId, limit: 20);
    } catch (e) {
      print('Error refreshing recommendations: $e');
    }
  }
}
