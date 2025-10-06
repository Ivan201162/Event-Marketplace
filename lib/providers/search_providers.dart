import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/price_range.dart';
import '../models/specialist.dart';
import '../models/specialist_filters.dart' as filters;
import '../models/specialist_sorting.dart' as sorting_utils;
import '../services/specialist_service.dart';

/// Провайдер для поискового запроса
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Провайдер для фильтров поиска
final searchFiltersProvider = StateProvider<filters.SpecialistFilters>(
  (ref) => const filters.SpecialistFilters(),
);

/// Провайдер для сортировки
final searchSortingProvider = StateProvider<sorting_utils.SpecialistSorting>(
  (ref) => const sorting_utils.SpecialistSorting(),
);

/// Провайдер для сервиса специалистов
final specialistServiceProvider =
    Provider<SpecialistService>((ref) => SpecialistService());

/// Провайдер для всех специалистов из Firestore
final allSpecialistsProvider = StreamProvider<List<Specialist>>((ref) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getAllSpecialistsStream();
});

/// Провайдер для отфильтрованных и отсортированных специалистов
final filteredSpecialistsProvider =
    Provider<AsyncValue<List<Specialist>>>((ref) {
  final specialistsAsync = ref.watch(allSpecialistsProvider);
  final filters = ref.watch(searchFiltersProvider);
  final sorting = ref.watch(searchSortingProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return specialistsAsync.when(
    data: (specialists) {
      // Применяем фильтры
      var filteredSpecialists =
          _applyFilters(specialists, filters, searchQuery);

      // Применяем сортировку
      filteredSpecialists =
          sorting_utils.SpecialistSortingUtils.sortSpecialists(
        filteredSpecialists,
        sorting,
      );

      return AsyncValue.data(filteredSpecialists);
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

/// Провайдер для статистики поиска
final searchStatsProvider = Provider<SearchStats>((ref) {
  final specialistsAsync = ref.watch(filteredSpecialistsProvider);

  return specialistsAsync.when(
    data: _calculateSearchStats,
    loading: () => const SearchStats(
      totalCount: 0,
      averagePrice: 0,
      averageRating: 0,
      priceRange: null,
    ),
    error: (_, __) => const SearchStats(
      totalCount: 0,
      averagePrice: 0,
      averageRating: 0,
      priceRange: null,
    ),
  );
});

/// Провайдер для городов (для фильтра по городу)
final citiesProvider = FutureProvider<List<String>>((ref) async {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getCities();
});

/// Провайдер для категорий специалистов
final specialistCategoriesProvider =
    Provider<List<SpecialistCategory>>((ref) => SpecialistCategory.values);

/// Провайдер для опций сортировки
final sortOptionsProvider = Provider<List<sorting_utils.SpecialistSortOption>>(
  (ref) => sorting_utils.SpecialistSortOption.allOptions,
);

/// Провайдер для популярных опций сортировки
final popularSortOptionsProvider =
    Provider<List<sorting_utils.SpecialistSortOption>>(
  (ref) => sorting_utils.SpecialistSortOption.popularOptions,
);

/// Провайдер для расширенных опций сортировки
final extendedSortOptionsProvider =
    Provider<List<sorting_utils.SpecialistSortOption>>(
  (ref) => sorting_utils.SpecialistSortOption.extendedOptions,
);

/// Провайдер для опций рейтинга
final ratingFilterOptionsProvider = Provider<List<filters.RatingFilterOption>>(
  (ref) => filters.RatingFilterOption.options,
);

/// Провайдер для опций цены
final priceFilterOptionsProvider = Provider<List<filters.PriceFilterOption>>(
  (ref) => filters.PriceFilterOption.options,
);

/// Провайдер для проверки активности фильтров
final hasActiveFiltersProvider = Provider<bool>((ref) {
  final filters = ref.watch(searchFiltersProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return filters.hasActiveFilters || searchQuery.isNotEmpty;
});

/// Провайдер для количества активных фильтров
final activeFiltersCountProvider = Provider<int>((ref) {
  final filters = ref.watch(searchFiltersProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  var count = filters.activeFiltersCount;
  if (searchQuery.isNotEmpty) count++;

  return count;
});

/// Провайдер для состояния загрузки поиска
final isSearchLoadingProvider = Provider<bool>((ref) {
  final specialistsAsync = ref.watch(filteredSpecialistsProvider);
  return specialistsAsync.isLoading;
});

/// Провайдер для ошибки поиска
final searchErrorProvider = Provider<String?>((ref) {
  final specialistsAsync = ref.watch(filteredSpecialistsProvider);
  return specialistsAsync.hasError ? specialistsAsync.error.toString() : null;
});

/// Провайдер для пустого результата поиска
final isEmptySearchResultProvider = Provider<bool>((ref) {
  final specialistsAsync = ref.watch(filteredSpecialistsProvider);
  return specialistsAsync.hasValue && specialistsAsync.value!.isEmpty;
});

/// Провайдер для специалиста по ID
final specialistByIdProvider =
    FutureProvider.family<Specialist?, String>((ref, specialistId) async {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getSpecialistById(specialistId);
});

/// Провайдер для рекомендуемых специалистов
final recommendedSpecialistsProvider =
    Provider<AsyncValue<List<Specialist>>>((ref) {
  final specialistsAsync = ref.watch(allSpecialistsProvider);

  return specialistsAsync.when(
    data: (specialists) {
      // Рекомендуем специалистов с высоким рейтингом и большим количеством отзывов
      final recommended = specialists
          .where((s) => s.rating >= 4.0 && s.reviewCount >= 10)
          .toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));

      return AsyncValue.data(recommended.take(6).toList());
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

/// Провайдер для популярных специалистов
final popularSpecialistsProvider =
    Provider<AsyncValue<List<Specialist>>>((ref) {
  final specialistsAsync = ref.watch(allSpecialistsProvider);

  return specialistsAsync.when(
    data: (specialists) {
      // Популярные специалисты - по количеству отзывов
      final popular = List<Specialist>.from(specialists)
        ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));

      return AsyncValue.data(popular.take(6).toList());
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

/// Провайдер для новых специалистов
final newSpecialistsProvider = Provider<AsyncValue<List<Specialist>>>((ref) {
  final specialistsAsync = ref.watch(allSpecialistsProvider);

  return specialistsAsync.when(
    data: (specialists) {
      // Новые специалисты - по дате создания
      final newSpecialists = List<Specialist>.from(specialists)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return AsyncValue.data(newSpecialists.take(6).toList());
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

/// Провайдер для специалистов по категории
final specialistsByCategoryProvider =
    Provider.family<AsyncValue<List<Specialist>>, SpecialistCategory>(
        (ref, category) {
  final specialistsAsync = ref.watch(allSpecialistsProvider);

  return specialistsAsync.when(
    data: (specialists) {
      final categorySpecialists = specialists
          .where((s) => s.category == category)
          .toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));

      return AsyncValue.data(categorySpecialists);
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

/// Провайдер для специалистов в городе
final specialistsByCityProvider =
    Provider.family<AsyncValue<List<Specialist>>, String>((ref, city) {
  final specialistsAsync = ref.watch(allSpecialistsProvider);

  return specialistsAsync.when(
    data: (specialists) {
      final citySpecialists = specialists
          .where(
            (s) => s.city?.toLowerCase().contains(city.toLowerCase()) ?? false,
          )
          .toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));

      return AsyncValue.data(citySpecialists);
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

/// Провайдер для поиска по тексту
final textSearchProvider =
    Provider.family<AsyncValue<List<Specialist>>, String>((ref, query) {
  final specialistsAsync = ref.watch(allSpecialistsProvider);

  return specialistsAsync.when(
    data: (specialists) {
      if (query.isEmpty) {
        return const AsyncValue.data([]);
      }

      final searchResults = specialists.where((specialist) {
        final searchLower = query.toLowerCase();
        return specialist.name.toLowerCase().contains(searchLower) ||
            (specialist.description?.toLowerCase().contains(searchLower) ??
                false) ||
            specialist.category.displayName
                .toLowerCase()
                .contains(searchLower) ||
            specialist.services
                .any((service) => service.toLowerCase().contains(searchLower));
      }).toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));

      return AsyncValue.data(searchResults);
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

/// Функция для применения фильтров
List<Specialist> _applyFilters(
  List<Specialist> specialists,
  filters.SpecialistFilters filters,
  String searchQuery,
) {
  final filtered = specialists.where((specialist) {
    // Поисковый запрос
    if (searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase();
      final matchesSearch = specialist.name
              .toLowerCase()
              .contains(searchLower) ||
          (specialist.description?.toLowerCase().contains(searchLower) ??
              false) ||
          specialist.category.displayName.toLowerCase().contains(searchLower) ||
          specialist.services
              .any((service) => service.toLowerCase().contains(searchLower));
      if (!matchesSearch) return false;
    }

    // Фильтр по цене
    if (filters.minPrice != null && specialist.price < filters.minPrice!) {
      return false;
    }
    if (filters.maxPrice != null && specialist.price > filters.maxPrice!) {
      return false;
    }

    // Фильтр по рейтингу
    if (filters.minRating != null && specialist.rating < filters.minRating!) {
      return false;
    }
    if (filters.maxRating != null && specialist.rating > filters.maxRating!) {
      return false;
    }

    // Фильтр по городу
    if (filters.city != null && filters.city!.isNotEmpty) {
      if (specialist.city?.toLowerCase() != filters.city!.toLowerCase()) {
        return false;
      }
    }

    // Фильтр по подкатегориям
    if (filters.subcategories.isNotEmpty ?? false) {
      final hasMatchingSubcategory = filters.subcategories.any(
        (subcategory) => specialist.services.any(
          (service) =>
              service.toLowerCase().contains(subcategory.toLowerCase()),
        ),
      );
      if (!hasMatchingSubcategory) return false;
    }

    // Фильтр по верификации
    if (filters.isVerified != null &&
        specialist.isVerified != filters.isVerified!) {
      return false;
    }

    // Фильтр по доступности
    if (filters.isAvailable != null &&
        specialist.isAvailable != filters.isAvailable!) {
      return false;
    }

    // Фильтр по дате
    if (filters.availableDate != null) {
      // Проверяем, что специалист доступен в указанную дату
      if (!specialist.isAvailableOnDate(filters.availableDate!)) return false;
    }

    return true;
  }).toList();

  return filtered;
}

/// Функция для расчета статистики поиска
SearchStats _calculateSearchStats(List<Specialist> specialists) {
  if (specialists.isEmpty) {
    return const SearchStats(
      totalCount: 0,
      averagePrice: 0,
      averageRating: 0,
      priceRange: null,
    );
  }

  double totalPrice = 0;
  double totalRating = 0;
  var minPrice = double.infinity;
  double maxPrice = 0;

  for (final specialist in specialists) {
    totalPrice += specialist.price;
    totalRating += specialist.rating;

    if (specialist.price < minPrice) minPrice = specialist.price;
    if (specialist.price > maxPrice) maxPrice = specialist.price;
  }

  return SearchStats(
    totalCount: specialists.length,
    averagePrice: totalPrice / specialists.length,
    averageRating: totalRating / specialists.length,
    priceRange: minPrice != double.infinity
        ? PriceRange(minPrice: minPrice, maxPrice: maxPrice)
        : null,
  );
}

/// Класс для статистики поиска
class SearchStats {
  const SearchStats({
    required this.totalCount,
    required this.averagePrice,
    required this.averageRating,
    required this.priceRange,
  });
  final int totalCount;
  final double averagePrice;
  final double averageRating;
  final PriceRange? priceRange;
}

/// Класс для управления поиском
class SearchController {
  SearchController(this.ref);
  final Ref ref;

  /// Обновить поисковый запрос
  void updateSearchQuery(String query) {
    ref.read(searchQueryProvider.notifier).state = query;
  }

  /// Обновить фильтры
  void updateFilters(filters.SpecialistFilters filters) {
    ref.read(searchFiltersProvider.notifier).state = filters;
  }

  /// Обновить сортировку
  void updateSorting(sorting_utils.SpecialistSorting sorting) {
    ref.read(searchSortingProvider.notifier).state = sorting;
  }

  /// Сбросить все фильтры
  void clearFilters() {
    ref.read(searchFiltersProvider.notifier).state =
        const filters.SpecialistFilters();
    ref.read(searchQueryProvider.notifier).state = '';
  }

  /// Сбросить только поисковый запрос
  void clearSearchQuery() {
    ref.read(searchQueryProvider.notifier).state = '';
  }

  /// Сбросить только фильтры
  void clearSearchFilters() {
    ref.read(searchFiltersProvider.notifier).state =
        const filters.SpecialistFilters();
  }

  /// Сбросить только сортировку
  void clearSorting() {
    ref.read(searchSortingProvider.notifier).state =
        const sorting_utils.SpecialistSorting();
  }

  /// Получить текущие фильтры
  filters.SpecialistFilters get currentFilters =>
      ref.read(searchFiltersProvider);

  /// Получить текущую сортировку
  sorting_utils.SpecialistSorting get currentSorting =>
      ref.read(searchSortingProvider);

  /// Получить текущий поисковый запрос
  String get currentSearchQuery => ref.read(searchQueryProvider);
}

/// Провайдер для контроллера поиска
final searchControllerProvider =
    Provider<SearchController>(SearchController.new);
