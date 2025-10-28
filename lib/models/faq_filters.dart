import 'package:equatable/equatable.dart';

/// FAQ filters model
class FAQFilters extends Equatable {

  const FAQFilters({
    this.category,
    this.searchQuery,
    this.isPublished,
    this.dateFrom,
    this.dateTo,
    this.tags,
    this.language,
  });

  /// Create FAQFilters from Map
  factory FAQFilters.fromMap(Map<String, dynamic> data) {
    return FAQFilters(
      category: data['category'],
      searchQuery: data['searchQuery'],
      isPublished: data['isPublished'],
      dateFrom:
          data['dateFrom'] != null ? DateTime.parse(data['dateFrom']) : null,
      dateTo: data['dateTo'] != null ? DateTime.parse(data['dateTo']) : null,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      language: data['language'],
    );
  }
  final String? category;
  final String? searchQuery;
  final bool? isPublished;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final List<String>? tags;
  final String? language;

  /// Convert FAQFilters to Map
  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'searchQuery': searchQuery,
      'isPublished': isPublished,
      'dateFrom': dateFrom?.toIso8601String(),
      'dateTo': dateTo?.toIso8601String(),
      'tags': tags,
      'language': language,
    };
  }

  /// Create a copy with updated fields
  FAQFilters copyWith({
    String? category,
    String? searchQuery,
    bool? isPublished,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? tags,
    String? language,
  }) {
    return FAQFilters(
      category: category ?? this.category,
      searchQuery: searchQuery ?? this.searchQuery,
      isPublished: isPublished ?? this.isPublished,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      tags: tags ?? this.tags,
      language: language ?? this.language,
    );
  }

  /// Check if filters are empty
  bool get isEmpty {
    return category == null &&
        searchQuery == null &&
        isPublished == null &&
        dateFrom == null &&
        dateTo == null &&
        (tags == null || tags!.isEmpty) &&
        language == null;
  }

  /// Check if filters have any value
  bool get isNotEmpty => !isEmpty;

  @override
  List<Object?> get props =>
      [category, searchQuery, isPublished, dateFrom, dateTo, tags, language];

  @override
  String toString() {
    return 'FAQFilters(category: $category, searchQuery: $searchQuery, isPublished: $isPublished)';
  }
}
