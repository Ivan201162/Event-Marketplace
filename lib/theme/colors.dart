import 'package:flutter/material.dart';

/// Цветовые токены приложения V7.5 - Premium Adaptive System
class AppColors {
  // Light Theme - Premium
  static const Color lightPrimary = Color(0xFF0066FF);
  static const Color lightBackground = Color(0xFFF8F9FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightAccent = Color(0xFFEE8D2D);
  static const Color lightGradientStart = Color(0xFF00B4DB);
  static const Color lightGradientEnd = Color(0xFF0083B0);
  static const Color lightOnBackground = Color(0xFF111111);
  
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6C757D);
  static const Color lightTextMuted = Color(0xFFADB5BD);
  
  static const Color lightOutline = Color(0xFFE9ECEF);
  static const Color lightDivider = Color(0xFFE9ECEF);
  
  static const Color lightSuccess = Color(0xFF28A745);
  static const Color lightWarning = Color(0xFFFFC107);
  static const Color lightError = Color(0xFFDC3545);
  
  // Dark Theme - Premium
  static const Color darkPrimary = Color(0xFF5A8FFF);
  static const Color darkBackground = Color(0xFF0D1017);
  static const Color darkSurface = Color(0xFF161C27);
  static const Color darkAccent = Color(0xFFF1A93B);
  static const Color darkGradientStart = Color(0xFF1E2A78);
  static const Color darkGradientEnd = Color(0xFF0B132B);
  static const Color darkOnBackground = Color(0xFFDADADA);
  
  static const Color darkTextPrimary = Color(0xFFF0F6FC);
  static const Color darkTextSecondary = Color(0xFFC9D1D9);
  static const Color darkTextMuted = Color(0xFF8B949E);
  
  static const Color darkOutline = Color(0xFF30363D);
  static const Color darkDivider = Color(0xFF30363D);
  
  static const Color darkSuccess = Color(0xFF3FB950);
  static const Color darkWarning = Color(0xFFD29922);
  static const Color darkError = Color(0xFFF85149);
  
  // Helper method для получения цветов в зависимости от темы
  static AppColorScheme of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? AppColorScheme.dark() : AppColorScheme.light();
  }
  
  // Gradient colors helper
  static List<Color> gradientColors(BuildContext context) {
    final scheme = of(context);
    return [scheme.gradientStart, scheme.gradientEnd];
  }
  
  // Shadows (soft)
  static List<BoxShadow> get lightShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
  
  static List<BoxShadow> get darkShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}

/// Color Scheme для адаптивных тем
class AppColorScheme {
  final Color primary;
  final Color background;
  final Color surface;
  final Color accent;
  final Color gradientStart;
  final Color gradientEnd;
  final Color onBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color outline;
  
  AppColorScheme({
    required this.primary,
    required this.background,
    required this.surface,
    required this.accent,
    required this.gradientStart,
    required this.gradientEnd,
    required this.onBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.outline,
  });
  
  factory AppColorScheme.light() {
    return AppColorScheme(
      primary: AppColors.lightPrimary,
      background: AppColors.lightBackground,
      surface: AppColors.lightSurface,
      accent: AppColors.lightAccent,
      gradientStart: AppColors.lightGradientStart,
      gradientEnd: AppColors.lightGradientEnd,
      onBackground: AppColors.lightOnBackground,
      textPrimary: AppColors.lightTextPrimary,
      textSecondary: AppColors.lightTextSecondary,
      outline: AppColors.lightOutline,
    );
  }
  
  factory AppColorScheme.dark() {
    return AppColorScheme(
      primary: AppColors.darkPrimary,
      background: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      accent: AppColors.darkAccent,
      gradientStart: AppColors.darkGradientStart,
      gradientEnd: AppColors.darkGradientEnd,
      onBackground: AppColors.darkOnBackground,
      textPrimary: AppColors.darkTextPrimary,
      textSecondary: AppColors.darkTextSecondary,
      outline: AppColors.darkOutline,
    );
  }
}

