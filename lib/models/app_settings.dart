import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель настроек приложения
class AppSettings {
  const AppSettings({
    required this.id,
    required this.key,
    required this.value,
    required this.type,
    this.description,
    this.category,
    this.isPublic = false,
    this.isRequired = false,
    this.defaultValue,
    this.allowedValues,
    this.validation,
    required this.createdAt,
    required this.updatedAt,
    this.updatedBy,
  });

  /// Создать из документа Firestore
  factory AppSettings.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return AppSettings(
      id: doc.id,
      key: (data['key'] as String?) ?? '',
      value: data['value'],
      type: SettingType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => SettingType.string,
      ),
      description: data['description'] as String?,
      category: data['category'] as String?,
      isPublic: (data['isPublic'] as bool?) ?? false,
      isRequired: (data['isRequired'] as bool?) ?? false,
      defaultValue: data['defaultValue'],
      allowedValues: data['allowedValues'] != null
          ? List<String>.from(data['allowedValues'] as Iterable<dynamic>)
          : null,
      validation: data['validation'] != null
          ? Map<String, dynamic>.from(
              data['validation'] as Map<dynamic, dynamic>)
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  /// Создать из Map
  factory AppSettings.fromMap(Map<String, dynamic> data) => AppSettings(
        id: (data['id'] as String?) ?? '',
        key: (data['key'] as String?) ?? '',
        value: data['value'],
        type: SettingType.values.firstWhere(
          (e) => e.toString().split('.').last == data['type'],
          orElse: () => SettingType.string,
        ),
        description: data['description'] as String?,
        category: data['category'] as String?,
        isPublic: (data['isPublic'] as bool?) ?? false,
        isRequired: (data['isRequired'] as bool?) ?? false,
        defaultValue: data['defaultValue'],
        allowedValues: data['allowedValues'] != null
            ? List<String>.from(data['allowedValues'] as Iterable<dynamic>)
            : null,
        validation: data['validation'] != null
            ? Map<String, dynamic>.from(
                data['validation'] as Map<dynamic, dynamic>)
            : null,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        updatedBy: data['updatedBy'] as String?,
      );
  final String id;
  final String key;
  final dynamic value;
  final SettingType type;
  final String? description;
  final String? category;
  final bool isPublic;
  final bool isRequired;
  final dynamic defaultValue;
  final List<String>? allowedValues;
  final Map<String, dynamic>? validation;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? updatedBy;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'key': key,
        'value': value,
        'type': type.toString().split('.').last,
        'description': description,
        'category': category,
        'isPublic': isPublic,
        'isRequired': isRequired,
        'defaultValue': defaultValue,
        'allowedValues': allowedValues,
        'validation': validation,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'updatedBy': updatedBy,
      };

  /// Создать копию с изменениями
  AppSettings copyWith({
    String? id,
    String? key,
    value,
    SettingType? type,
    String? description,
    String? category,
    bool? isPublic,
    bool? isRequired,
    defaultValue,
    List<String>? allowedValues,
    Map<String, dynamic>? validation,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedBy,
  }) =>
      AppSettings(
        id: id ?? this.id,
        key: key ?? this.key,
        value: value ?? this.value,
        type: type ?? this.type,
        description: description ?? this.description,
        category: category ?? this.category,
        isPublic: isPublic ?? this.isPublic,
        isRequired: isRequired ?? this.isRequired,
        defaultValue: defaultValue ?? this.defaultValue,
        allowedValues: allowedValues ?? this.allowedValues,
        validation: validation ?? this.validation,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  /// Получить типизированное значение
  T getTypedValue<T>() {
    switch (type) {
      case SettingType.string:
        return value as T;
      case SettingType.number:
        return (value as num).toDouble() as T;
      case SettingType.boolean:
        return value as T;
      case SettingType.array:
        return value as T;
      case SettingType.object:
        return value as T;
      case SettingType.color:
        return value as T;
      case SettingType.url:
        return value as T;
      case SettingType.email:
        return value as T;
      case SettingType.date:
        return value as T;
      case SettingType.json:
        return value as T;
    }
  }

  /// Проверить валидность значения
  bool isValid() {
    if (isRequired && value == null) return false;

    if (validation != null) {
      return _validateValue();
    }

    return true;
  }

  /// Валидация значения
  bool _validateValue() {
    if (validation == null) return true;

    switch (type) {
      case SettingType.string:
        return _validateString();
      case SettingType.number:
        return _validateNumber();
      case SettingType.email:
        return _validateEmail();
      case SettingType.url:
        return _validateUrl();
      case SettingType.array:
        return _validateArray();
      default:
        return true;
    }
  }

  /// Валидация строки
  bool _validateString() {
    final val = value as String?;
    if (val == null) return !isRequired;

    final minLength = validation?['minLength'] as int?;
    final maxLength = validation?['maxLength'] as int?;
    final pattern = validation?['pattern'] as String?;

    if (minLength != null && val.length < minLength) return false;
    if (maxLength != null && val.length > maxLength) return false;
    if (pattern != null && !RegExp(pattern).hasMatch(val)) return false;

    return true;
  }

  /// Валидация числа
  bool _validateNumber() {
    final val = value as num?;
    if (val == null) return !isRequired;

    final min = validation?['min'] as num?;
    final max = validation?['max'] as num?;

    if (min != null && val < min) return false;
    if (max != null && val > max) return false;

    return true;
  }

  /// Валидация email
  bool _validateEmail() {
    final val = value as String?;
    if (val == null) return !isRequired;

    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val);
  }

  /// Валидация URL
  bool _validateUrl() {
    final val = value as String?;
    if (val == null) return !isRequired;

    try {
      Uri.parse(val);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Валидация массива
  bool _validateArray() {
    final val = value as List?;
    if (val == null) return !isRequired;

    final minItems = validation?['minItems'] as int?;
    final maxItems = validation?['maxItems'] as int?;

    if (minItems != null && val.length < minItems) return false;
    if (maxItems != null && val.length > maxItems) return false;

    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.id == id &&
        other.key == key &&
        other.value == value &&
        other.type == type &&
        other.description == description &&
        other.category == category &&
        other.isPublic == isPublic &&
        other.isRequired == isRequired &&
        other.defaultValue == defaultValue &&
        other.allowedValues == allowedValues &&
        other.validation == validation &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.updatedBy == updatedBy;
  }

  @override
  int get hashCode => Object.hash(
        id,
        key,
        value,
        type,
        description,
        category,
        isPublic,
        isRequired,
        defaultValue,
        allowedValues,
        validation,
        createdAt,
        updatedAt,
        updatedBy,
      );

  @override
  String toString() =>
      'AppSettings(id: $id, key: $key, type: $type, value: $value)';
}

/// Модель конфигурации приложения
class AppConfiguration {
  const AppConfiguration({
    required this.id,
    required this.name,
    required this.description,
    required this.config,
    required this.type,
    this.environment,
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  /// Создать из документа Firestore
  factory AppConfiguration.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return AppConfiguration(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      config: Map<String, dynamic>.from(
          data['config'] as Map<dynamic, dynamic>? ?? {}),
      type: ConfigurationType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => ConfigurationType.general,
      ),
      environment: data['environment'] as String?,
      isActive: (data['isActive'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as String?,
      updatedBy: data['updatedBy'] as String?,
    );
  }

  /// Создать из Map
  factory AppConfiguration.fromMap(Map<String, dynamic> data) =>
      AppConfiguration(
        id: (data['id'] as String?) ?? '',
        name: (data['name'] as String?) ?? '',
        description: (data['description'] as String?) ?? '',
        config: Map<String, dynamic>.from(
            data['config'] as Map<dynamic, dynamic>? ?? {}),
        type: ConfigurationType.values.firstWhere(
          (e) => e.toString().split('.').last == data['type'],
          orElse: () => ConfigurationType.general,
        ),
        environment: data['environment'] as String?,
        isActive: (data['isActive'] as bool?) ?? false,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        createdBy: data['createdBy'] as String?,
        updatedBy: data['updatedBy'] as String?,
      );
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> config;
  final ConfigurationType type;
  final String? environment;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'config': config,
        'type': type.toString().split('.').last,
        'environment': environment,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
      };

  /// Создать копию с изменениями
  AppConfiguration copyWith({
    String? id,
    String? name,
    String? description,
    Map<String, dynamic>? config,
    ConfigurationType? type,
    String? environment,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) =>
      AppConfiguration(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        config: config ?? this.config,
        type: type ?? this.type,
        environment: environment ?? this.environment,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  /// Получить значение конфигурации
  T? getConfigValue<T>(String key) => config[key] as T?;

  /// Установить значение конфигурации
  AppConfiguration setConfigValue(String key, value) {
    final newConfig = Map<String, dynamic>.from(config);
    newConfig[key] = value;
    return copyWith(config: newConfig);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppConfiguration &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.config == config &&
        other.type == type &&
        other.environment == environment &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.createdBy == createdBy &&
        other.updatedBy == updatedBy;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        config,
        type,
        environment,
        isActive,
        createdAt,
        updatedAt,
        createdBy,
        updatedBy,
      );

  @override
  String toString() =>
      'AppConfiguration(id: $id, name: $name, type: $type, isActive: $isActive)';
}

/// Модель истории изменений настроек
class SettingsHistory {
  const SettingsHistory({
    required this.id,
    required this.settingId,
    required this.settingKey,
    required this.oldValue,
    required this.newValue,
    required this.changedBy,
    this.reason,
    required this.changedAt,
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory SettingsHistory.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SettingsHistory(
      id: doc.id,
      settingId: (data['settingId'] as String?) ?? '',
      settingKey: (data['settingKey'] as String?) ?? '',
      oldValue: data['oldValue'],
      newValue: data['newValue'],
      changedBy: (data['changedBy'] as String?) ?? '',
      reason: data['reason'] as String?,
      changedAt: (data['changedAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(
          data['metadata'] as Map<dynamic, dynamic>? ?? {}),
    );
  }

  /// Создать из Map
  factory SettingsHistory.fromMap(Map<String, dynamic> data) => SettingsHistory(
        id: (data['id'] as String?) ?? '',
        settingId: (data['settingId'] as String?) ?? '',
        settingKey: (data['settingKey'] as String?) ?? '',
        oldValue: data['oldValue'],
        newValue: data['newValue'],
        changedBy: (data['changedBy'] as String?) ?? '',
        reason: data['reason'] as String?,
        changedAt: (data['changedAt'] as Timestamp).toDate(),
        metadata: Map<String, dynamic>.from(
            data['metadata'] as Map<dynamic, dynamic>? ?? {}),
      );
  final String id;
  final String settingId;
  final String settingKey;
  final dynamic oldValue;
  final dynamic newValue;
  final String changedBy;
  final String? reason;
  final DateTime changedAt;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'settingId': settingId,
        'settingKey': settingKey,
        'oldValue': oldValue,
        'newValue': newValue,
        'changedBy': changedBy,
        'reason': reason,
        'changedAt': Timestamp.fromDate(changedAt),
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  SettingsHistory copyWith({
    String? id,
    String? settingId,
    String? settingKey,
    oldValue,
    newValue,
    String? changedBy,
    String? reason,
    DateTime? changedAt,
    Map<String, dynamic>? metadata,
  }) =>
      SettingsHistory(
        id: id ?? this.id,
        settingId: settingId ?? this.settingId,
        settingKey: settingKey ?? this.settingKey,
        oldValue: oldValue ?? this.oldValue,
        newValue: newValue ?? this.newValue,
        changedBy: changedBy ?? this.changedBy,
        reason: reason ?? this.reason,
        changedAt: changedAt ?? this.changedAt,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettingsHistory &&
        other.id == id &&
        other.settingId == settingId &&
        other.settingKey == settingKey &&
        other.oldValue == oldValue &&
        other.newValue == newValue &&
        other.changedBy == changedBy &&
        other.reason == reason &&
        other.changedAt == changedAt &&
        other.metadata == metadata;
  }

  @override
  int get hashCode => Object.hash(
        id,
        settingId,
        settingKey,
        oldValue,
        newValue,
        changedBy,
        reason,
        changedAt,
        metadata,
      );

  @override
  String toString() =>
      'SettingsHistory(id: $id, settingKey: $settingKey, changedBy: $changedBy)';
}

/// Типы настроек
enum SettingType {
  string,
  number,
  boolean,
  array,
  object,
  color,
  url,
  email,
  date,
  json
}

/// Расширение для типов настроек
extension SettingTypeExtension on SettingType {
  String get displayName {
    switch (this) {
      case SettingType.string:
        return 'Строка';
      case SettingType.number:
        return 'Число';
      case SettingType.boolean:
        return 'Логическое';
      case SettingType.array:
        return 'Массив';
      case SettingType.object:
        return 'Объект';
      case SettingType.color:
        return 'Цвет';
      case SettingType.url:
        return 'URL';
      case SettingType.email:
        return 'Email';
      case SettingType.date:
        return 'Дата';
      case SettingType.json:
        return 'JSON';
    }
  }

  String get description {
    switch (this) {
      case SettingType.string:
        return 'Текстовое значение';
      case SettingType.number:
        return 'Числовое значение';
      case SettingType.boolean:
        return 'Истина или ложь';
      case SettingType.array:
        return 'Список значений';
      case SettingType.object:
        return 'Структурированные данные';
      case SettingType.color:
        return 'Цвет в формате HEX';
      case SettingType.url:
        return 'Веб-адрес';
      case SettingType.email:
        return 'Адрес электронной почты';
      case SettingType.date:
        return 'Дата и время';
      case SettingType.json:
        return 'JSON данные';
    }
  }

  String get icon {
    switch (this) {
      case SettingType.string:
        return '📝';
      case SettingType.number:
        return '🔢';
      case SettingType.boolean:
        return '✅';
      case SettingType.array:
        return '📋';
      case SettingType.object:
        return '📦';
      case SettingType.color:
        return '🎨';
      case SettingType.url:
        return '🔗';
      case SettingType.email:
        return '📧';
      case SettingType.date:
        return '📅';
      case SettingType.json:
        return '📄';
    }
  }
}

/// Типы конфигураций
enum ConfigurationType {
  general,
  ui,
  api,
  database,
  security,
  notifications,
  payments,
  integrations,
  features,
  environment,
}

/// Расширение для типов конфигураций
extension ConfigurationTypeExtension on ConfigurationType {
  String get displayName {
    switch (this) {
      case ConfigurationType.general:
        return 'Общие';
      case ConfigurationType.ui:
        return 'Интерфейс';
      case ConfigurationType.api:
        return 'API';
      case ConfigurationType.database:
        return 'База данных';
      case ConfigurationType.security:
        return 'Безопасность';
      case ConfigurationType.notifications:
        return 'Уведомления';
      case ConfigurationType.payments:
        return 'Платежи';
      case ConfigurationType.integrations:
        return 'Интеграции';
      case ConfigurationType.features:
        return 'Функции';
      case ConfigurationType.environment:
        return 'Окружение';
    }
  }

  String get description {
    switch (this) {
      case ConfigurationType.general:
        return 'Общие настройки приложения';
      case ConfigurationType.ui:
        return 'Настройки пользовательского интерфейса';
      case ConfigurationType.api:
        return 'Настройки API и внешних сервисов';
      case ConfigurationType.database:
        return 'Настройки базы данных';
      case ConfigurationType.security:
        return 'Настройки безопасности';
      case ConfigurationType.notifications:
        return 'Настройки уведомлений';
      case ConfigurationType.payments:
        return 'Настройки платежных систем';
      case ConfigurationType.integrations:
        return 'Настройки интеграций';
      case ConfigurationType.features:
        return 'Настройки функций приложения';
      case ConfigurationType.environment:
        return 'Настройки окружения';
    }
  }

  String get icon {
    switch (this) {
      case ConfigurationType.general:
        return '⚙️';
      case ConfigurationType.ui:
        return '🎨';
      case ConfigurationType.api:
        return '🔌';
      case ConfigurationType.database:
        return '🗄️';
      case ConfigurationType.security:
        return '🔒';
      case ConfigurationType.notifications:
        return '🔔';
      case ConfigurationType.payments:
        return '💳';
      case ConfigurationType.integrations:
        return '🔗';
      case ConfigurationType.features:
        return '⭐';
      case ConfigurationType.environment:
        return '🌍';
    }
  }
}
