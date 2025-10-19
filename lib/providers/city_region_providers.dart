import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/city_region.dart';
import '../services/city_region_service.dart';

/// Провайдер сервиса городов и регионов
final cityRegionServiceProvider = Provider<CityRegionService>((ref) => CityRegionService());

/// Провайдер для получения всех городов
final citiesProvider = FutureProvider<List<CityRegion>>((ref) async {
  final service = ref.read(cityRegionServiceProvider);
  return service.getCities();
});

/// Провайдер для получения городов с фильтрами (мигрирован с StateNotifierProvider)
final filteredCitiesProvider =
    NotifierProvider<FilteredCitiesNotifier, AsyncValue<List<CityRegion>>>(() {
  return FilteredCitiesNotifier();
});

/// Провайдер для поиска городов по названию (мигрирован с StateNotifierProvider)
final citySearchProvider =
    NotifierProvider<CitySearchNotifier, AsyncValue<List<CityRegion>>>(() {
  return CitySearchNotifier();
});

/// Провайдер для получения популярных городов
final popularCitiesProvider = FutureProvider<List<CityRegion>>((ref) async {
  final service = ref.read(cityRegionServiceProvider);
  return service.getPopularCities();
});

/// Провайдер для получения всех регионов
final regionsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.read(cityRegionServiceProvider);
  return service.getRegions();
});

/// Провайдер для получения текущего местоположения
final currentLocationProvider = FutureProvider<Position?>((ref) async {
  final service = ref.read(cityRegionServiceProvider);
  return service.getCurrentLocation();
});

/// Провайдер для получения ближайших городов (мигрирован с StateNotifierProvider)
final nearbyCitiesProvider =
    NotifierProvider<NearbyCitiesNotifier, AsyncValue<List<CityRegion>>>(() {
  return NearbyCitiesNotifier();
});

/// Провайдер для выбранного города
final selectedCityProvider = StateProvider<CityRegion?>((ref) => null);

/// Провайдер для фильтров поиска городов
final citySearchFiltersProvider =
    StateProvider<CitySearchFilters>((ref) => const CitySearchFilters());

/// Провайдер для состояния инициализации городов
final citiesInitializationProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(cityRegionServiceProvider);
  try {
    await service.initializeRussianCities();
    return true;
  } on Exception {
    return false;
  }
});

/// Нотификатор для фильтрованных городов (мигрирован с StateNotifier)
class FilteredCitiesNotifier extends Notifier<AsyncValue<List<CityRegion>>> {
  @override
  AsyncValue<List<CityRegion>> build() {
    loadCities();
    return const AsyncValue.loading();
  }

  CityRegionService get _service => ref.read(cityRegionServiceProvider);
  CitySearchFilters _filters = const CitySearchFilters();

