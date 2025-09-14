import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

/// Провайдер для управления темой приложения
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// Загружает сохранённый режим темы
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt('theme_mode') ?? 0;
    state = ThemeMode.values[themeModeIndex];
  }

  /// Сохраняет режим темы
  Future<void> _saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', themeMode.index);
  }

  /// Устанавливает светлую тему
  Future<void> setLightTheme() async {
    state = ThemeMode.light;
    await _saveThemeMode(state);
  }

  /// Устанавливает тёмную тему
  Future<void> setDarkTheme() async {
    state = ThemeMode.dark;
    await _saveThemeMode(state);
  }

  /// Устанавливает системную тему
  Future<void> setSystemTheme() async {
    state = ThemeMode.system;
    await _saveThemeMode(state);
  }

  /// Переключает между светлой и тёмной темой
  Future<void> toggleTheme() async {
    if (state == ThemeMode.light) {
      await setDarkTheme();
    } else {
      await setLightTheme();
    }
  }
}

/// Провайдер для управления темой
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

/// Провайдер для получения текущей темы
final currentThemeProvider = Provider<ThemeData>((ref) {
  final themeMode = ref.watch(themeProvider);
  return _getThemeData(themeMode);
});

/// Провайдер для получения тёмной темы
final darkThemeProvider = Provider<ThemeData>((ref) {
  return _getThemeData(ThemeMode.dark);
});

/// Провайдер для получения светлой темы
final lightThemeProvider = Provider<ThemeData>((ref) {
  return _getThemeData(ThemeMode.light);
});

/// Создаёт тему данных с использованием FlexColorScheme
ThemeData _getThemeData(ThemeMode themeMode) {
  final isDark = themeMode == ThemeMode.dark;
  
  return FlexThemeData.light(
    scheme: FlexScheme.material,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 7,
    appBarStyle: FlexAppBarStyle.primary,
    appBarOpacity: 0.95,
    appBarElevation: 0,
    transparentStatusBar: true,
    tabBarStyle: FlexTabBarStyle.forAppBar,
    tooltipsMatchBackground: true,
    swapColors: false,
    lightIsWhite: false,
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    useMaterial3ErrorColors: true,
    primaryTextTheme: const TextTheme(),
    primaryIconTheme: const IconThemeData(),
    fontFamily: 'Roboto',
  ).copyWith(
    // Кастомизация для Event Marketplace
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1976D2), // Синий цвет для Event Marketplace
      brightness: isDark ? Brightness.dark : Brightness.light,
    ),
    // Анимации переходов
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

/// Расширение для удобного доступа к теме
extension ThemeExtension on BuildContext {
  /// Получает текущую тему
  ThemeData get theme => Theme.of(this);
  
  /// Получает цветовую схему
  ColorScheme get colorScheme => theme.colorScheme;
  
  /// Проверяет, используется ли тёмная тема
  bool get isDarkMode => theme.brightness == Brightness.dark;
  
  /// Получает цвет акцента
  Color get accentColor => colorScheme.primary;
  
  /// Получает цвет поверхности
  Color get surfaceColor => colorScheme.surface;
  
  /// Получает цвет фона
  Color get backgroundColor => colorScheme.background;
}