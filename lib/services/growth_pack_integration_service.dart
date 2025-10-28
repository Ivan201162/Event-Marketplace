import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:event_marketplace_app/services/ab_testing_service.dart';
import 'package:event_marketplace_app/services/automated_promotions_service.dart';
import 'package:event_marketplace_app/services/dynamic_pricing_service.dart';
import 'package:event_marketplace_app/services/growth_mechanics_service.dart';
import 'package:event_marketplace_app/services/growth_notifications_service.dart';
import 'package:event_marketplace_app/services/partnership_service.dart';
import 'package:event_marketplace_app/services/receipt_service.dart';
import 'package:event_marketplace_app/services/referral_service.dart';
import 'package:event_marketplace_app/services/revenue_analytics_service.dart';
import 'package:event_marketplace_app/services/smart_advertising_service.dart';

class GrowthPackIntegrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Сервисы Growth Pack
  final ReferralService _referralService = ReferralService();
  final DynamicPricingService _dynamicPricingService = DynamicPricingService();
  final SmartAdvertisingService _smartAdvertisingService =
      SmartAdvertisingService();
  final RevenueAnalyticsService _revenueAnalyticsService =
      RevenueAnalyticsService();
  final ReceiptService _receiptService = ReceiptService();
  final PartnershipService _partnershipService = PartnershipService();
  final GrowthMechanicsService _growthMechanicsService =
      GrowthMechanicsService();
  final ABTestingService _abTestingService = ABTestingService();
  final AutomatedPromotionsService _automatedPromotionsService =
      AutomatedPromotionsService();
  final GrowthNotificationsService _growthNotificationsService =
      GrowthNotificationsService();

  /// Инициализация всех сервисов Growth Pack
  Future<void> initializeGrowthPack() async {
    try {
      debugPrint(
          'INFO: [GrowthPackIntegrationService] Initializing Growth Pack...',);

      // Создаем предустановленные данные
      await _createDefaultData();

      // Создаем предустановленные A/B тесты
      await _abTestingService.createMonetizationABTests();

      // Создаем автоматические промо-кампании
      await _automatedPromotionsService.createDefaultPromotions();

      debugPrint(
          'INFO: [GrowthPackIntegrationService] Growth Pack initialized successfully',);
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthPackIntegrationService] Failed to initialize Growth Pack: $e',);
    }
  }

  /// Создание предустановленных данных
  Future<void> _createDefaultData() async {
    try {
      // Создаем достижения
      await _createDefaultAchievements();

      // Создаем значки
      await _createDefaultBadges();

      // Создаем челленджи
      await _createDefaultChallenges();

      // Создаем правила динамического ценообразования
      await _createDefaultPricingRules();

      // Создаем правила умной рекламы
      await _createDefaultSmartAdRules();

      debugPrint('INFO: [GrowthPackIntegrationService] Default data created');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthPackIntegrationService] Failed to create default data: $e',);
    }
  }

  /// Создание предустановленных достижений
  Future<void> _createDefaultAchievements() async {
    try {
      final achievements = <Map<String, dynamic>>[
        {
          'id': 'first_referral',
          'name': 'Первый реферал',
          'description': 'Пригласите первого друга',
          'type': 'referral',
          'condition': {'type': 'referral_count', 'count': 1},
          'reward': {'type': 'premium_days', 'days': 3},
          'points': 100,
          'isActive': true,
          'createdAt': DateTime.now(),
        },
        {
          'id': 'referral_master',
          'name': 'Мастер рефералов',
          'description': 'Пригласите 10 друзей',
          'type': 'referral',
          'condition': {'type': 'referral_count', 'count': 10},
          'reward': {'type': 'premium_days', 'days': 30},
          'points': 500,
          'isActive': true,
          'createdAt': DateTime.now(),
        },
        {
          'id': 'first_purchase',
          'name': 'Первый покупатель',
          'description': 'Совершите первую покупку',
          'type': 'purchase',
          'condition': {'type': 'purchase_count', 'count': 1},
          'reward': {'type': 'badge', 'badgeId': 'first_buyer'},
          'points': 200,
          'isActive': true,
          'createdAt': DateTime.now(),
        },
        {
          'id': 'big_spender',
          'name': 'Большой тратчик',
          'description': 'Потратьте 10,000 рублей',
          'type': 'purchase',
          'condition': {'type': 'total_spent', 'amount': 10000.0},
          'reward': {'type': 'discount', 'value': 0.15},
          'points': 1000,
          'isActive': true,
          'createdAt': DateTime.now(),
        },
        {
          'id': 'level_10',
          'name': 'Уровень 10',
          'description': 'Достигните 10 уровня',
          'type': 'level',
          'condition': {'type': 'level_reached', 'level': 10},
          'reward': {'type': 'premium_days', 'days': 7},
          'points': 300,
          'isActive': true,
          'createdAt': DateTime.now(),
        },
      ];

      for (final achievement in achievements) {
        await _firestore
            .collection('achievements')
            .doc(achievement['id'])
            .set(achievement);
      }

      debugPrint(
          'INFO: [GrowthPackIntegrationService] Default achievements created',);
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthPackIntegrationService] Failed to create default achievements: $e',);
    }
  }

  /// Создание предустановленных значков
  Future<void> _createDefaultBadges() async {
    try {
      final badges = <Map<String, dynamic>>[
        {
          'id': 'first_buyer',
          'name': 'Первый покупатель',
          'description': 'Совершил первую покупку',
          'type': 'purchase',
          'category': 'monetization',
          'icon': 'shopping_cart',
          'color': 'blue',
          'isActive': true,
          'createdAt': DateTime.now(),
        },
        {
          'id': 'referral_champion',
          'name': 'Чемпион рефералов',
          'description': 'Пригласил 10+ друзей',
          'type': 'referral',
          'category': 'social',
          'icon': 'people',
          'color': 'gold',
          'isActive': true,
          'createdAt': DateTime.now(),
        },
        {
          'id': 'level_master',
          'name': 'Мастер уровней',
          'description': 'Достиг высокого уровня',
          'type': 'level',
          'category': 'progress',
          'icon': 'star',
          'color': 'purple',
          'isActive': true,
          'createdAt': DateTime.now(),
        },
        {
          'id': 'challenge_completer',
          'name': 'Завершитель челленджей',
          'description': 'Завершил 5+ челленджей',
          'type': 'challenge',
          'category': 'achievement',
          'icon': 'emoji_events',
          'color': 'green',
          'isActive': true,
          'createdAt': DateTime.now(),
        },
      ];

      for (final badge in badges) {
        await _firestore.collection('badges').doc(badge['id']).set(badge);
      }

      debugPrint('INFO: [GrowthPackIntegrationService] Default badges created');
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthPackIntegrationService] Failed to create default badges: $e',);
    }
  }

  /// Создание предустановленных челленджей
  Future<void> _createDefaultChallenges() async {
    try {
      // Челлендж "Пригласи 5 друзей"
      await _growthMechanicsService.createChallenge(
        name: 'Пригласи 5 друзей',
        description: 'Пригласите 5 друзей и получите месяц Premium бесплатно!',
        type: 'referral',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        conditions: {'referral_count': 5},
        rewards: {
          'experience': 500,
          'premium_days': 30,
          'badge': 'referral_champion',
        },
        icon: 'people',
        category: 'social',
      );

      // Челлендж "Потрать 5,000 рублей"
      await _growthMechanicsService.createChallenge(
        name: 'Потрать 5,000 рублей',
        description: 'Потратьте 5,000 рублей и получите скидку 20%!',
        type: 'purchase',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 60)),
        conditions: {'total_spent': 5000.0},
        rewards: {'experience': 300, 'discount': 0.20},
        icon: 'shopping_cart',
        category: 'monetization',
      );

      // Челлендж "Достигни 5 уровня"
      await _growthMechanicsService.createChallenge(
        name: 'Достигни 5 уровня',
        description: 'Достигните 5 уровня и получите эксклюзивный значок!',
        type: 'level',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 90)),
        conditions: {'level': 5},
        rewards: {'experience': 200, 'badge': 'level_master'},
        icon: 'star',
        category: 'progress',
      );

      debugPrint(
          'INFO: [GrowthPackIntegrationService] Default challenges created',);
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthPackIntegrationService] Failed to create default challenges: $e',);
    }
  }

  /// Создание правил динамического ценообразования
  Future<void> _createDefaultPricingRules() async {
    try {
      // Правило для подписок
      await _firestore
          .collection('pricing_rules')
          .doc('subscription_pricing')
          .set({
        'id': 'subscription_pricing',
        'serviceType': 'subscription',
        'basePrice': 499.0,
        'demandFactor': 1.0,
        'timeFactor': 1.0,
        'regionFactor': 1.0,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'metadata': {
          'regionFactors': {'Moscow': 1.2, 'SPb': 1.1, 'other': 1.0},
          'timeFactors': {'peak_hours': 1.1, 'off_peak': 0.9},
        },
      });

      // Правило для продвижений
      await _firestore
          .collection('pricing_rules')
          .doc('promotion_pricing')
          .set({
        'id': 'promotion_pricing',
        'serviceType': 'promotion',
        'basePrice': 299.0,
        'demandFactor': 1.0,
        'timeFactor': 1.0,
        'regionFactor': 1.0,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'metadata': {
          'regionFactors': {'Moscow': 1.3, 'SPb': 1.2, 'other': 1.0},
        },
      });

      debugPrint(
          'INFO: [GrowthPackIntegrationService] Default pricing rules created',);
    } catch (e) {
      debugPrint(
        'ERROR: [GrowthPackIntegrationService] Failed to create default pricing rules: $e',
      );
    }
  }

  /// Создание правил умной рекламы
  Future<void> _createDefaultSmartAdRules() async {
    try {
      // Правило для показа рекламы по интересам
      await _firestore
          .collection('smart_ad_rules')
          .doc('interest_based_ads')
          .set({
        'id': 'interest_based_ads',
        'placementType': 'banner',
        'targetCriterion': 'user_interest',
        'criterionValue': 'music',
        'priority': 10,
        'maxImpressionsPerUser': 3,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'metadata': {'category': 'music', 'targetAudience': 'music_lovers'},
      });

      // Правило для показа рекламы по истории просмотров
      await _firestore
          .collection('smart_ad_rules')
          .doc('history_based_ads')
          .set({
        'id': 'history_based_ads',
        'placementType': 'profileRecommendation',
        'targetCriterion': 'view_history',
        'criterionValue': 'specialist_profile_view',
        'priority': 8,
        'maxImpressionsPerUser': 5,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'metadata': {
          'category': 'specialists',
          'targetAudience': 'active_browsers',
        },
      });

      // Правило для показа рекламы по локации
      await _firestore
          .collection('smart_ad_rules')
          .doc('location_based_ads')
          .set({
        'id': 'location_based_ads',
        'placementType': 'feedInsertion',
        'targetCriterion': 'location',
        'criterionValue': 'Moscow',
        'priority': 6,
        'maxImpressionsPerUser': 4,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'metadata': {'region': 'Moscow', 'targetAudience': 'moscow_users'},
      });

      debugPrint(
          'INFO: [GrowthPackIntegrationService] Default smart ad rules created',);
    } catch (e) {
      debugPrint(
        'ERROR: [GrowthPackIntegrationService] Failed to create default smart ad rules: $e',
      );
    }
  }

  /// Обработка события пользователя (интеграция всех сервисов)
  Future<void> handleUserEvent(
    String userId,
    String eventType,
    Map<String, dynamic> eventData,
  ) async {
    try {
      debugPrint(
        'INFO: [GrowthPackIntegrationService] Handling user event: $eventType for user $userId',
      );

      // Обработка в сервисе геймификации
      await _growthMechanicsService.checkAndAwardAchievements(
          userId, eventType, eventData,);

      // Обработка в сервисе автоматических промо-кампаний
      await _automatedPromotionsService.checkAndExecutePromotions(
          userId, eventType, eventData,);

      // Обработка в сервисе A/B тестирования
      await _abTestingService.logEvent(
          userId, 'general_test', eventType, eventData,);

      // Добавление опыта за активность
      await _addExperienceForEvent(userId, eventType, eventData);

      debugPrint(
          'INFO: [GrowthPackIntegrationService] User event handled successfully',);
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthPackIntegrationService] Failed to handle user event: $e',);
    }
  }

  /// Добавление опыта за событие
  Future<void> _addExperienceForEvent(
    String userId,
    String eventType,
    Map<String, dynamic> eventData,
  ) async {
    try {
      var experience = 0;
      var reason = '';

      switch (eventType) {
        case 'user_registration':
          experience = 100;
          reason = 'Регистрация';
        case 'first_purchase':
          experience = 200;
          reason = 'Первая покупка';
        case 'referral_completed':
          experience = 150;
          reason = 'Реферал зарегистрирован';
        case 'challenge_completed':
          experience = 300;
          reason = 'Челлендж завершен';
        case 'achievement_earned':
          experience = 100;
          reason = 'Достижение получено';
        case 'daily_login':
          experience = 10;
          reason = 'Ежедневный вход';
        case 'profile_view':
          experience = 5;
          reason = 'Просмотр профиля';
        case 'message_sent':
          experience = 3;
          reason = 'Отправлено сообщение';
        case 'idea_created':
          experience = 20;
          reason = 'Создана идея';
        case 'request_created':
          experience = 15;
          reason = 'Создан запрос';
      }

      if (experience > 0) {
        await _growthMechanicsService.addExperience(userId, experience, reason);
      }
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthPackIntegrationService] Failed to add experience for event: $e',);
    }
  }

  /// Получение статистики Growth Pack для пользователя
  Future<Map<String, dynamic>> getUserGrowthStats(String userId) async {
    try {
      // Получаем уровень пользователя
      final DocumentSnapshot levelDoc =
          await _firestore.collection('user_levels').doc(userId).get();

      // Получаем достижения
      final QuerySnapshot achievementsSnapshot = await _firestore
          .collection('user_achievements')
          .where('userId', isEqualTo: userId)
          .get();

      // Получаем значки
      final QuerySnapshot badgesSnapshot = await _firestore
          .collection('user_badges')
          .where('userId', isEqualTo: userId)
          .get();

      // Получаем челленджи
      final QuerySnapshot challengesSnapshot = await _firestore
          .collection('user_challenges')
          .where('userId', isEqualTo: userId)
          .get();

      // Получаем рефералов
      final QuerySnapshot referralsSnapshot = await _firestore
          .collection('referrals')
          .where('referrerId', isEqualTo: userId)
          .get();

      return {
        'level': levelDoc.exists
            ? (levelDoc.data()! as Map<String, dynamic>)['level']
            : 1,
        'experience': levelDoc.exists
            ? (levelDoc.data()! as Map<String, dynamic>)['experience']
            : 0,
        'totalExperience': levelDoc.exists
            ? (levelDoc.data()! as Map<String, dynamic>)['totalExperience']
            : 0,
        'achievementsCount': achievementsSnapshot.docs.length,
        'badgesCount': badgesSnapshot.docs.length,
        'challengesCount': challengesSnapshot.docs.length,
        'referralsCount': referralsSnapshot.docs.length,
        'isActive': true,
      };
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthPackIntegrationService] Failed to get user growth stats: $e',);
      return {
        'level': 1,
        'experience': 0,
        'totalExperience': 0,
        'achievementsCount': 0,
        'badgesCount': 0,
        'challengesCount': 0,
        'referralsCount': 0,
        'isActive': false,
      };
    }
  }

  /// Получение статистики Growth Pack для администратора
  Future<Map<String, dynamic>> getAdminGrowthStats() async {
    try {
      // Получаем общую статистику пользователей
      final QuerySnapshot usersSnapshot =
          await _firestore.collection('users').get();

      // Получаем статистику рефералов
      final QuerySnapshot referralsSnapshot =
          await _firestore.collection('referrals').get();

      // Получаем статистику транзакций
      final QuerySnapshot transactionsSnapshot =
          await _firestore.collection('transactions').get();

      // Получаем статистику достижений
      final QuerySnapshot achievementsSnapshot =
          await _firestore.collection('user_achievements').get();

      // Получаем статистику челленджей
      final QuerySnapshot challengesSnapshot =
          await _firestore.collection('user_challenges').get();

      return {
        'totalUsers': usersSnapshot.docs.length,
        'totalReferrals': referralsSnapshot.docs.length,
        'totalTransactions': transactionsSnapshot.docs.length,
        'totalAchievements': achievementsSnapshot.docs.length,
        'totalChallenges': challengesSnapshot.docs.length,
        'referralRate': usersSnapshot.docs.isNotEmpty
            ? referralsSnapshot.docs.length / usersSnapshot.docs.length
            : 0.0,
        'achievementRate': usersSnapshot.docs.isNotEmpty
            ? achievementsSnapshot.docs.length / usersSnapshot.docs.length
            : 0.0,
        'challengeParticipationRate': usersSnapshot.docs.isNotEmpty
            ? challengesSnapshot.docs.length / usersSnapshot.docs.length
            : 0.0,
      };
    } catch (e) {
      debugPrint(
          'ERROR: [GrowthPackIntegrationService] Failed to get admin growth stats: $e',);
      return {
        'totalUsers': 0,
        'totalReferrals': 0,
        'totalTransactions': 0,
        'totalAchievements': 0,
        'totalChallenges': 0,
        'referralRate': 0.0,
        'achievementRate': 0.0,
        'challengeParticipationRate': 0.0,
      };
    }
  }
}
