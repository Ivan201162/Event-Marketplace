import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Провайдер для управления темами приложения
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.system;
  }

  static const String _themeKey = 'theme_mode';

  ThemeMode get themeMode => state;

  /// Загружает сохранённую тему
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      state = ThemeMode.values[themeIndex];
    } catch (e) {
      debugPrint('Ошибка загрузки темы: $e');
      state = ThemeMode.system;
    }
  }

  /// Сохраняет выбранную тему
  Future<void> _saveTheme(ThemeMode theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, theme.index);
    } catch (e) {
      debugPrint('Ошибка сохранения темы: $e');
    }
  }

  /// Устанавливает светлую тему
  Future<void> setLightTheme() async {
    state = ThemeMode.light;
    await _saveTheme(state);
  }

  /// Устанавливает тёмную тему
  Future<void> setDarkTheme() async {
    state = ThemeMode.dark;
    await _saveTheme(state);
  }

  /// Устанавливает автоматическую тему
  Future<void> setSystemTheme() async {
    state = ThemeMode.system;
    await _saveTheme(state);
  }

  /// Переключает между светлой и тёмной темой
  Future<void> toggleTheme() async {
    if (state == ThemeMode.light) {
      await setDarkTheme();
    } else {
      await setLightTheme();
    }
  }

  /// Получает текущую тему
  ThemeData getCurrentTheme(BuildContext context) {
    switch (state) {
      case ThemeMode.light:
        return AppTheme.lightTheme;
      case ThemeMode.dark:
        return AppTheme.darkTheme;
      case ThemeMode.system:
        final brightness = MediaQuery.of(context).platformBrightness;
        return brightness == Brightness.light
            ? AppTheme.lightTheme
            : AppTheme.darkTheme;
    }
  }

  /// Проверяет, является ли текущая тема тёмной
  bool isDarkMode(BuildContext context) {
    switch (state) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }
}

/// Провайдер для управления темами
final themeProvider =
    NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

/// Провайдер для получения текущего режима темы
final themeModeProvider =
    Provider<ThemeMode>((ref) => ref.watch(themeProvider));
