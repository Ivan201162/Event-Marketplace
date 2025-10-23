import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pro_subscription.dart';
import '../services/pro_subscription_service.dart';

/// Провайдер сервиса PRO подписок
final proSubscriptionServiceProvider = Provider<ProSubscriptionService>(
  (ref) => ProSubscriptionService(),
);

/// Провайдер подписки пользователя
final userSubscriptionProvider =
    FutureProvider.family<ProSubscription?, String>((
  ref,
  userId,
) async {
  final service = ref.read(proSubscriptionServiceProvider);
  return service.getUserSubscription(userId);
});

/// Провайдер доступных планов
final availablePlansProvider = Provider<List<SubscriptionPlan>>((ref) {
  final service = ref.read(proSubscriptionServiceProvider);
  return service.getAvailablePlans();
});

/// Провайдер истории платежей
final paymentHistoryProvider = FutureProvider.family<List<Payment>, String>((
  ref,
  subscriptionId,
) async {
  final service = ref.read(proSubscriptionServiceProvider);
  return service.getPaymentHistory(subscriptionId: subscriptionId);
});

/// Провайдер статистики подписок
final subscriptionStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(proSubscriptionServiceProvider);
  return service.getSubscriptionStats();
});

/// Провайдер проверки доступности функции
final featureAccessProvider =
    FutureProvider.family<bool, FeatureAccessParams>((ref, params) async {
  final service = ref.read(proSubscriptionServiceProvider);
  return service.hasFeature(userId: params.userId, feature: params.feature);
});

/// Параметры для проверки доступа к функции
class FeatureAccessParams {
  const FeatureAccessParams({required this.userId, required this.feature});

  final String userId;
  final String feature;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeatureAccessParams &&
        other.userId == userId &&
        other.feature == feature;
  }

  @override
  int get hashCode => userId.hashCode ^ feature.hashCode;
}

/// Состояние подписки
class SubscriptionState {
  const SubscriptionState({
    this.subscription,
    this.isLoading = false,
    this.isPaymentInProgress = false,
    this.error,
    this.paymentHistory = const [],
  });

  final ProSubscription? subscription;
  final bool isLoading;
  final bool isPaymentInProgress;
  final String? error;
  final List<dynamic> paymentHistory;

  SubscriptionState copyWith({
    ProSubscription? subscription,
    bool? isLoading,
    bool? isPaymentInProgress,
    String? error,
    List<dynamic>? paymentHistory,
  }) =>
      SubscriptionState(
        subscription: subscription ?? this.subscription,
        isLoading: isLoading ?? this.isLoading,
        isPaymentInProgress: isPaymentInProgress ?? this.isPaymentInProgress,
        error: error ?? this.error,
        paymentHistory: paymentHistory ?? this.paymentHistory,
      );
}

/// Notifier для состояния подписки (мигрирован с StateNotifier)
class SubscriptionNotifier extends Notifier<SubscriptionState> {
  late final ProSubscriptionService _service;

  @override
  SubscriptionState build() {
    _service = ref.read(proSubscriptionServiceProvider);
    return const SubscriptionState();
  }

  /// Загрузить подписку пользователя
  Future<void> loadUserSubscription(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      final subscription = await _service.getUserSubscription(userId);
      state = state.copyWith(subscription: subscription, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Создать подписку
  Future<void> createSubscription({
    required String userId,
    required SubscriptionPlan plan,
    required String paymentMethodId,
    bool isTrial = false,
  }) async {
    state = state.copyWith(isPaymentInProgress: true);

    try {
      final subscription = await _service.createSubscription(
        userId: userId,
        plan: plan,
        paymentMethodId: paymentMethodId,
        isTrial: isTrial,
      );

      state = state.copyWith(
          subscription: subscription, isPaymentInProgress: false);
    } catch (e) {
      state = state.copyWith(isPaymentInProgress: false, error: e.toString());
    }
  }

  /// Обновить подписку
  Future<void> updateSubscription({
    required String subscriptionId,
    required SubscriptionPlan plan,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.updateSubscription(
          subscriptionId: subscriptionId, plan: plan);

      // Перезагружаем подписку после обновления
      if (state.subscription != null) {
        await loadUserSubscription(state.subscription!.userId);
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Отменить подписку
  Future<void> cancelSubscription([String? subscriptionId]) async {
    state = state.copyWith(isLoading: true);

    try {
      final id = subscriptionId ?? state.subscription?.id;
      if (id != null) {
        await _service.cancelSubscription(id);

        if (state.subscription != null) {
          await loadUserSubscription(state.subscription!.userId);
        }
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Возобновить подписку
  Future<void> renewSubscription([String? subscriptionId]) async {
    state = state.copyWith(isPaymentInProgress: true);

    try {
      final id = subscriptionId ?? state.subscription?.id;
      if (id != null) {
        final subscription = await _service.renewSubscription(id);

        if (state.subscription != null) {
          await loadUserSubscription(state.subscription!.userId);
        }

        state = state.copyWith(
            subscription: subscription, isPaymentInProgress: false);
      }
    } catch (e) {
      state = state.copyWith(isPaymentInProgress: false, error: e.toString());
    }
  }

  /// Загрузить историю платежей
  Future<void> loadPaymentHistory() async {
    if (state.subscription == null) return;

    try {
      final paymentHistory = await _service.getPaymentHistory(
        subscriptionId: state.subscription!.id,
      );

      state = state.copyWith(paymentHistory: paymentHistory);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith();
  }
}

/// Провайдер состояния подписки (мигрирован с StateNotifierProvider)
final subscriptionStateProvider =
    NotifierProvider<SubscriptionNotifier, SubscriptionState>(
  SubscriptionNotifier.new,
);
