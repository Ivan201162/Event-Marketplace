import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель для конфигурации окружения
class EnvironmentConfig {
  const EnvironmentConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.config,
    required this.secrets,
    required this.featureFlags,
    required this.apiEndpoints,
    required this.databaseConfig,
    required this.cacheConfig,
    required this.loggingConfig,
    required this.monitoringConfig,
    required this.securityConfig,
    required this.isActive,
    this.description,
    required this.tags,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory EnvironmentConfig.fromMap(Map<String, dynamic> map) =>
      EnvironmentConfig(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        type:
            EnvironmentType.fromString(map['type'] as String? ?? 'development'),
        config: Map<String, dynamic>.from(
            map['config'] as Map<dynamic, dynamic>? ?? {}),
        secrets: Map<String, dynamic>.from(
            map['secrets'] as Map<dynamic, dynamic>? ?? {}),
        featureFlags: Map<String, dynamic>.from(
            map['featureFlags'] as Map<dynamic, dynamic>? ?? {}),
        apiEndpoints: Map<String, dynamic>.from(
            map['apiEndpoints'] as Map<dynamic, dynamic>? ?? {}),
        databaseConfig: Map<String, dynamic>.from(
            map['databaseConfig'] as Map<dynamic, dynamic>? ?? {}),
        cacheConfig: Map<String, dynamic>.from(
            map['cacheConfig'] as Map<dynamic, dynamic>? ?? {}),
        loggingConfig: Map<String, dynamic>.from(
            map['loggingConfig'] as Map<dynamic, dynamic>? ?? {}),
        monitoringConfig: Map<String, dynamic>.from(
            map['monitoringConfig'] as Map<dynamic, dynamic>? ?? {}),
        securityConfig: Map<String, dynamic>.from(
            map['securityConfig'] as Map<dynamic, dynamic>? ?? {}),
        isActive: map['isActive'] as bool? ?? false,
        description: map['description'] as String?,
        tags: List<String>.from(map['tags'] ?? []),
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        createdBy: map['createdBy'] ?? '',
        updatedBy: map['updatedBy'] ?? '',
      );
  final String id;
  final String name;
  final EnvironmentType type;
  final Map<String, dynamic> config;
  final Map<String, dynamic> secrets;
  final Map<String, dynamic> featureFlags;
  final Map<String, dynamic> apiEndpoints;
  final Map<String, dynamic> databaseConfig;
  final Map<String, dynamic> cacheConfig;
  final Map<String, dynamic> loggingConfig;
  final Map<String, dynamic> monitoringConfig;
  final Map<String, dynamic> securityConfig;
  final bool isActive;
  final String? description;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.value,
        'config': config,
        'secrets': secrets,
        'featureFlags': featureFlags,
        'apiEndpoints': apiEndpoints,
        'databaseConfig': databaseConfig,
        'cacheConfig': cacheConfig,
        'loggingConfig': loggingConfig,
        'monitoringConfig': monitoringConfig,
        'securityConfig': securityConfig,
        'isActive': isActive,
        'description': description,
        'tags': tags,
        'metadata': metadata,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
      };

  EnvironmentConfig copyWith({
    String? id,
    String? name,
    EnvironmentType? type,
    Map<String, dynamic>? config,
    Map<String, dynamic>? secrets,
    Map<String, dynamic>? featureFlags,
    Map<String, dynamic>? apiEndpoints,
    Map<String, dynamic>? databaseConfig,
    Map<String, dynamic>? cacheConfig,
    Map<String, dynamic>? loggingConfig,
    Map<String, dynamic>? monitoringConfig,
    Map<String, dynamic>? securityConfig,
    bool? isActive,
    String? description,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) =>
      EnvironmentConfig(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        config: config ?? this.config,
        secrets: secrets ?? this.secrets,
        featureFlags: featureFlags ?? this.featureFlags,
        apiEndpoints: apiEndpoints ?? this.apiEndpoints,
        databaseConfig: databaseConfig ?? this.databaseConfig,
        cacheConfig: cacheConfig ?? this.cacheConfig,
        loggingConfig: loggingConfig ?? this.loggingConfig,
        monitoringConfig: monitoringConfig ?? this.monitoringConfig,
        securityConfig: securityConfig ?? this.securityConfig,
        isActive: isActive ?? this.isActive,
        description: description ?? this.description,
        tags: tags ?? this.tags,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  @override
  String toString() =>
      'EnvironmentConfig(id: $id, name: $name, type: $type, isActive: $isActive)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EnvironmentConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Типы окружений
enum EnvironmentType {
  development('development', 'Разработка'),
  staging('staging', 'Тестирование'),
  production('production', 'Продакшн'),
  testing('testing', 'Тестирование'),
  demo('demo', 'Демо');

  const EnvironmentType(this.value, this.displayName);

  final String value;
  final String displayName;

  static EnvironmentType fromString(String value) =>
      EnvironmentType.values.firstWhere(
        (type) => type.value == value,
        orElse: () => EnvironmentType.development,
      );

  String get icon {
    switch (this) {
      case EnvironmentType.development:
        return '🛠️';
      case EnvironmentType.staging:
        return '🧪';
      case EnvironmentType.production:
        return '🚀';
      case EnvironmentType.testing:
        return '🧪';
      case EnvironmentType.demo:
        return '🎭';
    }
  }

  String get color {
    switch (this) {
      case EnvironmentType.development:
        return 'blue';
      case EnvironmentType.staging:
        return 'orange';
      case EnvironmentType.production:
        return 'green';
      case EnvironmentType.testing:
        return 'purple';
      case EnvironmentType.demo:
        return 'teal';
    }
  }
}

/// Модель для переменных окружения
class EnvironmentVariable {
  const EnvironmentVariable({
    required this.id,
    required this.key,
    required this.value,
    required this.type,
    required this.isSecret,
    this.description,
    this.defaultValue,
    required this.isRequired,
    required this.allowedValues,
    this.validationPattern,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory EnvironmentVariable.fromMap(Map<String, dynamic> map) =>
      EnvironmentVariable(
        id: map['id'] ?? '',
        key: map['key'] ?? '',
        value: map['value'] ?? '',
        type: EnvironmentVariableType.fromString(map['type'] ?? 'string'),
        isSecret: map['isSecret'] ?? false,
        description: map['description'],
        defaultValue: map['defaultValue'],
        isRequired: map['isRequired'] ?? false,
        allowedValues: List<String>.from(map['allowedValues'] ?? []),
        validationPattern: map['validationPattern'],
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        createdBy: map['createdBy'] ?? '',
        updatedBy: map['updatedBy'] ?? '',
      );
  final String id;
  final String key;
  final String value;
  final EnvironmentVariableType type;
  final bool isSecret;
  final String? description;
  final String? defaultValue;
  final bool isRequired;
  final List<String> allowedValues;
  final String? validationPattern;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  Map<String, dynamic> toMap() => {
        'id': id,
        'key': key,
        'value': value,
        'type': type.value,
        'isSecret': isSecret,
        'description': description,
        'defaultValue': defaultValue,
        'isRequired': isRequired,
        'allowedValues': allowedValues,
        'validationPattern': validationPattern,
        'metadata': metadata,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
      };

  EnvironmentVariable copyWith({
    String? id,
    String? key,
    String? value,
    EnvironmentVariableType? type,
    bool? isSecret,
    String? description,
    String? defaultValue,
    bool? isRequired,
    List<String>? allowedValues,
    String? validationPattern,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) =>
      EnvironmentVariable(
        id: id ?? this.id,
        key: key ?? this.key,
        value: value ?? this.value,
        type: type ?? this.type,
        isSecret: isSecret ?? this.isSecret,
        description: description ?? this.description,
        defaultValue: defaultValue ?? this.defaultValue,
        isRequired: isRequired ?? this.isRequired,
        allowedValues: allowedValues ?? this.allowedValues,
        validationPattern: validationPattern ?? this.validationPattern,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  @override
  String toString() =>
      'EnvironmentVariable(id: $id, key: $key, type: $type, isSecret: $isSecret)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EnvironmentVariable && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Типы переменных окружения
enum EnvironmentVariableType {
  string('string', 'Строка'),
  number('number', 'Число'),
  boolean('boolean', 'Булево'),
  json('json', 'JSON'),
  url('url', 'URL'),
  email('email', 'Email'),
  password('password', 'Пароль'),
  apiKey('apiKey', 'API ключ'),
  token('token', 'Токен');

  const EnvironmentVariableType(this.value, this.displayName);

  final String value;
  final String displayName;

  static EnvironmentVariableType fromString(String value) =>
      EnvironmentVariableType.values.firstWhere(
        (type) => type.value == value,
        orElse: () => EnvironmentVariableType.string,
      );

  String get icon {
    switch (this) {
      case EnvironmentVariableType.string:
        return '📝';
      case EnvironmentVariableType.number:
        return '🔢';
      case EnvironmentVariableType.boolean:
        return '✅';
      case EnvironmentVariableType.json:
        return '📋';
      case EnvironmentVariableType.url:
        return '🔗';
      case EnvironmentVariableType.email:
        return '📧';
      case EnvironmentVariableType.password:
        return '🔒';
      case EnvironmentVariableType.apiKey:
        return '🗝️';
      case EnvironmentVariableType.token:
        return '🎫';
    }
  }
}

/// Модель для конфигурации развертывания
class DeploymentConfig {
  const DeploymentConfig({
    required this.id,
    required this.environmentId,
    required this.version,
    required this.status,
    required this.config,
    required this.secrets,
    required this.dependencies,
    required this.healthChecks,
    required this.scalingConfig,
    required this.networkingConfig,
    required this.storageConfig,
    required this.monitoringConfig,
    this.description,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory DeploymentConfig.fromMap(Map<String, dynamic> map) =>
      DeploymentConfig(
        id: map['id'] ?? '',
        environmentId: map['environmentId'] ?? '',
        version: map['version'] ?? '',
        status: DeploymentStatus.fromString(map['status'] ?? 'draft'),
        config: Map<String, dynamic>.from(map['config'] ?? {}),
        secrets: Map<String, dynamic>.from(map['secrets'] ?? {}),
        dependencies: List<String>.from(map['dependencies'] ?? []),
        healthChecks: List<String>.from(map['healthChecks'] ?? []),
        scalingConfig: Map<String, dynamic>.from(map['scalingConfig'] ?? {}),
        networkingConfig:
            Map<String, dynamic>.from(map['networkingConfig'] ?? {}),
        storageConfig: Map<String, dynamic>.from(map['storageConfig'] ?? {}),
        monitoringConfig:
            Map<String, dynamic>.from(map['monitoringConfig'] ?? {}),
        description: map['description'],
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        createdBy: map['createdBy'] ?? '',
        updatedBy: map['updatedBy'] ?? '',
      );
  final String id;
  final String environmentId;
  final String version;
  final DeploymentStatus status;
  final Map<String, dynamic> config;
  final Map<String, dynamic> secrets;
  final List<String> dependencies;
  final List<String> healthChecks;
  final Map<String, dynamic> scalingConfig;
  final Map<String, dynamic> networkingConfig;
  final Map<String, dynamic> storageConfig;
  final Map<String, dynamic> monitoringConfig;
  final String? description;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  Map<String, dynamic> toMap() => {
        'id': id,
        'environmentId': environmentId,
        'version': version,
        'status': status.value,
        'config': config,
        'secrets': secrets,
        'dependencies': dependencies,
        'healthChecks': healthChecks,
        'scalingConfig': scalingConfig,
        'networkingConfig': networkingConfig,
        'storageConfig': storageConfig,
        'monitoringConfig': monitoringConfig,
        'description': description,
        'metadata': metadata,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
      };

  DeploymentConfig copyWith({
    String? id,
    String? environmentId,
    String? version,
    DeploymentStatus? status,
    Map<String, dynamic>? config,
    Map<String, dynamic>? secrets,
    List<String>? dependencies,
    List<String>? healthChecks,
    Map<String, dynamic>? scalingConfig,
    Map<String, dynamic>? networkingConfig,
    Map<String, dynamic>? storageConfig,
    Map<String, dynamic>? monitoringConfig,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) =>
      DeploymentConfig(
        id: id ?? this.id,
        environmentId: environmentId ?? this.environmentId,
        version: version ?? this.version,
        status: status ?? this.status,
        config: config ?? this.config,
        secrets: secrets ?? this.secrets,
        dependencies: dependencies ?? this.dependencies,
        healthChecks: healthChecks ?? this.healthChecks,
        scalingConfig: scalingConfig ?? this.scalingConfig,
        networkingConfig: networkingConfig ?? this.networkingConfig,
        storageConfig: storageConfig ?? this.storageConfig,
        monitoringConfig: monitoringConfig ?? this.monitoringConfig,
        description: description ?? this.description,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  @override
  String toString() =>
      'DeploymentConfig(id: $id, environmentId: $environmentId, version: $version, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeploymentConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Статусы развертывания
enum DeploymentStatus {
  draft('draft', 'Черновик'),
  pending('pending', 'Ожидает'),
  deploying('deploying', 'Развертывается'),
  deployed('deployed', 'Развернуто'),
  failed('failed', 'Ошибка'),
  rolledBack('rolledBack', 'Откачено'),
  archived('archived', 'Архивировано');

  const DeploymentStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static DeploymentStatus fromString(String value) =>
      DeploymentStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => DeploymentStatus.draft,
      );

  String get icon {
    switch (this) {
      case DeploymentStatus.draft:
        return '📝';
      case DeploymentStatus.pending:
        return '⏳';
      case DeploymentStatus.deploying:
        return '🚀';
      case DeploymentStatus.deployed:
        return '✅';
      case DeploymentStatus.failed:
        return '❌';
      case DeploymentStatus.rolledBack:
        return '↩️';
      case DeploymentStatus.archived:
        return '📦';
    }
  }

  String get color {
    switch (this) {
      case DeploymentStatus.draft:
        return 'grey';
      case DeploymentStatus.pending:
        return 'orange';
      case DeploymentStatus.deploying:
        return 'blue';
      case DeploymentStatus.deployed:
        return 'green';
      case DeploymentStatus.failed:
        return 'red';
      case DeploymentStatus.rolledBack:
        return 'purple';
      case DeploymentStatus.archived:
        return 'brown';
    }
  }
}
