import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/automated_promotions.dart';

class AutomatedPromotionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Создание автоматической промо-кампании
  Future<String> createAutomatedPromotion({
    required String name,
    required String description,
    required PromotionTrigger trigger,
    required Map<String, dynamic> conditions,
    required Map<String, dynamic> actions,
    required DateTime startDate,
    required DateTime endDate,
    String? targetAudience,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final AutomatedPromotion promotion = AutomatedPromotion(
        id: _uuid.v4(),
        name: name,
        description: description,
        trigger: trigger,
        conditions: conditions,
        actions: actions,
        status: PromotionStatus.draft,
        startDate: startDate,
        endDate: endDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        targetAudience: targetAudience,
        metadata: metadata,
      );

      await _firestore
          .collection('automated_promotions')
          .doc(promotion.id)
          .set(promotion.toMap());

      debugPrint(
          'INFO: [AutomatedPromotionsService] Automated promotion created: ${promotion.id}');
      return promotion.id;
    } catch (e) {
      debugPrint(
          'ERROR: [AutomatedPromotionsService] Failed to create automated promotion: $e');
      rethrow;
    }
  }

  /// Активация автоматической промо-кампании
  Future<void> activatePromotion(String promotionId) async {
    try {
      await _firestore
          .collection('automated_promotions')
          .doc(promotionId)
          .update({
        'isActive': true,
        'status': PromotionStatus.active.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
          'INFO: [AutomatedPromotionsService] Automated promotion activated: $promotionId');
    } catch (e) {
      debugPrint(
          'ERROR: [AutomatedPromotionsService] Failed to activate promotion: $e');
    }
  }

  /// Деактивация автоматической промо-кампании
  Future<void> deactivatePromotion(String promotionId) async {
    try {
      await _firestore
          .collection('automated_promotions')
          .doc(promotionId)
          .update({
        'isActive': false,
        'status': PromotionStatus.completed.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
        'INFO: [AutomatedPromotionsService] Automated promotion deactivated: $promotionId',
      );
    } catch (e) {
      debugPrint(
          'ERROR: [AutomatedPromotionsService] Failed to deactivate promotion: $e');
    }
  }

  /// Проверка и выполнение автоматических промо-кампаний
  Future<void> checkAndExecutePromotions(
    String userId,
    String eventType,
    Map<String, dynamic> eventData,
  ) async {
    try {
      // Получаем все активные автоматические промо-кампании
      final QuerySnapshot promotionsSnapshot = await _firestore
          .collection('automated_promotions')
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: FieldValue.serverTimestamp())
          .where('endDate',
              isGreaterThanOrEqualTo: FieldValue.serverTimestamp())
          .get();

      for (final doc in promotionsSnapshot.docs) {
        final AutomatedPromotion promotion = AutomatedPromotion.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        // Проверяем, соответствует ли событие триггеру
        if (_matchesTrigger(promotion.trigger, eventType, eventData)) {
          // Проверяем условия
          if (await _checkConditions(userId, promotion.conditions)) {
            // Проверяем, не была ли уже применена эта промо-кампания к пользователю
            if (!await _isPromotionAppliedToUser(userId, promotion.id)) {
              await _executePromotion(userId, promotion);
            }
          }
        }
      }
    } catch (e) {
      debugPrint(
          'ERROR: [AutomatedPromotionsService] Failed to check and execute promotions: $e');
    }
  }

  /// Проверка соответствия события триггеру
  bool _matchesTrigger(PromotionTrigger trigger, String eventType,
      Map<String, dynamic> eventData) {
    switch (trigger) {
      case PromotionTrigger.userRegistration:
        return eventType == 'user_registration';
      case PromotionTrigger.firstPurchase:
        return eventType == 'first_purchase';
      case PromotionTrigger.subscriptionExpiry:
        return eventType == 'subscription_expiry';
      case PromotionTrigger.inactivity:
        return eventType == 'user_inactivity';
      case PromotionTrigger.holiday:
        return eventType == 'holiday' && _isHoliday(eventData['date']);
      case PromotionTrigger.seasonal:
        return eventType == 'seasonal' && _isSeasonalPeriod(eventData['date']);
      case PromotionTrigger.milestone:
        return eventType == 'milestone' && _matchesMilestone(eventData);
      case PromotionTrigger.custom:
        return eventType == eventData['custom_trigger'];
      default:
        return false;
    }
  }

  /// Проверка условий промо-кампании
  Future<bool> _checkConditions(
      String userId, Map<String, dynamic> conditions) async {
    try {
      for (final condition in conditions.entries) {
        final String conditionType = condition.key;
        final dynamic conditionValue = condition.value;

        switch (conditionType) {
          case 'user_level':
            final int userLevel = await _getUserLevel(userId);
            if (userLevel < (conditionValue as int)) return false;
            break;

          case 'subscription_type':
            final String subscriptionType =
                await _getUserSubscriptionType(userId);
            if (subscriptionType != conditionValue) return false;
            break;

          case 'region':
            final String userRegion = await _getUserRegion(userId);
            if (userRegion != conditionValue) return false;
            break;

          case 'registration_date':
            final DateTime registrationDate =
                await _getUserRegistrationDate(userId);
            final DateTime cutoffDate =
                DateTime.parse(conditionValue as String);
            if (registrationDate.isAfter(cutoffDate)) return false;
            break;

          case 'total_spent':
            final double totalSpent = await _getUserTotalSpent(userId);
            if (totalSpent < (conditionValue as double)) return false;
            break;

          case 'referral_count':
            final int referralCount = await _getUserReferralCount(userId);
            if (referralCount < (conditionValue as int)) return false;
            break;

          case 'inactivity_days':
            final int inactivityDays = await _getUserInactivityDays(userId);
            if (inactivityDays < (conditionValue as int)) return false;
            break;
        }
      }

      return true;
    } catch (e) {
      debugPrint(
          'ERROR: [AutomatedPromotionsService] Failed to check conditions: $e');
      return false;
    }
  }

  /// Выполнение промо-кампании
  Future<void> _executePromotion(
      String userId, AutomatedPromotion promotion) async {
    try {
      // Выполняем действия промо-кампании
      for (final action in promotion.actions.entries) {
        final String actionType = action.key;
        final dynamic actionValue = action.value;

        switch (actionType) {
          case 'send_notification':
            await _sendPromotionNotification(userId, promotion, actionValue);
            break;

          case 'apply_discount':
            await _applyDiscount(userId, actionValue);
            break;

          case 'add_premium_days':
            await _addPremiumDays(userId, actionValue as int);
            break;

          case 'give_bonus':
            await _giveBonus(userId, actionValue);
            break;

          case 'unlock_feature':
            await _unlockFeature(userId, actionValue as String);
            break;

          case 'send_email':
            await _sendPromotionEmail(userId, promotion, actionValue);
            break;
        }
      }

      // Записываем, что промо-кампания была применена к пользователю
      await _recordPromotionApplication(userId, promotion.id);

      debugPrint(
        'INFO: [AutomatedPromotionsService] Promotion executed: ${promotion.name} for user $userId',
      );
    } catch (e) {
      debugPrint(
          'ERROR: [AutomatedPromotionsService] Failed to execute promotion: $e');
    }
  }

  /// Создание предустановленных автоматических промо-кампаний
  Future<void> createDefaultPromotions() async {
    try {
      // Промо-кампания для новых пользователей
      await createAutomatedPromotion(
        name: 'Добро пожаловать!',
        description: 'Приветственный бонус для новых пользователей',
        trigger: PromotionTrigger.userRegistration,
        conditions: {},
        actions: {
          'send_notification': {
            'title': 'Добро пожаловать в Event Marketplace!',
            'message': 'Получите 3 дня Premium бесплатно!',
          },
          'add_premium_days': 3,
        },
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        targetAudience: 'new_users',
      );

      // Промо-кампания для неактивных пользователей
      await createAutomatedPromotion(
        name: 'Вернись к нам!',
        description: 'Специальное предложение для неактивных пользователей',
        trigger: PromotionTrigger.inactivity,
        conditions: {'inactivity_days': 7},
        actions: {
          'send_notification': {
            'title': 'Мы скучаем!',
            'message': 'Вернись и получи скидку 50% на Premium!',
          },
          'apply_discount': {
            'type': 'percentage',
            'value': 50.0,
            'duration_days': 7
          },
        },
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        targetAudience: 'inactive_users',
      );

      // Промо-кампания для истекающих подписок
      await createAutomatedPromotion(
        name: 'Продли подписку!',
        description: 'Специальное предложение перед истечением подписки',
        trigger: PromotionTrigger.subscriptionExpiry,
        conditions: {'subscription_type': 'premium'},
        actions: {
          'send_notification': {
            'title': 'Подписка истекает!',
            'message': 'Продли Premium со скидкой 30%!',
          },
          'apply_discount': {
            'type': 'percentage',
            'value': 30.0,
            'duration_days': 3
          },
        },
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        targetAudience: 'premium_users',
      );

      // Промо-кампания для праздников
      await createAutomatedPromotion(
        name: 'Праздничная скидка',
        description: 'Специальные предложения на праздники',
        trigger: PromotionTrigger.holiday,
        conditions: {},
        actions: {
          'send_notification': {
            'title': 'Праздничная скидка!',
            'message': 'Получите скидку 25% на все тарифы!',
          },
          'apply_discount': {
            'type': 'percentage',
            'value': 25.0,
            'duration_days': 7
          },
        },
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        targetAudience: 'all_users',
      );

      // Промо-кампания для достижения 10 рефералов
      await createAutomatedPromotion(
        name: 'Мастер рефералов',
        description: 'Бонус за приглашение 10 друзей',
        trigger: PromotionTrigger.milestone,
        conditions: {'referral_count': 10},
        actions: {
          'send_notification': {
            'title': 'Поздравляем!',
            'message': 'Вы пригласили 10 друзей! Получите месяц PRO бесплатно!',
          },
          'add_premium_days': 30,
          'unlock_feature': 'pro_features',
        },
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        targetAudience: 'active_users',
      );

      debugPrint(
          'INFO: [AutomatedPromotionsService] Default automated promotions created');
    } catch (e) {
      debugPrint(
          'ERROR: [AutomatedPromotionsService] Failed to create default promotions: $e');
    }
  }

  /// Вспомогательные методы для проверки условий
  Future<int> _getUserLevel(String userId) async {
    final DocumentSnapshot doc =
        await _firestore.collection('user_levels').doc(userId).get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['level'] ?? 1;
    }
    return 1;
  }

  Future<String> _getUserSubscriptionType(String userId) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('user_subscriptions')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      return data['planType'] ?? 'free';
    }
    return 'free';
  }

  Future<String> _getUserRegion(String userId) async {
    final DocumentSnapshot doc =
        await _firestore.collection('users').doc(userId).get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['region'] ?? 'unknown';
    }
    return 'unknown';
  }

  Future<DateTime> _getUserRegistrationDate(String userId) async {
    final DocumentSnapshot doc =
        await _firestore.collection('users').doc(userId).get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['createdAt'] as Timestamp?;
      return timestamp?.toDate() ?? DateTime.now();
    }
    return DateTime.now();
  }

  Future<double> _getUserTotalSpent(String userId) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .get();

    double total = 0.0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['amount'] ?? 0.0).toDouble();
    }
    return total;
  }

  Future<int> _getUserReferralCount(String userId) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('referrals')
        .where('referrerId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getUserInactivityDays(String userId) async {
    final DocumentSnapshot doc =
        await _firestore.collection('users').doc(userId).get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final lastActivity = data['lastActivityAt'] as Timestamp?;
      if (lastActivity != null) {
        return DateTime.now().difference(lastActivity.toDate()).inDays;
      }
    }
    return 0;
  }

  /// Вспомогательные методы для выполнения действий
  Future<void> _sendPromotionNotification(
    String userId,
    AutomatedPromotion promotion,
    Map<String, dynamic> notificationData,
  ) async {
    // Логика отправки уведомления
    debugPrint(
        'INFO: [AutomatedPromotionsService] Sending promotion notification to user $userId');
  }

  Future<void> _applyDiscount(
      String userId, Map<String, dynamic> discountData) async {
    // Логика применения скидки
    debugPrint(
        'INFO: [AutomatedPromotionsService] Applying discount to user $userId');
  }

  Future<void> _addPremiumDays(String userId, int days) async {
    // Логика добавления премиум дней
    debugPrint(
        'INFO: [AutomatedPromotionsService] Adding $days premium days to user $userId');
  }

  Future<void> _giveBonus(String userId, Map<String, dynamic> bonusData) async {
    // Логика выдачи бонуса
    debugPrint(
        'INFO: [AutomatedPromotionsService] Giving bonus to user $userId');
  }

  Future<void> _unlockFeature(String userId, String feature) async {
    // Логика разблокировки функции
    debugPrint(
        'INFO: [AutomatedPromotionsService] Unlocking feature $feature for user $userId');
  }

  Future<void> _sendPromotionEmail(
    String userId,
    AutomatedPromotion promotion,
    Map<String, dynamic> emailData,
  ) async {
    // Логика отправки email
    debugPrint(
        'INFO: [AutomatedPromotionsService] Sending promotion email to user $userId');
  }

  /// Вспомогательные методы для проверки дат и событий
  bool _isHoliday(DateTime date) {
    // Упрощенная логика проверки праздников
    // В реальном приложении нужна более сложная система
    return false;
  }

  bool _isSeasonalPeriod(DateTime date) {
    // Проверка сезонных периодов (например, лето, зима)
    final month = date.month;
    return month >= 6 && month <= 8; // Лето
  }

  bool _matchesMilestone(Map<String, dynamic> eventData) {
    // Проверка соответствия достижению
    return eventData['milestone_type'] == 'referral_count' &&
        eventData['count'] >= 10;
  }

  Future<bool> _isPromotionAppliedToUser(
      String userId, String promotionId) async {
    final QuerySnapshot snapshot = await _firestore
        .collection('promotion_applications')
        .where('userId', isEqualTo: userId)
        .where('promotionId', isEqualTo: promotionId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> _recordPromotionApplication(
      String userId, String promotionId) async {
    await _firestore.collection('promotion_applications').add({
      'userId': userId,
      'promotionId': promotionId,
      'appliedAt': FieldValue.serverTimestamp(),
    });
  }
}
