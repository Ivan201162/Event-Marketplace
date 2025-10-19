import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/city_region.dart';

/// Сервис для работы с городами и регионами России
class CityRegionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'cities_regions';

  /// Получить все города с фильтрами
  Future<List<CityRegion>> getCities({
    CitySearchFilters filters = const CitySearchFilters(),
    int limit = 100,
  }) async {
    try {
      var query = _firestore.collection(_collectionName).where('isActive', isEqualTo: true);

      // Фильтр по региону
      if (filters.region != null && filters.region!.isNotEmpty) {
        query = query.where('regionName', isEqualTo: filters.region);
      }

      // Фильтр по населению
      if (filters.minPopulation > 0) {
        query = query.where(
          'population',
          isGreaterThanOrEqualTo: filters.minPopulation,
        );
      }
      if (filters.maxPopulation < 10000000) {
        query = query.where(
          'population',
          isLessThanOrEqualTo: filters.maxPopulation,
        );
      }

      // Фильтр по столицам
      if (filters.isCapital != null) {
        query = query.where('isCapital', isEqualTo: filters.isCapital);
      }

      // Фильтр по крупным городам
      if (filters.isMajorCity != null) {
        query = query.where('isMajorCity', isEqualTo: filters.isMajorCity);
      }

      // Фильтр по специалистам
      if (filters.hasSpecialists) {
        query = query.where('totalSpecialists', isGreaterThan: 0);
      }

      // Сортировка
      switch (filters.sortBy) {
        case CitySortBy.population:
          query = query.orderBy('population', descending: !filters.sortAscending);
          break;
        case CitySortBy.name:
          query = query.orderBy('cityName', descending: !filters.sortAscending);
          break;
        case CitySortBy.region:
          query = query.orderBy('regionName', descending: !filters.sortAscending);
          break;
        case CitySortBy.specialistCount:
          query = query.orderBy(
            'totalSpecialists',
            descending: !filters.sortAscending,
          );
          break;
        case CitySortBy.rating:
          query = query.orderBy(
            'avgSpecialistRating',
            descending: !filters.sortAscending,
          );
          break;
        case CitySortBy.priority:
          // Приоритет вычисляется на клиенте
          query = query.orderBy('population', descending: true);
          break;
        case CitySortBy.distance:
          // Расстояние вычисляется на клиенте
          query = query.orderBy('population', descending: true);
          break;
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();
      var cities = querySnapshot.docs.map(CityRegion.fromDocument).toList();

      // Дополнительная фильтрация на клиенте
      cities = _applyClientSideFilters(cities, filters);

      return cities;
    } on Exception {
      // Логирование:'Ошибка получения городов: $e');
      return [];
    }
  }

  /// Поток городов с фильтрами
  Stream<List<CityRegion>> getCitiesStream({
    CitySearchFilters filters = const CitySearchFilters(),
    int limit = 100,
  }) {
    var query = _firestore.collection(_collectionName).where('isActive', isEqualTo: true);

    // Применяем те же фильтры, что и в getCities
    if (filters.region != null && filters.region!.isNotEmpty) {
      query = query.where('regionName', isEqualTo: filters.region);
    }

    if (filters.minPopulation > 0) {
      query = query.where(
        'population',
        isGreaterThanOrEqualTo: filters.minPopulation,
      );
    }
    if (filters.maxPopulation < 10000000) {
      query = query.where('population', isLessThanOrEqualTo: filters.maxPopulation);
    }

    if (filters.isCapital != null) {
      query = query.where('isCapital', isEqualTo: filters.isCapital);
    }

    if (filters.isMajorCity != null) {
      query = query.where('isMajorCity', isEqualTo: filters.isMajorCity);
    }

    if (filters.hasSpecialists) {
      query = query.where('totalSpecialists', isGreaterThan: 0);
    }

    // Сортировка
    switch (filters.sortBy) {
      case CitySortBy.population:
        query = query.orderBy('population', descending: !filters.sortAscending);
        break;
      case CitySortBy.name:
        query = query.orderBy('cityName', descending: !filters.sortAscending);
        break;
      case CitySortBy.region:
        query = query.orderBy('regionName', descending: !filters.sortAscending);
        break;
      case CitySortBy.specialistCount:
        query = query.orderBy(
          'totalSpecialists',
          descending: !filters.sortAscending,
        );
        break;
      case CitySortBy.rating:
        query = query.orderBy(
          'avgSpecialistRating',
          descending: !filters.sortAscending,
        );
        break;
      default:
        query = query.orderBy('population', descending: true);
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      var cities = snapshot.docs.map(CityRegion.fromDocument).toList();

      // Дополнительная фильтрация на клиенте
      cities = _applyClientSideFilters(cities, filters);

      return cities;
    });
  }

  /// Поиск городов по названию
  Future<List<CityRegion>> searchCitiesByName({
    required String query,
    int limit = 20,
  }) async {
    try {
      final cities = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .orderBy('cityName')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(limit)
          .get();

      return cities.docs.map(CityRegion.fromDocument).toList();
    } on Exception {
      // Логирование:'Ошибка поиска городов: $e');
      return [];
    }
  }

  /// Получить город по ID
  Future<CityRegion?> getCityById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();

      if (doc.exists) {
        return CityRegion.fromDocument(doc);
      }
      return null;
    } on Exception {
      // Логирование:'Ошибка получения города по ID: $e');
      return null;
    }
  }

  /// Получить города по региону
  Future<List<CityRegion>> getCitiesByRegion({
    required String regionName,
    int limit = 50,
  }) async {
    try {
      final cities = await _firestore
          .collection(_collectionName)
          .where('regionName', isEqualTo: regionName)
          .where('isActive', isEqualTo: true)
          .orderBy('population', descending: true)
          .limit(limit)
          .get();

      return cities.docs.map(CityRegion.fromDocument).toList();
    } on Exception {
      // Логирование:'Ошибка получения городов по региону: $e');
      return [];
    }
  }

  /// Получить все регионы
  Future<List<String>> getRegions() async {
    try {
      final cities =
          await _firestore.collection(_collectionName).where('isActive', isEqualTo: true).get();

      final regions = cities.docs.map((doc) => doc.data()['regionName'] as String).toSet().toList();

      regions.sort();
      return regions;
    } on Exception {
      // Логирование:'Ошибка получения регионов: $e');
      return [];
    }
  }

  /// Получить популярные города (столицы и крупные)
  Future<List<CityRegion>> getPopularCities({int limit = 20}) async {
    try {
      final cities = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .where('isCapital', isEqualTo: true)
          .orderBy('population', descending: true)
          .limit(limit)
          .get();

      final popularCities = cities.docs.map(CityRegion.fromDocument).toList();

      // Добавляем крупные города, если не хватает
      if (popularCities.length < limit) {
        final majorCities = await _firestore
            .collection(_collectionName)
            .where('isActive', isEqualTo: true)
            .where('isMajorCity', isEqualTo: true)
            .orderBy('population', descending: true)
            .limit(limit - popularCities.length)
            .get();

        final additionalCities = majorCities.docs.map(CityRegion.fromDocument).toList();

        popularCities.addAll(additionalCities);
      }

      return popularCities;
    } on Exception {
      // Логирование:'Ошибка получения популярных городов: $e');
      return [];
    }
  }

  /// Получить ближайшие города к координатам
  Future<List<CityRegion>> getNearbyCities({
    required double latitude,
    required double longitude,
    double radiusKm = 100.0,
    int limit = 20,
  }) async {
    try {
      // Получаем все города (это не оптимально, но для демо)
      final cities =
          await _firestore.collection(_collectionName).where('isActive', isEqualTo: true).get();

      final userCoordinates = Coordinates(
        latitude: latitude,
        longitude: longitude,
      );

      final nearbyCities = cities.docs.map(CityRegion.fromDocument).where((city) {
        final distance = city.coordinates.distanceTo(userCoordinates);
        return distance <= radiusKm;
      }).toList();

      // Сортируем по расстоянию
      nearbyCities.sort((a, b) {
        final distanceA = a.coordinates.distanceTo(userCoordinates);
        final distanceB = b.coordinates.distanceTo(userCoordinates);
        return distanceA.compareTo(distanceB);
      });

      return nearbyCities.take(limit).toList();
    } on Exception {
      // Логирование:'Ошибка получения ближайших городов: $e');
      return [];
    }
  }

  /// Автоопределение местоположения пользователя
  Future<Position?> getCurrentLocation() async {
    try {
      // Проверяем разрешения
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Логирование:'Службы геолокации отключены');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Логирование:'Разрешение на геолокацию отклонено');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Логирование:'Разрешение на геолокацию отклонено навсегда');
        return null;
      }

      // Получаем текущее местоположение
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } on Exception {
      // Логирование:'Ошибка получения местоположения: $e');
      return null;
    }
  }

  /// Получить город по координатам (геокодирование)
  Future<CityRegion?> getCityByCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Используем геокодирование для получения адреса
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final cityName = placemark.locality ?? placemark.administrativeArea;

        if (cityName != null) {
          // Ищем город в нашей базе
          final cities = await searchCitiesByName(query: cityName, limit: 1);
          if (cities.isNotEmpty) {
            return cities.first;
          }
        }
      }

      return null;
    } on Exception {
      // Логирование:'Ошибка геокодирования: $e');
      return null;
    }
  }

  /// Обновить статистику специалистов в городе
  Future<void> updateSpecialistStats({
    required String cityId,
    required int specialistCount,
    required double avgRating,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(cityId).update({
        'totalSpecialists': specialistCount,
        'avgSpecialistRating': avgRating,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception {
      // Логирование:'Ошибка обновления статистики специалистов: $e');
    }
  }

  /// Дополнительная фильтрация на клиенте
  List<CityRegion> _applyClientSideFilters(
    List<CityRegion> cities,
    CitySearchFilters filters,
  ) {
    var filteredCities = cities;

    // Фильтр по текстовому поиску
    if (filters.searchQuery.isNotEmpty) {
      final query = filters.searchQuery.toLowerCase();
      filteredCities = filteredCities
          .where(
            (city) =>
                city.cityName.toLowerCase().contains(query) ||
                city.regionName.toLowerCase().contains(query) ||
                city.searchName.contains(query),
          )
          .toList();
    }

    // Фильтр по размеру города
    if (filters.citySize != null) {
      filteredCities = filteredCities.where((city) => city.citySize == filters.citySize).toList();
    }

    // Фильтр по рейтингу специалистов
    if (filters.minSpecialistRating > 0.0) {
      filteredCities = filteredCities
          .where(
            (city) => city.avgSpecialistRating >= filters.minSpecialistRating,
          )
          .toList();
    }

    // Фильтр по категории специалистов
    if (filters.specialistCategory != null && filters.specialistCategory!.isNotEmpty) {
      filteredCities = filteredCities
          .where(
            (city) => city.specialistCategories.contains(filters.specialistCategory),
          )
          .toList();
    }

    // Сортировка по приоритету
    if (filters.sortBy == CitySortBy.priority) {
      filteredCities.sort((a, b) {
        final priorityA = a.priority;
        final priorityB = b.priority;
        return filters.sortAscending
            ? priorityA.compareTo(priorityB)
            : priorityB.compareTo(priorityA);
      });
    }

    return filteredCities;
  }

  /// Инициализация базовых данных городов России
  Future<void> initializeRussianCities() async {
    try {
      // Проверяем, есть ли уже данные
      final existingCities = await _firestore.collection(_collectionName).limit(1).get();

      if (existingCities.docs.isNotEmpty) {
        // Логирование:'Данные городов уже инициализированы');
        return;
      }

      // Основные города России с координатами
      final cities = [
        // Столицы и крупные города
        {
          'cityName': 'Москва',
          'regionName': 'Московская область',
          'coordinates': {'latitude': 55.7558, 'longitude': 37.6176},
          'population': 12615000,
          'isCapital': true,
          'isMajorCity': true,
          'timeZone': 'Europe/Moscow',
          'area': 2561.5,
          'density': 4925.0,
          'foundedYear': 1147,
          'description': 'Столица России, крупнейший город страны',
          'attractions': [
            'Красная площадь',
            'Кремль',
            'Большой театр',
            'Третьяковская галерея',
          ],
          'transportHubs': [
            'Шереметьево',
            'Домодедово',
            'Внуково',
            'Жуковский',
          ],
          'economicSectors': [
            'финансы',
            'IT',
            'туризм',
            'развлечения',
            'образование',
          ],
          'specialistCategories': [
            'фотограф',
            'видеограф',
            'dj',
            'ведущий',
            'декоратор',
          ],
        },
        {
          'cityName': 'Санкт-Петербург',
          'regionName': 'Ленинградская область',
          'coordinates': {'latitude': 59.9311, 'longitude': 30.3609},
          'population': 5383000,
          'isCapital': false,
          'isMajorCity': true,
          'timeZone': 'Europe/Moscow',
          'area': 1439.0,
          'density': 3741.0,
          'foundedYear': 1703,
          'description': 'Культурная столица России',
          'attractions': [
            'Эрмитаж',
            'Петропавловская крепость',
            'Исаакиевский собор',
            'Мариинский театр',
          ],
          'transportHubs': ['Пулково'],
          'economicSectors': ['туризм', 'культура', 'образование', 'IT'],
          'specialistCategories': [
            'фотограф',
            'видеограф',
            'музыкант',
            'декоратор',
          ],
        },
        {
          'cityName': 'Новосибирск',
          'regionName': 'Новосибирская область',
          'coordinates': {'latitude': 55.0084, 'longitude': 82.9357},
          'population': 1625000,
          'isCapital': false,
          'isMajorCity': true,
          'timeZone': 'Asia/Novosibirsk',
          'area': 502.7,
          'density': 3232.0,
          'foundedYear': 1893,
          'description': 'Столица Сибири',
          'attractions': [
            'Новосибирский зоопарк',
            'Оперный театр',
            'Академгородок',
          ],
          'transportHubs': ['Толмачево'],
          'economicSectors': ['наука', 'образование', 'IT', 'промышленность'],
          'specialistCategories': ['фотограф', 'dj', 'ведущий', 'декоратор'],
        },
        {
          'cityName': 'Екатеринбург',
          'regionName': 'Свердловская область',
          'coordinates': {'latitude': 56.8431, 'longitude': 60.6454},
          'population': 1495000,
          'isCapital': false,
          'isMajorCity': true,
          'timeZone': 'Asia/Yekaterinburg',
          'area': 468.0,
          'density': 3194.0,
          'foundedYear': 1723,
          'description': 'Столица Урала',
          'attractions': [
            'Храм на Крови',
            'Плотина городского пруда',
            'Ельцин Центр',
          ],
          'transportHubs': ['Кольцово'],
          'economicSectors': ['промышленность', 'IT', 'туризм'],
          'specialistCategories': ['фотограф', 'видеограф', 'dj', 'ведущий'],
        },
        {
          'cityName': 'Казань',
          'regionName': 'Республика Татарстан',
          'coordinates': {'latitude': 55.8304, 'longitude': 49.0661},
          'population': 1257000,
          'isCapital': false,
          'isMajorCity': true,
          'timeZone': 'Europe/Moscow',
          'area': 425.3,
          'density': 2955.0,
          'foundedYear': 1005,
          'description': 'Столица Татарстана',
          'attractions': [
            'Казанский Кремль',
            'Мечеть Кул-Шариф',
            'Университет',
          ],
          'transportHubs': ['Казань'],
          'economicSectors': ['образование', 'туризм', 'IT', 'спорт'],
          'specialistCategories': [
            'фотограф',
            'ведущий',
            'декоратор',
            'музыкант',
          ],
        },
        // Добавляем еще несколько крупных городов
        {
          'cityName': 'Нижний Новгород',
          'regionName': 'Нижегородская область',
          'coordinates': {'latitude': 56.2965, 'longitude': 43.9361},
          'population': 1255000,
          'isCapital': false,
          'isMajorCity': true,
          'timeZone': 'Europe/Moscow',
          'area': 410.0,
          'density': 3061.0,
          'foundedYear': 1221,
          'description': 'Крупный промышленный центр',
          'attractions': ['Нижегородский Кремль', 'Чкаловская лестница'],
          'transportHubs': ['Стригино'],
          'economicSectors': ['промышленность', 'автомобилестроение'],
          'specialistCategories': ['фотограф', 'dj', 'ведущий'],
        },
        {
          'cityName': 'Челябинск',
          'regionName': 'Челябинская область',
          'coordinates': {'latitude': 55.1644, 'longitude': 61.4368},
          'population': 1202000,
          'isCapital': false,
          'isMajorCity': true,
          'timeZone': 'Asia/Yekaterinburg',
          'area': 530.0,
          'density': 2268.0,
          'foundedYear': 1736,
          'description': 'Крупный промышленный центр',
          'attractions': ['Площадь Революции', 'Кировка'],
          'transportHubs': ['Баландино'],
          'economicSectors': ['металлургия', 'промышленность'],
          'specialistCategories': ['фотограф', 'dj', 'ведущий'],
        },
        {
          'cityName': 'Омск',
          'regionName': 'Омская область',
          'coordinates': {'latitude': 54.9885, 'longitude': 73.3242},
          'population': 1172000,
          'isCapital': false,
          'isMajorCity': true,
          'timeZone': 'Asia/Omsk',
          'area': 572.9,
          'density': 2046.0,
          'foundedYear': 1716,
          'description': 'Крупный сибирский город',
          'attractions': ['Омская крепость', 'Музыкальный театр'],
          'transportHubs': ['Центральный'],
          'economicSectors': ['промышленность', 'нефтехимия'],
          'specialistCategories': ['фотограф', 'dj', 'ведущий'],
        },
        {
          'cityName': 'Самара',
          'regionName': 'Самарская область',
          'coordinates': {'latitude': 53.2001, 'longitude': 50.1500},
          'population': 1165000,
          'isCapital': false,
          'isMajorCity': true,
          'timeZone': 'Europe/Samara',
          'area': 541.4,
          'density': 2152.0,
          'foundedYear': 1586,
          'description': 'Крупный промышленный центр',
          'attractions': ['Жигулевские ворота', 'Самарская набережная'],
          'transportHubs': ['Курумоч'],
          'economicSectors': ['авиастроение', 'промышленность'],
          'specialistCategories': ['фотограф', 'dj', 'ведущий'],
        },
        {
          'cityName': 'Ростов-на-Дону',
          'regionName': 'Ростовская область',
          'coordinates': {'latitude': 47.2357, 'longitude': 39.7015},
          'population': 1138000,
          'isCapital': false,
          'isMajorCity': true,
          'timeZone': 'Europe/Moscow',
          'area': 348.5,
          'density': 3265.0,
          'foundedYear': 1749,
          'description': 'Столица Юга России',
          'attractions': ['Набережная Дона', 'Большая Садовая'],
          'transportHubs': ['Платов'],
          'economicSectors': ['сельское хозяйство', 'туризм'],
          'specialistCategories': ['фотограф', 'dj', 'ведущий', 'декоратор'],
        },
      ];

      // Добавляем города в Firestore
      final batch = _firestore.batch();
      for (final cityData in cities) {
        final docRef = _firestore.collection(_collectionName).doc();
        batch.set(docRef, {
          ...cityData,
          'isActive': true,
          'avgSpecialistRating': 0.0,
          'totalSpecialists': 0,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      await batch.commit();
      // Логирование:'Инициализированы данные ${cities.length} городов России');
    } on Exception {
      // Логирование:'Ошибка инициализации городов: $e');
    }
  }
}
