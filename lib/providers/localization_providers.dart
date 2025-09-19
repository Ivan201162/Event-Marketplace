import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/localization.dart';
import '../services/localization_service.dart';

/// Провайдер сервиса локализации
final localizationServiceProvider =
    Provider<LocalizationService>((ref) => LocalizationService());

/// Нотификатор для настроек локализации
class LocalizationSettingsNotifier extends Notifier<LocalizationSettings?> {
  @override
  LocalizationSettings? build() => null;

  void setSettings(LocalizationSettings? settings) {
    state = settings;
  }
}

/// Провайдер настроек локализации
final localizationSettingsProvider =
    NotifierProvider<LocalizationSettingsNotifier, LocalizationSettings?>(
  LocalizationSettingsNotifier.new,
);

/// Нотификатор для текущей локализации
class CurrentLocalizationNotifier extends Notifier<LocalizationModel?> {
  @override
  LocalizationModel? build() => null;

  void setLocalization(LocalizationModel? localization) {
    state = localization;
  }
}

/// Провайдер текущей локализации
final currentLocalizationProvider =
    NotifierProvider<CurrentLocalizationNotifier, LocalizationModel?>(
  CurrentLocalizationNotifier.new,
);

/// Нотификатор для текущего языка
class CurrentLanguageNotifier extends Notifier<String> {
  @override
  String build() => 'ru';

  void setLanguage(String language) {
    state = language;
  }
}

/// Провайдер текущего языка
final currentLanguageProvider =
    NotifierProvider<CurrentLanguageNotifier, String>(
  CurrentLanguageNotifier.new,
);

/// Провайдер текущей локали
final currentLocaleProvider = Provider<Locale>((ref) {
  final language = ref.watch(currentLanguageProvider);
  final supportedLanguage = SupportedLanguage.values.firstWhere(
    (lang) => lang.languageCode == language,
    orElse: () => SupportedLanguage.russian,
  );
  return supportedLanguage.locale;
});

/// Нотификатор для доступных локализаций
class AvailableLocalizationsNotifier extends Notifier<List<LocalizationModel>> {
  @override
  List<LocalizationModel> build() => [];

  void setLocalizations(List<LocalizationModel> localizations) {
    state = localizations;
  }

  void addLocalization(LocalizationModel localization) {
    state = [...state, localization];
  }

  void removeLocalization(String languageCode) {
    state = state.where((l) => l.languageCode != languageCode).toList();
  }
}

/// Провайдер доступных локализаций
final availableLocalizationsProvider =
    NotifierProvider<AvailableLocalizationsNotifier, List<LocalizationModel>>(
  AvailableLocalizationsNotifier.new,
);

/// Провайдер поддерживаемых языков
final supportedLanguagesProvider =
    Provider<List<SupportedLanguage>>((ref) => SupportedLanguage.values);

/// Провайдер статистики локализации
final localizationStatsProvider =
    FutureProvider.family<LocalizationStats, String>(
  (ref, languageCode) =>
      ref.watch(localizationServiceProvider).getLocalizationStats(languageCode),
);

/// Провайдер всех статистик локализации
final allLocalizationStatsProvider = FutureProvider<List<LocalizationStats>>(
  (ref) => ref.watch(localizationServiceProvider).getAllLocalizationStats(),
);

/// Провайдер для перевода текста
final translateProvider =
    Provider<String Function(String, {Map<String, dynamic>? params})>((ref) {
  final service = ref.watch(localizationServiceProvider);
  return service.translate;
});

/// Провайдер для проверки наличия перевода
final hasTranslationProvider = Provider<bool Function(String)>((ref) {
  final service = ref.watch(localizationServiceProvider);
  return service.hasTranslation;
});

/// Провайдер для инициализации локализации
final localizationInitializationProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(localizationServiceProvider);
  await service.initialize();

  // Обновляем провайдеры после инициализации
  ref.read(localizationSettingsProvider.notifier).state = service.settings;
  ref.read(currentLocalizationProvider.notifier).state =
      service.currentLocalization;
  ref.read(currentLanguageProvider.notifier).state = service.currentLanguage;
  ref.read(availableLocalizationsProvider.notifier).state =
      service.availableLocalizations;
});

/// Провайдер для изменения языка
final changeLanguageProvider =
    FutureProvider.family<void, String>((ref, languageCode) async {
  final service = ref.watch(localizationServiceProvider);
  await service.setLanguage(languageCode);

  // Обновляем провайдеры после изменения языка
  ref.read(localizationSettingsProvider.notifier).state = service.settings;
  ref.read(currentLocalizationProvider.notifier).state =
      service.currentLocalization;
  ref.read(currentLanguageProvider.notifier).state = service.currentLanguage;
});

