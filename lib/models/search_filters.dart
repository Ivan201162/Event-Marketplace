import 'package:freezed_annotation/freezed_annotation.dart';
import '../core/stubs/stubs.dart';

part 'search_filters.freezed.dart';
part 'search_filters.g.dart';

/// Фильтры для поиска специалистов
@freezed
class SpecialistSearchFilters with _$SpecialistSearchFilters {
  const factory SpecialistSearchFilters({
    @Default([]) List<String> categories,
    @Default([]) List<String> services,
    @Default([]) List<String> locations,
    @Default(0.0) double minRating,
    @Default(5.0) double maxRating,
    @Default(0) int minPrice,
    @Default(100000) int maxPrice,
    DateTime? availableFrom,
    DateTime? availableTo,
    @Default(false) bool isAvailableNow,
    @Default(false) bool hasPortfolio,
    @Default(false) bool isVerified,
    @Default(false) bool hasReviews,
    @Default('') String searchQuery,
    @Default(SearchSortBy.relevance) SearchSortBy sortBy,
  }) = _SpecialistSearchFilters;

  factory SpecialistSearchFilters.fromJson(Map<String, dynamic> json) =>
      _$SpecialistSearchFiltersFromJson(json);
}

/// Варианты сортировки
enum SearchSortBy {
  relevance,
  rating,
  priceAsc,
  priceDesc,
  distance,
  availability,
  reviewsCount,
}

/// Результат поиска специалистов
@freezed
class SpecialistSearchResult with _$SpecialistSearchResult {
  const factory SpecialistSearchResult({
    required String specialistId,
    required String name,
    required String avatar,
    required double rating,
    required int reviewCount,
    required int priceFrom,
    required List<String> categories,
    required List<String> services,
    required String location,
    required bool isAvailable,
    required bool isVerified,
    required bool hasPortfolio,
    DateTime? nextAvailableDate,
    double? distance,
  }) = _SpecialistSearchResult;

  factory SpecialistSearchResult.fromJson(Map<String, dynamic> json) =>
      _$SpecialistSearchResultFromJson(json);
}

/// Состояние поиска
@freezed
class SearchState with _$SearchState {
  const factory SearchState({
    @Default([]) List<SpecialistSearchResult> results,
    @Default(false) bool isLoading,
    @Default(false) bool hasMore,
    @Default('') String error,
    @Default(SpecialistSearchFilters()) SpecialistSearchFilters filters,
    @Default(0) int totalCount,
  }) = _SearchState;

  factory SearchState.fromJson(Map<String, dynamic> json) =>
      _$SearchStateFromJson(json);
}
