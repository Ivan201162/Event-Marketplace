import 'package:flutter/material.dart';

/// Типографика приложения на основе Inter
class AppTypography {
  // Display
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

  // Headline
  static const TextStyle headline = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 28,
    height: 1.3,
    letterSpacing: -0.2,
  );

  // Title
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

  // Body
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

  // Caption
  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 11,
    height: 1.45,
    letterSpacing: 0.2,
  );

  /// Применить типографику к ThemeData
  static TextTheme get textTheme => const TextTheme(
        displayLarge: displayLg,
        displayMedium: displayMd,
        headlineLarge: headline,
        titleLarge: titleLg,
        titleMedium: titleMd,
        bodyLarge: bodyLg,
        bodyMedium: bodyMd,
        bodySmall: bodySm,
        labelSmall: caption,
      );
}

