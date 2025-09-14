import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Провайдер темы приложения
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

/// Провайдер цветовой схемы
final colorSchemeProvider = StateProvider<ColorScheme>((ref) {
  return ColorScheme.fromSeed(seedColor: Colors.deepPurple);
});

/// Провайдер настроек темы
final themeSettingsProvider = StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>((ref) {
  return ThemeSettingsNotifier();
});

/// Настройки темы
class ThemeSettings {
  final ThemeMode themeMode;
  final Color primaryColor;
  final bool useSystemTheme;
  final bool useMaterial3;

  const ThemeSettings({
    this.themeMode = ThemeMode.system,
    this.primaryColor = Colors.deepPurple,
    this.useSystemTheme = true,
    this.useMaterial3 = true,
  });

  ThemeSettings copyWith({
    ThemeMode? themeMode,
    Color? primaryColor,
    bool? useSystemTheme,
    bool? useMaterial3,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      primaryColor: primaryColor ?? this.primaryColor,
      useSystemTheme: useSystemTheme ?? this.useSystemTheme,
      useMaterial3: useMaterial3 ?? this.useMaterial3,
    );
  }
}

/// Нотификатор темы
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

  /// Сохранить тему
  Future<void> _saveTheme(ThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', theme.index);
  }

  /// Установить тему
  Future<void> setTheme(ThemeMode theme) async {
    state = theme;
    await _saveTheme(theme);
  }

  /// Переключить тему
  Future<void> toggleTheme() async {
    switch (state) {
      case ThemeMode.light:
        await setTheme(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setTheme(ThemeMode.system);
        break;
      case ThemeMode.system:
        await setTheme(ThemeMode.light);
        break;
    }
  }

  /// Получить название темы
  String get themeName {
    switch (state) {
      case ThemeMode.light:
        return 'Светлая';
      case ThemeMode.dark:
        return 'Темная';
      case ThemeMode.system:
        return 'Системная';
    }
  }

  /// Получить иконку темы
  IconData get themeIcon {
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

/// Нотификатор настроек темы
class ThemeSettingsNotifier extends StateNotifier<ThemeSettings> {
  ThemeSettingsNotifier() : super(const ThemeSettings()) {
    _loadSettings();
  }

  /// Загрузить настройки
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    final primaryColorValue = prefs.getInt('primary_color') ?? Colors.deepPurple.value;
    final useSystemTheme = prefs.getBool('use_system_theme') ?? true;
    final useMaterial3 = prefs.getBool('use_material3') ?? true;

    state = ThemeSettings(
      themeMode: ThemeMode.values[themeIndex],
      primaryColor: Color(primaryColorValue),
      useSystemTheme: useSystemTheme,
      useMaterial3: useMaterial3,
    );
  }

  /// Сохранить настройки
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', state.themeMode.index);
    await prefs.setInt('primary_color', state.primaryColor.value);
    await prefs.setBool('use_system_theme', state.useSystemTheme);
    await prefs.setBool('use_material3', state.useMaterial3);
  }

  /// Установить режим темы
  Future<void> setThemeMode(ThemeMode themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    await _saveSettings();
  }

  /// Установить основной цвет
  Future<void> setPrimaryColor(Color color) async {
    state = state.copyWith(primaryColor: color);
    await _saveSettings();
  }

  /// Установить использование системной темы
  Future<void> setUseSystemTheme(bool useSystemTheme) async {
    state = state.copyWith(useSystemTheme: useSystemTheme);
    await _saveSettings();
  }

  /// Установить использование Material 3
  Future<void> setUseMaterial3(bool useMaterial3) async {
    state = state.copyWith(useMaterial3: useMaterial3);
    await _saveSettings();
  }
}

/// Провайдер для получения текущей темы
final currentThemeProvider = Provider<ThemeData>((ref) {
  final themeMode = ref.watch(themeProvider);
  final settings = ref.watch(themeSettingsProvider);
  
  return _buildTheme(settings, themeMode);
});

/// Построить тему
ThemeData _buildTheme(ThemeSettings settings, ThemeMode themeMode) {
  final brightness = themeMode == ThemeMode.dark 
      ? Brightness.dark 
      : themeMode == ThemeMode.light 
          ? Brightness.light 
          : null;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: settings.primaryColor,
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: settings.useMaterial3,
    colorScheme: colorScheme,
    brightness: brightness,
    
    // Настройки AppBar
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
    ),
    
    // Настройки карточек
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    // Настройки кнопок
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    
    // Настройки полей ввода
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    
    // Настройки навигации
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
    ),
    
    // Настройки NavigationRail
    navigationRailTheme: NavigationRailThemeData(
      selectedIconTheme: IconThemeData(color: colorScheme.primary),
      selectedLabelTextStyle: TextStyle(color: colorScheme.primary),
    ),
  );
}

/// Провайдер для получения темной темы
final darkThemeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  return _buildTheme(settings, ThemeMode.dark);
});

/// Провайдер для получения светлой темы
final lightThemeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  return _buildTheme(settings, ThemeMode.light);
});

/// Провайдер для получения системной темы
final systemThemeProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  return _buildTheme(settings, ThemeMode.system);
});

/// Предустановленные цветовые схемы
final predefinedColors = [
  Colors.deepPurple,
  Colors.blue,
  Colors.green,
  Colors.orange,
  Colors.red,
  Colors.pink,
  Colors.teal,
  Colors.indigo,
  Colors.cyan,
  Colors.amber,
];

/// Провайдер для получения предустановленных цветов
final predefinedColorsProvider = Provider<List<Color>>((ref) {
  return predefinedColors;
});

