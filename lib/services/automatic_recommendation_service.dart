import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/specialist.dart';

/// Сервис автоматических рекомендаций на основе выбранных специалистов
class AutomaticRecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить рекомендации на основе выбранных специалистов
  Future<List<SpecialistRecommendation>> getRecommendationsForSelectedSpecialists({
    required List<String> selectedSpecialistIds,
    required String userId,
  }) async {
    try {
      if (selectedSpecialistIds.isEmpty) {
        return [];
      }

      // Получаем информацию о выбранных специалистах
      final selectedSpecialists = await _getSpecialistsByIds(selectedSpecialistIds);

      // Анализируем категории выбранных специалистов
      final categoryAnalysis = _analyzeSelectedCategories(selectedSpecialists);

      // Генерируем рекомендации на основе анализа
      final recommendations = await _generateRecommendations(
        categoryAnalysis: categoryAnalysis,
        selectedSpecialistIds: selectedSpecialistIds,
        userId: userId,
      );

      return recommendations;
    } on Exception catch (e) {
      debugPrint('Ошибка получения автоматических рекомендаций: $e');
      return [];
    }
  }

  /// Получить рекомендации для конкретной категории
  Future<List<SpecialistRecommendation>> getRecommendationsForCategory({
    required SpecialistCategory category,
    required String userId,
    List<String> excludeIds = const [],
  }) async {
    try {
      // Определяем рекомендуемые категории для данной категории
      final recommendedCategories = _getRecommendedCategoriesFor(category);

      final recommendations = <SpecialistRecommendation>[];

      for (final recommendedCategory in recommendedCategories) {
        final specialists = await _getSpecialistsByCategory(
          category: recommendedCategory,
          excludeIds: excludeIds,
          limit: 3,
        );

        for (final specialist in specialists) {
          final recommendation = SpecialistRecommendation(
            id: '${userId}_${specialist.id}_auto_${recommendedCategory.name}',
            specialistId: specialist.id,
            specialist: specialist,
            reason: _getRecommendationReason(category, recommendedCategory),
            score: _calculateRecommendationScore(category, recommendedCategory),
            timestamp: DateTime.now(),
            category: recommendedCategory,
            isAutomatic: true,
          );

          recommendations.add(recommendation);
        }
      }

      // Сортируем по релевантности
      recommendations.sort((a, b) => b.score.compareTo(a.score));

      return recommendations.take(6).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения рекомендаций для категории: $e');
      return [];
    }
  }

  /// Сохранить рекомендацию как показанную
  Future<void> markRecommendationAsShown(String recommendationId) async {
    try {
      await _firestore.collection('automatic_recommendations').doc(recommendationId).update({
        'isShown': true,
        'shownAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка сохранения статуса рекомендации: $e');
    }
  }

  /// Отметить рекомендацию как принятую
  Future<void> markRecommendationAsAccepted(String recommendationId) async {
    try {
      await _firestore.collection('automatic_recommendations').doc(recommendationId).update({
        'isAccepted': true,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка сохранения статуса принятия рекомендации: $e');
    }
  }

  // ========== ПРИВАТНЫЕ МЕТОДЫ ==========

  /// Получить специалистов по ID
  Future<List<Specialist>> _getSpecialistsByIds(
    List<String> specialistIds,
  ) async {
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

  /// Анализировать выбранные категории
  Map<SpecialistCategory, int> _analyzeSelectedCategories(
    List<Specialist> specialists,
  ) {
    final categoryCount = <SpecialistCategory, int>{};

    for (final specialist in specialists) {
      categoryCount[specialist.category] = (categoryCount[specialist.category] ?? 0) + 1;
    }

    return categoryCount;
  }

  /// Генерировать рекомендации на основе анализа
  Future<List<SpecialistRecommendation>> _generateRecommendations({
    required Map<SpecialistCategory, int> categoryAnalysis,
    required List<String> selectedSpecialistIds,
    required String userId,
  }) async {
    final recommendations = <SpecialistRecommendation>[];

    // Анализируем каждую выбранную категорию
    for (final entry in categoryAnalysis.entries) {
      final selectedCategory = entry.key;
      final count = entry.value;

      // Получаем рекомендуемые категории для выбранной
      final recommendedCategories = _getRecommendedCategoriesFor(selectedCategory);

      for (final recommendedCategory in recommendedCategories) {
        // Получаем специалистов в рекомендуемой категории
        final specialists = await _getSpecialistsByCategory(
          category: recommendedCategory,
          excludeIds: selectedSpecialistIds,
          limit: 2,
        );

        for (final specialist in specialists) {
          final recommendation = SpecialistRecommendation(
            id: '${userId}_${specialist.id}_auto_${selectedCategory.name}_${recommendedCategory.name}',
            specialistId: specialist.id,
            specialist: specialist,
            reason: _getRecommendationReason(selectedCategory, recommendedCategory),
            score: _calculateRecommendationScore(
                  selectedCategory,
                  recommendedCategory,
                ) *
                count,
            timestamp: DateTime.now(),
            category: recommendedCategory,
            isAutomatic: true,
          );

          recommendations.add(recommendation);
        }
      }
    }

    // Сортируем по релевантности
    recommendations.sort((a, b) => b.score.compareTo(a.score));

    return recommendations.take(8).toList();
  }

  /// Получить рекомендуемые категории для данной категории
  List<SpecialistCategory> _getRecommendedCategoriesFor(
    SpecialistCategory category,
  ) {
    switch (category) {
      case SpecialistCategory.host:
        return [
          SpecialistCategory.photographer,
          SpecialistCategory.videographer,
          SpecialistCategory.decorator,
          SpecialistCategory.dj,
        ];
      case SpecialistCategory.dj:
        return [
          SpecialistCategory.photographer,
          SpecialistCategory.videographer,
          SpecialistCategory.lighting,
          SpecialistCategory.sound,
        ];
      case SpecialistCategory.photographer:
        return [
          SpecialistCategory.videographer,
          SpecialistCategory.decorator,
          SpecialistCategory.makeup,
          SpecialistCategory.stylist,
        ];
      case SpecialistCategory.videographer:
        return [
          SpecialistCategory.photographer,
          SpecialistCategory.decorator,
          SpecialistCategory.lighting,
          SpecialistCategory.sound,
        ];
      case SpecialistCategory.decorator:
        return [
          SpecialistCategory.photographer,
          SpecialistCategory.videographer,
          SpecialistCategory.florist,
          SpecialistCategory.lighting,
        ];
      case SpecialistCategory.musician:
        return [
          SpecialistCategory.photographer,
          SpecialistCategory.videographer,
          SpecialistCategory.sound,
          SpecialistCategory.lighting,
        ];
      case SpecialistCategory.animator:
        return [
          SpecialistCategory.photographer,
          SpecialistCategory.videographer,
          SpecialistCategory.decorator,
          SpecialistCategory.makeup,
        ];
      default:
        return [
          SpecialistCategory.photographer,
          SpecialistCategory.videographer,
          SpecialistCategory.decorator,
        ];
    }
  }

  /// Получить специалистов по категории
  Future<List<Specialist>> _getSpecialistsByCategory({
    required SpecialistCategory category,
    List<String> excludeIds = const [],
    int limit = 5,
  }) async {
    try {
      final query = _firestore
          .collection('specialists')
          .where('category', isEqualTo: category.name)
          .where('isAvailable', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit * 2); // Берем больше, чтобы исключить нужных

      final snapshot = await query.get();
      final specialists = snapshot.docs
          .map(Specialist.fromDocument)
          .where((specialist) => !excludeIds.contains(specialist.id))
          .take(limit)
          .toList();

      return specialists;
    } on Exception catch (e) {
      debugPrint('Ошибка получения специалистов по категории: $e');
      return [];
    }
  }

  /// Получить причину рекомендации
  String _getRecommendationReason(
    SpecialistCategory selected,
    SpecialistCategory recommended,
  ) {
    final reasons = {
      '${SpecialistCategory.host.name}_${SpecialistCategory.photographer.name}':
          'Рекомендуем добавить фотографа для съемки ведущего',
      '${SpecialistCategory.host.name}_${SpecialistCategory.videographer.name}':
          'Рекомендуем добавить видеографа для записи мероприятия',
      '${SpecialistCategory.host.name}_${SpecialistCategory.decorator.name}':
          'Рекомендуем добавить декоратора для оформления зала',
      '${SpecialistCategory.dj.name}_${SpecialistCategory.photographer.name}':
          'Рекомендуем добавить фотографа для съемки танцпола',
      '${SpecialistCategory.dj.name}_${SpecialistCategory.lighting.name}':
          'Рекомендуем добавить световое оформление для дискотеки',
      '${SpecialistCategory.photographer.name}_${SpecialistCategory.videographer.name}':
          'Рекомендуем добавить видеографа для полного покрытия события',
      '${SpecialistCategory.photographer.name}_${SpecialistCategory.makeup.name}':
          'Рекомендуем добавить визажиста для подготовки к съемке',
    };

    final key = '${selected.name}_${recommended.name}';
    return reasons[key] ?? 'Рекомендуем добавить ${recommended.displayName}';
  }

  /// Рассчитать оценку рекомендации
  double _calculateRecommendationScore(
    SpecialistCategory selected,
    SpecialistCategory recommended,
  ) {
    // Базовые оценки совместимости категорий
    final compatibilityScores = {
      '${SpecialistCategory.host.name}_${SpecialistCategory.photographer.name}': 0.9,
      '${SpecialistCategory.host.name}_${SpecialistCategory.videographer.name}': 0.9,
      '${SpecialistCategory.host.name}_${SpecialistCategory.decorator.name}': 0.8,
      '${SpecialistCategory.dj.name}_${SpecialistCategory.photographer.name}': 0.8,
      '${SpecialistCategory.dj.name}_${SpecialistCategory.lighting.name}': 0.9,
      '${SpecialistCategory.photographer.name}_${SpecialistCategory.videographer.name}': 0.95,
      '${SpecialistCategory.photographer.name}_${SpecialistCategory.makeup.name}': 0.7,
      '${SpecialistCategory.decorator.name}_${SpecialistCategory.florist.name}': 0.8,
    };

    final key = '${selected.name}_${recommended.name}';
    return compatibilityScores[key] ?? 0.6;
  }
}

/// Модель автоматической рекомендации
class SpecialistRecommendation {
  const SpecialistRecommendation({
    required this.id,
    required this.specialistId,
    required this.specialist,
    required this.reason,
    required this.score,
    required this.timestamp,
    this.category,
    this.isAutomatic = false,
    this.isShown = false,
    this.isAccepted = false,
  });

  factory SpecialistRecommendation.fromMap(Map<String, dynamic> data) => SpecialistRecommendation(
        id: data['id'] as String? ?? '',
        specialistId: data['specialistId'] as String? ?? '',
        specialist: Specialist.fromMap(
          data['specialist'] as Map<String, dynamic>? ?? {},
        ),
        reason: data['reason'] as String? ?? '',
        score: (data['score'] as num?)?.toDouble() ?? 0.0,
        timestamp:
            data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
        category: data['category'] != null
            ? SpecialistCategory.values.firstWhere(
                (e) => e.name == data['category'] as String,
                orElse: () => SpecialistCategory.other,
              )
            : null,
        isAutomatic: data['isAutomatic'] as bool? ?? false,
        isShown: data['isShown'] as bool? ?? false,
        isAccepted: data['isAccepted'] as bool? ?? false,
      );

  final String id;
  final String specialistId;
  final Specialist specialist;
  final String reason;
  final double score;
  final DateTime timestamp;
  final SpecialistCategory? category;
  final bool isAutomatic;
  final bool isShown;
  final bool isAccepted;

  Map<String, dynamic> toMap() => {
        'id': id,
        'specialistId': specialistId,
        'specialist': specialist.toMap(),
        'reason': reason,
        'score': score,
        'timestamp': Timestamp.fromDate(timestamp),
        'category': category?.name,
        'isAutomatic': isAutomatic,
        'isShown': isShown,
        'isAccepted': isAccepted,
      };
}
