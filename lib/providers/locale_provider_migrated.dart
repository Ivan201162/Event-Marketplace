import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier для управления локализацией приложения (мигрирован с StateNotifier)
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _loadLocale();
    return const Locale('ru');
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

  /// Установить произвольную локаль
  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _saveLocale(locale);
  }

  /// Получить текущий язык
  String get currentLanguage {
    switch (state.languageCode) {
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

  /// Получить список доступных языков
  List<Locale> get availableLocales => const [
        Locale('ru'),
        Locale('en'),
        Locale('kk'),
      ];

  /// Получить название языка по коду
  String getLanguageName(String languageCode) {
    switch (languageCode) {
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

  /// Проверить, является ли текущий язык русским
  bool get isRussian => state.languageCode == 'ru';

  /// Проверить, является ли текущий язык английским
  bool get isEnglish => state.languageCode == 'en';

  /// Проверить, является ли текущий язык казахским
  bool get isKazakh => state.languageCode == 'kk';
}

/// Провайдер для управления локализацией (мигрирован с StateNotifierProvider)
final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

/// Провайдер для получения текущего языка
final currentLanguageProvider = Provider<String>((ref) {
  final locale = ref.watch(localeProvider);
  return locale.languageCode;
});

/// Провайдер для получения названия текущего языка
final currentLanguageNameProvider = Provider<String>((ref) {
  final localeNotifier = ref.watch(localeProvider.notifier);
  return localeNotifier.currentLanguage;
});

/// Провайдер для проверки языка
final isRussianProvider = Provider<bool>((ref) {
  final localeNotifier = ref.watch(localeProvider.notifier);
  return localeNotifier.isRussian;
});

final isEnglishProvider = Provider<bool>((ref) {
  final localeNotifier = ref.watch(localeProvider.notifier);
  return localeNotifier.isEnglish;
});

final isKazakhProvider = Provider<bool>((ref) {
  final localeNotifier = ref.watch(localeProvider.notifier);
  return localeNotifier.isKazakh;
});

/// Провайдер для списка доступных языков
final availableLocalesProvider = Provider<List<Locale>>((ref) {
  final localeNotifier = ref.watch(localeProvider.notifier);
  return localeNotifier.availableLocales;
});

