import 'package:flutter/material.dart';

/// Модель локализации
class LocalizationModel {
  const LocalizationModel({
    required this.languageCode,
    required this.countryCode,
    required this.displayName,
    required this.nativeName,
    required this.locale,
    required this.translations,
  });
  final String languageCode;
  final String countryCode;
  final String displayName;
  final String nativeName;
  final Locale locale;
  final Map<String, String> translations;

  /// Получить перевод по ключу
  String translate(String key, {Map<String, dynamic>? params}) {
    var translation = translations[key] ?? key;

    if (params != null) {
      params.forEach((key, value) {
        translation = translation.replaceAll('{$key}', value.toString());
      });
    }

    return translation;
  }

  /// Проверить наличие перевода
  bool hasTranslation(String key) => translations.containsKey(key);

  /// Получить все доступные ключи
  List<String> get availableKeys => translations.keys.toList();
}

/// Поддерживаемые языки
enum SupportedLanguage {
  russian('ru', 'RU', 'Русский', 'Русский'),
  english('en', 'US', 'English', 'English'),
  spanish('es', 'ES', 'Español', 'Español'),
  french('fr', 'FR', 'Français', 'Français'),
  german('de', 'DE', 'Deutsch', 'Deutsch'),
  chinese('zh', 'CN', '中文', '中文'),
  japanese('ja', 'JP', '日本語', '日本語'),
  korean('ko', 'KR', '한국어', '한국어'),
  arabic('ar', 'SA', 'العربية', 'العربية'),
  portuguese('pt', 'BR', 'Português', 'Português');

  const SupportedLanguage(
    this.languageCode,
    this.countryCode,
    this.displayName,
    this.nativeName,
  );

  final String languageCode;
  final String countryCode;
  final String displayName;
  final String nativeName;

  Locale get locale => Locale(languageCode, countryCode);
}

/// Модель настроек локализации
class LocalizationSettings {
  const LocalizationSettings({
    required this.currentLanguage,
    this.autoDetectLanguage = true,
    this.showNativeNames = false,
    this.preferredLanguages = const [],
    required this.lastUpdated,
  });

  factory LocalizationSettings.fromMap(Map<String, dynamic> map) =>
      LocalizationSettings(
        currentLanguage: map['currentLanguage'] ?? 'ru',
        autoDetectLanguage: map['autoDetectLanguage'] ?? true,
        showNativeNames: map['showNativeNames'] ?? false,
        preferredLanguages: List<String>.from(map['preferredLanguages'] ?? []),
        lastUpdated:
            DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] ?? 0),
      );
  final String currentLanguage;
  final bool autoDetectLanguage;
  final bool showNativeNames;
  final List<String> preferredLanguages;
  final DateTime lastUpdated;

  LocalizationSettings copyWith({
    String? currentLanguage,
    bool? autoDetectLanguage,
    bool? showNativeNames,
    List<String>? preferredLanguages,
    DateTime? lastUpdated,
  }) =>
      LocalizationSettings(
        currentLanguage: currentLanguage ?? this.currentLanguage,
        autoDetectLanguage: autoDetectLanguage ?? this.autoDetectLanguage,
        showNativeNames: showNativeNames ?? this.showNativeNames,
        preferredLanguages: preferredLanguages ?? this.preferredLanguages,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );

  Map<String, dynamic> toMap() => {
        'currentLanguage': currentLanguage,
        'autoDetectLanguage': autoDetectLanguage,
        'showNativeNames': showNativeNames,
        'preferredLanguages': preferredLanguages,
        'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      };
}

/// Модель перевода
class Translation {
  const Translation({
    required this.key,
    required this.value,
    required this.language,
    this.context,
    this.description,
    this.isPlural = false,
    this.pluralForms,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Translation.fromMap(Map<String, dynamic> map) => Translation(
        key: map['key'] ?? '',
        value: map['value'] ?? '',
        language: map['language'] ?? '',
        context: map['context'],
        description: map['description'],
        isPlural: map['isPlural'] ?? false,
        pluralForms: map['pluralForms'] != null
            ? Map<String, String>.from(map['pluralForms'])
            : null,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      );
  final String key;
  final String value;
  final String language;
  final String? context;
  final String? description;
  final bool isPlural;
  final Map<String, String>? pluralForms;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'key': key,
        'value': value,
        'language': language,
        'context': context,
        'description': description,
        'isPlural': isPlural,
        'pluralForms': pluralForms,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  Translation copyWith({
    String? key,
    String? value,
    String? language,
    String? context,
    String? description,
    bool? isPlural,
    Map<String, String>? pluralForms,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Translation(
        key: key ?? this.key,
        value: value ?? this.value,
        language: language ?? this.language,
        context: context ?? this.context,
        description: description ?? this.description,
        isPlural: isPlural ?? this.isPlural,
        pluralForms: pluralForms ?? this.pluralForms,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Модель статистики локализации
class LocalizationStats {
  const LocalizationStats({
    required this.language,
    required this.totalKeys,
    required this.translatedKeys,
    required this.missingKeys,
    required this.completionPercentage,
    required this.lastUpdated,
  });

  factory LocalizationStats.fromMap(Map<String, dynamic> map) =>
      LocalizationStats(
        language: map['language'] ?? '',
        totalKeys: map['totalKeys'] ?? 0,
        translatedKeys: map['translatedKeys'] ?? 0,
        missingKeys: map['missingKeys'] ?? 0,
        completionPercentage: map['completionPercentage']?.toDouble() ?? 0.0,
        lastUpdated:
            DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] ?? 0),
      );
  final String language;
  final int totalKeys;
  final int translatedKeys;
  final int missingKeys;
  final double completionPercentage;
  final DateTime lastUpdated;

  Map<String, dynamic> toMap() => {
        'language': language,
        'totalKeys': totalKeys,
        'translatedKeys': translatedKeys,
        'missingKeys': missingKeys,
        'completionPercentage': completionPercentage,
        'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      };
}

/// Модель контекста перевода
class TranslationContext {
  const TranslationContext({
    required this.name,
    required this.description,
    required this.keys,
    this.category,
  });

  factory TranslationContext.fromMap(Map<String, dynamic> map) =>
      TranslationContext(
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        keys: List<String>.from(map['keys'] ?? []),
        category: map['category'],
      );
  final String name;
  final String description;
  final List<String> keys;
  final String? category;

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'keys': keys,
        'category': category,
      };
}
