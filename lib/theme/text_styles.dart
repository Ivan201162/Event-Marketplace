import 'package:flutter/material.dart';
import 'app_colors.dart';

class T {
  // Заголовки (Cormorant)
  static const h1 = TextStyle(
    fontFamily: 'CormorantGaramond',
    fontWeight: FontWeight.w600,
    fontSize: 42,
    height: 1.05,
    letterSpacing: 0.2,
  );

  static const h2 = TextStyle(
    fontFamily: 'CormorantGaramond',
    fontWeight: FontWeight.w600,
    fontSize: 32,
    height: 1.08,
  );

  static const h3 = TextStyle(
    fontFamily: 'CormorantGaramond',
    fontWeight: FontWeight.w500,
    fontSize: 24,
    height: 1.1,
  );

  // Основной текст (Inter)
  static const body = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.35,
  );

  static const bodyM = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 16,
    height: 1.35,
  );

  static const caption = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 13,
    height: 1.3,
    color: AppColors.textMuted,
  );
}

