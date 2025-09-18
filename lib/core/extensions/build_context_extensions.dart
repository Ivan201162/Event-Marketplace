import 'package:flutter/material.dart';

/// Расширения для BuildContext
extension BuildContextExtensions on BuildContext {
  /// Получить цветовую схему
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Получить текстовую тему
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Получить тему
  ThemeData get theme => Theme.of(this);

  /// Получить размеры экрана
  Size get screenSize => MediaQuery.of(this).size;

  /// Получить ширину экрана
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Получить высоту экрана
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Проверить, является ли экран мобильным
  bool get isMobile => screenWidth < 600;

  /// Проверить, является ли экран планшетом
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;

  /// Проверить, является ли экран десктопом
  bool get isDesktop => screenWidth >= 1200;
}
