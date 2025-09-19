import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/search_filters.dart';
import '../services/advanced_search_service.dart';

part 'advanced_search_providers.g.dart';

/// Провайдер сервиса расширенного поиска
@riverpod
AdvancedSearchService advancedSearchService(AdvancedSearchServiceRef ref) =>
    AdvancedSearchService();

/// Провайдер состояния поиска
@riverpod
class SearchStateNotifier extends _$SearchStateNotifier {
  @override
  SearchState build() => const SearchState();

  /// Обновить фильтры
  void updateFilters(SpecialistSearchFilters filters) {
    state = state.copyWith(filters: filters);
  }

  /// Сбросить фильтры
  void resetFilters() {
    state = state.copyWith(filters: const SpecialistSearchFilters());
  }

  /// Выполнить поиск
  Future<void> search() async {
    state = state.copyWith(isLoading: true, error: '');

    try {
      final service = ref.read(advancedSearchServiceProvider);
      final results = await service.searchSpecialists(
        filters: state.filters,
        limit: 20,
      );

      state = state.copyWith(
        results: results,
        isLoading: false,
        totalCount: results.length,
        hasMore: results.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Загрузить больше результатов
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      final service = ref.read(advancedSearchServiceProvider);
      final results = await service.searchSpecialists(
        filters: state.filters,
        limit: 20,
      );

      state = state.copyWith(
        results: [...state.results, ...results],
        isLoading: false,
        hasMore: results.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Очистить результаты
  void clearResults() {
    state = state.copyWith(results: [], totalCount: 0);
  }
}

/// Провайдер популярных категорий
@riverpod
Future<List<String>> popularCategories(PopularCategoriesRef ref) async {
  final service = ref.read(advancedSearchServiceProvider);
  return service.getPopularCategories();
}

/// Провайдер популярных услуг
@riverpod
Future<List<String>> popularServices(PopularServicesRef ref) async {
  final service = ref.read(advancedSearchServiceProvider);
  return service.getPopularServices();
}

/// Провайдер доступных локаций
@riverpod
Future<List<String>> availableLocations(AvailableLocationsRef ref) async {
  final service = ref.read(advancedSearchServiceProvider);
  return service.getAvailableLocations();
}
