import 'package:flutter/material.dart';

/// Премиальная тёмная тема для Event Marketplace
class PremiumTheme {
  // Цветовая палитра
  static const Color primaryGold = Color(0xFFE6B325);
  static const Color darkBackground = Color(0xFF121212);
  static const Color secondaryText = Color(0xFFB0B0B0);
  static const Color whiteText = Color(0xFFFFFFFF);
  static const Color secondaryElements = Color(0xFF2C2C2C);
  static const Color cardBackground = Color(0xFF1C1C1C);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color errorColor = Color(0xFFFF5252);
  static const Color successColor = Color(0xFF4CAF50);

  /// Основная тёмная тема
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,

        // Основные цвета
        scaffoldBackgroundColor: darkBackground,
        primaryColor: primaryGold,
        cardColor: cardBackground,

        // Цветовая схема
        colorScheme: const ColorScheme.dark(
          primary: primaryGold,
          secondary: secondaryText,
          surface: surfaceColor,
          error: errorColor,
          onPrimary: darkBackground,
          onSecondary: whiteText,
          onError: whiteText,
        ),

        // AppBar тема
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: whiteText,),
          iconTheme: IconThemeData(color: whiteText),
        ),

        // Текстовая тема
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold, color: whiteText,),
          displayMedium: TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, color: whiteText,),
          displaySmall: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: whiteText,),
          headlineLarge: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w600, color: whiteText,),
          headlineMedium: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w600, color: whiteText,),
          headlineSmall: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600, color: whiteText,),
          titleLarge: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: whiteText,),
          titleMedium: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, color: whiteText,),
          titleSmall: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: secondaryText,),
          bodyLarge: TextStyle(
              fontSize: 16, fontWeight: FontWeight.normal, color: whiteText,),
          bodyMedium: TextStyle(
              fontSize: 14, fontWeight: FontWeight.normal, color: whiteText,),
          bodySmall: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: secondaryText,),
          labelLarge: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, color: whiteText,),
          labelMedium: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: secondaryText,),
          labelSmall: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w500, color: secondaryText,),
        ),

        // Карточки
        cardTheme: CardThemeData(
          color: cardBackground,
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),

        // Кнопки
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGold,
            foregroundColor: darkBackground,
            elevation: 2,
            shadowColor: primaryGold.withValues(alpha: 0.3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryGold,
            side: const BorderSide(color: primaryGold, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryGold,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),

        // Поля ввода
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: secondaryElements,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGold, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: errorColor, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: const TextStyle(color: secondaryText, fontSize: 14),
          labelStyle: const TextStyle(color: secondaryText, fontSize: 14),
        ),

        // Bottom Navigation Bar
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: cardBackground,
          selectedItemColor: primaryGold,
          unselectedItemColor: secondaryText,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),

        // Floating Action Button
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryGold,
          foregroundColor: darkBackground,
          elevation: 6,
        ),

        // Диалоги
        dialogTheme: DialogThemeData(
          backgroundColor: cardBackground,
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titleTextStyle: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: whiteText,),
          contentTextStyle: const TextStyle(fontSize: 14, color: whiteText),
        ),

        // Snackbar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: cardBackground,
          contentTextStyle: const TextStyle(color: whiteText),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          behavior: SnackBarBehavior.floating,
        ),

        // Divider
        dividerTheme: const DividerThemeData(
            color: secondaryElements, thickness: 1, space: 1,),

        // Chip
        chipTheme: ChipThemeData(
          backgroundColor: secondaryElements,
          selectedColor: primaryGold,
          disabledColor: secondaryElements.withValues(alpha: 0.5),
          labelStyle: const TextStyle(color: whiteText),
          secondaryLabelStyle: const TextStyle(color: darkBackground),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
}
