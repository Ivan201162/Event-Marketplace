import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../core/feature_flags.dart';
import '../models/dependency_management.dart';

/// Сервис для управления зависимостями
class DependencyManagementService {
  factory DependencyManagementService() => _instance;
  DependencyManagementService._internal();
  static final DependencyManagementService _instance =
      DependencyManagementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // Коллекции
  static const String _dependenciesCollection = 'dependencies';
  static const String _updatesCollection = 'dependency_updates';
  static const String _configCollection = 'dependency_config';

  // Потоки для real-time обновлений
  final StreamController<Dependency> _dependencyStreamController =
      StreamController<Dependency>.broadcast();
  final StreamController<DependencyUpdate> _updateStreamController =
      StreamController<DependencyUpdate>.broadcast();

  // Кэш зависимостей
  final Map<String, Dependency> _dependencyCache = {};
  final Map<String, DependencyUpdate> _updateCache = {};
  DependencyConfig? _config;

  bool _isInitialized = false;

  /// Инициализация сервиса
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadConfig();
      await _loadDependencies();
      _isInitialized = true;
    } catch (e) {
      await _crashlytics.recordError(e, null, fatal: true);
      rethrow;
    }
  }

  /// Загрузка конфигурации
  Future<void> _loadConfig() async {
    try {
      final doc =
          await _firestore.collection(_configCollection).doc('default').get();

      if (doc.exists) {
        _config = DependencyConfig.fromMap(doc.data()!);
      } else {
        // Создаем конфигурацию по умолчанию
        _config = DependencyConfig(
          id: 'default',
          enableAutoUpdates: false,
          enableSecurityUpdates: true,
          enableBreakingChangeNotifications: true,
          allowedUpdateTypes: UpdateType.values,
          allowedPriorities: UpdatePriority.values,
          maxConcurrentUpdates: 3,
          updateRetryAttempts: 3,
          updateTimeout: const Duration(minutes: 5),
          excludedDependencies: [],
          requiredApprovals: [],
          updatePolicies: {},
          notificationSettings: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: '',
          updatedBy: '',
        );
        await _saveConfig(_config!);
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Сохранение конфигурации
  Future<void> _saveConfig(DependencyConfig config) async {
    await _firestore
        .collection(_configCollection)
        .doc(config.id)
        .set(config.toMap());
  }

  /// Загрузка зависимостей
  Future<void> _loadDependencies() async {
    try {
      final snapshot =
          await _firestore.collection(_dependenciesCollection).get();

      for (final doc in snapshot.docs) {
        final dependency = Dependency.fromMap(doc.data());
        _dependencyCache[dependency.id] = dependency;
      }

      // Загружаем обновления
      final updatesSnapshot =
          await _firestore.collection(_updatesCollection).get();

      for (final doc in updatesSnapshot.docs) {
        final update = DependencyUpdate.fromMap(doc.data());
        _updateCache[update.id] = update;
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Поток зависимостей
  Stream<Dependency> get dependencyStream => _dependencyStreamController.stream;

  /// Поток обновлений
  Stream<DependencyUpdate> get updateStream => _updateStreamController.stream;

  /// Получение конфигурации
  DependencyConfig? get config => _config;

  /// Добавление зависимости
  Future<Dependency> addDependency({
    required String name,
    required String version,
    required DependencyType type,
    String? description,
    String? repositoryUrl,
    String? documentationUrl,
    List<String>? licenses,
    List<String>? authors,
    Map<String, dynamic>? metadata,
    List<String>? dependencies,
  }) async {
    if (!FeatureFlags.dependencyManagementEnabled) {
      throw Exception('Dependency management is disabled');
    }

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final dependency = Dependency(
        id: _generateId(),
        name: name,
        version: version,
        type: type,
        status: DependencyStatus.active,
        description: description,
        repositoryUrl: repositoryUrl,
        documentationUrl: documentationUrl,
        licenses: licenses ?? [],
        authors: authors ?? [],
        metadata: metadata ?? {},
        dependencies: dependencies ?? [],
        dependents: [],
        createdAt: now,
        updatedAt: now,
        createdBy: user.uid,
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_dependenciesCollection)
          .doc(dependency.id)
          .set(dependency.toMap());

      _dependencyCache[dependency.id] = dependency;
      _dependencyStreamController.add(dependency);

      return dependency;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Обновление зависимости
  Future<Dependency> updateDependency({
    required String id,
    String? name,
    String? version,
    String? latestVersion,
    DependencyType? type,
    DependencyStatus? status,
    String? description,
    String? repositoryUrl,
    String? documentationUrl,
    List<String>? licenses,
    List<String>? authors,
    Map<String, dynamic>? metadata,
    List<String>? dependencies,
    List<String>? dependents,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final existingDependency = _dependencyCache[id];
      if (existingDependency == null) throw Exception('Dependency not found');

      final updatedDependency = existingDependency.copyWith(
        name: name,
        version: version,
        latestVersion: latestVersion,
        type: type,
        status: status,
        description: description,
        repositoryUrl: repositoryUrl,
        documentationUrl: documentationUrl,
        licenses: licenses,
        authors: authors,
        metadata: metadata,
        dependencies: dependencies,
        dependents: dependents,
        updatedAt: DateTime.now(),
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_dependenciesCollection)
          .doc(id)
          .update(updatedDependency.toMap());

      _dependencyCache[id] = updatedDependency;
      _dependencyStreamController.add(updatedDependency);

      return updatedDependency;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Получение зависимости
  Dependency? getDependency(String id) => _dependencyCache[id];

  /// Получение всех зависимостей
  List<Dependency> getAllDependencies() => _dependencyCache.values.toList();

  /// Получение зависимостей по типу
  List<Dependency> getDependenciesByType(DependencyType type) =>
      _dependencyCache.values
          .where((dependency) => dependency.type == type)
          .toList();

  /// Получение зависимостей по статусу
  List<Dependency> getDependenciesByStatus(DependencyStatus status) =>
      _dependencyCache.values
          .where((dependency) => dependency.status == status)
          .toList();

  /// Проверка обновлений
  Future<List<DependencyUpdate>> checkForUpdates() async {
    try {
      final updates = <DependencyUpdate>[];

      for (final dependency in _dependencyCache.values) {
        if (dependency.latestVersion != null &&
            dependency.latestVersion != dependency.version) {
          final update = DependencyUpdate(
            id: _generateId(),
            dependencyId: dependency.id,
            currentVersion: dependency.version,
            newVersion: dependency.latestVersion!,
            type: _determineUpdateType(
              dependency.version,
              dependency.latestVersion!,
            ),
            priority: _determineUpdatePriority(dependency),
            breakingChanges: [],
            securityFixes: [],
            bugFixes: [],
            newFeatures: [],
            metadata: {},
            releaseDate: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: _auth.currentUser?.uid ?? '',
            updatedBy: _auth.currentUser?.uid ?? '',
          );

          await _firestore
              .collection(_updatesCollection)
              .doc(update.id)
              .set(update.toMap());

          _updateCache[update.id] = update;
          updates.add(update);
        }
      }

      return updates;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      return [];
    }
  }

  /// Определение типа обновления
  UpdateType _determineUpdateType(String currentVersion, String newVersion) {
    final currentParts = currentVersion.split('.');
    final newParts = newVersion.split('.');

    if (currentParts.length >= 3 && newParts.length >= 3) {
      final currentMajor = int.tryParse(currentParts[0]) ?? 0;
      final newMajor = int.tryParse(newParts[0]) ?? 0;
      final currentMinor = int.tryParse(currentParts[1]) ?? 0;
      final newMinor = int.tryParse(newParts[1]) ?? 0;

      if (newMajor > currentMajor) {
        return UpdateType.major;
      } else if (newMinor > currentMinor) {
        return UpdateType.minor;
      } else {
        return UpdateType.patch;
      }
    }

    return UpdateType.minor;
  }

  /// Определение приоритета обновления
  UpdatePriority _determineUpdatePriority(Dependency dependency) {
    if (dependency.status == DependencyStatus.vulnerable) {
      return UpdatePriority.critical;
    } else if (dependency.status == DependencyStatus.deprecated) {
      return UpdatePriority.high;
    } else if (dependency.status == DependencyStatus.outdated) {
      return UpdatePriority.medium;
    } else {
      return UpdatePriority.low;
    }
  }

  /// Применение обновления
  Future<bool> applyUpdate(String updateId) async {
    try {
      final update = _updateCache[updateId];
      if (update == null) throw Exception('Update not found');

      final dependency = _dependencyCache[update.dependencyId];
      if (dependency == null) throw Exception('Dependency not found');

      // Проверяем конфигурацию
      if (!_config!.allowedUpdateTypes.contains(update.type)) {
        throw Exception('Update type not allowed');
      }

      if (!_config!.allowedPriorities.contains(update.priority)) {
        throw Exception('Update priority not allowed');
      }

      // Обновляем зависимость
      final updatedDependency = dependency.copyWith(
        version: update.newVersion,
        latestVersion: update.newVersion,
        updatedAt: DateTime.now(),
        updatedBy: _auth.currentUser?.uid ?? '',
      );

      await _firestore
          .collection(_dependenciesCollection)
          .doc(dependency.id)
          .update(updatedDependency.toMap());

      _dependencyCache[dependency.id] = updatedDependency;
      _dependencyStreamController.add(updatedDependency);

      return true;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      return false;
    }
  }

  /// Получение обновлений
  List<DependencyUpdate> getUpdates() => _updateCache.values.toList();

  /// Получение обновлений по приоритету
  List<DependencyUpdate> getUpdatesByPriority(UpdatePriority priority) =>
      _updateCache.values
          .where((update) => update.priority == priority)
          .toList();

  /// Получение обновлений по типу
  List<DependencyUpdate> getUpdatesByType(UpdateType type) =>
      _updateCache.values.where((update) => update.type == type).toList();

  /// Обновление конфигурации
  Future<void> updateConfig(DependencyConfig config) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updatedConfig = config.copyWith(
        updatedAt: DateTime.now(),
        updatedBy: user.uid,
      );

      await _saveConfig(updatedConfig);
      _config = updatedConfig;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Анализ зависимостей
  Future<Map<String, dynamic>> analyzeDependencies() async {
    try {
      final dependencies = _dependencyCache.values;
      final updates = _updateCache.values;

      return {
        'total': dependencies.length,
        'byType': _groupDependenciesByType(dependencies),
        'byStatus': _groupDependenciesByStatus(dependencies),
        'outdated': dependencies
            .where((d) => d.status == DependencyStatus.outdated)
            .length,
        'vulnerable': dependencies
            .where((d) => d.status == DependencyStatus.vulnerable)
            .length,
        'deprecated': dependencies
            .where((d) => d.status == DependencyStatus.deprecated)
            .length,
        'updatesAvailable': updates.length,
        'criticalUpdates':
            updates.where((u) => u.priority == UpdatePriority.critical).length,
        'securityUpdates':
            updates.where((u) => u.securityFixes.isNotEmpty).length,
        'breakingChanges':
            updates.where((u) => u.breakingChanges.isNotEmpty).length,
      };
    } catch (e) {
      await _crashlytics.recordError(e, null);
      return {};
    }
  }

  /// Группировка зависимостей по типу
  Map<String, int> _groupDependenciesByType(List<Dependency> dependencies) {
    final groups = <String, int>{};
    for (final dependency in dependencies) {
      groups[dependency.type.value] = (groups[dependency.type.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка зависимостей по статусу
  Map<String, int> _groupDependenciesByStatus(List<Dependency> dependencies) {
    final groups = <String, int>{};
    for (final dependency in dependencies) {
      groups[dependency.status.value] =
          (groups[dependency.status.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Экспорт зависимостей
  Future<String> exportDependencies({String format = 'json'}) async {
    try {
      final dependencies = _dependencyCache.values;
      final updates = _updateCache.values;

      final exportData = {
        'dependencies': dependencies.map((d) => d.toMap()).toList(),
        'updates': updates.map((u) => u.toMap()).toList(),
        'config': _config?.toMap(),
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

  /// Импорт зависимостей
  Future<void> importDependencies(String data, {String format = 'json'}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      Map<String, dynamic> importData;
      if (format == 'json') {
        importData = jsonDecode(data);
      } else {
        throw ArgumentError('Unsupported format: $format');
      }

      final dependenciesData =
          importData['dependencies'] as List<dynamic>? ?? [];
      final updatesData = importData['updates'] as List<dynamic>? ?? [];
      final configData = importData['config'] as Map<String, dynamic>?;

      // Импортируем зависимости
      for (final dependencyData in dependenciesData) {
        final dependency = Dependency(
          id: _generateId(),
          name: dependencyData['name'] ?? '',
          version: dependencyData['version'] ?? '',
          latestVersion: dependencyData['latestVersion'],
          type: DependencyType.fromString(dependencyData['type'] ?? 'package'),
          status:
              DependencyStatus.fromString(dependencyData['status'] ?? 'active'),
          description: dependencyData['description'],
          repositoryUrl: dependencyData['repositoryUrl'],
          documentationUrl: dependencyData['documentationUrl'],
          licenses: List<String>.from(dependencyData['licenses'] ?? []),
          authors: List<String>.from(dependencyData['authors'] ?? []),
          metadata: Map<String, dynamic>.from(dependencyData['metadata'] ?? {}),
          dependencies: List<String>.from(dependencyData['dependencies'] ?? []),
          dependents: List<String>.from(dependencyData['dependents'] ?? []),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: user.uid,
          updatedBy: user.uid,
        );

        await _firestore
            .collection(_dependenciesCollection)
            .doc(dependency.id)
            .set(dependency.toMap());

        _dependencyCache[dependency.id] = dependency;
      }

      // Импортируем обновления
      for (final updateData in updatesData) {
        final update = DependencyUpdate(
          id: _generateId(),
          dependencyId: updateData['dependencyId'] ?? '',
          currentVersion: updateData['currentVersion'] ?? '',
          newVersion: updateData['newVersion'] ?? '',
          type: UpdateType.fromString(updateData['type'] ?? 'minor'),
          priority:
              UpdatePriority.fromString(updateData['priority'] ?? 'medium'),
          changelog: updateData['changelog'],
          breakingChanges:
              List<String>.from(updateData['breakingChanges'] ?? []),
          securityFixes: List<String>.from(updateData['securityFixes'] ?? []),
          bugFixes: List<String>.from(updateData['bugFixes'] ?? []),
          newFeatures: List<String>.from(updateData['newFeatures'] ?? []),
          metadata: Map<String, dynamic>.from(updateData['metadata'] ?? {}),
          releaseDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: user.uid,
          updatedBy: user.uid,
        );

        await _firestore
            .collection(_updatesCollection)
            .doc(update.id)
            .set(update.toMap());

        _updateCache[update.id] = update;
      }

      // Импортируем конфигурацию
      if (configData != null) {
        final config = DependencyConfig.fromMap(configData);
        await _saveConfig(config);
        _config = config;
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Конвертация в YAML
  String _convertToYAML(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('# Dependencies Export');
    buffer.writeln('dependencies:');

    for (final dependency in data['dependencies']) {
      buffer.writeln('  - name: ${dependency['name']}');
      buffer.writeln('    version: ${dependency['version']}');
      buffer.writeln('    type: ${dependency['type']}');
      buffer.writeln('    status: ${dependency['status']}');
    }

    return buffer.toString();
  }

  /// Генерация уникального ID
  String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      (1000 + (9999 - 1000) * (DateTime.now().microsecond / 1000000))
          .round()
          .toString();

  /// Закрытие сервиса
  Future<void> dispose() async {
    await _dependencyStreamController.close();
    await _updateStreamController.close();
  }
}
