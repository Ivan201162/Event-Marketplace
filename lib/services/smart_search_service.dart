import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Сервис умного поиска с подсказками и автозаполнением
class SmartSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Position? _currentPosition;
  String? _currentCity;

  /// Получить подсказки для поиска
  Future<List<SearchSuggestion>> getSearchSuggestions(String query) async {
    if (query.isEmpty) {
      return _getPopularSuggestions();
    }

    final suggestions = <SearchSuggestion>[];

    try {
      // Поиск по специалистам
      final specialistsQuery = await _firestore
          .collection('specialists')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .limit(5)
          .get();

      for (final doc in specialistsQuery.docs) {
        final data = doc.data();
        suggestions.add(
          SearchSuggestion(
            text: (data['name'] as String?) ?? '',
            type: SuggestionType.specialist,
            icon: Icons.person,
            subtitle: (data['category'] as String?) ?? '',
            data: {'specialistId': doc.id},
          ),
        );
      }

      // Поиск по категориям
      final categories = [
        'Ведущие',
        'DJ',
        'Фотографы',
        'Видеографы',
        'Декораторы',
        'Аниматоры',
        'Музыканты',
        'Танцоры',
        'Клоуны',
        'Фокусники',
        'Певцы',
        'Гитаристы',
      ];

      for (final category in categories) {
        if (category.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(
            SearchSuggestion(
              text: category,
              type: SuggestionType.category,
              icon: Icons.category,
              subtitle: 'Категория специалистов',
              data: {'category': category},
            ),
          );
        }
      }

      // Поиск по городам
      final cities = [
        'Москва',
        'Санкт-Петербург',
        'Казань',
        'Екатеринбург',
        'Новосибирск',
        'Нижний Новгород',
        'Челябинск',
        'Самара',
        'Омск',
        'Ростов-на-Дону',
        'Уфа',
        'Красноярск',
        'Воронеж',
        'Пермь',
        'Волгоград',
      ];

      for (final city in cities) {
        if (city.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(
            SearchSuggestion(
              text: city,
              type: SuggestionType.location,
              icon: Icons.location_on,
              subtitle: 'Город',
              data: {'city': city},
            ),
          );
        }
      }

      // Поиск по услугам
      final services = [
        'Свадьба',
        'Корпоратив',
        'День рождения',
        'Выпускной',
        'Юбилей',
        'Фотосессия',
        'Видеосъемка',
        'Ведущий',
        'DJ',
        'Аниматор',
      ];

      for (final service in services) {
        if (service.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(
            SearchSuggestion(
              text: service,
              type: SuggestionType.service,
              icon: Icons.event,
              subtitle: 'Услуга',
              data: {'service': service},
            ),
          );
        }
      }
    } on Exception catch (e) {
      debugPrint('Ошибка получения подсказок: $e');
    }

    return suggestions.take(10).toList();
  }

  /// Получить популярные подсказки
  List<SearchSuggestion> _getPopularSuggestions() => [
        SearchSuggestion(
          text: 'Ведущие',
          type: SuggestionType.category,
          icon: Icons.category,
          subtitle: 'Популярная категория',
          data: {'category': 'Ведущие'},
        ),
        SearchSuggestion(
          text: 'Фотографы',
          type: SuggestionType.category,
          icon: Icons.category,
          subtitle: 'Популярная категория',
          data: {'category': 'Фотографы'},
        ),
        SearchSuggestion(
          text: 'Москва',
          type: SuggestionType.location,
          icon: Icons.location_on,
          subtitle: 'Популярный город',
          data: {'city': 'Москва'},
        ),
        SearchSuggestion(
          text: 'Свадьба',
          type: SuggestionType.service,
          icon: Icons.event,
          subtitle: 'Популярная услуга',
          data: {'service': 'Свадьба'},
        ),
      ];

  /// Получить специалистов с фильтрами
  Future<List<Map<String, dynamic>>> searchSpecialists({
    String? query,
    String? category,
    String? city,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    DateTime? availableDate,
    SpecialistSortOption? sortBy,
  }) async {
    try {
      Query queryBuilder = _firestore.collection('specialists');

      // Фильтр по категории
      if (category != null && category.isNotEmpty) {
        queryBuilder = queryBuilder.where('category', isEqualTo: category);
      }

      // Фильтр по городу
      if (city != null && city.isNotEmpty) {
        queryBuilder = queryBuilder.where('city', isEqualTo: city);
      }

      // Фильтр по цене
      if (minPrice != null) {
        queryBuilder =
            queryBuilder.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        queryBuilder =
            queryBuilder.where('price', isLessThanOrEqualTo: maxPrice);
      }

      // Фильтр по рейтингу
      if (minRating != null) {
        queryBuilder =
            queryBuilder.where('rating', isGreaterThanOrEqualTo: minRating);
      }

      // Сортировка
      switch (sortBy) {
        case SpecialistSortOption.rating:
          queryBuilder = queryBuilder.orderBy('rating', descending: true);
          break;
        case SpecialistSortOption.price:
          queryBuilder = queryBuilder.orderBy('price', descending: false);
          break;
        case SpecialistSortOption.popularity:
          queryBuilder = queryBuilder.orderBy('views', descending: true);
          break;
        case SpecialistSortOption.distance:
          // TODO(developer): Реализовать сортировку по расстоянию
          queryBuilder = queryBuilder.orderBy('rating', descending: true);
          break;
        default:
          queryBuilder = queryBuilder.orderBy('rating', descending: true);
      }

      final snapshot = await queryBuilder.limit(50).get();
      final specialists = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        data['id'] = doc.id;

        // Фильтр по поисковому запросу
        if (query != null && query.isNotEmpty) {
          final searchLower = query.toLowerCase();
          final name = ((data['name'] as String?) ?? '').toLowerCase();
          final description =
              ((data['description'] as String?) ?? '').toLowerCase();
          final categoryName =
              ((data['category'] as String?) ?? '').toLowerCase();

          if (!name.contains(searchLower) &&
              !description.contains(searchLower) &&
              !categoryName.contains(searchLower)) {
            continue;
          }
        }

        specialists.add(data);
      }

      return specialists;
    } on Exception catch (e) {
      debugPrint('Ошибка поиска специалистов: $e');
      return [];
    }
  }

  /// Получить популярных специалистов недели
  Future<List<Map<String, dynamic>>> getPopularSpecialists() async {
    try {
      final snapshot = await _firestore
          .collection('specialists')
          .orderBy('views', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения популярных специалистов: $e');
      return [];
    }
  }

  /// Сохранить фильтры поиска
  Future<void> saveSearchFilters(Map<String, dynamic> filters) async {
    try {
      // TODO(developer): Реализовать сохранение фильтров в SharedPreferences
      debugPrint('Сохранение фильтров: $filters');
    } on Exception catch (e) {
      debugPrint('Ошибка сохранения фильтров: $e');
    }
  }

  /// Загрузить сохранённые фильтры
  Future<Map<String, dynamic>> loadSearchFilters() async {
    try {
      // TODO(developer): Реализовать загрузку фильтров из SharedPreferences
      return {};
    } on Exception catch (e) {
      debugPrint('Ошибка загрузки фильтров: $e');
      return {};
    }
  }

  /// Получить текущую геолокацию пользователя
  Future<Position?> getCurrentLocation() async {
    try {
      // Проверяем разрешения
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Получаем текущую позицию
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return _currentPosition;
    } catch (e) {
      debugPrint('Ошибка получения геолокации: $e');
      return null;
    }
  }

  /// Получить город по координатам
  Future<String?> getCityFromCoordinates(double lat, double lng) async {
    try {
      // Простая реализация - в реальном приложении используйте Geocoding API
      final cities = {
        'Москва': {'lat': 55.7558, 'lng': 37.6176},
        'Санкт-Петербург': {'lat': 59.9311, 'lng': 30.3609},
        'Новосибирск': {'lat': 55.0084, 'lng': 82.9357},
        'Екатеринбург': {'lat': 56.8431, 'lng': 60.6454},
        'Казань': {'lat': 55.8304, 'lng': 49.0661},
        'Нижний Новгород': {'lat': 56.2965, 'lng': 43.9361},
        'Челябинск': {'lat': 55.1644, 'lng': 61.4368},
        'Самара': {'lat': 53.2001, 'lng': 50.1500},
        'Омск': {'lat': 54.9885, 'lng': 73.3242},
        'Ростов-на-Дону': {'lat': 47.2357, 'lng': 39.7015},
      };

      String? closestCity;
      var minDistance = double.infinity;

      for (final entry in cities.entries) {
        final cityData = entry.value;
        final distance = _calculateDistance(
          lat,
          lng,
          cityData['lat']!,
          cityData['lng']!,
        );

        if (distance < minDistance) {
          minDistance = distance;
          closestCity = entry.key;
        }
      }

      _currentCity = closestCity;
      return closestCity;
    } catch (e) {
      debugPrint('Ошибка определения города: $e');
      return null;
    }
  }

  /// Вычислить расстояние между двумя точками
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) =>
      Geolocator.distanceBetween(lat1, lng1, lat2, lng2);

  /// Получить популярные города для автозаполнения
  Future<List<String>> getPopularCities() async {
    try {
      final query = await _firestore.collection('specialists').limit(100).get();

      final cities = <String>{};
      for (final doc in query.docs) {
        final city = doc.data()['city'] as String?;
        if (city != null && city.isNotEmpty) {
          cities.add(city);
        }
      }

      return cities.toList()..sort();
    } catch (e) {
      debugPrint('Ошибка получения городов: $e');
      return [
        'Москва',
        'Санкт-Петербург',
        'Новосибирск',
        'Екатеринбург',
        'Казань',
        'Нижний Новгород',
        'Челябинск',
        'Самара',
        'Омск',
        'Ростов-на-Дону',
      ];
    }
  }

  /// Получить популярные категории для автозаполнения
  Future<List<String>> getPopularCategories() async {
    try {
      final query = await _firestore.collection('specialists').limit(100).get();

      final categories = <String>{};
      for (final doc in query.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      debugPrint('Ошибка получения категорий: $e');
      return [
        'Ведущие',
        'DJ',
        'Фотографы',
        'Видеографы',
        'Декораторы',
        'Аниматоры',
        'Музыканты',
        'Танцоры',
        'Клоуны',
        'Фокусники',
        'Певцы',
        'Организаторы',
      ];
    }
  }

  /// Получить текущий город пользователя
  String? get currentCity => _currentCity;

  /// Получить текущую позицию пользователя
  Position? get currentPosition => _currentPosition;

  /// Получить популярных специалистов недели
  Future<List<Map<String, dynamic>>> getWeeklyPopularSpecialists() async {
    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      final query = await _firestore
          .collection('specialists')
          .where('isActive', isEqualTo: true)
          .orderBy('viewsCount', descending: true)
          .orderBy('rating', descending: true)
          .limit(10)
          .get();

      final specialists = <Map<String, dynamic>>[];

      for (final doc in query.docs) {
        final data = doc.data();

        // Добавляем дополнительные поля для бейджей
        final specialistData = <String, dynamic>{
          ...data,
          'id': doc.id,
          'reviewsCount': data['reviewsCount'] ?? 0,
          'isVerified': data['isVerified'] ?? false,
          'avgResponseTime': data['avgResponseTime'] ?? 60,
          'isOnline': data['isOnline'] ?? false,
          'hasDiscount': data['hasDiscount'] ?? false,
          'isPremium': data['isPremium'] ?? false,
        };

        specialists.add(specialistData);
      }

      // Если нет данных в Firestore, возвращаем тестовые данные
      if (specialists.isEmpty) {
        return _getTestWeeklyPopularSpecialists();
      }

      return specialists;
    } catch (e) {
      debugPrint('Ошибка получения популярных специалистов: $e');
      return _getTestWeeklyPopularSpecialists();
    }
  }

  /// Тестовые данные для популярных специалистов недели
  List<Map<String, dynamic>> _getTestWeeklyPopularSpecialists() => [
        {
          'id': 'specialist_1',
          'name': 'Анна Петрова',
          'category': 'Фотограф',
          'rating': 4.9,
          'price': 15000,
          'city': 'Москва',
          'avatarUrl': 'https://picsum.photos/200/200?random=1',
          'reviewsCount': 127,
          'isVerified': true,
          'avgResponseTime': 15,
          'isOnline': true,
          'hasDiscount': false,
          'isPremium': true,
          'viewsCount': 1250,
        },
        {
          'id': 'specialist_2',
          'name': 'Дмитрий Смирнов',
          'category': 'DJ',
          'rating': 4.8,
          'price': 25000,
          'city': 'Санкт-Петербург',
          'avatarUrl': 'https://picsum.photos/200/200?random=2',
          'reviewsCount': 89,
          'isVerified': true,
          'avgResponseTime': 25,
          'isOnline': true,
          'hasDiscount': true,
          'isPremium': false,
          'viewsCount': 980,
        },
        {
          'id': 'specialist_3',
          'name': 'Елена Козлова',
          'category': 'Ведущая',
          'rating': 4.7,
          'price': 20000,
          'city': 'Москва',
          'avatarUrl': 'https://picsum.photos/200/200?random=3',
          'reviewsCount': 156,
          'isVerified': true,
          'avgResponseTime': 20,
          'isOnline': false,
          'hasDiscount': false,
          'isPremium': true,
          'viewsCount': 1100,
        },
        {
          'id': 'specialist_4',
          'name': 'Михаил Волков',
          'category': 'Видеограф',
          'rating': 4.6,
          'price': 30000,
          'city': 'Новосибирск',
          'avatarUrl': 'https://picsum.photos/200/200?random=4',
          'reviewsCount': 67,
          'isVerified': false,
          'avgResponseTime': 45,
          'isOnline': true,
          'hasDiscount': false,
          'isPremium': false,
          'viewsCount': 750,
        },
        {
          'id': 'specialist_5',
          'name': 'Ольга Морозова',
          'category': 'Декоратор',
          'rating': 4.5,
          'price': 18000,
          'city': 'Екатеринбург',
          'avatarUrl': 'https://picsum.photos/200/200?random=5',
          'reviewsCount': 43,
          'isVerified': true,
          'avgResponseTime': 30,
          'isOnline': false,
          'hasDiscount': true,
          'isPremium': false,
          'viewsCount': 620,
        },
      ];
}

/// Подсказка для поиска
class SearchSuggestion {
  SearchSuggestion({
    required this.text,
    required this.type,
    required this.icon,
    required this.subtitle,
    required this.data,
  });
  final String text;
  final SuggestionType type;
  final IconData icon;
  final String subtitle;
  final Map<String, dynamic> data;
}

/// Тип подсказки
enum SuggestionType {
  specialist,
  category,
  location,
  service,
}

/// Опции сортировки специалистов
enum SpecialistSortOption {
  rating,
  price,
  popularity,
  distance,
}
