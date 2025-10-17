import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../generated/l10n/app_localizations.dart';

/// Провайдер для текущей локали
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

/// Провайдер для списка поддерживаемых локалей
final supportedLocalesProvider = Provider<List<Locale>>(
  (ref) => const [
    Locale('en', ''), // English
    Locale('ru', ''), // Russian
  ],
);

/// Провайдер для делегатов локализации
final localizationDelegatesProvider = Provider<List<LocalizationsDelegate>>(
  (ref) => const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
);

/// Провайдер для списка поддерживаемых локалей для MaterialApp
final supportedLocalesListProvider =
    Provider<List<Locale>>((ref) => ref.watch(supportedLocalesProvider));

/// Провайдер для текущего языка
final currentLanguageProvider = Provider<String>((ref) {
  final locale = ref.watch(localeProvider);
  return locale.languageCode;
});

/// Провайдер для проверки, является ли текущий язык русским
final isRussianProvider = Provider<bool>((ref) {
  final locale = ref.watch(localeProvider);
  return locale.languageCode == 'ru';
});

/// Провайдер для проверки, является ли текущий язык английским
final isEnglishProvider = Provider<bool>((ref) {
  final locale = ref.watch(localeProvider);
  return locale.languageCode == 'en';
});

/// Провайдер для получения локализованных строк
final localizedStringsProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(localeProvider);
  return lookupAppLocalizations(locale);
});

/// Провайдер для получения названия языка
final languageNameProvider = Provider<String>((ref) {
  final locale = ref.watch(localeProvider);
  switch (locale.languageCode) {
    case 'ru':
      return 'Русский';
    case 'en':
      return 'English';
    default:
      return 'English';
  }
});

/// Провайдер для получения списка языков с названиями
final languageListProvider = Provider<List<Map<String, String>>>(
  (ref) => const [
    {'code': 'en', 'name': 'English'},
    {'code': 'ru', 'name': 'Русский'},
  ],
);

/// Нотификатор для управления локалью
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _loadLocale();
    return const Locale('en', '');
  }

  /// Загрузить сохраненную локаль
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'en';
      state = Locale(languageCode, '');
    } catch (e) {
      // В случае ошибки используем английский по умолчанию
      state = const Locale('en', '');
    }
  }

  /// Установить локаль
  Future<void> setLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);
      state = locale;
    } catch (e) {
      // В случае ошибки все равно обновляем состояние
      state = locale;
    }
  }

  /// Переключить на русский язык
  Future<void> setRussian() async {
    await setLocale(const Locale('ru', ''));
  }

  /// Переключить на английский язык
  Future<void> setEnglish() async {
    await setLocale(const Locale('en', ''));
  }

  /// Переключить язык
  Future<void> toggleLanguage() async {
    if (state.languageCode == 'ru') {
      await setEnglish();
    } else {
      await setRussian();
    }
  }

  /// Получить следующий язык в списке
  Future<void> setNextLanguage() async {
    const languages = ['en', 'ru'];
    final currentIndex = languages.indexOf(state.languageCode);
    final nextIndex = (currentIndex + 1) % languages.length;
    await setLocale(Locale(languages[nextIndex], ''));
  }
}

/// Расширение для получения локализованных строк
extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Расширение для получения локализованных строк из провайдера
extension LocalizationProviderExtension on WidgetRef {
  AppLocalizations get l10n => read(localizedStringsProvider);
}

/// Утилиты для работы с локализацией
class LocalizationUtils {
  /// Получить название языка по коду
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return 'English';
    }
  }

  /// Получить код языка по названию
  static String getLanguageCode(String languageName) {
    switch (languageName) {
      case 'Русский':
        return 'ru';
      case 'English':
        return 'en';
      default:
        return 'en';
    }
  }

  /// Проверить, поддерживается ли язык
  static bool isLanguageSupported(String languageCode) => ['en', 'ru'].contains(languageCode);

  /// Получить локаль по коду языка
  static Locale getLocaleFromCode(String languageCode) => Locale(languageCode, '');

  /// Получить код языка из локали
  static String getCodeFromLocale(Locale locale) => locale.languageCode;

  /// Получить список всех поддерживаемых языков
  static List<Map<String, String>> getAllLanguages() => const [
        {'code': 'en', 'name': 'English'},
        {'code': 'ru', 'name': 'Русский'},
      ];

  /// Получить язык по умолчанию
  static Locale getDefaultLocale() => const Locale('en', '');

  /// Получить список поддерживаемых локалей
  static List<Locale> getSupportedLocales() => const [
        Locale('en', ''),
        Locale('ru', ''),
      ];
}
