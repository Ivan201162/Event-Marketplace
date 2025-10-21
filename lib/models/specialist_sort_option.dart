/// Specialist sort option enum
enum SpecialistSortOption {
  rating,
  price,
  experience,
  reviews,
  availability,
  distance,
  name,
  createdAt,
}

/// SpecialistSortOption extensions
extension SpecialistSortOptionExtension on SpecialistSortOption {
  /// Get display name for sort option
  String get displayName {
    switch (this) {
      case SpecialistSortOption.rating:
        return 'По рейтингу';
      case SpecialistSortOption.price:
        return 'По цене';
      case SpecialistSortOption.experience:
        return 'По опыту';
      case SpecialistSortOption.reviews:
        return 'По отзывам';
      case SpecialistSortOption.availability:
        return 'По доступности';
      case SpecialistSortOption.distance:
        return 'По расстоянию';
      case SpecialistSortOption.name:
        return 'По имени';
      case SpecialistSortOption.createdAt:
        return 'По дате регистрации';
    }
  }

  /// Get description for sort option
  String get description {
    switch (this) {
      case SpecialistSortOption.rating:
        return 'Сортировка по рейтингу специалиста';
      case SpecialistSortOption.price:
        return 'Сортировка по цене за час';
      case SpecialistSortOption.experience:
        return 'Сортировка по годам опыта';
      case SpecialistSortOption.reviews:
        return 'Сортировка по количеству отзывов';
      case SpecialistSortOption.availability:
        return 'Сортировка по доступности';
      case SpecialistSortOption.distance:
        return 'Сортировка по расстоянию';
      case SpecialistSortOption.name:
        return 'Сортировка по имени';
      case SpecialistSortOption.createdAt:
        return 'Сортировка по дате регистрации';
    }
  }

  /// Get all sort option values
  static List<SpecialistSortOption> get values => SpecialistSortOption.values;
}
