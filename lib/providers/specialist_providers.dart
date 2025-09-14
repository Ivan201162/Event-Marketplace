import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/specialist_service.dart';
import '../models/specialist.dart';

/// Провайдер сервиса специалистов
final specialistServiceProvider = Provider<SpecialistService>((ref) {
  return SpecialistService();
});

/// Провайдер всех специалистов
final allSpecialistsProvider = StreamProvider<List<Specialist>>((ref) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getAllSpecialistsStream();
});

/// Провайдер специалиста по ID
final specialistProvider = StreamProvider.family<Specialist?, String>((ref, specialistId) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getSpecialistStream(specialistId);
});

/// Провайдер специалиста по ID пользователя
final specialistByUserIdProvider = StreamProvider.family<Specialist?, String>((ref, userId) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getSpecialistByUserIdStream(userId);
});

/// Провайдер топ специалистов
final topSpecialistsProvider = FutureProvider<List<Specialist>>((ref) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getTopSpecialists();
});

/// Провайдер специалистов по категории
final specialistsByCategoryProvider = FutureProvider.family<List<Specialist>, SpecialistCategory>((ref, category) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getSpecialistsByCategory(category);
});

/// Провайдер фильтров поиска
final specialistFiltersProvider = StateProvider<SpecialistFilters>((ref) {
  return const SpecialistFilters();
});

/// Провайдер результатов поиска с фильтрами
final searchResultsProvider = StreamProvider<List<Specialist>>((ref) {
  final specialistService = ref.watch(specialistServiceProvider);
  final filters = ref.watch(specialistFiltersProvider);
  
  return specialistService.searchSpecialistsStream(filters);
});

/// Провайдер доступности специалиста на дату
final specialistAvailabilityProvider = FutureProvider.family<bool, SpecialistAvailabilityParams>((ref, params) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.isSpecialistAvailableOnDate(params.specialistId, params.date);
});

/// Провайдер доступных временных слотов специалиста
final specialistTimeSlotsProvider = FutureProvider.family<List<DateTime>, SpecialistTimeSlotsParams>((ref, params) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getAvailableTimeSlots(
    params.specialistId, 
    params.date,
    slotDuration: params.slotDuration,
  );
});

/// Провайдер состояния поиска
final searchStateProvider = StateNotifierProvider<SearchStateNotifier, SearchState>((ref) {
  return SearchStateNotifier();
});

/// Провайдер избранных специалистов
final favoriteSpecialistsProvider = StateNotifierProvider<FavoriteSpecialistsNotifier, List<String>>((ref) {
  return FavoriteSpecialistsNotifier();
});

/// Провайдер истории поиска
final searchHistoryProvider = StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier();
});

/// Параметры для проверки доступности специалиста
class SpecialistAvailabilityParams {
  final String specialistId;
  final DateTime date;

