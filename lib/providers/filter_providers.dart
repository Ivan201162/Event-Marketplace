import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/price_range.dart';
import '../models/specialist_filters_simple.dart';
import '../services/mock_data_service.dart';

/// Провайдер для состояния фильтров специалистов (мигрирован с StateNotifierProvider)
final specialistFiltersProvider = NotifierProvider<SpecialistFiltersNotifier, SpecialistFilters>(
  () => SpecialistFiltersNotifier(),
);

/// Провайдер для отфильтрованных специалистов
final filteredSpecialistsProvider = FutureProvider.family<List<Specialist>, FilterParams>(
  (ref, params) async => MockDataService.getFilteredSpecialists(
    categoryId: params.categoryId,
    filters: params.filters,
  ),
);

/// Параметры для фильтрации
class FilterParams {
  const FilterParams({this.categoryId, required this.filters});
  final String? categoryId;
  final SpecialistFilters filters;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterParams && other.categoryId == categoryId && other.filters == filters;
  }

  @override
  int get hashCode => Object.hash(categoryId, filters);
}

/// Notifier для управления фильтрами специалистов (мигрирован с StateNotifier)
class SpecialistFiltersNotifier extends Notifier<SpecialistFilters> {
  @override
  SpecialistFilters build() {
    return const SpecialistFilters();
  }

  /// Обновить фильтры
  void updateFilters(SpecialistFilters newFilters) {
    state = newFilters;
  }

  /// Сбросить все фильтры
  void clearAllFilters() {
    state = const SpecialistFilters();
  }

  /// Установить фильтр по цене
  void setPriceFilter({double? minPrice, double? maxPrice}) {
    state = state.copyWith(minPrice: minPrice, maxPrice: maxPrice);
  }

  /// Установить фильтр по рейтингу
  void setRatingFilter({double? minRating, double? maxRating}) {
    state = state.copyWith(minRating: minRating, maxRating: maxRating);
  }

  /// Установить фильтр по дате
  void setDateFilter(DateTime? date) {
    state = state.copyWith(availableDate: date);
  }

  /// Установить фильтр по городу
  void setCityFilter(String? city) {
    state = state.copyWith(city: city);
  }

  /// Установить поисковый запрос
  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Установить подкатегории
  void setSubcategories(List<String> subcategories) {
    state = state.copyWith(subcategories: subcategories);
  }

  /// Установить фильтр верификации
  void setVerificationFilter(bool? isVerified) {
    state = state.copyWith(isVerified: isVerified);
  }

  /// Установить фильтр доступности
  void setAvailabilityFilter(bool? isAvailable) {
    state = state.copyWith(isAvailable: isAvailable);
  }

  /// Сбросить фильтры по цене
  void clearPriceFilters() {
    state = state.clearPriceFilters();
  }

  /// Сбросить фильтры по рейтингу
  void clearRatingFilters() {
    state = state.clearRatingFilters();
  }

  /// Сбросить фильтр по дате
  void clearDateFilter() {
    state = state.clearDateFilter();
  }

  /// Сбросить фильтр по городу
  void clearCityFilter() {
    state = state.clearCityFilter();
  }

  /// Сбросить поисковый запрос
  void clearSearchQuery() {
    state = state.clearSearchQuery();
  }

  /// Сбросить подкатегории
  void clearSubcategories() {
    state = state.clearSubcategories();
  }

  /// Сбросить фильтры верификации
  void clearVerificationFilters() {
    state = state.clearVerificationFilters();
  }
}

/// Провайдер для получения уникальных городов из всех специалистов
final allCitiesProvider = FutureProvider<List<String>>((ref) async {
  final allSpecialists = MockDataService.getAllSpecialists();
  final cities = allSpecialists.map((specialist) => specialist.city).toSet().toList();
  cities.sort();
  return cities;
});