  /// Загрузить города с текущими фильтрами
  Future<void> loadCities() async {
    state = const AsyncValue.loading();
    try {
      final cities = await _service.getCities(filters: _filters);
      state = AsyncValue.data(cities);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Применить новые фильтры
  Future<void> applyFilters(CitySearchFilters filters) async {
    _filters = filters;
    await loadCities();
  }

  /// Обновить фильтр поиска
  Future<void> updateSearchQuery(String query) async {
    _filters = _filters.copyWith(searchQuery: query);
    await loadCities();
  }

  /// Обновить фильтр региона
  Future<void> updateRegion(String? region) async {
    _filters = _filters.copyWith(region: region);
    await loadCities();
  }

  /// Обновить фильтр размера города
  Future<void> updateCitySize(CitySize? citySize) async {
    _filters = _filters.copyWith(citySize: citySize);
    await loadCities();
  }

  /// Обновить фильтр населения
  Future<void> updatePopulationRange(int min, int max) async {
    _filters = _filters.copyWith(minPopulation: min, maxPopulation: max);
    await loadCities();
  }

  /// Обновить сортировку
  Future<void> updateSorting(CitySortBy sortBy, bool ascending) async {
    _filters = _filters.copyWith(sortBy: sortBy, sortAscending: ascending);
    await loadCities();
  }

  /// Сбросить фильтры
  Future<void> clearFilters() async {
    _filters = const CitySearchFilters();
    await loadCities();
  }

  /// Получить текущие фильтры
  CitySearchFilters get filters => _filters;
}

/// Нотификатор для поиска городов (мигрирован с StateNotifier)
class CitySearchNotifier extends Notifier<AsyncValue<List<CityRegion>>> {
  @override
  AsyncValue<List<CityRegion>> build() {
    return const AsyncValue.data([]);
  }

  CityRegionService get _service => ref.read(cityRegionServiceProvider);

  /// Поиск городов по названию
  Future<void> searchCities(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final cities = await _service.searchCitiesByName(query: query);
      state = AsyncValue.data(cities);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Очистить результаты поиска
  void clearSearch() {
    state = const AsyncValue.data([]);
  }
}

/// Нотификатор для ближайших городов (мигрирован с StateNotifier)
class NearbyCitiesNotifier extends Notifier<AsyncValue<List<CityRegion>>> {
  @override
  AsyncValue<List<CityRegion>> build() {
    return const AsyncValue.data([]);
  }

  CityRegionService get _service => ref.read(cityRegionServiceProvider);

  /// Получить ближайшие города к координатам
  Future<void> getNearbyCities({
    required double latitude,
    required double longitude,
    double radiusKm = 100.0,
  }) async {
    state = const AsyncValue.loading();
    try {
      final cities = await _service.getNearbyCities(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      state = AsyncValue.data(cities);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Получить ближайшие города к текущему местоположению
  Future<void> getNearbyCitiesToCurrentLocation() async {
    try {
      final position = await _service.getCurrentLocation();
      if (position != null) {
        await getNearbyCities(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } else {
        state = const AsyncValue.error('Не удалось получить местоположение', null);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Очистить результаты
  void clearResults() {
    state = const AsyncValue.data([]);
  }
}

/// Провайдер для получения городов по региону
final citiesByRegionProvider =
    FutureProvider.family<List<CityRegion>, String>((ref, regionName) async {
  final service = ref.read(cityRegionServiceProvider);
  return service.getCitiesByRegion(regionName: regionName);
});

/// Провайдер для получения города по ID
final cityByIdProvider = FutureProvider.family<CityRegion?, String>((ref, cityId) async {
  final service = ref.read(cityRegionServiceProvider);
  return service.getCityById(cityId);
});

/// Провайдер для получения города по координатам
final cityByCoordinatesProvider =
    FutureProvider.family<CityRegion?, Map<String, double>>((ref, coordinates) async {
  final service = ref.read(cityRegionServiceProvider);
  return service.getCityByCoordinates(
    latitude: coordinates['latitude']!,
    longitude: coordinates['longitude']!,
  );
});

/// Провайдер для статистики специалистов в городе
final citySpecialistStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, cityId) async {
  final service = ref.read(cityRegionServiceProvider);
  final city = await service.getCityById(cityId);

  if (city != null) {
    return {
      'totalSpecialists': city.totalSpecialists,
      'avgRating': city.avgSpecialistRating,
      'categories': city.specialistCategories,
    };
  }

  return {
    'totalSpecialists': 0,
    'avgRating': 0.0,
    'categories': <String>[],
  };
});

/// Провайдер для проверки доступности геолокации
final locationPermissionProvider = FutureProvider<LocationPermission>(
  (ref) async => Geolocator.checkPermission(),
);

/// Провайдер для запроса разрешения на геолокацию
final requestLocationPermissionProvider = FutureProvider<LocationPermission>(
  (ref) async => Geolocator.requestPermission(),
);

/// Провайдер для проверки включенности служб геолокации
final locationServiceEnabledProvider =
    FutureProvider<bool>((ref) async => Geolocator.isLocationServiceEnabled());

/// Провайдер для потока городов с фильтрами
final citiesStreamProvider =
    StreamProvider.family<List<CityRegion>, CitySearchFilters>((ref, filters) {
  final service = ref.read(cityRegionServiceProvider);
  return service.getCitiesStream(filters: filters);
});

/// Провайдер для популярных городов в регионе
final popularCitiesInRegionProvider =
    FutureProvider.family<List<CityRegion>, String>((ref, regionName) async {
  final service = ref.read(cityRegionServiceProvider);
  final cities = await service.getCitiesByRegion(regionName: regionName);

  // Сортируем по приоритету и возвращаем топ-10
  cities.sort((a, b) => a.priority.compareTo(b.priority));
  return cities.take(10).toList();
});

/// Провайдер для городов с специалистами определенной категории
final citiesWithSpecialistsProvider =
    FutureProvider.family<List<CityRegion>, String>((ref, category) async {
  final service = ref.read(cityRegionServiceProvider);
  final filters = CitySearchFilters(
    hasSpecialists: true,
    specialistCategory: category,
    sortBy: CitySortBy.specialistCount,
  );
  return service.getCities(filters: filters);
});
