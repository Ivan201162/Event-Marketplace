import 'city_region.dart';
import 'common_types.dart';
import 'specialist.dart';

/// Расширенные фильтры для поиска специалистов по всей России
class AdvancedSearchFilters {
  const AdvancedSearchFilters({
    this.searchQuery = '',
    this.categories = const [],
    this.subcategories = const [],
    this.selectedCity,
    this.selectedRegion,
    this.radiusKm = 50.0,
    this.minPrice = 0,
    this.maxPrice = 100000,
    this.minRating = 0.0,
    this.maxRating = 5.0,
    this.minExperience = 0,
    this.maxExperience = 50,
    this.experienceLevel,
    this.isAvailableNow = false,
    this.availableFrom,
    this.availableTo,
    this.hasPortfolio = false,
    this.isVerified = false,
    this.hasReviews = false,
    this.languages = const [],
    this.equipment = const [],
    this.services = const [],
    this.sortBy = AdvancedSearchSortBy.relevance,
    this.sortAscending = false,
    this.includeNearbyCities = true,
    this.maxDistance = 200.0,
  });

  /// Создать из JSON
  factory AdvancedSearchFilters.fromJson(Map<String, dynamic> json) => AdvancedSearchFilters(
    searchQuery: json['searchQuery'] as String? ?? '',
    categories:
        (json['categories'] as List<dynamic>?)
            ?.map(
              (e) => SpecialistCategory.values.firstWhere(
                (cat) => cat.name == e,
                orElse: () => SpecialistCategory.other,
              ),
            )
            .toList() ??
        [],
    subcategories: (json['subcategories'] as List<dynamic>?)?.cast<String>() ?? [],
    selectedCity: json['selectedCity'] != null
        ? CityRegion.fromMap(json['selectedCity'] as Map<String, dynamic>)
        : null,
    selectedRegion: json['selectedRegion'] as String?,
    radiusKm: (json['radiusKm'] as num?)?.toDouble() ?? 50.0,
    minPrice: json['minPrice'] as int? ?? 0,
    maxPrice: json['maxPrice'] as int? ?? 100000,
    minRating: (json['minRating'] as num?)?.toDouble() ?? 0.0,
    maxRating: (json['maxRating'] as num?)?.toDouble() ?? 5.0,
    minExperience: json['minExperience'] as int? ?? 0,
    maxExperience: json['maxExperience'] as int? ?? 50,
    experienceLevel: json['experienceLevel'] != null
        ? ExperienceLevel.values.firstWhere(
            (e) => e.name == json['experienceLevel'],
            orElse: () => ExperienceLevel.beginner,
          )
        : null,
    isAvailableNow: json['isAvailableNow'] as bool? ?? false,
    availableFrom: json['availableFrom'] != null
        ? DateTime.parse(json['availableFrom'] as String)
        : null,
    availableTo: json['availableTo'] != null ? DateTime.parse(json['availableTo'] as String) : null,
    hasPortfolio: json['hasPortfolio'] as bool? ?? false,
    isVerified: json['isVerified'] as bool? ?? false,
    hasReviews: json['hasReviews'] as bool? ?? false,
    languages: (json['languages'] as List<dynamic>?)?.cast<String>() ?? [],
    equipment: (json['equipment'] as List<dynamic>?)?.cast<String>() ?? [],
    services: (json['services'] as List<dynamic>?)?.cast<String>() ?? [],
    sortBy: AdvancedSearchSortBy.values.firstWhere(
      (e) => e.name == json['sortBy'],
      orElse: () => AdvancedSearchSortBy.relevance,
    ),
    sortAscending: json['sortAscending'] as bool? ?? false,
    includeNearbyCities: json['includeNearbyCities'] as bool? ?? true,
    maxDistance: (json['maxDistance'] as num?)?.toDouble() ?? 200.0,
  );

  final String searchQuery;
  final List<SpecialistCategory> categories;
  final List<String> subcategories;
  final CityRegion? selectedCity;
  final String? selectedRegion;
  final double radiusKm;
  final int minPrice;
  final int maxPrice;
  final double minRating;
  final double maxRating;
  final int minExperience;
  final int maxExperience;
  final ExperienceLevel? experienceLevel;
  final bool isAvailableNow;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final bool hasPortfolio;
  final bool isVerified;
  final bool hasReviews;
  final List<String> languages;
  final List<String> equipment;
  final List<String> services;
  final AdvancedSearchSortBy sortBy;
  final bool sortAscending;
  final bool includeNearbyCities;
  final double maxDistance;

