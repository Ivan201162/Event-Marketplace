import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/logger.dart';
import '../models/specialist.dart';
import '../models/specialist_recommendation.dart';

/// Улучшенный сервис рекомендаций с учетом бюджета и связанных специалистов
class EnhancedRecommendationService {
  factory EnhancedRecommendationService() => _instance;
  EnhancedRecommendationService._internal();
  static final EnhancedRecommendationService _instance = EnhancedRecommendationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Матрица связанных категорий специалистов
  static const Map<SpecialistCategory, List<SpecialistCategory>> _relatedCategories = {
    // Фотографы связаны с видеографами, декораторами, визажистами
    SpecialistCategory.photographer: [
      SpecialistCategory.videographer,
      SpecialistCategory.decorator,
      SpecialistCategory.makeup,
      SpecialistCategory.lighting,
      SpecialistCategory.stylist,
    ],
    
    // Видеографы связаны с фотографами, звуковым оборудованием
    SpecialistCategory.videographer: [
      SpecialistCategory.photographer,
      SpecialistCategory.sound,
      SpecialistCategory.lighting,
      SpecialistCategory.technician,
    ],
    
    // Декораторы связаны с флористами, аэродизайном, освещением
    SpecialistCategory.decorator: [
      SpecialistCategory.florist,
      SpecialistCategory.balloon,
      SpecialistCategory.lighting,
      SpecialistCategory.photographer,
      SpecialistCategory.venue,
    ],
    
    // DJ связаны с музыкантами, звуковым оборудованием, освещением
    SpecialistCategory.dj: [
      SpecialistCategory.musician,
      SpecialistCategory.sound,
      SpecialistCategory.lighting,
      SpecialistCategory.coverBand,
    ],
    
    // Ведущие связаны с аниматорами, DJ, музыкантами
    SpecialistCategory.host: [
      SpecialistCategory.animator,
      SpecialistCategory.dj,
      SpecialistCategory.musician,
      SpecialistCategory.magic,
      SpecialistCategory.clown,
    ],
    
    // Кейтеринг связан с кондитерами, арендой оборудования
    SpecialistCategory.caterer: [
      SpecialistCategory.cake,
      SpecialistCategory.rental,
      SpecialistCategory.cleaning,
    ],
    
    // Музыканты связаны с DJ, звуковым оборудованием
    SpecialistCategory.musician: [
      SpecialistCategory.dj,
      SpecialistCategory.sound,
      SpecialistCategory.coverBand,
      SpecialistCategory.lighting,
    ],
    
    // Флористы связаны с декораторами, аэродизайном
    SpecialistCategory.florist: [
      SpecialistCategory.decorator,
      SpecialistCategory.balloon,
      SpecialistCategory.photographer,
    ],
    
    // Визажисты связаны с парикмахерами, стилистами, фотографами
    SpecialistCategory.makeup: [
      SpecialistCategory.hairstylist,
      SpecialistCategory.stylist,
      SpecialistCategory.photographer,
      SpecialistCategory.costume,
    ],
  };

