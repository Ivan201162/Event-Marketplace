import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pro_subscription.dart';

/// Сервис для работы с PRO подписками
class ProSubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить подписку пользователя
  Future<ProSubscription?> getUserSubscription(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['active', 'trial'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return ProSubscription.fromMap(doc.data()! as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения подписки: $e');
    }
  }

  /// Создать подписку
  Future<ProSubscription> createSubscription({
    required String userId,
    required SubscriptionPlan plan,
    required String paymentMethodId,
    bool isTrial = false,
  }) async {
    try {
      final subscriptionId = _firestore.collection('subscriptions').doc().id;
      final now = DateTime.now();
      final endDate = isTrial
          ? now.add(const Duration(days: 7)) // 7 дней пробного периода
          : now.add(const Duration(days: 30)); // 30 дней подписки

      // Создать платеж
      final payment = await _createPayment(
        subscriptionId: subscriptionId,
        amount: isTrial ? 0.0 : plan.monthlyPrice,
        currency: 'RUB',
        paymentMethodId: paymentMethodId,
      );

      if (payment.status != PaymentStatus.completed && !isTrial) {
        throw Exception('Платеж не был завершен');
      }

      // Создать подписку
      final subscription = ProSubscription(
        id: subscriptionId,
        userId: userId,
        plan: plan,
        status: isTrial ? SubscriptionStatus.trial : SubscriptionStatus.active,
        startDate: now,
        endDate: endDate,
        price: plan.monthlyPrice,
        paymentMethod: paymentMethodId,
        trialEndDate: isTrial ? endDate : null,
        features: _getPlanFeatures(plan),
      );

      await _firestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .set(subscription.toMap());

      return subscription;
    } catch (e) {
      throw Exception('Ошибка создания подписки: $e');
    }
  }

  /// Обновить подписку
  Future<void> updateSubscription({
    required String subscriptionId,
    SubscriptionPlan? plan,
    SubscriptionStatus? status,
    DateTime? endDate,
    bool? autoRenew,
    Map<String, bool>? features,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (plan != null) updates['plan'] = plan.value;
      if (status != null) updates['status'] = status.value;
      if (endDate != null) updates['endDate'] = endDate.millisecondsSinceEpoch;
      if (autoRenew != null) updates['autoRenew'] = autoRenew;
      if (features != null) updates['features'] = features;

      await _firestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .update(updates);
    } catch (e) {
      throw Exception('Ошибка обновления подписки: $e');
    }
  }

  /// Отменить подписку
  Future<void> cancelSubscription({
    required String subscriptionId,
    String? reason,
  }) async {
    try {
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'status': SubscriptionStatus.cancelled.value,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason,
        'autoRenew': false,
      });
    } catch (e) {
      throw Exception('Ошибка отмены подписки: $e');
    }
  }

  /// Продлить подписку
  Future<void> renewSubscription({
    required String subscriptionId,
    required String paymentMethodId,
  }) async {
    try {
      // Получить текущую подписку
      final subscriptionDoc = await _firestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .get();

      if (!subscriptionDoc.exists) {
        throw Exception('Подписка не найдена');
      }

      final subscription = ProSubscription.fromMap(
        subscriptionDoc.data()!,
      );

      // Создать новый платеж
      final payment = await _createPayment(
        subscriptionId: subscriptionId,
        amount: subscription.plan.monthlyPrice,
        currency: subscription.currency,
        paymentMethodId: paymentMethodId,
      );

      if (payment.status != PaymentStatus.completed) {
        throw Exception('Платеж не был завершен');
      }

      // Обновить дату окончания
      final newEndDate = subscription.endDate.add(const Duration(days: 30));
      await updateSubscription(
        subscriptionId: subscriptionId,
        status: SubscriptionStatus.active,
        endDate: newEndDate,
      );
    } catch (e) {
      throw Exception('Ошибка продления подписки: $e');
    }
  }

  /// Получить историю платежей
  Future<List<Payment>> getPaymentHistory({
    required String subscriptionId,
    int limit = 20,
  }) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('payments')
          .where('subscriptionId', isEqualTo: subscriptionId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final payments = <Payment>[];

      for (final doc in snapshot.docs) {
        final payment = Payment.fromMap(doc.data()! as Map<String, dynamic>);
        payments.add(payment);
      }

      return payments;
    } catch (e) {
      throw Exception('Ошибка получения истории платежей: $e');
    }
  }

  /// Проверить доступность функции
  Future<bool> hasFeature({
    required String userId,
    required String feature,
  }) async {
    try {
      final subscription = await getUserSubscription(userId);
      if (subscription == null) return false;

      return subscription.hasFeature(feature);
    } catch (e) {
      throw Exception('Ошибка проверки доступности функции: $e');
    }
  }

  /// Получить доступные планы
  List<SubscriptionPlan> getAvailablePlans() => SubscriptionPlan.values;

  /// Создать платеж
  Future<Payment> _createPayment({
    required String subscriptionId,
    required double amount,
    required String currency,
    required String paymentMethodId,
  }) async {
    try {
      final paymentId = _firestore.collection('payments').doc().id;
      final now = DateTime.now();

      // Создать платеж в Stripe (заглушка)
      // TODO: Интегрировать с реальным Stripe API
      final paymentIntent = Payment(
        id: 'mock_payment_$paymentId',
        subscriptionId: subscriptionId,
        amount: amount,
        currency: currency,
        status: PaymentStatus.completed,
        createdAt: now,
        paymentMethod: paymentMethodId,
        transactionId: 'mock_transaction_$paymentId',
      );

      final payment = paymentIntent;

      await _firestore
          .collection('payments')
          .doc(paymentId)
          .set(payment.toMap());

      return payment;
    } catch (e) {
      throw Exception('Ошибка создания платежа: $e');
    }
  }

  /// Получить функции плана
  Map<String, bool> _getPlanFeatures(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.basic:
        return {
          'basic_profile': true,
          'portfolio_limit_5': true,
          'standard_support': true,
        };
      case SubscriptionPlan.pro:
        return {
          'basic_profile': true,
          'portfolio_limit_5': true,
          'standard_support': true,
          'unlimited_portfolio': true,
          'search_priority': true,
          'advanced_analytics': true,
          'priority_support': true,
          'no_ads': true,
        };
      case SubscriptionPlan.premium:
        return {
          'basic_profile': true,
          'portfolio_limit_5': true,
          'standard_support': true,
          'unlimited_portfolio': true,
          'search_priority': true,
          'advanced_analytics': true,
          'priority_support': true,
          'no_ads': true,
          'exclusive_features': true,
          'personal_manager': true,
          'custom_profile_design': true,
          'api_access': true,
          'white_label': true,
        };
    }
  }

  /// Получить статистику подписок
  Future<Map<String, dynamic>> getSubscriptionStats() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('subscriptions').get();

      var totalSubscriptions = 0;
      var activeSubscriptions = 0;
      var trialSubscriptions = 0;
      var totalRevenue = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        totalSubscriptions++;

        final status = SubscriptionStatus.fromString(data['status'] as String);
        if (status == SubscriptionStatus.active) {
          activeSubscriptions++;
        } else if (status == SubscriptionStatus.trial) {
          trialSubscriptions++;
        }

        totalRevenue += (data['price'] as num?)?.toDouble() ?? 0.0;
      }

      return {
        'totalSubscriptions': totalSubscriptions,
        'activeSubscriptions': activeSubscriptions,
        'trialSubscriptions': trialSubscriptions,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики подписок: $e');
    }
  }

  /// Проверить, нужна ли подписка для функции
  bool requiresSubscription(String feature) {
    const premiumFeatures = [
      'unlimited_portfolio',
      'search_priority',
      'advanced_analytics',
      'priority_support',
      'no_ads',
      'exclusive_features',
      'personal_manager',
      'custom_profile_design',
      'api_access',
      'white_label',
    ];

    return premiumFeatures.contains(feature);
  }

  /// Получить рекомендуемый план для пользователя
  SubscriptionPlan getRecommendedPlan({
    required int portfolioItems,
    required bool needsPriority,
    required bool needsAnalytics,
  }) {
    if (portfolioItems > 5 || needsPriority || needsAnalytics) {
      return SubscriptionPlan.pro;
    }
    return SubscriptionPlan.basic;
  }
}
