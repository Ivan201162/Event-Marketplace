/// Простая модель фильтров для специалистов без freezed
class SpecialistFilters {
  const SpecialistFilters({
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.maxRating,
    this.availableDate,
    this.city,
    this.searchQuery,
    this.subcategories = const [],
    this.isVerified,
    this.isAvailable,
  });

  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final double? maxRating;
  final DateTime? availableDate;
  final String? city;
  final String? searchQuery;
  final List<String> subcategories;
  final bool? isVerified;
  final bool? isAvailable;

  /// Проверить, есть ли активные фильтры
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
      isAvailable != null;

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
    return count;
  }

  /// Очистить фильтр по цене
  SpecialistFilters clearPriceFilter() => copyWith();

  /// Очистить фильтр по рейтингу
  SpecialistFilters clearRatingFilter() => copyWith();

  /// Очистить фильтр по дате
  SpecialistFilters clearDateFilter() => copyWith();

  /// Очистить фильтр по городу
  SpecialistFilters clearCityFilter() => copyWith();

  /// Очистить поисковый запрос
  SpecialistFilters clearSearchFilter() => copyWith();

  /// Очистить фильтр по подкатегориям
  SpecialistFilters clearSubcategoriesFilter() => copyWith(subcategories: []);

  /// Очистить фильтры по статусу
  SpecialistFilters clearStatusFilters() => copyWith();

  /// Создать копию с изменениями
  SpecialistFilters copyWith({
    double? minPrice,
    double? maxPrice,
    double? minRating,
    double? maxRating,
    DateTime? availableDate,
    String? city,
    String? searchQuery,
    List<String>? subcategories,
    bool? isVerified,
    bool? isAvailable,
  }) => SpecialistFilters(
    minPrice: minPrice ?? this.minPrice,
    maxPrice: maxPrice ?? this.maxPrice,
    minRating: minRating ?? this.minRating,
    maxRating: maxRating ?? this.maxRating,
    availableDate: availableDate ?? this.availableDate,
    city: city ?? this.city,
    searchQuery: searchQuery ?? this.searchQuery,
    subcategories: subcategories ?? this.subcategories,
    isVerified: isVerified ?? this.isVerified,
    isAvailable: isAvailable ?? this.isAvailable,
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
        other.subcategories == subcategories &&
        other.isVerified == isVerified &&
        other.isAvailable == isAvailable;
  }

  @override
  int get hashCode =>
      minPrice.hashCode ^
      maxPrice.hashCode ^
      minRating.hashCode ^
      maxRating.hashCode ^
      availableDate.hashCode ^
      city.hashCode ^
      searchQuery.hashCode ^
      subcategories.hashCode ^
      isVerified.hashCode ^
      isAvailable.hashCode;

  @override
  String toString() =>
      'SpecialistFilters(minPrice: $minPrice, maxPrice: $maxPrice, minRating: $minRating, maxRating: $maxRating, availableDate: $availableDate, city: $city, searchQuery: $searchQuery, subcategories: $subcategories, isVerified: $isVerified, isAvailable: $isAvailable)';
}
