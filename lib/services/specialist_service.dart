import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/specialist.dart';
import 'package:flutter/foundation.dart';
import 'cache_service.dart';
import 'package:flutter/foundation.dart';
import 'debounce_service.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ РґР»СЏ СЂР°Р±РѕС‚С‹ СЃ СЃРїРµС†РёР°Р»РёСЃС‚Р°РјРё
class SpecialistService {
  factory SpecialistService() => _instance;
  SpecialistService._internal();
  static final SpecialistService _instance = SpecialistService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'specialists';
  final CacheService _cacheService = CacheService();
  final DebounceService _debounceService = DebounceService();

  /// РџРѕР»СѓС‡РёС‚СЊ РІСЃРµС… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ СЃ РєСЌС€РёСЂРѕРІР°РЅРёРµРј
  Future<List<Specialist>> getAllSpecialists({bool useCache = true}) async {
    try {
      // РџСЂРѕРІРµСЂСЏРµРј РєСЌС€, РµСЃР»Рё РѕРЅ Р°РєС‚СѓР°Р»РµРЅ
      if (useCache && _cacheService.isSpecialistsCacheValid()) {
        final cachedData = _cacheService.getCachedSpecialists();
        if (cachedData != null) {
          return cachedData.map(Specialist.fromMap).toList();
        }
      }

      // Р—Р°РіСЂСѓР¶Р°РµРј РёР· Firestore
      final snapshot = await _firestore.collection(_collection).get();
      final specialists = snapshot.docs.map(Specialist.fromDocument).toList();

      // РљСЌС€РёСЂСѓРµРј СЂРµР·СѓР»СЊС‚Р°С‚
      if (useCache) {
        final dataToCache = specialists.map((s) => s.toMap()).toList();
        await _cacheService.cacheSpecialists(dataToCache);
      }

      return specialists;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ: $e');

      // РџС‹С‚Р°РµРјСЃСЏ РїРѕР»СѓС‡РёС‚СЊ РёР· РєСЌС€Р° РІ СЃР»СѓС‡Р°Рµ РѕС€РёР±РєРё
      if (useCache) {
        final cachedData = _cacheService.getCachedSpecialists();
        if (cachedData != null) {
          return cachedData.map(Specialist.fromMap).toList();
        }
      }

      return [];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РїРѕС‚РѕРє РІСЃРµС… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ
  Stream<List<Specialist>> getAllSpecialistsStream() => _firestore
      .collection(_collection)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Specialist.fromDocument).toList());

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРїРёСЃРѕРє РіРѕСЂРѕРґРѕРІ РёР· СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ
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
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РіРѕСЂРѕРґРѕРІ: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРїРµС†РёР°Р»РёСЃС‚Р° РїРѕ ID
  Future<Specialist?> getSpecialistById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Specialist.fromDocument(doc);
      }
      return null;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃРїРµС†РёР°Р»РёСЃС‚Р°: $e');
      return null;
    }
  }

  /// РџРѕРёСЃРє СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ СЃ С„РёР»СЊС‚СЂР°РјРё Рё debounce
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

  /// Р’С‹РїРѕР»РЅРµРЅРёРµ РїРѕРёСЃРєР° СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ
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

      // Р¤РёР»СЊС‚СЂ РїРѕ РєР°С‚РµРіРѕСЂРёРё
      if (category != null) {
        queryRef = queryRef.where('category', isEqualTo: category.name);
      }

      // Р¤РёР»СЊС‚СЂ РїРѕ С†РµРЅРµ
      if (minPrice != null) {
        queryRef = queryRef.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        queryRef = queryRef.where('price', isLessThanOrEqualTo: maxPrice);
      }

      // Р¤РёР»СЊС‚СЂ РїРѕ СЂРµР№С‚РёРЅРіСѓ
      if (minRating != null) {
        queryRef = queryRef.where('rating', isGreaterThanOrEqualTo: minRating);
      }

      // Р¤РёР»СЊС‚СЂ РїРѕ Р»РѕРєР°С†РёРё
      if (location != null && location.isNotEmpty) {
        queryRef = queryRef.where('location', isEqualTo: location);
      }

      final snapshot = await queryRef.get();
      var specialists = snapshot.docs.map(Specialist.fromDocument).toList();

      // Р¤РёР»СЊС‚СЂ РїРѕ С‚РµРєСЃС‚РѕРІРѕРјСѓ Р·Р°РїСЂРѕСЃСѓ
      if (query != null && query.isNotEmpty) {
        specialists = specialists.where((specialist) {
          final searchQuery = query.toLowerCase();
          return specialist.name.toLowerCase().contains(searchQuery) ||
              (specialist.description?.toLowerCase().contains(searchQuery) ?? false) ||
              specialist.category.displayName.toLowerCase().contains(searchQuery);
        }).toList();
      }

      // Р¤РёР»СЊС‚СЂ РїРѕ РґРѕСЃС‚СѓРїРЅС‹Рј РґР°С‚Р°Рј
      if (availableDates != null && availableDates.isNotEmpty) {
        specialists = specialists
            .where(
              (specialist) =>
                  availableDates.any((date) => specialist.availableDates.contains(date)),
            )
            .toList();
      }

      return specialists;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕРёСЃРєР° СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ РїРѕ РєР°С‚РµРіРѕСЂРёРё
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
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ РїРѕ РєР°С‚РµРіРѕСЂРёРё: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЂРµРєРѕРјРµРЅРґСѓРµРјС‹С… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ
  Future<List<Specialist>> getRecommendedSpecialists(String userId) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ СЃ РІС‹СЃРѕРєРёРј СЂРµР№С‚РёРЅРіРѕРј
      final snapshot = await _firestore
          .collection(_collection)
          .where('rating', isGreaterThanOrEqualTo: 4.5)
          .orderBy('rating', descending: true)
          .limit(10)
          .get();
      return snapshot.docs.map(Specialist.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЂРµРєРѕРјРµРЅРґСѓРµРјС‹С… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ: $e');
      return [];
    }
  }

  /// РЎРѕР·РґР°С‚СЊ РЅРѕРІРѕРіРѕ СЃРїРµС†РёР°Р»РёСЃС‚Р°
  Future<String?> createSpecialist(Specialist specialist) async {
    try {
      final docRef = await _firestore.collection(_collection).add(specialist.toMap());
      return docRef.id;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ СЃРїРµС†РёР°Р»РёСЃС‚Р°: $e');
      return null;
    }
  }

  /// РћР±РЅРѕРІРёС‚СЊ СЃРїРµС†РёР°Р»РёСЃС‚Р°
  Future<bool> updateSpecialist(String id, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(id).update(updates);
      return true;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ СЃРїРµС†РёР°Р»РёСЃС‚Р°: $e');
      return false;
    }
  }

  /// РЈРґР°Р»РёС‚СЊ СЃРїРµС†РёР°Р»РёСЃС‚Р°
  Future<bool> deleteSpecialist(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ СЃРїРµС†РёР°Р»РёСЃС‚Р°: $e');
      return false;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ СЃ РїР°РіРёРЅР°С†РёРµР№
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
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ СЃ РїР°РіРёРЅР°С†РёРµР№: $e');
      return [];
    }
  }

  /// Р¤РёР»СЊС‚СЂР°С†РёСЏ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ РїРѕ СЂР°Р·Р»РёС‡РЅС‹Рј РєСЂРёС‚РµСЂРёСЏРј
  Future<List<Specialist>> filterSpecialists({
    double? minPrice,
    double? maxPrice,
    double? minRating,
    DateTime? date,
  }) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј РІСЃРµС… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ
      final allSpecialists = await getAllSpecialists();

      // РџСЂРёРјРµРЅСЏРµРј С„РёР»СЊС‚СЂС‹
      final filteredSpecialists = allSpecialists.where((specialist) {
        // Р¤РёР»СЊС‚СЂ РїРѕ С†РµРЅРµ
        if (minPrice != null && specialist.price < minPrice) return false;
        if (maxPrice != null && specialist.price > maxPrice) return false;

        // Р¤РёР»СЊС‚СЂ РїРѕ СЂРµР№С‚РёРЅРіСѓ
        if (minRating != null && specialist.rating < minRating) return false;

        // Р¤РёР»СЊС‚СЂ РїРѕ РґР°С‚Рµ РґРѕСЃС‚СѓРїРЅРѕСЃС‚Рё
        if (date != null) {
          // РџСЂРѕРІРµСЂСЏРµРј, С‡С‚Рѕ РґР°С‚Р° РЅРµ Р·Р°РЅСЏС‚Р°
          if (specialist.isDateBusy(date)) return false;

          // РџСЂРѕРІРµСЂСЏРµРј, С‡С‚Рѕ СЃРїРµС†РёР°Р»РёСЃС‚ РґРѕСЃС‚СѓРїРµРЅ РІ СЌС‚Сѓ РґР°С‚Сѓ
          if (!specialist.isAvailableOnDate(date)) return false;
        }

        return true;
      }).toList();

      return filteredSpecialists;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° С„РёР»СЊС‚СЂР°С†РёРё СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃС‚Р°С‚РёСЃС‚РёРєСѓ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ
  Future<Map<String, dynamic>> getSpecialistsStats() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final specialists = snapshot.docs.map(Specialist.fromDocument).toList();

      final totalCount = specialists.length;
      final averageRating = specialists.isNotEmpty
          ? specialists.map((s) => s.rating).reduce((a, b) => a + b) / specialists.length
          : 0.0;
      final averagePrice = specialists.isNotEmpty
          ? specialists.map((s) => s.price).reduce((a, b) => a + b) / specialists.length
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
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃС‚Р°С‚РёСЃС‚РёРєРё СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ: $e');
      return {};
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ Р»РµРЅС‚Сѓ СЃРїРµС†РёР°Р»РёСЃС‚Р° (РїРѕСЃС‚С‹, Р°РєС‚РёРІРЅРѕСЃС‚Рё)
  Stream<List<Map<String, dynamic>>> getSpecialistFeed(String specialistId) async* {
    try {
      // TODO(developer): Implement specialist feed logic
      // РџРѕРєР° РІРѕР·РІСЂР°С‰Р°РµРј РїСѓСЃС‚РѕР№ СЃРїРёСЃРѕРє
      yield <Map<String, dynamic>>[];
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ Р»РµРЅС‚С‹ СЃРїРµС†РёР°Р»РёСЃС‚Р°: $e');
      yield <Map<String, dynamic>>[];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РїРѕС‚РѕРє СЃРїРµС†РёР°Р»РёСЃС‚Р° РїРѕ ID
  Stream<Specialist?> getSpecialistStream(String specialistId) async* {
    try {
      final specialist = await getSpecialistById(specialistId);
      yield specialist;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїРѕС‚РѕРєР° СЃРїРµС†РёР°Р»РёСЃС‚Р°: $e');
      yield null;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РїРѕС‚РѕРє СЃРїРµС†РёР°Р»РёСЃС‚Р° РїРѕ ID РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
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
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃРїРµС†РёР°Р»РёСЃС‚Р° РїРѕ userId: $e');
      yield null;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ С‚РѕРї СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ
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
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С‚РѕРї СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ: $e');
      return <Specialist>[];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ Р»РёРґРµСЂРѕРІ РЅРµРґРµР»Рё
  Future<List<Specialist>> getWeeklyLeaders({int limit = 10}) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ СЃ РІС‹СЃРѕРєРёРј СЂРµР№С‚РёРЅРіРѕРј Рё Р°РєС‚РёРІРЅРѕСЃС‚СЊСЋ Р·Р° РїРѕСЃР»РµРґРЅСЋСЋ РЅРµРґРµР»СЋ
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
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ Р»РёРґРµСЂРѕРІ РЅРµРґРµР»Рё: $e');
      return <Specialist>[];
    }
  }

  /// РџРѕРёСЃРє СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ СЃ С„РёР»СЊС‚СЂР°РјРё (РїРѕС‚РѕРє)
  Stream<List<Specialist>> searchSpecialistsStream(Map<String, dynamic> filters) async* {
    try {
      Query query = _firestore.collection(_collection);

      // РџСЂРёРјРµРЅСЏРµРј С„РёР»СЊС‚СЂС‹
      if (filters['category'] != null) {
        query = query.where('category', isEqualTo: filters['category']);
      }
      if (filters['city'] != null) {
        query = query.where('city', isEqualTo: filters['city']);
      }
      if (filters['minRating'] != null) {
        query = query.where('rating', isGreaterThanOrEqualTo: filters['minRating']);
      }
      if (filters['maxPrice'] != null) {
        query = query.where('pricePerHour', isLessThanOrEqualTo: filters['maxPrice']);
      }

      // РЎРѕСЂС‚РёСЂРѕРІРєР°
      final sortBy = filters['sortBy'] ?? 'rating';
      final descending = filters['descending'] ?? true;
      query = query.orderBy(sortBy, descending: descending);

      final snapshot = await query.limit(50).get();
      final specialists = snapshot.docs.map(Specialist.fromDocument).toList();
      yield specialists;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕРёСЃРєР° СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ: $e');
      yield <Specialist>[];
    }
  }

  /// РџСЂРѕРІРµСЂРёС‚СЊ РґРѕСЃС‚СѓРїРЅРѕСЃС‚СЊ СЃРїРµС†РёР°Р»РёСЃС‚Р° РЅР° РґР°С‚Сѓ
  Future<bool> isSpecialistAvailableOnDate(String specialistId, DateTime date) async {
    try {
      // TODO(developer): Implement availability check logic
      // РџРѕРєР° РІРѕР·РІСЂР°С‰Р°РµРј true РґР»СЏ РІСЃРµС… РґР°С‚
      return true;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїСЂРѕРІРµСЂРєРё РґРѕСЃС‚СѓРїРЅРѕСЃС‚Рё СЃРїРµС†РёР°Р»РёСЃС‚Р°: $e');
      return false;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РґРѕСЃС‚СѓРїРЅС‹Рµ РІСЂРµРјРµРЅРЅС‹Рµ СЃР»РѕС‚С‹
  Future<List<Map<String, dynamic>>> getAvailableTimeSlots(
    String specialistId,
    DateTime date,
  ) async {
    try {
      // TODO(developer): Implement time slots logic
      // РџРѕРєР° РІРѕР·РІСЂР°С‰Р°РµРј Р±Р°Р·РѕРІС‹Рµ СЃР»РѕС‚С‹
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
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РІСЂРµРјРµРЅРЅС‹С… СЃР»РѕС‚РѕРІ: $e');
      return <Map<String, dynamic>>[];
    }
  }
}

