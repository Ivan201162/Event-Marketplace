import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../analytics/analytics_service.dart';
import '../providers/analytics_providers.dart';
import '../core/feature_flags.dart';

/// Обертка для автоматического отслеживания аналитики
class AnalyticsWrapper extends ConsumerWidget {
  final Widget child;
  final String screenName;
  final Map<String, dynamic>? parameters;

  const AnalyticsWrapper({
    super.key,
    required this.child,
    required this.screenName,
    this.parameters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Инициализируем аналитику при первом использовании
    ref.listen(analyticsInitializationProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          // Аналитика инициализирована
        },
        error: (error, stackTrace) {
          // Ошибка инициализации аналитики
        },
      );
    });

    // Отслеживаем просмотр экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackScreenView(ref);
    });

    return child;
  }

  void _trackScreenView(WidgetRef ref) {
    if (!FeatureFlags.analyticsEnabled) return;

    final analyticsService = ref.read(analyticsServiceProvider);

    analyticsService.logScreenView(
      screenName,
      parameters: parameters,
    );
  }
}

/// Миксин для добавления аналитики в виджеты
mixin AnalyticsMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  AnalyticsService get analytics => ref.read(analyticsServiceProvider);

  /// Отправить событие
  Future<void> trackEvent(
    AnalyticsEventType type, {
    Map<String, dynamic>? parameters,
  }) async {
    await analytics.logEventWithParams(type, parameters ?? {});
  }

  /// Отправить простое событие
  Future<void> trackSimpleEvent(AnalyticsEventType type) async {
    await analytics.logSimpleEvent(type);
  }

  /// Отправить событие ошибки
  Future<void> trackError(
    String error,
    String description, {
    Map<String, dynamic>? parameters,
  }) async {
    await analytics.logError(
      error: error,
      description: description,
      parameters: parameters,
    );
  }

  /// Отправить событие производительности
  Future<void> trackPerformance(
    String operation,
    int durationMs, {
    Map<String, dynamic>? parameters,
  }) async {
    await analytics.logPerformance(
      operation: operation,
      durationMs: durationMs,
      parameters: parameters,
    );
  }

  /// Отправить событие навигации
  Future<void> trackNavigation({
    required String fromScreen,
    required String toScreen,
    String? action,
    Map<String, dynamic>? parameters,
  }) async {
    await analytics.logNavigationEvent(
      fromScreen: fromScreen,
      toScreen: toScreen,
      action: action,
      parameters: parameters,
    );
  }

  /// Отправить пользовательское событие
  Future<void> trackCustomEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    await analytics.logCustomEvent(
      eventName: eventName,
      parameters: parameters,
    );
  }
}

/// Виджет для отслеживания нажатий кнопок
class AnalyticsButton extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String buttonName;
  final String? screenName;
  final Map<String, dynamic>? parameters;

  const AnalyticsButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.buttonName,
    this.screenName,
    this.parameters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        _trackButtonClick(ref);
        onPressed?.call();
      },
      child: child,
    );
  }

  void _trackButtonClick(WidgetRef ref) {
    if (!FeatureFlags.analyticsEnabled) return;

    final analyticsService = ref.read(analyticsServiceProvider);

    analyticsService.logEventWithParams(
      AnalyticsEventType.buttonClicked,
      {
        'button_name': buttonName,
        'screen_name': screenName ?? 'unknown',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        ...?parameters,
      },
    );
  }
}

/// Виджет для отслеживания навигации
class AnalyticsNavigator extends ConsumerWidget {
  final Widget child;

  const AnalyticsNavigator({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Navigator(
      onGenerateRoute: (settings) {
        _trackNavigation(ref, settings.name ?? 'unknown');
        return MaterialPageRoute(
          builder: (context) => child,
          settings: settings,
        );
      },
    );
  }

  void _trackNavigation(WidgetRef ref, String routeName) {
    if (!FeatureFlags.analyticsEnabled) return;

    final analyticsService = ref.read(analyticsServiceProvider);

    analyticsService.logNavigationEvent(
      fromScreen: 'previous',
      toScreen: routeName,
      action: 'navigate',
    );
  }
}

/// Виджет для отслеживания ошибок
class AnalyticsErrorBoundary extends ConsumerWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace stackTrace)? errorBuilder;

  const AnalyticsErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (error, stackTrace) {
          _trackError(ref, error, stackTrace);

          if (errorBuilder != null) {
            return errorBuilder!(error, stackTrace);
          }

          return ErrorWidget(error);
        }
      },
    );
  }

  void _trackError(WidgetRef ref, Object error, StackTrace stackTrace) {
    if (!FeatureFlags.analyticsEnabled) return;

    final analyticsService = ref.read(analyticsServiceProvider);

    analyticsService.logError(
      error: error.toString(),
      description: 'Widget error boundary caught an error',
      parameters: {
        'error_type': error.runtimeType.toString(),
        'stack_trace': stackTrace.toString(),
      },
    );
  }
}

/// Виджет для отслеживания производительности
class AnalyticsPerformanceTracker extends ConsumerWidget {
  final Widget child;
  final String operationName;
  final Map<String, dynamic>? parameters;

  const AnalyticsPerformanceTracker({
    super.key,
    required this.child,
    required this.operationName,
    this.parameters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startTime = DateTime.now();

    return Builder(
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final endTime = DateTime.now();
          final duration = endTime.difference(startTime).inMilliseconds;

          _trackPerformance(ref, duration);
        });

        return child;
      },
    );
  }

  void _trackPerformance(WidgetRef ref, int durationMs) {
    if (!FeatureFlags.analyticsEnabled) return;

    final analyticsService = ref.read(analyticsServiceProvider);

    analyticsService.logPerformance(
      operation: operationName,
      durationMs: durationMs,
      parameters: parameters,
    );
  }
}
