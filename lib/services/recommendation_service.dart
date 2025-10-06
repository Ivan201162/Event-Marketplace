import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking.dart';
import '../models/recommendation.dart';
import '../models/specialist.dart';

/// Сервис для работы с рекомендациями специалистов
class RecommendationService {
  factory RecommendationService() => _instance;
  RecommendationService._internal();
  static final RecommendationService _instance =
      RecommendationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить рекомендации для пользователя
  Future<List<Recommendation>> getRecommendationsForUser(String userId) async {
    try {
      // Проверяем, есть ли у пользователя история заказов
      final hasOrderHistory = await _hasOrderHistory(userId);

      if (hasOrderHistory) {
        // Если есть история - используем персонализированные рекомендации
        return await _getPersonalizedRecommendations(userId);
      } else {
        // Если нет истории - показываем популярных специалистов
        return await _getPopularRecommendations(userId);
      }
    } catch (e) {
      print('Ошибка получения рекомендаций: $e');
      return _getPopularRecommendations(userId);
    }
  }

  /// Получить популярных специалистов
  Future<List<Recommendation>> getPopularSpecialists({String? userId}) async {
    try {
      // Получаем специалистов, отсортированных по количеству заказов и рейтингу
      final specialistsSnapshot = await _firestore
          .collection('specialists')
          .where('isAvailable', isEqualTo: true)
          .orderBy('totalBookings', descending: true)
          .orderBy('rating', descending: true)
          .limit(20)
          .get();

      final recommendations = <Recommendation>[];

      for (var i = 0; i < specialistsSnapshot.docs.length; i++) {
        final doc = specialistsSnapshot.docs[i];
        final specialist = Specialist.fromDocument(doc);

        // Рассчитываем оценку популярности
        final popularityScore = _calculatePopularityScore(specialist, i);

        final recommendation = Recommendation(
          id: '${userId ?? 'anonymous'}_${specialist.id}_popular',
          userId: userId ?? 'anonymous',
          specialistId: specialist.id,
          specialist: specialist,
          type: RecommendationType.popular,
          score: popularityScore,
          reason: 'Популярный специалист с высоким рейтингом',
          createdAt: DateTime.now(),
          category: specialist.category.name,
          location: specialist.location,
          priceRange: specialist.priceRangeString,
          rating: specialist.rating,
          bookingCount: specialist.totalBookings ?? 0,
        );

        recommendations.add(recommendation);
      }

      return recommendations;
    } catch (e) {
      print('Ошибка получения популярных специалистов: $e');
      return [];
    }
  }

  /// Получить рекомендации на основе истории заказов
  Future<List<Recommendation>> getRecommendationsBasedOnHistory(
    String userId,
  ) async {
    try {
      // Получаем историю заказов пользователя
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .orderBy('eventDate', descending: true)
          .limit(10)
          .get();

      if (bookingsSnapshot.docs.isEmpty) {
        return await getPopularSpecialists(userId: userId);
      }

      // Анализируем категории заказов
      final categoryPreferences = <String, int>{};
      final specialistIds = <String>{};

      for (final doc in bookingsSnapshot.docs) {
        final booking = Booking.fromDocument(doc);
        specialistIds.add(booking.specialistId);
      }

      // Получаем информацию о специалистах из истории
      final specialists = <Specialist>[];
      for (final specialistId in specialistIds) {
        final specialistDoc =
            await _firestore.collection('specialists').doc(specialistId).get();
        if (specialistDoc.exists) {
          specialists.add(Specialist.fromDocument(specialistDoc));
        }
      }

      // Анализируем предпочтения по категориям
      for (final specialist in specialists) {
        final category = specialist.category.name;
        categoryPreferences[category] =
            (categoryPreferences[category] ?? 0) + 1;
      }

      // Получаем рекомендации на основе предпочтений
      // return await _getRecommendationsByCategories(userId, categoryPreferences);
      // Временная заглушка - возвращаем пустой список
      return [];
    } catch (e) {
      print('Ошибка получения рекомендаций на основе истории: $e');
      return getPopularSpecialists(userId: userId);
    }
  }

