import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/specialist.dart';
import 'cache_service.dart';
import 'debounce_service.dart';

/// Сервис для работы с специалистами
class SpecialistService {
  factory SpecialistService() => _instance;
  SpecialistService._internal();
  static final SpecialistService _instance = SpecialistService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'specialists';
  final CacheService _cacheService = CacheService();
  final DebounceService _debounceService = DebounceService();

  /// Получить всех специалистов с кэшированием
  Future<List<Specialist>> getAllSpecialists({bool useCache = true}) async {
    try {
      // Проверяем кэш, если он актуален
      if (useCache && _cacheService.isSpecialistsCacheValid()) {
        final cachedData = _cacheService.getCachedSpecialists();
        if (cachedData != null) {
          return cachedData.map(Specialist.fromMap).toList();
        }
      }

      // Загружаем из Firestore
      final snapshot = await _firestore.collection(_collection).get();
      final specialists = snapshot.docs.map(Specialist.fromDocument).toList();

      // Кэшируем результат
      if (useCache) {
        final dataToCache = specialists.map((s) => s.toMap()).toList();
        await _cacheService.cacheSpecialists(dataToCache);
      }

      return specialists;
    } on Exception catch (e) {
      debugPrint('Ошибка получения специалистов: $e');

      // Пытаемся получить из кэша в случае ошибки
      if (useCache) {
        final cachedData = _cacheService.getCachedSpecialists();
        if (cachedData != null) {
          return cachedData.map(Specialist.fromMap).toList();
        }
      }

      return [];
    }
  }

