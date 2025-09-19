import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер для управления локализацией
final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

/// Нотификатор для управления локалью
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('ru');

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
