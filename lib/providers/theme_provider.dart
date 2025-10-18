import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';
import 'package:flutter/foundation.dart';

/// РџСЂРѕРІР°Р№РґРµСЂ РґР»СЏ СѓРїСЂР°РІР»РµРЅРёСЏ С‚РµРјР°РјРё РїСЂРёР»РѕР¶РµРЅРёСЏ
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.system;
  }

  static const String _themeKey = 'theme_mode';

  ThemeMode get themeMode => state;

  /// Р—Р°РіСЂСѓР¶Р°РµС‚ СЃРѕС…СЂР°РЅС‘РЅРЅСѓСЋ С‚РµРјСѓ
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      state = ThemeMode.values[themeIndex];
    } catch (e) {
      debugPrint('РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё С‚РµРјС‹: $e');
      state = ThemeMode.system;
    }
  }

  /// РЎРѕС…СЂР°РЅСЏРµС‚ РІС‹Р±СЂР°РЅРЅСѓСЋ С‚РµРјСѓ
  Future<void> _saveTheme(ThemeMode theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, theme.index);
    } catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕС…СЂР°РЅРµРЅРёСЏ С‚РµРјС‹: $e');
    }
  }

  /// РЈСЃС‚Р°РЅР°РІР»РёРІР°РµС‚ СЃРІРµС‚Р»СѓСЋ С‚РµРјСѓ
  Future<void> setLightTheme() async {
    state = ThemeMode.light;
    await _saveTheme(state);
  }

  /// РЈСЃС‚Р°РЅР°РІР»РёРІР°РµС‚ С‚С‘РјРЅСѓСЋ С‚РµРјСѓ
  Future<void> setDarkTheme() async {
    state = ThemeMode.dark;
    await _saveTheme(state);
  }

  /// РЈСЃС‚Р°РЅР°РІР»РёРІР°РµС‚ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєСѓСЋ С‚РµРјСѓ
  Future<void> setSystemTheme() async {
    state = ThemeMode.system;
    await _saveTheme(state);
  }

  /// РџРµСЂРµРєР»СЋС‡Р°РµС‚ РјРµР¶РґСѓ СЃРІРµС‚Р»РѕР№ Рё С‚С‘РјРЅРѕР№ С‚РµРјРѕР№
  Future<void> toggleTheme() async {
    if (state == ThemeMode.light) {
      await setDarkTheme();
    } else {
      await setLightTheme();
    }
  }

  /// РџРѕР»СѓС‡Р°РµС‚ С‚РµРєСѓС‰СѓСЋ С‚РµРјСѓ
  ThemeData getCurrentTheme(BuildContext context) {
    switch (state) {
      case ThemeMode.light:
        return AppTheme.lightTheme;
      case ThemeMode.dark:
        return AppTheme.darkTheme;
      case ThemeMode.system:
        final brightness = MediaQuery.of(context).platformBrightness;
        return brightness == Brightness.light ? AppTheme.lightTheme : AppTheme.darkTheme;
    }
  }

  /// РџСЂРѕРІРµСЂСЏРµС‚, СЏРІР»СЏРµС‚СЃСЏ Р»Рё С‚РµРєСѓС‰Р°СЏ С‚РµРјР° С‚С‘РјРЅРѕР№
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

/// РџСЂРѕРІР°Р№РґРµСЂ РґР»СЏ СѓРїСЂР°РІР»РµРЅРёСЏ С‚РµРјР°РјРё
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

/// РџСЂРѕРІР°Р№РґРµСЂ РґР»СЏ РїРѕР»СѓС‡РµРЅРёСЏ С‚РµРєСѓС‰РµРіРѕ СЂРµР¶РёРјР° С‚РµРјС‹
final themeModeProvider = Provider<ThemeMode>((ref) => ref.watch(themeProvider));

