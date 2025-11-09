import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/specialist_enhanced.dart';
import 'package:event_marketplace_app/models/search_filters.dart' as search_filters;
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Провайдер для получения ТОП специалистов по городу (по scoreWeekly)
final topSpecialistsByCityProvider =
    FutureProvider.family<List<SpecialistEnhanced>, String>((ref, city) async {
  try {
    // Сначала получаем рейтинги по городу
    final scoresQuery = FirebaseFirestore.instance
        .collection('specialist_scores')
        .where('city', isEqualTo: city)
        .orderBy('scoreWeekly', descending: true)
        .limit(10);

    final scoresSnapshot = await scoresQuery.get();
    if (scoresSnapshot.docs.isEmpty) {
      return [];
    }

    final specIds = scoresSnapshot.docs.map((doc) => doc.id).toList();
    
    // Получаем данные специалистов
    final specialists = <SpecialistEnhanced>[];
    for (final specId in specIds) {
      final specDoc = await FirebaseFirestore.instance
          .collection('specialists')
          .doc(specId)
          .get();
      
      if (specDoc.exists && (specDoc.data()?['isActive'] == true)) {
        specialists.add(SpecialistEnhanced.fromFirestore(specDoc));
      }
    }

    return specialists;
  } catch (e) {
    debugPrint('❌ Error fetching top specialists by city: $e');
    // Fallback на старую логику если нет рейтингов
    try {
      final query = FirebaseFirestore.instance
          .collection('specialists')
          .where('city', isEqualTo: city)
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(20);
      final snapshot = await query.get();
      return snapshot.docs.map(SpecialistEnhanced.fromFirestore).toList();
    } catch (e2) {
      return [];
    }
  }
});

/// Провайдер для получения ТОП специалистов по России (по scoreWeekly)
final topSpecialistsByRussiaProvider =
    FutureProvider<List<SpecialistEnhanced>>((ref) async {
  try {
    // Получаем специалистов с country='RU' и их рейтинги
    final statsQuery = FirebaseFirestore.instance
        .collection('specialist_stats')
        .where('country', isEqualTo: 'RU')
        .limit(100); // Больше для последующей фильтрации

    final statsSnapshot = await statsQuery.get();
    if (statsSnapshot.docs.isEmpty) {
      return [];
    }

    final specIds = statsSnapshot.docs.map((doc) => doc.id).toList();
    
    // Получаем рейтинги
    final scoresMap = <String, double>{};
    for (final specId in specIds) {
      final scoreDoc = await FirebaseFirestore.instance
          .collection('specialist_scores')
          .doc(specId)
          .get();
      if (scoreDoc.exists) {
        scoresMap[specId] = (scoreDoc.data()?['scoreWeekly'] ?? 0).toDouble();
      }
    }

    // Сортируем по scoreWeekly
    specIds.sort((a, b) => (scoresMap[b] ?? 0).compareTo(scoresMap[a] ?? 0));

    // Получаем топ-20 специалистов
    final specialists = <SpecialistEnhanced>[];
    for (final specId in specIds.take(20)) {
      final specDoc = await FirebaseFirestore.instance
          .collection('specialists')
          .doc(specId)
          .get();
      
      if (specDoc.exists && (specDoc.data()?['isActive'] == true)) {
        specialists.add(SpecialistEnhanced.fromFirestore(specDoc));
      }
    }

    return specialists;
  } catch (e) {
    debugPrint('❌ Error fetching top specialists by Russia: $e');
    // Fallback на старую логику
    try {
      final query = FirebaseFirestore.instance
          .collection('specialists')
          .where('region', isEqualTo: 'Россия')
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(20);
      final snapshot = await query.get();
      return snapshot.docs.map(SpecialistEnhanced.fromFirestore).toList();
    } catch (e2) {
      return [];
    }
  }
});

