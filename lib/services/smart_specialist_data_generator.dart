import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/smart_specialist.dart';
import 'package:flutter/foundation.dart';
import '../models/specialist.dart';
import 'package:flutter/foundation.dart';

/// Р“РµРЅРµСЂР°С‚РѕСЂ С‚РµСЃС‚РѕРІС‹С… РґР°РЅРЅС‹С… РґР»СЏ СѓРјРЅРѕРіРѕ РїРѕРёСЃРєР°
class SmartSpecialistDataGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ Рё СЃРѕС…СЂР°РЅРёС‚СЊ С‚РµСЃС‚РѕРІС‹С… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ
  Future<void> generateTestSpecialists({int count = 20}) async {
    try {
      final specialists = <SmartSpecialist>[];

      // РљР°С‚РµРіРѕСЂРёРё РґР»СЏ РіРµРЅРµСЂР°С†РёРё
      final categories = [
        SpecialistCategory.host,
        SpecialistCategory.photographer,
        SpecialistCategory.dj,
        SpecialistCategory.musician,
        SpecialistCategory.decorator,
        SpecialistCategory.florist,
        SpecialistCategory.animator,
        SpecialistCategory.makeup,
        SpecialistCategory.hairstylist,
        SpecialistCategory.caterer,
      ];

      // Р“РѕСЂРѕРґР°
      final cities = [
        'РњРѕСЃРєРІР°',
        'РЎР°РЅРєС‚-РџРµС‚РµСЂР±СѓСЂРі',
        'Р•РєР°С‚РµСЂРёРЅР±СѓСЂРі',
        'РќРѕРІРѕСЃРёР±РёСЂСЃРє',
        'РљР°Р·Р°РЅСЊ',
        'РќРёР¶РЅРёР№ РќРѕРІРіРѕСЂРѕРґ',
        'Р§РµР»СЏР±РёРЅСЃРє',
        'РЎР°РјР°СЂР°',
        'РћРјСЃРє',
        'Р РѕСЃС‚РѕРІ-РЅР°-Р”РѕРЅСѓ',
      ];

      // РЎС‚РёР»Рё
      final allStyles = [
        'РєР»Р°СЃСЃРёРєР°',
        'СЃРѕРІСЂРµРјРµРЅРЅС‹Р№',
        'СЋРјРѕСЂ',
        'РёРЅС‚РµСЂР°РєС‚РёРІ',
        'СЂРѕРјР°РЅС‚РёС‡РЅС‹Р№',
        'РѕС„РёС†РёР°Р»СЊРЅС‹Р№',
        'РєСЂРµР°С‚РёРІРЅС‹Р№',
        'СЌР»РµРіР°РЅС‚РЅС‹Р№',
        'РІРµСЃРµР»С‹Р№',
        'СЃС‚РёР»СЊРЅС‹Р№',
      ];

      // РРјРµРЅР°
      final firstNames = [
        'РђРЅРґСЂРµР№',
        'РђР»РµРєСЃР°РЅРґСЂ',
        'Р”РјРёС‚СЂРёР№',
        'РњР°РєСЃРёРј',
        'РЎРµСЂРіРµР№',
        'РђРЅРЅР°',
        'Р•Р»РµРЅР°',
        'РћР»СЊРіР°',
        'РўР°С‚СЊСЏРЅР°',
        'РќР°С‚Р°Р»СЊСЏ',
        'РРІР°РЅ',
        'РњРёС…Р°РёР»',
        'Р’Р»Р°РґРёРјРёСЂ',
        'РђР»РµРєСЃРµР№',
        'РќРёРєРѕР»Р°Р№',
        'РњР°СЂРёСЏ',
        'РЎРІРµС‚Р»Р°РЅР°',
        'Р®Р»РёСЏ',
        'РСЂРёРЅР°',
        'Р•РєР°С‚РµСЂРёРЅР°',
      ];

      final lastNames = [
        'РРІР°РЅРѕРІ',
        'РџРµС‚СЂРѕРІ',
        'РЎРёРґРѕСЂРѕРІ',
        'РљРѕР·Р»РѕРІ',
        'РќРѕРІРёРєРѕРІ',
        'РњРѕСЂРѕР·РѕРІ',
        'РџРµС‚СѓС…РѕРІ',
        'Р’РѕР»РєРѕРІ',
        'РЎРѕР»РѕРІСЊРµРІ',
        'Р’Р°СЃРёР»СЊРµРІ',
        'Р—Р°Р№С†РµРІ',
        'РџР°РІР»РѕРІ',
        'РЎРµРјРµРЅРѕРІ',
        'Р“РѕР»СѓР±РµРІ',
        'Р’РёРЅРѕРіСЂР°РґРѕРІ',
        'Р‘РѕРіРґР°РЅРѕРІ',
        'Р’РѕСЂРѕР±СЊРµРІ',
        'Р¤РµРґРѕСЂРѕРІ',
        'РњРёС…Р°Р№Р»РѕРІ',
        'Р‘РµР»РѕРІ',
      ];

      for (var i = 0; i < count; i++) {
        final category = categories[_random.nextInt(categories.length)];
        final firstName = firstNames[_random.nextInt(firstNames.length)];
        final lastName = lastNames[_random.nextInt(lastNames.length)];
        final city = cities[_random.nextInt(cities.length)];

        // Р“РµРЅРµСЂРёСЂСѓРµРј СЃС‚РёР»Рё РґР»СЏ СЃРїРµС†РёР°Р»РёСЃС‚Р°
        final specialistStyles = <String>[];
        final numStyles = _random.nextInt(3) + 1; // 1-3 СЃС‚РёР»СЏ
        for (var j = 0; j < numStyles; j++) {
          final style = allStyles[_random.nextInt(allStyles.length)];
          if (!specialistStyles.contains(style)) {
            specialistStyles.add(style);
          }
        }

        // Р“РµРЅРµСЂРёСЂСѓРµРј С†РµРЅС‹ РІ Р·Р°РІРёСЃРёРјРѕСЃС‚Рё РѕС‚ РєР°С‚РµРіРѕСЂРёРё
        final priceRange = _getPriceRangeForCategory(category);
        final price =
            priceRange['min'] + _random.nextDouble() * (priceRange['max'] - priceRange['min']);

        // Р“РµРЅРµСЂРёСЂСѓРµРј СЂРµР№С‚РёРЅРі
        final rating = 3.0 + _random.nextDouble() * 2.0; // 3.0-5.0

        // Р“РµРЅРµСЂРёСЂСѓРµРј РѕРїС‹С‚
        final experienceYears = _random.nextInt(15) + 1; // 1-15 Р»РµС‚

        // Р“РµРЅРµСЂРёСЂСѓРµРј РєРѕР»РёС‡РµСЃС‚РІРѕ РѕС‚Р·С‹РІРѕРІ
        final reviewCount = _random.nextInt(100) + 1; // 1-100 РѕС‚Р·С‹РІРѕРІ

        // Р“РµРЅРµСЂРёСЂСѓРµРј РґРѕСЃС‚СѓРїРЅС‹Рµ РґР°С‚С‹
        final availableDates = <DateTime>[];
        final today = DateTime.now();
        for (var j = 0; j < 10; j++) {
          final date = today.add(Duration(days: _random.nextInt(90) + 1));
          availableDates.add(date);
        }

        // Р“РµРЅРµСЂРёСЂСѓРµРј Р·Р°РЅСЏС‚С‹Рµ РґР°С‚С‹
        final busyDates = <DateTime>[];
        for (var j = 0; j < _random.nextInt(5); j++) {
          final date = today.add(Duration(days: _random.nextInt(30) + 1));
          busyDates.add(date);
        }

        final specialist = SmartSpecialist(
          id: 'specialist_${DateTime.now().millisecondsSinceEpoch}_$i',
          userId: 'user_${_random.nextInt(1000)}',
          name: '$firstName $lastName',
          description: _generateDescription(category, firstName),
          bio: _generateBio(category, firstName, experienceYears),
          category: category,
          categories: [category],
          subcategories: _generateSubcategories(category),
          experienceLevel: _getExperienceLevel(experienceYears),
          yearsOfExperience: experienceYears,
          hourlyRate: price / 8, // РџСЂРµРґРїРѕР»Р°РіР°РµРј 8-С‡Р°СЃРѕРІРѕР№ СЂР°Р±РѕС‡РёР№ РґРµРЅСЊ
          price: price,
          priceFrom: price * 0.8,
          priceTo: price * 1.2,
          rating: rating,
          reviewCount: reviewCount,
          city: city,
          location: city,
          isAvailable: _random.nextBool(),
          isVerified: _random.nextDouble() > 0.3, // 70% РІРµСЂРёС„РёС†РёСЂРѕРІР°РЅС‹
          portfolioImages: _generatePortfolioImages(category),
          portfolioVideos: _generatePortfolioVideos(category),
          services: _generateServices(category),
          equipment: _generateEquipment(category),
          languages: _generateLanguages(),
          workingHours: _generateWorkingHours(),
          availableDates: availableDates,
          busyDates: busyDates,
          createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
          updatedAt: DateTime.now(),
          lastActiveAt: DateTime.now().subtract(Duration(hours: _random.nextInt(24))),
          // РќРѕРІС‹Рµ РїРѕР»СЏ РґР»СЏ РёРЅС‚РµР»Р»РµРєС‚СѓР°Р»СЊРЅРѕРіРѕ РїРѕРёСЃРєР°
          styles: specialistStyles,
          keywords: _generateKeywords(category, city, specialistStyles),
          reputationScore: _calculateReputationScore(rating, reviewCount, experienceYears),
          searchTags: _generateSearchTags(category, city, specialistStyles),
          eventTypes: _generateEventTypes(category),
          specializations: _generateSpecializations(category),
          workingStyle: _generateWorkingStyle(category),
          personalityTraits: _generatePersonalityTraits(rating, experienceYears),
          availabilityPattern: _generateAvailabilityPattern(),
          clientPreferences: _generateClientPreferences(price),
          performanceMetrics: _generatePerformanceMetrics(rating, reviewCount),
          recommendationFactors: _generateRecommendationFactors(
            rating,
            reviewCount,
            experienceYears,
          ),
        );

        specialists.add(specialist);
      }

      // РЎРѕС…СЂР°РЅСЏРµРј РІ Firestore
      final batch = _firestore.batch();
      for (final specialist in specialists) {
        final docRef = _firestore.collection('specialists').doc(specialist.id);
        batch.set(docRef, specialist.toMap());
      }

      await batch.commit();

      debugPrint(
        'вњ… РЎРіРµРЅРµСЂРёСЂРѕРІР°РЅРѕ Рё СЃРѕС…СЂР°РЅРµРЅРѕ ${specialists.length} С‚РµСЃС‚РѕРІС‹С… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ',
      );
    } catch (e) {
      debugPrint('вќЊ РћС€РёР±РєР° РіРµРЅРµСЂР°С†РёРё С‚РµСЃС‚РѕРІС‹С… РґР°РЅРЅС‹С…: $e');
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РґРёР°РїР°Р·РѕРЅ С†РµРЅ РґР»СЏ РєР°С‚РµРіРѕСЂРёРё
  Map<String, double> _getPriceRangeForCategory(SpecialistCategory category) {
    switch (category) {
      case SpecialistCategory.host:
        return {'min': 15000, 'max': 50000};
      case SpecialistCategory.photographer:
        return {'min': 10000, 'max': 40000};
      case SpecialistCategory.dj:
        return {'min': 8000, 'max': 30000};
      case SpecialistCategory.musician:
        return {'min': 12000, 'max': 35000};
      case SpecialistCategory.decorator:
        return {'min': 5000, 'max': 25000};
      case SpecialistCategory.florist:
        return {'min': 3000, 'max': 15000};
      case SpecialistCategory.animator:
        return {'min': 4000, 'max': 20000};
      case SpecialistCategory.makeup:
        return {'min': 2000, 'max': 12000};
      case SpecialistCategory.hairstylist:
        return {'min': 1500, 'max': 10000};
      case SpecialistCategory.caterer:
        return {'min': 8000, 'max': 30000};
      default:
        return {'min': 5000, 'max': 25000};
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СѓСЂРѕРІРµРЅСЊ РѕРїС‹С‚Р°
  ExperienceLevel _getExperienceLevel(int years) {
    if (years < 2) return ExperienceLevel.beginner;
    if (years < 5) return ExperienceLevel.intermediate;
    if (years < 10) return ExperienceLevel.advanced;
    return ExperienceLevel.expert;
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РѕРїРёСЃР°РЅРёРµ
  String _generateDescription(SpecialistCategory category, String firstName) {
    final descriptions = {
      SpecialistCategory.host: [
        'РћРїС‹С‚РЅС‹Р№ РІРµРґСѓС‰РёР№ СЃ РѕС‚Р»РёС‡РЅС‹Рј С‡СѓРІСЃС‚РІРѕРј СЋРјРѕСЂР°',
        'РџСЂРѕС„РµСЃСЃРёРѕРЅР°Р»СЊРЅС‹Р№ РІРµРґСѓС‰РёР№ РјРµСЂРѕРїСЂРёСЏС‚РёР№',
        'РљСЂРµР°С‚РёРІРЅС‹Р№ РІРµРґСѓС‰РёР№ СЃ РёРЅРґРёРІРёРґСѓР°Р»СЊРЅС‹Рј РїРѕРґС…РѕРґРѕРј',
        'Р’РµРґСѓС‰РёР№ СЃ РјРЅРѕРіРѕР»РµС‚РЅРёРј РѕРїС‹С‚РѕРј СЂР°Р±РѕС‚С‹',
      ],
      SpecialistCategory.photographer: [
        'Р¤РѕС‚РѕРіСЂР°С„ СЃ С…СѓРґРѕР¶РµСЃС‚РІРµРЅРЅС‹Рј РІРёРґРµРЅРёРµРј',
        'РџСЂРѕС„РµСЃСЃРёРѕРЅР°Р»СЊРЅС‹Р№ С„РѕС‚РѕРіСЂР°С„ СЃ СЃРѕРІСЂРµРјРµРЅРЅС‹Рј СЃС‚РёР»РµРј',
        'РљСЂРµР°С‚РёРІРЅС‹Р№ С„РѕС‚РѕРіСЂР°С„ СЃ РёРЅРґРёРІРёРґСѓР°Р»СЊРЅС‹Рј РїРѕРґС…РѕРґРѕРј',
        'Р¤РѕС‚РѕРіСЂР°С„ СЃ РјРЅРѕРіРѕР»РµС‚РЅРёРј РѕРїС‹С‚РѕРј',
      ],
      SpecialistCategory.dj: [
        'DJ СЃ РѕС‚Р»РёС‡РЅС‹Рј РјСѓР·С‹РєР°Р»СЊРЅС‹Рј РІРєСѓСЃРѕРј',
        'РџСЂРѕС„РµСЃСЃРёРѕРЅР°Р»СЊРЅС‹Р№ РґРёРґР¶РµР№ СЃ СЃРѕРІСЂРµРјРµРЅРЅС‹Рј Р·РІСѓРєРѕРј',
        'DJ СЃ РјРЅРѕРіРѕР»РµС‚РЅРёРј РѕРїС‹С‚РѕРј СЂР°Р±РѕС‚С‹',
        'РљСЂРµР°С‚РёРІРЅС‹Р№ РґРёРґР¶РµР№ СЃ РёРЅРґРёРІРёРґСѓР°Р»СЊРЅС‹Рј СЃС‚РёР»РµРј',
      ],
    };

    final categoryDescriptions = descriptions[category] ?? ['РџСЂРѕС„РµСЃСЃРёРѕРЅР°Р»СЊРЅС‹Р№ СЃРїРµС†РёР°Р»РёСЃС‚'];
    return categoryDescriptions[_random.nextInt(categoryDescriptions.length)];
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ Р±РёРѕРіСЂР°С„РёСЋ
  String _generateBio(
    SpecialistCategory category,
    String firstName,
    int experienceYears,
  ) =>
      'РџСЂРёРІРµС‚! РњРµРЅСЏ Р·РѕРІСѓС‚ $firstName, Рё СЏ СЂР°Р±РѕС‚Р°СЋ РІ СЃС„РµСЂРµ ${category.displayName.toLowerCase()} СѓР¶Рµ $experienceYears Р»РµС‚. '
      'Р›СЋР±Р»СЋ СЃРѕР·РґР°РІР°С‚СЊ РЅРµР·Р°Р±С‹РІР°РµРјС‹Рµ РјРѕРјРµРЅС‚С‹ РґР»СЏ РјРѕРёС… РєР»РёРµРЅС‚РѕРІ. '
      'РРјРµСЋ РѕРїС‹С‚ СЂР°Р±РѕС‚С‹ СЃ СЂР°Р·Р»РёС‡РЅС‹РјРё С‚РёРїР°РјРё РјРµСЂРѕРїСЂРёСЏС‚РёР№ Рё РІСЃРµРіРґР° РЅР°С…РѕР¶Сѓ РёРЅРґРёРІРёРґСѓР°Р»СЊРЅС‹Р№ РїРѕРґС…РѕРґ Рє РєР°Р¶РґРѕРјСѓ РєР»РёРµРЅС‚Сѓ.';

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РїРѕРґРєР°С‚РµРіРѕСЂРёРё
  List<String> _generateSubcategories(SpecialistCategory category) {
    final subcategories = {
      SpecialistCategory.host: ['СЃРІР°РґСЊР±С‹', 'РєРѕСЂРїРѕСЂР°С‚РёРІС‹', 'РґРЅРё СЂРѕР¶РґРµРЅРёСЏ'],
      SpecialistCategory.photographer: [
        'СЃРІР°РґРµР±РЅР°СЏ СЃСЉРµРјРєР°',
        'РїРѕСЂС‚СЂРµС‚РЅР°СЏ СЃСЉРµРјРєР°',
        'СЂРµРїРѕСЂС‚Р°Р¶РЅР°СЏ СЃСЉРµРјРєР°',
      ],
      SpecialistCategory.dj: ['СЌР»РµРєС‚СЂРѕРЅРЅР°СЏ РјСѓР·С‹РєР°', 'РїРѕРї-РјСѓР·С‹РєР°', 'СЂРѕРє-РјСѓР·С‹РєР°'],
      SpecialistCategory.musician: [
        'Р¶РёРІР°СЏ РјСѓР·С‹РєР°',
        'РєР°РІРµСЂС‹',
        'Р°РІС‚РѕСЂСЃРєРёРµ РєРѕРјРїРѕР·РёС†РёРё',
      ],
    };

    return subcategories[category] ?? ['СѓСЃР»СѓРіРё'];
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РёР·РѕР±СЂР°Р¶РµРЅРёСЏ РїРѕСЂС‚С„РѕР»РёРѕ
  List<String> _generatePortfolioImages(SpecialistCategory category) {
    final count = _random.nextInt(5) + 3; // 3-7 РёР·РѕР±СЂР°Р¶РµРЅРёР№
    final images = <String>[];

    for (var i = 0; i < count; i++) {
      images.add('https://picsum.photos/400/300?random=${_random.nextInt(1000)}');
    }

    return images;
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РІРёРґРµРѕ РїРѕСЂС‚С„РѕР»РёРѕ
  List<String> _generatePortfolioVideos(SpecialistCategory category) {
    if (_random.nextBool()) {
      return [
        'https://example.com/video1.mp4',
        'https://example.com/video2.mp4',
      ];
    }
    return [];
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ СѓСЃР»СѓРіРё
  List<String> _generateServices(SpecialistCategory category) {
    final services = {
      SpecialistCategory.host: [
        'РІРµРґСѓС‰РёР№ РјРµСЂРѕРїСЂРёСЏС‚РёСЏ',
        'СЂР°Р·РІР»РµРєР°С‚РµР»СЊРЅР°СЏ РїСЂРѕРіСЂР°РјРјР°',
        'РёРіСЂС‹ Рё РєРѕРЅРєСѓСЂСЃС‹',
      ],
      SpecialistCategory.photographer: [
        'С„РѕС‚РѕСЃСЉРµРјРєР°',
        'РѕР±СЂР°Р±РѕС‚РєР° С„РѕС‚Рѕ',
        'РїРµС‡Р°С‚СЊ С„РѕС‚РѕРіСЂР°С„РёР№',
      ],
      SpecialistCategory.dj: [
        'РјСѓР·С‹РєР°Р»СЊРЅРѕРµ СЃРѕРїСЂРѕРІРѕР¶РґРµРЅРёРµ',
        'Р·РІСѓРєРѕРІРѕРµ РѕР±РѕСЂСѓРґРѕРІР°РЅРёРµ',
        'СЃРІРµС‚РѕРІРѕРµ С€РѕСѓ',
      ],
      SpecialistCategory.musician: [
        'Р¶РёРІРѕРµ РІС‹СЃС‚СѓРїР»РµРЅРёРµ',
        'РјСѓР·С‹РєР°Р»СЊРЅРѕРµ СЃРѕРїСЂРѕРІРѕР¶РґРµРЅРёРµ',
        'РёРЅС‚РµСЂР°РєС‚РёРІ СЃ РіРѕСЃС‚СЏРјРё',
      ],
    };

    return services[category] ?? ['СѓСЃР»СѓРіРё'];
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РѕР±РѕСЂСѓРґРѕРІР°РЅРёРµ
  List<String> _generateEquipment(SpecialistCategory category) {
    final equipment = {
      SpecialistCategory.host: [
        'РјРёРєСЂРѕС„РѕРЅ',
        'РєРѕР»РѕРЅРєРё',
        'РјСѓР·С‹РєР°Р»СЊРЅРѕРµ РѕР±РѕСЂСѓРґРѕРІР°РЅРёРµ',
      ],
      SpecialistCategory.photographer: [
        'РїСЂРѕС„РµСЃСЃРёРѕРЅР°Р»СЊРЅР°СЏ РєР°РјРµСЂР°',
        'РѕР±СЉРµРєС‚РёРІС‹',
        'РѕСЃРІРµС‰РµРЅРёРµ',
      ],
      SpecialistCategory.dj: ['DJ-РїСѓР»СЊС‚', 'РєРѕР»РѕРЅРєРё', 'РјРёРєСЂРѕС„РѕРЅС‹'],
      SpecialistCategory.musician: [
        'РјСѓР·С‹РєР°Р»СЊРЅС‹Рµ РёРЅСЃС‚СЂСѓРјРµРЅС‚С‹',
        'СѓСЃРёР»РёС‚РµР»Рё',
        'РјРёРєСЂРѕС„РѕРЅС‹',
      ],
    };

    return equipment[category] ?? ['РѕР±РѕСЂСѓРґРѕРІР°РЅРёРµ'];
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ СЏР·С‹РєРё
  List<String> _generateLanguages() {
    final languages = ['Р СѓСЃСЃРєРёР№', 'РђРЅРіР»РёР№СЃРєРёР№'];
    if (_random.nextBool()) {
      languages.add('РќРµРјРµС†РєРёР№');
    }
    return languages;
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ СЂР°Р±РѕС‡РёРµ С‡Р°СЃС‹
  Map<String, String> _generateWorkingHours() => {
        'monday': '09:00-18:00',
        'tuesday': '09:00-18:00',
        'wednesday': '09:00-18:00',
        'thursday': '09:00-18:00',
        'friday': '09:00-18:00',
        'saturday': '10:00-16:00',
        'sunday': 'Р’С‹С…РѕРґРЅРѕР№',
      };

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РєР»СЋС‡РµРІС‹Рµ СЃР»РѕРІР°
  List<String> _generateKeywords(
    SpecialistCategory category,
    String city,
    List<String> styles,
  ) {
    final keywords = <String>[];

    keywords.add(category.displayName.toLowerCase());
    keywords.add(city.toLowerCase());
    keywords.addAll(styles);

    // Р”РѕР±Р°РІР»СЏРµРј РґРѕРїРѕР»РЅРёС‚РµР»СЊРЅС‹Рµ РєР»СЋС‡РµРІС‹Рµ СЃР»РѕРІР°
    final additionalKeywords = [
      'РїСЂРѕС„РµСЃСЃРёРѕРЅР°Р»СЊРЅС‹Р№',
      'РѕРїС‹С‚РЅС‹Р№',
      'РєР°С‡РµСЃС‚РІРµРЅРЅС‹Р№',
      'РЅР°РґРµР¶РЅС‹Р№',
    ];
    keywords.addAll(additionalKeywords);

    return keywords;
  }

  /// Р’С‹С‡РёСЃР»РёС‚СЊ Р±Р°Р»Р» СЂРµРїСѓС‚Р°С†РёРё
  int _calculateReputationScore(
    double rating,
    int reviewCount,
    int experienceYears,
  ) {
    var score = 0;

    // Р‘Р°Р·РѕРІС‹Р№ Р±Р°Р»Р» Р·Р° СЂРµР№С‚РёРЅРі
    score += (rating * 10).round();

    // Р‘РѕРЅСѓСЃ Р·Р° РєРѕР»РёС‡РµСЃС‚РІРѕ РѕС‚Р·С‹РІРѕРІ
    if (reviewCount > 10) score += 10;
    if (reviewCount > 50) score += 10;
    if (reviewCount > 100) score += 10;

    // Р‘РѕРЅСѓСЃ Р·Р° РѕРїС‹С‚
    if (experienceYears > 5) score += 10;
    if (experienceYears > 10) score += 10;

    return score.clamp(0, 100);
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ С‚РµРіРё РґР»СЏ РїРѕРёСЃРєР°
  List<String> _generateSearchTags(
    SpecialistCategory category,
    String city,
    List<String> styles,
  ) {
    final tags = <String>[];

    tags.add(category.displayName);
    tags.add(city);
    tags.addAll(styles);

    return tags;
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ С‚РёРїС‹ РјРµСЂРѕРїСЂРёСЏС‚РёР№
  List<String> _generateEventTypes(SpecialistCategory category) {
    final eventTypes = {
      SpecialistCategory.host: [
        'СЃРІР°РґСЊР±Р°',
        'РєРѕСЂРїРѕСЂР°С‚РёРІ',
        'РґРµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ',
        'СЋР±РёР»РµР№',
      ],
      SpecialistCategory.photographer: [
        'СЃРІР°РґСЊР±Р°',
        'С„РѕС‚РѕСЃРµСЃСЃРёСЏ',
        'РєРѕСЂРїРѕСЂР°С‚РёРІ',
        'РґРµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ',
      ],
      SpecialistCategory.dj: [
        'СЃРІР°РґСЊР±Р°',
        'РєРѕСЂРїРѕСЂР°С‚РёРІ',
        'РґРµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ',
        'РІРµС‡РµСЂРёРЅРєР°',
      ],
      SpecialistCategory.musician: [
        'СЃРІР°РґСЊР±Р°',
        'РєРѕСЂРїРѕСЂР°С‚РёРІ',
        'РґРµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ',
        'РєРѕРЅС†РµСЂС‚',
      ],
    };

    return eventTypes[category] ?? ['РјРµСЂРѕРїСЂРёСЏС‚РёРµ'];
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ СЃРїРµС†РёР°Р»РёР·Р°С†РёРё
  List<String> _generateSpecializations(SpecialistCategory category) {
    final specializations = <String>[];

    specializations.add(category.displayName);

    if (_random.nextBool()) {
      specializations.add('РѕРїС‹С‚РЅС‹Р№');
    }

    return specializations;
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ СЃС‚РёР»СЊ СЂР°Р±РѕС‚С‹
  Map<String, dynamic> _generateWorkingStyle(SpecialistCategory category) => {
        'communication': _random.nextBool() ? 'РѕС‚Р»РёС‡РЅР°СЏ' : 'С…РѕСЂРѕС€Р°СЏ',
        'punctuality': 0.8 + _random.nextDouble() * 0.2,
        'flexibility': _random.nextBool() ? 'РІС‹СЃРѕРєР°СЏ' : 'СЃСЂРµРґРЅСЏСЏ',
        'creativity': _random.nextBool() ? 'РІС‹СЃРѕРєР°СЏ' : 'СЃСЂРµРґРЅСЏСЏ',
      };

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ С‡РµСЂС‚С‹ С…Р°СЂР°РєС‚РµСЂР°
  List<String> _generatePersonalityTraits(double rating, int experienceYears) {
    final traits = <String>[];

    if (rating > 4.5) {
      traits.add('РїСЂРѕС„РµСЃСЃРёРѕРЅР°Р»СЊРЅС‹Р№');
    }
    if (experienceYears > 5) {
      traits.add('РѕРїС‹С‚РЅС‹Р№');
    }
    if (_random.nextBool()) {
      traits.add('РєСЂРµР°С‚РёРІРЅС‹Р№');
    }
    if (_random.nextBool()) {
      traits.add('РЅР°РґРµР¶РЅС‹Р№');
    }

    return traits;
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РїР°С‚С‚РµСЂРЅ РґРѕСЃС‚СѓРїРЅРѕСЃС‚Рё
  Map<String, dynamic> _generateAvailabilityPattern() => {
        'weekdays': true,
        'weekends': _random.nextBool(),
        'evenings': _random.nextBool(),
        'flexible': _random.nextBool(),
      };

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РїСЂРµРґРїРѕС‡С‚РµРЅРёСЏ РєР»РёРµРЅС‚РѕРІ
  Map<String, dynamic> _generateClientPreferences(double price) {
    String budgetRange;
    if (price < 15000) {
      budgetRange = 'Р±СЋРґР¶РµС‚РЅС‹Р№';
    } else if (price < 30000) {
      budgetRange = 'СЃСЂРµРґРЅРёР№';
    } else {
      budgetRange = 'РїСЂРµРјРёСѓРј';
    }

    return {
      'budgetRange': budgetRange,
      'eventSize': _random.nextBool() ? 'Р»СЋР±РѕР№' : 'РјР°Р»С‹Р№-СЃСЂРµРґРЅРёР№',
      'style': _random.nextBool() ? 'РїСЂРµРјРёСѓРј' : 'СЃС‚Р°РЅРґР°СЂС‚РЅС‹Р№',
    };
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РјРµС‚СЂРёРєРё РїСЂРѕРёР·РІРѕРґРёС‚РµР»СЊРЅРѕСЃС‚Рё
  Map<String, dynamic> _generatePerformanceMetrics(
    double rating,
    int reviewCount,
  ) =>
      {
        'responseTime': _random.nextBool() ? 'Р±С‹СЃС‚СЂС‹Р№' : 'СЃСЂРµРґРЅРёР№',
        'completionRate': 0.9 + _random.nextDouble() * 0.1,
        'cancellationRate': _random.nextDouble() * 0.1,
        'clientSatisfaction': rating,
      };

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ С„Р°РєС‚РѕСЂС‹ СЂРµРєРѕРјРµРЅРґР°С†РёР№
  Map<String, dynamic> _generateRecommendationFactors(
    double rating,
    int reviewCount,
    int experienceYears,
  ) =>
      {
        'popularity': reviewCount,
        'quality': rating,
        'experience': experienceYears,
        'availability': true,
        'verification': _random.nextBool(),
      };
}

