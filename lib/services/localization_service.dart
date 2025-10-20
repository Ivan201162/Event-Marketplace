import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/localization.dart';

/// Сервис локализации
class LocalizationService {
  factory LocalizationService() => _instance;
  LocalizationService._internal();
  static final LocalizationService _instance = LocalizationService._internal();

  static const String _settingsKey = 'localization_settings';
  static const String _currentLanguageKey = 'current_language';

  LocalizationSettings? _settings;
  LocalizationModel? _currentLocalization;
  final Map<String, LocalizationModel> _localizations = {};

  /// Инициализация сервиса
  Future<void> initialize() async {
    await _loadSettings();
    await _loadLocalizations();
    await _setCurrentLanguage(_settings?.currentLanguage ?? 'ru');
  }

  /// Получить текущие настройки локализации
  LocalizationSettings? get settings => _settings;

  /// Получить текущую локализацию
  LocalizationModel? get currentLocalization => _currentLocalization;

  /// Получить текущий язык
  String get currentLanguage => _settings?.currentLanguage ?? 'ru';

  /// Получить текущую локаль
  Locale get currentLocale {
    final language = SupportedLanguage.values.firstWhere(
      (lang) => lang.languageCode == currentLanguage,
      orElse: () => SupportedLanguage.russian,
    );
    return language.locale;
  }

  /// Получить все доступные локализации
  List<LocalizationModel> get availableLocalizations => _localizations.values.toList();

  /// Получить все поддерживаемые языки
  List<SupportedLanguage> get supportedLanguages => SupportedLanguage.values;

