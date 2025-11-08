import 'package:flutter/material.dart';
import 'app_colors.dart';

OutlineInputBorder _outline(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: 1),
    );

ThemeData appLightTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.ivory,
    primaryColor: AppColors.gold,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.gold,
      secondary: AppColors.goldSoft,
      surface: AppColors.cardLight,
      onSurface: AppColors.textDark,
    ),
    cardColor: AppColors.cardLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: Colors.black54,
      showUnselectedLabels: false,
      showSelectedLabels: false,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: _outline(Colors.black12),
      focusedBorder: _outline(AppColors.gold),
      border: _outline(Colors.black26),
    ),
  );
}

ThemeData appDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.nearBlack,
    primaryColor: AppColors.gold,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.gold,
      secondary: AppColors.goldSoft,
      surface: AppColors.graphite,
      onSurface: AppColors.textLight,
    ),
    cardColor: AppColors.cardDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textLight,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.coal,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: Colors.white.withOpacity(.6),
      showUnselectedLabels: false,
      showSelectedLabels: false,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.graphite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: _outline(Colors.white24),
      focusedBorder: _outline(AppColors.gold),
      border: _outline(Colors.white30),
    ),
  );
}
