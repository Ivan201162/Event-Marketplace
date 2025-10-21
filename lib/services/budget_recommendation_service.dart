import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/specialist.dart';

/// Сервис для предложений по увеличению бюджета
class BudgetRecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить рекомендации по увеличению бюджета
  Future<List<BudgetRecommendation>> getBudgetRecommendations({
    required double currentBudget,
    required List<String> selectedSpecialistIds,
    required String userId,
  }) async {
    try {
      if (selectedSpecialistIds.isEmpty) {
        return [];
      }

      // Получаем информацию о выбранных специалистах
      final selectedSpecialists = await _getSpecialistsByIds(selectedSpecialistIds);

      // Рассчитываем минимальную сумму для добавления специалистов
      final recommendations = await _calculateBudgetRecommendations(
        currentBudget: currentBudget,
        selectedSpecialists: selectedSpecialists,
        userId: userId,
      );

      return recommendations;
    } on Exception catch (e) {
      debugPrint('Ошибка получения рекомендаций по бюджету: $e');
      return [];
    }
  }

  /// Получить минимальную стоимость специалистов в категории
  Future<double> getMinimumPriceForCategory(SpecialistCategory category) async {
    try {
      final snapshot = await _firestore
          .collection('specialists')
          .where('category', isEqualTo: category.name)
          .where('isAvailable', isEqualTo: true)
          .orderBy('price', descending: false)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return 0.0;
      }

      final specialist = Specialist.fromDocument(snapshot.docs.first);
      return specialist.price;
    } on Exception catch (e) {
      debugPrint('Ошибка получения минимальной цены для категории: $e');
      return 0.0;
    }
  }

  /// Получить среднюю стоимость специалистов в категории
  Future<double> getAveragePriceForCategory(SpecialistCategory category) async {
    try {
      final snapshot = await _firestore
          .collection('specialists')
          .where('category', isEqualTo: category.name)
          .where('isAvailable', isEqualTo: true)
          .limit(20)
          .get();

      if (snapshot.docs.isEmpty) {
        return 0.0;
      }

      final specialists = snapshot.docs.map(Specialist.fromDocument).toList();

      final totalPrice = specialists.fold<double>(0, (sum, specialist) => sum + specialist.price);
      return totalPrice / specialists.length;
    } on Exception catch (e) {
      debugPrint('Ошибка получения средней цены для категории: $e');
      return 0.0;
    }
  }

  /// Сохранить рекомендацию по бюджету как показанную
  Future<void> markBudgetRecommendationAsShown(String recommendationId) async {
    try {
      await _firestore.collection('budget_recommendations').doc(recommendationId).update({
        'isShown': true,
        'shownAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка сохранения статуса рекомендации по бюджету: $e');
    }
  }

  // ========== ПРИВАТНЫЕ МЕТОДЫ ==========

  /// Получить специалистов по ID
  Future<List<Specialist>> _getSpecialistsByIds(List<String> specialistIds) async {
    final specialists = <Specialist>[];

    for (final id in specialistIds) {
      try {
        final doc = await _firestore.collection('specialists').doc(id).get();
        if (doc.exists) {
          specialists.add(Specialist.fromDocument(doc));
        }
      } on Exception catch (e) {
        debugPrint('Ошибка получения специалиста $id: $e');
      }
    }

    return specialists;
  }

  /// Рассчитать рекомендации по бюджету
  Future<List<BudgetRecommendation>> _calculateBudgetRecommendations({
    required double currentBudget,
    required List<Specialist> selectedSpecialists,
    required String userId,
  }) async {
    final recommendations = <BudgetRecommendation>[];

    // Анализируем выбранные категории
    final selectedCategories = selectedSpecialists.map((s) => s.category).toSet();

    // Получаем рекомендуемые категории для выбранных
    for (final selectedCategory in selectedCategories) {
      final recommendedCategories = _getRecommendedCategoriesFor(selectedCategory);

      for (final recommendedCategory in recommendedCategories) {
        // Проверяем, не выбран ли уже специалист этой категории
        final hasSpecialistInCategory = selectedSpecialists.any(
          (s) => s.category == recommendedCategory,
        );

        if (hasSpecialistInCategory) continue;

        // Получаем минимальную цену для категории
        final minPrice = await getMinimumPriceForCategory(recommendedCategory);

        if (minPrice > 0) {
          final additionalBudget = minPrice;
          final totalBudget = currentBudget + additionalBudget;

          final recommendation = BudgetRecommendation(
            id: '${userId}_${recommendedCategory.name}_budget',
            category: recommendedCategory,
            currentBudget: currentBudget,
            additionalBudget: additionalBudget,
            totalBudget: totalBudget,
            reason: _getBudgetRecommendationReason(
              selectedCategory,
              recommendedCategory,
              additionalBudget,
            ),
            priority: _calculatePriority(selectedCategory, recommendedCategory),
            timestamp: DateTime.now(),
          );

          recommendations.add(recommendation);
        }
      }
    }

    // Сортируем по приоритету
    recommendations.sort((a, b) => b.priority.compareTo(a.priority));

    return recommendations.take(5).toList();
  }

  /// Получить рекомендуемые категории для данной категории
  List<SpecialistCategory> _getRecommendedCategoriesFor(SpecialistCategory category) {
    switch (category) {
      case SpecialistCategory.host:
        return [
          SpecialistCategory.photographer,
          SpecialistCategory.videographer,
          SpecialistCategory.decorator,
        ];
      case SpecialistCategory.dj:
        return [
          SpecialistCategory.photographer,
          SpecialistCategory.lighting,
          SpecialistCategory.sound,
        ];
      case SpecialistCategory.photographer:
        return [
          SpecialistCategory.videographer,
          SpecialistCategory.makeup,
          SpecialistCategory.stylist,
        ];
      case SpecialistCategory.videographer:
        return [
          SpecialistCategory.photographer,
          SpecialistCategory.lighting,
          SpecialistCategory.sound,
        ];
      case SpecialistCategory.decorator:
        return [
          SpecialistCategory.photographer,
          SpecialistCategory.videographer,
          SpecialistCategory.florist,
        ];
      case SpecialistCategory.musician:
        return [
          SpecialistCategory.photographer,
          SpecialistCategory.videographer,
          SpecialistCategory.sound,
        ];
      default:
        return [SpecialistCategory.photographer, SpecialistCategory.videographer];
    }
  }

  /// Получить причину рекомендации по бюджету
  String _getBudgetRecommendationReason(
    SpecialistCategory selected,
    SpecialistCategory recommended,
    double additionalBudget,
  ) {
    final reasons = {
      '${SpecialistCategory.host.name}_${SpecialistCategory.photographer.name}':
          'Добавьте +${additionalBudget.toStringAsFixed(0)} ₽, чтобы заказать фотографа',
      '${SpecialistCategory.host.name}_${SpecialistCategory.videographer.name}':
          'Добавьте +${additionalBudget.toStringAsFixed(0)} ₽, чтобы заказать видеографа',
      '${SpecialistCategory.host.name}_${SpecialistCategory.decorator.name}':
          'Добавьте +${additionalBudget.toStringAsFixed(0)} ₽, чтобы заказать декоратора',
      '${SpecialistCategory.dj.name}_${SpecialistCategory.photographer.name}':
          'Добавьте +${additionalBudget.toStringAsFixed(0)} ₽, чтобы заказать фотографа',
      '${SpecialistCategory.dj.name}_${SpecialistCategory.lighting.name}':
          'Добавьте +${additionalBudget.toStringAsFixed(0)} ₽, чтобы заказать световое оформление',
      '${SpecialistCategory.photographer.name}_${SpecialistCategory.videographer.name}':
          'Добавьте +${additionalBudget.toStringAsFixed(0)} ₽, чтобы заказать видеографа',
      '${SpecialistCategory.photographer.name}_${SpecialistCategory.makeup.name}':
          'Добавьте +${additionalBudget.toStringAsFixed(0)} ₽, чтобы заказать визажиста',
    };

    final key = '${selected.name}_${recommended.name}';
    return reasons[key] ??
        'Добавьте +${additionalBudget.toStringAsFixed(0)} ₽, чтобы заказать ${recommended.displayName}';
  }

  /// Рассчитать приоритет рекомендации
  double _calculatePriority(SpecialistCategory selected, SpecialistCategory recommended) {
    // Базовые приоритеты совместимости
    final compatibilityScores = {
      '${SpecialistCategory.host.name}_${SpecialistCategory.photographer.name}': 0.9,
      '${SpecialistCategory.host.name}_${SpecialistCategory.videographer.name}': 0.9,
      '${SpecialistCategory.host.name}_${SpecialistCategory.decorator.name}': 0.8,
      '${SpecialistCategory.dj.name}_${SpecialistCategory.photographer.name}': 0.8,
      '${SpecialistCategory.dj.name}_${SpecialistCategory.lighting.name}': 0.9,
      '${SpecialistCategory.photographer.name}_${SpecialistCategory.videographer.name}': 0.95,
      '${SpecialistCategory.photographer.name}_${SpecialistCategory.makeup.name}': 0.7,
    };

    final key = '${selected.name}_${recommended.name}';
    return compatibilityScores[key] ?? 0.6;
  }
}

