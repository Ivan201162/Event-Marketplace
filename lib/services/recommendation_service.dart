import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/specialist.dart';
import '../models/booking.dart';
import '../models/event_idea.dart';
import '../core/logger.dart';

/// Сервис для рекомендаций и cross-sell
class RecommendationService {
  factory RecommendationService() => _instance;
  RecommendationService._internal();
  static final RecommendationService _instance = RecommendationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить рекомендации для cross-sell на основе выбранных услуг
  Future<List<Specialist>> getCrossSellRecommendations({
    required List<String> selectedSpecialistIds,
    required String customerId,
    double? budget,
  }) async {
    try {
      AppLogger.logI('Получение cross-sell рекомендаций для ${selectedSpecialistIds.length} специалистов', 'recommendation_service');
      
      // Получаем категории уже выбранных специалистов
      final selectedCategories = <SpecialistCategory>{};
      for (final specialistId in selectedSpecialistIds) {
        final specialistDoc = await _firestore.collection('specialists').doc(specialistId).get();
        if (specialistDoc.exists) {
          final specialist = Specialist.fromDocument(specialistDoc);
          selectedCategories.add(specialist.category);
        }
      }

      // Определяем рекомендуемые категории для cross-sell
      final recommendedCategories = _getRecommendedCategories(selectedCategories);
      
      // Получаем специалистов из рекомендуемых категорий
      final recommendations = <Specialist>[];
      for (final category in recommendedCategories) {
        final specialistsSnapshot = await _firestore
            .collection('specialists')
            .where('category', isEqualTo: category.name)
            .where('isAvailable', isEqualTo: true)
            .where('isVerified', isEqualTo: true)
            .orderBy('rating', descending: true)
            .limit(3)
            .get();

        for (final doc in specialistsSnapshot.docs) {
          final specialist = Specialist.fromDocument(doc);
          
          // Фильтруем по бюджету если указан
          if (budget == null || specialist.price <= budget) {
            recommendations.add(specialist);
          }
        }
      }

      // Сортируем по рейтингу и убираем дубликаты
      recommendations.sort((a, b) => b.rating.compareTo(a.rating));
      final uniqueRecommendations = recommendations.toSet().toList();

      AppLogger.logI('Найдено ${uniqueRecommendations.length} cross-sell рекомендаций', 'recommendation_service');
      return uniqueRecommendations.take(6).toList(); // Максимум 6 рекомендаций
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка получения cross-sell рекомендаций', 'recommendation_service', e, stackTrace);
      return [];
    }
  }

  /// Получить рекомендации по увеличению бюджета
  Future<Map<String, dynamic>> getBudgetIncreaseRecommendations({
    required List<String> selectedSpecialistIds,
    required double currentBudget,
  }) async {
    try {
      AppLogger.logI('Получение рекомендаций по увеличению бюджета', 'recommendation_service');
      
      // Получаем категории уже выбранных специалистов
      final selectedCategories = <SpecialistCategory>{};
      for (final specialistId in selectedSpecialistIds) {
        final specialistDoc = await _firestore.collection('specialists').doc(specialistId).get();
        if (specialistDoc.exists) {
          final specialist = Specialist.fromDocument(specialistDoc);
          selectedCategories.add(specialist.category);
        }
      }

      // Определяем недостающие категории
      final missingCategories = _getMissingCategories(selectedCategories);
      
      // Рассчитываем рекомендуемое увеличение бюджета
      final recommendations = <Map<String, dynamic>>[];
      double totalAdditionalCost = 0;

      for (final category in missingCategories) {
        final avgPrice = await _getAveragePriceForCategory(category);
        if (avgPrice > 0) {
          recommendations.add({
            'category': category,
            'categoryName': category.displayName,
            'icon': category.icon,
            'averagePrice': avgPrice,
            'description': _getCategoryDescription(category),
          });
          totalAdditionalCost += avgPrice;
        }
      }

      return {
        'recommendations': recommendations,
        'totalAdditionalCost': totalAdditionalCost,
        'newTotalBudget': currentBudget + totalAdditionalCost,
        'budgetIncreasePercent': currentBudget > 0 ? (totalAdditionalCost / currentBudget) * 100 : 0,
      };
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка получения рекомендаций по бюджету', 'recommendation_service', e, stackTrace);
      return {};
    }
  }

