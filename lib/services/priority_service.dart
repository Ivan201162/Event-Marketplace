import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/advertisement.dart';
import '../models/promotion_boost.dart';
import '../models/subscription_plan.dart';
import '../services/advertisement_service.dart';
import '../services/promotion_service.dart';
import '../services/subscription_service.dart';

class PriorityService {
  static final PriorityService _instance = PriorityService._internal();
  factory PriorityService() => _instance;
  PriorityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SubscriptionService _subscriptionService = SubscriptionService();
  final PromotionService _promotionService = PromotionService();
  final AdvertisementService _advertisementService = AdvertisementService();

  /// Получение приоритета пользователя
  Future<int> getUserPriority(String userId) async {
    try {
      // Базовый приоритет
      int priority = 0;

      // Проверяем активную подписку
      final subscription = await _subscriptionService.getActiveSubscription(userId);
      if (subscription != null) {
        final plan = await _subscriptionService.getPlanById(subscription.planId);
        if (plan != null) {
          switch (plan.tier) {
            case SubscriptionTier.free:
              priority += 0;
              break;
            case SubscriptionTier.premium:
              priority += 100;
              break;
            case SubscriptionTier.pro:
              priority += 200;
              break;
          }
        }
      }

      // Проверяем активные продвижения
      final promotions = await _promotionService.getActivePromotions(userId);
      for (final promotion in promotions) {
        switch (promotion.priorityLevel) {
          case PromotionPriority.low:
            priority += 50;
            break;
          case PromotionPriority.medium:
            priority += 100;
            break;
          case PromotionPriority.high:
            priority += 200;
            break;
          case PromotionPriority.premium:
            priority += 300;
            break;
        }
      }

      return priority;
    } catch (e) {
      debugPrint('ERROR: [priority_service] Ошибка получения приоритета пользователя: $e');
      return 0;
    }
  }

  /// Сортировка пользователей по приоритету
  Future<List<Map<String, dynamic>>> sortUsersByPriority(
    List<Map<String, dynamic>> users,
  ) async {
    try {
      final usersWithPriority = <Map<String, dynamic>>[];

      for (final user in users) {
        final userId = user['id'] as String;
        final priority = await getUserPriority(userId);
        usersWithPriority.add({
          ...user,
          'priority': priority,
        });
      }

      // Сортируем по приоритету (убывание)
      usersWithPriority.sort((a, b) => (b['priority'] as int).compareTo(a['priority'] as int));

      return usersWithPriority;
    } catch (e) {
      debugPrint('ERROR: [priority_service] Ошибка сортировки пользователей: $e');
      return users;
    }
  }

  /// Получение топ пользователей с учетом приоритетов
  Future<List<Map<String, dynamic>>> getTopUsers({
    String? region,
    String? city,
    String? category,
    int limit = 10,
  }) async {
    try {
      debugPrint('INFO: [priority_service] Получение топ пользователей');

      Query query = _firestore.collection('users');

      if (region != null) {
        query = query.where('region', isEqualTo: region);
      }

      if (city != null) {
        query = query.where('city', isEqualTo: city);
      }

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.limit(limit * 2).get(); // Берем больше для сортировки

      final users = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();

      // Сортируем по приоритету
      final sortedUsers = await sortUsersByPriority(users);

      return sortedUsers.take(limit).toList();
    } catch (e) {
      debugPrint('ERROR: [priority_service] Ошибка получения топ пользователей: $e');
      return [];
    }
  }

