import 'package:flutter/material.dart';

/// Универсальные расширения для BuildContext
extension ContextExtensions on BuildContext {
  /// Получить тему приложения
  ThemeData get theme => Theme.of(this);

  /// Получить цветовую схему
  ColorScheme get colorScheme => theme.colorScheme;

  /// Получить текстовую тему
  TextTheme get textTheme => theme.textTheme;

  /// Получить медиа-запросы
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Получить размер экрана
  Size get screenSize => mediaQuery.size;

  /// Получить ширину экрана
  double get screenWidth => screenSize.width;

  /// Получить высоту экрана
  double get screenHeight => screenSize.height;

  /// Проверить, является ли экран мобильным
  bool get isMobile => screenWidth < 600;

  /// Проверить, является ли экран планшетом
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;

  /// Проверить, является ли экран десктопом
  bool get isDesktop => screenWidth >= 1200;

  /// Получить безопасную область
  EdgeInsets get safeArea => mediaQuery.padding;

  /// Получить статус-бар
  double get statusBarHeight => safeArea.top;

  /// Получить нижнюю панель
  double get bottomBarHeight => safeArea.bottom;

  /// Показать снэкбар
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? colorScheme.error,
      ),
    );
  }

  /// Показать диалог
  Future<T?> showDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: this,
      barrierDismissible: barrierDismissible,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Получить локализацию
  Locale get locale => Localizations.localeOf(this);

  /// Проверить, является ли текущая тема темной
  bool get isDarkMode => theme.brightness == Brightness.dark;
}
