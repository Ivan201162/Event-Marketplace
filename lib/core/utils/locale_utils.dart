import 'package:flutter/material.dart';

class LocaleUtils {
  static String getLocaleFlag(String localeCode) {
    switch (localeCode) {
      case 'ru':
        return '🇷🇺';
      case 'en':
        return '🇺🇸';
      case 'de':
        return '🇩🇪';
      case 'fr':
        return '🇫🇷';
      case 'es':
        return '🇪🇸';
      case 'it':
        return '🇮🇹';
      case 'pt':
        return '🇵🇹';
      case 'zh':
        return '🇨🇳';
      case 'ja':
        return '🇯🇵';
      case 'ko':
        return '🇰🇷';
      default:
        return '🌐';
    }
  }

  static String getLocaleName(String localeCode) {
    switch (localeCode) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      case 'de':
        return 'Deutsch';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      case 'it':
        return 'Italiano';
      case 'pt':
        return 'Português';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      default:
        return 'Unknown';
    }
  }

  static List<Locale> get supportedLocales => [
    const Locale('ru', 'RU'),
    const Locale('en', 'US'),
    const Locale('de', 'DE'),
    const Locale('fr', 'FR'),
    const Locale('es', 'ES'),
    const Locale('it', 'IT'),
    const Locale('pt', 'PT'),
    const Locale('zh', 'CN'),
    const Locale('ja', 'JP'),
    const Locale('ko', 'KR'),
  ];
}
