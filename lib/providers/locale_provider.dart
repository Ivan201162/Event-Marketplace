import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер для управления локализацией
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

/// Нотификатор для управления локалью
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ru'));

  /// Изменить локаль
  void setLocale(Locale locale) {
    state = locale;
  }

  /// Переключить между русским и английским
  void toggleLocale() {
    if (state.languageCode == 'ru') {
      state = const Locale('en');
    } else {
      state = const Locale('ru');
    }
  }

  /// Получить текущий язык
  String get currentLanguage => state.languageCode;

  /// Проверить, является ли текущий язык русским
  bool get isRussian => state.languageCode == 'ru';

  /// Проверить, является ли текущий язык английским
  bool get isEnglish => state.languageCode == 'en';
}
