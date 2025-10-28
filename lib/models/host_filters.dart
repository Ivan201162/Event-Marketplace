import 'package:equatable/equatable.dart';

/// Host filters model
class HostFilters extends Equatable {

  const HostFilters({
    this.searchQuery,
    this.city,
    this.categories,
    this.minRating,
    this.maxRating,
    this.minPrice,
    this.maxPrice,
    this.isAvailable,
    this.isVerified,
    this.experienceLevel,
  });

  /// Create HostFilters from Map
  factory HostFilters.fromMap(Map<String, dynamic> data) {
    return HostFilters(
      searchQuery: data['searchQuery'],
      city: data['city'],
      categories: data['categories'] != null
          ? List<String>.from(data['categories'])
          : null,
      minRating: data['minRating']?.toDouble(),
      maxRating: data['maxRating']?.toDouble(),
      minPrice: data['minPrice'],
      maxPrice: data['maxPrice'],
      isAvailable: data['isAvailable'],
      isVerified: data['isVerified'],
      experienceLevel: data['experienceLevel'],
    );
  }
  final String? searchQuery;
  final String? city;
  final List<String>? categories;
  final double? minRating;
  final double? maxRating;
  final int? minPrice;
  final int? maxPrice;
  final bool? isAvailable;
  final bool? isVerified;
  final String? experienceLevel;

  /// Convert HostFilters to Map
  Map<String, dynamic> toMap() {
    return {
      'searchQuery': searchQuery,
      'city': city,
      'categories': categories,
      'minRating': minRating,
      'maxRating': maxRating,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'isAvailable': isAvailable,
      'isVerified': isVerified,
      'experienceLevel': experienceLevel,
    };
  }

  /// Create a copy with updated fields
  HostFilters copyWith({
    String? searchQuery,
    String? city,
    List<String>? categories,
    double? minRating,
    double? maxRating,
    int? minPrice,
    int? maxPrice,
    bool? isAvailable,
    bool? isVerified,
    String? experienceLevel,
  }) {
    return HostFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      city: city ?? this.city,
      categories: categories ?? this.categories,
      minRating: minRating ?? this.minRating,
      maxRating: maxRating ?? this.maxRating,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      isAvailable: isAvailable ?? this.isAvailable,
      isVerified: isVerified ?? this.isVerified,
      experienceLevel: experienceLevel ?? this.experienceLevel,
    );
  }

  /// Check if filters are empty
  bool get isEmpty {
    return searchQuery == null &&
        city == null &&
        (categories == null || categories!.isEmpty) &&
        minRating == null &&
        maxRating == null &&
        minPrice == null &&
        maxPrice == null &&
        isAvailable == null &&
        isVerified == null &&
        experienceLevel == null;
  }

  /// Check if filters have any value
  bool get isNotEmpty => !isEmpty;

  @override
  List<Object?> get props => [
        searchQuery,
        city,
        categories,
        minRating,
        maxRating,
        minPrice,
        maxPrice,
        isAvailable,
        isVerified,
        experienceLevel,
      ];

  @override
  String toString() {
    return 'HostFilters(searchQuery: $searchQuery, city: $city, categories: $categories)';
  }
}
