import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription.dart';
import '../models/subscription_notification.dart';
import '../models/specialist_recommendation.dart';
import '../services/subscription_service.dart';

/// Провайдер сервиса подписок
final subscriptionServiceProvider =
    Provider<SubscriptionService>((ref) => SubscriptionService());

/// Провайдер для подписок пользователя
final userSubscriptionsProvider =
    StreamProvider.family<List<Subscription>, String>((ref, userId) {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return subscriptionService.getUserSubscriptions(userId);
});

/// Провайдер для проверки подписки
final isSubscribedProvider =
    FutureProvider.family<bool, IsSubscribedParams>((ref, params) async {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return subscriptionService.isSubscribed(params.userId, params.specialistId);
});

/// Параметры для проверки подписки
class IsSubscribedParams {
  const IsSubscribedParams({
    required this.userId,
    required this.specialistId,
  });
  final String userId;
  final String specialistId;
}

/// Провайдер для подписчиков специалиста
final specialistSubscribersProvider =
    StreamProvider.family<List<Subscription>, String>((ref, specialistId) {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return subscriptionService.getSpecialistSubscribers(specialistId);
});

/// Провайдер для состояния подписок
final subscriptionStateProvider =
    NotifierProvider<SubscriptionStateNotifier, SubscriptionState>(
  SubscriptionStateNotifier.new,
);

/// Состояние подписок
class SubscriptionState {
  const SubscriptionState({
    this.subscriptions = const [],
    this.isLoading = false,
    this.error,
    this.subscriptionStatus = const {},
  });
  final List<Subscription> subscriptions;
  final bool isLoading;
  final String? error;
  final Map<String, bool> subscriptionStatus;

  SubscriptionState copyWith({
    List<Subscription>? subscriptions,
    bool? isLoading,
    String? error,
    Map<String, bool>? subscriptionStatus,
  }) =>
      SubscriptionState(
        subscriptions: subscriptions ?? this.subscriptions,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      );
}

/// Нотификатор для состояния подписок
class SubscriptionStateNotifier extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() => const SubscriptionState();

  void setSubscriptions(List<Subscription> subscriptions) {
    state = state.copyWith(subscriptions: subscriptions);
  }

  void addSubscription(Subscription subscription) {
    final updatedSubscriptions = [...state.subscriptions, subscription];
    state = state.copyWith(subscriptions: updatedSubscriptions);
  }

  void removeSubscription(String subscriptionId) {
    final updatedSubscriptions =
        state.subscriptions.where((s) => s.id != subscriptionId).toList();
    state = state.copyWith(subscriptions: updatedSubscriptions);
  }

  void updateSubscriptionStatus(String specialistId, bool isSubscribed) {
    final updatedStatus = Map<String, bool>.from(state.subscriptionStatus);
    updatedStatus[specialistId] = isSubscribed;
    state = state.copyWith(subscriptionStatus: updatedStatus);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}

/// Провайдер для уведомлений подписок
final userNotificationsProvider =
    StreamProvider.family<List<SubscriptionNotification>, String>(
        (ref, userId) {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return subscriptionService.getUserNotifications(userId);
});

/// Провайдер для похожих специалистов
final similarSpecialistsRecommendationsProvider =
    FutureProvider.family<List<SpecialistRecommendation>, String>(
        (ref, specialistId) async {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return subscriptionService.getSimilarSpecialists(specialistId);
});
