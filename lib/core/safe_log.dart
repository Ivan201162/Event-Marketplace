import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'feature_flags.dart';

/// Безопасный логгер с контролем через фичефлаги
class SafeLog {
  static const String _tag = 'EventMarketplace';

  /// Логирование отладочной информации
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (FeatureFlags.debugMode && FeatureFlags.verboseLogging) {
      if (kDebugMode) {
        developer.log(
          message,
          name: _tag,
          level: 800, // DEBUG level
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Логирование информации
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    if (FeatureFlags.debugMode) {
      if (kDebugMode) {
        developer.log(
          message,
          name: _tag,
          level: 700, // INFO level
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Логирование предупреждений
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      developer.log(
        message,
        name: _tag,
        level: 900, // WARNING level
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Логирование ошибок
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      developer.log(
        message,
        name: _tag,
        level: 1000, // ERROR level
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Логирование критических ошибок
  static void critical(String message,
      [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      developer.log(
        message,
        name: _tag,
        level: 1200, // CRITICAL level
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Логирование с контекстом
  static void logWithContext(
    String message, {
    String? context,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final contextMessage = context != null ? '[$context] $message' : message;
    final dataString = data != null ? ' | Data: $data' : '';
    final fullMessage = '$contextMessage$dataString';

    if (FeatureFlags.debugMode) {
      if (kDebugMode) {
        developer.log(
          fullMessage,
          name: _tag,
          level: 700,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Логирование производительности
  static void performance(String operation, Duration duration) {
    if (FeatureFlags.debugMode && FeatureFlags.verboseLogging) {
      if (kDebugMode) {
        developer.log(
          'Performance: $operation took ${duration.inMilliseconds}ms',
          name: '$_tag.Performance',
          level: 800,
        );
      }
    }
  }

  /// Логирование сетевых запросов
  static void network(String method, String url,
      {int? statusCode, Duration? duration}) {
    if (FeatureFlags.debugMode && FeatureFlags.verboseLogging) {
      final status = statusCode != null ? ' ($statusCode)' : '';
      final time = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
      final message = '$method $url$status$time';

      if (kDebugMode) {
        developer.log(
          message,
          name: '$_tag.Network',
          level: 800,
        );
      }
    }
  }

  /// Логирование пользовательских действий
  static void userAction(String action, {Map<String, dynamic>? data}) {
    if (FeatureFlags.analyticsEnabled) {
      final dataString = data != null ? ' | Data: $data' : '';
      final message = 'User Action: $action$dataString';

      if (kDebugMode) {
        developer.log(
          message,
          name: '$_tag.UserAction',
          level: 700,
        );
      }
    }
  }
}
