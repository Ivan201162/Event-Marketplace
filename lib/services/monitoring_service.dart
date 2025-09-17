import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:event_marketplace_app/core/feature_flags.dart';
import 'package:event_marketplace_app/core/safe_log.dart';

/// Сервис мониторинга приложения
class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  final FirebasePerformance _performance = FirebasePerformance.instance;

  bool _isInitialized = false;
  final Map<String, Trace> _activeTraces = {};
  final Map<String, Timer> _timers = {};

  /// Инициализация мониторинга
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Настройка Crashlytics
      if (FeatureFlags.crashlyticsEnabled) {
        await _setupCrashlytics();
      }

      // Настройка Performance Monitoring
      if (FeatureFlags.performanceMonitoringEnabled) {
        await _setupPerformanceMonitoring();
      }

      // Настройка глобальных обработчиков ошибок
      _setupGlobalErrorHandlers();

      _isInitialized = true;
      SafeLog.info('Monitoring service initialized');
    } catch (e) {
      SafeLog.error('Failed to initialize monitoring service', e);
    }
  }

  /// Настройка Crashlytics
  Future<void> _setupCrashlytics() async {
    try {
      // Включение автоматического сбора данных о сбоях
      await _crashlytics.setCrashlyticsCollectionEnabled(true);

      // Настройка пользовательских ключей
      await _crashlytics.setCustomKey('app_version', '1.0.0');
      await _crashlytics.setCustomKey('platform', Platform.operatingSystem);

      SafeLog.info('Crashlytics configured');
    } catch (e) {
      SafeLog.error('Failed to setup Crashlytics', e);
    }
  }

  /// Настройка Performance Monitoring
  Future<void> _setupPerformanceMonitoring() async {
    try {
      // Включение мониторинга производительности
      await _performance.setPerformanceCollectionEnabled(true);

      SafeLog.info('Performance monitoring configured');
    } catch (e) {
      SafeLog.error('Failed to setup performance monitoring', e);
    }
  }

  /// Настройка глобальных обработчиков ошибок
  void _setupGlobalErrorHandlers() {
    // Обработка Flutter ошибок
    FlutterError.onError = (FlutterErrorDetails details) {
      SafeLog.error('Flutter error: ${details.exception}', details.exception,
          details.stack);

      if (FeatureFlags.crashlyticsEnabled) {
        _crashlytics.recordFlutterFatalError(details);
      }
    };

    // Обработка ошибок платформы
    PlatformDispatcher.instance.onError = (error, stack) {
      SafeLog.critical('Platform error: $error', error, stack);

      if (FeatureFlags.crashlyticsEnabled) {
        _crashlytics.recordError(error, stack, fatal: true);
      }

      return true;
    };
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
      SafeLog.error('Recorded error: $error', error, stackTrace);

      if (FeatureFlags.crashlyticsEnabled) {
        // Добавление пользовательских ключей
        if (customKeys != null) {
          for (final entry in customKeys.entries) {
            await _crashlytics.setCustomKey(entry.key, entry.value);
          }
        }

        await _crashlytics.recordError(
          error,
          stackTrace,
          reason: reason,
          fatal: fatal,
        );
      }
    } catch (e) {
      SafeLog.error('Failed to record error', e);
    }
  }

  /// Запись нефатальной ошибки
  Future<void> recordNonFatalError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? customKeys,
  }) async {
    await recordError(error, stackTrace,
        reason: reason, fatal: false, customKeys: customKeys);
  }

  /// Запись пользовательского действия
  Future<void> logUserAction(String action,
      {Map<String, dynamic>? parameters}) async {
    try {
      SafeLog.info('User action: $action', parameters);

      if (FeatureFlags.crashlyticsEnabled) {
        await _crashlytics.log('User action: $action');

        if (parameters != null) {
          for (final entry in parameters.entries) {
            await _crashlytics.setCustomKey('action_${entry.key}', entry.value);
          }
        }
      }
    } catch (e) {
      SafeLog.error('Failed to log user action', e);
    }
  }

  /// Начало трассировки производительности
  Future<void> startTrace(String traceName) async {
    if (!FeatureFlags.performanceMonitoringEnabled) return;

    try {
      final trace = _performance.newTrace(traceName);
      await trace.start();
      _activeTraces[traceName] = trace;

      SafeLog.info('Started trace: $traceName');
    } catch (e) {
      SafeLog.error('Failed to start trace: $traceName', e);
    }
  }

  /// Завершение трассировки производительности
  Future<void> stopTrace(String traceName) async {
    if (!FeatureFlags.performanceMonitoringEnabled) return;

    try {
      final trace = _activeTraces.remove(traceName);
      if (trace != null) {
        await trace.stop();
        SafeLog.info('Stopped trace: $traceName');
      }
    } catch (e) {
      SafeLog.error('Failed to stop trace: $traceName', e);
    }
  }

  /// Измерение времени выполнения
  Future<T> measureExecutionTime<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (!FeatureFlags.performanceMonitoringEnabled) {
      return await operation();
    }

    final stopwatch = Stopwatch()..start();

    try {
      await startTrace(operationName);
      final result = await operation();
      return result;
    } finally {
      stopwatch.stop();
      await stopTrace(operationName);

      SafeLog.info(
          'Operation $operationName took ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  /// Мониторинг использования памяти
  Future<Map<String, dynamic>> getMemoryUsage() async {
    try {
      final info = ProcessInfo.currentRss;
      return {
        'rss': info,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      SafeLog.error('Failed to get memory usage', e);
      return {};
    }
  }

  /// Мониторинг состояния сети
  Future<Map<String, dynamic>> getNetworkStatus() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      return {
        'isConnected': isConnected,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'isConnected': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Получение метрик приложения
  Future<Map<String, dynamic>> getAppMetrics() async {
    try {
      final memoryUsage = await getMemoryUsage();
      final networkStatus = await getNetworkStatus();

      return {
        'memory': memoryUsage,
        'network': networkStatus,
        'activeTraces': _activeTraces.keys.toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      SafeLog.error('Failed to get app metrics', e);
      return {};
    }
  }

  /// Установка пользовательского идентификатора
  Future<void> setUserId(String userId) async {
    try {
      if (FeatureFlags.crashlyticsEnabled) {
        await _crashlytics.setUserIdentifier(userId);
      }

      SafeLog.info('User ID set: $userId');
    } catch (e) {
      SafeLog.error('Failed to set user ID', e);
    }
  }

  /// Установка пользовательских атрибутов
  Future<void> setUserAttributes(Map<String, String> attributes) async {
    try {
      if (FeatureFlags.crashlyticsEnabled) {
        for (final entry in attributes.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value);
        }
      }

      SafeLog.info('User attributes set: $attributes');
    } catch (e) {
      SafeLog.error('Failed to set user attributes', e);
    }
  }

  /// Очистка данных мониторинга
  Future<void> clearData() async {
    try {
      if (FeatureFlags.crashlyticsEnabled) {
        await _crashlytics.deleteUnsentReports();
      }

      _activeTraces.clear();
      _timers.clear();

      SafeLog.info('Monitoring data cleared');
    } catch (e) {
      SafeLog.error('Failed to clear monitoring data', e);
    }
  }

  /// Проверка доступности мониторинга
  bool get isAvailable =>
      _isInitialized &&
      (FeatureFlags.crashlyticsEnabled ||
          FeatureFlags.performanceMonitoringEnabled);

  /// Получение статуса инициализации
  bool get isInitialized => _isInitialized;
}
