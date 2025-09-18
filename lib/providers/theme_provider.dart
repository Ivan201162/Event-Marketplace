import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';

/// Типы тем
enum ThemeMode {
  light,
  dark,
  system,
}

/// Провайдер для управления темами
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  () => ThemeNotifier(),
);

/// Провайдер для получения текущей темы
final currentThemeProvider = Provider<ThemeData>((ref) {
  final themeMode = ref.watch(themeProvider);
  final brightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  switch (themeMode) {
    case ThemeMode.light:
      return AppTheme.lightTheme;
    case ThemeMode.dark:
      return AppTheme.darkTheme;
    case ThemeMode.system:
      return brightness == Brightness.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme;
  }
});

/// Провайдер для получения режима темы
final themeModeProvider = Provider<ThemeMode>((ref) {
  final themeMode = ref.watch(themeProvider);
  final brightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  switch (themeMode) {
    case ThemeMode.light:
      return ThemeMode.light;
    case ThemeMode.dark:
      return ThemeMode.dark;
    case ThemeMode.system:
      return brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  }
});

/// Провайдер для получения яркости системы
final systemBrightnessProvider = Provider<Brightness>((ref) {
  return WidgetsBinding.instance.platformDispatcher.platformBrightness;
});

/// Провайдер для проверки, включена ли темная тема
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeProvider);
  final systemBrightness = ref.watch(systemBrightnessProvider);

  switch (themeMode) {
    case ThemeMode.light:
      return false;
    case ThemeMode.dark:
      return true;
    case ThemeMode.system:
      return systemBrightness == Brightness.dark;
  }
});

/// Провайдер для получения цветовой схемы
final colorSchemeProvider = Provider<ColorScheme>((ref) {
  final theme = ref.watch(currentThemeProvider);
  return theme.colorScheme;
});

/// Провайдер для получения цветов бренда
final brandColorsProvider = Provider<BrandColors>((ref) {
  return BrandColors();
});

/// Нотификатор для управления темами
class ThemeNotifier extends Notifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';

  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.system;
  }

  /// Загрузить сохраненную тему
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
      state = ThemeMode.values[themeIndex];
    } catch (e) {
      // В случае ошибки используем системную тему
      state = ThemeMode.system;
    }
  }

  /// Сохранить выбранную тему
  Future<void> _saveTheme(ThemeMode theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, theme.index);
    } catch (e) {
      // Игнорируем ошибки сохранения
    }
  }

  /// Установить светлую тему
  Future<void> setLightTheme() async {
    state = ThemeMode.light;
    await _saveTheme(ThemeMode.light);
  }

  /// Установить темную тему
  Future<void> setDarkTheme() async {
    state = ThemeMode.dark;
    await _saveTheme(ThemeMode.dark);
  }

  /// Установить системную тему
  Future<void> setSystemTheme() async {
    state = ThemeMode.system;
    await _saveTheme(ThemeMode.system);
  }

  /// Переключить тему
  Future<void> toggleTheme() async {
    final currentBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isCurrentlyDark = currentBrightness == Brightness.dark;

    if (state == ThemeMode.system) {
      // Если используется системная тема, переключаем на противоположную
      if (isCurrentlyDark) {
        await setLightTheme();
      } else {
        await setDarkTheme();
      }
    } else {
      // Если используется конкретная тема, переключаем на противоположную
      if (state == ThemeMode.light) {
        await setDarkTheme();
      } else {
        await setLightTheme();
      }
    }
  }

  /// Получить название текущей темы
  String getCurrentThemeName() {
    switch (state) {
      case ThemeMode.light:
        return 'Светлая';
      case ThemeMode.dark:
        return 'Темная';
      case ThemeMode.system:
        return 'Системная';
    }
  }

  /// Получить описание текущей темы
  String getCurrentThemeDescription() {
    switch (state) {
      case ThemeMode.light:
        return 'Всегда светлая тема';
      case ThemeMode.dark:
        return 'Всегда темная тема';
      case ThemeMode.system:
        return 'Следует системным настройкам';
    }
  }

  /// Получить иконку для текущей темы
  IconData getCurrentThemeIcon() {
    switch (state) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}

/// Расширения для ThemeMode
extension ThemeModeExtension on ThemeMode {
  /// Получить название темы
  String get name {
    switch (this) {
      case ThemeMode.light:
        return 'Светлая';
      case ThemeMode.dark:
        return 'Темная';
      case ThemeMode.system:
        return 'Системная';
    }
  }

  /// Получить описание темы
  String get description {
    switch (this) {
      case ThemeMode.light:
        return 'Всегда светлая тема';
      case ThemeMode.dark:
        return 'Всегда темная тема';
      case ThemeMode.system:
        return 'Следует системным настройкам';
    }
  }

  /// Получить иконку темы
  IconData get icon {
    switch (this) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}

/// Провайдер для получения доступных тем
final availableThemesProvider = Provider<List<ThemeMode>>((ref) {
  return ThemeMode.values;
});

/// Провайдер для получения информации о теме
final themeInfoProvider =
    Provider.family<ThemeInfo, ThemeMode>((ref, themeMode) {
  return ThemeInfo(
    mode: themeMode,
    name: themeMode.name,
    description: themeMode.description,
    icon: themeMode.icon,
  );
});

/// Информация о теме
class ThemeInfo {
  final ThemeMode mode;
  final String name;
  final String description;
  final IconData icon;

  const ThemeInfo({
    required this.mode,
    required this.name,
    required this.description,
    required this.icon,
  });
}

/// Провайдер для получения цветов темы
final themeColorsProvider = Provider<ThemeColors>((ref) {
  final colorScheme = ref.watch(colorSchemeProvider);
  final isDark = ref.watch(isDarkModeProvider);

  return ThemeColors(
    primary: colorScheme.primary,
    secondary: colorScheme.secondary,
    surface: colorScheme.surface,
    background: colorScheme.surface,
    error: colorScheme.error,
    onPrimary: colorScheme.onPrimary,
    onSecondary: colorScheme.onSecondary,
    onSurface: colorScheme.onSurface,
    onBackground: colorScheme.onSurface,
    onError: colorScheme.onError,
    isDark: isDark,
  );
});

/// Цвета темы
class ThemeColors {
  final Color primary;
  final Color secondary;
  final Color surface;
  final Color background;
  final Color error;
  final Color onPrimary;
  final Color onSecondary;
  final Color onSurface;
  final Color onBackground;
  final Color onError;
  final bool isDark;

  const ThemeColors({
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.background,
    required this.error,
    required this.onPrimary,
    required this.onSecondary,
    required this.onSurface,
    required this.onBackground,
    required this.onError,
    required this.isDark,
  });
}
