import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist.dart';
import '../models/specialist_post.dart';
import '../models/specialist_story.dart';
import '../services/specialist_service.dart';
import '../services/specialist_social_service.dart';
import '../services/specialist_service_service.dart';

/// Провайдер сервиса специалистов
final specialistServiceProvider =
    Provider<SpecialistService>((ref) => SpecialistService());

/// Провайдер для ленты специалиста
final specialistFeedProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>(
        (ref, specialistId) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getSpecialistFeed(specialistId);
});

/// Провайдер всех специалистов
final allSpecialistsProvider = StreamProvider<List<Specialist>>((ref) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getAllSpecialistsStream();
});

/// Провайдер специалиста по ID
final specialistProvider =
    StreamProvider.family<Specialist?, String>((ref, specialistId) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getSpecialistStream(specialistId);
});

/// Провайдер специалиста по ID пользователя
final specialistByUserIdProvider =
    StreamProvider.family<Specialist?, String>((ref, userId) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getSpecialistByUserIdStream(userId);
});

/// Провайдер топ специалистов
final topSpecialistsProvider = FutureProvider<List<Specialist>>((ref) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getTopSpecialists();
});

/// Провайдер специалистов по категории
final specialistsByCategoryProvider =
    FutureProvider.family<List<Specialist>, SpecialistCategory>(
        (ref, category) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getSpecialistsByCategory(category);
});

/// Провайдер фильтров поиска
final specialistFiltersProvider =
    NotifierProvider<SpecialistFiltersNotifier, SpecialistFilters>(
  SpecialistFiltersNotifier.new,
);

class SpecialistFiltersNotifier extends Notifier<SpecialistFilters> {
  @override
  SpecialistFilters build() => const SpecialistFilters();

  void updateFilters(SpecialistFilters filters) {
    state = filters;
  }
}

/// Провайдер результатов поиска с фильтрами
final searchResultsProvider = StreamProvider<List<Specialist>>((ref) {
  final specialistService = ref.watch(specialistServiceProvider);
  final filters = ref.watch(specialistFiltersProvider);

  return specialistService.searchSpecialistsStream(filters);
});

/// Провайдер доступности специалиста на дату
final specialistAvailabilityProvider =
    FutureProvider.family<bool, SpecialistAvailabilityParams>((ref, params) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.isSpecialistAvailableOnDate(
    params.specialistId,
    params.date,
  );
});

/// Провайдер доступных временных слотов специалиста
final specialistTimeSlotsProvider =
    FutureProvider.family<List<DateTime>, SpecialistTimeSlotsParams>(
        (ref, params) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getAvailableTimeSlots(
    params.specialistId,
    params.date,
    slotDuration: params.slotDuration,
  );
});

/// Провайдер состояния поиска
final searchStateProvider =
    NotifierProvider<SearchStateNotifier, SearchState>(SearchStateNotifier.new);

/// Провайдер избранных специалистов
final favoriteSpecialistsProvider =
    NotifierProvider<FavoriteSpecialistsNotifier, List<String>>(
  FavoriteSpecialistsNotifier.new,
);

/// Провайдер истории поиска
final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(
  SearchHistoryNotifier.new,
);

/// Параметры для проверки доступности специалиста
class SpecialistAvailabilityParams {
  const SpecialistAvailabilityParams({
    required this.specialistId,
    required this.date,
  });
  final String specialistId;
  final DateTime date;

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
  const SpecialistTimeSlotsParams({
    required this.specialistId,
    required this.date,
    this.slotDuration = const Duration(hours: 1),
  });
  final String specialistId;
  final DateTime date;
  final Duration slotDuration;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpecialistTimeSlotsParams &&
          runtimeType == other.runtimeType &&
          specialistId == other.specialistId &&
          date == other.date &&
          slotDuration == other.slotDuration;

  @override
  int get hashCode =>
      specialistId.hashCode ^ date.hashCode ^ slotDuration.hashCode;
}

/// Состояние поиска
class SearchState {
  const SearchState({
    this.isSearching = false,
    this.currentQuery,
    this.currentFilters = const SpecialistFilters(),
    this.results = const [],
    this.error,
  });
  final bool isSearching;
  final String? currentQuery;
  final SpecialistFilters currentFilters;
  final List<Specialist> results;
  final String? error;

