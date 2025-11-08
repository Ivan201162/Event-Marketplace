import 'package:flutter/material.dart';

/// Цветовые токены приложения
class AppColors {
  // Light Theme
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8F9FA);
  static const Color lightSurfaceVariant = Color(0xFFF1F3F5);
  
  static const Color lightPrimary = Color(0xFF0066FF);
  static const Color lightSecondary = Color(0xFF6C757D);
  
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6C757D);
  static const Color lightTextMuted = Color(0xFFADB5BD);
  
  static const Color lightOutline = Color(0xFFE9ECEF);
  static const Color lightDivider = Color(0xFFE9ECEF);
  
  static const Color lightSuccess = Color(0xFF28A745);
  static const Color lightWarning = Color(0xFFFFC107);
  static const Color lightError = Color(0xFFDC3545);
  
  // Dark Theme
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkSurfaceVariant = Color(0xFF21262D);
  
  static const Color darkPrimary = Color(0xFF58A6FF);
  static const Color darkSecondary = Color(0xFF8B949E);
  
  static const Color darkTextPrimary = Color(0xFFF0F6FC);
  static const Color darkTextSecondary = Color(0xFFC9D1D9);
  static const Color darkTextMuted = Color(0xFF8B949E);
  
  static const Color darkOutline = Color(0xFF30363D);
  static const Color darkDivider = Color(0xFF30363D);
  
  static const Color darkSuccess = Color(0xFF3FB950);
  static const Color darkWarning = Color(0xFFD29922);
  static const Color darkError = Color(0xFFF85149);
  
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

