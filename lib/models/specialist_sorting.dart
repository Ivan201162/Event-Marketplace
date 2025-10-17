import 'price_range.dart';
import 'specialist.dart';

/// Опции сортировки для специалистов
enum SpecialistSortOption {
  /// По умолчанию (без сортировки)
  none('none', 'По умолчанию', 'Стандартный порядок'),

  /// По цене (возрастание)
  priceAsc('priceAsc', 'Цена: по возрастанию', 'От дешевых к дорогим'),

  /// По цене (убывание)
  priceDesc('priceDesc', 'Цена: по убыванию', 'От дорогих к дешевым'),

  /// По рейтингу (от высшего к низшему)
  rating('rating', 'По рейтингу', 'От высокого к низкому'),

  /// По популярности (по количеству отзывов)
  popularity('popularity', 'По популярности', 'По количеству отзывов'),

  /// По имени (А-Я)
  nameAsc('nameAsc', 'Имя: А-Я', 'По алфавиту'),

  /// По имени (Я-А)
  nameDesc('nameDesc', 'Имя: Я-А', 'Обратный алфавит'),

  /// По дате добавления (новые сначала)
  dateNewest('dateNewest', 'Новые сначала', 'Недавно добавленные'),

  /// По дате добавления (старые сначала)
  dateOldest('dateOldest', 'Старые сначала', 'Добавленные давно');

  const SpecialistSortOption(this.value, this.label, this.description);

  /// Значение для API
  final String value;

  /// Отображаемое название
  final String label;

  /// Описание сортировки
  final String description;

  /// Получить опцию по значению
  static SpecialistSortOption? fromValue(String value) {
    try {
      return SpecialistSortOption.values.firstWhere((option) => option.value == value);
    } catch (e) {
      return null;
    }
  }

  /// Получить все опции сортировки
  static List<SpecialistSortOption> get allOptions => SpecialistSortOption.values;

  /// Получить популярные опции сортировки
  static List<SpecialistSortOption> get popularOptions => [
        SpecialistSortOption.priceAsc,
        SpecialistSortOption.priceDesc,
        SpecialistSortOption.rating,
        SpecialistSortOption.popularity,
      ];

  /// Получить расширенные опции сортировки
  static List<SpecialistSortOption> get extendedOptions => [
        SpecialistSortOption.nameAsc,
        SpecialistSortOption.nameDesc,
        SpecialistSortOption.dateNewest,
        SpecialistSortOption.dateOldest,
      ];
}

/// Класс для управления сортировкой специалистов
class SpecialistSorting {
  const SpecialistSorting({
    this.sortOption = SpecialistSortOption.none,
    this.isAscending = true,
  });
  final SpecialistSortOption sortOption;
  final bool isAscending;

  /// Создать копию с изменениями
  SpecialistSorting copyWith({
    SpecialistSortOption? sortOption,
    bool? isAscending,
  }) =>
      SpecialistSorting(
        sortOption: sortOption ?? this.sortOption,
        isAscending: isAscending ?? this.isAscending,
      );

  /// Проверить, активна ли сортировка
  bool get isActive => sortOption != SpecialistSortOption.none;

  /// Получить отображаемое название
  String get displayName => sortOption.label;

  /// Получить описание
  String get description => sortOption.description;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpecialistSorting &&
        other.sortOption == sortOption &&
        other.isAscending == isAscending;
  }

  @override
  int get hashCode => Object.hash(sortOption, isAscending);

  @override
  String toString() => 'SpecialistSorting(sortOption: $sortOption, isAscending: $isAscending)';
}

