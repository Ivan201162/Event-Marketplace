import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ СѓРјРЅРѕРіРѕ РїРѕРёСЃРєР° СЃ РїРѕРґСЃРєР°Р·РєР°РјРё Рё Р°РІС‚РѕР·Р°РїРѕР»РЅРµРЅРёРµРј
class SmartSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Position? _currentPosition;
  String? _currentCity;

  /// РџРѕР»СѓС‡РёС‚СЊ РїРѕРґСЃРєР°Р·РєРё РґР»СЏ РїРѕРёСЃРєР°
  Future<List<SearchSuggestion>> getSearchSuggestions(String query) async {
    if (query.isEmpty) {
      return _getPopularSuggestions();
    }

    final suggestions = <SearchSuggestion>[];

    try {
      // РџРѕРёСЃРє РїРѕ СЃРїРµС†РёР°Р»РёСЃС‚Р°Рј
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

      // РџРѕРёСЃРє РїРѕ РєР°С‚РµРіРѕСЂРёСЏРј
      final categories = [
        'Р’РµРґСѓС‰РёРµ',
        'DJ',
        'Р¤РѕС‚РѕРіСЂР°С„С‹',
        'Р’РёРґРµРѕРіСЂР°С„С‹',
        'Р”РµРєРѕСЂР°С‚РѕСЂС‹',
        'РђРЅРёРјР°С‚РѕСЂС‹',
        'РњСѓР·С‹РєР°РЅС‚С‹',
        'РўР°РЅС†РѕСЂС‹',
        'РљР»РѕСѓРЅС‹',
        'Р¤РѕРєСѓСЃРЅРёРєРё',
        'РџРµРІС†С‹',
        'Р“РёС‚Р°СЂРёСЃС‚С‹',
      ];

      for (final category in categories) {
        if (category.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(
            SearchSuggestion(
              text: category,
              type: SuggestionType.category,
              icon: Icons.category,
              subtitle: 'РљР°С‚РµРіРѕСЂРёСЏ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ',
              data: {'category': category},
            ),
          );
        }
      }

      // РџРѕРёСЃРє РїРѕ РіРѕСЂРѕРґР°Рј
      final cities = [
        'РњРѕСЃРєРІР°',
        'РЎР°РЅРєС‚-РџРµС‚РµСЂР±СѓСЂРі',
        'РљР°Р·Р°РЅСЊ',
        'Р•РєР°С‚РµСЂРёРЅР±СѓСЂРі',
        'РќРѕРІРѕСЃРёР±РёСЂСЃРє',
        'РќРёР¶РЅРёР№ РќРѕРІРіРѕСЂРѕРґ',
        'Р§РµР»СЏР±РёРЅСЃРє',
        'РЎР°РјР°СЂР°',
        'РћРјСЃРє',
        'Р РѕСЃС‚РѕРІ-РЅР°-Р”РѕРЅСѓ',
        'РЈС„Р°',
        'РљСЂР°СЃРЅРѕСЏСЂСЃРє',
        'Р’РѕСЂРѕРЅРµР¶',
        'РџРµСЂРјСЊ',
        'Р’РѕР»РіРѕРіСЂР°Рґ',
      ];

      for (final city in cities) {
        if (city.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(
            SearchSuggestion(
              text: city,
              type: SuggestionType.location,
              icon: Icons.location_on,
              subtitle: 'Р“РѕСЂРѕРґ',
              data: {'city': city},
            ),
          );
        }
      }

      // РџРѕРёСЃРє РїРѕ СѓСЃР»СѓРіР°Рј
      final services = [
        'РЎРІР°РґСЊР±Р°',
        'РљРѕСЂРїРѕСЂР°С‚РёРІ',
        'Р”РµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ',
        'Р’С‹РїСѓСЃРєРЅРѕР№',
        'Р®Р±РёР»РµР№',
        'Р¤РѕС‚РѕСЃРµСЃСЃРёСЏ',
        'Р’РёРґРµРѕСЃСЉРµРјРєР°',
        'Р’РµРґСѓС‰РёР№',
        'DJ',
        'РђРЅРёРјР°С‚РѕСЂ',
      ];

      for (final service in services) {
        if (service.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(
            SearchSuggestion(
              text: service,
              type: SuggestionType.service,
              icon: Icons.event,
              subtitle: 'РЈСЃР»СѓРіР°',
              data: {'service': service},
            ),
          );
        }
      }
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїРѕРґСЃРєР°Р·РѕРє: $e');
    }

    return suggestions.take(10).toList();
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РїРѕРїСѓР»СЏСЂРЅС‹Рµ РїРѕРґСЃРєР°Р·РєРё
  List<SearchSuggestion> _getPopularSuggestions() => [
        SearchSuggestion(
          text: 'Р’РµРґСѓС‰РёРµ',
          type: SuggestionType.category,
          icon: Icons.category,
          subtitle: 'РџРѕРїСѓР»СЏСЂРЅР°СЏ РєР°С‚РµРіРѕСЂРёСЏ',
          data: {'category': 'Р’РµРґСѓС‰РёРµ'},
        ),
        SearchSuggestion(
          text: 'Р¤РѕС‚РѕРіСЂР°С„С‹',
          type: SuggestionType.category,
          icon: Icons.category,
          subtitle: 'РџРѕРїСѓР»СЏСЂРЅР°СЏ РєР°С‚РµРіРѕСЂРёСЏ',
          data: {'category': 'Р¤РѕС‚РѕРіСЂР°С„С‹'},
        ),
        SearchSuggestion(
          text: 'РњРѕСЃРєРІР°',
          type: SuggestionType.location,
          icon: Icons.location_on,
          subtitle: 'РџРѕРїСѓР»СЏСЂРЅС‹Р№ РіРѕСЂРѕРґ',
          data: {'city': 'РњРѕСЃРєРІР°'},
        ),
        SearchSuggestion(
          text: 'РЎРІР°РґСЊР±Р°',
          type: SuggestionType.service,
          icon: Icons.event,
          subtitle: 'РџРѕРїСѓР»СЏСЂРЅР°СЏ СѓСЃР»СѓРіР°',
          data: {'service': 'РЎРІР°РґСЊР±Р°'},
        ),
      ];

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ СЃ С„РёР»СЊС‚СЂР°РјРё
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

      // Р¤РёР»СЊС‚СЂ РїРѕ РєР°С‚РµРіРѕСЂРёРё
      if (category != null && category.isNotEmpty) {
        queryBuilder = queryBuilder.where('category', isEqualTo: category);
      }

      // Р¤РёР»СЊС‚СЂ РїРѕ РіРѕСЂРѕРґСѓ
      if (city != null && city.isNotEmpty) {
        queryBuilder = queryBuilder.where('city', isEqualTo: city);
      }

      // Р¤РёР»СЊС‚СЂ РїРѕ С†РµРЅРµ
      if (minPrice != null) {
        queryBuilder = queryBuilder.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        queryBuilder = queryBuilder.where('price', isLessThanOrEqualTo: maxPrice);
      }

      // Р¤РёР»СЊС‚СЂ РїРѕ СЂРµР№С‚РёРЅРіСѓ
      if (minRating != null) {
        queryBuilder = queryBuilder.where('rating', isGreaterThanOrEqualTo: minRating);
      }

      // РЎРѕСЂС‚РёСЂРѕРІРєР°
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
          // TODO(developer): Р РµР°Р»РёР·РѕРІР°С‚СЊ СЃРѕСЂС‚РёСЂРѕРІРєСѓ РїРѕ СЂР°СЃСЃС‚РѕСЏРЅРёСЋ
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

        // Р¤РёР»СЊС‚СЂ РїРѕ РїРѕРёСЃРєРѕРІРѕРјСѓ Р·Р°РїСЂРѕСЃСѓ
        if (query != null && query.isNotEmpty) {
          final searchLower = query.toLowerCase();
          final name = ((data['name'] as String?) ?? '').toLowerCase();
          final description = ((data['description'] as String?) ?? '').toLowerCase();
          final categoryName = ((data['category'] as String?) ?? '').toLowerCase();

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
      debugPrint('РћС€РёР±РєР° РїРѕРёСЃРєР° СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РїРѕРїСѓР»СЏСЂРЅС‹С… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ РЅРµРґРµР»Рё
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
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїРѕРїСѓР»СЏСЂРЅС‹С… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ: $e');
      return [];
    }
  }

  /// РЎРѕС…СЂР°РЅРёС‚СЊ С„РёР»СЊС‚СЂС‹ РїРѕРёСЃРєР°
  Future<void> saveSearchFilters(Map<String, dynamic> filters) async {
    try {
      // TODO(developer): Р РµР°Р»РёР·РѕРІР°С‚СЊ СЃРѕС…СЂР°РЅРµРЅРёРµ С„РёР»СЊС‚СЂРѕРІ РІ SharedPreferences
      debugPrint('РЎРѕС…СЂР°РЅРµРЅРёРµ С„РёР»СЊС‚СЂРѕРІ: $filters');
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕС…СЂР°РЅРµРЅРёСЏ С„РёР»СЊС‚СЂРѕРІ: $e');
    }
  }

  /// Р—Р°РіСЂСѓР·РёС‚СЊ СЃРѕС…СЂР°РЅС‘РЅРЅС‹Рµ С„РёР»СЊС‚СЂС‹
  Future<Map<String, dynamic>> loadSearchFilters() async {
    try {
      // TODO(developer): Р РµР°Р»РёР·РѕРІР°С‚СЊ Р·Р°РіСЂСѓР·РєСѓ С„РёР»СЊС‚СЂРѕРІ РёР· SharedPreferences
      return {};
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё С„РёР»СЊС‚СЂРѕРІ: $e');
      return {};
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ С‚РµРєСѓС‰СѓСЋ РіРµРѕР»РѕРєР°С†РёСЋ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<Position?> getCurrentLocation() async {
    try {
      // РџСЂРѕРІРµСЂСЏРµРј СЂР°Р·СЂРµС€РµРЅРёСЏ
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

      // РџРѕР»СѓС‡Р°РµРј С‚РµРєСѓС‰СѓСЋ РїРѕР·РёС†РёСЋ
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return _currentPosition;
    } catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РіРµРѕР»РѕРєР°С†РёРё: $e');
      return null;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РіРѕСЂРѕРґ РїРѕ РєРѕРѕСЂРґРёРЅР°С‚Р°Рј
  Future<String?> getCityFromCoordinates(double lat, double lng) async {
    try {
      // РџСЂРѕСЃС‚Р°СЏ СЂРµР°Р»РёР·Р°С†РёСЏ - РІ СЂРµР°Р»СЊРЅРѕРј РїСЂРёР»РѕР¶РµРЅРёРё РёСЃРїРѕР»СЊР·СѓР№С‚Рµ Geocoding API
      final cities = {
        'РњРѕСЃРєРІР°': {'lat': 55.7558, 'lng': 37.6176},
        'РЎР°РЅРєС‚-РџРµС‚РµСЂР±СѓСЂРі': {'lat': 59.9311, 'lng': 30.3609},
        'РќРѕРІРѕСЃРёР±РёСЂСЃРє': {'lat': 55.0084, 'lng': 82.9357},
        'Р•РєР°С‚РµСЂРёРЅР±СѓСЂРі': {'lat': 56.8431, 'lng': 60.6454},
        'РљР°Р·Р°РЅСЊ': {'lat': 55.8304, 'lng': 49.0661},
        'РќРёР¶РЅРёР№ РќРѕРІРіРѕСЂРѕРґ': {'lat': 56.2965, 'lng': 43.9361},
        'Р§РµР»СЏР±РёРЅСЃРє': {'lat': 55.1644, 'lng': 61.4368},
        'РЎР°РјР°СЂР°': {'lat': 53.2001, 'lng': 50.1500},
        'РћРјСЃРє': {'lat': 54.9885, 'lng': 73.3242},
        'Р РѕСЃС‚РѕРІ-РЅР°-Р”РѕРЅСѓ': {'lat': 47.2357, 'lng': 39.7015},
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
      debugPrint('РћС€РёР±РєР° РѕРїСЂРµРґРµР»РµРЅРёСЏ РіРѕСЂРѕРґР°: $e');
      return null;
    }
  }

  /// Р’С‹С‡РёСЃР»РёС‚СЊ СЂР°СЃСЃС‚РѕСЏРЅРёРµ РјРµР¶РґСѓ РґРІСѓРјСЏ С‚РѕС‡РєР°РјРё
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) =>
      Geolocator.distanceBetween(lat1, lng1, lat2, lng2);

  /// РџРѕР»СѓС‡РёС‚СЊ РїРѕРїСѓР»СЏСЂРЅС‹Рµ РіРѕСЂРѕРґР° РґР»СЏ Р°РІС‚РѕР·Р°РїРѕР»РЅРµРЅРёСЏ
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
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РіРѕСЂРѕРґРѕРІ: $e');
      return [
        'РњРѕСЃРєРІР°',
        'РЎР°РЅРєС‚-РџРµС‚РµСЂР±СѓСЂРі',
        'РќРѕРІРѕСЃРёР±РёСЂСЃРє',
        'Р•РєР°С‚РµСЂРёРЅР±СѓСЂРі',
        'РљР°Р·Р°РЅСЊ',
        'РќРёР¶РЅРёР№ РќРѕРІРіРѕСЂРѕРґ',
        'Р§РµР»СЏР±РёРЅСЃРє',
        'РЎР°РјР°СЂР°',
        'РћРјСЃРє',
        'Р РѕСЃС‚РѕРІ-РЅР°-Р”РѕРЅСѓ',
      ];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РїРѕРїСѓР»СЏСЂРЅС‹Рµ РєР°С‚РµРіРѕСЂРёРё РґР»СЏ Р°РІС‚РѕР·Р°РїРѕР»РЅРµРЅРёСЏ
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
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РєР°С‚РµРіРѕСЂРёР№: $e');
      return [
        'Р’РµРґСѓС‰РёРµ',
        'DJ',
        'Р¤РѕС‚РѕРіСЂР°С„С‹',
        'Р’РёРґРµРѕРіСЂР°С„С‹',
        'Р”РµРєРѕСЂР°С‚РѕСЂС‹',
        'РђРЅРёРјР°С‚РѕСЂС‹',
        'РњСѓР·С‹РєР°РЅС‚С‹',
        'РўР°РЅС†РѕСЂС‹',
        'РљР»РѕСѓРЅС‹',
        'Р¤РѕРєСѓСЃРЅРёРєРё',
        'РџРµРІС†С‹',
        'РћСЂРіР°РЅРёР·Р°С‚РѕСЂС‹',
      ];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ С‚РµРєСѓС‰РёР№ РіРѕСЂРѕРґ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  String? get currentCity => _currentCity;

  /// РџРѕР»СѓС‡РёС‚СЊ С‚РµРєСѓС‰СѓСЋ РїРѕР·РёС†РёСЋ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Position? get currentPosition => _currentPosition;

  /// РџРѕР»СѓС‡РёС‚СЊ РїРѕРїСѓР»СЏСЂРЅС‹С… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ РЅРµРґРµР»Рё
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

        // Р”РѕР±Р°РІР»СЏРµРј РґРѕРїРѕР»РЅРёС‚РµР»СЊРЅС‹Рµ РїРѕР»СЏ РґР»СЏ Р±РµР№РґР¶РµР№
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

      // Р•СЃР»Рё РЅРµС‚ РґР°РЅРЅС‹С… РІ Firestore, РІРѕР·РІСЂР°С‰Р°РµРј С‚РµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ
      if (specialists.isEmpty) {
        return _getTestWeeklyPopularSpecialists();
      }

      return specialists;
    } catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїРѕРїСѓР»СЏСЂРЅС‹С… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ: $e');
      return _getTestWeeklyPopularSpecialists();
    }
  }

  /// РўРµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ РґР»СЏ РїРѕРїСѓР»СЏСЂРЅС‹С… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ РЅРµРґРµР»Рё
  List<Map<String, dynamic>> _getTestWeeklyPopularSpecialists() => [
        {
          'id': 'specialist_1',
          'name': 'РђРЅРЅР° РџРµС‚СЂРѕРІР°',
          'category': 'Р¤РѕС‚РѕРіСЂР°С„',
          'rating': 4.9,
          'price': 15000,
          'city': 'РњРѕСЃРєРІР°',
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
          'name': 'Р”РјРёС‚СЂРёР№ РЎРјРёСЂРЅРѕРІ',
          'category': 'DJ',
          'rating': 4.8,
          'price': 25000,
          'city': 'РЎР°РЅРєС‚-РџРµС‚РµСЂР±СѓСЂРі',
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
          'name': 'Р•Р»РµРЅР° РљРѕР·Р»РѕРІР°',
          'category': 'Р’РµРґСѓС‰Р°СЏ',
          'rating': 4.7,
          'price': 20000,
          'city': 'РњРѕСЃРєРІР°',
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
          'name': 'РњРёС…Р°РёР» Р’РѕР»РєРѕРІ',
          'category': 'Р’РёРґРµРѕРіСЂР°С„',
          'rating': 4.6,
          'price': 30000,
          'city': 'РќРѕРІРѕСЃРёР±РёСЂСЃРє',
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
          'name': 'РћР»СЊРіР° РњРѕСЂРѕР·РѕРІР°',
          'category': 'Р”РµРєРѕСЂР°С‚РѕСЂ',
          'rating': 4.5,
          'price': 18000,
          'city': 'Р•РєР°С‚РµСЂРёРЅР±СѓСЂРі',
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

/// РџРѕРґСЃРєР°Р·РєР° РґР»СЏ РїРѕРёСЃРєР°
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

/// РўРёРї РїРѕРґСЃРєР°Р·РєРё
enum SuggestionType {
  specialist,
  category,
  location,
  service,
}

/// РћРїС†РёРё СЃРѕСЂС‚РёСЂРѕРІРєРё СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ
enum SpecialistSortOption {
  rating,
  price,
  popularity,
  distance,
}

