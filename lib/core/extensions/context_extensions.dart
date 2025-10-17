import 'package:flutter/material.dart';

/// Расширения для BuildContext для работы с размерами экрана и темой
extension ContextExtensions on BuildContext {
  /// Проверка, является ли устройство мобильным
  bool get isMobile => MediaQuery.of(this).size.width < 768;

  /// Проверка, является ли устройство планшетом
  bool get isTablet =>
      MediaQuery.of(this).size.width >= 768 && MediaQuery.of(this).size.width < 1024;

  /// Проверка, является ли устройство десктопом
  bool get isDesktop => MediaQuery.of(this).size.width >= 1024;

  /// Получение текстовой темы
  TextTheme get text => Theme.of(this).textTheme;

  /// Получение цветовой схемы
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Адаптивный выбор значения в зависимости от размера экрана
  T responsive<T>(T mobile, [T? tablet, T? desktop]) {
    if (isDesktop && desktop != null) {
      return desktop;
    } else if (isTablet && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }

  /// Получение ширины экрана
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Получение высоты экрана
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Проверка темной темы
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Получение отступов безопасной зоны
  EdgeInsets get safeArea => MediaQuery.of(this).padding;

  /// Получение размера экрана
  Size get screenSize => MediaQuery.of(this).size;

  /// Проверка ориентации
  bool get isPortrait => MediaQuery.of(this).orientation == Orientation.portrait;
  bool get isLandscape => MediaQuery.of(this).orientation == Orientation.landscape;
}
