import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/advanced_search_filters.dart';
import '../services/advanced_specialist_search_service.dart';

/// Провайдер сервиса расширенного поиска
final advancedSearchServiceProvider = Provider<AdvancedSpecialistSearchService>((ref) {
  return AdvancedSpecialistSearchService();
});

/// Провайдер состояния расширенного поиска
final advancedSearchProvider = StateNotifierProvider<AdvancedSearchNotifier, AsyncValue<AdvancedSearchState>>((ref) {
  final service = ref.read(advancedSearchServiceProvider);
  return AdvancedSearchNotifier(service);
});

/// Провайдер для фильтров поиска
final searchFiltersProvider = StateProvider<AdvancedSearchFilters>((ref) => const AdvancedSearchFilters());

/// Провайдер для статистики поиска
final searchStatsProvider = FutureProvider.family<Map<String, dynamic>, AdvancedSearchFilters>((ref, filters) async {
  final service = ref.read(advancedSearchServiceProvider);
  return await service.getSearchStats(filters: filters);
});

/// Провайдер для популярных категорий в регионе
final popularCategoriesProvider = FutureProvider.family<List<SpecialistCategory>, Map<String, dynamic>>((ref, params) async {
  final service = ref.read(advancedSearchServiceProvider);
  return await service.getPopularCategoriesInRegion(
    regionName: params['regionName'] as String?,
    city: params['city'] as CityRegion?,
    limit: params['limit'] as int? ?? 10,
  );
});

/// Нотификатор для расширенного поиска
class AdvancedSearchNotifier extends StateNotifier<AsyncValue<AdvancedSearchState>> {
  AdvancedSearchNotifier(this._service) : super(const AsyncValue.loading()) {
    _initialize();
  }

  final AdvancedSpecialistSearchService _service;
  AdvancedSearchFilters _currentFilters = const AdvancedSearchFilters();
  List<AdvancedSearchResult> _allResults = [];
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;

  /// Инициализация
  void _initialize() {
    state = const AsyncValue.data(AdvancedSearchState());
  }

