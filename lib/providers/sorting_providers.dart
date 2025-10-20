import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist.dart';
import '../models/specialist_filters_simple.dart';
import '../models/specialist_sorting.dart';
import '../services/mock_data_service.dart';

/// Провайдер для состояния сортировки специалистов (мигрирован с StateNotifierProvider)
final specialistSortingProvider = NotifierProvider<SpecialistSortingNotifier, SpecialistSorting>(
  () => SpecialistSortingNotifier(),
);

/// Провайдер для отсортированных специалистов
final sortedSpecialistsProvider = FutureProvider.family<List<Specialist>, SortParams>(
  (ref, params) async => MockDataService.getSortedSpecialists(
    categoryId: params.categoryId,
    filters: params.filters,
    sorting: params.sorting,
  ),
);

/// Параметры для сортировки
class SortParams {
  const SortParams({
    this.categoryId,
    this.filters,
    required this.sorting,
  });
  final String? categoryId;
  final SpecialistFilters? filters;
  final SpecialistSorting sorting;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SortParams &&
        other.categoryId == categoryId &&
        other.filters == filters &&
        other.sorting == sorting;
  }

  @override
  int get hashCode => Object.hash(categoryId, filters, sorting);
}

/// Notifier для управления сортировкой специалистов (мигрирован с StateNotifier)
class SpecialistSortingNotifier extends Notifier<SpecialistSorting> {
  @override
  SpecialistSorting build() {
    return const SpecialistSorting();
  }

  /// Установить сортировку
  void setSorting(SpecialistSortOption sortOption) {
    state = state.copyWith(sortOption: sortOption);
  }

  /// Сбросить сортировку
  void clearSorting() {
    state = const SpecialistSorting();
  }

  /// Переключить направление сортировки
  void toggleSortDirection() {
    state = state.copyWith(isAscending: !state.isAscending);
  }

  /// Установить сортировку по цене (возрастание)
  void sortByPriceAsc() {
    state = state.copyWith(sortOption: SpecialistSortOption.priceAsc);
  }

  /// Установить сортировку по цене (убывание)
  void sortByPriceDesc() {
    state = state.copyWith(sortOption: SpecialistSortOption.priceDesc);
  }

  /// Установить сортировку по рейтингу
  void sortByRating() {
    state = state.copyWith(sortOption: SpecialistSortOption.rating);
  }

  /// Установить сортировку по популярности
  void sortByPopularity() {
    state = state.copyWith(sortOption: SpecialistSortOption.popularity);
  }

  /// Установить сортировку по имени (А-Я)
  void sortByNameAsc() {
    state = state.copyWith(sortOption: SpecialistSortOption.nameAsc);
  }

  /// Установить сортировку по имени (Я-А)
  void sortByNameDesc() {
    state = state.copyWith(sortOption: SpecialistSortOption.nameDesc);
  }

  /// Установить сортировку по дате (новые сначала)
  void sortByDateNewest() {
    state = state.copyWith(sortOption: SpecialistSortOption.dateNewest);
  }

  /// Установить сортировку по дате (старые сначала)
  void sortByDateOldest() {
    state = state.copyWith(sortOption: SpecialistSortOption.dateOldest);
  }
}

/// Провайдер для статистики сортировки
final sortStatsProvider = Provider.family<SortStats, SortParams>((ref, params) {
  final specialists = ref.watch(sortedSpecialistsProvider(params));

  return specialists.when(
    data: (specialists) => SpecialistSortingUtils.getSortStats(specialists, params.sorting),
    loading: () => const SortStats(
      totalCount: 0,
      priceRange: null,
      averageRating: 0,
      averageReviews: 0,
    ),
    error: (_, __) => const SortStats(
      totalCount: 0,
      priceRange: null,
      averageRating: 0,
      averageReviews: 0,
    ),
  );
});

/// Провайдер для получения доступных опций сортировки
final availableSortOptionsProvider = Provider<List<SpecialistSortOption>>(
  (ref) => SpecialistSortOption.popularOptions,
);

/// Провайдер для получения всех опций сортировки
final allSortOptionsProvider = Provider<List<SpecialistSortOption>>(
  (ref) => SpecialistSortOption.allOptions,
);

/// Провайдер для получения расширенных опций сортировки
final extendedSortOptionsProvider = Provider<List<SpecialistSortOption>>(
  (ref) => SpecialistSortOption.extendedOptions,
);

/// Провайдер для комбинированных параметров (фильтры + сортировка)
final combinedParamsProvider = Provider.family<SortParams, CombinedParams>((ref, params) {
  final filters = ref.watch(params.filtersProvider);
  final sorting = ref.watch(params.sortingProvider);

  return SortParams(
    categoryId: params.categoryId,
    filters: filters,
    sorting: sorting,
  );
});

/// Параметры для комбинированного провайдера
class CombinedParams {
  const CombinedParams({
    this.categoryId,
    required this.filtersProvider,
    required this.sortingProvider,
  });
  final String? categoryId;
  final StateNotifierProvider filtersProvider;
  final StateNotifierProvider sortingProvider;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CombinedParams &&
        other.categoryId == categoryId &&
        other.filtersProvider == filtersProvider &&
        other.sortingProvider == sortingProvider;
  }

  @override
  int get hashCode => Object.hash(categoryId, filtersProvider, sortingProvider);
}

/// Провайдер для отсортированных и отфильтрованных специалистов
final filteredAndSortedSpecialistsProvider =
    FutureProvider.family<List<Specialist>, CombinedParams>((ref, params) {
  final combinedParams = ref.watch(combinedParamsProvider(params));
  return ref.watch(sortedSpecialistsProvider(combinedParams));
});

/// Провайдер для получения информации о текущей сортировке
final currentSortingInfoProvider = Provider<SortingInfo>((ref) {
  final sorting = ref.watch(specialistSortingProvider);

  return SortingInfo(
    isActive: sorting.isActive,
    displayName: sorting.displayName,
    description: sorting.description,
    sortOption: sorting.sortOption,
  );
});

/// Информация о текущей сортировке
class SortingInfo {
  const SortingInfo({
    required this.isActive,
    required this.displayName,
    required this.description,
    required this.sortOption,
  });
  final bool isActive;
  final String displayName;
  final String description;
  final SpecialistSortOption sortOption;
}