/// Провайдер для обновления настроек локализации
final updateLocalizationSettingsProvider =
    FutureProvider.family<void, LocalizationSettings>((ref, settings) async {
  final service = ref.watch(localizationServiceProvider);
  await service.updateSettings(settings);

  // Обновляем провайдеры после обновления настроек
  ref.read(localizationSettingsProvider.notifier).state = service.settings;
  ref.read(currentLocalizationProvider.notifier).state =
      service.currentLocalization;
  ref.read(currentLanguageProvider.notifier).state = service.currentLanguage;
});

/// Провайдер для экспорта переводов
final exportTranslationsProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
  (ref, languageCode) =>
      ref.watch(localizationServiceProvider).exportTranslations(languageCode),
);

/// Провайдер для импорта переводов
final importTranslationsProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, data) async {
  final service = ref.watch(localizationServiceProvider);
  final languageCode = data['languageCode'] as String;
  final translations = data['translations'] as Map<String, String>;

  await service.importTranslations(languageCode, translations);

  // Обновляем провайдеры после импорта
  ref.read(availableLocalizationsProvider.notifier).state =
      service.availableLocalizations;
  if (languageCode == service.currentLanguage) {
    ref.read(currentLocalizationProvider.notifier).state =
        service.currentLocalization;
  }
});

/// Провайдер для очистки кэша локализации
final clearLocalizationCacheProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(localizationServiceProvider);
  await service.clearCache();

  // Обновляем провайдеры после очистки кэша
  ref.read(availableLocalizationsProvider.notifier).state =
      service.availableLocalizations;
  ref.read(currentLocalizationProvider.notifier).state =
      service.currentLocalization;
});

/// Провайдер для получения языка по коду
final getLanguageByCodeProvider = Provider<SupportedLanguage Function(String)>(
  (ref) => (languageCode) => SupportedLanguage.values.firstWhere(
        (lang) => lang.languageCode == languageCode,
        orElse: () => SupportedLanguage.russian,
      ),
);

/// Провайдер для получения отображаемого имени языка
final getLanguageDisplayNameProvider = Provider<String Function(String, bool)>(
  (ref) => (languageCode, showNative) {
    final language = SupportedLanguage.values.firstWhere(
      (lang) => lang.languageCode == languageCode,
      orElse: () => SupportedLanguage.russian,
    );
    return showNative ? language.nativeName : language.displayName;
  },
);

/// Провайдер для проверки RTL языков
final isRTLProvider = Provider<bool Function(String)>(
  (ref) => (languageCode) {
    // Список RTL языков
    const rtlLanguages = ['ar', 'he', 'fa', 'ur'];
    return rtlLanguages.contains(languageCode);
  },
);

/// Провайдер для получения направления текста
final textDirectionProvider = Provider<TextDirection Function(String)>(
  (ref) => (languageCode) {
    final isRTL = ref.watch(isRTLProvider)(languageCode);
    return isRTL ? TextDirection.rtl : TextDirection.ltr;
  },
);

/// Провайдер для форматирования даты
final dateFormatProvider = Provider<String Function(DateTime, String)>(
  (ref) => (date, languageCode) {
    // Простое форматирование даты в зависимости от языка
    switch (languageCode) {
      case 'ru':
        return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
      case 'en':
        return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
      case 'es':
      case 'fr':
      case 'de':
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      default:
        return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  },
);

/// Провайдер для форматирования времени
final timeFormatProvider = Provider<String Function(DateTime, String)>(
  (ref) => (time, languageCode) {
    // Простое форматирование времени в зависимости от языка
    switch (languageCode) {
      case 'ru':
      case 'en':
      case 'es':
      case 'fr':
      case 'de':
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      default:
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  },
);

/// Провайдер для форматирования чисел
final numberFormatProvider = Provider<String Function(num, String)>(
  (ref) => (number, languageCode) {
    // Простое форматирование чисел в зависимости от языка
    switch (languageCode) {
      case 'ru':
        return number.toString().replaceAll('.', ',');
      case 'en':
      case 'es':
      case 'fr':
      case 'de':
        return number.toString();
      default:
        return number.toString();
    }
  },
);

/// Провайдер для форматирования валюты
final currencyFormatProvider = Provider<String Function(num, String, String)>(
  (ref) => (amount, languageCode, currencyCode) {
    // Простое форматирование валюты в зависимости от языка
    switch (languageCode) {
      case 'ru':
        return '${amount.toStringAsFixed(2).replaceAll('.', ',')} ₽';
      case 'en':
        return '\$${amount.toStringAsFixed(2)}';
      case 'es':
        return '${amount.toStringAsFixed(2)} €';
      case 'fr':
        return '${amount.toStringAsFixed(2)} €';
      case 'de':
        return '${amount.toStringAsFixed(2)} €';
      default:
        return '${amount.toStringAsFixed(2)} ₽';
    }
  },
);