  /// Получить рекомендации связанных специалистов на основе выбранных категорий
  Future<List<SpecialistRecommendation>> getRelatedSpecialistRecommendations({
    required List<String> selectedSpecialistIds,
    required String customerId,
    double? budget,
    int limit = 10,
  }) async {
    try {
      AppLogger.logI('Получение рекомендаций связанных специалистов для ${selectedSpecialistIds.length} специалистов', 'enhanced_recommendation_service');
      
      // Получаем категории уже выбранных специалистов
      final selectedCategories = <SpecialistCategory>{};
      final selectedSpecialists = <Specialist>[];
      
      for (final specialistId in selectedSpecialistIds) {
        final specialistDoc = await _firestore.collection('specialists').doc(specialistId).get();
        if (specialistDoc.exists) {
          final specialist = Specialist.fromDocument(specialistDoc);
          selectedSpecialists.add(specialist);
          selectedCategories.add(specialist.category);
        }
      }

      // Определяем рекомендуемые категории
      final recommendedCategories = <SpecialistCategory>{};
      for (final category in selectedCategories) {
        final related = _relatedCategories[category] ?? [];
        recommendedCategories.addAll(related);
      }

      // Исключаем уже выбранные категории
      recommendedCategories.removeAll(selectedCategories);

      if (recommendedCategories.isEmpty) {
        AppLogger.logI('Нет связанных категорий для рекомендаций', 'enhanced_recommendation_service');
        return [];
      }

      // Получаем специалистов из рекомендуемых категорий
      final recommendations = <SpecialistRecommendation>[];
      
      for (final category in recommendedCategories) {
        final specialists = await _getSpecialistsByCategory(
          category: category,
          excludeIds: selectedSpecialistIds,
          budget: budget,
          limit: (limit / recommendedCategories.length).ceil(),
        );

        for (final specialist in specialists) {
          final reason = _getRecommendationReason(category, selectedCategories);
          final score = _calculateRecommendationScore(specialist, selectedSpecialists, budget);
          
          recommendations.add(SpecialistRecommendation(
            id: '${customerId}_${specialist.id}_${DateTime.now().millisecondsSinceEpoch}',
            specialistId: specialist.id,
            reason: reason,
            score: score,
            timestamp: DateTime.now(),
            specialist: specialist,
          ));
        }
      }

      // Сортируем по релевантности и возвращаем топ результатов
      recommendations.sort((a, b) => b.score.compareTo(a.score));
      return recommendations.take(limit).toList();

    } catch (e) {
      AppLogger.logE('Ошибка получения рекомендаций связанных специалистов: $e', 'enhanced_recommendation_service');
      return [];
    }
  }

  /// Получить рекомендации по увеличению бюджета для новых идей
  Future<List<BudgetEnhancementRecommendation>> getBudgetEnhancementRecommendations({
    required String customerId,
    required double currentBudget,
    required List<String> selectedSpecialistIds,
    int limit = 5,
  }) async {
    try {
      AppLogger.logI('Получение рекомендаций по увеличению бюджета для клиента $customerId', 'enhanced_recommendation_service');
      
      final recommendations = <BudgetEnhancementRecommendation>[];

      // Получаем информацию о выбранных специалистах
      final selectedSpecialists = <Specialist>[];
      for (final specialistId in selectedSpecialistIds) {
        final specialistDoc = await _firestore.collection('specialists').doc(specialistId).get();
        if (specialistDoc.exists) {
          selectedSpecialists.add(Specialist.fromDocument(specialistDoc));
        }
      }

      // Анализируем возможности улучшения
      final enhancements = await _analyzeBudgetEnhancements(
        currentBudget: currentBudget,
        selectedSpecialists: selectedSpecialists,
      );

      for (final enhancement in enhancements) {
        recommendations.add(BudgetEnhancementRecommendation(
          id: '${customerId}_${enhancement.category.name}_${DateTime.now().millisecondsSinceEpoch}',
          category: enhancement.category,
          title: enhancement.title,
          description: enhancement.description,
          additionalCost: enhancement.additionalCost,
          totalBudget: currentBudget + enhancement.additionalCost,
          impact: enhancement.impact,
          priority: enhancement.priority,
          specialists: enhancement.specialists,
        ));
      }

      // Сортируем по приоритету и возвращаем топ результатов
      recommendations.sort((a, b) => b.priority.compareTo(a.priority));
      return recommendations.take(limit).toList();

    } catch (e) {
      AppLogger.logE('Ошибка получения рекомендаций по увеличению бюджета: $e', 'enhanced_recommendation_service');
      return [];
    }
  }

