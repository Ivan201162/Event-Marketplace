import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Цветовая схема бренда Event Marketplace
class BrandColors {
  // Основные цвета бренда
  static const Color primary = Color(0xFF6366F1); // Индиго
  static const Color primaryVariant = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF10B981); // Изумрудный
  static const Color secondaryVariant = Color(0xFF059669);

  // Акцентные цвета
  static const Color accent = Color(0xFFF59E0B); // Янтарный
  static const Color accentVariant = Color(0xFFD97706);

  // Нейтральные цвета
  static const Color surface = Color(0xFFFAFAFA);
  static const Color background = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF3B82F6);

  // Градиенты
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Тема приложения
class AppTheme {
  static ThemeData get lightTheme => FlexThemeData.light(
        scheme: FlexScheme.material,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        appBarStyle: FlexAppBarStyle.primary,
        appBarOpacity: 0.95,
        appBarElevation: 0,
        tabBarStyle: FlexTabBarStyle.forAppBar,
        tooltipsMatchBackground: true,
        lightIsWhite: true,
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        fontFamily: 'Roboto',
        primary: BrandColors.primary,
        primaryContainer: BrandColors.primaryVariant,
        secondary: BrandColors.secondary,
        secondaryContainer: BrandColors.secondaryVariant,
        tertiary: BrandColors.accent,
        tertiaryContainer: BrandColors.accentVariant,
        error: BrandColors.error,
      ).copyWith(
        // Кастомные настройки
        colorScheme: const ColorScheme.light(
          primary: BrandColors.primary,
          primaryContainer: BrandColors.primaryVariant,
          secondary: BrandColors.secondary,
          secondaryContainer: BrandColors.secondaryVariant,
          tertiary: BrandColors.accent,
          tertiaryContainer: BrandColors.accentVariant,
          surface: BrandColors.surface,
          error: BrandColors.error,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onSurface: Color(0xFF1F2937),
        ),
        // Кастомные стили текста
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
          headlineLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          titleLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2937),
          ),
          titleSmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFF1F2937),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xFF1F2937),
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: Color(0xFF6B7280),
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2937),
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9CA3AF),
          ),
        ),
        // Кастомные стили карточек
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          color: Colors.white,
          shadowColor: Colors.black12,
        ),
        // Кастомные стили кнопок
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Кастомные стили полей ввода
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: BrandColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: BrandColors.error),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      );

  static ThemeData get darkTheme => FlexThemeData.dark(
        scheme: FlexScheme.material,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 15,
        appBarStyle: FlexAppBarStyle.primary,
        appBarOpacity: 0.90,
        appBarElevation: 0,
        tabBarStyle: FlexTabBarStyle.forAppBar,
        tooltipsMatchBackground: true,
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        fontFamily: 'Roboto',
        primary: BrandColors.primary,
        primaryContainer: BrandColors.primaryVariant,
        secondary: BrandColors.secondary,
        secondaryContainer: BrandColors.secondaryVariant,
        tertiary: BrandColors.accent,
        tertiaryContainer: BrandColors.accentVariant,
        error: BrandColors.error,
      ).copyWith(
        // Кастомные настройки для темной темы
        colorScheme: const ColorScheme.dark(
          primary: BrandColors.primary,
          primaryContainer: BrandColors.primaryVariant,
          secondary: BrandColors.secondary,
          secondaryContainer: BrandColors.secondaryVariant,
          tertiary: BrandColors.accent,
          tertiaryContainer: BrandColors.accentVariant,
          surface: Color(0xFF1F2937),
          error: BrandColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onError: Colors.white,
        ),
        // Кастомные стили карточек для темной темы
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          color: Color(0xFF1F2937),
          shadowColor: Colors.black26,
        ),
      );
}

/// Расширения для удобства работы с темой
extension ThemeExtensions on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // Брендовые цвета
  Color get primaryColor => BrandColors.primary;
  Color get secondaryColor => BrandColors.secondary;
  Color get accentColor => BrandColors.accent;

  // Градиенты
  LinearGradient get primaryGradient => BrandColors.primaryGradient;
  LinearGradient get secondaryGradient => BrandColors.secondaryGradient;
  LinearGradient get accentGradient => BrandColors.accentGradient;
}
