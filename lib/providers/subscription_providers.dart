import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';

/// Провайдер сервиса подписок
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

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
  final String userId;
  final String specialistId;

  const IsSubscribedParams({
    required this.userId,
    required this.specialistId,
  });
}

/// Провайдер для подписчиков специалиста
final specialistSubscribersProvider =
    StreamProvider.family<List<Subscription>, String>((ref, specialistId) {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return subscriptionService.getSpecialistSubscribers(specialistId);
});

/// Провайдер для состояния подписок
final subscriptionStateProvider =
    StateNotifierProvider<SubscriptionStateNotifier, SubscriptionState>((ref) {
  return SubscriptionStateNotifier();
});

/// Состояние подписок
class SubscriptionState {
  final List<Subscription> subscriptions;
  final bool isLoading;
  final String? error;
  final Map<String, bool> subscriptionStatus;

  const SubscriptionState({
    this.subscriptions = const [],
    this.isLoading = false,
    this.error,
    this.subscriptionStatus = const {},
  });

  SubscriptionState copyWith({
    List<Subscription>? subscriptions,
    bool? isLoading,
    String? error,
    Map<String, bool>? subscriptionStatus,
  }) {
    return SubscriptionState(
      subscriptions: subscriptions ?? this.subscriptions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
    );
  }
}

/// Нотификатор для состояния подписок
class SubscriptionStateNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionStateNotifier() : super(const SubscriptionState());

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