  /// Преобразовать в JSON
  Map<String, dynamic> toJson() => {
    'searchQuery': searchQuery,
    'categories': categories.map((e) => e.name).toList(),
    'subcategories': subcategories,
    'selectedCity': selectedCity?.toMap(),
    'selectedRegion': selectedRegion,
    'radiusKm': radiusKm,
    'minPrice': minPrice,
    'maxPrice': maxPrice,
    'minRating': minRating,
    'maxRating': maxRating,
    'minExperience': minExperience,
    'maxExperience': maxExperience,
    'experienceLevel': experienceLevel?.name,
    'isAvailableNow': isAvailableNow,
    'availableFrom': availableFrom?.toIso8601String(),
    'availableTo': availableTo?.toIso8601String(),
    'hasPortfolio': hasPortfolio,
    'isVerified': isVerified,
    'hasReviews': hasReviews,
    'languages': languages,
    'equipment': equipment,
    'services': services,
    'sortBy': sortBy.name,
    'sortAscending': sortAscending,
    'includeNearbyCities': includeNearbyCities,
    'maxDistance': maxDistance,
  };

  /// Копировать с изменениями
  AdvancedSearchFilters copyWith({
    String? searchQuery,
    List<SpecialistCategory>? categories,
    List<String>? subcategories,
    CityRegion? selectedCity,
    String? selectedRegion,
    double? radiusKm,
    int? minPrice,
    int? maxPrice,
    double? minRating,
    double? maxRating,
    int? minExperience,
    int? maxExperience,
    ExperienceLevel? experienceLevel,
    bool? isAvailableNow,
    DateTime? availableFrom,
    DateTime? availableTo,
    bool? hasPortfolio,
    bool? isVerified,
    bool? hasReviews,
    List<String>? languages,
    List<String>? equipment,
    List<String>? services,
    AdvancedSearchSortBy? sortBy,
    bool? sortAscending,
    bool? includeNearbyCities,
    double? maxDistance,
  }) => AdvancedSearchFilters(
    searchQuery: searchQuery ?? this.searchQuery,
    categories: categories ?? this.categories,
    subcategories: subcategories ?? this.subcategories,
    selectedCity: selectedCity ?? this.selectedCity,
    selectedRegion: selectedRegion ?? this.selectedRegion,
    radiusKm: radiusKm ?? this.radiusKm,
    minPrice: minPrice ?? this.minPrice,
    maxPrice: maxPrice ?? this.maxPrice,
    minRating: minRating ?? this.minRating,
    maxRating: maxRating ?? this.maxRating,
    minExperience: minExperience ?? this.minExperience,
    maxExperience: maxExperience ?? this.maxExperience,
    experienceLevel: experienceLevel ?? this.experienceLevel,
    isAvailableNow: isAvailableNow ?? this.isAvailableNow,
    availableFrom: availableFrom ?? this.availableFrom,
    availableTo: availableTo ?? this.availableTo,
    hasPortfolio: hasPortfolio ?? this.hasPortfolio,
    isVerified: isVerified ?? this.isVerified,
    hasReviews: hasReviews ?? this.hasReviews,
    languages: languages ?? this.languages,
    equipment: equipment ?? this.equipment,
    services: services ?? this.services,
    sortBy: sortBy ?? this.sortBy,
    sortAscending: sortAscending ?? this.sortAscending,
    includeNearbyCities: includeNearbyCities ?? this.includeNearbyCities,
    maxDistance: maxDistance ?? this.maxDistance,
  );

  /// Проверить, применены ли фильтры
  bool get hasFilters =>
      searchQuery.isNotEmpty ||
      categories.isNotEmpty ||
      subcategories.isNotEmpty ||
      selectedCity != null ||
      selectedRegion != null ||
      minPrice > 0 ||
      maxPrice < 100000 ||
      minRating > 0.0 ||
      maxRating < 5.0 ||
      minExperience > 0 ||
      maxExperience < 50 ||
      experienceLevel != null ||
      isAvailableNow ||
      availableFrom != null ||
      availableTo != null ||
      hasPortfolio ||
      isVerified ||
      hasReviews ||
      languages.isNotEmpty ||
      equipment.isNotEmpty ||
      services.isNotEmpty;

  /// Сбросить все фильтры
  AdvancedSearchFilters clear() => const AdvancedSearchFilters();

