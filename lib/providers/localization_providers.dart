import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/localization.dart';
import '../services/localization_service.dart';

/// Провайдер сервиса локализации
final localizationServiceProvider = Provider<LocalizationService>((ref) {
  return LocalizationService();
});

/// Провайдер настроек локализации
final localizationSettingsProvider =
    StateProvider<LocalizationSettings?>((ref) {
  return null;
});

/// Провайдер текущей локализации
final currentLocalizationProvider = StateProvider<LocalizationModel?>((ref) {
  return null;
});

/// Провайдер текущего языка
final currentLanguageProvider = StateProvider<String>((ref) {
  return 'ru';
});

/// Провайдер текущей локали
final currentLocaleProvider = Provider<Locale>((ref) {
  final language = ref.watch(currentLanguageProvider);
  final supportedLanguage = SupportedLanguage.values.firstWhere(
    (lang) => lang.languageCode == language,
    orElse: () => SupportedLanguage.russian,
  );
  return supportedLanguage.locale;
});

/// Провайдер доступных локализаций
final availableLocalizationsProvider =
    StateProvider<List<LocalizationModel>>((ref) {
  return [];
});

/// Провайдер поддерживаемых языков
final supportedLanguagesProvider = Provider<List<SupportedLanguage>>((ref) {
  return SupportedLanguage.values;
});

/// Провайдер статистики локализации
final localizationStatsProvider =
    FutureProvider.family<LocalizationStats, String>((ref, languageCode) {
  return ref
      .watch(localizationServiceProvider)
      .getLocalizationStats(languageCode);
});

/// Провайдер всех статистик локализации
final allLocalizationStatsProvider =
    FutureProvider<List<LocalizationStats>>((ref) {
  return ref.watch(localizationServiceProvider).getAllLocalizationStats();
});

/// Провайдер для перевода текста
final translateProvider =
    Provider<String Function(String, {Map<String, dynamic>? params})>((ref) {
  final service = ref.watch(localizationServiceProvider);
  return (String key, {Map<String, dynamic>? params}) {
    return service.translate(key, params: params);
  };
});

/// Провайдер для проверки наличия перевода
final hasTranslationProvider = Provider<bool Function(String)>((ref) {
  final service = ref.watch(localizationServiceProvider);
  return (String key) {
    return service.hasTranslation(key);
  };
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
    FutureProvider.family<Map<String, dynamic>, String>((ref, languageCode) {
  return ref
      .watch(localizationServiceProvider)
      .exportTranslations(languageCode);
});

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
final getLanguageByCodeProvider =
    Provider<SupportedLanguage Function(String)>((ref) {
  return (String languageCode) {
    return SupportedLanguage.values.firstWhere(
      (lang) => lang.languageCode == languageCode,
      orElse: () => SupportedLanguage.russian,
    );
  };
});

/// Провайдер для получения отображаемого имени языка
final getLanguageDisplayNameProvider =
    Provider<String Function(String, bool)>((ref) {
  return (String languageCode, bool showNative) {
    final language = SupportedLanguage.values.firstWhere(
      (lang) => lang.languageCode == languageCode,
      orElse: () => SupportedLanguage.russian,
    );
    return showNative ? language.nativeName : language.displayName;
  };
});

/// Провайдер для проверки RTL языков
final isRTLProvider = Provider<bool Function(String)>((ref) {
  return (String languageCode) {
    // Список RTL языков
    const rtlLanguages = ['ar', 'he', 'fa', 'ur'];
    return rtlLanguages.contains(languageCode);
  };
});

/// Провайдер для получения направления текста
final textDirectionProvider = Provider<TextDirection Function(String)>((ref) {
  return (String languageCode) {
    final isRTL = ref.watch(isRTLProvider)(languageCode);
    return isRTL ? TextDirection.rtl : TextDirection.ltr;
  };
});

/// Провайдер для форматирования даты
final dateFormatProvider = Provider<String Function(DateTime, String)>((ref) {
  return (DateTime date, String languageCode) {
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
  };
});

/// Провайдер для форматирования времени
final timeFormatProvider = Provider<String Function(DateTime, String)>((ref) {
  return (DateTime time, String languageCode) {
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
  };
});

/// Провайдер для форматирования чисел
final numberFormatProvider = Provider<String Function(num, String)>((ref) {
  return (num number, String languageCode) {
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
  };
});

/// Провайдер для форматирования валюты
final currencyFormatProvider =
    Provider<String Function(num, String, String)>((ref) {
  return (num amount, String languageCode, String currencyCode) {
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
  };
});
