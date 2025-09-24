import 'dart:developer' as developer;

/// Логгер для приложения
class AppLogger {
  static void logD(String message, [String? tag]) {
    developer.log(
      message,
      name: tag ?? 'AppLogger',
      level: 500, // DEBUG
    );
  }

  static void logI(String message, [String? tag]) {
    developer.log(
      message,
      name: tag ?? 'AppLogger',
      level: 800, // INFO
    );
  }

  static void logW(String message, [String? tag]) {
    developer.log(
      message,
      name: tag ?? 'AppLogger',
      level: 900, // WARNING
    );
  }

  static void logE(String message, [String? tag]) {
    developer.log(
      message,
      name: tag ?? 'AppLogger',
      level: 1000, // ERROR
    );
  }
}