  /// Поиск специалистов с новыми фильтрами
  Future<void> searchSpecialists(AdvancedSearchFilters filters) async {
    _currentFilters = filters;
    _allResults = [];
    _currentPage = 0;
    _hasMore = true;

    state = const AsyncValue.loading();

    try {
      final results = await _service.searchSpecialists(
        filters: filters,
        limit: _pageSize,
      );

      _allResults = results;
      _hasMore = results.length >= _pageSize;

      final searchState = AdvancedSearchState(
        results: _allResults,
        isLoading: false,
        hasMore: _hasMore,
        filters: filters,
        totalCount: _allResults.length,
        searchTime: 0, // TODO: Измерить время поиска
      );

      state = AsyncValue.data(searchState);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Загрузить больше результатов
  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;

    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final moreResults = await _service.searchSpecialists(
        filters: _currentFilters,
        limit: _pageSize,
      );

      _allResults.addAll(moreResults);
      _currentPage++;
      _hasMore = moreResults.length >= _pageSize;

      final updatedState = currentState.copyWith(
        results: _allResults,
        isLoading: false,
        hasMore: _hasMore,
        totalCount: _allResults.length,
      );

      state = AsyncValue.data(updatedState);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Обновить фильтры
  Future<void> updateFilters(AdvancedSearchFilters filters) async {
    await searchSpecialists(filters);
  }

  /// Обновить поисковый запрос
  Future<void> updateSearchQuery(String query) async {
    final newFilters = _currentFilters.copyWith(searchQuery: query);
    await searchSpecialists(newFilters);
  }

  /// Обновить выбранный город
  Future<void> updateSelectedCity(CityRegion? city) async {
    final newFilters = _currentFilters.copyWith(selectedCity: city);
    await searchSpecialists(newFilters);
  }

  /// Обновить категории
  Future<void> updateCategories(List<SpecialistCategory> categories) async {
    final newFilters = _currentFilters.copyWith(categories: categories);
    await searchSpecialists(newFilters);
  }

  /// Обновить ценовой диапазон
  Future<void> updatePriceRange(int minPrice, int maxPrice) async {
    final newFilters = _currentFilters.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
    await searchSpecialists(newFilters);
  }

  /// Обновить рейтинг
  Future<void> updateRating(double minRating, double maxRating) async {
    final newFilters = _currentFilters.copyWith(
      minRating: minRating,
      maxRating: maxRating,
    );
    await searchSpecialists(newFilters);
  }

  /// Обновить сортировку
  Future<void> updateSorting(AdvancedSearchSortBy sortBy, bool ascending) async {
    final newFilters = _currentFilters.copyWith(
      sortBy: sortBy,
      sortAscending: ascending,
    );
    await searchSpecialists(newFilters);
  }

  /// Сбросить фильтры
  Future<void> clearFilters() async {
    await searchSpecialists(const AdvancedSearchFilters());
  }

  /// Обновить радиус поиска
  Future<void> updateRadius(double radiusKm) async {
    final newFilters = _currentFilters.copyWith(radiusKm: radiusKm);
    await searchSpecialists(newFilters);
  }

  /// Обновить фильтр доступности
  Future<void> updateAvailability(bool isAvailableNow) async {
    final newFilters = _currentFilters.copyWith(isAvailableNow: isAvailableNow);
    await searchSpecialists(newFilters);
  }

  /// Обновить фильтр верификации
  Future<void> updateVerification(bool isVerified) async {
    final newFilters = _currentFilters.copyWith(isVerified: isVerified);
    await searchSpecialists(newFilters);
  }

  /// Обновить фильтр портфолио
  Future<void> updatePortfolio(bool hasPortfolio) async {
    final newFilters = _currentFilters.copyWith(hasPortfolio: hasPortfolio);
    await searchSpecialists(newFilters);
  }

  /// Обновить фильтр отзывов
  Future<void> updateReviews(bool hasReviews) async {
    final newFilters = _currentFilters.copyWith(hasReviews: hasReviews);
    await searchSpecialists(newFilters);
  }

  /// Обновить фильтр опыта
  Future<void> updateExperience(int minExperience, int maxExperience) async {
    final newFilters = _currentFilters.copyWith(
      minExperience: minExperience,
      maxExperience: maxExperience,
    );
    await searchSpecialists(newFilters);
  }

  /// Обновить фильтр языков
  Future<void> updateLanguages(List<String> languages) async {
    final newFilters = _currentFilters.copyWith(languages: languages);
    await searchSpecialists(newFilters);
  }

  /// Обновить фильтр оборудования
  Future<void> updateEquipment(List<String> equipment) async {
    final newFilters = _currentFilters.copyWith(equipment: equipment);
    await searchSpecialists(newFilters);
  }

  /// Обновить фильтр услуг
  Future<void> updateServices(List<String> services) async {
    final newFilters = _currentFilters.copyWith(services: services);
    await searchSpecialists(newFilters);
  }

  /// Обновить фильтр дат доступности
  Future<void> updateAvailabilityDates(DateTime? from, DateTime? to) async {
    final newFilters = _currentFilters.copyWith(
      availableFrom: from,
      availableTo: to,
    );
    await searchSpecialists(newFilters);
  }

  /// Получить текущие фильтры
  AdvancedSearchFilters get currentFilters => _currentFilters;

  /// Получить текущие результаты
  List<AdvancedSearchResult> get currentResults => _allResults;

  /// Проверить, есть ли еще результаты для загрузки
  bool get hasMoreResults => _hasMore;

  /// Проверить, выполняется ли поиск
  bool get isSearching => state.isLoading;
}

/// Провайдер для потока поиска
final searchStreamProvider = StreamProvider.family<List<AdvancedSearchResult>, AdvancedSearchFilters>((ref, filters) {
  final service = ref.read(advancedSearchServiceProvider);
  return service.searchSpecialistsStream(filters: filters);
});

/// Провайдер для быстрого поиска (без фильтров)
final quickSearchProvider = StateNotifierProvider<QuickSearchNotifier, AsyncValue<List<AdvancedSearchResult>>>((ref) {
  final service = ref.read(advancedSearchServiceProvider);
  return QuickSearchNotifier(service);
});

/// Нотификатор для быстрого поиска
class QuickSearchNotifier extends StateNotifier<AsyncValue<List<AdvancedSearchResult>>> {
  QuickSearchNotifier(this._service) : super(const AsyncValue.data([]));

  final AdvancedSpecialistSearchService _service;

  /// Быстрый поиск по запросу
  Future<void> quickSearch(String query, {CityRegion? city}) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final filters = AdvancedSearchFilters(
        searchQuery: query,
        selectedCity: city,
        sortBy: AdvancedSearchSortBy.relevance,
      );

      final results = await _service.searchSpecialists(
        filters: filters,
        limit: 10,
      );

      state = AsyncValue.data(results);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Очистить результаты
  void clearResults() {
    state = const AsyncValue.data([]);
  }
}

/// Провайдер для рекомендуемых специалистов
final recommendedSpecialistsProvider = FutureProvider.family<List<AdvancedSearchResult>, Map<String, dynamic>>((ref, params) async {
  final service = ref.read(advancedSearchServiceProvider);
  
  final filters = AdvancedSearchFilters(
    selectedCity: params['city'] as CityRegion?,
    selectedRegion: params['region'] as String?,
    sortBy: AdvancedSearchSortBy.popularity,
    minRating: 4.0,
    hasReviews: true,
  );

  return await service.searchSpecialists(
    filters: filters,
    limit: params['limit'] as int? ?? 10,
  );
});

/// Провайдер для похожих специалистов
final similarSpecialistsProvider = FutureProvider.family<List<AdvancedSearchResult>, Map<String, dynamic>>((ref, params) async {
  final service = ref.read(advancedSearchServiceProvider);
  
  final specialist = params['specialist'] as Specialist;
  final city = params['city'] as CityRegion?;
  
  final filters = AdvancedSearchFilters(
    categories: specialist.categories,
    selectedCity: city,
    sortBy: AdvancedSearchSortBy.relevance,
    minRating: specialist.rating - 0.5,
    maxRating: specialist.rating + 0.5,
  );

  final results = await service.searchSpecialists(
    filters: filters,
    limit: params['limit'] as int? ?? 5,
  );

  // Исключаем самого специалиста из результатов
  return results.where((result) => result.specialist.id != specialist.id).toList();
});

/// Провайдер для статистики по категориям
final categoryStatsProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final service = ref.read(advancedSearchServiceProvider);
  
  final category = params['category'] as SpecialistCategory;
  final city = params['city'] as CityRegion?;
  final region = params['region'] as String?;
  
  final filters = AdvancedSearchFilters(
    categories: [category],
    selectedCity: city,
    selectedRegion: region,
  );

  return await service.getSearchStats(filters: filters);
});

/// Провайдер для трендов поиска
final searchTrendsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // TODO: Реализовать получение трендов поиска
  // Это может включать популярные запросы, категории, города и т.д.
  return {
    'popularQueries': ['фотограф', 'dj', 'ведущий', 'декоратор'],
    'popularCategories': ['photographer', 'dj', 'host', 'decorator'],
    'popularCities': ['Москва', 'Санкт-Петербург', 'Новосибирск'],
    'trendingServices': ['свадебная фотосъемка', 'корпоративные мероприятия'],
  };
});