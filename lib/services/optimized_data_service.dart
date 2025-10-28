import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/category.dart';
import 'package:event_marketplace_app/models/specialist.dart';
import 'package:flutter/foundation.dart';

/// Оптимизированный сервис для работы с данными
class OptimizedDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Кэш для категорий
  List<Category>? _cachedCategories;
  DateTime? _categoriesCacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 30);

  // Кэш для специалистов
  final Map<String, List<Specialist>> _specialistsCache = {};
  final Map<String, DateTime> _specialistsCacheTime = {};

  /// Получить категории с кэшированием
  Future<List<Category>> getCategories({bool forceRefresh = false}) async {
    try {
      // Проверяем кэш
      if (!forceRefresh &&
          _cachedCategories != null &&
          _categoriesCacheTime != null &&
          DateTime.now().difference(_categoriesCacheTime!) < _cacheExpiry) {
        return _cachedCategories!;
      }

      debugPrint('📂 Загрузка категорий из Firestore...');

      final snapshot = await _firestore
          .collection('categories')
          .orderBy('popularity', descending: true)
          .limit(20)
          .get();

      final categories = snapshot.docs.map((doc) {
        final data = doc.data();
        return Category(
          id: doc.id,
          name: data['name'] ?? '',
          displayName: data['displayName'] ?? data['name'] ?? '',
          icon: data['icon'] ?? 'category',
          color: data['color'] ?? 0xFF2196F3,
          description: data['description'] ?? '',
          popularity: data['popularity']?.toInt() ?? 0,
          specialistCount: data['specialistCount']?.toInt() ?? 0,
          isActive: data['isActive'] ?? true,
        );
      }).toList();

      // Обновляем кэш
      _cachedCategories = categories;
      _categoriesCacheTime = DateTime.now();

      debugPrint('✅ Загружено ${categories.length} категорий');
      return categories;
    } catch (e) {
      debugPrint('❌ Ошибка загрузки категорий: $e');
      return _cachedCategories ?? [];
    }
  }

  /// Получить популярных специалистов с кэшированием
  Future<List<Specialist>> getPopularSpecialists({
    String? city,
    String? category,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = '${city ?? 'all'}_${category ?? 'all'}_$limit';

      // Проверяем кэш
      if (!forceRefresh &&
          _specialistsCache.containsKey(cacheKey) &&
          _specialistsCacheTime.containsKey(cacheKey) &&
          DateTime.now().difference(_specialistsCacheTime[cacheKey]!) <
              _cacheExpiry) {
        return _specialistsCache[cacheKey]!;
      }

      debugPrint('👥 Загрузка популярных специалистов из Firestore...');

      Query query = _firestore
          .collection('specialists')
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .orderBy('rating', descending: true)
          .orderBy('reviewCount', descending: true)
          .limit(limit);

      // Фильтры
      if (city != null) {
        query = query.where('city', isEqualTo: city);
      }
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();

      final specialists = snapshot.docs.map((doc) {
        final data = doc.data();
        return Specialist.fromFirestore(doc);
      }).toList();

      // Обновляем кэш
      _specialistsCache[cacheKey] = specialists;
      _specialistsCacheTime[cacheKey] = DateTime.now();

      debugPrint('✅ Загружено ${specialists.length} специалистов');
      return specialists;
    } catch (e) {
      debugPrint('❌ Ошибка загрузки специалистов: $e');
      return _specialistsCache[cacheKey] ?? [];
    }
  }

  /// Получить специалистов по городу с сортировкой
  Future<List<Specialist>> getSpecialistsByCity({
    required String city,
    String? category,
    String sortBy = 'popularity', // popularity, rating, price
    int limit = 20,
  }) async {
    try {
      debugPrint('🏙️ Загрузка специалистов для города: $city');

      Query query = _firestore
          .collection('specialists')
          .where('city', isEqualTo: city)
          .where('isActive', isEqualTo: true)
          .limit(limit);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      // Сортировка
      switch (sortBy) {
        case 'popularity':
          query = query.orderBy('reviewCount', descending: true);
        case 'rating':
          query = query.orderBy('rating', descending: true);
        case 'price':
          query = query.orderBy('price', descending: false);
        default:
          query = query.orderBy('createdAt', descending: true);
      }

      final snapshot = await query.get();

      final specialists = snapshot.docs.map((doc) {
        return Specialist.fromFirestore(doc);
      }).toList();

      debugPrint('✅ Загружено ${specialists.length} специалистов для $city');
      return specialists;
    } catch (e) {
      debugPrint('❌ Ошибка загрузки специалистов по городу: $e');
      return [];
    }
  }

  /// Получить статистику категорий
  Future<Map<String, int>> getCategoryStats() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      final stats = <String, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        stats[doc.id] = data['specialistCount']?.toInt() ?? 0;
      }

      return stats;
    } catch (e) {
      debugPrint('❌ Ошибка загрузки статистики категорий: $e');
      return {};
    }
  }

  /// Очистить кэш
  void clearCache() {
    _cachedCategories = null;
    _categoriesCacheTime = null;
    _specialistsCache.clear();
    _specialistsCacheTime.clear();
    debugPrint('🧹 Кэш очищен');
  }

  /// Очистить кэш специалистов
  void clearSpecialistsCache() {
    _specialistsCache.clear();
    _specialistsCacheTime.clear();
    debugPrint('🧹 Кэш специалистов очищен');
  }
}
