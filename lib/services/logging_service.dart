import 'dart:developer' as developer;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Уровни логирования
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

/// Сервис для логирования и мониторинга
class LoggingService {
  static const String _logLevelKey = 'log_level';
  static const String _enableCrashlyticsKey = 'enable_crashlytics';
  static const String _enablePerformanceKey = 'enable_performance';

  static LogLevel _currentLogLevel = LogLevel.info;
  static bool _enableCrashlytics = true;
  static bool _enablePerformance = true;

  /// Инициализация сервиса логирования
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Загружаем настройки
      final logLevelIndex = prefs.getInt(_logLevelKey) ?? LogLevel.info.index;
      _currentLogLevel = LogLevel.values[logLevelIndex];
      _enableCrashlytics = prefs.getBool(_enableCrashlyticsKey) ?? true;
      _enablePerformance = prefs.getBool(_enablePerformanceKey) ?? true;

      // Инициализируем Firebase Crashlytics
      if (_enableCrashlytics) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

        // Устанавливаем обработчик ошибок Flutter
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

        // Устанавливаем обработчик ошибок платформы
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      // Инициализируем Firebase Performance
      if (_enablePerformance) {
        await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
      }

      debugPrint('LoggingService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing LoggingService: $e');
    }
  }

  /// Логирование сообщения
  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    // Проверяем уровень логирования
    if (level.index < _currentLogLevel.index) {
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final logTag = tag ?? 'App';
    final levelName = level.name.toUpperCase();

    // Логируем в консоль
    developer.log(
      message,
      name: logTag,
      level: _getLogLevelValue(level),
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );

    // Логируем в Firebase Crashlytics для ошибок
    if (_enableCrashlytics && (level == LogLevel.error || level == LogLevel.fatal)) {
      FirebaseCrashlytics.instance.log('[$levelName] $logTag: $message');

      if (error != null) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: level == LogLevel.fatal,
          information: extra?.entries.map((e) => DiagnosticsProperty(e.key, e.value)).toList(),
        );
      }
    }

    // В debug режиме выводим дополнительную информацию
    if (kDebugMode) {
      debugPrint('[$timestamp] [$levelName] $logTag: $message');
      if (extra != null) {
        debugPrint('Extra data: $extra');
      }
    }
  }

  /// Логирование отладочной информации
  static void debug(
    String message, {
    String? tag,
    Map<String, dynamic>? extra,
  }) {
    log(message, level: LogLevel.debug, tag: tag, extra: extra);
  }

  /// Логирование информационных сообщений
  static void info(String message, {String? tag, Map<String, dynamic>? extra}) {
    log(message, tag: tag, extra: extra);
  }

  /// Логирование предупреждений
  static void warning(
    String message, {
    String? tag,
    Map<String, dynamic>? extra,
  }) {
    log(message, level: LogLevel.warning, tag: tag, extra: extra);
  }

  /// Логирование ошибок
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    log(
      message,
      level: LogLevel.error,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      extra: extra,
    );
  }

  /// Логирование критических ошибок
  static void fatal(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    log(
      message,
      level: LogLevel.fatal,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      extra: extra,
    );
  }

  /// Логирование пользовательских действий
  static void userAction(
    String action, {
    String? userId,
    Map<String, dynamic>? parameters,
  }) {
    final extra = <String, dynamic>{
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (userId != null) {
      extra['userId'] = userId;
    }

    if (parameters != null) {
      extra.addAll(parameters);
    }

    info('User action: $action', tag: 'UserAction', extra: extra);
  }

  /// Логирование производительности
  static void performance(
    String operation, {
    Duration? duration,
    Map<String, dynamic>? metrics,
  }) {
    final extra = <String, dynamic>{
      'operation': operation,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (duration != null) {
      extra['duration_ms'] = duration.inMilliseconds;
    }

    if (metrics != null) {
      extra.addAll(metrics);
    }

    info('Performance: $operation', tag: 'Performance', extra: extra);
  }

  /// Логирование сетевых запросов
  static void network(
    String method,
    String url, {
    int? statusCode,
    Duration? duration,
    int? responseSize,
    Map<String, dynamic>? headers,
  }) {
    final extra = <String, dynamic>{
      'method': method,
      'url': url,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (statusCode != null) {
      extra['status_code'] = statusCode;
    }

    if (duration != null) {
      extra['duration_ms'] = duration.inMilliseconds;
    }

    if (responseSize != null) {
      extra['response_size_bytes'] = responseSize;
    }

    if (headers != null) {
      extra['headers'] = headers;
    }

    info('Network: $method $url', tag: 'Network', extra: extra);
  }

  /// Логирование ошибок сети
  static void networkError(
    String method,
    String url, {
    Object? error,
    StackTrace? stackTrace,
    int? statusCode,
  }) {
    final extra = <String, dynamic>{
      'method': method,
      'url': url,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (statusCode != null) {
      extra['status_code'] = statusCode;
    }

    this.error(
      'Network error: $method $url',
      tag: 'Network',
      error: error,
      stackTrace: stackTrace,
      extra: extra,
    );
  }

  /// Установить уровень логирования
  static Future<void> setLogLevel(LogLevel level) async {
    _currentLogLevel = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_logLevelKey, level.index);
  }

  /// Получить текущий уровень логирования
  static LogLevel getLogLevel() => _currentLogLevel;

  /// Включить/выключить Crashlytics
  static Future<void> setCrashlyticsEnabled(bool enabled) async {
    _enableCrashlytics = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableCrashlyticsKey, enabled);

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
  }

  /// Включить/выключить Performance Monitoring
  static Future<void> setPerformanceEnabled(bool enabled) async {
    _enablePerformance = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enablePerformanceKey, enabled);

    await FirebasePerformance.instance.setPerformanceCollectionEnabled(enabled);
  }

  /// Установить пользовательский идентификатор для Crashlytics
  static Future<void> setUserId(String userId) async {
    if (_enableCrashlytics) {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    }
  }

  /// Установить пользовательские данные для Crashlytics
  static Future<void> setCustomKey(String key, value) async {
    if (_enableCrashlytics) {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    }
  }

  /// Записать нефатальную ошибку
  static Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? information,
  }) async {
    if (_enableCrashlytics) {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
        information: information?.entries.map((e) => DiagnosticsProperty(e.key, e.value)).toList(),
      );
    }
  }

  /// Создать трейс для отслеживания производительности
  static Future<Trace> startTrace(String name) async {
    if (_enablePerformance) {
      return FirebasePerformance.instance.newTrace(name);
    }
    return _DummyTrace();
  }

  /// Создать HTTP метрику
  static Future<HttpMetric> startHttpMetric(
    String url,
    HttpMethod method,
  ) async {
    if (_enablePerformance) {
      return FirebasePerformance.instance.newHttpMetric(url, method);
    }
    return _DummyHttpMetric();
  }

  /// Получить числовое значение уровня логирования
  static int _getLogLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.fatal:
        return 1200;
    }
  }

  /// Очистить все логи
  static Future<void> clearLogs() async {
    // В реальном приложении здесь можно очистить локальные логи
    debugPrint('Logs cleared');
  }

  /// Экспортировать логи
  static Future<String> exportLogs() async {
    // В реальном приложении здесь можно экспортировать логи
    return 'Logs exported successfully';
  }
}

/// Заглушка для трейса когда Performance отключен
class _DummyTrace implements Trace {
  @override
  String get name => 'dummy';

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> incrementMetric(String name, int value) async {}

  @override
  Future<void> putMetric(String name, int value) async {}

  @override
  Future<void> putAttribute(String name, String value) async {}

  @override
  Future<void> removeAttribute(String name) async {}

  @override
  Future<Map<String, String>> getAttributes() async => {};

  @override
  Future<int> getMetric(String name) async => 0;
}

/// Заглушка для HTTP метрики когда Performance отключен
class _DummyHttpMetric implements HttpMetric {
  @override
  String get url => 'dummy';

  @override
  HttpMethod get httpMethod => HttpMethod.Get;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setHttpResponseCode(int code) async {}

  @override
  Future<void> setRequestPayloadSize(int bytes) async {}

  @override
  Future<void> setResponsePayloadSize(int bytes) async {}

  @override
  Future<void> setResponseContentType(String contentType) async {}

  @override
  Future<void> putAttribute(String name, String value) async {}

  @override
  Future<void> removeAttribute(String name) async {}

  @override
  Future<Map<String, String>> getAttributes() async => {};
}
