import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/price_range.dart';
import '../models/specialist.dart';
import '../models/specialist_filters.dart' as filters;
import '../models/specialist_sorting.dart' as sorting_utils;
import '../services/specialist_service.dart';

/// Notifier для поискового запроса (мигрирован с StateProvider)
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }

  void clearQuery() {
    state = '';
  }
}

/// Notifier для фильтров поиска (мигрирован с StateProvider)
class SearchFiltersNotifier extends Notifier<filters.SpecialistFilters> {
  @override
  filters.SpecialistFilters build() => const filters.SpecialistFilters();

  void updateFilters(filters.SpecialistFilters newFilters) {
    state = newFilters;
  }

  void clearFilters() {
    state = const filters.SpecialistFilters();
  }

  void updatePriceRange(double? minPrice, double? maxPrice) {
    state = state.copyWith(minPrice: minPrice, maxPrice: maxPrice);
  }

  void updateLocation(String? location) {
    state = state.copyWith(location: location);
  }

  void updateCategory(String? category) {
    state = state.copyWith(category: category);
  }

  void updateRating(double? minRating) {
    state = state.copyWith(minRating: minRating);
  }

  void updateAvailability(bool? isAvailable) {
    state = state.copyWith(isAvailable: isAvailable);
  }
}

/// Notifier для сортировки (мигрирован с StateProvider)
class SearchSortingNotifier extends Notifier<sorting_utils.SpecialistSorting> {
  @override
  sorting_utils.SpecialistSorting build() =>
      const sorting_utils.SpecialistSorting();

  void updateSorting(sorting_utils.SpecialistSorting newSorting) {
    state = newSorting;
  }

  void setSortBy(sorting_utils.SortBy sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void setSortOrder(sorting_utils.SortOrder sortOrder) {
    state = state.copyWith(sortOrder: sortOrder);
  }
}

/// Провайдер для поискового запроса (мигрирован)
final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// Провайдер для фильтров поиска (мигрирован)
final searchFiltersProvider =
    NotifierProvider<SearchFiltersNotifier, filters.SpecialistFilters>(
  SearchFiltersNotifier.new,
);

/// Провайдер для сортировки (мигрирован)
final searchSortingProvider =
    NotifierProvider<SearchSortingNotifier, sorting_utils.SpecialistSorting>(
  SearchSortingNotifier.new,
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

/// Применение фильтров к списку специалистов
List<Specialist> _applyFilters(
  List<Specialist> specialists,
  filters.SpecialistFilters filters,
  String searchQuery,
) {
  final filtered = specialists.where((specialist) {
    // Поисковый запрос
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      final matchesName = specialist.name.toLowerCase().contains(query);
      final matchesCategory = specialist.category.toLowerCase().contains(query);
      final matchesDescription =
          specialist.description.toLowerCase().contains(query);

      if (!matchesName && !matchesCategory && !matchesDescription) {
        return false;
      }
    }

    // Фильтр по цене
    if (filters.minPrice != null &&
        specialist.pricePerHour < filters.minPrice!) {
      return false;
    }
    if (filters.maxPrice != null &&
        specialist.pricePerHour > filters.maxPrice!) {
      return false;
    }

    // Фильтр по местоположению
    if (filters.location != null && filters.location!.isNotEmpty) {
      if (!specialist.location
          .toLowerCase()
          .contains(filters.location!.toLowerCase())) {
        return false;
      }
    }

    // Фильтр по категории
    if (filters.category != null && filters.category!.isNotEmpty) {
      if (specialist.category != filters.category) {
        return false;
      }
    }

    // Фильтр по рейтингу
    if (filters.minRating != null && specialist.rating < filters.minRating!) {
      return false;
    }

    // Фильтр по доступности
    if (filters.isAvailable != null &&
        specialist.isAvailable != filters.isAvailable) {
      return false;
    }

    return true;
  }).toList();

  return filtered;
}

/// Провайдер для статистики поиска
final searchStatsProvider = Provider<Map<String, int>>((ref) {
  final specialistsAsync = ref.watch(allSpecialistsProvider);
  final filters = ref.watch(searchFiltersProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return specialistsAsync.when(
    data: (specialists) {
      final filtered = _applyFilters(specialists, filters, searchQuery);

      return {
        'total': specialists.length,
        'filtered': filtered.length,
        'available': specialists.where((s) => s.isAvailable).length,
        'categories': specialists.map((s) => s.category).toSet().length,
      };
    },
    loading: () => const {
      'total': 0,
      'filtered': 0,
      'available': 0,
      'categories': 0,
    },
    error: (_, __) => const {
      'total': 0,
      'filtered': 0,
      'available': 0,
      'categories': 0,
    },
  );
});

/// Провайдер для популярных категорий
final popularCategoriesProvider = Provider<List<String>>((ref) {
  final specialistsAsync = ref.watch(allSpecialistsProvider);

  return specialistsAsync.when(
    data: (specialists) {
      final categoryCount = <String, int>{};

      for (final specialist in specialists) {
        categoryCount[specialist.category] =
            (categoryCount[specialist.category] ?? 0) + 1;
      }

      final sortedCategories = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedCategories.take(10).map((e) => e.key).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Провайдер для диапазона цен
final priceRangeProvider = Provider<PriceRange>((ref) {
  final specialistsAsync = ref.watch(allSpecialistsProvider);

  return specialistsAsync.when(
    data: (specialists) {
      if (specialists.isEmpty) {
        return const PriceRange(min: 0, max: 1000);
      }

      final prices = specialists.map((s) => s.pricePerHour).toList();
      prices.sort();

      return PriceRange(
        min: prices.first,
        max: prices.last,
      );
    },
    loading: () => const PriceRange(min: 0, max: 1000),
    error: (_, __) => const PriceRange(min: 0, max: 1000),
  );
});

/// Провайдер для сохранения поисковых настроек
final searchSettingsProvider = Provider<Map<String, dynamic>>((ref) {
  final filters = ref.watch(searchFiltersProvider);
  final sorting = ref.watch(searchSortingProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return {
    'filters': {
      'minPrice': filters.minPrice,
      'maxPrice': filters.maxPrice,
      'location': filters.location,
      'category': filters.category,
      'minRating': filters.minRating,
      'isAvailable': filters.isAvailable,
    },
    'sorting': {
      'sortBy': sorting.sortBy.toString(),
      'sortOrder': sorting.sortOrder.toString(),
    },
    'searchQuery': searchQuery,
  };
});


