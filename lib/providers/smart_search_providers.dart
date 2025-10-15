import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/smart_search_service.dart';

/// Провайдер сервиса умного поиска
final smartSearchServiceProvider =
    Provider<SmartSearchService>((ref) => SmartSearchService());

/// Провайдер подсказок поиска
final searchSuggestionsProvider =
    FutureProvider.family<List<SearchSuggestion>, String>((ref, query) async {
  final service = ref.read(smartSearchServiceProvider);
  return service.getSearchSuggestions(query);
});

/// Провайдер результатов поиска специалистов
final searchResultsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, SearchParams>(
        (ref, params) async {
  final service = ref.read(smartSearchServiceProvider);
  return service.searchSpecialists(
    query: params.query,
    category: params.category,
    city: params.city,
    minPrice: params.minPrice,
    maxPrice: params.maxPrice,
    minRating: params.minRating,
    availableDate: params.availableDate,
    sortBy: params.sortBy,
  );
});

/// Провайдер популярных специалистов
final popularSpecialistsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(smartSearchServiceProvider);
  return service.getPopularSpecialists();
});

/// Провайдер популярных специалистов недели
final weeklyPopularSpecialistsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(smartSearchServiceProvider);
  return service.getWeeklyPopularSpecialists();
});

/// Провайдер сохранённых фильтров поиска
final savedSearchFiltersProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(smartSearchServiceProvider);
  return service.loadSearchFilters();
});

/// Параметры поиска
class SearchParams {
  const SearchParams({
    this.query,
    this.category,
    this.city,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.availableDate,
    this.sortBy,
  });
  final String? query;
  final String? category;
  final String? city;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final DateTime? availableDate;
  final SpecialistSortOption? sortBy;

  SearchParams copyWith({
    String? query,
    String? category,
    String? city,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    DateTime? availableDate,
    SpecialistSortOption? sortBy,
  }) =>
      SearchParams(
        query: query ?? this.query,
        category: category ?? this.category,
        city: city ?? this.city,
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        minRating: minRating ?? this.minRating,
        availableDate: availableDate ?? this.availableDate,
        sortBy: sortBy ?? this.sortBy,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchParams &&
        other.query == query &&
        other.category == category &&
        other.city == city &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        other.minRating == minRating &&
        other.availableDate == availableDate &&
        other.sortBy == sortBy;
  }

  @override
  int get hashCode => Object.hash(
        query,
        category,
        city,
        minPrice,
        maxPrice,
        minRating,
        availableDate,
        sortBy,
      );
}
