import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../core/feature_flags.dart';
import '../models/environment_config.dart';

/// Сервис для управления конфигурацией окружения
class EnvironmentConfigService {
  factory EnvironmentConfigService() => _instance;
  EnvironmentConfigService._internal();
  static final EnvironmentConfigService _instance =
      EnvironmentConfigService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // Коллекции
  static const String _environmentsCollection = 'environment_configs';
  static const String _variablesCollection = 'environment_variables';
  static const String _deploymentsCollection = 'deployment_configs';

  // Потоки для real-time обновлений
  final StreamController<EnvironmentConfig> _environmentStreamController =
      StreamController<EnvironmentConfig>.broadcast();
  final StreamController<EnvironmentVariable> _variableStreamController =
      StreamController<EnvironmentVariable>.broadcast();
  final StreamController<DeploymentConfig> _deploymentStreamController =
      StreamController<DeploymentConfig>.broadcast();

  // Кэш конфигураций
  final Map<String, EnvironmentConfig> _environmentCache = {};
  final Map<String, EnvironmentVariable> _variableCache = {};
  final Map<String, DeploymentConfig> _deploymentCache = {};

  bool _isInitialized = false;

  /// Инициализация сервиса
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadCache();
      _isInitialized = true;
    } catch (e) {
      await _crashlytics.recordError(e, null, fatal: true);
      rethrow;
    }
  }

  /// Загрузка кэша
  Future<void> _loadCache() async {
    try {
      // Загружаем активные конфигурации окружений
      final environmentsSnapshot = await _firestore
          .collection(_environmentsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in environmentsSnapshot.docs) {
        final config = EnvironmentConfig.fromMap(doc.data());
        _environmentCache[config.id] = config;
      }

      // Загружаем переменные окружения
      final variablesSnapshot =
          await _firestore.collection(_variablesCollection).get();

      for (final doc in variablesSnapshot.docs) {
        final variable = EnvironmentVariable.fromMap(doc.data());
        _variableCache[variable.id] = variable;
      }

      // Загружаем конфигурации развертывания
      final deploymentsSnapshot =
          await _firestore.collection(_deploymentsCollection).get();

      for (final doc in deploymentsSnapshot.docs) {
        final deployment = DeploymentConfig.fromMap(doc.data());
        _deploymentCache[deployment.id] = deployment;
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Поток конфигураций окружений
  Stream<EnvironmentConfig> get environmentStream =>
      _environmentStreamController.stream;

  /// Поток переменных окружения
  Stream<EnvironmentVariable> get variableStream =>
      _variableStreamController.stream;

  /// Поток конфигураций развертывания
  Stream<DeploymentConfig> get deploymentStream =>
      _deploymentStreamController.stream;

  /// Создание конфигурации окружения
  Future<EnvironmentConfig> createEnvironmentConfig({
    required String name,
    required EnvironmentType type,
    required Map<String, dynamic> config,
    Map<String, dynamic>? secrets,
    Map<String, dynamic>? featureFlags,
    Map<String, dynamic>? apiEndpoints,
    Map<String, dynamic>? databaseConfig,
    Map<String, dynamic>? cacheConfig,
    Map<String, dynamic>? loggingConfig,
    Map<String, dynamic>? monitoringConfig,
    Map<String, dynamic>? securityConfig,
    String? description,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    if (!FeatureFlags.environmentManagementEnabled) {
      throw Exception('Environment management is disabled');
    }

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final environmentConfig = EnvironmentConfig(
        id: _generateId(),
        name: name,
        type: type,
        config: config,
        secrets: secrets ?? {},
        featureFlags: featureFlags ?? {},
        apiEndpoints: apiEndpoints ?? {},
        databaseConfig: databaseConfig ?? {},
        cacheConfig: cacheConfig ?? {},
        loggingConfig: loggingConfig ?? {},
        monitoringConfig: monitoringConfig ?? {},
        securityConfig: securityConfig ?? {},
        isActive: false,
        description: description,
        tags: tags ?? [],
        metadata: metadata ?? {},
        createdAt: now,
        updatedAt: now,
        createdBy: user.uid,
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_environmentsCollection)
          .doc(environmentConfig.id)
          .set(environmentConfig.toMap());

      _environmentCache[environmentConfig.id] = environmentConfig;
      _environmentStreamController.add(environmentConfig);

      return environmentConfig;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Обновление конфигурации окружения
  Future<EnvironmentConfig> updateEnvironmentConfig({
    required String id,
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
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final existingConfig = _environmentCache[id];
      if (existingConfig == null) {
        throw Exception('Environment config not found');
      }

      final updatedConfig = existingConfig.copyWith(
        name: name,
        type: type,
        config: config,
        secrets: secrets,
        featureFlags: featureFlags,
        apiEndpoints: apiEndpoints,
        databaseConfig: databaseConfig,
        cacheConfig: cacheConfig,
        loggingConfig: loggingConfig,
        monitoringConfig: monitoringConfig,
        securityConfig: securityConfig,
        isActive: isActive,
        description: description,
        tags: tags,
        metadata: metadata,
        updatedAt: DateTime.now(),
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_environmentsCollection)
          .doc(id)
          .update(updatedConfig.toMap());

      _environmentCache[id] = updatedConfig;
      _environmentStreamController.add(updatedConfig);

      return updatedConfig;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Получение конфигурации окружения
  EnvironmentConfig? getEnvironmentConfig(String id) => _environmentCache[id];

  /// Получение всех конфигураций окружений
  List<EnvironmentConfig> getAllEnvironmentConfigs() =>
      _environmentCache.values.toList();

  /// Получение активной конфигурации окружения
  EnvironmentConfig? getActiveEnvironmentConfig() =>
      _environmentCache.values.firstWhere(
        (config) => config.isActive,
        orElse: () => _environmentCache.values.isNotEmpty
            ? _environmentCache.values.first
            : null,
      );

  /// Активация конфигурации окружения
  Future<void> activateEnvironmentConfig(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Деактивируем все остальные конфигурации
      final batch = _firestore.batch();
      for (final config in _environmentCache.values) {
        if (config.id != id && config.isActive) {
          final docRef =
              _firestore.collection(_environmentsCollection).doc(config.id);
          batch.update(docRef, {
            'isActive': false,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
            'updatedBy': user.uid,
          });
        }
      }

      // Активируем выбранную конфигурацию
      final docRef = _firestore.collection(_environmentsCollection).doc(id);
      batch.update(docRef, {
        'isActive': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedBy': user.uid,
      });

      await batch.commit();

      // Обновляем кэш
      for (final config in _environmentCache.values) {
        if (config.id != id) {
          _environmentCache[config.id] = config.copyWith(
            isActive: false,
            updatedAt: DateTime.now(),
            updatedBy: user.uid,
          );
        } else {
          _environmentCache[config.id] = config.copyWith(
            isActive: true,
            updatedAt: DateTime.now(),
            updatedBy: user.uid,
          );
        }
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Создание переменной окружения
  Future<EnvironmentVariable> createEnvironmentVariable({
    required String key,
    required String value,
    required EnvironmentVariableType type,
    bool isSecret = false,
    String? description,
    String? defaultValue,
    bool isRequired = false,
    List<String>? allowedValues,
    String? validationPattern,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final variable = EnvironmentVariable(
        id: _generateId(),
        key: key,
        value: value,
        type: type,
        isSecret: isSecret,
        description: description,
        defaultValue: defaultValue,
        isRequired: isRequired,
        allowedValues: allowedValues ?? [],
        validationPattern: validationPattern,
        metadata: metadata ?? {},
        createdAt: now,
        updatedAt: now,
        createdBy: user.uid,
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_variablesCollection)
          .doc(variable.id)
          .set(variable.toMap());

      _variableCache[variable.id] = variable;
      _variableStreamController.add(variable);

      return variable;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Обновление переменной окружения
  Future<EnvironmentVariable> updateEnvironmentVariable({
    required String id,
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
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final existingVariable = _variableCache[id];
      if (existingVariable == null) {
        throw Exception('Environment variable not found');
      }

      final updatedVariable = existingVariable.copyWith(
        key: key,
        value: value,
        type: type,
        isSecret: isSecret,
        description: description,
        defaultValue: defaultValue,
        isRequired: isRequired,
        allowedValues: allowedValues,
        validationPattern: validationPattern,
        metadata: metadata,
        updatedAt: DateTime.now(),
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_variablesCollection)
          .doc(id)
          .update(updatedVariable.toMap());

      _variableCache[id] = updatedVariable;
      _variableStreamController.add(updatedVariable);

      return updatedVariable;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Получение переменной окружения
  EnvironmentVariable? getEnvironmentVariable(String id) => _variableCache[id];

  /// Получение переменной окружения по ключу
  EnvironmentVariable? getEnvironmentVariableByKey(String key) =>
      _variableCache.values
          .firstWhere((variable) => variable.key == key, orElse: () => null);

  /// Получение всех переменных окружения
  List<EnvironmentVariable> getAllEnvironmentVariables() =>
      _variableCache.values.toList();

  /// Создание конфигурации развертывания
  Future<DeploymentConfig> createDeploymentConfig({
    required String environmentId,
    required String version,
    required Map<String, dynamic> config,
    Map<String, dynamic>? secrets,
    List<String>? dependencies,
    List<String>? healthChecks,
    Map<String, dynamic>? scalingConfig,
    Map<String, dynamic>? networkingConfig,
    Map<String, dynamic>? storageConfig,
    Map<String, dynamic>? monitoringConfig,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final deploymentConfig = DeploymentConfig(
        id: _generateId(),
        environmentId: environmentId,
        version: version,
        status: DeploymentStatus.draft,
        config: config,
        secrets: secrets ?? {},
        dependencies: dependencies ?? [],
        healthChecks: healthChecks ?? [],
        scalingConfig: scalingConfig ?? {},
        networkingConfig: networkingConfig ?? {},
        storageConfig: storageConfig ?? {},
        monitoringConfig: monitoringConfig ?? {},
        description: description,
        metadata: metadata ?? {},
        createdAt: now,
        updatedAt: now,
        createdBy: user.uid,
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_deploymentsCollection)
          .doc(deploymentConfig.id)
          .set(deploymentConfig.toMap());

      _deploymentCache[deploymentConfig.id] = deploymentConfig;
      _deploymentStreamController.add(deploymentConfig);

      return deploymentConfig;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Обновление конфигурации развертывания
  Future<DeploymentConfig> updateDeploymentConfig({
    required String id,
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
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final existingDeployment = _deploymentCache[id];
      if (existingDeployment == null) {
        throw Exception('Deployment config not found');
      }

      final updatedDeployment = existingDeployment.copyWith(
        version: version,
        status: status,
        config: config,
        secrets: secrets,
        dependencies: dependencies,
        healthChecks: healthChecks,
        scalingConfig: scalingConfig,
        networkingConfig: networkingConfig,
        storageConfig: storageConfig,
        monitoringConfig: monitoringConfig,
        description: description,
        metadata: metadata,
        updatedAt: DateTime.now(),
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_deploymentsCollection)
          .doc(id)
          .update(updatedDeployment.toMap());

      _deploymentCache[id] = updatedDeployment;
      _deploymentStreamController.add(updatedDeployment);

      return updatedDeployment;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Получение конфигурации развертывания
  DeploymentConfig? getDeploymentConfig(String id) => _deploymentCache[id];

  /// Получение всех конфигураций развертывания
  List<DeploymentConfig> getAllDeploymentConfigs() =>
      _deploymentCache.values.toList();

  /// Получение конфигураций развертывания для окружения
  List<DeploymentConfig> getDeploymentConfigsForEnvironment(
          String environmentId) =>
      _deploymentCache.values
          .where((deployment) => deployment.environmentId == environmentId)
          .toList();

  /// Экспорт конфигурации окружения
  Future<String> exportEnvironmentConfig(String id,
      {String format = 'json'}) async {
    try {
      final config = _environmentCache[id];
      if (config == null) throw Exception('Environment config not found');

      final exportData = {
        'environment': config.toMap(),
        'variables': _variableCache.values
            .where((variable) => config.config.containsKey(variable.key))
            .map((variable) => variable.toMap())
            .toList(),
        'deployments': _deploymentCache.values
            .where((deployment) => deployment.environmentId == id)
            .map((deployment) => deployment.toMap())
            .toList(),
        'exportDate': DateTime.now().toIso8601String(),
      };

      if (format == 'json') {
        return jsonEncode(exportData);
      } else if (format == 'yaml') {
        return _convertToYAML(exportData);
      } else {
        throw ArgumentError('Unsupported format: $format');
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Импорт конфигурации окружения
  Future<EnvironmentConfig> importEnvironmentConfig(String data,
      {String format = 'json'}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      Map<String, dynamic> importData;
      if (format == 'json') {
        importData = jsonDecode(data);
      } else {
        throw ArgumentError('Unsupported format: $format');
      }

      final environmentData = importData['environment'] as Map<String, dynamic>;
      final variablesData = importData['variables'] as List<dynamic>? ?? [];
      final deploymentsData = importData['deployments'] as List<dynamic>? ?? [];

      // Создаем конфигурацию окружения
      final now = DateTime.now();
      final environmentConfig = EnvironmentConfig(
        id: _generateId(),
        name: environmentData['name'] ?? 'Imported Environment',
        type: EnvironmentType.fromString(
            environmentData['type'] ?? 'development'),
        config: Map<String, dynamic>.from(environmentData['config'] ?? {}),
        secrets: Map<String, dynamic>.from(environmentData['secrets'] ?? {}),
        featureFlags:
            Map<String, dynamic>.from(environmentData['featureFlags'] ?? {}),
        apiEndpoints:
            Map<String, dynamic>.from(environmentData['apiEndpoints'] ?? {}),
        databaseConfig:
            Map<String, dynamic>.from(environmentData['databaseConfig'] ?? {}),
        cacheConfig:
            Map<String, dynamic>.from(environmentData['cacheConfig'] ?? {}),
        loggingConfig:
            Map<String, dynamic>.from(environmentData['loggingConfig'] ?? {}),
        monitoringConfig: Map<String, dynamic>.from(
            environmentData['monitoringConfig'] ?? {}),
        securityConfig:
            Map<String, dynamic>.from(environmentData['securityConfig'] ?? {}),
        isActive: false,
        description: environmentData['description'],
        tags: List<String>.from(environmentData['tags'] ?? []),
        metadata: Map<String, dynamic>.from(environmentData['metadata'] ?? {}),
        createdAt: now,
        updatedAt: now,
        createdBy: user.uid,
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_environmentsCollection)
          .doc(environmentConfig.id)
          .set(environmentConfig.toMap());

      _environmentCache[environmentConfig.id] = environmentConfig;

      // Импортируем переменные окружения
      for (final variableData in variablesData) {
        final variable = EnvironmentVariable(
          id: _generateId(),
          key: variableData['key'] ?? '',
          value: variableData['value'] ?? '',
          type: EnvironmentVariableType.fromString(
              variableData['type'] ?? 'string'),
          isSecret: variableData['isSecret'] ?? false,
          description: variableData['description'],
          defaultValue: variableData['defaultValue'],
          isRequired: variableData['isRequired'] ?? false,
          allowedValues: List<String>.from(variableData['allowedValues'] ?? []),
          validationPattern: variableData['validationPattern'],
          metadata: Map<String, dynamic>.from(variableData['metadata'] ?? {}),
          createdAt: now,
          updatedAt: now,
          createdBy: user.uid,
          updatedBy: user.uid,
        );

        await _firestore
            .collection(_variablesCollection)
            .doc(variable.id)
            .set(variable.toMap());

        _variableCache[variable.id] = variable;
      }

      // Импортируем конфигурации развертывания
      for (final deploymentData in deploymentsData) {
        final deployment = DeploymentConfig(
          id: _generateId(),
          environmentId: environmentConfig.id,
          version: deploymentData['version'] ?? '1.0.0',
          status:
              DeploymentStatus.fromString(deploymentData['status'] ?? 'draft'),
          config: Map<String, dynamic>.from(deploymentData['config'] ?? {}),
          secrets: Map<String, dynamic>.from(deploymentData['secrets'] ?? {}),
          dependencies: List<String>.from(deploymentData['dependencies'] ?? []),
          healthChecks: List<String>.from(deploymentData['healthChecks'] ?? []),
          scalingConfig:
              Map<String, dynamic>.from(deploymentData['scalingConfig'] ?? {}),
          networkingConfig: Map<String, dynamic>.from(
              deploymentData['networkingConfig'] ?? {}),
          storageConfig:
              Map<String, dynamic>.from(deploymentData['storageConfig'] ?? {}),
          monitoringConfig: Map<String, dynamic>.from(
              deploymentData['monitoringConfig'] ?? {}),
          description: deploymentData['description'],
          metadata: Map<String, dynamic>.from(deploymentData['metadata'] ?? {}),
          createdAt: now,
          updatedAt: now,
          createdBy: user.uid,
          updatedBy: user.uid,
        );

        await _firestore
            .collection(_deploymentsCollection)
            .doc(deployment.id)
            .set(deployment.toMap());

        _deploymentCache[deployment.id] = deployment;
      }

      _environmentStreamController.add(environmentConfig);
      return environmentConfig;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Конвертация в YAML
  String _convertToYAML(Map<String, dynamic> data) {
    // Простая конвертация в YAML-подобный формат
    final buffer = StringBuffer();
    buffer.writeln('# Environment Configuration');
    buffer.writeln('environment:');
    buffer.writeln('  name: ${data['environment']['name']}');
    buffer.writeln('  type: ${data['environment']['type']}');
    buffer.writeln('  isActive: ${data['environment']['isActive']}');

    if (data['variables'].isNotEmpty) {
      buffer.writeln('variables:');
      for (final variable in data['variables']) {
        buffer.writeln('  - key: ${variable['key']}');
        buffer.writeln('    value: ${variable['value']}');
        buffer.writeln('    type: ${variable['type']}');
        buffer.writeln('    isSecret: ${variable['isSecret']}');
      }
    }

    return buffer.toString();
  }

  /// Валидация конфигурации окружения
  Future<List<String>> validateEnvironmentConfig(String id) async {
    try {
      final config = _environmentCache[id];
      if (config == null) return ['Environment config not found'];

      final errors = <String>[];

      // Проверяем обязательные поля
      if (config.name.isEmpty) {
        errors.add('Environment name is required');
      }

      // Проверяем переменные окружения
      for (final variable in _variableCache.values) {
        if (variable.isRequired && !config.config.containsKey(variable.key)) {
          errors.add(
              'Required environment variable "${variable.key}" is missing');
        }
      }

      // Проверяем API endpoints
      if (config.apiEndpoints.isEmpty) {
        errors.add('API endpoints configuration is required');
      }

      // Проверяем конфигурацию базы данных
      if (config.databaseConfig.isEmpty) {
        errors.add('Database configuration is required');
      }

      return errors;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      return ['Validation error: $e'];
    }
  }

  /// Получение статистики конфигураций
  Future<Map<String, dynamic>> getConfigStatistics() async {
    try {
      final environments = _environmentCache.values;
      final variables = _variableCache.values;
      final deployments = _deploymentCache.values;

      return {
        'environments': {
          'total': environments.length,
          'active': environments.where((e) => e.isActive).length,
          'byType': _groupEnvironmentsByType(environments),
        },
        'variables': {
          'total': variables.length,
          'secrets': variables.where((v) => v.isSecret).length,
          'required': variables.where((v) => v.isRequired).length,
          'byType': _groupVariablesByType(variables),
        },
        'deployments': {
          'total': deployments.length,
          'byStatus': _groupDeploymentsByStatus(deployments),
        },
      };
    } catch (e) {
      await _crashlytics.recordError(e, null);
      return {};
    }
  }

  /// Группировка окружений по типу
  Map<String, int> _groupEnvironmentsByType(
      List<EnvironmentConfig> environments) {
    final groups = <String, int>{};
    for (final env in environments) {
      groups[env.type.value] = (groups[env.type.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка переменных по типу
  Map<String, int> _groupVariablesByType(List<EnvironmentVariable> variables) {
    final groups = <String, int>{};
    for (final variable in variables) {
      groups[variable.type.value] = (groups[variable.type.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка развертываний по статусу
  Map<String, int> _groupDeploymentsByStatus(
      List<DeploymentConfig> deployments) {
    final groups = <String, int>{};
    for (final deployment in deployments) {
      groups[deployment.status.value] =
          (groups[deployment.status.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Генерация уникального ID
  String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      (1000 + (9999 - 1000) * (DateTime.now().microsecond / 1000000))
          .round()
          .toString();

  /// Закрытие сервиса
  Future<void> dispose() async {
    await _environmentStreamController.close();
    await _variableStreamController.close();
    await _deploymentStreamController.close();
  }
}
