import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subscription_service.dart';
import '../models/subscription.dart';
import '../core/feature_flags.dart';

/// Провайдер сервиса подписок
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

/// Провайдер для проверки доступности подписок
final subscriptionsAvailableProvider = Provider<bool>((ref) {
  return FeatureFlags.subscriptionsEnabled;
});

/// Провайдер подписки пользователя
final userSubscriptionProvider =
    StreamProvider.family<Subscription?, String>((ref, userId) {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return subscriptionService.getUserSubscription(userId);
});

/// Провайдер истории подписок пользователя
final userSubscriptionHistoryProvider =
    StreamProvider.family<List<Subscription>, String>((ref, userId) {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return subscriptionService.getUserSubscriptionHistory(userId);
});

/// Провайдер активных подписок
final activeSubscriptionsProvider = StreamProvider<List<Subscription>>((ref) {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return subscriptionService.getActiveSubscriptions();
});

/// Провайдер подписок, истекающих скоро
final expiringSubscriptionsProvider =
    StreamProvider.family<List<Subscription>, int>((ref, daysAhead) {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return subscriptionService.getExpiringSubscriptions(daysAhead: daysAhead);
});

/// Провайдер типа подписки пользователя
final userSubscriptionTypeProvider =
    FutureProvider.family<SubscriptionType, String>((ref, userId) async {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return await subscriptionService.getUserSubscriptionType(userId);
});

/// Провайдер доступа к функции
final featureAccessProvider =
    FutureProvider.family<bool, ({String userId, String feature})>(
        (ref, params) async {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return await subscriptionService.hasFeatureAccess(
      params.userId, params.feature);
});

/// Провайдер лимита пользователя
final userLimitProvider =
    FutureProvider.family<int, ({String userId, String limit})>(
        (ref, params) async {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return await subscriptionService.getUserLimit(params.userId, params.limit);
});

/// Провайдер проверки превышения лимита
final limitExceededProvider = FutureProvider.family<bool,
    ({String userId, String limit, int currentUsage})>((ref, params) async {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return await subscriptionService.isLimitExceeded(
      params.userId, params.limit, params.currentUsage);
});

/// Провайдер статистики подписок
final subscriptionStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return await subscriptionService.getSubscriptionStats();
});
