import 'specialist.dart';

/// Фильтры для специалистов
class SpecialistFilters {
  const SpecialistFilters({
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.maxRating,
    this.availableDate,
    this.city,
    this.location,
    this.searchQuery,
    this.subcategories = const [],
    this.isVerified,
    this.isAvailable,
    this.sortBy,
    this.sortAscending = false,
    this.maxHourlyRate,
    this.category,
    this.minExperienceLevel,
    this.serviceAreas = const [],
    this.languages = const [],
  });

  /// Минимальная цена
  final double? minPrice;

  /// Максимальная цена
  final double? maxPrice;

  /// Минимальный рейтинг
  final double? minRating;

  /// Максимальный рейтинг
  final double? maxRating;

  /// Доступная дата
  final DateTime? availableDate;

  /// Город
  final String? city;

  /// Местоположение
  final String? location;

  /// Поисковый запрос
  final String? searchQuery;

  /// Подкатегории
  final List<String> subcategories;

  /// Только верифицированные
  final bool? isVerified;

  /// Только доступные
  final bool? isAvailable;

  /// Сортировка
  final SpecialistSortOption? sortBy;

  /// Порядок сортировки (true - по возрастанию, false - по убыванию)
  final bool sortAscending;

  /// Максимальная почасовая ставка
  final double? maxHourlyRate;

  /// Категория специалиста
  final SpecialistCategory? category;

  /// Минимальный уровень опыта
  final ExperienceLevel? minExperienceLevel;

  /// Области обслуживания
  final List<String> serviceAreas;

  /// Языки
  final List<String> languages;

  /// Создать копию с изменениями
  SpecialistFilters copyWith({
    double? minPrice,
    double? maxPrice,
    double? minRating,
    double? maxRating,
    DateTime? availableDate,
    String? city,
    String? location,
    String? searchQuery,
    List<String>? subcategories,
    bool? isVerified,
    bool? isAvailable,
    SpecialistSortOption? sortBy,
    bool? sortAscending,
    double? maxHourlyRate,
    SpecialistCategory? category,
    ExperienceLevel? minExperienceLevel,
    List<String>? serviceAreas,
    List<String>? languages,
  }) =>
      SpecialistFilters(
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        minRating: minRating ?? this.minRating,
        maxRating: maxRating ?? this.maxRating,
        availableDate: availableDate ?? this.availableDate,
        city: city ?? this.city,
        location: location ?? this.location,
        searchQuery: searchQuery ?? this.searchQuery,
        subcategories: subcategories ?? this.subcategories,
        isVerified: isVerified ?? this.isVerified,
        isAvailable: isAvailable ?? this.isAvailable,
        maxHourlyRate: maxHourlyRate ?? this.maxHourlyRate,
        category: category ?? this.category,
        minExperienceLevel: minExperienceLevel ?? this.minExperienceLevel,
        serviceAreas: serviceAreas ?? this.serviceAreas,
        languages: languages ?? this.languages,
        sortBy: sortBy ?? this.sortBy,
        sortAscending: sortAscending ?? this.sortAscending,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpecialistFilters &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        other.minRating == minRating &&
        other.maxRating == maxRating &&
        other.availableDate == availableDate &&
        other.city == city &&
        other.searchQuery == searchQuery &&
        _listEquals(other.subcategories, subcategories) &&
        other.isVerified == isVerified &&
        other.isAvailable == isAvailable &&
        other.sortBy == sortBy &&
        other.sortAscending == sortAscending;
  }

  @override
  int get hashCode => Object.hash(
        minPrice,
        maxPrice,
        minRating,
        maxRating,
        availableDate,
        city,
        searchQuery,
        subcategories,
        isVerified,
        isAvailable,
        sortBy,
        sortAscending,
      );

  /// Сравнение списков
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (var index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  /// Проверка, есть ли активные фильтры
  bool get hasActiveFilters =>
      minPrice != null ||
      maxPrice != null ||
      minRating != null ||
      maxRating != null ||
      availableDate != null ||
      city != null ||
      (searchQuery != null && searchQuery!.isNotEmpty) ||
      subcategories.isNotEmpty ||
      isVerified != null ||
      isAvailable != null ||
      sortBy != null;

  /// Получить количество активных фильтров
  int get activeFiltersCount {
    var count = 0;
    if (minPrice != null) count++;
    if (maxPrice != null) count++;
    if (minRating != null) count++;
    if (maxRating != null) count++;
    if (availableDate != null) count++;
    if (city != null) count++;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    if (subcategories.isNotEmpty) count++;
    if (isVerified != null) count++;
    if (isAvailable != null) count++;
    if (sortBy != null) count++;
    return count;
  }

  /// Сбросить все фильтры
  SpecialistFilters clearAll() => const SpecialistFilters();

  /// Сбросить фильтры по цене
  SpecialistFilters clearPriceFilters() => copyWith();

  /// Сбросить фильтры по рейтингу
  SpecialistFilters clearRatingFilters() => copyWith();

  /// Сбросить фильтр по дате
  SpecialistFilters clearDateFilter() => copyWith();

  /// Сбросить фильтр по городу
  SpecialistFilters clearCityFilter() => copyWith();

  /// Сбросить поисковый запрос
  SpecialistFilters clearSearchQuery() => copyWith();

  /// Сбросить подкатегории
  SpecialistFilters clearSubcategories() => copyWith(subcategories: []);

  /// Сбросить фильтры верификации
  SpecialistFilters clearVerificationFilters() => copyWith();

  /// Сбросить сортировку
  SpecialistFilters clearSorting() => copyWith(sortAscending: false);
}

/// Опции сортировки специалистов
enum SpecialistSortOption {
  rating('rating', 'По рейтингу'),
  price('price', 'По цене'),
  experience('experience', 'По опыту'),
  reviews('reviews', 'По отзывам'),
  name('name', 'По имени'),
  dateAdded('dateAdded', 'По дате добавления');

  const SpecialistSortOption(this.value, this.label);

  final String value;
  final String label;
}

/// Опции рейтинга для фильтра
class RatingFilterOption {
  const RatingFilterOption({
    required this.minRating,
    required this.label,
    required this.description,
  });
  final double minRating;
  final String label;
  final String description;

  static const List<RatingFilterOption> options = [
    RatingFilterOption(minRating: 4.5, label: '4.5+', description: 'Отлично'),
    RatingFilterOption(
        minRating: 4, label: '4.0+', description: 'Очень хорошо'),
    RatingFilterOption(minRating: 3.5, label: '3.5+', description: 'Хорошо'),
    RatingFilterOption(
        minRating: 3, label: '3.0+', description: 'Удовлетворительно'),
  ];
}

/// Опции цены для фильтра
class PriceFilterOption {
  const PriceFilterOption({
    this.minPrice,
    this.maxPrice,
    required this.label,
    required this.description,
  });
  final double? minPrice;
  final double? maxPrice;
  final String label;
  final String description;

  static const List<PriceFilterOption> options = [
    PriceFilterOption(
        maxPrice: 10000,
        label: 'До 10 000 ₽',
        description: 'Бюджетный вариант'),
    PriceFilterOption(
      minPrice: 10000,
      maxPrice: 25000,
      label: '10 000 - 25 000 ₽',
      description: 'Средний ценовой сегмент',
    ),
    PriceFilterOption(
      minPrice: 25000,
      maxPrice: 50000,
      label: '25 000 - 50 000 ₽',
      description: 'Премиум сегмент',
    ),
    PriceFilterOption(
        minPrice: 50000, label: 'От 50 000 ₽', description: 'Люкс сегмент'),
  ];
}
