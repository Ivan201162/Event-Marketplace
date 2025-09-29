import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/app_theme.dart';

/// Типы тем
enum AppThemeMode {
  light,
  dark,
  system,
}

/// Провайдер для управления темами
final themeProvider = NotifierProvider<ThemeNotifier, AppThemeMode>(
  ThemeNotifier.new,
);

/// Провайдер для получения текущей темы
final currentThemeProvider = Provider<ThemeData>((ref) {
  final themeMode = ref.watch(themeProvider);
  final brightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  switch (themeMode) {
    case AppThemeMode.light:
      return AppTheme.lightTheme;
    case AppThemeMode.dark:
      return AppTheme.darkTheme;
    case AppThemeMode.system:
      return brightness == Brightness.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme;
  }
});

/// Провайдер для получения режима темы
final AppThemeModeProvider = Provider<AppThemeMode>((ref) {
  final themeMode = ref.watch(themeProvider);
  final brightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  switch (themeMode) {
    case AppThemeMode.light:
      return AppThemeMode.light;
    case AppThemeMode.dark:
      return AppThemeMode.dark;
    case AppThemeMode.system:
      return brightness == Brightness.dark
          ? AppThemeMode.dark
          : AppThemeMode.light;
  }
});

/// Провайдер для получения яркости системы
final systemBrightnessProvider = Provider<Brightness>(
  (ref) => WidgetsBinding.instance.platformDispatcher.platformBrightness,
);

/// Провайдер для проверки, включена ли темная тема
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeProvider);
  final systemBrightness = ref.watch(systemBrightnessProvider);

  switch (themeMode) {
    case AppThemeMode.light:
      return false;
    case AppThemeMode.dark:
      return true;
    case AppThemeMode.system:
      return systemBrightness == Brightness.dark;
  }
});

/// Провайдер для получения цветовой схемы
final colorSchemeProvider = Provider<ColorScheme>((ref) {
  final theme = ref.watch(currentThemeProvider);
  return theme.colorScheme;
});

/// Провайдер для получения цветов бренда
final brandColorsProvider = Provider<BrandColors>((ref) => BrandColors());

/// Нотификатор для управления темами
class ThemeNotifier extends Notifier<AppThemeMode> {
  static const String _themeKey = 'theme_mode';

  @override
  AppThemeMode build() {
    _loadTheme();
    return AppThemeMode.system;
  }

  /// Загрузить сохраненную тему
  Future<void> _loadTheme() async {
    try {
      final storage = const FlutterSecureStorage();
      final themeIndexStr = await storage.read(key: _themeKey);
      final themeIndex = themeIndexStr != null
          ? int.parse(themeIndexStr)
          : AppThemeMode.system.index;
      state = AppThemeMode.values[themeIndex];
    } catch (e) {
      // В случае ошибки используем системную тему
      state = AppThemeMode.system;
    }
  }

  /// Сохранить выбранную тему
  Future<void> _saveTheme(AppThemeMode theme) async {
    try {
      final storage = const FlutterSecureStorage();
      await storage.write(key: _themeKey, value: theme.index.toString());
    } catch (e) {
      // Игнорируем ошибки сохранения
    }
  }

  /// Установить светлую тему
  Future<void> setLightTheme() async {
    state = AppThemeMode.light;
    await _saveTheme(AppThemeMode.light);
  }

  /// Установить темную тему
  Future<void> setDarkTheme() async {
    state = AppThemeMode.dark;
    await _saveTheme(AppThemeMode.dark);
  }

  /// Установить системную тему
  Future<void> setSystemTheme() async {
    state = AppThemeMode.system;
    await _saveTheme(AppThemeMode.system);
  }

  /// Переключить тему
  Future<void> toggleTheme() async {
    final currentBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isCurrentlyDark = currentBrightness == Brightness.dark;

    if (state == AppThemeMode.system) {
      // Если используется системная тема, переключаем на противоположную
      if (isCurrentlyDark) {
        await setLightTheme();
      } else {
        await setDarkTheme();
      }
    } else {
      // Если используется конкретная тема, переключаем на противоположную
      if (state == AppThemeMode.light) {
        await setDarkTheme();
      } else {
        await setLightTheme();
      }
    }
  }

  /// Получить название текущей темы
  String getCurrentThemeName() {
    switch (state) {
      case AppThemeMode.light:
        return 'Светлая';
      case AppThemeMode.dark:
        return 'Темная';
      case AppThemeMode.system:
        return 'Системная';
    }
  }

  /// Получить описание текущей темы
  String getCurrentThemeDescription() {
    switch (state) {
      case AppThemeMode.light:
        return 'Всегда светлая тема';
      case AppThemeMode.dark:
        return 'Всегда темная тема';
      case AppThemeMode.system:
        return 'Следует системным настройкам';
    }
  }

  /// Получить иконку для текущей темы
  IconData getCurrentThemeIcon() {
    switch (state) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}

/// Расширения для AppThemeMode
extension AppThemeModeExtension on AppThemeMode {
  /// Получить название темы
  String get name {
    switch (this) {
      case AppThemeMode.light:
        return 'Светлая';
      case AppThemeMode.dark:
        return 'Темная';
      case AppThemeMode.system:
        return 'Системная';
    }
  }

  /// Получить описание темы
  String get description {
    switch (this) {
      case AppThemeMode.light:
        return 'Всегда светлая тема';
      case AppThemeMode.dark:
        return 'Всегда темная тема';
      case AppThemeMode.system:
        return 'Следует системным настройкам';
    }
  }

  /// Получить иконку темы
  IconData get icon {
    switch (this) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}

/// Провайдер для получения доступных тем
final availableThemesProvider =
    Provider<List<AppThemeMode>>((ref) => AppThemeMode.values);

/// Провайдер для получения информации о теме
final themeInfoProvider = Provider.family<ThemeInfo, AppThemeMode>(
  (ref, AppThemeMode) => ThemeInfo(
    mode: AppThemeMode,
    name: AppThemeMode.name,
    description: AppThemeMode.description,
    icon: AppThemeMode.icon,
  ),
);

/// Информация о теме
class ThemeInfo {
  const ThemeInfo({
    required this.mode,
    required this.name,
    required this.description,
    required this.icon,
  });
  final AppThemeMode mode;
  final String name;
  final String description;
  final IconData icon;
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
}
