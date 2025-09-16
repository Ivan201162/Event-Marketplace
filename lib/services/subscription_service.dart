import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription.dart';
import '../core/feature_flags.dart';
import '../core/safe_log.dart';

/// Сервис для работы с подписками
class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Коллекции
  static const String _subscriptionsCollection = 'subscriptions';

  /// Получить подписку пользователя
  Stream<Subscription?> getUserSubscription(String userId) {
    return _firestore
        .collection(_subscriptionsCollection)
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
          SubscriptionStatus.active.name,
          SubscriptionStatus.pending.name,
        ])
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return Subscription.fromDocument(snapshot.docs.first);
      }
      return null;
    });
  }

  /// Создать подписку
  Future<Subscription> createSubscription({
    required String userId,
    required SubscriptionType type,
    required SubscriptionPeriod period,
    required double price,
    required String currency,
    String? paymentId,
    String? paymentMethod,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      SafeLog.info('SubscriptionService: Creating subscription for user $userId');

      // Проверяем, есть ли уже активная подписка
      final existingSubscription = await _getActiveSubscription(userId);
      if (existingSubscription != null) {
        throw Exception('У пользователя уже есть активная подписка');
      }

      // Определяем даты
      final now = DateTime.now();
      final endDate = _calculateEndDate(now, period);

      // Получаем функции и лимиты для типа подписки
      final plan = SubscriptionPlans.getPlanByType(type);
      if (plan == null) {
        throw Exception('Неизвестный тип подписки: $type');
      }

      // Создаем подписку
      final subscription = Subscription(
        id: '', // Будет установлен Firestore
        userId: userId,
        type: type,
        status: SubscriptionStatus.active,
        period: period,
        startDate: now,
        endDate: endDate,
        price: price,
        currency: currency,
        paymentId: paymentId,
        paymentMethod: paymentMethod,
        features: _getFeaturesMap(plan),
        limits: _getLimitsMap(plan),
        autoRenew: true,
        createdAt: now,
        updatedAt: now,
        metadata: metadata,
      );

      // Сохраняем в Firestore
      final docRef = await _firestore.collection(_subscriptionsCollection).add(subscription.toMap());
      
      // Обновляем ID
      final createdSubscription = subscription.copyWith(id: docRef.id);

      SafeLog.info('SubscriptionService: Subscription created successfully: ${docRef.id}');

      return createdSubscription;
    } catch (e, stackTrace) {
      SafeLog.error('SubscriptionService: Error creating subscription', e, stackTrace);
      rethrow;
    }
  }

  /// Обновить подписку
  Future<Subscription> updateSubscription(
    String subscriptionId, {
    SubscriptionType? type,
    SubscriptionStatus? status,
    SubscriptionPeriod? period,
    DateTime? endDate,
    bool? autoRenew,
    String? cancellationReason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      SafeLog.info('SubscriptionService: Updating subscription $subscriptionId');

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (type != null) {
        updateData['type'] = type.name;
        // Обновляем функции и лимиты при изменении типа
        final plan = SubscriptionPlans.getPlanByType(type);
        if (plan != null) {
          updateData['features'] = _getFeaturesMap(plan);
          updateData['limits'] = _getLimitsMap(plan);
        }
      }
      if (status != null) updateData['status'] = status.name;
      if (period != null) updateData['period'] = period.name;
      if (endDate != null) updateData['endDate'] = Timestamp.fromDate(endDate);
      if (autoRenew != null) updateData['autoRenew'] = autoRenew;
      if (cancellationReason != null) {
        updateData['cancellationReason'] = cancellationReason;
        updateData['cancelledAt'] = FieldValue.serverTimestamp();
      }
      if (metadata != null) updateData['metadata'] = metadata;

      await _firestore.collection(_subscriptionsCollection).doc(subscriptionId).update(updateData);

      // Получаем обновленную подписку
      final doc = await _firestore.collection(_subscriptionsCollection).doc(subscriptionId).get();
      final updatedSubscription = Subscription.fromDocument(doc);

      SafeLog.info('SubscriptionService: Subscription updated successfully');

      return updatedSubscription;
    } catch (e, stackTrace) {
      SafeLog.error('SubscriptionService: Error updating subscription', e, stackTrace);
      rethrow;
    }
  }

  /// Отменить подписку
  Future<void> cancelSubscription(
    String subscriptionId, {
    String? reason,
  }) async {
    try {
      SafeLog.info('SubscriptionService: Cancelling subscription $subscriptionId');

      await _firestore.collection(_subscriptionsCollection).doc(subscriptionId).update({
        'status': SubscriptionStatus.cancelled.name,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      SafeLog.info('SubscriptionService: Subscription cancelled successfully');
    } catch (e, stackTrace) {
      SafeLog.error('SubscriptionService: Error cancelling subscription', e, stackTrace);
      rethrow;
    }
  }

  /// Продлить подписку
  Future<Subscription> renewSubscription(
    String subscriptionId, {
    SubscriptionPeriod? newPeriod,
  }) async {
    try {
      SafeLog.info('SubscriptionService: Renewing subscription $subscriptionId');

      // Получаем текущую подписку
      final doc = await _firestore.collection(_subscriptionsCollection).doc(subscriptionId).get();
      if (!doc.exists) {
        throw Exception('Подписка не найдена');
      }

      final currentSubscription = Subscription.fromDocument(doc);
      final period = newPeriod ?? currentSubscription.period;
      
      // Вычисляем новую дату окончания
      final newEndDate = _calculateEndDate(currentSubscription.endDate, period);

      // Обновляем подписку
      await _firestore.collection(_subscriptionsCollection).doc(subscriptionId).update({
        'status': SubscriptionStatus.active.name,
        'period': period.name,
        'endDate': Timestamp.fromDate(newEndDate),
        'autoRenew': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Получаем обновленную подписку
      final updatedDoc = await _firestore.collection(_subscriptionsCollection).doc(subscriptionId).get();
      final renewedSubscription = Subscription.fromDocument(updatedDoc);

      SafeLog.info('SubscriptionService: Subscription renewed successfully');

      return renewedSubscription;
    } catch (e, stackTrace) {
      SafeLog.error('SubscriptionService: Error renewing subscription', e, stackTrace);
      rethrow;
    }
  }

  /// Переключить автопродление
  Future<void> toggleAutoRenew(String subscriptionId, bool autoRenew) async {
    try {
      SafeLog.info('SubscriptionService: Toggling auto-renew for subscription $subscriptionId');

      await _firestore.collection(_subscriptionsCollection).doc(subscriptionId).update({
        'autoRenew': autoRenew,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      SafeLog.info('SubscriptionService: Auto-renew toggled successfully');
    } catch (e, stackTrace) {
      SafeLog.error('SubscriptionService: Error toggling auto-renew', e, stackTrace);
      rethrow;
    }
  }

  /// Получить историю подписок пользователя
  Stream<List<Subscription>> getUserSubscriptionHistory(String userId) {
    return _firestore
        .collection(_subscriptionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Subscription.fromDocument(doc)).toList();
    });
  }

  /// Получить все активные подписки
  Stream<List<Subscription>> getActiveSubscriptions() {
    return _firestore
        .collection(_subscriptionsCollection)
        .where('status', isEqualTo: SubscriptionStatus.active.name)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Subscription.fromDocument(doc)).toList();
    });
  }

  /// Получить подписки, истекающие скоро
  Stream<List<Subscription>> getExpiringSubscriptions({int daysAhead = 7}) {
    final futureDate = DateTime.now().add(Duration(days: daysAhead));
    
    return _firestore
        .collection(_subscriptionsCollection)
        .where('status', isEqualTo: SubscriptionStatus.active.name)
        .where('endDate', isLessThanOrEqualTo: Timestamp.fromDate(futureDate))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Subscription.fromDocument(doc)).toList();
    });
  }

  /// Проверить, есть ли у пользователя доступ к функции
  Future<bool> hasFeatureAccess(String userId, String feature) async {
    try {
      final subscription = await _getActiveSubscription(userId);
      if (subscription == null) {
        // Проверяем бесплатный план
        final freePlan = SubscriptionPlans.getPlanByType(SubscriptionType.free);
        return freePlan?.hasFeature(feature) ?? false;
      }
      
      return subscription.hasFeature(feature);
    } catch (e, stackTrace) {
      SafeLog.error('SubscriptionService: Error checking feature access', e, stackTrace);
      return false;
    }
  }

  /// Проверить, превышен ли лимит
  Future<bool> isLimitExceeded(String userId, String limit, int currentUsage) async {
    try {
      final subscription = await _getActiveSubscription(userId);
      if (subscription == null) {
        // Проверяем бесплатный план
        final freePlan = SubscriptionPlans.getPlanByType(SubscriptionType.free);
        return freePlan?.isLimitExceeded(limit, currentUsage) ?? false;
      }
      
      return subscription.isLimitExceeded(limit, currentUsage);
    } catch (e, stackTrace) {
      SafeLog.error('SubscriptionService: Error checking limit', e, stackTrace);
      return false;
    }
  }

  /// Получить лимит для пользователя
  Future<int> getUserLimit(String userId, String limit) async {
    try {
      final subscription = await _getActiveSubscription(userId);
      if (subscription == null) {
        // Возвращаем лимит бесплатного плана
        final freePlan = SubscriptionPlans.getPlanByType(SubscriptionType.free);
        return freePlan?.getLimit(limit) ?? 0;
      }
      
      return subscription.getLimit(limit);
    } catch (e, stackTrace) {
      SafeLog.error('SubscriptionService: Error getting user limit', e, stackTrace);
      return 0;
    }
  }

  /// Получить тип подписки пользователя
  Future<SubscriptionType> getUserSubscriptionType(String userId) async {
    try {
      final subscription = await _getActiveSubscription(userId);
      return subscription?.type ?? SubscriptionType.free;
    } catch (e, stackTrace) {
      SafeLog.error('SubscriptionService: Error getting user subscription type', e, stackTrace);
      return SubscriptionType.free;
    }
  }

  /// Получить активную подписку пользователя
  Future<Subscription?> _getActiveSubscription(String userId) async {
    try {
      final query = await _firestore
          .collection(_subscriptionsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: [
            SubscriptionStatus.active.name,
            SubscriptionStatus.pending.name,
          ])
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return Subscription.fromDocument(query.docs.first);
      }
      return null;
    } catch (e, stackTrace) {
      SafeLog.error('SubscriptionService: Error getting active subscription', e, stackTrace);
      return null;
    }
  }

  /// Вычислить дату окончания подписки
  DateTime _calculateEndDate(DateTime startDate, SubscriptionPeriod period) {
    switch (period) {
      case SubscriptionPeriod.monthly:
        return DateTime(
          startDate.year,
          startDate.month + 1,
          startDate.day,
          startDate.hour,
          startDate.minute,
          startDate.second,
        );
      case SubscriptionPeriod.quarterly:
        return DateTime(
          startDate.year,
          startDate.month + 3,
          startDate.day,
          startDate.hour,
          startDate.minute,
          startDate.second,
        );
      case SubscriptionPeriod.yearly:
        return DateTime(
          startDate.year + 1,
          startDate.month,
          startDate.day,
          startDate.hour,
          startDate.minute,
          startDate.second,
        );
      case SubscriptionPeriod.lifetime:
        return DateTime(
          startDate.year + 100, // Практически навсегда
          startDate.month,
          startDate.day,
          startDate.hour,
          startDate.minute,
          startDate.second,
        );
    }
  }

  /// Получить карту функций из плана
  Map<String, dynamic> _getFeaturesMap(SubscriptionPlan plan) {
    final featuresMap = <String, dynamic>{};
    for (final feature in plan.features) {
      featuresMap[feature] = true;
    }
    return featuresMap;
  }

  /// Получить карту лимитов из плана
  Map<String, dynamic> _getLimitsMap(SubscriptionPlan plan) {
    return Map<String, dynamic>.from(plan.limits);
  }

  /// Обработать истекшие подписки
  Future<void> processExpiredSubscriptions() async {
    try {
      SafeLog.info('SubscriptionService: Processing expired subscriptions');

      final now = DateTime.now();
      final query = await _firestore
          .collection(_subscriptionsCollection)
          .where('status', isEqualTo: SubscriptionStatus.active.name)
          .where('endDate', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = _firestore.batch();
      
      for (final doc in query.docs) {
        batch.update(doc.reference, {
          'status': SubscriptionStatus.expired.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      SafeLog.info('SubscriptionService: Processed ${query.docs.length} expired subscriptions');
    } catch (e, stackTrace) {
      SafeLog.error('SubscriptionService: Error processing expired subscriptions', e, stackTrace);
    }
  }

  /// Получить статистику подписок
  Future<Map<String, dynamic>> getSubscriptionStats() async {
    try {
      SafeLog.info('SubscriptionService: Getting subscription stats');

      final activeQuery = await _firestore
          .collection(_subscriptionsCollection)
          .where('status', isEqualTo: SubscriptionStatus.active.name)
          .get();

      final totalQuery = await _firestore
          .collection(_subscriptionsCollection)
          .get();

      final stats = <String, dynamic>{
        'totalSubscriptions': totalQuery.docs.length,
        'activeSubscriptions': activeQuery.docs.length,
        'expiredSubscriptions': 0,
        'cancelledSubscriptions': 0,
        'revenue': 0.0,
        'subscriptionTypes': <String, int>{},
      };

      // Подсчитываем статистику по типам и статусам
      for (final doc in totalQuery.docs) {
        final subscription = Subscription.fromDocument(doc);
        
        // Статистика по статусам
        switch (subscription.status) {
          case SubscriptionStatus.expired:
            stats['expiredSubscriptions']++;
            break;
          case SubscriptionStatus.cancelled:
            stats['cancelledSubscriptions']++;
            break;
          default:
            break;
        }

        // Статистика по типам
        final typeName = subscription.type.name;
        stats['subscriptionTypes'][typeName] = (stats['subscriptionTypes'][typeName] ?? 0) + 1;

        // Доход (только для активных подписок)
        if (subscription.status == SubscriptionStatus.active) {
          stats['revenue'] += subscription.price;
        }
      }

      SafeLog.info('SubscriptionService: Subscription stats calculated');

      return stats;
    } catch (e, stackTrace) {
      SafeLog.error('SubscriptionService: Error getting subscription stats', e, stackTrace);
      return {};
    }
  }
}
