import 'package:flutter/foundation.dart';

/// Утилиты для работы с платформами
class PlatformUtils {
  /// Проверка, является ли платформа Web
  static bool get isWeb => kIsWeb;

  /// Проверка, является ли платформа мобильной
  static bool get isMobile => !kIsWeb;

  /// Условное выполнение кода только для Web
  static T webOnly<T>(T Function() webCode, T Function() fallback) {
    if (isWeb) {
      return webCode();
    }
    return fallback();
  }

  /// Условное выполнение кода только для мобильных платформ
  static T mobileOnly<T>(T Function() mobileCode, T Function() fallback) {
    if (isMobile) {
      return mobileCode();
    }
    return fallback();
  }
}
