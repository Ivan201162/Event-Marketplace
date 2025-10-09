import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Сервис умного поиска с подсказками и автозаполнением
class SmartSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
