import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/search_filters.dart';
import '../models/specialist.dart';
import '../services/specialist_service.dart';

/// Search filters notifier
class SearchFiltersNotifier extends Notifier<SearchFilters> {
  @override
  SearchFilters build() => SearchFilters.empty();
  
  void updateFilters(SearchFilters filters) {
    state = filters;
  }
  
  void clearFilters() {
    state = SearchFilters.empty();
  }
}

/// Specialist service provider
final specialistServiceProvider = Provider<SpecialistService>((ref) {
  return SpecialistService();
});

/// All specialists provider
final specialistsProvider = FutureProvider<List<Specialist>>((ref) async {
  final service = ref.read(specialistServiceProvider);
  return await service.getAllSpecialists();
});

/// Top specialists provider (by rating)
final topSpecialistsProvider = FutureProvider<List<Specialist>>((ref) async {
  final service = ref.read(specialistServiceProvider);
  return await service.getTopSpecialists();
});

/// Top specialists by Russia provider
final topSpecialistsRuProvider = FutureProvider<List<Specialist>>((ref) async {
  final service = ref.read(specialistServiceProvider);
  return await service.getTopSpecialists();
});

/// Top specialists by city provider
final topSpecialistsCityProvider = FutureProvider.family<List<Specialist>, String>((
  ref,
  city,
) async {
  final service = ref.read(specialistServiceProvider);
  return await service.getTopSpecialistsByCity(city);
});

/// Specialists by city provider
final specialistsByCityProvider = FutureProvider.family<List<Specialist>, String>((
  ref,
  city,
) async {
  final service = ref.read(specialistServiceProvider);
  return await service.getSpecialistsByCity(city);
});

/// Specialists by specialization provider
final specialistsBySpecializationProvider = FutureProvider.family<List<Specialist>, String>((
  ref,
  specialization,
) async {
  final service = ref.read(specialistServiceProvider);
  return await service.getSpecialistsBySpecialization(specialization);
});

/// Search filters provider
final searchFiltersProvider = NotifierProvider<SearchFiltersNotifier, SearchFilters>(() {
  return SearchFiltersNotifier();
});

/// Search results provider
final searchResultsProvider = FutureProvider.family<List<Specialist>, SearchFilters>((
  ref,
  filters,
) async {
  final service = ref.read(specialistServiceProvider);
  return await service.searchSpecialists(filters);
});

/// Available specializations provider
final specializationsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.read(specialistServiceProvider);
  return await service.getSpecializations();
});

/// Available cities provider
final citiesProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.read(specialistServiceProvider);
  return await service.getCities();
});

/// Available services provider
final servicesProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.read(specialistServiceProvider);
  return await service.getServices();
});

/// Specialist by ID provider
final specialistByIdProvider = FutureProvider.family<Specialist?, String>((ref, id) async {
  final service = ref.read(specialistServiceProvider);
  return await service.getSpecialistById(id);
});

/// Stream of all specialists provider
final specialistsStreamProvider = StreamProvider<List<Specialist>>((ref) {
  final service = ref.read(specialistServiceProvider);
  return service.getSpecialistsStream();
});

/// Stream of specialists by city provider
final specialistsByCityStreamProvider = StreamProvider.family<List<Specialist>, String>((
  ref,
  city,
) {
  final service = ref.read(specialistServiceProvider);
  return service.getSpecialistsByCityStream(city);
});

/// Popular specializations provider (most used)
final popularSpecializationsProvider = FutureProvider<List<String>>((ref) async {
  final specialistsAsync = ref.watch(specialistsProvider);
  return specialistsAsync.when(
    data: (specialists) {
      final specializationCount = <String, int>{};
      for (final specialist in specialists) {
        specializationCount[specialist.specialization] =
            (specializationCount[specialist.specialization] ?? 0) + 1;
      }

      final sortedSpecializations = specializationCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedSpecializations.take(8).map((e) => e.key).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Popular cities provider (most used)
final popularCitiesProvider = FutureProvider<List<String>>((ref) async {
  final specialistsAsync = ref.watch(specialistsProvider);
  return specialistsAsync.when(
    data: (specialists) {
      final cityCount = <String, int>{};
      for (final specialist in specialists) {
        cityCount[specialist.city] = (cityCount[specialist.city] ?? 0) + 1;
      }

      final sortedCities = cityCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

      return sortedCities.take(10).map((e) => e.key).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