/// Утилиты для сортировки специалистов
class SpecialistSortingUtils {
  /// Сортировать список специалистов
  static List<Specialist> sortSpecialists(
    List<Specialist> specialists,
    SpecialistSorting sorting,
  ) {
    if (!sorting.isActive) {
      return specialists;
    }

    final sortedList = List<Specialist>.from(specialists);

    switch (sorting.sortOption) {
      case SpecialistSortOption.priceAsc:
        sortedList.sort((a, b) => _comparePrice(a, b, true));
        break;
      case SpecialistSortOption.priceDesc:
        sortedList.sort((a, b) => _comparePrice(a, b, false));
        break;
      case SpecialistSortOption.rating:
        sortedList.sort((a, b) => _compareRating(a, b, false));
        break;
      case SpecialistSortOption.popularity:
        sortedList.sort((a, b) => _comparePopularity(a, b, false));
        break;
      case SpecialistSortOption.nameAsc:
        sortedList.sort((a, b) => _compareName(a, b, true));
        break;
      case SpecialistSortOption.nameDesc:
        sortedList.sort((a, b) => _compareName(a, b, false));
        break;
      case SpecialistSortOption.dateNewest:
        sortedList.sort((a, b) => _compareDate(a, b, false));
        break;
      case SpecialistSortOption.dateOldest:
        sortedList.sort((a, b) => _compareDate(a, b, true));
        break;
      case SpecialistSortOption.none:
        // Без сортировки
        break;
    }

    return sortedList;
  }

  /// Сравнение по цене
  static int _comparePrice(Specialist a, Specialist b, bool ascending) {
    final priceA = a.priceRange?.minPrice ?? 0;
    final priceB = b.priceRange?.minPrice ?? 0;

    if (ascending) {
      return priceA.compareTo(priceB);
    } else {
      return priceB.compareTo(priceA);
    }
  }

  /// Сравнение по рейтингу
  static int _compareRating(Specialist a, Specialist b, bool ascending) {
    if (ascending) {
      return a.rating.compareTo(b.rating);
    } else {
      return b.rating.compareTo(a.rating);
    }
  }

  /// Сравнение по популярности (количество отзывов)
  static int _comparePopularity(Specialist a, Specialist b, bool ascending) {
    final reviewsA = a.totalReviews ?? 0;
    final reviewsB = b.totalReviews ?? 0;
    if (ascending) {
      return reviewsA.compareTo(reviewsB);
    } else {
      return reviewsB.compareTo(reviewsA);
    }
  }

  /// Сравнение по имени
  static int _compareName(Specialist a, Specialist b, bool ascending) {
    final nameA = '${a.firstName} ${a.lastName}';
    final nameB = '${b.firstName} ${b.lastName}';

    if (ascending) {
      return nameA.compareTo(nameB);
    } else {
      return nameB.compareTo(nameA);
    }
  }

  /// Сравнение по дате добавления
  static int _compareDate(Specialist a, Specialist b, bool ascending) {
    if (ascending) {
      return a.createdAt.compareTo(b.createdAt);
    } else {
      return b.createdAt.compareTo(a.createdAt);
    }
  }

  /// Получить статистику сортировки
  static SortStats getSortStats(
    List<Specialist> specialists,
    SpecialistSorting sorting,
  ) {
    if (specialists.isEmpty) {
      return const SortStats(
        totalCount: 0,
        priceRange: null,
        averageRating: 0,
        averageReviews: 0,
      );
    }

    var minPrice = double.infinity;
    double maxPrice = 0;
    double totalRating = 0;
    var totalReviews = 0;

    for (final specialist in specialists) {
      // Ценовой диапазон
      final priceRange = specialist.priceRange;
      if (priceRange != null) {
        if (priceRange.minPrice < minPrice) minPrice = priceRange.minPrice;
        if (priceRange.maxPrice > maxPrice) maxPrice = priceRange.maxPrice;
      }

      // Рейтинг и отзывы
      totalRating += specialist.rating;
      totalReviews += specialist.totalReviews ?? 0;
    }

    return SortStats(
      totalCount: specialists.length,
      priceRange:
          minPrice != double.infinity ? PriceRange(minPrice: minPrice, maxPrice: maxPrice) : null,
      averageRating: totalRating / specialists.length,
      averageReviews: totalReviews / specialists.length,
    );
  }
}

/// Статистика сортировки
class SortStats {
  const SortStats({
    required this.totalCount,
    required this.priceRange,
    required this.averageRating,
    required this.averageReviews,
  });
  final int totalCount;
  final PriceRange? priceRange;
  final double averageRating;
  final double averageReviews;
}
