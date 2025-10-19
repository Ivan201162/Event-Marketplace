import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist.dart';
import '../models/specialist_comparison.dart';

/// Провайдер для управления сравнением специалистов (мигрирован с StateNotifierProvider)
final specialistComparisonProvider =
    NotifierProvider<SpecialistComparisonNotifier, SpecialistComparison>(
  () => SpecialistComparisonNotifier(),
);

/// Нотификатор для сравнения специалистов (мигрирован с StateNotifier)
class SpecialistComparisonNotifier extends Notifier<SpecialistComparison> {
  @override
  SpecialistComparison build() {
    return SpecialistComparison.empty();
  }

  /// Добавить специалиста для сравнения
  void addSpecialist(Specialist specialist) {
    try {
      state = state.addSpecialist(specialist);
    } on Exception {
      // Ошибка уже обработана в модели
      rethrow;
    }
  }

  /// Удалить специалиста из сравнения
  void removeSpecialist(String specialistId) {
    state = state.removeSpecialist(specialistId);
  }

  /// Очистить сравнение
  void clear() {
    state = state.clear();
  }

  /// Проверить, можно ли добавить специалиста
  bool canAddSpecialist(Specialist specialist) => state.canAddSpecialist(specialist);

  /// Проверить, добавлен ли специалист
  bool isSpecialistAdded(String specialistId) => state.specialists.any((s) => s.id == specialistId);

  /// Получить количество специалистов
  int get specialistCount => state.count;

  /// Проверить, пустое ли сравнение
  bool get isEmpty => state.isEmpty;

  /// Проверить, полное ли сравнение
  bool get isFull => state.isFull;
}

/// Провайдер для получения статистики сравнения
final comparisonStatsProvider = Provider<ComparisonStats>((ref) {
  final comparison = ref.watch(specialistComparisonProvider);
  return comparison.stats;
});

/// Провайдер для получения лучшего специалиста по рейтингу
final bestSpecialistByRatingProvider = Provider<Specialist?>((ref) {
  final comparison = ref.watch(specialistComparisonProvider);
  final stats = ref.watch(comparisonStatsProvider);
  return stats.getBestByRating(comparison.specialists);
});

/// Провайдер для получения самого дешевого специалиста
final cheapestSpecialistProvider = Provider<Specialist?>((ref) {
  final comparison = ref.watch(specialistComparisonProvider);
  final stats = ref.watch(comparisonStatsProvider);
  return stats.getCheapest(comparison.specialists);
});

/// Провайдер для получения самого дорогого специалиста
final mostExpensiveSpecialistProvider = Provider<Specialist?>((ref) {
  final comparison = ref.watch(specialistComparisonProvider);
  final stats = ref.watch(comparisonStatsProvider);
  return stats.getMostExpensive(comparison.specialists);
});

/// Провайдер для получения самого опытного специалиста
final mostExperiencedSpecialistProvider = Provider<Specialist?>((ref) {
  final comparison = ref.watch(specialistComparisonProvider);
  final stats = ref.watch(comparisonStatsProvider);
  return stats.getMostExperienced(comparison.specialists);
});

/// Провайдер для получения специалиста с наибольшим количеством отзывов
final mostReviewedSpecialistProvider = Provider<Specialist?>((ref) {
  final comparison = ref.watch(specialistComparisonProvider);
  final stats = ref.watch(comparisonStatsProvider);
  return stats.getMostReviewed(comparison.specialists);
});

/// Провайдер для получения диапазона цен
final priceRangeProvider = Provider<PriceRange>((ref) {
  final comparison = ref.watch(specialistComparisonProvider);
  return comparison.priceRange;
});

/// Провайдер для получения диапазона опыта
final experienceRangeProvider = Provider<ExperienceRange>((ref) {
  final comparison = ref.watch(specialistComparisonProvider);
  return comparison.experienceRange;
});

/// Провайдер для получения общих категорий
final commonCategoriesProvider = Provider<List<SpecialistCategory>>((ref) {
  final comparison = ref.watch(specialistComparisonProvider);
  return comparison.commonCategories;
});

/// Провайдер для получения общих услуг
final commonServicesProvider = Provider<List<String>>((ref) {
  final comparison = ref.watch(specialistComparisonProvider);
  return comparison.commonServices;
});

/// Провайдер для получения общих локаций
final commonLocationsProvider = Provider<List<String>>((ref) {
  final comparison = ref.watch(specialistComparisonProvider);
  return comparison.commonLocations;
});

/// Провайдер для получения среднего рейтинга
final averageRatingProvider = Provider<double>((ref) {
  final comparison = ref.watch(specialistComparisonProvider);
  return comparison.averageRating;
});

/// Провайдер для проверки, добавлен ли конкретный специалист
final isSpecialistInComparisonProvider = Provider.family<bool, String>((ref, specialistId) {
  final comparison = ref.watch(specialistComparisonProvider);
  return comparison.specialists.any((s) => s.id == specialistId);
});

/// Провайдер для получения количества специалистов в сравнении
final comparisonCountProvider = Provider<int>((ref) {
  final comparison = ref.watch(specialistComparisonProvider);
  return comparison.count;
});

/// Провайдер для проверки, можно ли добавить специалиста
final canAddSpecialistProvider = Provider.family<bool, Specialist>((ref, specialist) {
  final comparison = ref.watch(specialistComparisonProvider);
  return comparison.canAddSpecialist(specialist);
});

/// Провайдер для получения результатов сравнения по критериям
final comparisonResultsProvider = Provider<List<ComparisonResult>>((ref) {
  final comparison = ref.watch(specialistComparisonProvider);
  final results = <ComparisonResult>[];

  for (final criteria in ComparisonCriteria.values) {
    final values = <String, dynamic>{};
    String? winner;

    for (final specialist in comparison.specialists) {
      dynamic value;

      switch (criteria) {
        case ComparisonCriteria.rating:
          value = specialist.rating;
          break;
        case ComparisonCriteria.price:
          value = specialist.hourlyRate;
          break;
        case ComparisonCriteria.experience:
          value = specialist.yearsOfExperience;
          break;
        case ComparisonCriteria.reviews:
          value = specialist.reviewCount;
          break;
        case ComparisonCriteria.availability:
          value = specialist.isAvailable;
          break;
        case ComparisonCriteria.location:
          value = specialist.location ?? '';
          break;
      }

      values[specialist.id] = value;
    }

    // Определяем победителя
    if (values.isNotEmpty) {
      switch (criteria) {
        case ComparisonCriteria.rating:
        case ComparisonCriteria.experience:
        case ComparisonCriteria.reviews:
          winner = values.entries
              .reduce(
                (a, b) => (a.value as Comparable).compareTo(b.value) > 0 ? a : b,
              )
              .key;
          break;
        case ComparisonCriteria.price:
          winner = values.entries
              .reduce(
                (a, b) => (a.value as double) < (b.value as double) ? a : b,
              )
              .key;
          break;
        case ComparisonCriteria.availability:
          winner = values.entries
              .firstWhere(
                (e) => e.value == true,
                orElse: () => values.entries.first,
              )
              .key;
          break;
        case ComparisonCriteria.location:
          winner = null; // Все равны по локации
          break;
      }
    }

    results.add(
      ComparisonResult(
        criteria: criteria,
        values: values,
        winner: winner,
      ),
    );
  }

  return results;
});
