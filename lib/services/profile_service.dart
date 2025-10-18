import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/customer_profile.dart';
import 'package:flutter/foundation.dart';
import '../models/organizer_profile.dart';
import 'package:flutter/foundation.dart';
import '../models/specialist_profile.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'package:flutter/foundation.dart';
import 'organizer_service.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ РґР»СЏ СѓРїСЂР°РІР»РµРЅРёСЏ РїСЂРѕС„РёР»СЏРјРё РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OrganizerService _organizerService = OrganizerService();

  /// РџРѕР»СѓС‡РёС‚СЊ РїСЂРѕС„РёР»СЊ Р·Р°РєР°Р·С‡РёРєР°
  Future<CustomerProfile?> getCustomerProfile(String userId) async {
    try {
      final doc = await _firestore.collection('customer_profiles').doc(userId).get();

      if (doc.exists) {
        return CustomerProfile.fromDocument(doc);
      }
      return null;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїСЂРѕС„РёР»СЏ Р·Р°РєР°Р·С‡РёРєР°: $e');
      return null;
    }
  }

  /// РЎРѕР·РґР°С‚СЊ РёР»Рё РѕР±РЅРѕРІРёС‚СЊ РїСЂРѕС„РёР»СЊ Р·Р°РєР°Р·С‡РёРєР°
  Future<void> createOrUpdateCustomerProfile(CustomerProfile profile) async {
    try {
      await _firestore.collection('customer_profiles').doc(profile.userId).set(profile.toMap());
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕС…СЂР°РЅРµРЅРёСЏ РїСЂРѕС„РёР»СЏ Р·Р°РєР°Р·С‡РёРєР°: $e');
      throw Exception('РћС€РёР±РєР° СЃРѕС…СЂР°РЅРµРЅРёСЏ РїСЂРѕС„РёР»СЏ: $e');
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РїСЂРѕС„РёР»СЊ СЃРїРµС†РёР°Р»РёСЃС‚Р°
  Future<SpecialistProfile?> getSpecialistProfile(String userId) async {
    try {
      final doc = await _firestore.collection('specialist_profiles').doc(userId).get();

      if (doc.exists) {
        return SpecialistProfile.fromDocument(doc);
      }
      return null;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїСЂРѕС„РёР»СЏ СЃРїРµС†РёР°Р»РёСЃС‚Р°: $e');
      return null;
    }
  }

  /// РЎРѕР·РґР°С‚СЊ РёР»Рё РѕР±РЅРѕРІРёС‚СЊ РїСЂРѕС„РёР»СЊ СЃРїРµС†РёР°Р»РёСЃС‚Р°
  Future<void> createOrUpdateSpecialistProfile(
    SpecialistProfile profile,
  ) async {
    try {
      // РћР±РЅРѕРІР»СЏРµРј РІСЂРµРјСЏ РїРѕСЃР»РµРґРЅРµРіРѕ РёР·РјРµРЅРµРЅРёСЏ
      final updatedProfile = profile.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('specialist_profiles')
          .doc(profile.userId)
          .set(updatedProfile.toMap(), SetOptions(merge: true));
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕС…СЂР°РЅРµРЅРёСЏ РїСЂРѕС„РёР»СЏ СЃРїРµС†РёР°Р»РёСЃС‚Р°: $e');
      throw Exception('РћС€РёР±РєР° СЃРѕС…СЂР°РЅРµРЅРёСЏ РїСЂРѕС„РёР»СЏ: $e');
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РїСЂРѕС„РёР»СЊ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ (Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё РѕРїСЂРµРґРµР»СЏРµС‚ С‚РёРї)
  Future<dynamic> getUserProfile(String userId, UserRole role) async {
    switch (role) {
      case UserRole.customer:
        return getCustomerProfile(userId);
      case UserRole.specialist:
        return getSpecialistProfile(userId);
      case UserRole.organizer:
        return _organizerService.getOrganizerProfileByUserId(userId);
      case UserRole.moderator:
        return null;
      case UserRole.guest:
        return null;
      case UserRole.admin:
        return null;
    }
  }

  /// РЎРѕР·РґР°С‚СЊ РёР»Рё РѕР±РЅРѕРІРёС‚СЊ РїСЂРѕС„РёР»СЊ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<void> createOrUpdateUserProfile(profile, UserRole role) async {
    switch (role) {
      case UserRole.customer:
        if (profile is CustomerProfile) {
          await createOrUpdateCustomerProfile(profile);
        }
        break;
      case UserRole.specialist:
        if (profile is SpecialistProfile) {
          await createOrUpdateSpecialistProfile(profile);
        }
        break;
      case UserRole.organizer:
        if (profile is OrganizerProfile) {
          await _organizerService.createOrganizerProfile(profile);
        }
        break;
      case UserRole.moderator:
        // РњРѕРґРµСЂР°С‚РѕСЂС‹ РЅРµ РёРјРµСЋС‚ СЃРїРµС†РёР°Р»СЊРЅРѕРіРѕ РїСЂРѕС„РёР»СЏ
        break;
      case UserRole.guest:
        throw Exception('Р“РѕСЃС‚Рё РЅРµ РјРѕРіСѓС‚ РёРјРµС‚СЊ РїСЂРѕС„РёР»Рё');
      case UserRole.admin:
        throw Exception('РђРґРјРёРЅС‹ РЅРµ РјРѕРіСѓС‚ РёРјРµС‚СЊ РїСЂРѕС„РёР»Рё');
    }
  }

  /// Р—Р°РіСЂСѓР·РёС‚СЊ С„РѕС‚Рѕ РїСЂРѕС„РёР»СЏ
  Future<String?> uploadProfilePhoto(String userId, String filePath) async {
    try {
      // Р’ СЂРµР°Р»СЊРЅРѕРј РїСЂРёР»РѕР¶РµРЅРёРё Р·РґРµСЃСЊ Р±С‹Р»Р° Р±С‹ Р·Р°РіСЂСѓР·РєР° РІ Firebase Storage
      // Р”Р»СЏ РґРµРјРѕРЅСЃС‚СЂР°С†РёРё РІРѕР·РІСЂР°С‰Р°РµРј С„РёРєС‚РёРІРЅС‹Р№ URL
      return 'https://example.com/profile_photos/$userId.jpg';
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё С„РѕС‚Рѕ: $e');
      return null;
    }
  }

  /// Р—Р°РіСЂСѓР·РёС‚СЊ СЌР»РµРјРµРЅС‚ РїРѕСЂС‚С„РѕР»РёРѕ
  Future<String?> uploadPortfolioItem(
    String userId,
    String filePath,
    String type,
  ) async {
    try {
      // Р’ СЂРµР°Р»СЊРЅРѕРј РїСЂРёР»РѕР¶РµРЅРёРё Р·РґРµСЃСЊ Р±С‹Р»Р° Р±С‹ Р·Р°РіСЂСѓР·РєР° РІ Firebase Storage
      // Р”Р»СЏ РґРµРјРѕРЅСЃС‚СЂР°С†РёРё РІРѕР·РІСЂР°С‰Р°РµРј С„РёРєС‚РёРІРЅС‹Р№ URL
      return 'https://example.com/portfolio/$userId/${DateTime.now().millisecondsSinceEpoch}.$type';
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё РїРѕСЂС‚С„РѕР»РёРѕ: $e');
      return null;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РІСЃРµС… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ РїРѕ РєР°С‚РµРіРѕСЂРёРё
  Future<List<SpecialistProfile>> getSpecialistsByCategory(
    SpecialistCategory category, {
    int limit = 20,
    bool onlyAvailable = true,
    bool onlyVerified = false,
  }) async {
    try {
      var query = _firestore
          .collection('specialist_profiles')
          .where('categories', arrayContains: category.name);

      if (onlyAvailable) {
        query = query.where('isAvailable', isEqualTo: true);
      }

      if (onlyVerified) {
        query = query.where('isVerified', isEqualTo: true);
      }

      final querySnapshot = await query.orderBy('rating', descending: true).limit(limit).get();

      return querySnapshot.docs.map(SpecialistProfile.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ РїРѕ РєР°С‚РµРіРѕСЂРёРё: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ РїРѕ РЅРµСЃРєРѕР»СЊРєРёРј РєР°С‚РµРіРѕСЂРёСЏРј
  Future<List<SpecialistProfile>> getSpecialistsByCategories(
    List<SpecialistCategory> categories, {
    int limit = 20,
    bool onlyAvailable = true,
    bool onlyVerified = false,
  }) async {
    try {
      var query = _firestore.collection('specialist_profiles').where(
            'categories',
            arrayContainsAny: categories.map((e) => e.name).toList(),
          );

      if (onlyAvailable) {
        query = query.where('isAvailable', isEqualTo: true);
      }

      if (onlyVerified) {
        query = query.where('isVerified', isEqualTo: true);
      }

      final querySnapshot = await query.orderBy('rating', descending: true).limit(limit).get();

      return querySnapshot.docs.map(SpecialistProfile.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ РїРѕ РєР°С‚РµРіРѕСЂРёСЏРј: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РїРѕРїСѓР»СЏСЂРЅС‹Рµ РєР°С‚РµРіРѕСЂРёРё СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ
  Future<List<Map<String, dynamic>>> getPopularCategories({
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('specialist_profiles')
          .where('isAvailable', isEqualTo: true)
          .get();

      final categoryCounts = <String, int>{};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final categories = List<String>.from(data['categories'] ?? []);

        for (final category in categories) {
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
      }

      final sortedCategories = categoryCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedCategories
          .take(limit)
          .map(
            (entry) => {
              'category': entry.key,
              'count': entry.value,
            },
          )
          .toList();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїРѕРїСѓР»СЏСЂРЅС‹С… РєР°С‚РµРіРѕСЂРёР№: $e');
      return [];
    }
  }

  /// РџРѕРёСЃРє СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ
  Future<List<SpecialistProfile>> searchSpecialists({
    String? query,
    List<SpecialistCategory>? categories,
    double? minRating,
    double? maxHourlyRate,
    String? location,
    bool? isAvailable,
    bool? isVerified,
    int? minExperienceYears,
    int? maxExperienceYears,
    List<String>? languages,
    List<String>? equipment,
    DateTime? availableDate,
  }) async {
    try {
      Query<Map<String, dynamic>> queryRef = _firestore.collection('specialist_profiles');

      // Р¤РёР»СЊС‚СЂ РїРѕ РґРѕСЃС‚СѓРїРЅРѕСЃС‚Рё
      if (isAvailable != null) {
        queryRef = queryRef.where('isAvailable', isEqualTo: isAvailable);
      }

      // Р¤РёР»СЊС‚СЂ РїРѕ РІРµСЂРёС„РёРєР°С†РёРё
      if (isVerified != null) {
        queryRef = queryRef.where('isVerified', isEqualTo: isVerified);
      }

      // Р¤РёР»СЊС‚СЂ РїРѕ РєР°С‚РµРіРѕСЂРёСЏРј
      if (categories != null && categories.isNotEmpty) {
        queryRef = queryRef.where(
          'categories',
          arrayContainsAny: categories.map((e) => e.name).toList(),
        );
      }

      // Р¤РёР»СЊС‚СЂ РїРѕ СЂРµР№С‚РёРЅРіСѓ
      if (minRating != null) {
        queryRef = queryRef.where('rating', isGreaterThanOrEqualTo: minRating);
      }

      // Р¤РёР»СЊС‚СЂ РїРѕ С†РµРЅРµ
      if (maxHourlyRate != null) {
        queryRef = queryRef.where('hourlyRate', isLessThanOrEqualTo: maxHourlyRate);
      }

      // Р¤РёР»СЊС‚СЂ РїРѕ РѕРїС‹С‚Сѓ
      if (minExperienceYears != null) {
        queryRef = queryRef.where(
          'experienceYears',
          isGreaterThanOrEqualTo: minExperienceYears,
        );
      }
      if (maxExperienceYears != null) {
        queryRef = queryRef.where(
          'experienceYears',
          isLessThanOrEqualTo: maxExperienceYears,
        );
      }

      // Р¤РёР»СЊС‚СЂ РїРѕ Р»РѕРєР°С†РёРё
      if (location != null && location.isNotEmpty) {
        queryRef = queryRef.where('location', isEqualTo: location);
      }

      // Р¤РёР»СЊС‚СЂ РїРѕ СЏР·С‹РєР°Рј
      if (languages != null && languages.isNotEmpty) {
        queryRef = queryRef.where('languages', arrayContainsAny: languages);
      }

      // Р¤РёР»СЊС‚СЂ РїРѕ РѕР±РѕСЂСѓРґРѕРІР°РЅРёСЋ
      if (equipment != null && equipment.isNotEmpty) {
        queryRef = queryRef.where('equipment', arrayContainsAny: equipment);
      }

      final querySnapshot = await queryRef.orderBy('rating', descending: true).limit(50).get();

      var specialists = querySnapshot.docs.map(SpecialistProfile.fromDocument).toList();

      // Р¤РёР»СЊС‚СЂ РїРѕ С‚РµРєСЃС‚РѕРІРѕРјСѓ Р·Р°РїСЂРѕСЃСѓ (РµСЃР»Рё СѓРєР°Р·Р°РЅ)
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        specialists = specialists
            .where(
              (specialist) =>
                  specialist.name?.toLowerCase().contains(lowerQuery) ??
                  false || specialist.bio?.toLowerCase().contains(lowerQuery) ??
                  false ||
                      specialist.services.any(
                        (service) => service.toLowerCase().contains(lowerQuery),
                      ) ||
                      specialist.categoryDisplayNames.any(
                        (category) => category.toLowerCase().contains(lowerQuery),
                      ) ||
                      specialist.languages.any(
                        (lang) => lang.toLowerCase().contains(lowerQuery),
                      ) ||
                      specialist.equipment.any(
                        (eq) => eq.toLowerCase().contains(lowerQuery),
                      ),
            )
            .toList();
      }

      // Р¤РёР»СЊС‚СЂ РїРѕ РґРѕСЃС‚СѓРїРЅРѕСЃС‚Рё РЅР° РґР°С‚Сѓ
      if (availableDate != null) {
        specialists = specialists
            .where(
              (specialist) =>
                  specialist.isAvailable &&
                  !specialist.busyDates.any(
                    (busyDate) =>
                        busyDate.year == availableDate.year &&
                        busyDate.month == availableDate.month &&
                        busyDate.day == availableDate.day,
                  ),
            )
            .toList();
      }

      return specialists;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕРёСЃРєР° СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ С‚РѕРї СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ
  Future<List<SpecialistProfile>> getTopSpecialists({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('specialist_profiles')
          .where('isVerified', isEqualTo: true)
          .orderBy('rating', descending: true)
          .orderBy('reviewCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map(SpecialistProfile.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С‚РѕРї СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ: $e');
      return [];
    }
  }

  /// РЈРґР°Р»РёС‚СЊ РїСЂРѕС„РёР»СЊ
  Future<void> deleteProfile(String userId, UserRole role) async {
    try {
      switch (role) {
        case UserRole.customer:
          await _firestore.collection('customer_profiles').doc(userId).delete();
          break;
        case UserRole.specialist:
          await _firestore.collection('specialist_profiles').doc(userId).delete();
          break;
        case UserRole.organizer:
          await _firestore.collection('customer_profiles').doc(userId).delete();
          break;
        case UserRole.moderator:
          throw Exception('РњРѕРґРµСЂР°С‚РѕСЂС‹ РЅРµ РјРѕРіСѓС‚ РёРјРµС‚СЊ РїСЂРѕС„РёР»Рё');
        case UserRole.guest:
          throw Exception('Р“РѕСЃС‚Рё РЅРµ РјРѕРіСѓС‚ РёРјРµС‚СЊ РїСЂРѕС„РёР»Рё');
        case UserRole.admin:
          throw Exception('РђРґРјРёРЅС‹ РЅРµ РјРѕРіСѓС‚ РёРјРµС‚СЊ РїСЂРѕС„РёР»Рё');
      }
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ РїСЂРѕС„РёР»СЏ: $e');
      throw Exception('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ РїСЂРѕС„РёР»СЏ: $e');
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃС‚Р°С‚РёСЃС‚РёРєСѓ РїСЂРѕС„РёР»СЏ
  Future<Map<String, dynamic>> getProfileStats(
    String userId,
    UserRole role,
  ) async {
    try {
      var stats = <String, dynamic>{};

      if (role == UserRole.specialist) {
        // РЎС‚Р°С‚РёСЃС‚РёРєР° РґР»СЏ СЃРїРµС†РёР°Р»РёСЃС‚Р°
        final bookingsQuery =
            await _firestore.collection('bookings').where('specialistId', isEqualTo: userId).get();

        final reviewsQuery =
            await _firestore.collection('reviews').where('specialistId', isEqualTo: userId).get();

        stats = {
          'totalBookings': bookingsQuery.docs.length,
          'completedBookings':
              bookingsQuery.docs.where((doc) => doc.data()['status'] == 'completed').length,
          'totalReviews': reviewsQuery.docs.length,
          'averageRating': reviewsQuery.docs.isNotEmpty
              ? reviewsQuery.docs
                      .map((doc) => doc.data()['rating'] as double)
                      .reduce((a, b) => a + b) /
                  reviewsQuery.docs.length
              : 0.0,
        };
      } else if (role == UserRole.customer) {
        // РЎС‚Р°С‚РёСЃС‚РёРєР° РґР»СЏ Р·Р°РєР°Р·С‡РёРєР°
        final bookingsQuery =
            await _firestore.collection('bookings').where('customerId', isEqualTo: userId).get();

        stats = {
          'totalBookings': bookingsQuery.docs.length,
          'completedBookings':
              bookingsQuery.docs.where((doc) => doc.data()['status'] == 'completed').length,
        };
      }

      return stats;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃС‚Р°С‚РёСЃС‚РёРєРё РїСЂРѕС„РёР»СЏ: $e');
      return {};
    }
  }

  /// РћР±РЅРѕРІРёС‚СЊ РґРѕСЃС‚СѓРїРЅРѕСЃС‚СЊ СЃРїРµС†РёР°Р»РёСЃС‚Р°
  Future<void> updateSpecialistAvailability(
    String userId,
    Map<String, dynamic> availability,
  ) async {
    try {
      await _firestore.collection('specialist_profiles').doc(userId).update({
        'availability': availability,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РґРѕСЃС‚СѓРїРЅРѕСЃС‚Рё: $e');
      throw Exception('РќРµ СѓРґР°Р»РѕСЃСЊ РѕР±РЅРѕРІРёС‚СЊ РґРѕСЃС‚СѓРїРЅРѕСЃС‚СЊ');
    }
  }

  /// Р”РѕР±Р°РІРёС‚СЊ Р·Р°РЅСЏС‚СѓСЋ РґР°С‚Сѓ
  Future<void> addBusyDate(String userId, DateTime date) async {
    try {
      final profile = await getSpecialistProfile(userId);
      if (profile != null) {
        final updatedProfile = profile.addBusyDate(date);
        await createOrUpdateSpecialistProfile(updatedProfile);
      }
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ Р·Р°РЅСЏС‚РѕР№ РґР°С‚С‹: $e');
      throw Exception('РќРµ СѓРґР°Р»РѕСЃСЊ РґРѕР±Р°РІРёС‚СЊ Р·Р°РЅСЏС‚СѓСЋ РґР°С‚Сѓ');
    }
  }

  /// РЈРґР°Р»РёС‚СЊ Р·Р°РЅСЏС‚СѓСЋ РґР°С‚Сѓ
  Future<void> removeBusyDate(String userId, DateTime date) async {
    try {
      final profile = await getSpecialistProfile(userId);
      if (profile != null) {
        final updatedProfile = profile.removeBusyDate(date);
        await createOrUpdateSpecialistProfile(updatedProfile);
      }
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ Р·Р°РЅСЏС‚РѕР№ РґР°С‚С‹: $e');
      throw Exception('РќРµ СѓРґР°Р»РѕСЃСЊ СѓРґР°Р»РёС‚СЊ Р·Р°РЅСЏС‚СѓСЋ РґР°С‚Сѓ');
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ Р·Р°РЅСЏС‚С‹Рµ РґР°С‚С‹ СЃРїРµС†РёР°Р»РёСЃС‚Р°
  Future<List<DateTime>> getSpecialistBusyDates(String userId) async {
    try {
      final profile = await getSpecialistProfile(userId);
      return profile?.busyDates ?? [];
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ Р·Р°РЅСЏС‚С‹С… РґР°С‚: $e');
      return [];
    }
  }

  /// РџСЂРѕРІРµСЂРёС‚СЊ РґРѕСЃС‚СѓРїРЅРѕСЃС‚СЊ СЃРїРµС†РёР°Р»РёСЃС‚Р° РЅР° РґР°С‚Сѓ
  Future<bool> isSpecialistAvailable(String userId, DateTime date) async {
    try {
      final profile = await getSpecialistProfile(userId);
      if (profile == null) return false;

      return profile.isAvailable &&
          !profile.busyDates.any(
            (busyDate) =>
                busyDate.year == date.year &&
                busyDate.month == date.month &&
                busyDate.day == date.day,
          );
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїСЂРѕРІРµСЂРєРё РґРѕСЃС‚СѓРїРЅРѕСЃС‚Рё: $e');
      return false;
    }
  }
}

