import 'package:equatable/equatable.dart';

/// Search filters for specialists
class SearchFilters extends Equatable {

  const SearchFilters({
    this.query,
    this.city,
    this.specialization,
    this.minRating,
    this.minPrice,
    this.maxPrice,
    this.isAvailable,
    this.services,
    this.sortBy,
    this.sortAscending,
  });

  /// Create empty filters
  factory SearchFilters.empty() {
    return const SearchFilters();
  }

  /// Create filters from map
  factory SearchFilters.fromMap(Map<String, dynamic> map) {
    return SearchFilters(
      query: map['query'] as String?,
      city: map['city'] as String?,
      specialization: map['specialization'] as String?,
      minRating: map['minRating'] as double?,
      minPrice: map['minPrice'] as int?,
      maxPrice: map['maxPrice'] as int?,
      isAvailable: map['isAvailable'] as bool?,
      services:
          map['services'] != null ? List<String>.from(map['services']) : null,
      sortBy: map['sortBy'] as String?,
      sortAscending: map['sortAscending'] as bool?,
    );
  }
  final String? query;
  final String? city;
  final String? specialization;
  final double? minRating;
  final int? minPrice;
  final int? maxPrice;
  final bool? isAvailable;
  final List<String>? services;
  final String? sortBy; // 'rating', 'price', 'name', 'experience'
  final bool? sortAscending;

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'query': query,
      'city': city,
      'specialization': specialization,
      'minRating': minRating,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'isAvailable': isAvailable,
      'services': services,
      'sortBy': sortBy,
      'sortAscending': sortAscending,
    };
  }

  /// Create a copy with updated fields
  SearchFilters copyWith({
    String? query,
    String? city,
    String? specialization,
    double? minRating,
    int? minPrice,
    int? maxPrice,
    bool? isAvailable,
    List<String>? services,
    String? sortBy,
    bool? sortAscending,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      city: city ?? this.city,
      specialization: specialization ?? this.specialization,
      minRating: minRating ?? this.minRating,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      isAvailable: isAvailable ?? this.isAvailable,
      services: services ?? this.services,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  /// Check if filters are empty
  bool get isEmpty {
    return query == null &&
        city == null &&
        specialization == null &&
        minRating == null &&
        minPrice == null &&
        maxPrice == null &&
        isAvailable == null &&
        (services == null || services!.isEmpty) &&
        sortBy == null;
  }

  /// Check if filters have any values
  bool get isNotEmpty => !isEmpty;

  /// Get active filters count
  int get activeFiltersCount {
    var count = 0;
    if (query != null && query!.isNotEmpty) count++;
    if (city != null) count++;
    if (specialization != null) count++;
    if (minRating != null) count++;
    if (minPrice != null) count++;
    if (maxPrice != null) count++;
    if (isAvailable != null) count++;
    if (services != null && services!.isNotEmpty) count++;
    return count;
  }

  /// Clear all filters
  SearchFilters clear() {
    return const SearchFilters();
  }

  @override
  List<Object?> get props => [
        query,
        city,
        specialization,
        minRating,
        minPrice,
        maxPrice,
        isAvailable,
        services,
        sortBy,
        sortAscending,
      ];

  @override
  String toString() {
    return 'SearchFilters(query: $query, city: $city, specialization: $specialization, minRating: $minRating, minPrice: $minPrice, maxPrice: $maxPrice, isAvailable: $isAvailable, services: $services, sortBy: $sortBy, sortAscending: $sortAscending)';
  }
}
