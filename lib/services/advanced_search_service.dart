import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:event_marketplace_app/core/feature_flags.dart';
import 'package:event_marketplace_app/models/search_filters.dart';
import 'package:event_marketplace_app/models/specialist.dart';

/// Сервис расширенного поиска специалистов
class AdvancedSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Поиск специалистов с фильтрами
  Future<List<SpecialistSearchResult>> searchSpecialists({
    required SpecialistSearchFilters filters,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    if (!FeatureFlags.searchEnabled) {
      return [];
    }

    try {
      Query<Map<String, dynamic>> query = _firestore.collection('specialists');

      // Фильтр по категориям
      if (filters.categories.isNotEmpty) {
        query = query.where('categories', arrayContainsAny: filters.categories);
      }

      // Фильтр по услугам
      if (filters.services.isNotEmpty) {
        query = query.where('services', arrayContainsAny: filters.services);
      }

      // Фильтр по локации
      if (filters.locations.isNotEmpty) {
        query = query.where('location', whereIn: filters.locations);
      }

      // Фильтр по рейтингу
      if (filters.minRating > 0) {
        query =
            query.where('rating', isGreaterThanOrEqualTo: filters.minRating);
      }
      if (filters.maxRating < 5.0) {
        query = query.where('rating', isLessThanOrEqualTo: filters.maxRating);
      }

      // Фильтр по цене
      if (filters.minPrice > 0) {
        query =
            query.where('priceFrom', isGreaterThanOrEqualTo: filters.minPrice);
      }
      if (filters.maxPrice < 100000) {
        query = query.where('priceFrom', isLessThanOrEqualTo: filters.maxPrice);
      }

      // Фильтр по доступности
      if (filters.isAvailableNow) {
        query = query.where('isAvailable', isEqualTo: true);
      }

      // Фильтр по портфолио
      if (filters.hasPortfolio) {
        query = query.where('hasPortfolio', isEqualTo: true);
      }

      // Фильтр по верификации
      if (filters.isVerified) {
        query = query.where('isVerified', isEqualTo: true);
      }

      // Фильтр по отзывам
      if (filters.hasReviews) {
        query = query.where('reviewCount', isGreaterThan: 0);
      }

      // Сортировка
      switch (filters.sortBy) {
        case SearchSortBy.rating:
          query = query.orderBy('rating', descending: true);
        case SearchSortBy.priceAsc:
          query = query.orderBy('priceFrom', descending: false);
        case SearchSortBy.priceDesc:
          query = query.orderBy('priceFrom', descending: true);
        case SearchSortBy.reviewsCount:
          query = query.orderBy('reviewCount', descending: true);
        case SearchSortBy.availability:
          query = query.orderBy('isAvailable', descending: true);
        default:
          query = query.orderBy('rating', descending: true);
      }

      // Пагинация
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      query = query.limit(limit);

      final snapshot = await query.get();
      final results = <SpecialistSearchResult>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final specialist = Specialist.fromMap(data);

        // Фильтр по текстовому поиску
        if (filters.searchQuery.isNotEmpty) {
          final query = filters.searchQuery.toLowerCase();
          final matchesName = specialist.name.toLowerCase().contains(query);
          final matchesDescription =
              specialist.description?.toLowerCase().contains(query) ?? false;
          final matchesCategories = specialist.categories.any(
            (category) => category.name.toLowerCase().contains(query),
          );

          if (!matchesName && !matchesDescription && !matchesCategories) {
            continue;
          }
        }

        // Фильтр по дате доступности
        if (filters.availableFrom != null || filters.availableTo != null) {
          // TODO(developer): Реализовать проверку доступности по датам
          // Это требует интеграции с календарем специалиста
        }

        results.add(
          SpecialistSearchResult(
            specialistId: doc.id,
            name: specialist.name,
            avatar: specialist.avatar ?? '',
            rating: specialist.rating,
            reviewCount: specialist.reviewCount,
            priceFrom: specialist.hourlyRate ?? specialist.pricePerHour ?? 0.0,
            categories: specialist.categories,
            services: specialist.services,
            location: specialist.location,
            isAvailable: specialist.isAvailable,
            isVerified: specialist.isVerified,
            hasPortfolio: specialist.portfolio.isNotEmpty,
            nextAvailableDate: specialist.lastActiveAt,
          ),
        );
      }

      return results;
    } catch (e) {
      throw Exception('Ошибка поиска специалистов: $e');
    }
  }

  /// Получить популярные категории
  Future<List<String>> getPopularCategories() async {
    try {
      final snapshot = await _firestore.collection('specialists').get();

      final categoryCount = <String, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final categories = List<String>.from(data['categories'] ?? []);

        for (final category in categories) {
          categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        }
      }

      final sortedCategories = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedCategories.take(10).map((e) => e.key).toList();
    } catch (e) {
      return [];
    }
  }

  /// Получить популярные услуги
  Future<List<String>> getPopularServices() async {
    try {
      final snapshot = await _firestore.collection('specialists').get();

      final serviceCount = <String, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final services = List<String>.from(data['services'] ?? []);

        for (final service in services) {
          serviceCount[service] = (serviceCount[service] ?? 0) + 1;
        }
      }

      final sortedServices = serviceCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedServices.take(10).map((e) => e.key).toList();
    } catch (e) {
      return [];
    }
  }

  /// Получить доступные локации
  Future<List<String>> getAvailableLocations() async {
    try {
      final snapshot = await _firestore.collection('specialists').get();

      final locations = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final location = data['location'] as String?;
        if (location != null && location.isNotEmpty) {
          locations.add(location);
        }
      }

      return locations.toList()..sort();
    } catch (e) {
      return [];
    }
  }
}
