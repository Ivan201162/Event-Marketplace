import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/idea.dart';
import '../models/event_idea.dart';

/// Сервис для рекомендаций идей
class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить рекомендованные идеи для пользователя
  Future<List<Idea>> getRecommendedIdeas(
    String userId, {
    int limit = 20,
  }) async {
    try {
      // Получаем предпочтения пользователя
      final userPreferences = await _getUserPreferences(userId);
      
      // Получаем сохраненные идеи пользователя
      final savedIdeas = await _getUserSavedIdeas(userId);
      
      // Получаем лайкнутые идеи пользователя
      final likedIdeas = await _getUserLikedIdeas(userId);
      
      // Собираем теги из сохраненных и лайкнутых идей
      final userTags = <String>{};
      for (final idea in [...savedIdeas, ...likedIdeas]) {
        userTags.addAll(idea.tags);
      }
      
      // Получаем категории из предпочтений
      final userCategories = userPreferences['categories'] as List<String>? ?? [];
      
      // Ищем похожие идеи
      final similarIdeas = await _findSimilarIdeas(
        userTags.toList(),
        userCategories,
        limit: limit,
      );
      
      return similarIdeas;
    } catch (e) {
      debugPrint('Error getting recommended ideas: $e');
      return [];
    }
  }

  /// Получить предпочтения пользователя
  Future<Map<String, dynamic>> _getUserPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection('user_preferences')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return doc.data() ?? {};
      }
      
      return {};
    } catch (e) {
      debugPrint('Error getting user preferences: $e');
      return {};
    }
  }

  /// Получить сохраненные идеи пользователя
  Future<List<Idea>> _getUserSavedIdeas(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('ideas')
          .where('savedBy', arrayContains: userId)
          .limit(50)
          .get();
      
      return snapshot.docs
          .map((doc) => Idea.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      debugPrint('Error getting user saved ideas: $e');
      return [];
    }
  }

  /// Получить лайкнутые идеи пользователя
  Future<List<Idea>> _getUserLikedIdeas(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('ideas')
          .where('likedBy', arrayContains: userId)
          .limit(50)
          .get();
      
      return snapshot.docs
          .map((doc) => Idea.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      debugPrint('Error getting user liked ideas: $e');
      return [];
    }
  }

  /// Найти похожие идеи
  Future<List<Idea>> _findSimilarIdeas(
    List<String> userTags,
    List<String> userCategories, {
    int limit = 20,
  }) async {
    try {
      // Если нет предпочтений, возвращаем популярные идеи
      if (userTags.isEmpty && userCategories.isEmpty) {
        return await _getPopularIdeas(limit: limit);
      }

      final ideas = <Idea>[];
      
      // Ищем по тегам
      if (userTags.isNotEmpty) {
        final tagIdeas = await _firestore
            .collection('ideas')
            .where('tags', arrayContainsAny: userTags.take(10).toList())
            .where('isPublic', isEqualTo: true)
            .limit(limit)
            .get();
        
        ideas.addAll(tagIdeas.docs
            .map((doc) => Idea.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                })));
      }
      
      // Ищем по категориям
      if (userCategories.isNotEmpty) {
        for (final category in userCategories.take(3)) {
          final categoryIdeas = await _firestore
              .collection('ideas')
              .where('category', isEqualTo: category)
              .where('isPublic', isEqualTo: true)
              .limit(limit ~/ userCategories.length)
              .get();
          
          ideas.addAll(categoryIdeas.docs
              .map((doc) => Idea.fromMap({
                    'id': doc.id,
                    ...doc.data(),
                  })));
        }
      }
      
      // Убираем дубликаты и сортируем по релевантности
      final uniqueIdeas = <String, Idea>{};
      for (final idea in ideas) {
        uniqueIdeas[idea.id] = idea;
      }
      
      final sortedIdeas = uniqueIdeas.values.toList();
      sortedIdeas.sort((a, b) => _calculateRelevanceScore(b, userTags, userCategories)
          .compareTo(_calculateRelevanceScore(a, userTags, userCategories)));
      
      return sortedIdeas.take(limit).toList();
    } catch (e) {
      debugPrint('Error finding similar ideas: $e');
      return await _getPopularIdeas(limit: limit);
    }
  }

  /// Вычислить релевантность идеи
  double _calculateRelevanceScore(
    Idea idea,
    List<String> userTags,
    List<String> userCategories,
  ) {
    double score = 0;
    
    // Бонус за совпадающие теги
    final matchingTags = idea.tags.where((tag) => userTags.contains(tag)).length;
    score += matchingTags * 2;
    
    // Бонус за совпадающую категорию
    if (userCategories.contains(idea.category)) {
      score += 3;
    }
    
    // Бонус за популярность
    score += idea.likesCount * 0.1;
    score += idea.savesCount * 0.2;
    
    // Штраф за возраст (новые идеи получают небольшой бонус)
    final daysSinceCreation = DateTime.now().difference(idea.createdAt).inDays;
    score += (30 - daysSinceCreation) * 0.01;
    
    return score;
  }

  /// Получить популярные идеи
  Future<List<Idea>> _getPopularIdeas({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('ideas')
          .where('isPublic', isEqualTo: true)
          .orderBy('likesCount', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => Idea.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      debugPrint('Error getting popular ideas: $e');
      return [];
    }
  }

  /// Обновить предпочтения пользователя
  Future<void> updateUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      await _firestore
          .collection('user_preferences')
          .doc(userId)
          .set(preferences, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user preferences: $e');
      throw Exception('Ошибка обновления предпочтений: $e');
    }
  }

  /// Получить рекомендации на основе типа события
  Future<List<EventIdea>> getEventTypeRecommendations(
    EventIdeaType eventType, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('event_ideas')
          .where('type', isEqualTo: eventType.name)
          .where('isPublic', isEqualTo: true)
          .orderBy('likesCount', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => EventIdea.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting event type recommendations: $e');
      return [];
    }
  }

  /// Получить рекомендации на основе категории
  Future<List<EventIdea>> getCategoryRecommendations(
    EventIdeaCategory category, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('event_ideas')
          .where('category', isEqualTo: category.name)
          .where('isPublic', isEqualTo: true)
          .orderBy('likesCount', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => EventIdea.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting category recommendations: $e');
      return [];
    }
  }

  /// Получить рекомендации на основе бюджета
  Future<List<EventIdea>> getBudgetRecommendations(
    String budgetRange, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('event_ideas')
          .where('budgetRange', isEqualTo: budgetRange)
          .where('isPublic', isEqualTo: true)
          .orderBy('likesCount', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => EventIdea.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting budget recommendations: $e');
      return [];
    }
  }

  /// Получить рекомендации на основе сезона
  Future<List<EventIdea>> getSeasonRecommendations(
    String season, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('event_ideas')
          .where('season', isEqualTo: season)
          .where('isPublic', isEqualTo: true)
          .orderBy('likesCount', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => EventIdea.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting season recommendations: $e');
      return [];
    }
  }

  /// Получить рекомендации на основе стиля
  Future<List<EventIdea>> getStyleRecommendations(
    String style, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('event_ideas')
          .where('style', isEqualTo: style)
          .where('isPublic', isEqualTo: true)
          .orderBy('likesCount', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => EventIdea.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting style recommendations: $e');
      return [];
    }
  }

  /// Получить рекомендации на основе цветовой схемы
  Future<List<EventIdea>> getColorSchemeRecommendations(
    String colorScheme, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('event_ideas')
          .where('colorScheme', isEqualTo: colorScheme)
          .where('isPublic', isEqualTo: true)
          .orderBy('likesCount', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => EventIdea.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting color scheme recommendations: $e');
      return [];
    }
  }

  /// Получить рекомендации на основе количества гостей
  Future<List<EventIdea>> getGuestCountRecommendations(
    String guestCount, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('event_ideas')
          .where('guestCount', isEqualTo: guestCount)
          .where('isPublic', isEqualTo: true)
          .orderBy('likesCount', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => EventIdea.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting guest count recommendations: $e');
      return [];
    }
  }

  /// Получить рекомендации на основе местоположения
  Future<List<EventIdea>> getLocationRecommendations(
    String location, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('event_ideas')
          .where('location', isEqualTo: location)
          .where('isPublic', isEqualTo: true)
          .orderBy('likesCount', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => EventIdea.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting location recommendations: $e');
      return [];
    }
  }

  /// Получить рекомендации на основе сложности
  Future<List<EventIdea>> getDifficultyRecommendations(
    String difficultyLevel, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('event_ideas')
          .where('difficultyLevel', isEqualTo: difficultyLevel)
          .where('isPublic', isEqualTo: true)
          .orderBy('likesCount', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => EventIdea.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting difficulty recommendations: $e');
      return [];
    }
  }

  /// Получить рекомендации на основе времени подготовки
  Future<List<EventIdea>> getPreparationTimeRecommendations(
    String timeToPrepare, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('event_ideas')
          .where('timeToPrepare', isEqualTo: timeToPrepare)
          .where('isPublic', isEqualTo: true)
          .orderBy('likesCount', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => EventIdea.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting preparation time recommendations: $e');
      return [];
    }
  }

  /// Получить рекомендации на основе связанных услуг
  Future<List<EventIdea>> getRelatedServicesRecommendations(
    List<String> relatedServices, {
    int limit = 10,
  }) async {
    try {
      final ideas = <EventIdea>[];
      
      for (final service in relatedServices.take(5)) {
        final snapshot = await _firestore
            .collection('event_ideas')
            .where('relatedServices', arrayContains: service)
            .where('isPublic', isEqualTo: true)
            .orderBy('likesCount', descending: true)
            .limit(limit ~/ relatedServices.length)
            .get();
        
        ideas.addAll(snapshot.docs
            .map((doc) => EventIdea.fromDocument(doc)));
      }
      
      // Убираем дубликаты
      final uniqueIdeas = <String, EventIdea>{};
      for (final idea in ideas) {
        uniqueIdeas[idea.id] = idea;
      }
      
      return uniqueIdeas.values.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting related services recommendations: $e');
      return [];
    }
  }
}