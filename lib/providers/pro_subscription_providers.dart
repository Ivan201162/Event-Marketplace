import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pro_subscription.dart';
import '../services/pro_subscription_service.dart';

/// Провайдер сервиса PRO подписок
final proSubscriptionServiceProvider =
    Provider<ProSubscriptionService>((ref) => ProSubscriptionService());

/// Провайдер подписки пользователя
final userSubscriptionProvider =
    FutureProvider.family<ProSubscription?, String>((ref, userId) async {
  final service = ref.read(proSubscriptionServiceProvider);
  return service.getUserSubscription(userId);
});

/// Провайдер доступных планов
final availablePlansProvider = Provider<List<SubscriptionPlan>>((ref) {
  final service = ref.read(proSubscriptionServiceProvider);
  return service.getAvailablePlans();
});

/// Провайдер истории платежей
final paymentHistoryProvider =
    FutureProvider.family<List<Payment>, String>((ref, subscriptionId) async {
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
  return service.hasFeature(
    userId: params.userId,
    feature: params.feature,
  );
});

/// Параметры для проверки доступа к функции
class FeatureAccessParams {
  const FeatureAccessParams({
    required this.userId,
    required this.feature,
  });
  final String userId;
  final String feature;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeatureAccessParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          feature == other.feature;

  @override
  int get hashCode => userId.hashCode ^ feature.hashCode;
}

/// Провайдер для управления состоянием подписки
final subscriptionStateProvider =
    StateNotifierProvider<SubscriptionStateNotifier, SubscriptionState>((ref) =>
        SubscriptionStateNotifier(ref.read(proSubscriptionServiceProvider)));

/// Состояние подписки
class SubscriptionState {
  const SubscriptionState({
    this.subscription,
    this.isLoading = false,
    this.error,
    this.paymentHistory = const [],
    this.isPaymentInProgress = false,
  });
  final ProSubscription? subscription;
  final bool isLoading;
  final String? error;
  final List<Payment> paymentHistory;
  final bool isPaymentInProgress;

  SubscriptionState copyWith({
    ProSubscription? subscription,
    bool? isLoading,
    String? error,
    List<Payment>? paymentHistory,
    bool? isPaymentInProgress,
  }) =>
      SubscriptionState(
        subscription: subscription ?? this.subscription,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        paymentHistory: paymentHistory ?? this.paymentHistory,
        isPaymentInProgress: isPaymentInProgress ?? this.isPaymentInProgress,
      );
}

/// Нотификатор состояния подписки
class SubscriptionStateNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionStateNotifier(this._service) : super(const SubscriptionState());
  final ProSubscriptionService _service;

  /// Загрузить подписку пользователя
  Future<void> loadUserSubscription(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      final subscription = await _service.getUserSubscription(userId);
      state = state.copyWith(
        subscription: subscription,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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
        subscription: subscription,
        isPaymentInProgress: false,
      );
    } catch (e) {
      state = state.copyWith(
        isPaymentInProgress: false,
        error: e.toString(),
      );
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
    state = state.copyWith(isLoading: true);

    try {
      await _service.updateSubscription(
        subscriptionId: subscriptionId,
        plan: plan,
        status: status,
        endDate: endDate,
        autoRenew: autoRenew,
        features: features,
      );

      // Перезагрузить подписку
      if (state.subscription != null) {
        await loadUserSubscription(state.subscription!.userId);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Отменить подписку
  Future<void> cancelSubscription({
    required String subscriptionId,
    String? reason,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.cancelSubscription(
        subscriptionId: subscriptionId,
        reason: reason,
      );

      // Перезагрузить подписку
      if (state.subscription != null) {
        await loadUserSubscription(state.subscription!.userId);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Продлить подписку
  Future<void> renewSubscription({
    required String subscriptionId,
    required String paymentMethodId,
  }) async {
    state = state.copyWith(isPaymentInProgress: true);

    try {
      await _service.renewSubscription(
        subscriptionId: subscriptionId,
        paymentMethodId: paymentMethodId,
      );

      // Перезагрузить подписку
      if (state.subscription != null) {
        await loadUserSubscription(state.subscription!.userId);
      }
    } catch (e) {
      state = state.copyWith(
        isPaymentInProgress: false,
        error: e.toString(),
      );
    }
  }

  /// Загрузить историю платежей
  Future<void> loadPaymentHistory(String subscriptionId) async {
    try {
      final paymentHistory = await _service.getPaymentHistory(
        subscriptionId: subscriptionId,
      );

      state = state.copyWith(paymentHistory: paymentHistory);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Проверить доступность функции
  Future<bool> hasFeature({
    required String userId,
    required String feature,
  }) async {
    try {
      return await _service.hasFeature(
        userId: userId,
        feature: feature,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith();
  }
}
