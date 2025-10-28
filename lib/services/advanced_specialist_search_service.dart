import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:event_marketplace_app/models/advanced_search_filters.dart';
import 'package:event_marketplace_app/models/city_region.dart';
import 'package:event_marketplace_app/models/specialist.dart';
import 'package:event_marketplace_app/services/city_region_service.dart';

/// Сервис расширенного поиска специалистов по всей России
class AdvancedSpecialistSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CityRegionService _cityService = CityRegionService();
  static const String _collectionName = 'specialists';

  /// Поиск специалистов с расширенными фильтрами
  Future<List<AdvancedSearchResult>> searchSpecialists({
    required AdvancedSearchFilters filters,
    int limit = 50,
    DocumentSnapshot? lastDocument,
  }) async {
    final startTime = DateTime.now();

    try {
      // Получаем города для поиска
      final searchCities = await _getSearchCities(filters);

      // Строим базовый запрос
      Query<Map<String, dynamic>> query =
          _firestore.collection(_collectionName);

      // Применяем фильтры
      query = _applyFilters(query, filters, searchCities);

      // Применяем сортировку
      query = _applySorting(query, filters);

      // Ограничиваем количество результатов
      query = query.limit(limit);

      // Выполняем запрос
      final querySnapshot = await query.get();

      // Преобразуем результаты
      var results = <AdvancedSearchResult>[];

      for (final doc in querySnapshot.docs) {
        final specialist = Specialist.fromDocument(doc);
        final result =
            await _createSearchResult(specialist, filters, searchCities);
        if (result != null) {
          results.add(result);
        }
      }

      // Дополнительная фильтрация и сортировка на клиенте
      results = _applyClientSideFilters(results, filters);
      results = _applyClientSideSorting(results, filters);

      final endTime = DateTime.now();
      final searchTime = endTime.difference(startTime).inMilliseconds;

      // Обновляем время поиска в результатах (для отладки)
      debugPrint(
          'Поиск завершен за $searchTimeмс, найдено ${results.length} результатов',);

      return results;
    } catch (e) {
      debugPrint('Ошибка расширенного поиска специалистов: $e');
      return [];
    }
  }

  /// Поток поиска специалистов с фильтрами
  Stream<List<AdvancedSearchResult>> searchSpecialistsStream({
    required AdvancedSearchFilters filters,
    int limit = 50,
  }) async* {
    try {
      // Получаем города для поиска
      final searchCities = await _getSearchCities(filters);

      // Строим базовый запрос
      Query<Map<String, dynamic>> query =
          _firestore.collection(_collectionName);

      // Применяем фильтры
      query = _applyFilters(query, filters, searchCities);

      // Применяем сортировку
      query = _applySorting(query, filters);

      // Ограничиваем количество результатов
      query = query.limit(limit);

      // Слушаем изменения
      await for (final snapshot in query.snapshots()) {
        var results = <AdvancedSearchResult>[];

        for (final doc in snapshot.docs) {
          final specialist = Specialist.fromDocument(doc);
          final result =
              await _createSearchResult(specialist, filters, searchCities);
          if (result != null) {
            results.add(result);
          }
        }

        // Дополнительная фильтрация и сортировка на клиенте
        results = _applyClientSideFilters(results, filters);
        results = _applyClientSideSorting(results, filters);

        yield results;
      }
    } catch (e) {
      debugPrint('Ошибка потока поиска специалистов: $e');
      yield [];
    }
  }

  /// Получить города для поиска
  Future<List<CityRegion>> _getSearchCities(
      AdvancedSearchFilters filters,) async {
    if (filters.selectedCity != null) {
      final cities = [filters.selectedCity!];

      // Добавляем соседние города, если включено
      if (filters.includeNearbyCities) {
        final nearbyCities = await _cityService.getNearbyCities(
          latitude: filters.selectedCity!.coordinates.latitude,
          longitude: filters.selectedCity!.coordinates.longitude,
          radiusKm: filters.maxDistance,
        );
        cities.addAll(nearbyCities);
      }

      return cities;
    } else if (filters.selectedRegion != null) {
      return _cityService.getCitiesByRegion(
          regionName: filters.selectedRegion!,);
    } else {
      // Поиск по всей России
      return _cityService.getCities(limit: 1000);
    }
  }

  /// Применить фильтры к запросу
  Query<Map<String, dynamic>> _applyFilters(
    Query<Map<String, dynamic>> query,
    AdvancedSearchFilters filters,
    List<CityRegion> searchCities,
  ) {
    // Фильтр по доступности
    query = query.where('isAvailable', isEqualTo: true);

    // Фильтр по категориям
    if (filters.categories.isNotEmpty) {
      query = query.where(
        'categories',
        arrayContainsAny: filters.categories.map((cat) => cat.name).toList(),
      );
    }

    // Фильтр по подкатегориям
    if (filters.subcategories.isNotEmpty) {
      query =
          query.where('subcategories', arrayContainsAny: filters.subcategories);
    }

    // Фильтр по локации (города)
    if (searchCities.isNotEmpty) {
      final cityNames = searchCities.map((city) => city.cityName).toList();
      query = query.where('location', whereIn: cityNames);
    }

    // Фильтр по рейтингу
    if (filters.minRating > 0) {
      query = query.where('rating', isGreaterThanOrEqualTo: filters.minRating);
    }
    if (filters.maxRating < 5.0) {
      query = query.where('rating', isLessThanOrEqualTo: filters.maxRating);
    }

    // Фильтр по цене
    if (filters.minPrice > 0) {
      query = query.where('price', isGreaterThanOrEqualTo: filters.minPrice);
    }
    if (filters.maxPrice < 100000) {
      query = query.where('price', isLessThanOrEqualTo: filters.maxPrice);
    }

    // Если нет фильтров по цене, добавляем базовый фильтр для исключения нулевых цен
    if (filters.minPrice == 0 && filters.maxPrice >= 100000) {
      query = query.where('price', isGreaterThan: 0);
    }

    // Фильтр по опыту
    if (filters.minExperience > 0) {
      query = query.where('yearsOfExperience',
          isGreaterThanOrEqualTo: filters.minExperience,);
    }
    if (filters.maxExperience < 50) {
      query = query.where('yearsOfExperience',
          isLessThanOrEqualTo: filters.maxExperience,);
    }

    // Фильтр по уровню опыта
    if (filters.experienceLevel != null) {
      query = query.where('experienceLevel',
          isEqualTo: filters.experienceLevel!.name,);
    }

    // Фильтр по верификации
    if (filters.isVerified) {
      query = query.where('isVerified', isEqualTo: true);
    }

    // Фильтр по наличию портфолио
    if (filters.hasPortfolio) {
      query = query.where('portfolioImages', isGreaterThan: []);
    }

    // Фильтр по наличию отзывов
    if (filters.hasReviews) {
      query = query.where('reviewCount', isGreaterThan: 0);
    }

    // Фильтр по языкам
    if (filters.languages.isNotEmpty) {
      query = query.where('languages', arrayContainsAny: filters.languages);
    }

    // Фильтр по оборудованию
    if (filters.equipment.isNotEmpty) {
      query = query.where('equipment', arrayContainsAny: filters.equipment);
    }

    // Фильтр по услугам
    if (filters.services.isNotEmpty) {
      query = query.where('services', arrayContainsAny: filters.services);
    }

    return query;
  }

  /// Применить сортировку к запросу
  Query<Map<String, dynamic>> _applySorting(
    Query<Map<String, dynamic>> query,
    AdvancedSearchFilters filters,
  ) {
    switch (filters.sortBy) {
      case AdvancedSearchSortBy.rating:
        query = query.orderBy('rating', descending: !filters.sortAscending);
      case AdvancedSearchSortBy.priceAsc:
        query = query.orderBy('price', descending: false);
      case AdvancedSearchSortBy.priceDesc:
        query = query.orderBy('price', descending: true);
      case AdvancedSearchSortBy.experience:
        query = query.orderBy('yearsOfExperience',
            descending: !filters.sortAscending,);
      case AdvancedSearchSortBy.reviewsCount:
        query =
            query.orderBy('reviewCount', descending: !filters.sortAscending);
      case AdvancedSearchSortBy.newest:
        query = query.orderBy('createdAt', descending: !filters.sortAscending);
      case AdvancedSearchSortBy.availability:
        query =
            query.orderBy('lastActiveAt', descending: !filters.sortAscending);
      default:
        // По умолчанию сортируем по рейтингу
        query = query.orderBy('rating', descending: true);
    }

    return query;
  }

  /// Создать результат поиска
  Future<AdvancedSearchResult?> _createSearchResult(
    Specialist specialist,
    AdvancedSearchFilters filters,
    List<CityRegion> searchCities,
  ) async {
    try {
      // Вычисляем релевантность
      final relevanceScore = _calculateRelevanceScore(specialist, filters);

      // Вычисляем расстояние
      double? distance;
      if (filters.selectedCity != null) {
        // Находим город специалиста
        final specialistCity = searchCities.firstWhere(
          (city) => city.cityName == specialist.location,
          orElse: () => filters.selectedCity!,
        );
        distance = specialistCity.coordinates
            .distanceTo(filters.selectedCity!.coordinates);
      }

      // Вычисляем баллы
      final availabilityScore =
          _calculateAvailabilityScore(specialist, filters);
      final priceScore = _calculatePriceScore(specialist, filters);
      final ratingScore = _calculateRatingScore(specialist, filters);
      final experienceScore = _calculateExperienceScore(specialist, filters);

      // Находим совпадающие категории и услуги
      final matchingCategories = specialist.categories
          .where((cat) => filters.categories.contains(cat))
          .map((cat) => cat.name)
          .toList();

      final matchingServices = specialist.services
          .where((service) => filters.services.contains(service))
          .toList();

      return AdvancedSearchResult(
        specialist: specialist,
        relevanceScore: relevanceScore,
        distance: distance,
        city: specialist.location,
        region: _findRegionForCity(specialist.location, searchCities),
        matchingCategories: matchingCategories,
        matchingServices: matchingServices,
        availabilityScore: availabilityScore,
        priceScore: priceScore,
        ratingScore: ratingScore,
        experienceScore: experienceScore,
      );
    } catch (e) {
      debugPrint('Ошибка создания результата поиска: $e');
      return null;
    }
  }

  /// Вычислить балл релевантности
  double _calculateRelevanceScore(
      Specialist specialist, AdvancedSearchFilters filters,) {
    var score = 0;

    // Поиск по тексту
    if (filters.searchQuery.isNotEmpty) {
      final query = filters.searchQuery.toLowerCase();
      if (specialist.name.toLowerCase().contains(query)) {
        score += 0.3;
      }
      if (specialist.description?.toLowerCase().contains(query) ?? false) {
        score += 0.2;
      }
      if (specialist.categories
          .any((cat) => cat.displayName.toLowerCase().contains(query))) {
        score += 0.2;
      }
      if (specialist.services
          .any((service) => service.toLowerCase().contains(query))) {
        score += 0.1;
      }
    }

    // Совпадение категорий
    if (filters.categories.isNotEmpty) {
      final matchingCategories = specialist.categories
          .where((cat) => filters.categories.contains(cat))
          .length;
      score += (matchingCategories / filters.categories.length) * 0.2;
    }

    // Совпадение услуг
    if (filters.services.isNotEmpty) {
      final matchingServices = specialist.services
          .where((service) => filters.services.contains(service))
          .length;
      score += (matchingServices / filters.services.length) * 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Вычислить балл доступности
  double _calculateAvailabilityScore(
      Specialist specialist, AdvancedSearchFilters filters,) {
    var score = 0;

    if (specialist.isAvailable) {
      score += 0.5;
    }

    if (specialist.isOnline ?? false) {
      score += 0.3;
    }

    if (filters.isAvailableNow && specialist.isAvailable) {
      score += 0.2;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Вычислить балл цены
  double _calculatePriceScore(
      Specialist specialist, AdvancedSearchFilters filters,) {
    if (filters.minPrice == 0 && filters.maxPrice == 100000) {
      return 1; // Нет фильтра по цене
    }

    final price = specialist.price;
    if (price >= filters.minPrice && price <= filters.maxPrice) {
      return 1;
    } else if (price < filters.minPrice) {
      return 0.5; // Дешевле желаемого
    } else {
      return 0; // Дороже желаемого
    }
  }

  /// Вычислить балл рейтинга
  double _calculateRatingScore(
      Specialist specialist, AdvancedSearchFilters filters,) {
    if (filters.minRating == 0.0 && filters.maxRating == 5.0) {
      return specialist.rating / 5.0; // Нормализуем к 0-1
    }

    final rating = specialist.rating;
    if (rating >= filters.minRating && rating <= filters.maxRating) {
      return rating / 5.0;
    } else {
      return 0;
    }
  }

  /// Вычислить балл опыта
  double _calculateExperienceScore(
      Specialist specialist, AdvancedSearchFilters filters,) {
    if (filters.minExperience == 0 && filters.maxExperience == 50) {
      return (specialist.yearsOfExperience / 20.0).clamp(0.0, 1.0);
    }

    final experience = specialist.yearsOfExperience;
    if (experience >= filters.minExperience &&
        experience <= filters.maxExperience) {
      return (experience / 20.0).clamp(0.0, 1.0);
    } else {
      return 0;
    }
  }

  /// Найти регион для города
  String? _findRegionForCity(String? cityName, List<CityRegion> searchCities) {
    if (cityName == null) return null;

    final city = searchCities.firstWhere(
      (city) => city.cityName == cityName,
      orElse: () => searchCities.first,
    );

    return city.regionName;
  }

  /// Дополнительная фильтрация на клиенте
  List<AdvancedSearchResult> _applyClientSideFilters(
    List<AdvancedSearchResult> results,
    AdvancedSearchFilters filters,
  ) =>
      results.where((result) {
        final specialist = result.specialist;

        // Фильтр по расстоянию
        if (filters.selectedCity != null && result.distance != null) {
          if (result.distance! > filters.radiusKm) {
            return false;
          }
        }

        // Фильтр по датам доступности
        if (filters.availableFrom != null || filters.availableTo != null) {
          // TODO(developer): Реализовать проверку доступности по датам
          // Это требует интеграции с календарем специалиста
        }

        // Фильтр по минимальному баллу релевантности
        if (result.relevanceScore < 0.1) {
          return false;
        }

        return true;
      }).toList();

  /// Дополнительная сортировка на клиенте
  List<AdvancedSearchResult> _applyClientSideSorting(
    List<AdvancedSearchResult> results,
    AdvancedSearchFilters filters,
  ) {
    switch (filters.sortBy) {
      case AdvancedSearchSortBy.relevance:
        results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
      case AdvancedSearchSortBy.distance:
        if (filters.selectedCity != null) {
          results.sort((a, b) {
            final distanceA = a.distance ?? double.infinity;
            final distanceB = b.distance ?? double.infinity;
            return distanceA.compareTo(distanceB);
          });
        }
      case AdvancedSearchSortBy.popularity:
        results.sort((a, b) =>
            b.specialist.reviewCount.compareTo(a.specialist.reviewCount),);
      default:
        // Сортировка уже применена на сервере
        break;
    }

    if (filters.sortAscending) {
      results = results.reversed.toList();
    }

    return results;
  }

  /// Получить популярные категории в регионе
  Future<List<SpecialistCategory>> getPopularCategoriesInRegion({
    String? regionName,
    CityRegion? city,
    int limit = 10,
  }) async {
    try {
      List<CityRegion> searchCities;

      if (city != null) {
        searchCities = [city];
      } else if (regionName != null) {
        searchCities =
            await _cityService.getCitiesByRegion(regionName: regionName);
      } else {
        searchCities = await _cityService.getCities();
      }

      final cityNames = searchCities.map((city) => city.cityName).toList();

      final query = await _firestore
          .collection(_collectionName)
          .where('isAvailable', isEqualTo: true)
          .where('location', whereIn: cityNames)
          .get();

      final categoryCounts = <SpecialistCategory, int>{};

      for (final doc in query.docs) {
        final specialist = Specialist.fromDocument(doc);
        for (final category in specialist.categories) {
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
      }

      final sortedCategories = categoryCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedCategories.take(limit).map((entry) => entry.key).toList();
    } catch (e) {
      debugPrint('Ошибка получения популярных категорий: $e');
      return [];
    }
  }

  /// Получить статистику поиска
  Future<Map<String, dynamic>> getSearchStats(
      {required AdvancedSearchFilters filters,}) async {
    try {
      final searchCities = await _getSearchCities(filters);
      final cityNames = searchCities.map((city) => city.cityName).toList();

      final query = await _firestore
          .collection(_collectionName)
          .where('isAvailable', isEqualTo: true)
          .where('location', whereIn: cityNames)
          .get();

      final totalSpecialists = query.docs.length;
      final avgRating = query.docs
              .map((doc) => Specialist.fromDocument(doc).rating)
              .reduce((a, b) => a + b) /
          totalSpecialists;

      final priceRange = query.docs
          .map((doc) => Specialist.fromDocument(doc).price)
          .toList()
        ..sort();

      return {
        'totalSpecialists': totalSpecialists,
        'avgRating': avgRating,
        'minPrice': priceRange.isNotEmpty ? priceRange.first : 0,
        'maxPrice': priceRange.isNotEmpty ? priceRange.last : 0,
        'searchCities': searchCities.length,
      };
    } catch (e) {
      debugPrint('Ошибка получения статистики поиска: $e');
      return {
        'totalSpecialists': 0,
        'avgRating': 0.0,
        'minPrice': 0,
        'maxPrice': 0,
        'searchCities': 0,
      };
    }
  }
}
