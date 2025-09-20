/// Фильтры для поиска специалистов
class SpecialistSearchFilters {
  const SpecialistSearchFilters({
    this.categories = const [],
    this.services = const [],
    this.locations = const [],
    this.minRating = 0.0,
    this.maxRating = 5.0,
    this.minPrice = 0,
    this.maxPrice = 100000,
    this.availableFrom,
    this.availableTo,
    this.isAvailableNow = false,
    this.hasPortfolio = false,
    this.isVerified = false,
    this.hasReviews = false,
    this.searchQuery = '',
    this.sortBy = SearchSortBy.relevance,
  });

  final List<String> categories;
  final List<String> services;
  final List<String> locations;
  final double minRating;
  final double maxRating;
  final int minPrice;
  final int maxPrice;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final bool isAvailableNow;
  final bool hasPortfolio;
  final bool isVerified;
  final bool hasReviews;
  final String searchQuery;
  final SearchSortBy sortBy;

  factory SpecialistSearchFilters.fromJson(Map<String, dynamic> json) =>
      SpecialistSearchFilters(
        categories:
            (json['categories'] as List<dynamic>?)?.cast<String>() ?? [],
        services: (json['services'] as List<dynamic>?)?.cast<String>() ?? [],
        locations: (json['locations'] as List<dynamic>?)?.cast<String>() ?? [],
        minRating: (json['minRating'] as num?)?.toDouble() ?? 0.0,
        maxRating: (json['maxRating'] as num?)?.toDouble() ?? 5.0,
        minPrice: json['minPrice'] as int? ?? 0,
        maxPrice: json['maxPrice'] as int? ?? 100000,
        availableFrom: json['availableFrom'] != null
            ? DateTime.parse(json['availableFrom'] as String)
            : null,
        availableTo: json['availableTo'] != null
            ? DateTime.parse(json['availableTo'] as String)
            : null,
        isAvailableNow: json['isAvailableNow'] as bool? ?? false,
        hasPortfolio: json['hasPortfolio'] as bool? ?? false,
        isVerified: json['isVerified'] as bool? ?? false,
        hasReviews: json['hasReviews'] as bool? ?? false,
        searchQuery: json['searchQuery'] as String? ?? '',
        sortBy: SearchSortBy.values.firstWhere(
          (e) => e.name == json['sortBy'],
          orElse: () => SearchSortBy.relevance,
        ),
      );

  Map<String, dynamic> toJson() => {
        'categories': categories,
        'services': services,
        'locations': locations,
        'minRating': minRating,
        'maxRating': maxRating,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'availableFrom': availableFrom?.toIso8601String(),
        'availableTo': availableTo?.toIso8601String(),
        'isAvailableNow': isAvailableNow,
        'hasPortfolio': hasPortfolio,
        'isVerified': isVerified,
        'hasReviews': hasReviews,
        'searchQuery': searchQuery,
        'sortBy': sortBy.name,
      };
}

/// Варианты сортировки
enum SearchSortBy {
  relevance,
  rating,
  priceAsc,
  priceDesc,
  distance,
  availability,
  reviewsCount,
}

/// Результат поиска специалистов
class SpecialistSearchResult {
  const SpecialistSearchResult({
    required this.specialistId,
    required this.name,
    required this.avatar,
    required this.rating,
    required this.reviewCount,
    required this.priceFrom,
    required this.categories,
    required this.services,
    required this.location,
    required this.isAvailable,
    required this.isVerified,
    required this.hasPortfolio,
    this.nextAvailableDate,
    this.distance,
  });

  final String specialistId;
  final String name;
  final String avatar;
  final double rating;
  final int reviewCount;
  final int priceFrom;
  final List<String> categories;
  final List<String> services;
  final String location;
  final bool isAvailable;
  final bool isVerified;
  final bool hasPortfolio;
  final DateTime? nextAvailableDate;
  final double? distance;

  factory SpecialistSearchResult.fromJson(Map<String, dynamic> json) =>
      SpecialistSearchResult(
        specialistId: json['specialistId'] as String,
        name: json['name'] as String,
        avatar: json['avatar'] as String,
        rating: (json['rating'] as num).toDouble(),
        reviewCount: json['reviewCount'] as int,
        priceFrom: json['priceFrom'] as int,
        categories: (json['categories'] as List<dynamic>).cast<String>(),
        services: (json['services'] as List<dynamic>).cast<String>(),
        location: json['location'] as String,
        isAvailable: json['isAvailable'] as bool,
        isVerified: json['isVerified'] as bool,
        hasPortfolio: json['hasPortfolio'] as bool,
        nextAvailableDate: json['nextAvailableDate'] != null
            ? DateTime.parse(json['nextAvailableDate'] as String)
            : null,
        distance: (json['distance'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'specialistId': specialistId,
        'name': name,
        'avatar': avatar,
        'rating': rating,
        'reviewCount': reviewCount,
        'priceFrom': priceFrom,
        'categories': categories,
        'services': services,
        'location': location,
        'isAvailable': isAvailable,
        'isVerified': isVerified,
        'hasPortfolio': hasPortfolio,
        'nextAvailableDate': nextAvailableDate?.toIso8601String(),
        'distance': distance,
      };
}

/// Состояние поиска
class SearchState {
  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.hasMore = false,
    this.error = '',
    this.filters = const SpecialistSearchFilters(),
    this.totalCount = 0,
  });

  final List<SpecialistSearchResult> results;
  final bool isLoading;
  final bool hasMore;
  final String error;
  final SpecialistSearchFilters filters;
  final int totalCount;

  factory SearchState.fromJson(Map<String, dynamic> json) => SearchState(
        results: (json['results'] as List<dynamic>?)
                ?.map((e) =>
                    SpecialistSearchResult.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        isLoading: json['isLoading'] as bool? ?? false,
        hasMore: json['hasMore'] as bool? ?? false,
        error: json['error'] as String? ?? '',
        filters: json['filters'] != null
            ? SpecialistSearchFilters.fromJson(
                json['filters'] as Map<String, dynamic>)
            : const SpecialistSearchFilters(),
        totalCount: json['totalCount'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'results': results.map((e) => e.toJson()).toList(),
        'isLoading': isLoading,
        'hasMore': hasMore,
        'error': error,
        'filters': filters.toJson(),
        'totalCount': totalCount,
      };
}