  /// Получение продвинутых пользователей для отображения в топе
  Future<List<Map<String, dynamic>>> getPromotedUsers({
    String? region,
    String? city,
    String? category,
    int limit = 5,
  }) async {
    try {
      debugPrint('INFO: [priority_service] Получение продвинутых пользователей');

      // Получаем активные продвижения профилей
      final promotions = await _promotionService.getPromotedProfiles(
        region: region,
        city: city,
        category: category,
        limit: limit,
      );

      final promotedUsers = <Map<String, dynamic>>[];

      for (final promotion in promotions) {
        final userDoc = await _firestore.collection('users').doc(promotion.userId).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          promotedUsers.add({
            'id': userDoc.id,
            ...userData,
            'promotion': promotion,
            'isPromoted': true,
          });
        }
      }

      return promotedUsers;
    } catch (e) {
      debugPrint('ERROR: [priority_service] Ошибка получения продвинутых пользователей: $e');
      return [];
    }
  }

  /// Получение рекламных объявлений для отображения
  Future<List<Advertisement>> getAdvertisementsForDisplay({
    required AdPlacement placement,
    String? region,
    String? city,
    String? category,
    int limit = 3,
  }) async {
    try {
      return await _advertisementService.getAdvertisementsForDisplay(
        placement: placement,
        region: region,
        city: city,
        category: category,
        limit: limit,
      );
    } catch (e) {
      debugPrint('ERROR: [priority_service] Ошибка получения рекламы: $e');
      return [];
    }
  }

  /// Проверка, является ли пользователь премиум
  Future<bool> isPremiumUser(String userId) async {
    try {
      final subscription = await _subscriptionService.getActiveSubscription(userId);
      if (subscription == null) return false;

      final plan = await _subscriptionService.getPlanById(subscription.planId);
      return plan?.tier != SubscriptionTier.free;
    } catch (e) {
      debugPrint('ERROR: [priority_service] Ошибка проверки премиум статуса: $e');
      return false;
    }
  }

  /// Получение уровня подписки пользователя
  Future<SubscriptionTier> getUserSubscriptionTier(String userId) async {
    try {
      return await _subscriptionService.getUserSubscriptionTier(userId);
    } catch (e) {
      debugPrint('ERROR: [priority_service] Ошибка получения уровня подписки: $e');
      return SubscriptionTier.free;
    }
  }

  /// Проверка доступа к премиум функциям
  Future<bool> hasPremiumAccess(String userId) async {
    try {
      return await _subscriptionService.hasPremiumAccess(userId);
    } catch (e) {
      debugPrint('ERROR: [priority_service] Ошибка проверки премиум доступа: $e');
      return false;
    }
  }

  /// Получение статистики приоритетов
  Future<Map<String, dynamic>> getPriorityStats() async {
    try {
      final subscriptionStats = await _subscriptionService.getSubscriptionStats();
      final promotionStats = await _promotionService.getPromotionStats();
      final advertisementStats = await _advertisementService.getAdvertisementStats();

      return {
        'subscriptions': subscriptionStats,
        'promotions': promotionStats,
        'advertisements': advertisementStats,
        'totalRevenue': (subscriptionStats['totalRevenue'] as double? ?? 0.0) +
            (promotionStats['totalRevenue'] as double? ?? 0.0) +
            (advertisementStats['totalRevenue'] as double? ?? 0.0),
      };
    } catch (e) {
      debugPrint('ERROR: [priority_service] Ошибка получения статистики: $e');
      return {};
    }
  }

  /// Обновление статистики показов и кликов
  Future<void> updateDisplayStats({
    required String userId,
    required String type, // 'user', 'promotion', 'advertisement'
    required String itemId,
    bool isClick = false,
  }) async {
    try {
      if (type == 'promotion') {
        await _promotionService.updatePromotionStats(
          promotionId: itemId,
          impressions: isClick ? 0 : 1,
          clicks: isClick ? 1 : 0,
        );
      } else if (type == 'advertisement') {
        await _advertisementService.updateAdvertisementStats(
          adId: itemId,
          impressions: isClick ? 0 : 1,
          clicks: isClick ? 1 : 0,
        );
      }
    } catch (e) {
      debugPrint('ERROR: [priority_service] Ошибка обновления статистики: $e');
    }
  }

  /// Получение рекомендаций для пользователя
  Future<List<Map<String, dynamic>>> getRecommendations({
    required String userId,
    String? region,
    String? city,
    String? category,
    int limit = 10,
  }) async {
    try {
      // Получаем обычных пользователей
      final regularUsers = await getTopUsers(
        region: region,
        city: city,
        category: category,
        limit: limit ~/ 2,
      );

      // Получаем продвинутых пользователей
      final promotedUsers = await getPromotedUsers(
        region: region,
        city: city,
        category: category,
        limit: limit ~/ 2,
      );

      // Объединяем и сортируем
      final allUsers = [...promotedUsers, ...regularUsers];
      final sortedUsers = await sortUsersByPriority(allUsers);

      return sortedUsers.take(limit).toList();
    } catch (e) {
      debugPrint('ERROR: [priority_service] Ошибка получения рекомендаций: $e');
      return [];
    }
  }
}
