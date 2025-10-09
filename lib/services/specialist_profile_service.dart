import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/profile_statistics.dart';
import '../models/portfolio_item.dart';
import '../models/social_link.dart';

/// Сервис для работы с профилем специалиста
class SpecialistProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить статистику профиля
  Future<ProfileStatistics> getProfileStatistics(String specialistId) async {
    try {
      final doc = await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('statistics')
          .doc('profile')
          .get();

      if (doc.exists) {
        return ProfileStatistics.fromMap(doc.data()!);
      } else {
        // Создать базовую статистику
        final defaultStats = const ProfileStatistics(
          views: 0,
          likes: 0,
          rating: 0.0,
          reviewsCount: 0,
          averagePrice: 0.0,
          completedOrders: 0,
          responseTime: 0.0,
          onlineStatus: false,
          lastActive: null,
          portfolioItems: 0,
          socialLinks: 0,
          pinnedPosts: 0,
        );
        
        await _firestore
            .collection('specialists')
            .doc(specialistId)
            .collection('statistics')
            .doc('profile')
            .set(defaultStats.toMap());
            
        return defaultStats;
      }
    } on Exception catch (e) {
      debugPrint('Ошибка получения статистики профиля: $e');
      return const ProfileStatistics(
        views: 0,
        likes: 0,
        rating: 0.0,
        reviewsCount: 0,
        averagePrice: 0.0,
        completedOrders: 0,
        responseTime: 0.0,
        onlineStatus: false,
        lastActive: null,
        portfolioItems: 0,
        socialLinks: 0,
        pinnedPosts: 0,
      );
    }
  }

  /// Обновить статистику профиля
  Future<void> updateProfileStatistics(
    String specialistId,
    ProfileStatistics statistics,
  ) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('statistics')
          .doc('profile')
          .set(statistics.toMap());
    } on Exception catch (e) {
      debugPrint('Ошибка обновления статистики профиля: $e');
    }
  }

  /// Увеличить количество просмотров
  Future<void> incrementViews(String specialistId) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('statistics')
          .doc('profile')
          .update({
        'views': FieldValue.increment(1),
        'lastActive': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка увеличения просмотров: $e');
    }
  }

  /// Получить портфолио специалиста
  Future<List<PortfolioItem>> getPortfolio(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('portfolio')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PortfolioItem.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения портфолио: $e');
      return [];
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
          
      // Обновить количество элементов портфолио в статистике
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('statistics')
          .doc('profile')
          .update({
        'portfolioItems': FieldValue.increment(1),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка добавления элемента портфолио: $e');
    }
  }

  /// Удалить элемент из портфолио
  Future<void> removePortfolioItem(String specialistId, String itemId) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('portfolio')
          .doc(itemId)
          .delete();
          
      // Обновить количество элементов портфолио в статистике
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('statistics')
          .doc('profile')
          .update({
        'portfolioItems': FieldValue.increment(-1),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка удаления элемента портфолио: $e');
    }
  }

  /// Получить социальные ссылки
  Future<List<SocialLink>> getSocialLinks(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('socialLinks')
          .where('isPublic', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => SocialLink.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения социальных ссылок: $e');
      return [];
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
          
      // Обновить количество социальных ссылок в статистике
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('statistics')
          .doc('profile')
          .update({
        'socialLinks': FieldValue.increment(1),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка добавления социальной ссылки: $e');
    }
  }

  /// Удалить социальную ссылку
  Future<void> removeSocialLink(String specialistId, String linkId) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('socialLinks')
          .doc(linkId)
          .delete();
          
      // Обновить количество социальных ссылок в статистике
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('statistics')
          .doc('profile')
          .update({
        'socialLinks': FieldValue.increment(-1),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка удаления социальной ссылки: $e');
    }
  }

  /// Получить закреплённые посты
  Future<List<Map<String, dynamic>>> getPinnedPosts(String specialistId) async {
    try {
      final snapshot = await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('pinnedPosts')
          .orderBy('pinnedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } on Exception catch (e) {
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
      
      // Обновить количество закреплённых постов в статистике
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('statistics')
          .doc('profile')
          .update({
        'pinnedPosts': FieldValue.increment(1),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка закрепления поста: $e');
    }
  }

  /// Открепить пост
  Future<void> unpinPost(String specialistId, String pinnedPostId) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('pinnedPosts')
          .doc(pinnedPostId)
          .delete();
          
      // Обновить количество закреплённых постов в статистике
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('statistics')
          .doc('profile')
          .update({
        'pinnedPosts': FieldValue.increment(-1),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка открепления поста: $e');
    }
  }

  /// Обновить статус онлайн
  Future<void> updateOnlineStatus(String specialistId, bool isOnline) async {
    try {
      await _firestore
          .collection('specialists')
          .doc(specialistId)
          .collection('statistics')
          .doc('profile')
          .update({
        'onlineStatus': isOnline,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка обновления статуса онлайн: $e');
    }
  }

  /// Поделиться профилем
  Future<String> shareProfile(String specialistId) async {
    // TODO(developer): Реализовать генерацию ссылки для шаринга
    return 'https://eventmarketplace.app/specialist/$specialistId';
  }
}