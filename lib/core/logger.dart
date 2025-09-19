import 'package:flutter/foundation.dart';

/// Централизованный логгер для приложения
class AppLogger {
  static const bool _isDebugMode = kDebugMode;
  
  /// Логирование отладочной информации
  static void logD(String message, [String? tag]) {
    if (_isDebugMode) {
      final tagStr = tag != null ? '[$tag] ' : '';
      debugPrint('DEBUG: $tagStr$message');
    }
  }
  
  /// Логирование информации
  static void logI(String message, [String? tag]) {
    if (_isDebugMode) {
      final tagStr = tag != null ? '[$tag] ' : '';
      debugPrint('INFO: $tagStr$message');
    }
  }
  
  /// Логирование предупреждений
  static void logW(String message, [String? tag]) {
    if (_isDebugMode) {
      final tagStr = tag != null ? '[$tag] ' : '';
      debugPrint('WARNING: $tagStr$message');
    }
  }
  
  /// Логирование ошибок
  static void logE(String message, [String? tag, Object? error, StackTrace? stackTrace]) {
    if (_isDebugMode) {
      final tagStr = tag != null ? '[$tag] ' : '';
      debugPrint('ERROR: $tagStr$message');
      if (error != null) {
        debugPrint('Error details: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }
  
  /// Логирование только в debug режиме
  static void logDebug(String message, [String? tag]) {
    if (_isDebugMode) {
      final tagStr = tag != null ? '[$tag] ' : '';
      debugPrint('DEBUG: $tagStr$message');
    }
  }
}
