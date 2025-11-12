import 'package:flutter/material.dart';
import 'package:event_marketplace_app/theme/colors.dart';

/// Typography System 2.0 - V7.5
/// Основной: Inter Display, Вторичный: Roboto Flex
class AppTypography {
  // Display - Inter Display
  static TextStyle displayLarge(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 34,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.of(context).textPrimary,
  );

  static TextStyle displayMedium(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 28,
    height: 1.25,
    letterSpacing: -0.3,
    color: AppColors.of(context).textPrimary,
  );

  // Headline
  static TextStyle headlineStyle(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 1.3,
    letterSpacing: -0.2,
    color: AppColors.of(context).textPrimary,
  );

  // Title
  static TextStyle titleLarge(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 22,
    height: 1.35,
    letterSpacing: 0,
    color: AppColors.of(context).textPrimary,
  );

  static TextStyle titleMedium(BuildContext context) => TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 1.4,
    letterSpacing: 0,
    color: AppColors.of(context).textPrimary,
  );

  // Body - адаптация к теме
  static TextStyle bodyLarge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w400,
      fontSize: 16,
      height: 1.4,
      letterSpacing: isDark ? 0.2 : 0,
      color: AppColors.of(context).textPrimary,
    );
  }

  static TextStyle bodyMedium(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w400,
      fontSize: 14,
      height: 1.4,
      letterSpacing: isDark ? 0.2 : 0,
      color: AppColors.of(context).textPrimary,
    );
  }

  static TextStyle bodySmall(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w400,
      fontSize: 12,
      height: 1.5,
      letterSpacing: isDark ? 0.2 : 0.1,
      color: AppColors.of(context).textSecondary,
    );
  }

  // Label - с accent цветом
  static TextStyle labelSmall(BuildContext context) => TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 1.45,
    letterSpacing: 0.2,
    color: AppColors.of(context).accent,
  );

  // Legacy static styles для обратной совместимости
  static const TextStyle displayLg = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 48,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMd = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 36,
    height: 1.25,
    letterSpacing: -0.3,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 28,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const TextStyle titleLg = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 22,
    height: 1.35,
    letterSpacing: 0,
  );

  static const TextStyle titleMd = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.5,
    letterSpacing: 0.1,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 11,
    height: 1.45,
    letterSpacing: 0.2,
  );

  /// Применить типографику к ThemeData
  static TextTheme textTheme(BuildContext context) => TextTheme(
        displayLarge: displayLarge(context),
        displayMedium: displayMedium(context),
        headlineLarge: headlineStyle(context),
        titleLarge: titleLarge(context),
        titleMedium: titleMedium(context),
        bodyLarge: bodyLarge(context),
        bodyMedium: bodyMedium(context),
        bodySmall: bodySmall(context),
        labelSmall: labelSmall(context),
      );
}

