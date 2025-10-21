import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель города/региона для поиска специалистов по России
class CityRegion {
  const CityRegion({
    required this.id,
    required this.cityName,
    required this.regionName,
    required this.coordinates,
    required this.population,
    this.isCapital = false,
    this.isMajorCity = false,
    this.timeZone = 'Europe/Moscow',
    this.postalCode,
    this.area,
    this.density,
    this.foundedYear,
    this.description,
    this.attractions = const [],
    this.neighboringCities = const [],
    this.transportHubs = const [],
    this.economicSectors = const [],
    this.specialistCategories = const [],
    this.avgSpecialistRating = 0.0,
    this.totalSpecialists = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать из документа Firestore
  factory CityRegion.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return CityRegion(
      id: doc.id,
      cityName: data['cityName'] as String? ?? '',
      regionName: data['regionName'] as String? ?? '',
      coordinates: data['coordinates'] != null
          ? Coordinates.fromMap(data['coordinates'] as Map<String, dynamic>)
          : const Coordinates(latitude: 0, longitude: 0),
      population: data['population'] as int? ?? 0,
      isCapital: data['isCapital'] as bool? ?? false,
      isMajorCity: data['isMajorCity'] as bool? ?? false,
      timeZone: data['timeZone'] as String? ?? 'Europe/Moscow',
      postalCode: data['postalCode'] as String?,
      area: (data['area'] as num?)?.toDouble(),
      density: (data['density'] as num?)?.toDouble(),
      foundedYear: data['foundedYear'] as int?,
      description: data['description'] as String?,
      attractions: List<String>.from((data['attractions'] as List<dynamic>?) ?? []),
      neighboringCities: List<String>.from((data['neighboringCities'] as List<dynamic>?) ?? []),
      transportHubs: List<String>.from((data['transportHubs'] as List<dynamic>?) ?? []),
      economicSectors: List<String>.from((data['economicSectors'] as List<dynamic>?) ?? []),
      specialistCategories: List<String>.from(
        (data['specialistCategories'] as List<dynamic>?) ?? [],
      ),
      avgSpecialistRating: (data['avgSpecialistRating'] as num?)?.toDouble() ?? 0.0,
      totalSpecialists: data['totalSpecialists'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Создать из Map
  factory CityRegion.fromMap(Map<String, dynamic> data) => CityRegion(
    id: data['id'] as String? ?? '',
    cityName: data['cityName'] as String? ?? '',
    regionName: data['regionName'] as String? ?? '',
    coordinates: data['coordinates'] != null
        ? Coordinates.fromMap(data['coordinates'] as Map<String, dynamic>)
        : const Coordinates(latitude: 0, longitude: 0),
    population: data['population'] as int? ?? 0,
    isCapital: data['isCapital'] as bool? ?? false,
    isMajorCity: data['isMajorCity'] as bool? ?? false,
    timeZone: data['timeZone'] as String? ?? 'Europe/Moscow',
    postalCode: data['postalCode'] as String?,
    area: (data['area'] as num?)?.toDouble(),
    density: (data['density'] as num?)?.toDouble(),
    foundedYear: data['foundedYear'] as int?,
    description: data['description'] as String?,
    attractions: List<String>.from((data['attractions'] as List<dynamic>?) ?? []),
    neighboringCities: List<String>.from((data['neighboringCities'] as List<dynamic>?) ?? []),
    transportHubs: List<String>.from((data['transportHubs'] as List<dynamic>?) ?? []),
    economicSectors: List<String>.from((data['economicSectors'] as List<dynamic>?) ?? []),
    specialistCategories: List<String>.from((data['specialistCategories'] as List<dynamic>?) ?? []),
    avgSpecialistRating: (data['avgSpecialistRating'] as num?)?.toDouble() ?? 0.0,
    totalSpecialists: data['totalSpecialists'] as int? ?? 0,
    isActive: data['isActive'] as bool? ?? true,
    createdAt: data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
    updatedAt: data['updatedAt'] != null
        ? (data['updatedAt'] as Timestamp).toDate()
        : DateTime.now(),
  );

  final String id;
  final String cityName;
  final String regionName;
  final Coordinates coordinates;
  final int population;
  final bool isCapital;
  final bool isMajorCity;
  final String timeZone;
  final String? postalCode;
  final double? area; // в км²
  final double? density; // человек на км²
  final int? foundedYear;
  final String? description;
  final List<String> attractions;
  final List<String> neighboringCities;
  final List<String> transportHubs;
  final List<String> economicSectors;
  final List<String> specialistCategories;
  final double avgSpecialistRating;
  final int totalSpecialists;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'cityName': cityName,
    'regionName': regionName,
    'coordinates': coordinates.toMap(),
    'population': population,
    'isCapital': isCapital,
    'isMajorCity': isMajorCity,
    'timeZone': timeZone,
    'postalCode': postalCode,
    'area': area,
    'density': density,
    'foundedYear': foundedYear,
    'description': description,
    'attractions': attractions,
    'neighboringCities': neighboringCities,
    'transportHubs': transportHubs,
    'economicSectors': economicSectors,
    'specialistCategories': specialistCategories,
    'avgSpecialistRating': avgSpecialistRating,
    'totalSpecialists': totalSpecialists,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  /// Копировать с изменениями
  CityRegion copyWith({
    String? id,
    String? cityName,
    String? regionName,
    Coordinates? coordinates,
    int? population,
    bool? isCapital,
    bool? isMajorCity,
    String? timeZone,
    String? postalCode,
    double? area,
    double? density,
    int? foundedYear,
    String? description,
    List<String>? attractions,
    List<String>? neighboringCities,
    List<String>? transportHubs,
    List<String>? economicSectors,
    List<String>? specialistCategories,
    double? avgSpecialistRating,
    int? totalSpecialists,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CityRegion(
    id: id ?? this.id,
    cityName: cityName ?? this.cityName,
    regionName: regionName ?? this.regionName,
    coordinates: coordinates ?? this.coordinates,
    population: population ?? this.population,
    isCapital: isCapital ?? this.isCapital,
    isMajorCity: isMajorCity ?? this.isMajorCity,
    timeZone: timeZone ?? this.timeZone,
    postalCode: postalCode ?? this.postalCode,
    area: area ?? this.area,
    density: density ?? this.density,
    foundedYear: foundedYear ?? this.foundedYear,
    description: description ?? this.description,
    attractions: attractions ?? this.attractions,
    neighboringCities: neighboringCities ?? this.neighboringCities,
    transportHubs: transportHubs ?? this.transportHubs,
    economicSectors: economicSectors ?? this.economicSectors,
    specialistCategories: specialistCategories ?? this.specialistCategories,
    avgSpecialistRating: avgSpecialistRating ?? this.avgSpecialistRating,
    totalSpecialists: totalSpecialists ?? this.totalSpecialists,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Получить отображаемое название города с регионом
  String get displayName => '$cityName, $regionName';

  /// Получить краткое название для поиска
  String get searchName => cityName.toLowerCase();

  /// Получить приоритет для сортировки (столицы и крупные города выше)
  int get priority {
    if (isCapital) return 1;
    if (isMajorCity) return 2;
    if (population > 1000000) return 3;
    if (population > 500000) return 4;
    if (population > 100000) return 5;
    return 6;
  }

  /// Получить размер города по населению
  CitySize get citySize {
    if (population > 1000000) return CitySize.megapolis;
    if (population > 500000) return CitySize.large;
    if (population > 100000) return CitySize.medium;
    if (population > 50000) return CitySize.small;
    return CitySize.town;
  }

  /// Проверить, является ли город популярным для событий
  bool get isPopularForEvents =>
      isCapital ||
      isMajorCity ||
      population > 500000 ||
      attractions.isNotEmpty ||
      economicSectors.contains('туризм') ||
      economicSectors.contains('развлечения');

  /// Получить расстояние до другого города (приблизительно)
  double distanceTo(CityRegion other) => coordinates.distanceTo(other.coordinates);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CityRegion && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CityRegion(id: $id, cityName: $cityName, regionName: $regionName)';
}

/// Координаты города
class Coordinates {
  const Coordinates({required this.latitude, required this.longitude, this.altitude});

  factory Coordinates.fromMap(Map<String, dynamic> map) => Coordinates(
    latitude: (map['latitude'] as num).toDouble(),
    longitude: (map['longitude'] as num).toDouble(),
    altitude: (map['altitude'] as num?)?.toDouble(),
  );

  final double latitude;
  final double longitude;
  final double? altitude;

  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
  };

  /// Вычислить расстояние до другой точки (в километрах)
  double distanceTo(Coordinates other) {
    const double earthRadius = 6371; // Радиус Земли в км

    final lat1Rad = latitude * (3.14159265359 / 180);
    final lat2Rad = other.latitude * (3.14159265359 / 180);
    final deltaLatRad = (other.latitude - latitude) * (3.14159265359 / 180);
    final deltaLonRad = (other.longitude - longitude) * (3.14159265359 / 180);

    final a =
        math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLonRad / 2) *
            math.sin(deltaLonRad / 2);
    final c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  @override
  String toString() => 'Coordinates(lat: $latitude, lng: $longitude)';
}

/// Размер города
enum CitySize {
  megapolis, // Мегаполис (>1M)
  large, // Крупный город (500K-1M)
  medium, // Средний город (100K-500K)
  small, // Малый город (50K-100K)
  town, // Городок (<50K)
}

/// Расширение для получения названий размеров городов
extension CitySizeExtension on CitySize {
  String get displayName {
    switch (this) {
      case CitySize.megapolis:
        return 'Мегаполис';
      case CitySize.large:
        return 'Крупный город';
      case CitySize.medium:
        return 'Средний город';
      case CitySize.small:
        return 'Малый город';
      case CitySize.town:
        return 'Городок';
    }
  }

  String get icon {
    switch (this) {
      case CitySize.megapolis:
        return '🏙️';
      case CitySize.large:
        return '🏢';
      case CitySize.medium:
        return '🏘️';
      case CitySize.small:
        return '🏘️';
      case CitySize.town:
        return '🏘️';
    }
  }
}

/// Фильтры для поиска городов
class CitySearchFilters {
  const CitySearchFilters({
    this.searchQuery = '',
    this.region,
    this.minPopulation = 0,
    this.maxPopulation = 10000000,
    this.isCapital,
    this.isMajorCity,
    this.citySize,
    this.hasSpecialists = false,
    this.minSpecialistRating = 0.0,
    this.specialistCategory,
    this.sortBy = CitySortBy.population,
    this.sortAscending = false,
  });

  final String searchQuery;
  final String? region;
  final int minPopulation;
  final int maxPopulation;
  final bool? isCapital;
  final bool? isMajorCity;
  final CitySize? citySize;
  final bool hasSpecialists;
  final double minSpecialistRating;
  final String? specialistCategory;
  final CitySortBy sortBy;
  final bool sortAscending;

  /// Копировать с изменениями
  CitySearchFilters copyWith({
    String? searchQuery,
    String? region,
    int? minPopulation,
    int? maxPopulation,
    bool? isCapital,
    bool? isMajorCity,
    CitySize? citySize,
    bool? hasSpecialists,
    double? minSpecialistRating,
    String? specialistCategory,
    CitySortBy? sortBy,
    bool? sortAscending,
  }) => CitySearchFilters(
    searchQuery: searchQuery ?? this.searchQuery,
    region: region ?? this.region,
    minPopulation: minPopulation ?? this.minPopulation,
    maxPopulation: maxPopulation ?? this.maxPopulation,
    isCapital: isCapital ?? this.isCapital,
    isMajorCity: isMajorCity ?? this.isMajorCity,
    citySize: citySize ?? this.citySize,
    hasSpecialists: hasSpecialists ?? this.hasSpecialists,
    minSpecialistRating: minSpecialistRating ?? this.minSpecialistRating,
    specialistCategory: specialistCategory ?? this.specialistCategory,
    sortBy: sortBy ?? this.sortBy,
    sortAscending: sortAscending ?? this.sortAscending,
  );

  /// Проверить, применены ли фильтры
  bool get hasFilters =>
      searchQuery.isNotEmpty ||
      region != null ||
      minPopulation > 0 ||
      maxPopulation < 10000000 ||
      isCapital != null ||
      isMajorCity != null ||
      citySize != null ||
      hasSpecialists ||
      minSpecialistRating > 0.0 ||
      specialistCategory != null;

  /// Сбросить все фильтры
  CitySearchFilters clear() => const CitySearchFilters();
}

/// Варианты сортировки городов
enum CitySortBy {
  population, // По населению
  name, // По названию
  region, // По региону
  specialistCount, // По количеству специалистов
  rating, // По рейтингу специалистов
  distance, // По расстоянию
  priority, // По приоритету
}

/// Расширение для получения названий сортировки
extension CitySortByExtension on CitySortBy {
  String get displayName {
    switch (this) {
      case CitySortBy.population:
        return 'По населению';
      case CitySortBy.name:
        return 'По названию';
      case CitySortBy.region:
        return 'По региону';
      case CitySortBy.specialistCount:
        return 'По количеству специалистов';
      case CitySortBy.rating:
        return 'По рейтингу';
      case CitySortBy.distance:
        return 'По расстоянию';
      case CitySortBy.priority:
        return 'По приоритету';
    }
  }
}