  const SpecialistAvailabilityParams({
    required this.specialistId,
    required this.date,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpecialistAvailabilityParams &&
          runtimeType == other.runtimeType &&
          specialistId == other.specialistId &&
          date == other.date;

  @override
  int get hashCode => specialistId.hashCode ^ date.hashCode;
}

/// Параметры для получения временных слотов специалиста
class SpecialistTimeSlotsParams {
  final String specialistId;
  final DateTime date;
  final Duration slotDuration;

  const SpecialistTimeSlotsParams({
    required this.specialistId,
    required this.date,
    this.slotDuration = const Duration(hours: 1),
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpecialistTimeSlotsParams &&
          runtimeType == other.runtimeType &&
          specialistId == other.specialistId &&
          date == other.date &&
          slotDuration == other.slotDuration;

  @override
  int get hashCode => specialistId.hashCode ^ date.hashCode ^ slotDuration.hashCode;
}

/// Состояние поиска
class SearchState {
  final bool isSearching;
  final String? currentQuery;
  final SpecialistFilters currentFilters;
  final List<Specialist> results;
  final String? error;

  const SearchState({
    this.isSearching = false,
    this.currentQuery,
    this.currentFilters = const SpecialistFilters(),
    this.results = const [],
    this.error,
  });

  SearchState copyWith({
    bool? isSearching,
    String? currentQuery,
    SpecialistFilters? currentFilters,
    List<Specialist>? results,
    String? error,
  }) {
    return SearchState(
      isSearching: isSearching ?? this.isSearching,
      currentQuery: currentQuery ?? this.currentQuery,
      currentFilters: currentFilters ?? this.currentFilters,
      results: results ?? this.results,
      error: error ?? this.error,
    );
  }
}

/// Нотификатор состояния поиска
class SearchStateNotifier extends StateNotifier<SearchState> {
  SearchStateNotifier() : super(const SearchState());

  /// Начать поиск
  void startSearch(String query, SpecialistFilters filters) {
    state = state.copyWith(
      isSearching: true,
      currentQuery: query,
      currentFilters: filters,
      error: null,
    );
  }

  /// Завершить поиск
  void finishSearch(List<Specialist> results) {
    state = state.copyWith(
      isSearching: false,
      results: results,
      error: null,
    );
  }

  /// Ошибка поиска
  void setError(String error) {
    state = state.copyWith(
      isSearching: false,
      error: error,
    );
  }

  /// Очистить результаты
  void clearResults() {
    state = state.copyWith(
      results: [],
      currentQuery: null,
      error: null,
    );
  }

  /// Обновить фильтры
  void updateFilters(SpecialistFilters filters) {
    state = state.copyWith(currentFilters: filters);
  }

  /// Сбросить фильтры
  void resetFilters() {
    state = state.copyWith(currentFilters: const SpecialistFilters());
  }
}

/// Нотификатор избранных специалистов
class FavoriteSpecialistsNotifier extends StateNotifier<List<String>> {
  FavoriteSpecialistsNotifier() : super([]);

  /// Добавить в избранное
  void addToFavorites(String specialistId) {
    if (!state.contains(specialistId)) {
      state = [...state, specialistId];
    }
  }

  /// Удалить из избранного
  void removeFromFavorites(String specialistId) {
    state = state.where((id) => id != specialistId).toList();
  }

  /// Проверить, в избранном ли
  bool isFavorite(String specialistId) {
    return state.contains(specialistId);
  }

  /// Очистить избранное
  void clearFavorites() {
    state = [];
  }
}

/// Нотификатор истории поиска
class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier() : super([]);

  /// Добавить запрос в историю
  void addToHistory(String query) {
    if (query.trim().isEmpty) return;
    
    // Удаляем дубликаты
    state = state.where((item) => item.toLowerCase() != query.toLowerCase()).toList();
    
    // Добавляем в начало
    state = [query, ...state];
    
    // Ограничиваем количество записей
    if (state.length > 10) {
      state = state.take(10).toList();
    }
  }

  /// Очистить историю
  void clearHistory() {
    state = [];
  }

  /// Удалить запрос из истории
  void removeFromHistory(String query) {
    state = state.where((item) => item != query).toList();
  }
}

/// Провайдер для получения специалистов с учетом избранного
final specialistsWithFavoritesProvider = Provider<List<Specialist>>((ref) {
  final specialists = ref.watch(searchResultsProvider).when(
    data: (specialists) => specialists,
    loading: () => <Specialist>[],
    error: (_, __) => <Specialist>[],
  );
  
  final favorites = ref.watch(favoriteSpecialistsProvider);
  
  // Сортируем: сначала избранные, потом остальные
  final sortedSpecialists = List<Specialist>.from(specialists);
  sortedSpecialists.sort((a, b) {
    final aIsFavorite = favorites.contains(a.id);
    final bIsFavorite = favorites.contains(b.id);
    
    if (aIsFavorite && !bIsFavorite) return -1;
    if (!aIsFavorite && bIsFavorite) return 1;
    
    // Если оба в избранном или оба не в избранном, сортируем по рейтингу
    return b.rating.compareTo(a.rating);
  });
  
  return sortedSpecialists;
});

/// Провайдер для статистики поиска
final searchStatsProvider = Provider<SearchStats>((ref) {
  final specialists = ref.watch(searchResultsProvider).when(
    data: (specialists) => specialists,
    loading: () => <Specialist>[],
    error: (_, __) => <Specialist>[],
  );
  
  final filters = ref.watch(specialistFiltersProvider);
  
  return SearchStats(
    totalResults: specialists.length,
    verifiedCount: specialists.where((s) => s.isVerified).length,
    averageRating: specialists.isNotEmpty 
        ? specialists.map((s) => s.rating).reduce((a, b) => a + b) / specialists.length 
        : 0.0,
    priceRange: specialists.isNotEmpty 
        ? PriceRange(
            min: specialists.map((s) => s.hourlyRate).reduce((a, b) => a < b ? a : b),
            max: specialists.map((s) => s.hourlyRate).reduce((a, b) => a > b ? a : b),
          )
        : const PriceRange(min: 0, max: 0),
    categoryDistribution: _getCategoryDistribution(specialists),
    hasActiveFilters: filters.hasFilters,
  );
});

/// Статистика поиска
class SearchStats {
  final int totalResults;
  final int verifiedCount;
  final double averageRating;
  final PriceRange priceRange;
  final Map<SpecialistCategory, int> categoryDistribution;
  final bool hasActiveFilters;

  const SearchStats({
    required this.totalResults,
    required this.verifiedCount,
    required this.averageRating,
    required this.priceRange,
    required this.categoryDistribution,
    required this.hasActiveFilters,
  });
}

/// Диапазон цен
class PriceRange {
  final double min;
  final double max;

  const PriceRange({
    required this.min,
    required this.max,
  });

  String get displayText {
    if (min == max) {
      return '${min.toStringAsFixed(0)} ₽/час';
    }
    return '${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)} ₽/час';
  }
}

/// Получить распределение по категориям
Map<SpecialistCategory, int> _getCategoryDistribution(List<Specialist> specialists) {
  final distribution = <SpecialistCategory, int>{};
  
  for (final specialist in specialists) {
    distribution[specialist.category] = (distribution[specialist.category] ?? 0) + 1;
  }
  
  return distribution;
}
