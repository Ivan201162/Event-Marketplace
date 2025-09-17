import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:event_marketplace_app/services/monitoring_service.dart';
import 'package:event_marketplace_app/core/feature_flags.dart';

/// Провайдер сервиса мониторинга
final monitoringServiceProvider = Provider<MonitoringService>((ref) {
  return MonitoringService();
});

/// Провайдер состояния мониторинга
final monitoringStateProvider =
    StateNotifierProvider<MonitoringStateNotifier, MonitoringState>((ref) {
  final monitoringService = ref.watch(monitoringServiceProvider);
  return MonitoringStateNotifier(monitoringService);
});

/// Состояние мониторинга
class MonitoringState {
  final bool isInitialized;
  final bool isEnabled;
  final Map<String, dynamic> metrics;
  final List<String> activeTraces;
  final String? lastError;
  final DateTime? lastErrorTime;

  const MonitoringState({
    this.isInitialized = false,
    this.isEnabled = false,
    this.metrics = const {},
    this.activeTraces = const [],
    this.lastError,
    this.lastErrorTime,
  });

  MonitoringState copyWith({
    bool? isInitialized,
    bool? isEnabled,
    Map<String, dynamic>? metrics,
    List<String>? activeTraces,
    String? lastError,
    DateTime? lastErrorTime,
  }) {
    return MonitoringState(
      isInitialized: isInitialized ?? this.isInitialized,
      isEnabled: isEnabled ?? this.isEnabled,
      metrics: metrics ?? this.metrics,
      activeTraces: activeTraces ?? this.activeTraces,
      lastError: lastError ?? this.lastError,
      lastErrorTime: lastErrorTime ?? this.lastErrorTime,
    );
  }
}

/// Нотификатор состояния мониторинга
class MonitoringStateNotifier extends StateNotifier<MonitoringState> {
  final MonitoringService _monitoringService;

  MonitoringStateNotifier(this._monitoringService)
      : super(const MonitoringState()) {
    _initialize();
  }

  /// Инициализация мониторинга
  Future<void> _initialize() async {
    try {
      await _monitoringService.initialize();

      state = state.copyWith(
        isInitialized: _monitoringService.isInitialized,
        isEnabled: _monitoringService.isAvailable,
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
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? customKeys,
  }) async {
    try {
      await _monitoringService.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
        customKeys: customKeys,
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
  Future<void> logUserAction(String action,
      {Map<String, dynamic>? parameters}) async {
    try {
      await _monitoringService.logUserAction(action, parameters: parameters);
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
      await _monitoringService.startTrace(traceName);

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
      await _monitoringService.stopTrace(traceName);

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
      final metrics = await _monitoringService.getAppMetrics();
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
      await _monitoringService.setUserId(userId);
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
      await _monitoringService.clearData();

      state = state.copyWith(
        metrics: {},
        activeTraces: [],
        lastError: null,
        lastErrorTime: null,
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
final monitoringAvailableProvider = Provider<bool>((ref) {
  return FeatureFlags.crashlyticsEnabled ||
      FeatureFlags.performanceMonitoringEnabled;
});

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