  /// Получить список городов для поиска
  List<String> get searchCities {
    if (selectedCity == null) return [];

    final cities = [selectedCity!.cityName];

    if (includeNearbyCities && selectedCity!.neighboringCities.isNotEmpty) {
      cities.addAll(selectedCity!.neighboringCities);
    }

    return cities;
  }

  /// Получить радиус поиска в метрах
  double get radiusMeters => radiusKm * 1000;

  /// Проверить, включен ли фильтр по местоположению
  bool get hasLocationFilter => selectedCity != null || selectedRegion != null;

  /// Получить отображаемое название местоположения
  String get locationDisplayName {
    if (selectedCity != null) {
      return selectedCity!.displayName;
    } else if (selectedRegion != null) {
      return selectedRegion!;
    }
    return 'Вся Россия';
  }
}

/// Варианты сортировки для расширенного поиска
enum AdvancedSearchSortBy {
  relevance, // По релевантности
  rating, // По рейтингу
  priceAsc, // По цене (возрастание)
  priceDesc, // По цене (убывание)
  experience, // По опыту
  distance, // По расстоянию
  availability, // По доступности
  reviewsCount, // По количеству отзывов
  popularity, // По популярности
  newest, // По дате регистрации
}

/// Расширение для получения названий сортировки
extension AdvancedSearchSortByExtension on AdvancedSearchSortBy {
  String get displayName {
    switch (this) {
      case AdvancedSearchSortBy.relevance:
        return 'По релевантности';
      case AdvancedSearchSortBy.rating:
        return 'По рейтингу';
      case AdvancedSearchSortBy.priceAsc:
        return 'По цене (дешевые)';
      case AdvancedSearchSortBy.priceDesc:
        return 'По цене (дорогие)';
      case AdvancedSearchSortBy.experience:
        return 'По опыту';
      case AdvancedSearchSortBy.distance:
        return 'По расстоянию';
      case AdvancedSearchSortBy.availability:
        return 'По доступности';
      case AdvancedSearchSortBy.reviewsCount:
        return 'По отзывам';
      case AdvancedSearchSortBy.popularity:
        return 'По популярности';
      case AdvancedSearchSortBy.newest:
        return 'Новые';
    }
  }

  String get icon {
    switch (this) {
      case AdvancedSearchSortBy.relevance:
        return '🎯';
      case AdvancedSearchSortBy.rating:
        return '⭐';
      case AdvancedSearchSortBy.priceAsc:
        return '💰';
      case AdvancedSearchSortBy.priceDesc:
        return '💎';
      case AdvancedSearchSortBy.experience:
        return '🎓';
      case AdvancedSearchSortBy.distance:
        return '📍';
      case AdvancedSearchSortBy.availability:
        return '✅';
      case AdvancedSearchSortBy.reviewsCount:
        return '💬';
      case AdvancedSearchSortBy.popularity:
        return '🔥';
      case AdvancedSearchSortBy.newest:
        return '🆕';
    }
  }
}

/// Результат расширенного поиска специалистов
class AdvancedSearchResult {
  const AdvancedSearchResult({
    required this.specialist,
    required this.relevanceScore,
    this.distance,
    this.city,
    this.region,
    this.matchingCategories = const [],
    this.matchingServices = const [],
    this.availabilityScore = 0.0,
    this.priceScore = 0.0,
    this.ratingScore = 0.0,
    this.experienceScore = 0.0,
  });

  /// Создать из JSON
  factory AdvancedSearchResult.fromJson(Map<String, dynamic> json) => AdvancedSearchResult(
    specialist: Specialist.fromMap(json['specialist'] as Map<String, dynamic>),
    relevanceScore: (json['relevanceScore'] as num).toDouble(),
    distance: (json['distance'] as num?)?.toDouble(),
    city: json['city'] as String?,
    region: json['region'] as String?,
    matchingCategories: (json['matchingCategories'] as List<dynamic>?)?.cast<String>() ?? [],
    matchingServices: (json['matchingServices'] as List<dynamic>?)?.cast<String>() ?? [],
    availabilityScore: (json['availabilityScore'] as num?)?.toDouble() ?? 0.0,
    priceScore: (json['priceScore'] as num?)?.toDouble() ?? 0.0,
    ratingScore: (json['ratingScore'] as num?)?.toDouble() ?? 0.0,
    experienceScore: (json['experienceScore'] as num?)?.toDouble() ?? 0.0,
  );

  final Specialist specialist;
  final double relevanceScore;
  final double? distance;
  final String? city;
  final String? region;
  final List<String> matchingCategories;
  final List<String> matchingServices;
  final double availabilityScore;
  final double priceScore;
  final double ratingScore;
  final double experienceScore;