  /// Получить идеи мероприятий
  Future<List<EventIdea>> getEventIdeas({
    EventIdeaType? type,
    EventIdeaCategory? category,
    String? searchQuery,
    int limit = 20,
  }) async {
    try {
      AppLogger.logI('Получение идей мероприятий', 'recommendation_service');
      
      Query query = _firestore
          .collection('event_ideas')
          .where('isPublic', isEqualTo: true)
          .orderBy('isFeatured', descending: true)
          .orderBy('likesCount', descending: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }

      final snapshot = await query.limit(limit).get();
      
      List<EventIdea> ideas = snapshot.docs
          .map((doc) => EventIdea.fromDocument(doc))
          .toList();

      // Фильтруем по поисковому запросу если указан
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final queryLower = searchQuery.toLowerCase();
        ideas = ideas.where((idea) =>
            idea.title.toLowerCase().contains(queryLower) ||
            idea.description.toLowerCase().contains(queryLower) ||
            idea.tags.any((tag) => tag.toLowerCase().contains(queryLower))
        ).toList();
      }

      AppLogger.logI('Найдено ${ideas.length} идей мероприятий', 'recommendation_service');
      return ideas;
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка получения идей мероприятий', 'recommendation_service', e, stackTrace);
      return [];
    }
  }

  /// Получить сохраненные идеи пользователя
  Future<List<EventIdea>> getSavedIdeas(String userId) async {
    try {
      AppLogger.logI('Получение сохраненных идей пользователя: $userId', 'recommendation_service');
      
      final savedIdeasSnapshot = await _firestore
          .collection('saved_ideas')
          .where('userId', isEqualTo: userId)
          .orderBy('savedAt', descending: true)
          .get();

      final ideaIds = savedIdeasSnapshot.docs
          .map((doc) => doc.data()['ideaId'] as String)
          .toList();

      if (ideaIds.isEmpty) {
        return [];
      }

      final ideas = <EventIdea>[];
      for (final ideaId in ideaIds) {
        final ideaDoc = await _firestore.collection('event_ideas').doc(ideaId).get();
        if (ideaDoc.exists) {
          ideas.add(EventIdea.fromDocument(ideaDoc));
        }
      }

      AppLogger.logI('Найдено ${ideas.length} сохраненных идей', 'recommendation_service');
      return ideas;
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка получения сохраненных идей', 'recommendation_service', e, stackTrace);
      return [];
    }
  }

  /// Сохранить идею в избранное
  Future<void> saveIdea(String userId, String ideaId, {String? notes}) async {
    try {
      AppLogger.logI('Сохранение идеи $ideaId пользователем $userId', 'recommendation_service');
      
      await _firestore.collection('saved_ideas').add({
        'userId': userId,
        'ideaId': ideaId,
        'savedAt': Timestamp.fromDate(DateTime.now()),
        'notes': notes,
        'isFavorite': false,
        'tags': [],
      });

      // Увеличиваем счетчик сохранений
      await _firestore.collection('event_ideas').doc(ideaId).update({
        'savesCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.logI('Идея сохранена', 'recommendation_service');
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка сохранения идеи', 'recommendation_service', e, stackTrace);
    }
  }

  /// Удалить идею из избранного
  Future<void> unsaveIdea(String userId, String ideaId) async {
    try {
      AppLogger.logI('Удаление идеи $ideaId из избранного пользователя $userId', 'recommendation_service');
      
      final savedIdeasSnapshot = await _firestore
          .collection('saved_ideas')
          .where('userId', isEqualTo: userId)
          .where('ideaId', isEqualTo: ideaId)
          .get();

      for (final doc in savedIdeasSnapshot.docs) {
        await doc.reference.delete();
      }

      // Уменьшаем счетчик сохранений
      await _firestore.collection('event_ideas').doc(ideaId).update({
        'savesCount': FieldValue.increment(-1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.logI('Идея удалена из избранного', 'recommendation_service');
    } catch (e, stackTrace) {
      AppLogger.logE('Ошибка удаления идеи из избранного', 'recommendation_service', e, stackTrace);
    }
  }

  /// Получить рекомендуемые категории на основе выбранных
  Set<SpecialistCategory> _getRecommendedCategories(Set<SpecialistCategory> selectedCategories) {
    final recommended = <SpecialistCategory>{};
    
    // Логика рекомендаций
    if (selectedCategories.contains(SpecialistCategory.host)) {
      recommended.addAll([SpecialistCategory.dj, SpecialistCategory.photographer, SpecialistCategory.decorator]);
    }
    
    if (selectedCategories.contains(SpecialistCategory.photographer)) {
      recommended.addAll([SpecialistCategory.videographer, SpecialistCategory.makeup, SpecialistCategory.stylist]);
    }
    
    if (selectedCategories.contains(SpecialistCategory.dj)) {
      recommended.addAll([SpecialistCategory.lighting, SpecialistCategory.sound, SpecialistCategory.host]);
    }
    
    if (selectedCategories.contains(SpecialistCategory.decorator)) {
      recommended.addAll([SpecialistCategory.florist, SpecialistCategory.lighting, SpecialistCategory.photographer]);
    }
    
    if (selectedCategories.contains(SpecialistCategory.caterer)) {
      recommended.addAll([SpecialistCategory.waiter, SpecialistCategory.chef, SpecialistCategory.decorator]);
    }

    // Убираем уже выбранные категории
    recommended.removeAll(selectedCategories);
    
    return recommended;
  }

  /// Получить недостающие категории для полного пакета услуг
  Set<SpecialistCategory> _getMissingCategories(Set<SpecialistCategory> selectedCategories) {
    final essentialCategories = {
      SpecialistCategory.host,
      SpecialistCategory.photographer,
      SpecialistCategory.dj,
      SpecialistCategory.decorator,
    };
    
    return essentialCategories.difference(selectedCategories);
  }

  /// Получить среднюю цену по категории
  Future<double> _getAveragePriceForCategory(SpecialistCategory category) async {
    try {
      final snapshot = await _firestore
          .collection('specialists')
          .where('category', isEqualTo: category.name)
          .where('isAvailable', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      final prices = snapshot.docs
          .map((doc) => Specialist.fromDocument(doc))
          .map((specialist) => specialist.price)
          .where((price) => price > 0)
          .toList();

      if (prices.isEmpty) return 0.0;

      return prices.reduce((a, b) => a + b) / prices.length;
    } catch (e) {
      return 0.0;
    }
  }

  /// Получить описание категории
  String _getCategoryDescription(SpecialistCategory category) {
    switch (category) {
      case SpecialistCategory.host:
        return 'Ведущий сделает ваше мероприятие незабываемым';
      case SpecialistCategory.photographer:
        return 'Профессиональная фотосъемка сохранит лучшие моменты';
      case SpecialistCategory.dj:
        return 'DJ создаст идеальную атмосферу с музыкой';
      case SpecialistCategory.decorator:
        return 'Декоратор превратит пространство в сказку';
      case SpecialistCategory.videographer:
        return 'Видеограф запечатлит все эмоции на видео';
      case SpecialistCategory.makeup:
        return 'Визажист сделает вас неотразимыми';
      case SpecialistCategory.florist:
        return 'Флорист создаст красивые цветочные композиции';
      case SpecialistCategory.lighting:
        return 'Световое оформление добавит магии';
      default:
        return 'Дополнительные услуги для вашего мероприятия';
    }
  }
}