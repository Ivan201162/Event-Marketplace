import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Провайдер для управления локализацией приложения
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ru')) {
    _loadLocale();
  }

  /// Загрузить сохраненную локаль
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString('locale') ?? 'ru';
    state = Locale(localeCode);
  }

  /// Сохранить выбранную локаль
  Future<void> _saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
  }

  /// Установить русскую локаль
  Future<void> setRussian() async {
    state = const Locale('ru');
    await _saveLocale(state);
  }

  /// Установить английскую локаль
  Future<void> setEnglish() async {
    state = const Locale('en');
    await _saveLocale(state);
  }

  /// Установить казахскую локаль
  Future<void> setKazakh() async {
    state = const Locale('kk');
    await _saveLocale(state);
  }

  /// Установить локаль
  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _saveLocale(locale);
  }

  /// Переключить локаль
  Future<void> toggleLocale() async {
    switch (state.languageCode) {
      case 'ru':
        await setEnglish();
        break;
      case 'en':
        await setKazakh();
        break;
      case 'kk':
        await setRussian();
        break;
      default:
        await setRussian();
        break;
    }
  }

  /// Получить список поддерживаемых локалей
  List<Locale> get supportedLocales => const [
        Locale('ru'),
        Locale('en'),
        Locale('kk'),
      ];

  /// Получить название локали
  String getLocaleName(Locale locale) {
    switch (locale.languageCode) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      case 'kk':
        return 'Қазақша';
      default:
        return 'Русский';
    }
  }

  /// Получить флаг локали
  String getLocaleFlag(Locale locale) {
    switch (locale.languageCode) {
      case 'ru':
        return '🇷🇺';
      case 'en':
        return '🇺🇸';
      case 'kk':
        return '🇰🇿';
      default:
        return '🇷🇺';
    }
  }
}

/// Провайдер для управления локализацией
final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());

/// Провайдер для получения текущей локали
final currentLocaleProvider =
    Provider<Locale>((ref) => ref.watch(localeProvider));