  /// Преобразовать в JSON
  Map<String, dynamic> toJson() => {
    'specialist': specialist.toMap(),
    'relevanceScore': relevanceScore,
    'distance': distance,
    'city': city,
    'region': region,
    'matchingCategories': matchingCategories,
    'matchingServices': matchingServices,
    'availabilityScore': availabilityScore,
    'priceScore': priceScore,
    'ratingScore': ratingScore,
    'experienceScore': experienceScore,
  };

  /// Получить общий балл релевантности
  double get totalScore =>
      (relevanceScore * 0.4) +
      (ratingScore * 0.2) +
      (availabilityScore * 0.2) +
      (priceScore * 0.1) +
      (experienceScore * 0.1);

  /// Получить отображаемое расстояние
  String get distanceDisplay {
    if (distance == null) return '';

    if (distance! < 1) {
      return '${(distance! * 1000).round()} м';
    } else if (distance! < 10) {
      return '${distance!.toStringAsFixed(1)} км';
    } else {
      return '${distance!.round()} км';
    }
  }

  /// Получить отображаемое местоположение
  String get locationDisplay {
    if (city != null && region != null) {
      return '$city, $region';
    } else if (city != null) {
      return city!;
    } else if (region != null) {
      return region!;
    }
    return specialist.location ?? 'Не указано';
  }
}

/// Состояние расширенного поиска
class AdvancedSearchState {
  const AdvancedSearchState({
    this.results = const [],
    this.isLoading = false,
    this.hasMore = false,
    this.error = '',
    this.filters = const AdvancedSearchFilters(),
    this.totalCount = 0,
    this.searchTime = 0,
    this.suggestedCities = const [],
    this.popularCategories = const [],
  });

  /// Создать из JSON
  factory AdvancedSearchState.fromJson(Map<String, dynamic> json) => AdvancedSearchState(
    results:
        (json['results'] as List<dynamic>?)
            ?.map((e) => AdvancedSearchResult.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    isLoading: json['isLoading'] as bool? ?? false,
    hasMore: json['hasMore'] as bool? ?? false,
    error: json['error'] as String? ?? '',
    filters: json['filters'] != null
        ? AdvancedSearchFilters.fromJson(json['filters'] as Map<String, dynamic>)
        : const AdvancedSearchFilters(),
    totalCount: json['totalCount'] as int? ?? 0,
    searchTime: json['searchTime'] as int? ?? 0,
    suggestedCities:
        (json['suggestedCities'] as List<dynamic>?)
            ?.map((e) => CityRegion.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [],
    popularCategories:
        (json['popularCategories'] as List<dynamic>?)
            ?.map(
              (e) => SpecialistCategory.values.firstWhere(
                (cat) => cat.name == e,
                orElse: () => SpecialistCategory.other,
              ),
            )
            .toList() ??
        [],
  );

  final List<AdvancedSearchResult> results;
  final bool isLoading;
  final bool hasMore;
  final String error;
  final AdvancedSearchFilters filters;
  final int totalCount;
  final int searchTime; // в миллисекундах
  final List<CityRegion> suggestedCities;
  final List<SpecialistCategory> popularCategories;

  /// Преобразовать в JSON
  Map<String, dynamic> toJson() => {
    'results': results.map((e) => e.toJson()).toList(),
    'isLoading': isLoading,
    'hasMore': hasMore,
    'error': error,
    'filters': filters.toJson(),
    'totalCount': totalCount,
    'searchTime': searchTime,
    'suggestedCities': suggestedCities.map((e) => e.toMap()).toList(),
    'popularCategories': popularCategories.map((e) => e.name).toList(),
  };

  /// Копировать с изменениями
  AdvancedSearchState copyWith({
    List<AdvancedSearchResult>? results,
    bool? isLoading,
    bool? hasMore,
    String? error,
    AdvancedSearchFilters? filters,
    int? totalCount,
    int? searchTime,
    List<CityRegion>? suggestedCities,
    List<SpecialistCategory>? popularCategories,
  }) => AdvancedSearchState(
    results: results ?? this.results,
    isLoading: isLoading ?? this.isLoading,
    hasMore: hasMore ?? this.hasMore,
    error: error ?? this.error,
    filters: filters ?? this.filters,
    totalCount: totalCount ?? this.totalCount,
    searchTime: searchTime ?? this.searchTime,
    suggestedCities: suggestedCities ?? this.suggestedCities,
    popularCategories: popularCategories ?? this.popularCategories,
  );
}
