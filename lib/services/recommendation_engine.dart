import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../models/idea.dart';
import '../models/review.dart';

/// Тип рекомендации
enum RecommendationType {
  specialist,
  event,
  idea,
  category,
}

/// Модель рекомендации
class Recommendation {
  final String id;
  final RecommendationType type;
  final String title;
  final String description;
  final String? imageUrl;
  final double score;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const Recommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.score,
    this.metadata = const {},
    required this.createdAt,
  });

  /// Создать из Map
  factory Recommendation.fromMap(Map<String, dynamic> data) {
    return Recommendation(
      id: data['id'] ?? '',
      type: RecommendationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => RecommendationType.specialist,
      ),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      score: (data['score'] as num?)?.toDouble() ?? 0.0,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'score': score,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Параметры для рекомендаций
class RecommendationParams {
  final String userId;
  final int limit;
  final List<String>? excludeIds;
  final String? category;
  final Map<String, dynamic>? filters;

  const RecommendationParams({
    required this.userId,
    this.limit = 10,
    this.excludeIds,
    this.category,
    this.filters,
  });
}

/// Движок рекомендаций
class RecommendationEngine {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить рекомендации для пользователя
  Future<List<Recommendation>> getRecommendations(
      RecommendationParams params) async {
    try {
      // Получаем историю пользователя
      final userHistory = await _getUserHistory(params.userId);

      // Анализируем предпочтения
      final preferences = await _analyzeUserPreferences(userHistory);

      // Генерируем рекомендации
      final recommendations = <Recommendation>[];

      // Рекомендации специалистов
      final specialistRecs =
          await _getSpecialistRecommendations(params, preferences);
      recommendations.addAll(specialistRecs);

      // Рекомендации событий
      final eventRecs = await _getEventRecommendations(params, preferences);
      recommendations.addAll(eventRecs);

      // Рекомендации идей
      final ideaRecs = await _getIdeaRecommendations(params, preferences);
      recommendations.addAll(ideaRecs);

      // Сортируем по релевантности
      recommendations.sort((a, b) => b.score.compareTo(a.score));

      // Исключаем уже просмотренные
      final filteredRecs = recommendations
          .where((rec) => !(params.excludeIds?.contains(rec.id) ?? false))
          .take(params.limit)
          .toList();

      return filteredRecs;
    } catch (e) {
      debugPrint('Error getting recommendations: $e');
      return [];
    }
  }

  /// Получить историю пользователя
  Future<Map<String, dynamic>> _getUserHistory(String userId) async {
    try {
      // Получаем бронирования
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();

      final bookings = bookingsQuery.docs
          .map((doc) => Booking.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      // Получаем отзывы
      final reviewsQuery = await _firestore
          .collection('reviews')
          .where('reviewerId', isEqualTo: userId)
          .get();

      final reviews = reviewsQuery.docs
          .map((doc) => Review.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      // Получаем сохраненные идеи
      final savedIdeasQuery = await _firestore
          .collection('ideas')
          .where('savedBy', arrayContains: userId)
          .get();

      final savedIdeas = savedIdeasQuery.docs
          .map((doc) => Idea.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      return {
        'bookings': bookings,
        'reviews': reviews,
        'savedIdeas': savedIdeas,
      };
    } catch (e) {
      debugPrint('Error getting user history: $e');
      return {
        'bookings': <Booking>[],
        'reviews': <Review>[],
        'savedIdeas': <Idea>[],
      };
    }
  }

  /// Анализировать предпочтения пользователя
  Future<Map<String, dynamic>> _analyzeUserPreferences(
      Map<String, dynamic> history) async {
    final bookings = history['bookings'] as List<Booking>;
    final reviews = history['reviews'] as List<Review>;
    final savedIdeas = history['savedIdeas'] as List<Idea>;

    // Анализ категорий
    final categoryPreferences = <String, double>{};
    for (final booking in bookings) {
      // TODO: Получить категорию события из booking
      final category = 'wedding'; // Заглушка
      categoryPreferences[category] = (categoryPreferences[category] ?? 0) + 1;
    }

    // Анализ предпочитаемых специалистов
    final specialistPreferences = <String, double>{};
    for (final booking in bookings) {
      if (booking.specialistId != null) {
        specialistPreferences[booking.specialistId!] =
            (specialistPreferences[booking.specialistId!] ?? 0) + 1;
      }
    }

    // Анализ тегов из сохраненных идей
    final tagPreferences = <String, double>{};
    for (final idea in savedIdeas) {
      for (final tag in idea.tags) {
        tagPreferences[tag] = (tagPreferences[tag] ?? 0) + 1;
      }
    }

    // Анализ рейтингов
    final averageRating = reviews.isNotEmpty
        ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length
        : 3.0;

    return {
      'categoryPreferences': categoryPreferences,
      'specialistPreferences': specialistPreferences,
      'tagPreferences': tagPreferences,
      'averageRating': averageRating,
      'totalBookings': bookings.length,
      'totalReviews': reviews.length,
      'totalSavedIdeas': savedIdeas.length,
    };
  }

  /// Получить рекомендации специалистов
  Future<List<Recommendation>> _getSpecialistRecommendations(
    RecommendationParams params,
    Map<String, dynamic> preferences,
  ) async {
    try {
      final categoryPreferences =
          preferences['categoryPreferences'] as Map<String, double>;
      final specialistPreferences =
          preferences['specialistPreferences'] as Map<String, double>;

      // Получаем популярных специалистов
      final specialistsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.specialist.name)
          .limit(20)
          .get();

      final recommendations = <Recommendation>[];

      for (final doc in specialistsQuery.docs) {
        final specialist = AppUser.fromMap({
          'id': doc.id,
          ...doc.data(),
        });

        // Пропускаем уже известных специалистов
        if (specialistPreferences.containsKey(specialist.id)) {
          continue;
        }

        // Вычисляем релевантность
        double score = 0.5; // Базовый скор

        // Бонус за высокий рейтинг
        // TODO: Получить рейтинг специалиста
        final rating = 4.5; // Заглушка
        score += (rating - 3.0) * 0.2;

        // Бонус за популярность
        // TODO: Получить количество заказов
        final orderCount = 10; // Заглушка
        score += (orderCount / 100.0) * 0.1;

        // Бонус за соответствие категории
        // TODO: Получить категорию специалиста
        final specialistCategory = 'wedding'; // Заглушка
        if (categoryPreferences.containsKey(specialistCategory)) {
          score += 0.3;
        }

        recommendations.add(Recommendation(
          id: specialist.id,
          type: RecommendationType.specialist,
          title: specialist.displayName,
          description: 'Специалист по организации мероприятий',
          imageUrl: specialist.photoURL,
          score: score,
          metadata: {
            'category': specialistCategory,
            'rating': rating,
            'orderCount': orderCount,
          },
          createdAt: DateTime.now(),
        ));
      }

      return recommendations;
    } catch (e) {
      debugPrint('Error getting specialist recommendations: $e');
      return [];
    }
  }

  /// Получить рекомендации событий
  Future<List<Recommendation>> _getEventRecommendations(
    RecommendationParams params,
    Map<String, dynamic> preferences,
  ) async {
    try {
      final categoryPreferences =
          preferences['categoryPreferences'] as Map<String, double>;

      // Получаем предстоящие события
      final eventsQuery = await _firestore
          .collection('events')
          .where('date', isGreaterThan: Timestamp.now())
          .limit(20)
          .get();

      final recommendations = <Recommendation>[];

      for (final doc in eventsQuery.docs) {
        final event = Event.fromMap({
          'id': doc.id,
          ...doc.data(),
        });

        // Вычисляем релевантность
        double score = 0.5; // Базовый скор

        // Бонус за соответствие категории
        if (categoryPreferences.containsKey(event.category)) {
          score += 0.4;
        }

        // Бонус за близость даты
        final daysUntilEvent = event.date.difference(DateTime.now()).inDays;
        if (daysUntilEvent <= 30) {
          score += 0.2;
        }

        // Бонус за доступность мест
        final availability = event.maxParticipants - event.currentParticipants;
        if (availability > 0) {
          score += (availability / event.maxParticipants) * 0.1;
        }

        recommendations.add(Recommendation(
          id: event.id,
          type: RecommendationType.event,
          title: event.title,
          description: event.description,
          imageUrl: event.images.isNotEmpty ? event.images.first : null,
          score: score,
          metadata: {
            'category': event.category,
            'date': event.date.toIso8601String(),
            'price': event.price,
            'location': event.location,
          },
          createdAt: DateTime.now(),
        ));
      }

      return recommendations;
    } catch (e) {
      debugPrint('Error getting event recommendations: $e');
      return [];
    }
  }

  /// Получить рекомендации идей
  Future<List<Recommendation>> _getIdeaRecommendations(
    RecommendationParams params,
    Map<String, dynamic> preferences,
  ) async {
    try {
      final tagPreferences =
          preferences['tagPreferences'] as Map<String, double>;
      final categoryPreferences =
          preferences['categoryPreferences'] as Map<String, double>;

      // Получаем популярные идеи
      final ideasQuery = await _firestore
          .collection('ideas')
          .where('isPublic', isEqualTo: true)
          .orderBy('likesCount', descending: true)
          .limit(20)
          .get();

      final recommendations = <Recommendation>[];

      for (final doc in ideasQuery.docs) {
        final idea = Idea.fromMap({
          'id': doc.id,
          ...doc.data(),
        });

        // Пропускаем уже сохраненные идеи
        if (idea.savedBy.contains(params.userId)) {
          continue;
        }

        // Вычисляем релевантность
        double score = 0.3; // Базовый скор

        // Бонус за соответствие тегам
        for (final tag in idea.tags) {
          if (tagPreferences.containsKey(tag)) {
            score += 0.2;
          }
        }

        // Бонус за соответствие категории
        if (categoryPreferences.containsKey(idea.category)) {
          score += 0.3;
        }

        // Бонус за популярность
        score += (idea.likesCount / 100.0) * 0.1;

        recommendations.add(Recommendation(
          id: idea.id,
          type: RecommendationType.idea,
          title: idea.title,
          description: idea.description,
          imageUrl: idea.images.isNotEmpty ? idea.images.first : null,
          score: score,
          metadata: {
            'category': idea.category,
            'tags': idea.tags,
            'likesCount': idea.likesCount,
            'authorName': idea.authorName,
          },
          createdAt: DateTime.now(),
        ));
      }

      return recommendations;
    } catch (e) {
      debugPrint('Error getting idea recommendations: $e');
      return [];
    }
  }

  /// Получить похожих пользователей
  Future<List<String>> getSimilarUsers(String userId) async {
    try {
      final userHistory = await _getUserHistory(userId);
      final preferences = await _analyzeUserPreferences(userHistory);

      // Получаем других пользователей
      final usersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.customer.name)
          .limit(100)
          .get();

      final similarUsers = <MapEntry<String, double>>[];

      for (final doc in usersQuery.docs) {
        if (doc.id == userId) continue;

        final otherUserHistory = await _getUserHistory(doc.id);
        final otherPreferences =
            await _analyzeUserPreferences(otherUserHistory);

        // Вычисляем схожесть
        final similarity = _calculateSimilarity(preferences, otherPreferences);
        if (similarity > 0.3) {
          similarUsers.add(MapEntry(doc.id, similarity));
        }
      }

      // Сортируем по схожести
      similarUsers.sort((a, b) => b.value.compareTo(a.value));

      return similarUsers.take(10).map((entry) => entry.key).toList();
    } catch (e) {
      debugPrint('Error getting similar users: $e');
      return [];
    }
  }

  /// Вычислить схожесть пользователей
  double _calculateSimilarity(
    Map<String, dynamic> preferences1,
    Map<String, dynamic> preferences2,
  ) {
    final categoryPrefs1 =
        preferences1['categoryPreferences'] as Map<String, double>;
    final categoryPrefs2 =
        preferences2['categoryPreferences'] as Map<String, double>;
    final tagPrefs1 = preferences1['tagPreferences'] as Map<String, double>;
    final tagPrefs2 = preferences2['tagPreferences'] as Map<String, double>;

    double similarity = 0.0;

    // Схожесть по категориям
    final allCategories = {...categoryPrefs1.keys, ...categoryPrefs2.keys};
    double categorySimilarity = 0.0;
    for (final category in allCategories) {
      final pref1 = categoryPrefs1[category] ?? 0.0;
      final pref2 = categoryPrefs2[category] ?? 0.0;
      categorySimilarity += (pref1 - pref2).abs();
    }
    similarity += 1.0 - (categorySimilarity / allCategories.length);

    // Схожесть по тегам
    final allTags = {...tagPrefs1.keys, ...tagPrefs2.keys};
    double tagSimilarity = 0.0;
    for (final tag in allTags) {
      final pref1 = tagPrefs1[tag] ?? 0.0;
      final pref2 = tagPrefs2[tag] ?? 0.0;
      tagSimilarity += (pref1 - pref2).abs();
    }
    similarity += 1.0 - (tagSimilarity / allTags.length);

    return similarity / 2.0;
  }

  /// Обновить рекомендации для пользователя
  Future<void> updateUserRecommendations(String userId) async {
    try {
      final params = RecommendationParams(userId: userId, limit: 50);
      final recommendations = await getRecommendations(params);

      // Сохраняем рекомендации
      final batch = _firestore.batch();
      final recommendationsRef =
          _firestore.collection('user_recommendations').doc(userId);

      batch.set(recommendationsRef, {
        'userId': userId,
        'recommendations': recommendations.map((r) => r.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error updating user recommendations: $e');
    }
  }

  /// Получить сохраненные рекомендации
  Future<List<Recommendation>> getCachedRecommendations(String userId) async {
    try {
      final doc =
          await _firestore.collection('user_recommendations').doc(userId).get();

      if (!doc.exists) {
        return [];
      }

      final data = doc.data()!;
      final recommendationsData = data['recommendations'] as List;

      return recommendationsData
          .map((item) => Recommendation.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting cached recommendations: $e');
      return [];
    }
  }
}
