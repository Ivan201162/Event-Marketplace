import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/app_settings.dart';

/// Сервис управления настройками и конфигурацией
class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final Map<String, AppSettings> _settingsCache = {};
  final Map<String, AppConfiguration> _configurationsCache = {};
  SharedPreferences? _prefs;

  /// Инициализация сервиса
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettingsCache();
      await _loadConfigurationsCache();
      await _loadLocalSettings();

      if (kDebugMode) {
        print('Settings service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка инициализации сервиса настроек: $e');
      }
    }
  }

  /// Получить настройку по ключу
  Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    try {
      // Сначала проверяем локальный кэш
      final cachedSetting = _settingsCache[key];
      if (cachedSetting != null) {
        return cachedSetting.getTypedValue<T>();
      }

      // Загружаем из Firestore
      final doc = await _firestore.collection('appSettings').doc(key).get();
      if (doc.exists) {
        final setting = AppSettings.fromDocument(doc);
        _settingsCache[key] = setting;
        return setting.getTypedValue<T>();
      }

      // Возвращаем значение по умолчанию
      return defaultValue;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения настройки $key: $e');
      }
      return defaultValue;
    }
  }

  /// Установить настройку
  Future<void> setSetting<T>(
    String key,
    T value, {
    SettingType? type,
    String? description,
    String? category,
    bool isPublic = false,
    bool isRequired = false,
    Map<String, dynamic>? validation,
    String? updatedBy,
  }) async {
    try {
      final now = DateTime.now();
      final settingType = type ?? _inferType(value);

      // Получаем старую настройку для истории
      final oldSetting = _settingsCache[key];
      final oldValue = oldSetting?.value;

      final setting = AppSettings(
        id: key,
        key: key,
        value: value,
        type: settingType,
        description: description,
        category: category,
        isPublic: isPublic,
        isRequired: isRequired,
        validation: validation,
        updatedBy: updatedBy,
        createdAt: oldSetting?.createdAt ?? now,
        updatedAt: now,
      );

      // Валидируем настройку
      if (!setting.isValid()) {
        throw Exception('Некорректное значение настройки $key');
      }

      // Сохраняем в Firestore
      await _firestore.collection('appSettings').doc(key).set(setting.toMap());
      _settingsCache[key] = setting;

      // Сохраняем локально
      await _saveLocalSetting(key, value);

      // Логируем изменение
      if (oldValue != value) {
        await _logSettingChange(
          settingId: key,
          settingKey: key,
          oldValue: oldValue,
          newValue: value,
          changedBy: updatedBy ?? 'system',
        );
      }

      if (kDebugMode) {
        print('Setting updated: $key = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка установки настройки $key: $e');
      }
      rethrow;
    }
  }

  /// Удалить настройку
  Future<void> removeSetting(String key, {String? removedBy}) async {
    try {
      // Получаем старую настройку для истории
      final oldSetting = _settingsCache[key];
      final oldValue = oldSetting?.value;

      // Удаляем из Firestore
      await _firestore.collection('appSettings').doc(key).delete();
      _settingsCache.remove(key);

      // Удаляем локально
      await _removeLocalSetting(key);

      // Логируем изменение
      if (oldSetting != null) {
        await _logSettingChange(
          settingId: key,
          settingKey: key,
          oldValue: oldValue,
          newValue: null,
          changedBy: removedBy ?? 'system',
          reason: 'Setting removed',
        );
      }

      if (kDebugMode) {
        print('Setting removed: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка удаления настройки $key: $e');
      }
      rethrow;
    }
  }

  /// Получить настройки по категории
  Future<List<AppSettings>> getSettingsByCategory(String category) async {
    try {
      final settings = _settingsCache.values
          .where((setting) => setting.category == category)
          .toList();

      if (settings.isEmpty) {
        // Загружаем из Firestore
        final snapshot = await _firestore
            .collection('appSettings')
            .where('category', isEqualTo: category)
            .get();

        for (final doc in snapshot.docs) {
          final setting = AppSettings.fromDocument(doc);
          _settingsCache[setting.key] = setting;
        }

        return _settingsCache.values
            .where((setting) => setting.category == category)
            .toList();
      }

      return settings;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения настроек по категории $category: $e');
      }
      return [];
    }
  }

  /// Получить публичные настройки
  Future<List<AppSettings>> getPublicSettings() async {
    try {
      final settings =
          _settingsCache.values.where((setting) => setting.isPublic).toList();

      if (settings.isEmpty) {
        // Загружаем из Firestore
        final snapshot = await _firestore
            .collection('appSettings')
            .where('isPublic', isEqualTo: true)
            .get();

        for (final doc in snapshot.docs) {
          final setting = AppSettings.fromDocument(doc);
          _settingsCache[setting.key] = setting;
        }

        return _settingsCache.values
            .where((setting) => setting.isPublic)
            .toList();
      }

      return settings;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения публичных настроек: $e');
      }
      return [];
    }
  }

  /// Создать конфигурацию
  Future<String> createConfiguration({
    required String name,
    required String description,
    required Map<String, dynamic> config,
    required ConfigurationType type,
    String? environment,
    String? createdBy,
  }) async {
    try {
      final configId = _uuid.v4();
      final now = DateTime.now();

      final configuration = AppConfiguration(
        id: configId,
        name: name,
        description: description,
        config: config,
        type: type,
        environment: environment,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('appConfigurations')
          .doc(configId)
          .set(configuration.toMap());
      _configurationsCache[configId] = configuration;

      if (kDebugMode) {
        print('Configuration created: $name');
      }

      return configId;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка создания конфигурации: $e');
      }
      rethrow;
    }
  }

  /// Активировать конфигурацию
  Future<void> activateConfiguration(String configId,
      {String? activatedBy}) async {
    try {
      // Деактивируем все конфигурации того же типа
      final configuration = _configurationsCache[configId];
      if (configuration == null) {
        throw Exception('Конфигурация не найдена');
      }

      final sameTypeConfigs = _configurationsCache.values
          .where(
              (config) => config.type == configuration.type && config.isActive)
          .toList();

      for (final config in sameTypeConfigs) {
        await _firestore.collection('appConfigurations').doc(config.id).update({
          'isActive': false,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'updatedBy': activatedBy,
        });

        _configurationsCache[config.id] = config.copyWith(
          isActive: false,
          updatedAt: DateTime.now(),
          updatedBy: activatedBy,
        );
      }

      // Активируем выбранную конфигурацию
      await _firestore.collection('appConfigurations').doc(configId).update({
        'isActive': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedBy': activatedBy,
      });

      _configurationsCache[configId] = configuration.copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
        updatedBy: activatedBy,
      );

      if (kDebugMode) {
        print('Configuration activated: $configId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка активации конфигурации: $e');
      }
      rethrow;
    }
  }

  /// Получить активную конфигурацию по типу
  AppConfiguration? getActiveConfiguration(ConfigurationType type) {
    return _configurationsCache.values
        .where((config) => config.type == type && config.isActive)
        .firstOrNull;
  }

  /// Получить конфигурации по типу
  List<AppConfiguration> getConfigurationsByType(ConfigurationType type) {
    return _configurationsCache.values
        .where((config) => config.type == type)
        .toList();
  }

  /// Получить историю изменений настроек
  Future<List<SettingsHistory>> getSettingsHistory(String settingKey,
      {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('settingsHistory')
          .where('settingKey', isEqualTo: settingKey)
          .orderBy('changedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => SettingsHistory.fromDocument(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения истории настроек: $e');
      }
      return [];
    }
  }

  /// Экспортировать настройки
  Future<Map<String, dynamic>> exportSettings({String? category}) async {
    try {
      final settings = category != null
          ? await getSettingsByCategory(category)
          : _settingsCache.values.toList();

      final export = <String, dynamic>{};
      for (final setting in settings) {
        export[setting.key] = {
          'value': setting.value,
          'type': setting.type.toString().split('.').last,
          'description': setting.description,
          'category': setting.category,
          'isPublic': setting.isPublic,
          'isRequired': setting.isRequired,
          'defaultValue': setting.defaultValue,
          'validation': setting.validation,
        };
      }

      return export;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка экспорта настроек: $e');
      }
      return {};
    }
  }

  /// Импортировать настройки
  Future<void> importSettings(
    Map<String, dynamic> settings, {
    String? importedBy,
    bool overwrite = false,
  }) async {
    try {
      for (final entry in settings.entries) {
        final key = entry.key;
        final data = entry.value as Map<String, dynamic>;

        if (!overwrite && _settingsCache.containsKey(key)) {
          continue; // Пропускаем существующие настройки
        }

        final settingType = SettingType.values.firstWhere(
            (e) => e.toString().split('.').last == data['type'],
            orElse: () => SettingType.string);

        await setSetting(
          key,
          data['value'],
          type: settingType,
          description: data['description'],
          category: data['category'],
          isPublic: data['isPublic'] ?? false,
          isRequired: data['isRequired'] ?? false,
          validation: data['validation'],
          updatedBy: importedBy,
        );
      }

      if (kDebugMode) {
        print('Settings imported: ${settings.length} settings');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка импорта настроек: $e');
      }
      rethrow;
    }
  }

  /// Сбросить настройки к значениям по умолчанию
  Future<void> resetToDefaults({String? resetBy}) async {
    try {
      for (final setting in _settingsCache.values) {
        if (setting.defaultValue != null) {
          await setSetting(
            setting.key,
            setting.defaultValue,
            type: setting.type,
            description: setting.description,
            category: setting.category,
            isPublic: setting.isPublic,
            isRequired: setting.isRequired,
            validation: setting.validation,
            updatedBy: resetBy,
          );
        }
      }

      if (kDebugMode) {
        print('Settings reset to defaults');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка сброса настроек: $e');
      }
      rethrow;
    }
  }

  /// Определить тип значения
  SettingType _inferType(dynamic value) {
    if (value is String) {
      if (RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$').hasMatch(value)) {
        return SettingType.color;
      }
      if (RegExp(r'^https?://').hasMatch(value)) {
        return SettingType.url;
      }
      if (RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
        return SettingType.email;
      }
      return SettingType.string;
    }
    if (value is num) return SettingType.number;
    if (value is bool) return SettingType.boolean;
    if (value is List) return SettingType.array;
    if (value is Map) return SettingType.object;
    if (value is DateTime) return SettingType.date;
    return SettingType.string;
  }

  /// Сохранить настройку локально
  Future<void> _saveLocalSetting(String key, dynamic value) async {
    try {
      if (_prefs == null) return;

      if (value is String) {
        await _prefs!.setString('setting_$key', value);
      } else if (value is int) {
        await _prefs!.setInt('setting_$key', value);
      } else if (value is double) {
        await _prefs!.setDouble('setting_$key', value);
      } else if (value is bool) {
        await _prefs!.setBool('setting_$key', value);
      } else if (value is List) {
        await _prefs!.setStringList('setting_$key', value.cast<String>());
      } else {
        await _prefs!.setString('setting_$key', json.encode(value));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка сохранения локальной настройки: $e');
      }
    }
  }

  /// Удалить локальную настройку
  Future<void> _removeLocalSetting(String key) async {
    try {
      if (_prefs == null) return;
      await _prefs!.remove('setting_$key');
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка удаления локальной настройки: $e');
      }
    }
  }

  /// Загрузить локальные настройки
  Future<void> _loadLocalSettings() async {
    try {
      if (_prefs == null) return;

      final keys = _prefs!.getKeys().where((key) => key.startsWith('setting_'));
      for (final key in keys) {
        final settingKey = key.substring(8); // Убираем префикс 'setting_'
        final value = _prefs!.get(key);

        if (value != null && !_settingsCache.containsKey(settingKey)) {
          // Создаем временную настройку для локального значения
          final setting = AppSettings(
            id: settingKey,
            key: settingKey,
            value: value,
            type: _inferType(value),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          _settingsCache[settingKey] = setting;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки локальных настроек: $e');
      }
    }
  }

  /// Логировать изменение настройки
  Future<void> _logSettingChange({
    required String settingId,
    required String settingKey,
    required dynamic oldValue,
    required dynamic newValue,
    required String changedBy,
    String? reason,
  }) async {
    try {
      final historyId = _uuid.v4();
      final history = SettingsHistory(
        id: historyId,
        settingId: settingId,
        settingKey: settingKey,
        oldValue: oldValue,
        newValue: newValue,
        changedBy: changedBy,
        reason: reason,
        changedAt: DateTime.now(),
      );

      await _firestore
          .collection('settingsHistory')
          .doc(historyId)
          .set(history.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка логирования изменения настройки: $e');
      }
    }
  }

  /// Загрузить кэш настроек
  Future<void> _loadSettingsCache() async {
    try {
      final snapshot =
          await _firestore.collection('appSettings').limit(1000).get();

      for (final doc in snapshot.docs) {
        final setting = AppSettings.fromDocument(doc);
        _settingsCache[setting.key] = setting;
      }

      if (kDebugMode) {
        print('Loaded ${_settingsCache.length} settings');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки кэша настроек: $e');
      }
    }
  }

  /// Загрузить кэш конфигураций
  Future<void> _loadConfigurationsCache() async {
    try {
      final snapshot = await _firestore.collection('appConfigurations').get();

      for (final doc in snapshot.docs) {
        final configuration = AppConfiguration.fromDocument(doc);
        _configurationsCache[configuration.id] = configuration;
      }

      if (kDebugMode) {
        print('Loaded ${_configurationsCache.length} configurations');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки кэша конфигураций: $e');
      }
    }
  }

  /// Получить все настройки
  List<AppSettings> getAllSettings() {
    return _settingsCache.values.toList();
  }

  /// Получить все конфигурации
  List<AppConfiguration> getAllConfigurations() {
    return _configurationsCache.values.toList();
  }

  /// Закрыть сервис
  void dispose() {
    _settingsCache.clear();
    _configurationsCache.clear();
  }
}
