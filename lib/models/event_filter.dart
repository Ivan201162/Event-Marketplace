import 'event.dart';

/// Модель фильтра для поиска событий
class EventFilter {
  const EventFilter({
    this.searchQuery,
    this.categories,
    this.minPrice,
    this.maxPrice,
    this.startDate,
    this.endDate,
    this.isPublic,
    this.status,
    this.organizerId,
  });
  final String? searchQuery;
  final List<EventCategory>? categories;
  final double? minPrice;
  final double? maxPrice;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isPublic;
  final EventStatus? status;
  final String? organizerId;

  /// Создать копию с изменениями
  EventFilter copyWith({
    String? searchQuery,
    List<EventCategory>? categories,
    double? minPrice,
    double? maxPrice,
    DateTime? startDate,
    DateTime? endDate,
    bool? isPublic,
    EventStatus? status,
    String? organizerId,
  }) => EventFilter(
    searchQuery: searchQuery ?? this.searchQuery,
    categories: categories ?? this.categories,
    minPrice: minPrice ?? this.minPrice,
    maxPrice: maxPrice ?? this.maxPrice,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    isPublic: isPublic ?? this.isPublic,
    status: status ?? this.status,
    organizerId: organizerId ?? this.organizerId,
  );

  /// Проверить, есть ли активные фильтры
  bool get hasActiveFilters =>
      searchQuery != null ||
      (categories != null && categories!.isNotEmpty) ||
      minPrice != null ||
      maxPrice != null ||
      startDate != null ||
      endDate != null ||
      isPublic != null ||
      status != null ||
      organizerId != null;

  /// Проверить, соответствует ли событие фильтру
  bool matches(Event event) {
    // Поиск по тексту
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      if (!event.title.toLowerCase().contains(query) &&
          !event.description.toLowerCase().contains(query) &&
          !event.location.toLowerCase().contains(query)) {
        return false;
      }
    }

    // Фильтр по категории
    if (categories != null && categories!.isNotEmpty) {
      if (!categories!.contains(event.category)) {
        return false;
      }
    }

    // Фильтр по цене
    if (minPrice != null && event.price < minPrice!) {
      return false;
    }
    if (maxPrice != null && event.price > maxPrice!) {
      return false;
    }

    // Фильтр по дате
    if (startDate != null && event.date.isBefore(startDate!)) {
      return false;
    }
    if (endDate != null && event.date.isAfter(endDate!)) {
      return false;
    }

    // Фильтр по публичности
    if (isPublic != null && event.isPublic != isPublic!) {
      return false;
    }

    // Фильтр по статусу
    if (status != null && event.status != status!) {
      return false;
    }

    // Фильтр по организатору
    if (organizerId != null && event.organizerId != organizerId!) {
      return false;
    }

    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventFilter &&
        other.searchQuery == searchQuery &&
        _listEquals(other.categories, categories) &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.isPublic == isPublic &&
        other.status == status &&
        other.organizerId == organizerId;
  }

  @override
  int get hashCode => Object.hash(
    searchQuery,
    categories,
    minPrice,
    maxPrice,
    startDate,
    endDate,
    isPublic,
    status,
    organizerId,
  );

  /// Сравнить два списка на равенство
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (var index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
