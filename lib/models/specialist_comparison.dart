import '../models/specialist.dart';

/// Модель для сравнения специалистов
class SpecialistComparison {
  const SpecialistComparison(
      {required this.specialists, required this.createdAt});

  /// Создать пустое сравнение
  factory SpecialistComparison.empty() =>
      SpecialistComparison(specialists: [], createdAt: DateTime.now());
  final List<Specialist> specialists;
  final DateTime createdAt;

  /// Максимальное количество специалистов для сравнения
  static const int maxSpecialists = 3;

  /// Добавить специалиста для сравнения
  SpecialistComparison addSpecialist(Specialist specialist) {
    if (specialists.length >= maxSpecialists) {
      throw Exception(
          'Максимальное количество специалистов для сравнения: $maxSpecialists');
    }

    if (specialists.any((s) => s.id == specialist.id)) {
      throw Exception('Специалист уже добавлен для сравнения');
    }

    return SpecialistComparison(
        specialists: [...specialists, specialist], createdAt: createdAt);
  }

  /// Удалить специалиста из сравнения
  SpecialistComparison removeSpecialist(String specialistId) =>
      SpecialistComparison(
        specialists: specialists.where((s) => s.id != specialistId).toList(),
        createdAt: createdAt,
      );

  /// Очистить сравнение
  SpecialistComparison clear() => SpecialistComparison.empty();

  /// Проверить, можно ли добавить специалиста
  bool canAddSpecialist(Specialist specialist) =>
      specialists.length < maxSpecialists &&
      !specialists.any((s) => s.id == specialist.id);

  /// Получить количество специалистов
  int get count => specialists.length;

  /// Проверить, пустое ли сравнение
  bool get isEmpty => specialists.isEmpty;

  /// Проверить, полное ли сравнение
  bool get isFull => specialists.length >= maxSpecialists;

  /// Получить средний рейтинг
  double get averageRating {
    if (specialists.isEmpty) return 0;
    final totalRating = specialists.fold(0, (sum, s) => sum + s.rating);
    return totalRating / specialists.length;
  }

  /// Получить диапазон цен
  PriceRange get priceRange {
    if (specialists.isEmpty) return const PriceRange(min: 0, max: 0);

    final prices = specialists.map((s) => s.hourlyRate).toList();
    prices.sort();

    return PriceRange(min: prices.first, max: prices.last);
  }

  /// Получить диапазон опыта
  ExperienceRange get experienceRange {
    if (specialists.isEmpty) return const ExperienceRange(min: 0, max: 0);

    final experiences = specialists.map((s) => s.yearsOfExperience).toList();
    experiences.sort();

    return ExperienceRange(min: experiences.first, max: experiences.last);
  }

  /// Получить общие категории
  List<SpecialistCategory> get commonCategories {
    if (specialists.isEmpty) return [];

    final allCategories = specialists.expand((s) => [s.category]).toSet();
    return allCategories.toList();
  }

  /// Получить общие услуги
  List<String> get commonServices {
    if (specialists.isEmpty) return [];

    final allServices = specialists.expand((s) => s.services).toSet();
    return allServices.toList();
  }

  /// Получить общие локации
  List<String> get commonLocations {
    if (specialists.isEmpty) return [];

    final allLocations = specialists
        .where((s) => s.location != null && s.location!.isNotEmpty)
        .map((s) => s.location!)
        .toSet();
    return allLocations.toList();
  }

  /// Получить статистику сравнения
  ComparisonStats get stats => ComparisonStats(
        totalSpecialists: specialists.length,
        averageRating: averageRating,
        priceRange: priceRange,
        experienceRange: experienceRange,
        commonCategories: commonCategories,
        commonServices: commonServices,
        commonLocations: commonLocations,
      );
}

/// Диапазон цен
class PriceRange {
  const PriceRange({required this.min, required this.max});
  final double min;
  final double max;

  /// Получить строковое представление
  String get displayString {
    if (min == max) {
      return '${min.toStringAsFixed(0)} ₽/час';
    }
    return '${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)} ₽/час';
  }

