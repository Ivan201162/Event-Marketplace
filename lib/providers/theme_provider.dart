import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Провайдер для управления темой приложения
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  /// Загрузить сохраненную тему
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    state = ThemeMode.values[themeIndex];
  }

  /// Сохранить выбранную тему
  Future<void> _saveTheme(ThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', theme.index);
  }

  /// Установить светлую тему
  Future<void> setLightTheme() async {
    state = ThemeMode.light;
    await _saveTheme(state);
  }

  /// Установить темную тему
  Future<void> setDarkTheme() async {
    state = ThemeMode.dark;
    await _saveTheme(state);
  }

  /// Установить системную тему
  Future<void> setSystemTheme() async {
    state = ThemeMode.system;
    await _saveTheme(state);
  }

  /// Переключить тему
  Future<void> toggleTheme() async {
    switch (state) {
      case ThemeMode.light:
        await setDarkTheme();
        break;
      case ThemeMode.dark:
        await setSystemTheme();
        break;
      case ThemeMode.system:
        await setLightTheme();
        break;
    }
  }

  /// Получить текущую тему (с учетом системных настроек)
  ThemeMode getCurrentTheme(BuildContext context) {
    if (state == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light;
    }
    return state;
  }

  /// Проверить, является ли текущая тема темной
  bool isDarkMode(BuildContext context) =>
      getCurrentTheme(context) == ThemeMode.dark;
}

/// Провайдер для управления темой
final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) => ThemeNotifier());

/// Провайдер для получения текущей темы с учетом системных настроек
final currentThemeProvider = Provider<ThemeMode>((ref) {
  final themeMode = ref.watch(themeProvider);
  // Этот провайдер будет использоваться в контексте, где доступен BuildContext
  return themeMode;
});

/// Провайдер для проверки темной темы
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeProvider);
  // Этот провайдер будет использоваться в контексте, где доступен BuildContext
  return themeMode == ThemeMode.dark;
});