/// Модель рекомендации по бюджету
class BudgetRecommendation {
  const BudgetRecommendation({
    required this.id,
    required this.category,
    required this.currentBudget,
    required this.additionalBudget,
    required this.totalBudget,
    required this.reason,
    required this.priority,
    required this.timestamp,
    this.isShown = false,
  });

  factory BudgetRecommendation.fromMap(Map<String, dynamic> data) => BudgetRecommendation(
    id: data['id'] as String? ?? '',
    category: SpecialistCategory.values.firstWhere(
      (e) => e.name == data['category'] as String,
      orElse: () => SpecialistCategory.other,
    ),
    currentBudget: (data['currentBudget'] as num?)?.toDouble() ?? 0.0,
    additionalBudget: (data['additionalBudget'] as num?)?.toDouble() ?? 0.0,
    totalBudget: (data['totalBudget'] as num?)?.toDouble() ?? 0.0,
    reason: data['reason'] as String? ?? '',
    priority: (data['priority'] as num?)?.toDouble() ?? 0.0,
    timestamp: data['timestamp'] != null
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.now(),
    isShown: data['isShown'] as bool? ?? false,
  );

  final String id;
  final SpecialistCategory category;
  final double currentBudget;
  final double additionalBudget;
  final double totalBudget;
  final String reason;
  final double priority;
  final DateTime timestamp;
  final bool isShown;

  Map<String, dynamic> toMap() => {
    'id': id,
    'category': category.name,
    'currentBudget': currentBudget,
    'additionalBudget': additionalBudget,
    'totalBudget': totalBudget,
    'reason': reason,
    'priority': priority,
    'timestamp': Timestamp.fromDate(timestamp),
    'isShown': isShown,
  };
}