  /// Получить разброс цен
  double get spread => max - min;

  /// Проверить, одинаковые ли цены
  bool get isEqual => min == max;
}

/// Диапазон опыта
class ExperienceRange {
  const ExperienceRange({required this.min, required this.max});
  final int min;
  final int max;

  /// Получить строковое представление
  String get displayString {
    if (min == max) {
      return '$min лет';
    }
    return '$min - $max лет';
  }

  /// Получить разброс опыта
  int get spread => max - min;

  /// Проверить, одинаковый ли опыт
  bool get isEqual => min == max;
}

/// Статистика сравнения
class ComparisonStats {
  const ComparisonStats({
    required this.totalSpecialists,
    required this.averageRating,
    required this.priceRange,
    required this.experienceRange,
    required this.commonCategories,
    required this.commonServices,
    required this.commonLocations,
  });
  final int totalSpecialists;
  final double averageRating;
  final PriceRange priceRange;
  final ExperienceRange experienceRange;
  final List<SpecialistCategory> commonCategories;
  final List<String> commonServices;
  final List<String> commonLocations;

  /// Получить лучшего специалиста по рейтингу
  Specialist? getBestByRating(List<Specialist> specialists) {
    if (specialists.isEmpty) return null;

    return specialists.reduce((a, b) => a.rating > b.rating ? a : b);
  }

  /// Получить самого дешевого специалиста
  Specialist? getCheapest(List<Specialist> specialists) {
    if (specialists.isEmpty) return null;

    return specialists.reduce((a, b) => a.hourlyRate < b.hourlyRate ? a : b);
  }

  /// Получить самого дорогого специалиста
  Specialist? getMostExpensive(List<Specialist> specialists) {
    if (specialists.isEmpty) return null;

    return specialists.reduce((a, b) => a.hourlyRate > b.hourlyRate ? a : b);
  }

  /// Получить самого опытного специалиста
  Specialist? getMostExperienced(List<Specialist> specialists) {
    if (specialists.isEmpty) return null;

    return specialists
        .reduce((a, b) => a.yearsOfExperience > b.yearsOfExperience ? a : b);
  }

  /// Получить специалиста с наибольшим количеством отзывов
  Specialist? getMostReviewed(List<Specialist> specialists) {
    if (specialists.isEmpty) return null;

    return specialists.reduce((a, b) => a.reviewCount > b.reviewCount ? a : b);
  }
}

/// Критерии сравнения
enum ComparisonCriteria {
  rating('Рейтинг', 'По рейтингу'),
  price('Цена', 'По цене'),
  experience('Опыт', 'По опыту'),
  reviews('Отзывы', 'По количеству отзывов'),
  availability('Доступность', 'По доступности'),
  location('Локация', 'По локации');

  const ComparisonCriteria(this.label, this.description);

  final String label;
  final String description;
}

/// Результат сравнения по критерию
class ComparisonResult {
  const ComparisonResult(
      {required this.criteria, required this.values, this.winner});
  final ComparisonCriteria criteria;
  final Map<String, dynamic> values;
  final String? winner;

  /// Получить значение для специалиста
  dynamic getValue(String specialistId) => values[specialistId];

  /// Получить строковое представление значения
  String getDisplayValue(String specialistId) {
    final value = getValue(specialistId);
    if (value == null) return 'Н/Д';

    switch (criteria) {
      case ComparisonCriteria.rating:
        return '${(value as double).toStringAsFixed(1)} ⭐';
      case ComparisonCriteria.price:
        return '${(value as double).toStringAsFixed(0)} ₽/час';
      case ComparisonCriteria.experience:
        return '$value лет';
      case ComparisonCriteria.reviews:
        return '$value отзывов';
      case ComparisonCriteria.availability:
        return (value as bool) ? 'Доступен' : 'Занят';
      case ComparisonCriteria.location:
        return value as String;
    }
  }
}
