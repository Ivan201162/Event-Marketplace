import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/enhanced_specialist.dart';
import '../models/enhanced_specialist_category.dart';

/// Сервис расширенного поиска специалистов
class EnhancedSearchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Поиск специалистов с расширенными фильтрами
  Future<List<EnhancedSpecialist>> searchSpecialists({
    String? query,
    List<EnhancedSpecialistCategory>? categories,
    String? location,
    double? minPrice,
    double? maxPrice,
    DateTime? availableFrom,
    DateTime? availableTo,
    double? minRating,
    int? minReviews,
    List<String>? languages,
    bool? isVerified,
    bool? isPremium,
    SearchSortOption sortBy = SearchSortOption.relevance,
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      Query<Map<String, dynamic>> queryBuilder = _db.collection('enhanced_specialists');

      // Фильтр по активности
      queryBuilder = queryBuilder.where('isActive', isEqualTo: true);

      // Фильтр по категориям
      if (categories != null && categories.isNotEmpty) {
        queryBuilder = queryBuilder.where('categories', arrayContainsAny: 
            categories.map((cat) => cat.name).toList());
      }

      // Фильтр по местоположению
      if (location != null && location.isNotEmpty) {
        queryBuilder = queryBuilder.where('location', isGreaterThanOrEqualTo: location)
            .where('location', isLessThanOrEqualTo: '$location\uf8ff');
      }

      // Фильтр по рейтингу
      if (minRating != null) {
        queryBuilder = queryBuilder.where('rating', isGreaterThanOrEqualTo: minRating);
      }

      // Фильтр по количеству отзывов
      if (minReviews != null) {
        queryBuilder = queryBuilder.where('reviewsCount', isGreaterThanOrEqualTo: minReviews);
      }

      // Фильтр по верификации
      if (isVerified != null) {
        queryBuilder = queryBuilder.where('isVerified', isEqualTo: isVerified);
      }

      // Фильтр по премиум статусу
      if (isPremium != null) {
        queryBuilder = queryBuilder.where('isPremium', isEqualTo: isPremium);
      }

      // Фильтр по языкам
      if (languages != null && languages.isNotEmpty) {
        queryBuilder = queryBuilder.where('languages', arrayContainsAny: languages);
      }

      // Сортировка
      switch (sortBy) {
        case SearchSortOption.relevance:
          // Для релевантности используем комбинацию рейтинга и количества отзывов
          queryBuilder = queryBuilder.orderBy('rating', descending: true)
              .orderBy('reviewsCount', descending: true);
          break;
        case SearchSortOption.rating:
          queryBuilder = queryBuilder.orderBy('rating', descending: true);
          break;
        case SearchSortOption.priceLow:
          queryBuilder = queryBuilder.orderBy('averageOrderValue', descending: false);
          break;
        case SearchSortOption.priceHigh:
          queryBuilder = queryBuilder.orderBy('averageOrderValue', descending: true);
          break;
        case SearchSortOption.popularity:
          queryBuilder = queryBuilder.orderBy('totalOrders', descending: true);
          break;
        case SearchSortOption.newest:
          queryBuilder = queryBuilder.orderBy('createdAt', descending: true);
          break;
        case SearchSortOption.responseTime:
          queryBuilder = queryBuilder.orderBy('responseTime', descending: false);
          break;
      }

      // Пагинация
      if (lastDocumentId != null) {
        final lastDoc = await _db.collection('enhanced_specialists').doc(lastDocumentId).get();
        if (lastDoc.exists) {
          queryBuilder = queryBuilder.startAfterDocument(lastDoc);
        }
      }

      queryBuilder = queryBuilder.limit(limit);

      final querySnapshot = await queryBuilder.get();
      var specialists = querySnapshot.docs
          .map((doc) => EnhancedSpecialist.fromDocument(doc))
          .toList();

      // Фильтрация по цене (после получения данных, так как Firestore не поддерживает сложные запросы)
      if (minPrice != null || maxPrice != null) {
        specialists = specialists.where((specialist) {
          final specialistMinPrice = specialist.minPrice;
          final specialistMaxPrice = specialist.maxPrice;
          
          if (minPrice != null && specialistMaxPrice < minPrice) return false;
          if (maxPrice != null && specialistMinPrice > maxPrice) return false;
          
          return true;
        }).toList();
      }

      // Фильтрация по доступности
      if (availableFrom != null || availableTo != null) {
        specialists = specialists.where((specialist) {
          if (availableFrom != null && !specialist.isAvailableOn(availableFrom)) return false;
          if (availableTo != null && !specialist.isAvailableOn(availableTo)) return false;
          return true;
        }).toList();
      }

      // Текстовый поиск (если указан запрос)
      if (query != null && query.isNotEmpty) {
        specialists = _filterByTextQuery(specialists, query);
      }

      return specialists;
    } catch (e) {
      debugPrint('Ошибка поиска специалистов: $e');
      return [];
    }
  }

  /// Поиск по текстовому запросу с поддержкой русского языка
  List<EnhancedSpecialist> _filterByTextQuery(List<EnhancedSpecialist> specialists, String query) {
    final normalizedQuery = _normalizeText(query.toLowerCase());
    
    return specialists.where((specialist) {
      // Поиск по имени
      if (_normalizeText(specialist.name.toLowerCase()).contains(normalizedQuery)) {
        return true;
      }

      // Поиск по описанию
      if (specialist.description != null && 
          _normalizeText(specialist.description!.toLowerCase()).contains(normalizedQuery)) {
        return true;
      }

      // Поиск по биографии
      if (specialist.bio != null && 
          _normalizeText(specialist.bio!.toLowerCase()).contains(normalizedQuery)) {
        return true;
      }

      // Поиск по местоположению
      if (_normalizeText(specialist.location.toLowerCase()).contains(normalizedQuery)) {
        return true;
      }

      // Поиск по категориям
      for (final category in specialist.categories) {
        if (_normalizeText(category.name.toLowerCase()).contains(normalizedQuery)) {
          return true;
        }
      }

      // Поиск по услугам
      for (final service in specialist.services) {
        if (_normalizeText(service.name.toLowerCase()).contains(normalizedQuery) ||
            _normalizeText(service.description.toLowerCase()).contains(normalizedQuery)) {
          return true;
        }
      }

      // Поиск по тегам в портфолио
      for (final item in specialist.portfolio) {
        for (final tag in item.tags) {
          if (_normalizeText(tag.toLowerCase()).contains(normalizedQuery)) {
            return true;
          }
        }
      }

      return false;
    }).toList();
  }

  /// Нормализация текста для поиска (удаление диакритических знаков, приведение к базовой форме)
  String _normalizeText(String text) {
    // Удаление диакритических знаков
    final Map<String, String> replacements = {
      'ё': 'е', 'й': 'и', 'ъ': '', 'ь': '', 'ы': 'и',
      'а': 'а', 'б': 'б', 'в': 'в', 'г': 'г', 'д': 'д',
      'е': 'е', 'ж': 'ж', 'з': 'з', 'и': 'и', 'к': 'к',
      'л': 'л', 'м': 'м', 'н': 'н', 'о': 'о', 'п': 'п',
      'р': 'р', 'с': 'с', 'т': 'т', 'у': 'у', 'ф': 'ф',
      'х': 'х', 'ц': 'ц', 'ч': 'ч', 'ш': 'ш', 'щ': 'щ',
      'э': 'э', 'ю': 'ю', 'я': 'я',
    };

    String normalized = text;
    replacements.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    return normalized;
  }

  /// Получить популярные категории
  Future<List<EnhancedSpecialistCategoryModel>> getPopularCategories({int limit = 10}) async {
    try {
      final query = await _db
          .collection('enhanced_categories')
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => EnhancedSpecialistCategoryModel.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Ошибка получения популярных категорий: $e');
      return [];
    }
  }

  /// Получить рекомендуемых специалистов
  Future<List<EnhancedSpecialist>> getRecommendedSpecialists({
    required String userId,
    int limit = 10,
  }) async {
    try {
      // Получаем историю заказов пользователя
      final userOrders = await _getUserOrderHistory(userId);
      
      if (userOrders.isEmpty) {
        // Если нет истории, возвращаем популярных специалистов
        return await _getPopularSpecialists(limit: limit);
      }

      // Анализируем предпочтения пользователя
      final userPreferences = _analyzeUserPreferences(userOrders);
      
      // Ищем специалистов на основе предпочтений
      return await searchSpecialists(
        categories: userPreferences.categories,
        location: userPreferences.preferredLocation,
        minRating: 4.0,
        sortBy: SearchSortOption.relevance,
        limit: limit,
      );
    } catch (e) {
      debugPrint('Ошибка получения рекомендаций: $e');
      return await _getPopularSpecialists(limit: limit);
    }
  }

  /// Получить историю заказов пользователя
  Future<List<Map<String, dynamic>>> _getUserOrderHistory(String userId) async {
    try {
      final query = await _db
          .collection('bookings')
          .where('customerId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return query.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Ошибка получения истории заказов: $e');
      return [];
    }
  }

  /// Анализ предпочтений пользователя
  UserPreferences _analyzeUserPreferences(List<Map<String, dynamic>> orders) {
    final categoryCounts = <EnhancedSpecialistCategory, int>{};
    final locationCounts = <String, int>{};
    final priceRange = <double>[];

    for (final order in orders) {
      // Анализ категорий
      final category = order['category'] as String?;
      if (category != null) {
        final categoryEnum = EnhancedSpecialistCategory.values.firstWhere(
          (cat) => cat.name == category,
          orElse: () => EnhancedSpecialistCategory.photography,
        );
        categoryCounts[categoryEnum] = (categoryCounts[categoryEnum] ?? 0) + 1;
      }

      // Анализ местоположения
      final location = order['location'] as String?;
      if (location != null) {
        locationCounts[location] = (locationCounts[location] ?? 0) + 1;
      }

      // Анализ цен
      final price = (order['totalPrice'] as num?)?.toDouble();
      if (price != null) {
        priceRange.add(price);
      }
    }

    // Определяем предпочитаемые категории (топ-3)
    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final preferredCategories = sortedCategories.take(3).map((e) => e.key).toList();

    // Определяем предпочитаемое местоположение
    final sortedLocations = locationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final preferredLocation = sortedLocations.isNotEmpty ? sortedLocations.first.key : null;

    return UserPreferences(
      categories: preferredCategories,
      preferredLocation: preferredLocation,
      averagePrice: priceRange.isNotEmpty 
          ? priceRange.reduce((a, b) => a + b) / priceRange.length 
          : null,
    );
  }

  /// Получить популярных специалистов
  Future<List<EnhancedSpecialist>> _getPopularSpecialists({int limit = 10}) async {
    try {
      return await searchSpecialists(
        sortBy: SearchSortOption.popularity,
        limit: limit,
      );
    } catch (e) {
      debugPrint('Ошибка получения популярных специалистов: $e');
      return [];
    }
  }

  /// Получить похожих специалистов
  Future<List<EnhancedSpecialist>> getSimilarSpecialists({
    required String specialistId,
    int limit = 5,
  }) async {
    try {
      // Получаем информацию о специалисте
      final specialistDoc = await _db.collection('enhanced_specialists').doc(specialistId).get();
      if (!specialistDoc.exists) return [];

      final specialist = EnhancedSpecialist.fromDocument(specialistDoc);

      // Ищем специалистов с похожими категориями
      return await searchSpecialists(
        categories: specialist.categories,
        location: specialist.location,
        minRating: specialist.rating - 0.5,
        sortBy: SearchSortOption.relevance,
        limit: limit + 1, // +1 чтобы исключить самого специалиста
      ).then((specialists) => 
          specialists.where((s) => s.id != specialistId).take(limit).toList());
    } catch (e) {
      debugPrint('Ошибка получения похожих специалистов: $e');
      return [];
    }
  }

  /// Получить статистику поиска
  Future<SearchStatistics> getSearchStatistics() async {
    try {
      final specialistsQuery = await _db.collection('enhanced_specialists').get();
      final categoriesQuery = await _db.collection('enhanced_categories').get();

      final totalSpecialists = specialistsQuery.docs.length;
      final totalCategories = categoriesQuery.docs.length;
      final activeSpecialists = specialistsQuery.docs
          .where((doc) => doc.data()['isActive'] == true)
          .length;

      return SearchStatistics(
        totalSpecialists: totalSpecialists,
        activeSpecialists: activeSpecialists,
        totalCategories: totalCategories,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Ошибка получения статистики поиска: $e');
      return SearchStatistics(
        totalSpecialists: 0,
        activeSpecialists: 0,
        totalCategories: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }
}

/// Опции сортировки
enum SearchSortOption {
  relevance,      // Релевантность
  rating,         // Рейтинг
  priceLow,       // Цена (по возрастанию)
  priceHigh,      // Цена (по убыванию)
  popularity,     // Популярность
  newest,         // Новые
  responseTime,   // Время отклика
}

/// Предпочтения пользователя
class UserPreferences {
  const UserPreferences({
    required this.categories,
    this.preferredLocation,
    this.averagePrice,
  });

  final List<EnhancedSpecialistCategory> categories;
  final String? preferredLocation;
  final double? averagePrice;
}

/// Статистика поиска
class SearchStatistics {
  const SearchStatistics({
    required this.totalSpecialists,
    required this.activeSpecialists,
    required this.totalCategories,
    required this.lastUpdated,
  });

  final int totalSpecialists;
  final int activeSpecialists;
  final int totalCategories;
  final DateTime lastUpdated;
}