  /// Загрузить настройки
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _settings = LocalizationSettings.fromMap(settingsMap);
      } else {
        _settings = LocalizationSettings(
          currentLanguage: 'ru',
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('Ошибка загрузки настроек локализации: $e');
      _settings = LocalizationSettings(
        currentLanguage: 'ru',
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Сохранить настройки
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(_settings!.toMap());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      debugPrint('Ошибка сохранения настроек локализации: $e');
    }
  }

  /// Загрузить локализации
  Future<void> _loadLocalizations() async {
    try {
      // Загружаем русскую локализацию
      _localizations['ru'] = await _loadLocalization('ru');

      // Загружаем английскую локализацию
      _localizations['en'] = await _loadLocalization('en');

      // Загружаем другие языки по мере необходимости
      for (final language in SupportedLanguage.values) {
        if (!_localizations.containsKey(language.languageCode)) {
          _localizations[language.languageCode] = await _loadLocalization(language.languageCode);
        }
      }
    } catch (e) {
      debugPrint('Ошибка загрузки локализаций: $e');
    }
  }

  /// Загрузить конкретную локализацию
  Future<LocalizationModel> _loadLocalization(String languageCode) async {
    try {
      final language = SupportedLanguage.values.firstWhere(
        (lang) => lang.languageCode == languageCode,
        orElse: () => SupportedLanguage.russian,
      );

      // Загружаем переводы из JSON файлов
      final translations = await _loadTranslations(languageCode);

      return LocalizationModel(
        languageCode: language.languageCode,
        countryCode: language.countryCode,
        displayName: language.displayName,
        nativeName: language.nativeName,
        locale: language.locale,
        translations: translations,
      );
    } catch (e) {
      debugPrint('Ошибка загрузки локализации $languageCode: $e');
      return _getDefaultLocalization(languageCode);
    }
  }

  /// Загрузить переводы из JSON
  Future<Map<String, String>> _loadTranslations(String languageCode) async {
    try {
      // В реальном приложении здесь будет загрузка из файлов
      // Пока используем встроенные переводы
      return _getBuiltInTranslations(languageCode);
    } catch (e) {
      debugPrint('Ошибка загрузки переводов для $languageCode: $e');
      return {};
    }
  }

  /// Получить встроенные переводы
  Map<String, String> _getBuiltInTranslations(String languageCode) {
    switch (languageCode) {
      case 'ru':
        return _getRussianTranslations();
      case 'en':
        return _getEnglishTranslations();
      case 'es':
        return _getSpanishTranslations();
      case 'fr':
        return _getFrenchTranslations();
      case 'de':
        return _getGermanTranslations();
      default:
        return _getRussianTranslations();
    }
  }

  /// Русские переводы
  Map<String, String> _getRussianTranslations() => {
        // Общие
        'app_name': 'Event Marketplace',
        'loading': 'Загрузка...',
        'error': 'Ошибка',
        'success': 'Успешно',
        'cancel': 'Отмена',
        'save': 'Сохранить',
        'delete': 'Удалить',
        'edit': 'Редактировать',
        'add': 'Добавить',
        'search': 'Поиск',
        'filter': 'Фильтр',
        'sort': 'Сортировка',
        'refresh': 'Обновить',
        'back': 'Назад',
        'next': 'Далее',
        'previous': 'Назад',
        'done': 'Готово',
        'close': 'Закрыть',
        'yes': 'Да',
        'no': 'Нет',
        'ok': 'ОК',

        // Навигация
        'home': 'Главная',
        'events': 'События',
        'profile': 'Профиль',
        'settings': 'Настройки',
        'notifications': 'Уведомления',
        'messages': 'Сообщения',
        'bookings': 'Бронирования',
        'reviews': 'Отзывы',
        'analytics': 'Аналитика',
        'support': 'Поддержка',
        'integrations': 'Интеграции',

        // События
        'create_event': 'Создать событие',
        'event_title': 'Название события',
        'event_description': 'Описание события',
        'event_date': 'Дата события',
        'event_time': 'Время события',
        'event_location': 'Место проведения',
        'event_price': 'Цена',
        'event_category': 'Категория',
        'event_image': 'Изображение события',

        // Профиль
        'profile_name': 'Имя',
        'profile_email': 'Email',
        'profile_phone': 'Телефон',
        'profile_bio': 'О себе',
        'profile_photo': 'Фото профиля',
        'profile_rating': 'Рейтинг',
        'profile_reviews': 'Отзывы',
        'profile_events': 'События',
        'profile_bookings': 'Бронирования',

        // Настройки
        'language': 'Язык',
        'theme': 'Тема',
        'notifications_settings': 'Настройки уведомлений',
        'privacy_settings': 'Настройки приватности',
        'account_settings': 'Настройки аккаунта',
        'about': 'О приложении',
        'version': 'Версия',
        'logout': 'Выйти',

        // Уведомления
        'push_notifications': 'Push уведомления',
        'email_notifications': 'Email уведомления',
        'sms_notifications': 'SMS уведомления',
        'notification_sound': 'Звук уведомлений',
        'notification_vibration': 'Вибрация',

        // Ошибки
        'error_network': 'Ошибка сети',
        'error_server': 'Ошибка сервера',
        'error_unknown': 'Неизвестная ошибка',
        'error_permission': 'Нет разрешения',
        'error_location': 'Ошибка определения местоположения',
        'error_camera': 'Ошибка камеры',
        'error_gallery': 'Ошибка галереи',

        // Успех
        'success_saved': 'Сохранено',
        'success_deleted': 'Удалено',
        'success_updated': 'Обновлено',
        'success_created': 'Создано',
        'success_sent': 'Отправлено',
      };

  /// Английские переводы
  Map<String, String> _getEnglishTranslations() => {
        // Общие
        'app_name': 'Event Marketplace',
        'loading': 'Loading...',
        'error': 'Error',
        'success': 'Success',
        'cancel': 'Cancel',
        'save': 'Save',
        'delete': 'Delete',
        'edit': 'Edit',
        'add': 'Add',
        'search': 'Search',
        'filter': 'Filter',
        'sort': 'Sort',
        'refresh': 'Refresh',
        'back': 'Back',
        'next': 'Next',
        'previous': 'Previous',
        'done': 'Done',
        'close': 'Close',
        'yes': 'Yes',
        'no': 'No',
        'ok': 'OK',

        // Навигация
        'home': 'Home',
        'events': 'Events',
        'profile': 'Profile',
        'settings': 'Settings',
        'notifications': 'Notifications',
        'messages': 'Messages',
        'bookings': 'Bookings',
        'reviews': 'Reviews',
        'analytics': 'Analytics',
        'support': 'Support',
        'integrations': 'Integrations',

        // События
        'create_event': 'Create Event',
        'event_title': 'Event Title',
        'event_description': 'Event Description',
        'event_date': 'Event Date',
        'event_time': 'Event Time',
        'event_location': 'Event Location',
        'event_price': 'Price',
        'event_category': 'Category',
        'event_image': 'Event Image',

        // Профиль
        'profile_name': 'Name',
        'profile_email': 'Email',
        'profile_phone': 'Phone',
        'profile_bio': 'Bio',
        'profile_photo': 'Profile Photo',
        'profile_rating': 'Rating',
        'profile_reviews': 'Reviews',
        'profile_events': 'Events',
        'profile_bookings': 'Bookings',

        // Настройки
        'language': 'Language',
        'theme': 'Theme',
        'notifications_settings': 'Notification Settings',
        'privacy_settings': 'Privacy Settings',
        'account_settings': 'Account Settings',
        'about': 'About',
        'version': 'Version',
        'logout': 'Logout',

        // Уведомления
        'push_notifications': 'Push Notifications',
        'email_notifications': 'Email Notifications',
        'sms_notifications': 'SMS Notifications',
        'notification_sound': 'Notification Sound',
        'notification_vibration': 'Vibration',

        // Ошибки
        'error_network': 'Network Error',
        'error_server': 'Server Error',
        'error_unknown': 'Unknown Error',
        'error_permission': 'Permission Denied',
        'error_location': 'Location Error',
        'error_camera': 'Camera Error',
        'error_gallery': 'Gallery Error',

        // Успех
        'success_saved': 'Saved',
        'success_deleted': 'Deleted',
        'success_updated': 'Updated',
        'success_created': 'Created',
        'success_sent': 'Sent',
      };

  /// Испанские переводы
  Map<String, String> _getSpanishTranslations() => {
        'app_name': 'Event Marketplace',
        'loading': 'Cargando...',
        'error': 'Error',
        'success': 'Éxito',
        'cancel': 'Cancelar',
        'save': 'Guardar',
        'delete': 'Eliminar',
        'edit': 'Editar',
        'add': 'Agregar',
        'search': 'Buscar',
        'filter': 'Filtrar',
        'sort': 'Ordenar',
        'refresh': 'Actualizar',
        'back': 'Atrás',
        'next': 'Siguiente',
        'previous': 'Anterior',
        'done': 'Hecho',
        'close': 'Cerrar',
        'yes': 'Sí',
        'no': 'No',
        'ok': 'OK',
      };

  /// Французские переводы
  Map<String, String> _getFrenchTranslations() => {
        'app_name': 'Event Marketplace',
        'loading': 'Chargement...',
        'error': 'Erreur',
        'success': 'Succès',
        'cancel': 'Annuler',
        'save': 'Enregistrer',
        'delete': 'Supprimer',
        'edit': 'Modifier',
        'add': 'Ajouter',
        'search': 'Rechercher',
        'filter': 'Filtrer',
        'sort': 'Trier',
        'refresh': 'Actualiser',
        'back': 'Retour',
        'next': 'Suivant',
        'previous': 'Précédent',
        'done': 'Terminé',
        'close': 'Fermer',
        'yes': 'Oui',
        'no': 'Non',
        'ok': 'OK',
      };

  /// Немецкие переводы
  Map<String, String> _getGermanTranslations() => {
        'app_name': 'Event Marketplace',
        'loading': 'Laden...',
        'error': 'Fehler',
        'success': 'Erfolg',
        'cancel': 'Abbrechen',
        'save': 'Speichern',
        'delete': 'Löschen',
        'edit': 'Bearbeiten',
        'add': 'Hinzufügen',
        'search': 'Suchen',
        'filter': 'Filtern',
        'sort': 'Sortieren',
        'refresh': 'Aktualisieren',
        'back': 'Zurück',
        'next': 'Weiter',
        'previous': 'Vorherige',
        'done': 'Fertig',
        'close': 'Schließen',
        'yes': 'Ja',
        'no': 'Nein',
        'ok': 'OK',
      };

  /// Получить локализацию по умолчанию
  LocalizationModel _getDefaultLocalization(String languageCode) {
    final language = SupportedLanguage.values.firstWhere(
      (lang) => lang.languageCode == languageCode,
      orElse: () => SupportedLanguage.russian,
    );

    return LocalizationModel(
      languageCode: language.languageCode,
      countryCode: language.countryCode,
      displayName: language.displayName,
      nativeName: language.nativeName,
      locale: language.locale,
      translations: _getRussianTranslations(), // Fallback to Russian
    );
  }

  /// Установить текущий язык
  Future<void> setLanguage(String languageCode) async {
    try {
      await _setCurrentLanguage(languageCode);
      _settings = _settings?.copyWith(
        currentLanguage: languageCode,
        lastUpdated: DateTime.now(),
      );
      await _saveSettings();
    } catch (e) {
      debugPrint('Ошибка установки языка: $e');
    }
  }

  /// Установить текущий язык (внутренний метод)
  Future<void> _setCurrentLanguage(String languageCode) async {
    if (_localizations.containsKey(languageCode)) {
      _currentLocalization = _localizations[languageCode];
    } else {
      _currentLocalization = await _loadLocalization(languageCode);
      _localizations[languageCode] = _currentLocalization!;
    }
  }

  /// Получить перевод
  String translate(String key, {Map<String, dynamic>? params}) {
    if (_currentLocalization != null) {
      return _currentLocalization!.translate(key, params: params);
    }
    return key;
  }

  /// Проверить наличие перевода
  bool hasTranslation(String key) => _currentLocalization?.hasTranslation(key) ?? false;

  /// Обновить настройки локализации
  Future<void> updateSettings(LocalizationSettings newSettings) async {
    try {
      _settings = newSettings;
      await _saveSettings();
      await setLanguage(newSettings.currentLanguage);
    } catch (e) {
      debugPrint('Ошибка обновления настроек локализации: $e');
    }
  }

  /// Получить статистику локализации
  Future<LocalizationStats> getLocalizationStats(String languageCode) async {
    try {
      final localization = _localizations[languageCode];
      if (localization == null) {
        return LocalizationStats(
          language: languageCode,
          totalKeys: 0,
          translatedKeys: 0,
          missingKeys: 0,
          completionPercentage: 0,
          lastUpdated: DateTime.now(),
        );
      }

      final totalKeys = localization.translations.length;
      final translatedKeys =
          localization.translations.values.where((value) => value.isNotEmpty).length;
      final missingKeys = totalKeys - translatedKeys;
      final completionPercentage = totalKeys > 0 ? (translatedKeys / totalKeys) * 100 : 0.0;

      return LocalizationStats(
        language: languageCode,
        totalKeys: totalKeys,
        translatedKeys: translatedKeys,
        missingKeys: missingKeys,
        completionPercentage: completionPercentage,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Ошибка получения статистики локализации: $e');
      return LocalizationStats(
        language: languageCode,
        totalKeys: 0,
        translatedKeys: 0,
        missingKeys: 0,
        completionPercentage: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Получить все статистики локализации
  Future<List<LocalizationStats>> getAllLocalizationStats() async {
    final stats = <LocalizationStats>[];

    for (final languageCode in _localizations.keys) {
      final stat = await getLocalizationStats(languageCode);
      stats.add(stat);
    }

    return stats;
  }

  /// Очистить кэш локализации
  Future<void> clearCache() async {
    try {
      _localizations.clear();
      await _loadLocalizations();
    } catch (e) {
      debugPrint('Ошибка очистки кэша локализации: $e');
    }
  }

  /// Экспортировать переводы
  Future<Map<String, dynamic>> exportTranslations(String languageCode) async {
    try {
      final localization = _localizations[languageCode];
      if (localization == null) {
        return {};
      }

      return {
        'language': languageCode,
        'translations': localization.translations,
        'exported_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Ошибка экспорта переводов: $e');
      return {};
    }
  }

  /// Импортировать переводы
  Future<void> importTranslations(
    String languageCode,
    Map<String, String> translations,
  ) async {
    try {
      final language = SupportedLanguage.values.firstWhere(
        (lang) => lang.languageCode == languageCode,
        orElse: () => SupportedLanguage.russian,
      );

      final localization = LocalizationModel(
        languageCode: language.languageCode,
        countryCode: language.countryCode,
        displayName: language.displayName,
        nativeName: language.nativeName,
        locale: language.locale,
        translations: translations,
      );

      _localizations[languageCode] = localization;

      if (languageCode == currentLanguage) {
        _currentLocalization = localization;
      }
    } catch (e) {
      debugPrint('Ошибка импорта переводов: $e');
    }
  }
}
