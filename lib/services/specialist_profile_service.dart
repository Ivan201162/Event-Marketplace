import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../models/portfolio_item.dart';
import 'package:flutter/foundation.dart';
import '../models/profile_statistics.dart';
import 'package:flutter/foundation.dart';
import '../models/social_link.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ РґР»СЏ СѓРїСЂР°РІР»РµРЅРёСЏ РїСЂРѕС„РёР»РµРј СЃРїРµС†РёР°Р»РёСЃС‚Р°
class SpecialistProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// РџРѕР»СѓС‡РёС‚СЊ СЃС‚Р°С‚РёСЃС‚РёРєСѓ РїСЂРѕС„РёР»СЏ
  Future<ProfileStatistics> getProfileStatistics(String specialistId) async {
    try {
      final doc = await _firestore.collection('specialists').doc(specialistId).get();

      if (!doc.exists) {
        return _getDefaultStatistics();
      }

      final data = doc.data()!;

      return ProfileStatistics(
        views: (data['views'] as int?) ?? 0,
        likes: (data['likes'] as int?) ?? 0,
        rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
        reviewsCount: (data['reviewsCount'] as int?) ?? 0,
        averagePrice: (data['averagePrice'] as num?)?.toDouble() ?? 0.0,
        completedOrders: (data['completedOrders'] as int?) ?? 0,
        responseTime: (data['responseTime'] as num?)?.toDouble() ?? 0.0,
        onlineStatus: data['onlineStatus'] as bool? ?? false,
        lastActive: data['lastActive'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['lastActive'])
            : null,
        portfolioItems: (data['portfolioItems'] as int?) ?? 0,
        socialLinks: (data['socialLinks'] as int?) ?? 0,
        pinnedPosts: (data['pinnedPosts'] as int?) ?? 0,
      );
    } catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃС‚Р°С‚РёСЃС‚РёРєРё РїСЂРѕС„РёР»СЏ: $e');
      return _getDefaultStatistics();
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РїРѕСЂС‚С„РѕР»РёРѕ СЃРїРµС†РёР°Р»РёСЃС‚Р°
  Future<List<PortfolioItem>> getPortfolio(String specialistId) async {
    try {
      final query = await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('portfolio')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return PortfolioItem.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РїРѕСЂС‚С„РѕР»РёРѕ: $e');
      return _getTestPortfolio();
    }
  }

  /// Р”РѕР±Р°РІРёС‚СЊ СЌР»РµРјРµРЅС‚ РІ РїРѕСЂС‚С„РѕР»РёРѕ
  Future<void> addPortfolioItem(String specialistId, PortfolioItem item) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('portfolio')
          .add(item.toMap());
    } catch (e) {
      debugPrint('РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ СЌР»РµРјРµРЅС‚Р° РїРѕСЂС‚С„РѕР»РёРѕ: $e');
      rethrow;
    }
  }

  /// РћР±РЅРѕРІРёС‚СЊ СЌР»РµРјРµРЅС‚ РїРѕСЂС‚С„РѕР»РёРѕ
  Future<void> updatePortfolioItem(
    String specialistId,
    String itemId,
    PortfolioItem item,
  ) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('portfolio')
          .doc(itemId)
          .update(item.toMap());
    } catch (e) {
      debugPrint('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ СЌР»РµРјРµРЅС‚Р° РїРѕСЂС‚С„РѕР»РёРѕ: $e');
      rethrow;
    }
  }

  /// РЈРґР°Р»РёС‚СЊ СЌР»РµРјРµРЅС‚ РїРѕСЂС‚С„РѕР»РёРѕ
  Future<void> deletePortfolioItem(String specialistId, String itemId) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('portfolio')
          .doc(itemId)
          .delete();
    } catch (e) {
      debugPrint('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ СЌР»РµРјРµРЅС‚Р° РїРѕСЂС‚С„РѕР»РёРѕ: $e');
      rethrow;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРѕС†РёР°Р»СЊРЅС‹Рµ СЃСЃС‹Р»РєРё
  Future<List<SocialLink>> getSocialLinks(String specialistId) async {
    try {
      final query = await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('socialLinks')
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return SocialLink.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃРѕС†РёР°Р»СЊРЅС‹С… СЃСЃС‹Р»РѕРє: $e');
      return _getTestSocialLinks();
    }
  }

  /// Р”РѕР±Р°РІРёС‚СЊ СЃРѕС†РёР°Р»СЊРЅСѓСЋ СЃСЃС‹Р»РєСѓ
  Future<void> addSocialLink(String specialistId, SocialLink link) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('socialLinks')
          .add(link.toMap());
    } catch (e) {
      debugPrint('РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ СЃРѕС†РёР°Р»СЊРЅРѕР№ СЃСЃС‹Р»РєРё: $e');
      rethrow;
    }
  }

  /// РћР±РЅРѕРІРёС‚СЊ СЃРѕС†РёР°Р»СЊРЅСѓСЋ СЃСЃС‹Р»РєСѓ
  Future<void> updateSocialLink(
    String specialistId,
    String linkId,
    SocialLink link,
  ) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('socialLinks')
          .doc(linkId)
          .update(link.toMap());
    } catch (e) {
      debugPrint('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ СЃРѕС†РёР°Р»СЊРЅРѕР№ СЃСЃС‹Р»РєРё: $e');
      rethrow;
    }
  }

  /// РЈРґР°Р»РёС‚СЊ СЃРѕС†РёР°Р»СЊРЅСѓСЋ СЃСЃС‹Р»РєСѓ
  Future<void> deleteSocialLink(String specialistId, String linkId) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('socialLinks')
          .doc(linkId)
          .delete();
    } catch (e) {
      debugPrint('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ СЃРѕС†РёР°Р»СЊРЅРѕР№ СЃСЃС‹Р»РєРё: $e');
      rethrow;
    }
  }

  /// РћР±РЅРѕРІРёС‚СЊ РѕРЅР»Р°Р№РЅ СЃС‚Р°С‚СѓСЃ
  Future<void> updateOnlineStatus(String specialistId, bool isOnline) async {
    try {
      await _firestore.collection('specialists').doc(specialistId).update({
        'onlineStatus': isOnline,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РѕРЅР»Р°Р№РЅ СЃС‚Р°С‚СѓСЃР°: $e');
      rethrow;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ Р·Р°РєСЂРµРїР»С‘РЅРЅС‹Рµ РїРѕСЃС‚С‹
  Future<List<Map<String, dynamic>>> getPinnedPosts(String specialistId) async {
    try {
      final query = await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('pinnedPosts')
          .orderBy('pinnedAt', descending: true)
          .get();

      return query.docs
          .map(
            (doc) => {
              'id': doc.id,
              ...doc.data(),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ Р·Р°РєСЂРµРїР»С‘РЅРЅС‹С… РїРѕСЃС‚РѕРІ: $e');
      return [];
    }
  }

  /// Р—Р°РєСЂРµРїРёС‚СЊ РїРѕСЃС‚
  Future<void> pinPost(String specialistId, String postId) async {
    try {
      await _firestore.collection('specialists').doc(specialistId).collection('pinnedPosts').add({
        'postId': postId,
        'pinnedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('РћС€РёР±РєР° Р·Р°РєСЂРµРїР»РµРЅРёСЏ РїРѕСЃС‚Р°: $e');
      rethrow;
    }
  }

  /// РћС‚РєСЂРµРїРёС‚СЊ РїРѕСЃС‚
  Future<void> unpinPost(String specialistId, String postId) async {
    try {
      final query = await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('pinnedPosts')
          .where('postId', isEqualTo: postId)
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‚РєСЂРµРїР»РµРЅРёСЏ РїРѕСЃС‚Р°: $e');
      rethrow;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РєР°Р»РµРЅРґР°СЂСЊ Р·Р°РЅСЏС‚РѕСЃС‚Рё
  Future<List<Map<String, dynamic>>> getAvailabilityCalendar(
    String specialistId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('availability')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();

      return query.docs
          .map(
            (doc) => {
              'id': doc.id,
              ...doc.data(),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РєР°Р»РµРЅРґР°СЂСЏ Р·Р°РЅСЏС‚РѕСЃС‚Рё: $e');
      return [];
    }
  }

  /// РћР±РЅРѕРІРёС‚СЊ РґРѕСЃС‚СѓРїРЅРѕСЃС‚СЊ
  Future<void> updateAvailability(
    String specialistId,
    DateTime date,
    bool isAvailable,
    List<String> timeSlots,
  ) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('availability')
          .doc(date.toIso8601String().split('T')[0])
          .set({
        'date': date,
        'isAvailable': isAvailable,
        'timeSlots': timeSlots,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РґРѕСЃС‚СѓРїРЅРѕСЃС‚Рё: $e');
      rethrow;
    }
  }

  /// РўРµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ РґР»СЏ СЃС‚Р°С‚РёСЃС‚РёРєРё
  ProfileStatistics _getDefaultStatistics() => const ProfileStatistics(
        views: 0,
        likes: 0,
        rating: 0,
        reviewsCount: 0,
        averagePrice: 0,
        completedOrders: 0,
        responseTime: 0,
        onlineStatus: false,
        portfolioItems: 0,
        socialLinks: 0,
        pinnedPosts: 0,
      );

  /// РўРµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ РґР»СЏ РїРѕСЂС‚С„РѕР»РёРѕ
  List<PortfolioItem> _getTestPortfolio() => [
        PortfolioItem(
          id: '1',
          specialistId: 'test',
          title: 'РЎРІР°РґРµР±РЅР°СЏ С„РѕС‚РѕСЃРµСЃСЃРёСЏ РІ РїР°СЂРєРµ',
          description: 'Р РѕРјР°РЅС‚РёС‡РµСЃРєР°СЏ СЃРІР°РґРµР±РЅР°СЏ СЃСЉС‘РјРєР° РІ РїР°СЂРєРµ СЃ РєСЂР°СЃРёРІС‹РјРё РєР°РґСЂР°РјРё',
          mediaUrl: 'https://picsum.photos/400/300?random=1',
          mediaType: PortfolioMediaType.image,
          category: 'РЎРІР°РґРµР±РЅР°СЏ СЃСЉС‘РјРєР°',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          views: 45,
          likes: 12,
          tags: ['СЃРІР°РґСЊР±Р°', 'С„РѕС‚Рѕ', 'РїР°СЂРє'],
          location: 'РњРѕСЃРєРІР°',
          eventDate: DateTime.now().subtract(const Duration(days: 1)),
          clientName: 'РђРЅРЅР° Рё Р”РјРёС‚СЂРёР№',
        ),
        PortfolioItem(
          id: '2',
          specialistId: 'test',
          title: 'РџРѕСЂС‚СЂРµС‚РЅР°СЏ СЃСЉС‘РјРєР° РІ СЃС‚СѓРґРёРё',
          description: 'РџСЂРѕС„РµСЃСЃРёРѕРЅР°Р»СЊРЅР°СЏ РїРѕСЂС‚СЂРµС‚РЅР°СЏ СЃСЉС‘РјРєР° РІ СЃС‚СѓРґРёРё',
          mediaUrl: 'https://picsum.photos/400/300?random=2',
          mediaType: PortfolioMediaType.image,
          category: 'РџРѕСЂС‚СЂРµС‚РЅР°СЏ СЃСЉС‘РјРєР°',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          views: 32,
          likes: 8,
          tags: ['РїРѕСЂС‚СЂРµС‚', 'СЃС‚СѓРґРёСЏ', 'РїСЂРѕС„РµСЃСЃРёРѕРЅР°Р»СЊРЅР°СЏ'],
          location: 'РЎС‚СѓРґРёСЏ РІ РњРѕСЃРєРІРµ',
          eventDate: DateTime.now().subtract(const Duration(days: 3)),
          clientName: 'Р•Р»РµРЅР° Рљ.',
        ),
        PortfolioItem(
          id: '3',
          specialistId: 'test',
          title: 'РљРѕСЂРїРѕСЂР°С‚РёРІРЅРѕРµ РјРµСЂРѕРїСЂРёСЏС‚РёРµ',
          description: 'Р’РёРґРµРѕСЃСЉС‘РјРєР° РєРѕСЂРїРѕСЂР°С‚РёРІРЅРѕРіРѕ РјРµСЂРѕРїСЂРёСЏС‚РёСЏ',
          mediaUrl: 'https://picsum.photos/400/300?random=3',
          mediaType: PortfolioMediaType.video,
          category: 'РљРѕСЂРїРѕСЂР°С‚РёРІРЅРѕРµ РјРµСЂРѕРїСЂРёСЏС‚РёРµ',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          views: 78,
          likes: 15,
          tags: ['РєРѕСЂРїРѕСЂР°С‚РёРІ', 'РІРёРґРµРѕ', 'РјРµСЂРѕРїСЂРёСЏС‚РёРµ'],
          location: 'РћС„РёСЃ РєРѕРјРїР°РЅРёРё',
          eventDate: DateTime.now().subtract(const Duration(days: 7)),
          clientName: 'РћРћРћ "РўРµС…РЅРѕР»РѕРіРёРё"',
        ),
      ];

  /// РўРµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ РґР»СЏ СЃРѕС†РёР°Р»СЊРЅС‹С… СЃСЃС‹Р»РѕРє
  List<SocialLink> _getTestSocialLinks() => [
        SocialLink(
          id: '1',
          specialistId: 'test',
          platform: SocialPlatform.instagram,
          url: 'https://instagram.com/photographer',
          username: 'photographer',
          isVerified: true,
          isPublic: true,
          followersCount: 1250,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        SocialLink(
          id: '2',
          specialistId: 'test',
          platform: SocialPlatform.vk,
          url: 'https://vk.com/photographer',
          username: 'photographer',
          isVerified: false,
          isPublic: true,
          followersCount: 890,
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
        ),
        SocialLink(
          id: '3',
          specialistId: 'test',
          platform: SocialPlatform.telegram,
          url: 'https://t.me/photographer',
          username: 'photographer',
          isVerified: true,
          isPublic: true,
          followersCount: 450,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
      ];
}

