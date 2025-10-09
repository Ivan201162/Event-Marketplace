import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Провайдер для управления темами приложения
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadThemePreference();
  }

  /// Загрузка сохранённой темы
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString('themeMode') ?? 'system';
      state = _getThemeModeFromString(themeString);
    } on Exception {
      // Если ошибка, используем системную тему
      state = ThemeMode.system;
    }
  }

  /// Сохранение выбранной темы
  Future<void> _saveThemePreference(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeMode', mode.toString().split('.').last);
    } on Exception {
      // Игнорируем ошибки сохранения
    }
  }

  /// Преобразование строки в ThemeMode
  ThemeMode _getThemeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Изменение темы
  Future<void> changeTheme(ThemeMode mode) async {
    state = mode;
    await _saveThemePreference(mode);
  }

  /// Автоматическое определение темы по времени суток
  void applyAutoThemeByTime() {
    final hour = DateTime.now().hour;
    if (hour >= 7 && hour < 19) {
      // День (7:00 - 19:00) - светлая тема
      state = ThemeMode.light;
    } else {
      // Ночь (19:00 - 7:00) - тёмная тема
      state = ThemeMode.dark;
    }
  }

  /// Получение текущей темы с учётом времени суток
  ThemeMode getCurrentThemeWithTime() {
    if (state == ThemeMode.system) {
      final hour = DateTime.now().hour;
      return (hour >= 7 && hour < 19) ? ThemeMode.light : ThemeMode.dark;
    }
    return state;
  }
}

/// Провайдер для управления темами
final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) => ThemeNotifier());

/// Провайдер для получения текущей темы с учётом времени
final currentThemeProvider = Provider<ThemeMode>((ref) {
  final themeNotifier = ref.watch(themeProvider.notifier);
  return themeNotifier.getCurrentThemeWithTime();
});

/// Провайдер для получения цветовой схемы
final colorSchemeProvider = Provider<ColorScheme>((ref) {
  final themeMode = ref.watch(currentThemeProvider);
  final brightness =
      themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;

  if (brightness == Brightness.dark) {
    return const ColorScheme.dark(
      primary: Colors.amber,
      secondary: Colors.deepPurple,
      error: Colors.redAccent,
    );
  } else {
    return const ColorScheme.light(
      primary: Colors.deepPurple,
      secondary: Colors.amber,
      error: Colors.red,
    );
  }
});
