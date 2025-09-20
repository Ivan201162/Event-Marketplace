import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/feature_flags.dart';
import '../services/monitoring_service.dart';

/// Провайдер сервиса мониторинга
final monitoringServiceProvider =
    Provider<MonitoringService>((ref) => MonitoringService());

/// Провайдер состояния мониторинга
final monitoringStateProvider =
    NotifierProvider<MonitoringStateNotifier, MonitoringState>(
  MonitoringStateNotifier.new,
);

/// Состояние мониторинга
class MonitoringState {
  const MonitoringState({
    this.isInitialized = false,
    this.isEnabled = false,
    this.metrics = const {},
    this.activeTraces = const [],
    this.lastError,
    this.lastErrorTime,
  });
  final bool isInitialized;
  final bool isEnabled;
  final Map<String, dynamic> metrics;
  final List<String> activeTraces;
  final String? lastError;
  final DateTime? lastErrorTime;

  MonitoringState copyWith({
    bool? isInitialized,
    bool? isEnabled,
    Map<String, dynamic>? metrics,
    List<String>? activeTraces,
    String? lastError,
    DateTime? lastErrorTime,
  }) =>
      MonitoringState(
        isInitialized: isInitialized ?? this.isInitialized,
        isEnabled: isEnabled ?? this.isEnabled,
        metrics: metrics ?? this.metrics,
        activeTraces: activeTraces ?? this.activeTraces,
        lastError: lastError ?? this.lastError,
        lastErrorTime: lastErrorTime ?? this.lastErrorTime,
      );
}

/// Нотификатор состояния мониторинга
class MonitoringStateNotifier extends Notifier<MonitoringState> {
  @override
  MonitoringState build() {
    _initialize();
    return const MonitoringState();
  }

  /// Инициализация мониторинга
  Future<void> _initialize() async {
    try {
      final monitoringService = ref.read(monitoringServiceProvider);
      await monitoringService.initialize();

      state = state.copyWith(
        isInitialized: monitoringService.isInitialized,
        isEnabled: monitoringService.isAvailable,
      );
    } catch (e) {
      state = state.copyWith(
        lastError: e.toString(),
        lastErrorTime: DateTime.now(),
      );
    }
  }

  /// Запись ошибки
  Future<void> recordError(
    error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? customKeys,
  }) async {
    try {
      final monitoringService = ref.read(monitoringServiceProvider);
      await monitoringService.recordError(
        error,
        stackTrace,
        context: reason,
      );

      state = state.copyWith(
        lastError: error.toString(),
        lastErrorTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        lastError: e.toString(),
        lastErrorTime: DateTime.now(),
      );
    }
  }

  /// Запись пользовательского действия
  Future<void> logUserAction(
    String action, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final monitoringService = ref.read(monitoringServiceProvider);
      await monitoringService.logUserAction('', action, parameters);
    } catch (e) {
      state = state.copyWith(
        lastError: e.toString(),
        lastErrorTime: DateTime.now(),
      );
    }
  }

  /// Начало трассировки
  Future<void> startTrace(String traceName) async {
    try {
      final monitoringService = ref.read(monitoringServiceProvider);
      await monitoringService.startTrace(traceName);

      final updatedTraces = List<String>.from(state.activeTraces)
        ..add(traceName);
      state = state.copyWith(activeTraces: updatedTraces);
    } catch (e) {
      state = state.copyWith(
        lastError: e.toString(),
        lastErrorTime: DateTime.now(),
      );
    }
  }

  /// Завершение трассировки
  Future<void> stopTrace(String traceName) async {
    try {
      final monitoringService = ref.read(monitoringServiceProvider);
      await monitoringService.stopTrace(traceName);

      final updatedTraces = List<String>.from(state.activeTraces)
        ..remove(traceName);
      state = state.copyWith(activeTraces: updatedTraces);
    } catch (e) {
      state = state.copyWith(
        lastError: e.toString(),
        lastErrorTime: DateTime.now(),
      );
    }
  }

  /// Обновление метрик
  Future<void> updateMetrics() async {
    try {
      final monitoringService = ref.read(monitoringServiceProvider);
      final metrics = await monitoringService.getAppMetrics();
      state = state.copyWith(metrics: metrics);
    } catch (e) {
      state = state.copyWith(
        lastError: e.toString(),
        lastErrorTime: DateTime.now(),
      );
    }
  }

  /// Установка пользовательского ID
  Future<void> setUserId(String userId) async {
    try {
      final monitoringService = ref.read(monitoringServiceProvider);
      await monitoringService.setUserId(userId);
    } catch (e) {
      state = state.copyWith(
        lastError: e.toString(),
        lastErrorTime: DateTime.now(),
      );
    }
  }

  /// Очистка данных
  Future<void> clearData() async {
    try {
      final monitoringService = ref.read(monitoringServiceProvider);
      await monitoringService.clearData();

      state = state.copyWith(
        metrics: {},
        activeTraces: [],
      );
    } catch (e) {
      state = state.copyWith(
        lastError: e.toString(),
        lastErrorTime: DateTime.now(),
      );
    }
  }
}

/// Провайдер для проверки доступности мониторинга
final monitoringAvailableProvider = Provider<bool>(
  (ref) =>
      FeatureFlags.crashlyticsEnabled ||
      FeatureFlags.performanceMonitoringEnabled,
);

/// Провайдер для получения метрик приложения
final appMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final monitoringService = ref.watch(monitoringServiceProvider);
  return await monitoringService.getAppMetrics();
});

/// Провайдер для мониторинга состояния сети
final networkStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final monitoringService = ref.watch(monitoringServiceProvider);
  return await monitoringService.getNetworkStatus();
});

/// Провайдер для мониторинга использования памяти
final memoryUsageProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final monitoringService = ref.watch(monitoringServiceProvider);
  return await monitoringService.getMemoryUsage();
});
