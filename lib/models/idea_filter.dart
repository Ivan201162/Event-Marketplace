/// Фильтр для поиска идей
class IdeaFilter {
  const IdeaFilter({
    this.category,
    this.authorId,
    this.tags,
    this.isPublic,
    this.limit,
    this.searchQuery,
  });

  /// Создать фильтр для публичных идей
  factory IdeaFilter.public({int? limit}) => IdeaFilter(isPublic: true, limit: limit);

  /// Создать фильтр по категории
  factory IdeaFilter.byCategory(String category, {int? limit}) =>
      IdeaFilter(category: category, isPublic: true, limit: limit);

  /// Создать фильтр по автору
  factory IdeaFilter.byAuthor(String authorId, {int? limit}) =>
      IdeaFilter(authorId: authorId, limit: limit);

  /// Создать фильтр по тегам
  factory IdeaFilter.byTags(List<String> tags, {int? limit}) =>
      IdeaFilter(tags: tags, isPublic: true, limit: limit);

  /// Создать фильтр для поиска
  factory IdeaFilter.search(String query, {int? limit}) =>
      IdeaFilter(searchQuery: query, isPublic: true, limit: limit);
  final String? category;
  final String? authorId;
  final List<String>? tags;
  final bool? isPublic;
  final int? limit;
  final String? searchQuery;

  /// Создать копию с изменениями
  IdeaFilter copyWith({
    String? category,
    String? authorId,
    List<String>? tags,
    bool? isPublic,
    int? limit,
    String? searchQuery,
  }) => IdeaFilter(
    category: category ?? this.category,
    authorId: authorId ?? this.authorId,
    tags: tags ?? this.tags,
    isPublic: isPublic ?? this.isPublic,
    limit: limit ?? this.limit,
    searchQuery: searchQuery ?? this.searchQuery,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IdeaFilter &&
        other.category == category &&
        other.authorId == authorId &&
        other.tags == tags &&
        other.isPublic == isPublic &&
        other.limit == limit &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode =>
      category.hashCode ^
      authorId.hashCode ^
      tags.hashCode ^
      isPublic.hashCode ^
      limit.hashCode ^
      searchQuery.hashCode;

  @override
  String toString() =>
      'IdeaFilter(category: $category, authorId: $authorId, tags: $tags, isPublic: $isPublic, limit: $limit, searchQuery: $searchQuery)';
}