  /// Получить поток всех специалистов
  Stream<List<Specialist>> getAllSpecialistsStream() => _firestore
      .collection(_collection)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Specialist.fromDocument).toList());

  /// Получить список городов из специалистов
  Future<List<String>> getCities() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final cities = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final city = data['city'] as String?;
        if (city != null && city.isNotEmpty) {
          cities.add(city);
        }
      }

      return cities.toList()..sort();
    } on Exception catch (e) {
      debugPrint('Ошибка получения городов: $e');
      return [];
    }
  }

  /// Получить специалиста по ID
  Future<Specialist?> getSpecialistById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Specialist.fromDocument(doc);
      }
      return null;
    } on Exception catch (e) {
      debugPrint('Ошибка получения специалиста: $e');
      return null;
    }
  }

  /// Поиск специалистов с фильтрами и debounce
  Future<List<Specialist>> searchSpecialists({
    String? query,
    SpecialistCategory? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? location,
    List<String>? availableDates,
    bool useDebounce = true,
  }) async {
    if (useDebounce && query != null && query.isNotEmpty) {
      return _debounceService.debounceFuture(
        'search_specialists',
        () => _performSearch(
          query: query,
          category: category,
          minPrice: minPrice,
          maxPrice: maxPrice,
          minRating: minRating,
          location: location,
          availableDates: availableDates,
        ),
      );
    }

    return _performSearch(
      query: query,
      category: category,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minRating: minRating,
      location: location,
      availableDates: availableDates,
    );
  }

  /// Выполнение поиска специалистов
  Future<List<Specialist>> _performSearch({
    String? query,
    SpecialistCategory? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? location,
    List<String>? availableDates,
  }) async {
    try {
      Query queryRef = _firestore.collection(_collection);

      // Фильтр по категории
      if (category != null) {
        queryRef = queryRef.where('category', isEqualTo: category.name);
      }

      // Фильтр по цене
      if (minPrice != null) {
        queryRef = queryRef.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        queryRef = queryRef.where('price', isLessThanOrEqualTo: maxPrice);
      }

      // Фильтр по рейтингу
      if (minRating != null) {
        queryRef = queryRef.where('rating', isGreaterThanOrEqualTo: minRating);
      }

      // Фильтр по локации
      if (location != null && location.isNotEmpty) {
        queryRef = queryRef.where('location', isEqualTo: location);
      }

      final snapshot = await queryRef.get();
      var specialists = snapshot.docs.map(Specialist.fromDocument).toList();

      // Фильтр по текстовому запросу
      if (query != null && query.isNotEmpty) {
        specialists = specialists.where((specialist) {
          final searchQuery = query.toLowerCase();
          return specialist.name.toLowerCase().contains(searchQuery) ||
              (specialist.description?.toLowerCase().contains(searchQuery) ??
                  false) ||
              specialist.category.displayName
                  .toLowerCase()
                  .contains(searchQuery);
        }).toList();
      }

      // Фильтр по доступным датам
      if (availableDates != null && availableDates.isNotEmpty) {
        specialists = specialists
            .where(
              (specialist) => availableDates
                  .any((date) => specialist.availableDates.contains(date)),
            )
            .toList();
      }

      return specialists;
    } on Exception catch (e) {
      debugPrint('Ошибка поиска специалистов: $e');
      return [];
    }
  }

  /// Получить специалистов по категории
  Future<List<Specialist>> getSpecialistsByCategory(
    SpecialistCategory category,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category.name)
          .get();
      return snapshot.docs.map(Specialist.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения специалистов по категории: $e');
      return [];
    }
  }

  /// Получить рекомендуемых специалистов
  Future<List<Specialist>> getRecommendedSpecialists(String userId) async {
    try {
      // Получаем специалистов с высоким рейтингом
      final snapshot = await _firestore
          .collection(_collection)
          .where('rating', isGreaterThanOrEqualTo: 4.5)
          .orderBy('rating', descending: true)
          .limit(10)
          .get();
      return snapshot.docs.map(Specialist.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения рекомендуемых специалистов: $e');
      return [];
    }
  }

  /// Создать нового специалиста
  Future<String?> createSpecialist(Specialist specialist) async {
    try {
      final docRef =
          await _firestore.collection(_collection).add(specialist.toMap());
      return docRef.id;
    } on Exception catch (e) {
      debugPrint('Ошибка создания специалиста: $e');
      return null;
    }
  }

  /// Обновить специалиста
  Future<bool> updateSpecialist(String id, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(id).update(updates);
      return true;
    } on Exception catch (e) {
      debugPrint('Ошибка обновления специалиста: $e');
      return false;
    }
  }

  /// Удалить специалиста
  Future<bool> deleteSpecialist(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } on Exception catch (e) {
      debugPrint('Ошибка удаления специалиста: $e');
      return false;
    }
  }

  /// Получить специалистов с пагинацией
  Future<List<Specialist>> getSpecialistsPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    SpecialistCategory? category,
  }) async {
    try {
      Query queryRef = _firestore.collection(_collection);

      if (category != null) {
        queryRef = queryRef.where('category', isEqualTo: category.name);
      }

      queryRef = queryRef.orderBy('rating', descending: true).limit(limit);

      if (lastDocument != null) {
        queryRef = queryRef.startAfterDocument(lastDocument);
      }

      final snapshot = await queryRef.get();
      return snapshot.docs.map(Specialist.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения специалистов с пагинацией: $e');
      return [];
    }
  }

  /// Фильтрация специалистов по различным критериям
  Future<List<Specialist>> filterSpecialists({
    double? minPrice,
    double? maxPrice,
    double? minRating,
    DateTime? date,
  }) async {
    try {
      // Получаем всех специалистов
      final allSpecialists = await getAllSpecialists();

      // Применяем фильтры
      final filteredSpecialists = allSpecialists.where((specialist) {
        // Фильтр по цене
        if (minPrice != null && specialist.price < minPrice) return false;
        if (maxPrice != null && specialist.price > maxPrice) return false;

        // Фильтр по рейтингу
        if (minRating != null && specialist.rating < minRating) return false;

        // Фильтр по дате доступности
        if (date != null) {
          // Проверяем, что дата не занята
          if (specialist.isDateBusy(date)) return false;

          // Проверяем, что специалист доступен в эту дату
          if (!specialist.isAvailableOnDate(date)) return false;
        }

        return true;
      }).toList();

      return filteredSpecialists;
    } on Exception catch (e) {
      debugPrint('Ошибка фильтрации специалистов: $e');
      return [];
    }
  }

  /// Получить статистику специалистов
  Future<Map<String, dynamic>> getSpecialistsStats() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final specialists = snapshot.docs.map(Specialist.fromDocument).toList();

      final totalCount = specialists.length;
      final averageRating = specialists.isNotEmpty
          ? specialists.map((s) => s.rating).reduce((a, b) => a + b) /
              specialists.length
          : 0.0;
      final averagePrice = specialists.isNotEmpty
          ? specialists.map((s) => s.price).reduce((a, b) => a + b) /
              specialists.length
          : 0.0;

      final categoryStats = <String, int>{};
      for (final specialist in specialists) {
        final category = specialist.category.displayName;
        categoryStats[category] = (categoryStats[category] ?? 0) + 1;
      }

      return {
        'totalCount': totalCount,
        'averageRating': averageRating,
        'averagePrice': averagePrice,
        'categoryStats': categoryStats,
      };
    } on Exception catch (e) {
      debugPrint('Ошибка получения статистики специалистов: $e');
      return {};
    }
  }

  /// Получить ленту специалиста (посты, активности)
  Stream<List<Map<String, dynamic>>> getSpecialistFeed(
      String specialistId) async* {
    try {
      // TODO(developer): Implement specialist feed logic
      // Пока возвращаем пустой список
      yield <Map<String, dynamic>>[];
    } on Exception catch (e) {
      debugPrint('Ошибка получения ленты специалиста: $e');
      yield <Map<String, dynamic>>[];
    }
  }

  /// Получить поток специалиста по ID
  Stream<Specialist?> getSpecialistStream(String specialistId) async* {
    try {
      final specialist = await getSpecialistById(specialistId);
      yield specialist;
    } on Exception catch (e) {
      debugPrint('Ошибка получения потока специалиста: $e');
      yield null;
    }
  }

  /// Получить поток специалиста по ID пользователя
  Stream<Specialist?> getSpecialistByUserIdStream(String userId) async* {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        yield Specialist.fromDocument(snapshot.docs.first);
      } else {
        yield null;
      }
    } on Exception catch (e) {
      debugPrint('Ошибка получения специалиста по userId: $e');
      yield null;
    }
  }

  /// Получить топ специалистов
  Future<List<Specialist>> getTopSpecialists({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('rating', descending: true)
          .orderBy('reviewsCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(Specialist.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения топ специалистов: $e');
      return <Specialist>[];
    }
  }

  /// Получить лидеров недели
  Future<List<Specialist>> getWeeklyLeaders({int limit = 10}) async {
    try {
      // Получаем специалистов с высоким рейтингом и активностью за последнюю неделю
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await _firestore
          .collection(_collection)
          .where('lastActivity', isGreaterThan: weekAgo)
          .orderBy('lastActivity', descending: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(Specialist.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения лидеров недели: $e');
      return <Specialist>[];
    }
  }

  /// Поиск специалистов с фильтрами (поток)
  Stream<List<Specialist>> searchSpecialistsStream(
      Map<String, dynamic> filters) async* {
    try {
      Query query = _firestore.collection(_collection);

      // Применяем фильтры
      if (filters['category'] != null) {
        query = query.where('category', isEqualTo: filters['category']);
      }
      if (filters['city'] != null) {
        query = query.where('city', isEqualTo: filters['city']);
      }
      if (filters['minRating'] != null) {
        query =
            query.where('rating', isGreaterThanOrEqualTo: filters['minRating']);
      }
      if (filters['maxPrice'] != null) {
        query = query.where('pricePerHour',
            isLessThanOrEqualTo: filters['maxPrice']);
      }

      // Сортировка
      final sortBy = filters['sortBy'] ?? 'rating';
      final descending = filters['descending'] ?? true;
      query = query.orderBy(sortBy, descending: descending);

      final snapshot = await query.limit(50).get();
      final specialists = snapshot.docs.map(Specialist.fromDocument).toList();
      yield specialists;
    } on Exception catch (e) {
      debugPrint('Ошибка поиска специалистов: $e');
      yield <Specialist>[];
    }
  }

  /// Проверить доступность специалиста на дату
  Future<bool> isSpecialistAvailableOnDate(
      String specialistId, DateTime date) async {
    try {
      // TODO(developer): Implement availability check logic
      // Пока возвращаем true для всех дат
      return true;
    } on Exception catch (e) {
      debugPrint('Ошибка проверки доступности специалиста: $e');
      return false;
    }
  }

  /// Получить доступные временные слоты
  Future<List<Map<String, dynamic>>> getAvailableTimeSlots(
    String specialistId,
    DateTime date,
  ) async {
    try {
      // TODO(developer): Implement time slots logic
      // Пока возвращаем базовые слоты
      return [
        {'time': '09:00', 'available': true},
        {'time': '10:00', 'available': true},
        {'time': '11:00', 'available': false},
        {'time': '12:00', 'available': true},
        {'time': '13:00', 'available': true},
        {'time': '14:00', 'available': true},
        {'time': '15:00', 'available': false},
        {'time': '16:00', 'available': true},
        {'time': '17:00', 'available': true},
        {'time': '18:00', 'available': true},
      ];
    } on Exception catch (e) {
      debugPrint('Ошибка получения временных слотов: $e');
      return <Map<String, dynamic>>[];
    }
  }
}
