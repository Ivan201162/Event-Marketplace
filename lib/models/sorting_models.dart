/// Тип сортировки специалистов
enum SortBy { rating, price, distance, availability, experience, reviews, popularity, newest, name }

/// Порядок сортировки
enum SortOrder { ascending, descending }

/// Расширение для SortBy
extension SortByExtension on SortBy {
  /// Получить название типа сортировки
  String get displayName {
    switch (this) {
      case SortBy.rating:
        return 'По рейтингу';
      case SortBy.price:
        return 'По цене';
      case SortBy.distance:
        return 'По расстоянию';
      case SortBy.availability:
        return 'По доступности';
      case SortBy.experience:
        return 'По опыту';
      case SortBy.reviews:
        return 'По отзывам';
      case SortBy.popularity:
        return 'По популярности';
      case SortBy.newest:
        return 'По новизне';
      case SortBy.name:
        return 'По имени';
    }
  }

  /// Получить иконку типа сортировки
  String get icon {
    switch (this) {
      case SortBy.rating:
        return '⭐';
      case SortBy.price:
        return '💰';
      case SortBy.distance:
        return '📍';
      case SortBy.availability:
        return '✅';
      case SortBy.experience:
        return '🎯';
      case SortBy.reviews:
        return '💬';
      case SortBy.popularity:
        return '🔥';
      case SortBy.newest:
        return '🆕';
      case SortBy.name:
        return '🔤';
    }
  }
}

/// Расширение для SortOrder
extension SortOrderExtension on SortOrder {
  /// Получить название порядка сортировки
  String get displayName {
    switch (this) {
      case SortOrder.ascending:
        return 'По возрастанию';
      case SortOrder.descending:
        return 'По убыванию';
    }
  }

  /// Получить иконку порядка сортировки
  String get icon {
    switch (this) {
      case SortOrder.ascending:
        return '⬆️';
      case SortOrder.descending:
        return '⬇️';
    }
  }
}

/// Модель настроек сортировки
class SortingSettings {
  const SortingSettings({
    this.sortBy = SortBy.rating,
    this.sortOrder = SortOrder.descending,
    this.isCustom = false,
  });

  final SortBy sortBy;
  final SortOrder sortOrder;
  final bool isCustom;

  /// Создать из Map
  factory SortingSettings.fromMap(Map<String, dynamic> data) {
    return SortingSettings(
      sortBy: _parseSortBy(data['sortBy']),
      sortOrder: _parseSortOrder(data['sortOrder']),
      isCustom: data['isCustom'] as bool? ?? false,
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
    'sortBy': sortBy.name,
    'sortOrder': sortOrder.name,
    'isCustom': isCustom,
  };

  /// Копировать с изменениями
  SortingSettings copyWith({SortBy? sortBy, SortOrder? sortOrder, bool? isCustom}) =>
      SortingSettings(
        sortBy: sortBy ?? this.sortBy,
        sortOrder: sortOrder ?? this.sortOrder,
        isCustom: isCustom ?? this.isCustom,
      );

  /// Парсинг типа сортировки из строки
  static SortBy _parseSortBy(String? sortBy) {
    switch (sortBy) {
      case 'rating':
        return SortBy.rating;
      case 'price':
        return SortBy.price;
      case 'distance':
        return SortBy.distance;
      case 'availability':
        return SortBy.availability;
      case 'experience':
        return SortBy.experience;
      case 'reviews':
        return SortBy.reviews;
      case 'popularity':
        return SortBy.popularity;
      case 'newest':
        return SortBy.newest;
      case 'name':
        return SortBy.name;
      default:
        return SortBy.rating;
    }
  }

  /// Парсинг порядка сортировки из строки
  static SortOrder _parseSortOrder(String? sortOrder) {
    switch (sortOrder) {
      case 'ascending':
        return SortOrder.ascending;
      case 'descending':
        return SortOrder.descending;
      default:
        return SortOrder.descending;
    }
  }

  /// Получить отображаемое название настроек сортировки
  String get displayName {
    return '${sortBy.displayName} (${sortOrder.displayName})';
  }

  /// Проверить, является ли сортировка по умолчанию
  bool get isDefault {
    return sortBy == SortBy.rating && sortOrder == SortOrder.descending && !isCustom;
  }
}
