import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/organizer_profile.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ РґР»СЏ СѓРїСЂР°РІР»РµРЅРёСЏ РїСЂРѕС„РёР»СЏРјРё РѕСЂРіР°РЅРёР·Р°С‚РѕСЂРѕРІ
class OrganizerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// РЎРѕР·РґР°С‚СЊ РїСЂРѕС„РёР»СЊ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂР°
  Future<void> createOrganizerProfile(OrganizerProfile profile) async {
    try {
      await _firestore.collection('organizer_profiles').doc(profile.id).set(profile.toMap());
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ РїСЂРѕС„РёР»СЏ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂР°: $e');
      throw Exception('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ РїСЂРѕС„РёР»СЏ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂР°: $e');
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РїСЂРѕС„РёР»СЊ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂР° РїРѕ ID
  Future<OrganizerProfile?> getOrganizerProfile(String organizerId) async {
    try {
      final doc = await _firestore.collection('organizer_profiles').doc(organizerId).get();

      if (doc.exists) {
        return OrganizerProfile.fromDocument(doc);
      }
      return null;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїСЂРѕС„РёР»СЏ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂР°: $e');
      return null;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РїСЂРѕС„РёР»СЊ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂР° РїРѕ ID РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<OrganizerProfile?> getOrganizerProfileByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('organizer_profiles')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return OrganizerProfile.fromDocument(querySnapshot.docs.first);
      }
      return null;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїСЂРѕС„РёР»СЏ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂР° РїРѕ userId: $e');
      return null;
    }
  }

  /// РћР±РЅРѕРІРёС‚СЊ РїСЂРѕС„РёР»СЊ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂР°
  Future<void> updateOrganizerProfile(OrganizerProfile profile) async {
    try {
      final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('organizer_profiles')
          .doc(profile.id)
          .update(updatedProfile.toMap());
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РїСЂРѕС„РёР»СЏ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂР°: $e');
      throw Exception('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РїСЂРѕС„РёР»СЏ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂР°: $e');
    }
  }

  /// РЈРґР°Р»РёС‚СЊ РїСЂРѕС„РёР»СЊ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂР°
  Future<void> deleteOrganizerProfile(String organizerId) async {
    try {
      await _firestore.collection('organizer_profiles').doc(organizerId).delete();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ РїСЂРѕС„РёР»СЏ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂР°: $e');
      throw Exception('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ РїСЂРѕС„РёР»СЏ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂР°: $e');
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРїРёСЃРѕРє РІСЃРµС… Р°РєС‚РёРІРЅС‹С… РѕСЂРіР°РЅРёР·Р°С‚РѕСЂРѕРІ
  Future<List<OrganizerProfile>> getAllActiveOrganizers({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('organizer_profiles')
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map(OrganizerProfile.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃРїРёСЃРєР° РѕСЂРіР°РЅРёР·Р°С‚РѕСЂРѕРІ: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂРѕРІ РїРѕ РєР°С‚РµРіРѕСЂРёРё
  Future<List<OrganizerProfile>> getOrganizersByCategory(
    String category, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('organizer_profiles')
          .where('isActive', isEqualTo: true)
          .where('categories', arrayContains: category)
          .orderBy('rating', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map(OrganizerProfile.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂРѕРІ РїРѕ РєР°С‚РµРіРѕСЂРёРё: $e');
      return [];
    }
  }

  /// РџРѕРёСЃРє РѕСЂРіР°РЅРёР·Р°С‚РѕСЂРѕРІ РїРѕ РЅР°Р·РІР°РЅРёСЋ
  Future<List<OrganizerProfile>> searchOrganizers(
    String searchQuery, {
    int limit = 20,
  }) async {
    try {
      // Firestore РЅРµ РїРѕРґРґРµСЂР¶РёРІР°РµС‚ РїРѕР»РЅРѕС‚РµРєСЃС‚РѕРІС‹Р№ РїРѕРёСЃРє, РїРѕСЌС‚РѕРјСѓ РёСЃРїРѕР»СЊР·СѓРµРј РїСЂРѕСЃС‚РѕР№ С„РёР»СЊС‚СЂ
      final querySnapshot = await _firestore
          .collection('organizer_profiles')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .limit(limit)
          .get();

      final allOrganizers = querySnapshot.docs.map(OrganizerProfile.fromDocument).toList();

      // Р¤РёР»СЊС‚СЂСѓРµРј СЂРµР·СѓР»СЊС‚Р°С‚С‹ РЅР° РєР»РёРµРЅС‚Рµ
      final searchLower = searchQuery.toLowerCase();
      return allOrganizers
          .where(
            (organizer) =>
                organizer.name.toLowerCase().contains(searchLower) ||
                (organizer.description?.toLowerCase().contains(searchLower) ?? false) ||
                organizer.categories.any(
                  (category) => category.toLowerCase().contains(searchLower),
                ),
          )
          .toList();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕРёСЃРєР° РѕСЂРіР°РЅРёР·Р°С‚РѕСЂРѕРІ: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ С‚РѕРї РѕСЂРіР°РЅРёР·Р°С‚РѕСЂРѕРІ РїРѕ СЂРµР№С‚РёРЅРіСѓ
  Future<List<OrganizerProfile>> getTopOrganizers({
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('organizer_profiles')
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .orderBy('rating', descending: true)
          .orderBy('reviewCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map(OrganizerProfile.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С‚РѕРї РѕСЂРіР°РЅРёР·Р°С‚РѕСЂРѕРІ: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂРѕРІ СЂСЏРґРѕРј СЃ Р»РѕРєР°С†РёРµР№
  Future<List<OrganizerProfile>> getOrganizersNearLocation(
    String location, {
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('organizer_profiles')
          .where('isActive', isEqualTo: true)
          .where('location', isEqualTo: location)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map(OrganizerProfile.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂРѕРІ РїРѕ Р»РѕРєР°С†РёРё: $e');
      return [];
    }
  }

  /// РћР±РЅРѕРІРёС‚СЊ СЂРµР№С‚РёРЅРі РѕСЂРіР°РЅРёР·Р°С‚РѕСЂР°
  Future<void> updateOrganizerRating(
    String organizerId,
    double newRating,
    int reviewCount,
  ) async {
    try {
      await _firestore.collection('organizer_profiles').doc(organizerId).update({
        'rating': newRating,
        'reviewCount': reviewCount,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ СЂРµР№С‚РёРЅРіР° РѕСЂРіР°РЅРёР·Р°С‚РѕСЂР°: $e');
      throw Exception('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ СЂРµР№С‚РёРЅРіР°: $e');
    }
  }

  /// Р”РѕР±Р°РІРёС‚СЊ СЃРѕР±С‹С‚РёРµ РІ РїРѕСЂС‚С„РѕР»РёРѕ
  Future<void> addEventToPortfolio(
    String organizerId,
    String eventId,
  ) async {
    try {
      await _firestore.collection('organizer_profiles').doc(organizerId).update({
        'pastEvents': FieldValue.arrayUnion([eventId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ СЃРѕР±С‹С‚РёСЏ РІ РїРѕСЂС‚С„РѕР»РёРѕ: $e');
      throw Exception('РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ СЃРѕР±С‹С‚РёСЏ: $e');
    }
  }

  /// Р”РѕР±Р°РІРёС‚СЊ РёР·РѕР±СЂР°Р¶РµРЅРёРµ РІ РїРѕСЂС‚С„РѕР»РёРѕ
  Future<void> addPortfolioImage(
    String organizerId,
    String imageUrl,
  ) async {
    try {
      await _firestore.collection('organizer_profiles').doc(organizerId).update({
        'portfolioImages': FieldValue.arrayUnion([imageUrl]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ РёР·РѕР±СЂР°Р¶РµРЅРёСЏ РІ РїРѕСЂС‚С„РѕР»РёРѕ: $e');
      throw Exception('РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ РёР·РѕР±СЂР°Р¶РµРЅРёСЏ: $e');
    }
  }

  /// Р”РѕР±Р°РІРёС‚СЊ РІРёРґРµРѕ РІ РїРѕСЂС‚С„РѕР»РёРѕ
  Future<void> addPortfolioVideo(
    String organizerId,
    String videoUrl,
  ) async {
    try {
      await _firestore.collection('organizer_profiles').doc(organizerId).update({
        'portfolioVideos': FieldValue.arrayUnion([videoUrl]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ РІРёРґРµРѕ РІ РїРѕСЂС‚С„РѕР»РёРѕ: $e');
      throw Exception('РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ РІРёРґРµРѕ: $e');
    }
  }

  /// Р”РѕР±Р°РІРёС‚СЊ С‡Р»РµРЅР° РєРѕРјР°РЅРґС‹
  Future<void> addTeamMember(
    String organizerId,
    String specialistId,
  ) async {
    try {
      await _firestore.collection('organizer_profiles').doc(organizerId).update({
        'teamMembers': FieldValue.arrayUnion([specialistId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ С‡Р»РµРЅР° РєРѕРјР°РЅРґС‹: $e');
      throw Exception('РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ С‡Р»РµРЅР° РєРѕРјР°РЅРґС‹: $e');
    }
  }

  /// РЈРґР°Р»РёС‚СЊ С‡Р»РµРЅР° РєРѕРјР°РЅРґС‹
  Future<void> removeTeamMember(
    String organizerId,
    String specialistId,
  ) async {
    try {
      await _firestore.collection('organizer_profiles').doc(organizerId).update({
        'teamMembers': FieldValue.arrayRemove([specialistId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ С‡Р»РµРЅР° РєРѕРјР°РЅРґС‹: $e');
      throw Exception('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ С‡Р»РµРЅР° РєРѕРјР°РЅРґС‹: $e');
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃС‚Р°С‚РёСЃС‚РёРєСѓ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂР°
  Future<Map<String, dynamic>> getOrganizerStats(String organizerId) async {
    try {
      final organizer = await getOrganizerProfile(organizerId);
      if (organizer == null) {
        return {};
      }

      // РџРѕР»СѓС‡Р°РµРј РєРѕР»РёС‡РµСЃС‚РІРѕ Р·Р°РІРµСЂС€РµРЅРЅС‹С… РїСЂРѕРµРєС‚РѕРІ
      final completedProjectsQuery = await _firestore
          .collection('bookings')
          .where('organizerId', isEqualTo: organizerId)
          .where('status', isEqualTo: 'completed')
          .get();

      // РџРѕР»СѓС‡Р°РµРј РєРѕР»РёС‡РµСЃС‚РІРѕ Р°РєС‚РёРІРЅС‹С… РїСЂРѕРµРєС‚РѕРІ
      final activeProjectsQuery = await _firestore
          .collection('bookings')
          .where('organizerId', isEqualTo: organizerId)
          .where(
        'status',
        whereIn: ['pending', 'confirmed', 'in_progress'],
      ).get();

      return {
        'totalProjects': organizer.pastEvents.length,
        'completedProjects': completedProjectsQuery.docs.length,
        'activeProjects': activeProjectsQuery.docs.length,
        'rating': organizer.rating,
        'reviewCount': organizer.reviewCount,
        'teamSize': organizer.teamMembers.length,
        'experienceYears': organizer.experienceYears,
      };
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃС‚Р°С‚РёСЃС‚РёРєРё РѕСЂРіР°РЅРёР·Р°С‚РѕСЂР°: $e');
      return {};
    }
  }

  /// РџСЂРѕРІРµСЂРёС‚СЊ, СЃСѓС‰РµСЃС‚РІСѓРµС‚ Р»Рё РїСЂРѕС„РёР»СЊ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂР° РґР»СЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<bool> hasOrganizerProfile(String userId) async {
    try {
      final profile = await getOrganizerProfileByUserId(userId);
      return profile != null;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїСЂРѕРІРµСЂРєРё РїСЂРѕС„РёР»СЏ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂР°: $e');
      return false;
    }
  }
}