/// Провайдер для получения уникальных городов по категории
final categoryCitiesProvider = FutureProvider.family<List<String>, String>((ref, categoryId) async {
  final specialists = MockDataService.getSpecialistsByCategory(categoryId);
  final cities = specialists.map((specialist) => specialist.city).toSet().toList();
  cities.sort();
  return cities;
});

/// Провайдер для получения ценового диапазона всех специалистов
final allPriceRangeProvider = FutureProvider<Map<String, double>>((ref) async {
  final allSpecialists = MockDataService.getAllSpecialists();
  var minPrice = double.infinity;
  double maxPrice = 0;

  for (final specialist in allSpecialists) {
    final priceRange = specialist.priceRange;
    if (priceRange != null) {
      if (priceRange.minPrice < minPrice) minPrice = priceRange.minPrice;
      if (priceRange.maxPrice > maxPrice) maxPrice = priceRange.maxPrice;
    }
  }

  return {'min': minPrice == double.infinity ? 0 : minPrice, 'max': maxPrice};
});

/// Провайдер для получения ценового диапазона по категории
final categoryPriceRangeProvider = FutureProvider.family<Map<String, double>, String>((
  ref,
  categoryId,
) async {
  final specialists = MockDataService.getSpecialistsByCategory(categoryId);
  var minPrice = double.infinity;
  double maxPrice = 0;

  for (final specialist in specialists) {
    final priceRange = specialist.priceRange;
    if (priceRange != null) {
      if (priceRange.minPrice < minPrice) minPrice = priceRange.minPrice;
      if (priceRange.maxPrice > maxPrice) maxPrice = priceRange.maxPrice;
    }
  }

  return {'min': minPrice == double.infinity ? 0 : minPrice, 'max': maxPrice};
});

/// Провайдер для получения подкатегорий по категории
final categorySubcategoriesProvider = FutureProvider.family<List<String>, String>((
  ref,
  categoryId,
) async {
  final specialists = MockDataService.getSpecialistsByCategory(categoryId);
  final subcategories = <String>{};

  for (final specialist in specialists) {
    subcategories.addAll(specialist.subcategories);
  }

  final result = subcategories.toList();
  result.sort();
  return result;
});

/// Провайдер для статистики фильтров
final filterStatsProvider = Provider.family<FilterStats, FilterParams>((ref, params) {
  final specialists = ref.watch(filteredSpecialistsProvider(params));

  return specialists.when(
    data: (specialists) => FilterStats(
      totalCount: specialists.length,
      averageRating: specialists.isNotEmpty
          ? specialists.map((s) => s.rating).reduce((a, b) => a + b) / specialists.length
          : 0,
      priceRange: specialists.isNotEmpty ? _calculatePriceRange(specialists) : null,
      cities: specialists.map((s) => s.city).toSet().toList(),
    ),
    loading: () => const FilterStats(totalCount: 0, averageRating: 0, priceRange: null, cities: []),
    error: (_, __) =>
        const FilterStats(totalCount: 0, averageRating: 0, priceRange: null, cities: []),
  );
});

/// Статистика фильтров
class FilterStats {
  const FilterStats({
    required this.totalCount,
    required this.averageRating,
    required this.priceRange,
    required this.cities,
  });
  final int totalCount;
  final double averageRating;
  final PriceRange? priceRange;
  final List<String> cities;
}

/// Вычисление ценового диапазона из списка специалистов
PriceRange? _calculatePriceRange(List<Specialist> specialists) {
  var minPrice = double.infinity;
  double maxPrice = 0;
  var hasPrice = false;

  for (final specialist in specialists) {
    final priceRange = specialist.priceRange;
    if (priceRange != null) {
      hasPrice = true;
      if (priceRange.minPrice < minPrice) minPrice = priceRange.minPrice;
      if (priceRange.maxPrice > maxPrice) maxPrice = priceRange.maxPrice;
    }
  }

  if (!hasPrice) return null;

  return PriceRange(min: minPrice == double.infinity ? 0 : minPrice, max: maxPrice);
}
