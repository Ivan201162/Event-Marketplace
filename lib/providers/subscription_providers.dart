import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:event_marketplace_app/models/subscription.dart';
import 'package:event_marketplace_app/services/subscription_service.dart';

part 'subscription_providers.g.dart';

/// Провайдер для SubscriptionService
@riverpod
SubscriptionService subscriptionService(SubscriptionServiceRef ref) {
  return SubscriptionService();
}

/// Провайдер для проверки подписки
@riverpod
Future<bool> isSubscribed(
  IsSubscribedRef ref, {
  required String userId,
  required String specialistId,
}) async {
  final service = ref.watch(subscriptionServiceProvider);
  return service.isSubscribed(
    userId: userId,
    specialistId: specialistId,
  );
}

/// Провайдер для получения подписок пользователя
@riverpod
Future<List<Subscription>> userSubscriptions(
    UserSubscriptionsRef ref, String userId) async {
  final service = ref.watch(subscriptionServiceProvider);
  return service.getUserSubscriptions(userId);
}

/// Провайдер для получения подписчиков специалиста
@riverpod
Future<List<Subscription>> specialistSubscribers(
    SpecialistSubscribersRef ref, String specialistId) async {
  final service = ref.watch(subscriptionServiceProvider);
  return service.getSpecialistSubscribers(specialistId);
}

/// Провайдер для получения количества подписчиков
@riverpod
Future<int> specialistSubscribersCount(
    SpecialistSubscribersCountRef ref, String specialistId) async {
  final service = ref.watch(subscriptionServiceProvider);
  return service.getSpecialistSubscribersCount(specialistId);
}

/// Провайдер для получения уведомлений пользователя
@riverpod
Future<List<SubscriptionNotification>> userNotifications(
    UserNotificationsRef ref, String userId) async {
  final service = ref.watch(subscriptionServiceProvider);
  return service.getUserNotifications(userId: userId);
}

/// Провайдер для получения количества непрочитанных уведомлений
@riverpod
Future<int> unreadNotificationsCount(
    UnreadNotificationsCountRef ref, String userId) async {
  final service = ref.watch(subscriptionServiceProvider);
  return service.getUnreadNotificationsCount(userId);
}