  /// Получить рекомендации по категориям
  Future<List<Recommendation>> getRecommendationsByCategories(
    String userId,
    Map<String, int> categoryPreferences,
  ) async {
    try {
      final recommendations = <Recommendation>[];

      // Сортируем категории по популярности
      final sortedCategories = categoryPreferences.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final categoryEntry in sortedCategories.take(3)) {
        final category = categoryEntry.key;

        // Получаем специалистов в этой категории
        final specialistsSnapshot = await _firestore
            .collection('specialists')
            .where('category', isEqualTo: category)
            .where('isAvailable', isEqualTo: true)
            .orderBy('rating', descending: true)
            .limit(5)
            .get();

        for (var i = 0; i < specialistsSnapshot.docs.length; i++) {
          final doc = specialistsSnapshot.docs[i];
          final specialist = Specialist.fromDocument(doc);

          // Рассчитываем оценку релевантности
          final relevanceScore = _calculateRelevanceScore(
            specialist,
            categoryPreferences,
            i,
          );

          final recommendation = Recommendation(
            id: '${userId}_${specialist.id}_category_$category',
            userId: userId,
            specialistId: specialist.id,
            specialist: specialist,
            type: RecommendationType.categoryBased,
            score: relevanceScore,
            reason:
                'В категории "${specialist.category.displayName}", которую вы часто заказываете',
            createdAt: DateTime.now(),
            category: category,
            location: specialist.location,
            priceRange: specialist.priceRangeString,
            rating: specialist.rating,
            bookingCount: specialist.totalBookings ?? 0,
          );

          recommendations.add(recommendation);
        }
      }

      // Сортируем по релевантности
      recommendations.sort((a, b) => b.score.compareTo(a.score));

      return recommendations.take(15).toList();
    } catch (e) {
      print('Ошибка получения рекомендаций по категориям: $e');
      return [];
    }
  }

  /// Сохранить рекомендацию
  Future<void> saveRecommendation(Recommendation recommendation) async {
    try {
      await _firestore
          .collection('recommendations')
          .doc(recommendation.id)
          .set(recommendation.toMap());
    } catch (e) {
      print('Ошибка сохранения рекомендации: $e');
    }
  }

  /// Отметить рекомендацию как просмотренную
  Future<void> markAsViewed(String recommendationId) async {
    try {
      await _firestore
          .collection('recommendations')
          .doc(recommendationId)
          .update({
        'isViewed': true,
        'viewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка обновления статуса просмотра: $e');
    }
  }

  /// Отметить рекомендацию как кликнутую
  Future<void> markAsClicked(String recommendationId) async {
    try {
      await _firestore
          .collection('recommendations')
          .doc(recommendationId)
          .update({
        'isClicked': true,
        'clickedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка обновления статуса клика: $e');
    }
  }

  /// Отметить рекомендацию как забронированную
  Future<void> markAsBooked(String recommendationId) async {
    try {
      await _firestore
          .collection('recommendations')
          .doc(recommendationId)
          .update({
        'isBooked': true,
        'bookedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка обновления статуса бронирования: $e');
    }
  }

  /// Получить статистику рекомендаций
  Future<RecommendationStats> getRecommendationStats(String userId) async {
    try {
      final recommendationsSnapshot = await _firestore
          .collection('recommendations')
          .where('userId', isEqualTo: userId)
          .get();

      final recommendations = recommendationsSnapshot.docs
          .map(Recommendation.fromDocument)
          .toList();

      return RecommendationStats.fromRecommendations(recommendations);
    } catch (e) {
      print('Ошибка получения статистики рекомендаций: $e');
      return RecommendationStats.empty();
    }
  }

  // ========== ПРИВАТНЫЕ МЕТОДЫ ==========

  /// Проверить, есть ли у пользователя история заказов
  Future<bool> _hasOrderHistory(String userId) async {
    try {
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .limit(1)
          .get();

      return bookingsSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Ошибка проверки истории заказов: $e');
      return false;
    }
  }

  /// Получить персонализированные рекомендации
  Future<List<Recommendation>> _getPersonalizedRecommendations(
    String userId,
  ) async {
    try {
      final recommendations = <Recommendation>[];

      // Рекомендации на основе истории (40%)
      final historyRecommendations =
          await getRecommendationsBasedOnHistory(userId);
      recommendations.addAll(historyRecommendations.take(6));

      // Популярные специалисты (60%)
      final popularRecommendations =
          await getPopularSpecialists(userId: userId);
      recommendations.addAll(popularRecommendations.take(6));

      // Сортируем по релевантности
      recommendations.sort((a, b) => b.score.compareTo(a.score));

      return recommendations.take(12).toList();
    } catch (e) {
      print('Ошибка получения персонализированных рекомендаций: $e');
      return getPopularSpecialists(userId: userId);
    }
  }

  /// Получить популярные рекомендации
  Future<List<Recommendation>> _getPopularRecommendations(String userId) async {
    try {
      final recommendations = <Recommendation>[];

      // Популярные специалисты (100%)
      final popularRecommendations =
          await getPopularSpecialists(userId: userId);
      recommendations.addAll(popularRecommendations.take(12));

      // Сортируем по релевантности
      recommendations.sort((a, b) => b.score.compareTo(a.score));

      return recommendations;
    } catch (e) {
      print('Ошибка получения популярных рекомендаций: $e');
      return [];
    }
  }

  /// Рассчитать оценку популярности
  double _calculatePopularityScore(Specialist specialist, int index) {
    const ratingWeight = 0.4;
    const bookingWeight = 0.4;
    const positionWeight = 0.2;

    final ratingScore = (specialist.rating / 5.0) * ratingWeight;
    final bookingScore =
        _normalizeBookingCount(specialist.totalBookings ?? 0) * bookingWeight;
    final positionScore = (1.0 - (index / 20.0)) * positionWeight;

    return ratingScore + bookingScore + positionScore;
  }

  /// Рассчитать оценку релевантности
  double _calculateRelevanceScore(
    Specialist specialist,
    Map<String, int> categoryPreferences,
    int index,
  ) {
    const categoryWeight = 0.5;
    const ratingWeight = 0.3;
    const positionWeight = 0.2;

    final categoryScore = _getCategoryPreferenceScore(
          specialist.category.name,
          categoryPreferences,
        ) *
        categoryWeight;
    final ratingScore = (specialist.rating / 5.0) * ratingWeight;
    final positionScore = (1.0 - (index / 5.0)) * positionWeight;

    return categoryScore + ratingScore + positionScore;
  }

  /// Получить оценку предпочтения категории
  double _getCategoryPreferenceScore(
    String category,
    Map<String, int> preferences,
  ) {
    final totalPreferences =
        preferences.values.fold(0, (sum, count) => sum + count);
    if (totalPreferences == 0) return 0;

    final categoryCount = preferences[category] ?? 0;
    return categoryCount / totalPreferences;
  }

  /// Нормализовать количество заказов
  double _normalizeBookingCount(int bookingCount) {
    // Логистическая функция для нормализации
    return 1.0 / (1.0 + (100.0 / (bookingCount + 1)));
  }
}