/// Провайдер для поиска специалистов с фильтрами
final searchSpecialistsProvider =
    FutureProvider.family<List<SpecialistEnhanced>, SearchFilters>(
        (ref, filters) async {
  try {
    Query query = FirebaseFirestore.instance.collection('specialists');

    // Фильтр по городу
    if (filters.city != null) {
      query = query.where('city', isEqualTo: filters.city);
    }

    // Фильтр по региону
    if (filters.region != null) {
      query = query.where('region', isEqualTo: filters.region);
    }

    // Фильтр по категориям
    if (filters.categories.isNotEmpty) {
      query = query.where('categories', arrayContainsAny: filters.categories);
    }

    // Фильтр по рейтингу
    if (filters.minRating != null) {
      query = query.where('rating', isGreaterThanOrEqualTo: filters.minRating);
    }
    if (filters.maxRating != null) {
      query = query.where('rating', isLessThanOrEqualTo: filters.maxRating);
    }

    // Фильтр по верификации
    if (filters.isVerified != null) {
      query = query.where('isVerified', isEqualTo: filters.isVerified);
    }

    // Фильтр по ТОП недели
    if (filters.isTopWeek != null) {
      query = query.where('isTopWeek', isEqualTo: filters.isTopWeek);
    }

    // Фильтр по новичкам
    if (filters.isNewcomer != null) {
      query = query.where('isNewcomer', isEqualTo: filters.isNewcomer);
    }

    // Сортировка
    switch (filters.sortBy) {
      case 'rating':
        query = query.orderBy('rating', descending: true);
      case 'orders':
        query = query.orderBy('successfulOrders', descending: true);
      case 'price':
        query = query.orderBy('pricing.minPrice', descending: false);
      case 'newest':
        query = query.orderBy('createdAt', descending: true);
      default:
        query = query.orderBy('rating', descending: true);
    }

    // Ограничение результатов
    query = query.limit(50);

    final snapshot = await query.get();
    var specialists = snapshot.docs
        .map(SpecialistEnhanced.fromFirestore)
        .toList();

    // Дополнительная фильтрация на клиенте (для сложных фильтров)
    if (filters.minPrice != null || filters.maxPrice != null) {
      specialists = specialists.where((specialist) {
        final minPrice = specialist.minPrice;
        final maxPrice = specialist.maxPrice;

        if (filters.minPrice != null && maxPrice < filters.minPrice!) {
          return false;
        }
        if (filters.maxPrice != null && minPrice > filters.maxPrice!) {
          return false;
        }
        return true;
      }).toList();
    }

    // Фильтр по языкам
    if (filters.languages.isNotEmpty) {
      specialists = specialists.where((specialist) {
        return filters.languages
            .any((language) => specialist.languages.contains(language));
      }).toList();
    }

    // Фильтр по доступным датам
    if (filters.availableDates.isNotEmpty) {
      debugLog("SEARCH_DATE_FILTER_APPLIED:${filters.availableDates.join(',')}");
      specialists = specialists.where((specialist) {
        return filters.availableDates
            .any((date) => specialist.availableDates.contains(date));
      }).toList();
    }

    return specialists;
  } catch (e) {
    debugPrint('❌ Error searching specialists: $e');
    return [];
  }
});

/// Провайдер для получения специалистов рядом с пользователем
final nearbySpecialistsProvider =
    FutureProvider.family<List<SpecialistEnhanced>, Position>(
        (ref, position) async {
  try {
    // Получаем всех специалистов (пока без геолокации в Firestore)
    final query = FirebaseFirestore.instance
        .collection('specialists')
        .where('isActive', isEqualTo: true)
        .limit(20);

    final snapshot = await query.get();
    final specialists = snapshot.docs
        .map(SpecialistEnhanced.fromFirestore)
        .toList();

    // Фильтруем по расстоянию (если есть координаты)
    final nearbySpecialists = <SpecialistEnhanced>[];

    for (final specialist in specialists) {
      if (specialist.location.containsKey('latitude') &&
          specialist.location.containsKey('longitude')) {
        final lat = specialist.location['latitude'] as double?;
        final lng = specialist.location['longitude'] as double?;

        if (lat != null && lng != null) {
          final distance = Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                lat,
                lng,
              ) /
              1000; // в километрах

          if (distance <= 50) {
            // в радиусе 50 км
            nearbySpecialists.add(specialist);
          }
        }
      }
    }

    // Сортируем по расстоянию
    nearbySpecialists.sort((a, b) {
      final distanceA = _calculateDistance(position, a.location);
      final distanceB = _calculateDistance(position, b.location);
      return distanceA.compareTo(distanceB);
    });

    return nearbySpecialists.take(10).toList();
  } catch (e) {
    debugPrint('❌ Error fetching nearby specialists: $e');
    return [];
  }
});

/// Провайдер для получения категорий специалистов
final specialistCategoriesProvider =
    FutureProvider<List<SpecialistCategory>>((ref) async {
  try {
    // Возвращаем все доступные категории
    return SpecialistCategory.values;
  } catch (e) {
    debugPrint('❌ Error fetching specialist categories: $e');
    return [];
  }
});

/// Провайдер для получения популярных поисковых запросов
final popularSearchQueriesProvider = FutureProvider<List<String>>((ref) async {
  try {
    // Здесь можно получать из Firestore или возвращать статичные данные
    return [
      'Ведущий свадьбы',
      'Фотограф на мероприятие',
      'Кейтеринг',
      'Декор для свадьбы',
      'Музыканты',
      'DJ',
      'Визажист',
      'Стилист',
      'Охрана',
      'Транспорт',
    ];
  } catch (e) {
    debugPrint('❌ Error fetching popular search queries: $e');
    return [];
  }
});

