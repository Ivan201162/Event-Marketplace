import 'package:flutter/material.dart';

/// Современная цветовая палитра для Event Marketplace
class AppColors {
  // Светлая тема
  static const Color lightBackground = Color(0xFFFAFAFA); // off-white
  static const Color lightSurface = Color(0xFFFFFFFF); // чистый белый
  static const Color lightCard = Color(0xFFF5F5F5); // светло-серый
  static const Color lightSecondary = Color(0xFFE8E8E8); // кремовый
  static const Color lightText = Color(0xFF1A1A1A); // тёмный текст
  static const Color lightSecondaryText = Color(0xFF666666); // серый текст
  static const Color lightBorder = Color(0xFFE0E0E0); // границы

  // Тёмная тема
  static const Color darkBackground = Color(0xFF0A0A0A); // глубокий чёрный
  static const Color darkSurface = Color(0xFF1A1A1A); // графит
  static const Color darkCard = Color(0xFF2A2A2A); // тёмно-серый
  static const Color darkSecondary = Color(0xFF3A3A3A); // вторичный графит
  static const Color darkText = Color(0xFFFFFFFF); // белый текст
  static const Color darkSecondaryText = Color(0xFFB0B0B0); // светло-серый текст
  static const Color darkBorder = Color(0xFF404040); // тёмные границы

  // Акцентные цвета (премиальные)
  static const Color primaryAccent = Color(0xFF2E5BFF); // благородный синий
  static const Color secondaryAccent = Color(0xFF8B5CF6); // фиолетовый
  static const Color successAccent = Color(0xFF10B981); // зелёный
  static const Color warningAccent = Color(0xFFF59E0B); // золотистый
  static const Color errorAccent = Color(0xFFEF4444); // красный
  static const Color infoAccent = Color(0xFF06B6D4); // голубой

  // Градиенты
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryAccent, secondaryAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [successAccent, Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warningAccent, Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Тема приложения с поддержкой светлой и тёмной тем
class AppTheme {
  /// Светлая тема
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.lightBackground,

    // Цветовая схема
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryAccent,
      secondary: AppColors.secondaryAccent,
      error: AppColors.errorAccent,
      onSecondary: Colors.white,
      onSurface: AppColors.lightText,
      outline: AppColors.lightBorder,
    ),

    // AppBar тема
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightSurface,
      foregroundColor: AppColors.lightText,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
      ),
      iconTheme: IconThemeData(color: AppColors.lightText),
    ),

    // Текстовая тема
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.lightText,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.lightText,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.lightText,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
      ),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.lightText),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.lightText),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.lightSecondaryText,
      ),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.lightText),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.lightText,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.lightSecondaryText,
      ),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.lightText),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.lightSecondaryText,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.lightSecondaryText,
      ),
    ),

    // Карточки
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Кнопки
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: AppColors.primaryAccent.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryAccent,
        side: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),

    // Поля ввода
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSecondary,
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
        borderSide: const BorderSide(color: AppColors.primaryAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: const TextStyle(color: AppColors.lightSecondaryText, fontSize: 14),
      labelStyle: const TextStyle(color: AppColors.lightSecondaryText, fontSize: 14),
    ),

    // Bottom Navigation Bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedItemColor: AppColors.primaryAccent,
      unselectedItemColor: AppColors.lightSecondaryText,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryAccent,
      foregroundColor: Colors.white,
      elevation: 6,
    ),

    // Диалоги
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.lightSurface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.lightText,
      ),
      contentTextStyle: const TextStyle(fontSize: 14, color: AppColors.lightText),
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurface,
      contentTextStyle: const TextStyle(color: AppColors.darkText),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),

    // Divider
    dividerTheme: const DividerThemeData(color: AppColors.lightBorder, thickness: 1, space: 1),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightSecondary,
      selectedColor: AppColors.primaryAccent,
      disabledColor: AppColors.lightSecondary.withValues(alpha: 0.5),
      labelStyle: const TextStyle(color: AppColors.lightText),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  /// Тёмная тема
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.darkBackground,

    // Цветовая схема
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryAccent,
      secondary: AppColors.secondaryAccent,
      surface: AppColors.darkSurface,
      error: AppColors.errorAccent,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
      outline: AppColors.darkBorder,
    ),

    // AppBar тема
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
      iconTheme: IconThemeData(color: AppColors.darkText),
    ),

    // Текстовая тема
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkText),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.darkText,
      ),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkText),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkText),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkText),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.darkSecondaryText,
      ),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.darkText),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.darkText),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.darkSecondaryText,
      ),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkText),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.darkSecondaryText,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.darkSecondaryText,
      ),
    ),

    // Карточки
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Кнопки
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: AppColors.primaryAccent.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryAccent,
        side: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),

    // Поля ввода
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSecondary,
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
        borderSide: const BorderSide(color: AppColors.primaryAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: const TextStyle(color: AppColors.darkSecondaryText, fontSize: 14),
      labelStyle: const TextStyle(color: AppColors.darkSecondaryText, fontSize: 14),
    ),

    // Bottom Navigation Bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.primaryAccent,
      unselectedItemColor: AppColors.darkSecondaryText,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryAccent,
      foregroundColor: Colors.white,
      elevation: 6,
    ),

    // Диалоги
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkSurface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.darkText,
      ),
      contentTextStyle: const TextStyle(fontSize: 14, color: AppColors.darkText),
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkCard,
      contentTextStyle: const TextStyle(color: AppColors.darkText),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),

    // Divider
    dividerTheme: const DividerThemeData(color: AppColors.darkBorder, thickness: 1, space: 1),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkSecondary,
      selectedColor: AppColors.primaryAccent,
      disabledColor: AppColors.darkSecondary.withValues(alpha: 0.5),
      labelStyle: const TextStyle(color: AppColors.darkText),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

/// Брендовые цвета для совместимости с существующим кодом
class BrandColors {
  static const Color primary = Color(0xFF2E5BFF);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFF10B981); // success color as accent
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF06B6D4);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color border = Color(0xFFE0E0E0);
}