  /// Получить специалистов по категории с учетом бюджета
  Future<List<Specialist>> _getSpecialistsByCategory({
    required SpecialistCategory category,
    required List<String> excludeIds,
    double? budget,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore
          .collection('specialists')
          .where('category', isEqualTo: category.name)
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit * 2); // Получаем больше для фильтрации

      final snapshot = await query.get();
      final specialists = snapshot.docs
          .map((doc) => Specialist.fromDocument(doc))
          .where((specialist) => !excludeIds.contains(specialist.id))
          .toList();

      // Фильтруем по бюджету если указан
      if (budget != null) {
        specialists.removeWhere((specialist) => 
          specialist.hourlyRate * (specialist.minBookingHours ?? 1) > budget * 0.3); // Максимум 30% от бюджета на дополнительного специалиста
      }

      return specialists.take(limit).toList();
    } catch (e) {
      AppLogger.logE('Ошибка получения специалистов по категории ${category.name}: $e', 'enhanced_recommendation_service');
      return [];
    }
  }

  /// Получить причину рекомендации
  String _getRecommendationReason(SpecialistCategory category, Set<SpecialistCategory> selectedCategories) {
    // Удаляем неиспользуемую переменную
    
    if (selectedCategories.contains(SpecialistCategory.photographer) && 
        [SpecialistCategory.videographer, SpecialistCategory.lighting, SpecialistCategory.makeup].contains(category)) {
      return 'Дополнит работу фотографа';
    }
    
    if (selectedCategories.contains(SpecialistCategory.decorator) && 
        [SpecialistCategory.florist, SpecialistCategory.balloon, SpecialistCategory.lighting].contains(category)) {
      return 'Улучшит декоративное оформление';
    }
    
    if (selectedCategories.contains(SpecialistCategory.dj) && 
        [SpecialistCategory.sound, SpecialistCategory.lighting, SpecialistCategory.musician].contains(category)) {
      return 'Дополнит музыкальное сопровождение';
    }

    return 'Рекомендуется для полноты мероприятия';
  }

  /// Рассчитать релевантность рекомендации
  double _calculateRecommendationScore(
    Specialist specialist,
    List<Specialist> selectedSpecialists,
    double? budget,
  ) {
    var score = 0.0;

    // Базовый рейтинг специалиста (0-1)
    score += (specialist.rating / 5.0) * 0.3;

    // Количество отзывов (нормализованное)
    final reviewCount = specialist.reviewCount ?? 0;
    score += (reviewCount / 100.0).clamp(0.0, 1.0) * 0.2;

    // Соответствие бюджету
    if (budget != null) {
      final specialistMinPrice = specialist.hourlyRate * (specialist.minBookingHours ?? 1);
      final budgetRatio = specialistMinPrice / budget;
      if (budgetRatio <= 0.3) {
        score += 0.3; // Отлично подходит по бюджету
      } else if (budgetRatio <= 0.5) {
        score += 0.2; // Хорошо подходит
      } else if (budgetRatio <= 0.7) {
        score += 0.1; // Приемлемо
      }
    } else {
      score += 0.2; // Если бюджет не указан, даем средний балл
    }

    // Географическая близость (если есть координаты)
    if (specialist.location != null && selectedSpecialists.isNotEmpty) {
      // Упрощенная проверка - если есть координаты, добавляем балл
      score += 0.1;
    }

    // Опыт работы
    switch (specialist.experienceLevel) {
      case ExperienceLevel.expert:
        score += 0.1;
        break;
      case ExperienceLevel.advanced:
        score += 0.08;
        break;
      case ExperienceLevel.intermediate:
        score += 0.05;
        break;
      case ExperienceLevel.beginner:
        score += 0.02;
        break;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Анализировать возможности улучшения бюджета
  Future<List<BudgetEnhancement>> _analyzeBudgetEnhancements({
    required double currentBudget,
    required List<Specialist> selectedSpecialists,
  }) async {
    final enhancements = <BudgetEnhancement>[];

    // Анализируем выбранные категории
    final selectedCategories = selectedSpecialists.map((s) => s.category).toSet();

    // Рекомендации по освещению
    if (!selectedCategories.contains(SpecialistCategory.lighting) && 
        (selectedCategories.contains(SpecialistCategory.photographer) || 
         selectedCategories.contains(SpecialistCategory.videographer))) {
      enhancements.add(BudgetEnhancement(
        category: SpecialistCategory.lighting,
        title: 'Профессиональное освещение',
        description: 'Улучшит качество фото и видео съемки',
        additionalCost: currentBudget * 0.15,
        impact: 'Высокий',
        priority: 8,
        specialists: await _getSpecialistsByCategory(
          category: SpecialistCategory.lighting,
          excludeIds: [],
          budget: currentBudget * 0.15,
          limit: 3,
        ),
      ));
    }

    // Рекомендации по звуку
    if (!selectedCategories.contains(SpecialistCategory.sound) && 
        (selectedCategories.contains(SpecialistCategory.dj) || 
         selectedCategories.contains(SpecialistCategory.musician))) {
      enhancements.add(BudgetEnhancement(
        category: SpecialistCategory.sound,
        title: 'Качественное звуковое оборудование',
        description: 'Обеспечит отличное звучание музыки',
        additionalCost: currentBudget * 0.12,
        impact: 'Высокий',
        priority: 7,
        specialists: await _getSpecialistsByCategory(
          category: SpecialistCategory.sound,
          excludeIds: [],
          budget: currentBudget * 0.12,
          limit: 3,
        ),
      ));
    }

    // Рекомендации по декорациям
    if (!selectedCategories.contains(SpecialistCategory.decorator) && 
        !selectedCategories.contains(SpecialistCategory.florist)) {
      enhancements.add(BudgetEnhancement(
        category: SpecialistCategory.decorator,
        title: 'Декоративное оформление',
        description: 'Создаст атмосферу и украсит мероприятие',
        additionalCost: currentBudget * 0.2,
        impact: 'Средний',
        priority: 6,
        specialists: await _getSpecialistsByCategory(
          category: SpecialistCategory.decorator,
          excludeIds: [],
          budget: currentBudget * 0.2,
          limit: 3,
        ),
      ));
    }

    // Рекомендации по ведущему
    if (!selectedCategories.contains(SpecialistCategory.host) && 
        selectedCategories.length >= 2) {
      enhancements.add(BudgetEnhancement(
        category: SpecialistCategory.host,
        title: 'Профессиональный ведущий',
        description: 'Сделает мероприятие более организованным и веселым',
        additionalCost: currentBudget * 0.18,
        impact: 'Средний',
        priority: 5,
        specialists: await _getSpecialistsByCategory(
          category: SpecialistCategory.host,
          excludeIds: [],
          budget: currentBudget * 0.18,
          limit: 3,
        ),
      ));
    }

    // Рекомендации по анимации
    if (!selectedCategories.contains(SpecialistCategory.animator) && 
        !selectedCategories.contains(SpecialistCategory.magic)) {
      enhancements.add(BudgetEnhancement(
        category: SpecialistCategory.animator,
        title: 'Развлекательная программа',
        description: 'Добавит интерактивности и веселья',
        additionalCost: currentBudget * 0.1,
        impact: 'Средний',
        priority: 4,
        specialists: await _getSpecialistsByCategory(
          category: SpecialistCategory.animator,
          excludeIds: [],
          budget: currentBudget * 0.1,
          limit: 3,
        ),
      ));
    }

    return enhancements;
  }
}

/// Рекомендация по увеличению бюджета
class BudgetEnhancementRecommendation {
  const BudgetEnhancementRecommendation({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.additionalCost,
    required this.totalBudget,
    required this.impact,
    required this.priority,
    required this.specialists,
  });

  final String id;
  final SpecialistCategory category;
  final String title;
  final String description;
  final double additionalCost;
  final double totalBudget;
  final String impact;
  final int priority; // 1-10, где 10 - высший приоритет
  final List<Specialist> specialists;
}

/// Возможность улучшения бюджета
class BudgetEnhancement {
  const BudgetEnhancement({
    required this.category,
    required this.title,
    required this.description,
    required this.additionalCost,
    required this.impact,
    required this.priority,
    required this.specialists,
  });

  final SpecialistCategory category;
  final String title;
  final String description;
  final double additionalCost;
  final String impact;
  final int priority;
  final List<Specialist> specialists;
}