  SearchState copyWith({
    bool? isSearching,
    String? currentQuery,
    SpecialistFilters? currentFilters,
    List<Specialist>? results,
    String? error,
  }) =>
      SearchState(
        isSearching: isSearching ?? this.isSearching,
        currentQuery: currentQuery ?? this.currentQuery,
        currentFilters: currentFilters ?? this.currentFilters,
        results: results ?? this.results,
        error: error ?? this.error,
      );
}

/// Нотификатор состояния поиска
class SearchStateNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  /// Начать поиск
  void startSearch(String query, SpecialistFilters filters) {
    state = state.copyWith(
      isSearching: true,
      currentQuery: query,
      currentFilters: filters,
    );
  }

  /// Завершить поиск
  void finishSearch(List<Specialist> results) {
    state = state.copyWith(
      isSearching: false,
      results: results,
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
class FavoriteSpecialistsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

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
  bool isFavorite(String specialistId) => state.contains(specialistId);

  /// Очистить избранное
  void clearFavorites() {
    state = [];
  }
}

/// Нотификатор истории поиска
class SearchHistoryNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  /// Добавить запрос в историю
  void addToHistory(String query) {
    if (query.trim().isEmpty) return;

    // Удаляем дубликаты
    state = state
        .where((item) => item.toLowerCase() != query.toLowerCase())
        .toList();

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
        ? specialists.map((s) => s.rating).reduce((a, b) => a + b) /
            specialists.length
        : 0.0,
    priceRange: specialists.isNotEmpty
        ? PriceRange(
            min: specialists
                .map((s) => s.hourlyRate)
                .reduce((a, b) => a < b ? a : b),
            max: specialists
                .map((s) => s.hourlyRate)
                .reduce((a, b) => a > b ? a : b),
          )
        : const PriceRange(min: 0, max: 0),
    categoryDistribution: _getCategoryDistribution(specialists),
    hasActiveFilters: filters.hasFilters,
  );
});

/// Статистика поиска
class SearchStats {
  const SearchStats({
    required this.totalResults,
    required this.verifiedCount,
    required this.averageRating,
    required this.priceRange,
    required this.categoryDistribution,
    required this.hasActiveFilters,
  });
  final int totalResults;
  final int verifiedCount;
  final double averageRating;
  final PriceRange priceRange;
  final Map<SpecialistCategory, int> categoryDistribution;
  final bool hasActiveFilters;
}

/// Диапазон цен
class PriceRange {
  const PriceRange({
    required this.min,
    required this.max,
  });
  final double min;
  final double max;

  String get displayText {
    if (min == max) {
      return '${min.toStringAsFixed(0)} ₽/час';
    }
    return '${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)} ₽/час';
  }
}

/// Получить распределение по категориям
Map<SpecialistCategory, int> _getCategoryDistribution(
  List<Specialist> specialists,
) {
  final distribution = <SpecialistCategory, int>{};

  for (final specialist in specialists) {
    distribution[specialist.category] =
        (distribution[specialist.category] ?? 0) + 1;
  }

  return distribution;
}

/// Провайдер сервиса социальных функций специалистов
final specialistContentServiceProvider =
    Provider<SpecialistSocialService>((ref) => SpecialistSocialService());

/// Провайдер сервиса услуг специалистов
final specialistServiceServiceProvider =
    Provider<SpecialistServiceService>((ref) => SpecialistServiceService());

/// Провайдер постов специалиста
final specialistPostsProvider =
    StreamProvider.family<List<SpecialistPost>, String>((ref, specialistId) {
  final socialService = ref.watch(specialistContentServiceProvider);
  return socialService.getSpecialistPosts(specialistId);
});

/// Провайдер сторис специалиста
final specialistStoriesProvider =
    StreamProvider.family<List<SpecialistStory>, String>((ref, specialistId) {
  final socialService = ref.watch(specialistContentServiceProvider);
  return socialService.getSpecialistStories(specialistId);
});

/// Провайдер услуг специалиста
final specialistServicesProvider =
    StreamProvider.family<List<SpecialistService>, String>((ref, specialistId) {
  final serviceService = ref.watch(specialistServiceServiceProvider);
  return serviceService.getSpecialistServices(specialistId);
});

/// Провайдер статистики специалиста
final specialistStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, specialistId) {
  final socialService = ref.watch(specialistContentServiceProvider);
  return socialService.getSpecialistStats(specialistId);
});
