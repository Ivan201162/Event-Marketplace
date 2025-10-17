import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist.dart';
import '../models/specialist_filters.dart';
import '../services/specialist_service.dart';

/// Провайдер сервиса специалистов
final specialistServiceProvider = Provider<SpecialistService>((ref) => SpecialistService());

/// Провайдер для ленты специалиста
final specialistFeedProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, specialistId) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getSpecialistFeed(specialistId);
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

/// Провайдер лидеров недели
final weeklyLeadersProvider = FutureProvider<List<Specialist>>((ref) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getWeeklyLeaders();
});

/// Провайдер специалистов по категории
final specialistsByCategoryProvider =
    FutureProvider.family<List<Specialist>, SpecialistCategory>((ref, category) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getSpecialistsByCategory(category);
});

/// Провайдер фильтров специалистов
final specialistFiltersProvider = Provider<SpecialistFiltersNotifier>((ref) {
  return SpecialistFiltersNotifier();
});

/// Провайдер поиска специалистов
final specialistSearchProvider =
    StreamProvider.family<List<Specialist>, Map<String, dynamic>>((ref, filters) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.searchSpecialistsStream(filters);
});

/// Провайдер доступности специалиста
final specialistAvailabilityProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, params) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.isSpecialistAvailableOnDate(
    params['specialistId'] as String,
    params['date'] as DateTime,
  );
});

/// Провайдер временных слотов
final timeSlotsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) {
  final specialistService = ref.watch(specialistServiceProvider);
  return specialistService.getAvailableTimeSlots(
    params['specialistId'] as String,
    params['date'] as DateTime,
  );
});

/// Notifier для фильтров специалистов
class SpecialistFiltersNotifier extends ChangeNotifier {
  SpecialistFilters _filters = const SpecialistFilters();

  SpecialistFilters get filters => _filters;

  void updateFilters(SpecialistFilters filters) {
    _filters = filters;
    notifyListeners();
  }

  void clearFilters() {
    _filters = const SpecialistFilters();
    notifyListeners();
  }

  void setCategory(SpecialistCategory? category) {
    _filters = _filters.copyWith(category: category);
    notifyListeners();
  }

  void setCity(String? city) {
    _filters = _filters.copyWith(city: city);
    notifyListeners();
  }

  void setPriceRange(double? minPrice, double? maxPrice) {
    _filters = _filters.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
    notifyListeners();
  }

  void setRating(double? minRating) {
    _filters = _filters.copyWith(minRating: minRating);
    notifyListeners();
  }

  void setSortBy(SpecialistSortOption? sortBy) {
    _filters = _filters.copyWith(sortBy: sortBy);
    notifyListeners();
  }
}

/// Провайдер состояния поиска
final specialistSearchStateProvider = Provider<SpecialistSearchNotifier>((ref) {
  return SpecialistSearchNotifier();
});

/// Состояние поиска специалистов
class SpecialistSearchState {
  const SpecialistSearchState({
    this.query = '',
    this.isSearching = false,
    this.results = const [],
    this.currentFilters = const SpecialistFilters(),
    this.hasActiveFilters = false,
  });

  final String query;
  final bool isSearching;
  final List<Specialist> results;
  final SpecialistFilters currentFilters;
  final bool hasActiveFilters;

  SpecialistSearchState copyWith({
    String? query,
    bool? isSearching,
    List<Specialist>? results,
    SpecialistFilters? currentFilters,
    bool? hasActiveFilters,
  }) {
    return SpecialistSearchState(
      query: query ?? this.query,
      isSearching: isSearching ?? this.isSearching,
      results: results ?? this.results,
      currentFilters: currentFilters ?? this.currentFilters,
      hasActiveFilters: hasActiveFilters ?? this.hasActiveFilters,
    );
  }
}

/// Notifier для поиска специалистов
class SpecialistSearchNotifier extends ChangeNotifier {
  SpecialistSearchState _state = const SpecialistSearchState();

  SpecialistSearchState get state => _state;

  void startSearch(String query, SpecialistFilters filters) {
    _state = _state.copyWith(
      query: query,
      isSearching: true,
      currentFilters: filters,
      hasActiveFilters: _hasActiveFilters(filters),
    );
    notifyListeners();
  }

  void updateResults(List<Specialist> results) {
    _state = _state.copyWith(
      results: results,
      isSearching: false,
    );
    notifyListeners();
  }

  void updateFilters(SpecialistFilters filters) {
    _state = _state.copyWith(
      currentFilters: filters,
      hasActiveFilters: _hasActiveFilters(filters),
    );
    notifyListeners();
  }

  void clearSearch() {
    _state = const SpecialistSearchState();
    notifyListeners();
  }

  bool _hasActiveFilters(SpecialistFilters filters) {
    return filters.category != null ||
        filters.city != null ||
        filters.minPrice != null ||
        filters.maxPrice != null ||
        filters.minRating != null;
  }
}
