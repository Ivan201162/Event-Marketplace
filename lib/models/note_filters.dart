import 'package:equatable/equatable.dart';

/// Note filters model
class NoteFilters extends Equatable {

  const NoteFilters({
    this.searchQuery,
    this.tags,
    this.dateFrom,
    this.dateTo,
    this.isPinned,
    this.category,
    this.authorId,
  });

  /// Create NoteFilters from Map
  factory NoteFilters.fromMap(Map<String, dynamic> data) {
    return NoteFilters(
      searchQuery: data['searchQuery'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      dateFrom:
          data['dateFrom'] != null ? DateTime.parse(data['dateFrom']) : null,
      dateTo: data['dateTo'] != null ? DateTime.parse(data['dateTo']) : null,
      isPinned: data['isPinned'],
      category: data['category'],
      authorId: data['authorId'],
    );
  }
  final String? searchQuery;
  final List<String>? tags;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final bool? isPinned;
  final String? category;
  final String? authorId;

  /// Convert NoteFilters to Map
  Map<String, dynamic> toMap() {
    return {
      'searchQuery': searchQuery,
      'tags': tags,
      'dateFrom': dateFrom?.toIso8601String(),
      'dateTo': dateTo?.toIso8601String(),
      'isPinned': isPinned,
      'category': category,
      'authorId': authorId,
    };
  }

  /// Create a copy with updated fields
  NoteFilters copyWith({
    String? searchQuery,
    List<String>? tags,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? isPinned,
    String? category,
    String? authorId,
  }) {
    return NoteFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      tags: tags ?? this.tags,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      isPinned: isPinned ?? this.isPinned,
      category: category ?? this.category,
      authorId: authorId ?? this.authorId,
    );
  }

  /// Check if filters are empty
  bool get isEmpty {
    return searchQuery == null &&
        (tags == null || tags!.isEmpty) &&
        dateFrom == null &&
        dateTo == null &&
        isPinned == null &&
        category == null &&
        authorId == null;
  }

  /// Check if filters have any value
  bool get isNotEmpty => !isEmpty;

  @override
  List<Object?> get props =>
      [searchQuery, tags, dateFrom, dateTo, isPinned, category, authorId];

  @override
  String toString() {
    return 'NoteFilters(searchQuery: $searchQuery, tags: $tags, isPinned: $isPinned)';
  }
}