/// Провайдер для получения сохраненных фильтров пользователя
final savedFiltersProvider =
    NotifierProvider<SavedFiltersNotifier, List<search_filters.SearchFilters>>(() {
  return SavedFiltersNotifier();
});

/// Провайдер для текущих фильтров поиска
final currentSearchFiltersProvider =
    NotifierProvider<SearchFiltersNotifier, search_filters.SearchFilters>(() {
  return SearchFiltersNotifier();
});

/// Провайдер для избранных специалистов
final favoriteSpecialistsProvider =
    NotifierProvider<FavoriteSpecialistsNotifier, List<String>>(() {
  return FavoriteSpecialistsNotifier();
});

/// Провайдер для получения геолокации пользователя
final userLocationProvider = FutureProvider<Position?>((ref) async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requestPermission = await Geolocator.requestPermission();
      if (requestPermission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  } catch (e) {
    debugPrint('❌ Error getting user location: $e');
    return null;
  }
});

/// Провайдер для получения города пользователя
final userCityProvider = FutureProvider<String?>((ref) async {
  try {
    final location = await ref.watch(userLocationProvider.future);
    if (location == null) return null;

    // Здесь можно использовать геокодирование для получения города
    // Пока возвращаем заглушку
    return 'Москва';
  } catch (e) {
    debugPrint('❌ Error getting user city: $e');
    return null;
  }
});

/// Вспомогательные функции

/// Вычислить расстояние между двумя точками
double _calculateDistance(Position position, Map<String, dynamic> location) {
  final lat = location['latitude'] as double?;
  final lng = location['longitude'] as double?;

  if (lat == null || lng == null) return double.infinity;

  return Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        lat,
        lng,
      ) /
      1000; // в километрах
}

/// Нотификатор для сохраненных фильтров
class SavedFiltersNotifier extends Notifier<List<search_filters.SearchFilters>> {
  @override
  List<search_filters.SearchFilters> build() {
    _loadSavedFilters();
    return [];
  }

  Future<void> _loadSavedFilters() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_filters')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final filters = snapshot.docs
          .map((doc) => search_filters.SearchFilters.fromMap(doc.data()))
          .toList();

      state = filters;
    } catch (e) {
      debugPrint('Error loading saved filters: $e');
    }
  }

  Future<void> addFilter(search_filters.SearchFilters filter, String? name) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_filters')
          .add({
        'name': name ?? 'Фильтр ${DateTime.now().toString().substring(0, 10)}',
        ...filter.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _loadSavedFilters();
      debugLog("SEARCH_FILTER_SAVED:${name ?? 'unnamed'}");
    } catch (e) {
      debugPrint('Error saving filter: $e');
      debugLog("SEARCH_FILTER_SAVE_ERR:$e");
    }
  }

  Future<void> removeFilter(String filterId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_filters')
          .doc(filterId)
          .delete();

      await _loadSavedFilters();
      debugLog("SEARCH_FILTER_DELETED:$filterId");
    } catch (e) {
      debugPrint('Error deleting filter: $e');
      debugLog("SEARCH_FILTER_DELETE_ERR:$e");
    }
  }

  Future<void> clearAll() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_filters')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      state = [];
      debugLog("SEARCH_FILTERS_CLEARED");
    } catch (e) {
      debugPrint('Error clearing filters: $e');
      debugLog("SEARCH_FILTERS_CLEAR_ERR:$e");
  }
  }

  Future<void> loadFilter(search_filters.SearchFilters filter) async {
    // Применяем фильтр к текущему поиску
    // Это будет использоваться через searchFiltersProvider
    debugLog("SEARCH_FILTER_LOADED");
  }
}

/// Нотификатор для текущих фильтров поиска
class SearchFiltersNotifier extends Notifier<search_filters.SearchFilters> {
  @override
  search_filters.SearchFilters build() => const search_filters.SearchFilters();

  void updateFilters(search_filters.SearchFilters newFilters) {
    state = newFilters;
  }

  void clearFilters() {
    state = const search_filters.SearchFilters();
  }

  void setCity(String? city) {
    state = state.copyWith(city: city);
  }

  void setCategories(List<String> categories) {
    state = state.copyWith(services: categories);
  }

  void setRatingRange(double? minRating, double? maxRating) {
    state = state.copyWith(minRating: minRating);
  }

  void setPriceRange(double? minPrice, double? maxPrice) {
    state = state.copyWith(
      minPrice: minPrice?.toInt(),
      maxPrice: maxPrice?.toInt(),
    );
  }
}

/// Нотификатор для избранных специалистов
class FavoriteSpecialistsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void toggleFavorite(String specialistId) {
    if (state.contains(specialistId)) {
      state = state.where((id) => id != specialistId).toList();
    } else {
      state = [...state, specialistId];
    }
  }

  bool isFavorite(String specialistId) {
    return state.contains(specialistId);
  }

  void clearFavorites() {
    state = [];
  }
}
