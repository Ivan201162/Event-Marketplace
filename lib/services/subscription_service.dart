import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription_plan.dart';
import '../models/transaction.dart' as transaction_model;
import '../services/payment_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PaymentService _paymentService = PaymentService();

  /// Получение всех доступных планов подписки
  Future<List<SubscriptionPlan>> getAvailablePlans() async {
    try {
      debugPrint('INFO: [subscription_service] Получение доступных планов подписки');

      final snapshot = await _firestore
          .collection('subscription_plans')
          .where('isActive', isEqualTo: true)
          .orderBy('price')
          .get();

      return snapshot.docs
          .map((doc) => SubscriptionPlan.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      debugPrint('ERROR: [subscription_service] Ошибка получения планов: $e');
      return [];
    }
  }

  /// Получение плана подписки по ID
  Future<SubscriptionPlan?> getPlanById(String planId) async {
    try {
      final doc = await _firestore.collection('subscription_plans').doc(planId).get();

      if (doc.exists) {
        return SubscriptionPlan.fromMap({
          'id': doc.id,
          ...doc.data()!,
        });
      }
      return null;
    } catch (e) {
      debugPrint('ERROR: [subscription_service] Ошибка получения плана: $e');
      return null;
    }
  }

  /// Получение активной подписки пользователя
  Future<UserSubscription?> getActiveSubscription(String userId) async {
    try {
      debugPrint(
          'INFO: [subscription_service] Получение активной подписки для пользователя $userId');

      final snapshot = await _firestore
          .collection('user_subscriptions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('endDate', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return UserSubscription.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }
      return null;
    } catch (e) {
      debugPrint('ERROR: [subscription_service] Ошибка получения активной подписки: $e');
      return null;
    }
  }

  /// Получение всех подписок пользователя
  Future<List<UserSubscription>> getUserSubscriptions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('user_subscriptions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserSubscription.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      debugPrint('ERROR: [subscription_service] Ошибка получения подписок пользователя: $e');
      return [];
    }
  }

  /// Покупка подписки
  Future<PaymentResult> purchaseSubscription({
    required String userId,
    required String planId,
    required PaymentMethod paymentMethod,
    PaymentProvider provider = PaymentProvider.stripe,
  }) async {
    try {
      debugPrint('INFO: [subscription_service] Покупка подписки $planId для пользователя $userId');

      // Получаем план подписки
      final plan = await getPlanById(planId);
      if (plan == null) {
        return PaymentResult(
          success: false,
          errorMessage: 'План подписки не найден',
        );
      }

      // Создаем платеж
      final paymentResult = await _paymentService.createSubscriptionPayment(
        userId: userId,
        plan: plan,
        paymentMethod: paymentMethod,
        provider: provider,
      );

      if (paymentResult.success) {
        // Создаем транзакцию
        final transaction = transaction_model.Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          type: transaction_model.TransactionType.subscription,
          amount: plan.price,
          currency: 'RUB',
          status: transaction_model.TransactionStatus.pending,
          timestamp: DateTime.now(),
          description: 'Подписка ${plan.name}',
          subscriptionId: planId,
          paymentMethod: paymentMethod.toString().split('.').last,
          paymentProvider: provider.toString().split('.').last,
          externalTransactionId: paymentResult.externalTransactionId,
          metadata: paymentResult.metadata,
        );

        // Сохраняем транзакцию
        await _firestore.collection('transactions').doc(transaction.id).set(transaction.toMap());

        return PaymentResult(
          success: true,
          transactionId: transaction.id,
          externalTransactionId: paymentResult.externalTransactionId,
          metadata: paymentResult.metadata,
        );
      }

      return paymentResult;
    } catch (e) {
      debugPrint('ERROR: [subscription_service] Ошибка покупки подписки: $e');
      return PaymentResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Активация подписки после успешной оплаты
  Future<bool> activateSubscription({
    required String userId,
    required String planId,
    required String transactionId,
  }) async {
    try {
      debugPrint('INFO: [subscription_service] Активация подписки для пользователя $userId');

      final plan = await getPlanById(planId);
      if (plan == null) {
        debugPrint('ERROR: [subscription_service] План подписки не найден');
        return false;
      }

      // Отменяем предыдущие активные подписки
      await _cancelActiveSubscriptions(userId);

      // Создаем новую подписку
      final startDate = DateTime.now();
      final endDate = startDate.add(Duration(days: plan.durationDays));

      final subscription = UserSubscription(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        planId: planId,
        startDate: startDate,
        endDate: endDate,
        status: SubscriptionStatus.active,
        autoRenew: false,
        transactionId: transactionId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Сохраняем подписку
      await _firestore
          .collection('user_subscriptions')
          .doc(subscription.id)
          .set(subscription.toMap());

      // Обновляем статус транзакции
      await _firestore.collection('transactions').doc(transactionId).update({
        'status': 'success',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('INFO: [subscription_service] Подписка успешно активирована');
      return true;
    } catch (e) {
      debugPrint('ERROR: [subscription_service] Ошибка активации подписки: $e');
      return false;
    }
  }

  /// Отмена активных подписок пользователя
  Future<void> _cancelActiveSubscriptions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('user_subscriptions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': SubscriptionStatus.cancelled.toString().split('.').last,
          'cancelledAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('ERROR: [subscription_service] Ошибка отмены подписок: $e');
    }
  }

  /// Отмена подписки
  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      debugPrint('INFO: [subscription_service] Отмена подписки $subscriptionId');

      await _firestore.collection('user_subscriptions').doc(subscriptionId).update({
        'status': SubscriptionStatus.cancelled.toString().split('.').last,
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('INFO: [subscription_service] Подписка успешно отменена');
      return true;
    } catch (e) {
      debugPrint('ERROR: [subscription_service] Ошибка отмены подписки: $e');
      return false;
    }
  }

  /// Продление подписки
  Future<bool> renewSubscription(String subscriptionId) async {
    try {
      debugPrint('INFO: [subscription_service] Продление подписки $subscriptionId');

      final doc = await _firestore.collection('user_subscriptions').doc(subscriptionId).get();

      if (!doc.exists) {
        debugPrint('ERROR: [subscription_service] Подписка не найдена');
        return false;
      }

      final subscription = UserSubscription.fromMap({
        'id': doc.id,
        ...doc.data()!,
      });

      final plan = await getPlanById(subscription.planId);
      if (plan == null) {
        debugPrint('ERROR: [subscription_service] План подписки не найден');
        return false;
      }

      // Продлеваем подписку на срок плана
      final newEndDate = subscription.endDate.add(Duration(days: plan.durationDays));

      await _firestore.collection('user_subscriptions').doc(subscriptionId).update({
        'endDate': Timestamp.fromDate(newEndDate),
        'status': SubscriptionStatus.active.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('INFO: [subscription_service] Подписка успешно продлена');
      return true;
    } catch (e) {
      debugPrint('ERROR: [subscription_service] Ошибка продления подписки: $e');
      return false;
    }
  }

  /// Проверка истечения подписок
  Future<void> checkExpiredSubscriptions() async {
    try {
      debugPrint('INFO: [subscription_service] Проверка истекших подписок');

      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('user_subscriptions')
          .where('status', isEqualTo: 'active')
          .where('endDate', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': SubscriptionStatus.expired.toString().split('.').last,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      await batch.commit();

      debugPrint(
          'INFO: [subscription_service] Обработано ${snapshot.docs.length} истекших подписок');
    } catch (e) {
      debugPrint('ERROR: [subscription_service] Ошибка проверки истекших подписок: $e');
    }
  }

  /// Проверка, имеет ли пользователь активную подписку
  Future<bool> hasActiveSubscription(String userId) async {
    try {
      final subscription = await getActiveSubscription(userId);
      return subscription != null && subscription.isActive;
    } catch (e) {
      debugPrint('ERROR: [subscription_service] Ошибка проверки активной подписки: $e');
      return false;
    }
  }

  /// Получение уровня подписки пользователя
  Future<SubscriptionTier> getUserSubscriptionTier(String userId) async {
    try {
      final subscription = await getActiveSubscription(userId);
      if (subscription == null) {
        return SubscriptionTier.free;
      }

      final plan = await getPlanById(subscription.planId);
      return plan?.tier ?? SubscriptionTier.free;
    } catch (e) {
      debugPrint('ERROR: [subscription_service] Ошибка получения уровня подписки: $e');
      return SubscriptionTier.free;
    }
  }

  /// Проверка доступа к премиум функциям
  Future<bool> hasPremiumAccess(String userId) async {
    try {
      final tier = await getUserSubscriptionTier(userId);
      return tier == SubscriptionTier.premium || tier == SubscriptionTier.pro;
    } catch (e) {
      debugPrint('ERROR: [subscription_service] Ошибка проверки премиум доступа: $e');
      return false;
    }
  }

  /// Получение статистики подписок
  Future<Map<String, dynamic>> getSubscriptionStats() async {
    try {
      final snapshot = await _firestore.collection('user_subscriptions').get();

      int activeCount = 0;
      int expiredCount = 0;
      int cancelledCount = 0;
      double totalRevenue = 0.0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

        switch (status) {
          case 'active':
            activeCount++;
            break;
          case 'expired':
            expiredCount++;
            break;
          case 'cancelled':
            cancelledCount++;
            break;
        }
        totalRevenue += amount;
      }

      return {
        'totalSubscriptions': snapshot.docs.length,
        'activeSubscriptions': activeCount,
        'expiredSubscriptions': expiredCount,
        'cancelledSubscriptions': cancelledCount,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      debugPrint('ERROR: [subscription_service] Ошибка получения статистики: $e');
      return {};
    }
  }

  /// Подписка на специалиста
  Future<void> subscribeToSpecialist({
    required String userId,
    required String specialistId,
    required String specialistName,
    required String specialistPhotoUrl,
  }) async {
    try {
      debugPrint('INFO: [subscription_service] Подписка на специалиста $specialistId');

      await _firestore.collection('subscriptions').add({
        'subscriber_id': userId,
        'specialist_id': specialistId,
        'specialist_name': specialistName,
        'specialist_photo_url': specialistPhotoUrl,
        'created_at': FieldValue.serverTimestamp(),
        'is_active': true,
      });

      debugPrint('INFO: [subscription_service] Успешная подписка на специалиста');
    } catch (e) {
      debugPrint('ERROR: [subscription_service] Ошибка подписки: $e');
      rethrow;
    }
  }

  /// Отписка от специалиста
  Future<void> unsubscribeFromSpecialist(
    String userId,
    String specialistId,
  ) async {
    try {
      debugPrint('INFO: [subscription_service] Отписка от специалиста $specialistId');

      final query = await _firestore
          .collection('subscriptions')
          .where('subscriber_id', isEqualTo: userId)
          .where('specialist_id', isEqualTo: specialistId)
          .where('is_active', isEqualTo: true)
          .get();

      for (final doc in query.docs) {
        await doc.reference.update({
          'is_active': false,
          'unsubscribed_at': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('INFO: [subscription_service] Успешная отписка от специалиста');
    } catch (e) {
      debugPrint('ERROR: [subscription_service] Ошибка отписки: $e');
      rethrow;
    }
  }

  /// Отметить уведомление как прочитанное
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      debugPrint('INFO: [subscription_service] Отметка уведомления как прочитанного');

      await _firestore.collection('notifications').doc(notificationId).update({
        'is_read': true,
        'read_at': FieldValue.serverTimestamp(),
      });

      debugPrint('INFO: [subscription_service] Уведомление отмечено как прочитанное');
    } catch (e) {
      debugPrint('ERROR: [subscription_service] Ошибка отметки уведомления: $e');
      rethrow;
    }
  }
}
