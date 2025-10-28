import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:event_marketplace_app/models/portfolio_item.dart';
import 'package:event_marketplace_app/models/profile_statistics.dart';
import 'package:event_marketplace_app/models/social_link.dart';

/// Сервис для управления профилем специалиста
class SpecialistProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить статистику профиля
  Future<ProfileStatistics> getProfileStatistics(String specialistId) async {
    try {
      final doc =
          await _firestore.collection('specialists').doc(specialistId).get();

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
      debugPrint('Ошибка получения статистики профиля: $e');
      return _getDefaultStatistics();
    }
  }

  /// Получить портфолио специалиста
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
        return PortfolioItem.fromMap({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      debugPrint('Ошибка получения портфолио: $e');
      return _getTestPortfolio();
    }
  }

  /// Добавить элемент в портфолио
  Future<void> addPortfolioItem(String specialistId, PortfolioItem item) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('portfolio')
          .add(item.toMap());
    } catch (e) {
      debugPrint('Ошибка добавления элемента портфолио: $e');
      rethrow;
    }
  }

  /// Обновить элемент портфолио
  Future<void> updatePortfolioItem(
      String specialistId, String itemId, PortfolioItem item,) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('portfolio')
          .doc(itemId)
          .update(item.toMap());
    } catch (e) {
      debugPrint('Ошибка обновления элемента портфолио: $e');
      rethrow;
    }
  }

  /// Удалить элемент портфолио
  Future<void> deletePortfolioItem(String specialistId, String itemId) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('portfolio')
          .doc(itemId)
          .delete();
    } catch (e) {
      debugPrint('Ошибка удаления элемента портфолио: $e');
      rethrow;
    }
  }

  /// Получить социальные ссылки
  Future<List<SocialLink>> getSocialLinks(String specialistId) async {
    try {
      final query = await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('socialLinks')
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return SocialLink.fromMap({'id': doc.id, ...data});
      }).toList();
    } catch (e) {
      debugPrint('Ошибка получения социальных ссылок: $e');
      return _getTestSocialLinks();
    }
  }

  /// Добавить социальную ссылку
  Future<void> addSocialLink(String specialistId, SocialLink link) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('socialLinks')
          .add(link.toMap());
    } catch (e) {
      debugPrint('Ошибка добавления социальной ссылки: $e');
      rethrow;
    }
  }

  /// Обновить социальную ссылку
  Future<void> updateSocialLink(
      String specialistId, String linkId, SocialLink link,) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('socialLinks')
          .doc(linkId)
          .update(link.toMap());
    } catch (e) {
      debugPrint('Ошибка обновления социальной ссылки: $e');
      rethrow;
    }
  }

  /// Удалить социальную ссылку
  Future<void> deleteSocialLink(String specialistId, String linkId) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('socialLinks')
          .doc(linkId)
          .delete();
    } catch (e) {
      debugPrint('Ошибка удаления социальной ссылки: $e');
      rethrow;
    }
  }

  /// Обновить онлайн статус
  Future<void> updateOnlineStatus(String specialistId, bool isOnline) async {
    try {
      await _firestore.collection('specialists').doc(specialistId).update({
        'onlineStatus': isOnline,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Ошибка обновления онлайн статуса: $e');
      rethrow;
    }
  }

  /// Получить закреплённые посты
  Future<List<Map<String, dynamic>>> getPinnedPosts(String specialistId) async {
    try {
      final query = await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('pinnedPosts')
          .orderBy('pinnedAt', descending: true)
          .get();

      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('Ошибка получения закреплённых постов: $e');
      return [];
    }
  }

  /// Закрепить пост
  Future<void> pinPost(String specialistId, String postId) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('pinnedPosts')
          .add({
        'postId': postId,
        'pinnedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Ошибка закрепления поста: $e');
      rethrow;
    }
  }

  /// Открепить пост
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
      debugPrint('Ошибка открепления поста: $e');
      rethrow;
    }
  }

  /// Получить календарь занятости
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

      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('Ошибка получения календаря занятости: $e');
      return [];
    }
  }

  /// Обновить доступность
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
      debugPrint('Ошибка обновления доступности: $e');
      rethrow;
    }
  }

  /// Тестовые данные для статистики
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

  /// Тестовые данные для портфолио
  List<PortfolioItem> _getTestPortfolio() => [
        PortfolioItem(
          id: '1',
          specialistId: 'test',
          title: 'Свадебная фотосессия в парке',
          description:
              'Романтическая свадебная съёмка в парке с красивыми кадрами',
          mediaUrl: 'https://picsum.photos/400/300?random=1',
          mediaType: PortfolioMediaType.image,
          category: 'Свадебная съёмка',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          views: 45,
          likes: 12,
          tags: ['свадьба', 'фото', 'парк'],
          location: 'Москва',
          eventDate: DateTime.now().subtract(const Duration(days: 1)),
          clientName: 'Анна и Дмитрий',
        ),
        PortfolioItem(
          id: '2',
          specialistId: 'test',
          title: 'Портретная съёмка в студии',
          description: 'Профессиональная портретная съёмка в студии',
          mediaUrl: 'https://picsum.photos/400/300?random=2',
          mediaType: PortfolioMediaType.image,
          category: 'Портретная съёмка',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          views: 32,
          likes: 8,
          tags: ['портрет', 'студия', 'профессиональная'],
          location: 'Студия в Москве',
          eventDate: DateTime.now().subtract(const Duration(days: 3)),
          clientName: 'Елена К.',
        ),
        PortfolioItem(
          id: '3',
          specialistId: 'test',
          title: 'Корпоративное мероприятие',
          description: 'Видеосъёмка корпоративного мероприятия',
          mediaUrl: 'https://picsum.photos/400/300?random=3',
          mediaType: PortfolioMediaType.video,
          category: 'Корпоративное мероприятие',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          views: 78,
          likes: 15,
          tags: ['корпоратив', 'видео', 'мероприятие'],
          location: 'Офис компании',
          eventDate: DateTime.now().subtract(const Duration(days: 7)),
          clientName: 'ООО "Технологии"',
        ),
      ];

  /// Тестовые данные для социальных ссылок
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
