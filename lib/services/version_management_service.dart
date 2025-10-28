import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/version_management.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

/// Сервис управления версиями и обновлениями
class VersionManagementService {
  factory VersionManagementService() => _instance;
  VersionManagementService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  static final VersionManagementService _instance =
      VersionManagementService._internal();

  final Map<String, AppVersion> _versionsCache = {};
  final Map<String, AppUpdate> _updatesCache = {};
  final Map<String, VersionStatistics> _statisticsCache = {};

  PackageInfo? _packageInfo;
  String? _currentVersion;
  String? _currentBuildNumber;
  String? _currentPlatform;

  /// Инициализация сервиса
  Future<void> initialize() async {
    try {
      await _loadPackageInfo();
      await _loadVersionsCache();
      await _loadUpdatesCache();
      await _loadStatisticsCache();

      if (kDebugMode) {
        debugPrint('Version management service initialized');
        debugPrint('Current version: $_currentVersion ($_currentBuildNumber)');
        debugPrint('Platform: $_currentPlatform');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка инициализации сервиса управления версиями: $e');
      }
    }
  }

  /// Загрузить информацию о пакете
  Future<void> _loadPackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = _packageInfo?.version;
      _currentBuildNumber = _packageInfo?.buildNumber;
      _currentPlatform = Platform.operatingSystem;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка загрузки информации о пакете: $e');
      }
    }
  }

  /// Проверить наличие обновлений
  Future<AppVersion?> checkForUpdates() async {
    try {
      if (_currentVersion == null || _currentPlatform == null) {
        return null;
      }

      // Получаем последнюю доступную версию для текущей платформы
      final snapshot = await _firestore
          .collection('appVersions')
          .where('platform', isEqualTo: _currentPlatform)
          .where('isAvailable', isEqualTo: true)
          .orderBy('releaseDate', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final latestVersion = AppVersion.fromDocument(snapshot.docs.first);

      // Проверяем, есть ли более новая версия
      if (_isVersionNewer(latestVersion.version, _currentVersion!)) {
        return latestVersion;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка проверки обновлений: $e');
      }
      return null;
    }
  }

  /// Проверить, является ли версия более новой
  bool _isVersionNewer(String newVersion, String currentVersion) {
    try {
      final newParts = newVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();

      // Дополняем массивы нулями до одинаковой длины
      while (newParts.length < currentParts.length) {
        newParts.add(0);
      }
      while (currentParts.length < newParts.length) {
        currentParts.add(0);
      }

      for (var i = 0; i < newParts.length; i++) {
        if (newParts[i] > currentParts[i]) {
          return true;
        } else if (newParts[i] < currentParts[i]) {
          return false;
        }
      }

      return false; // Версии одинаковые
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка сравнения версий: $e');
      }
      return false;
    }
  }

  /// Создать версию приложения
  Future<String> createVersion({
    required String version,
    required String buildNumber,
    required String platform,
    required VersionType type,
    String? description,
    List<String>? features,
    List<String>? bugFixes,
    List<String>? breakingChanges,
    bool isForced = false,
    String? downloadUrl,
    String? releaseNotes,
    DateTime? expirationDate,
    Map<String, dynamic>? metadata,
    String? createdBy,
  }) async {
    try {
      final versionId = _uuid.v4();
      final now = DateTime.now();

      final appVersion = AppVersion(
        id: versionId,
        version: version,
        buildNumber: buildNumber,
        platform: platform,
        type: type,
        description: description,
        features: features ?? [],
        bugFixes: bugFixes ?? [],
        breakingChanges: breakingChanges ?? [],
        isForced: isForced,
        downloadUrl: downloadUrl,
        releaseNotes: releaseNotes,
        expirationDate: expirationDate,
        metadata: metadata ?? {},
        createdBy: createdBy,
        releaseDate: now,
      );

      await _firestore
          .collection('appVersions')
          .doc(versionId)
          .set(appVersion.toMap());
      _versionsCache[versionId] = appVersion;

      if (kDebugMode) {
        debugPrint('Version created: $version ($buildNumber) for $platform');
      }

      return versionId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка создания версии: $e');
      }
      rethrow;
    }
  }

  /// Обновить версию
  Future<void> updateVersion(
      String versionId, AppVersion updatedVersion,) async {
    try {
      await _firestore
          .collection('appVersions')
          .doc(versionId)
          .update(updatedVersion.toMap());
      _versionsCache[versionId] = updatedVersion;

      if (kDebugMode) {
        debugPrint('Version updated: ${updatedVersion.version}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка обновления версии: $e');
      }
      rethrow;
    }
  }

  /// Активировать версию
  Future<void> activateVersion(String versionId, {String? activatedBy}) async {
    try {
      final version = _versionsCache[versionId];
      if (version == null) {
        throw Exception('Версия не найдена');
      }

      // Деактивируем все версии того же типа и платформы
      final sameTypeVersions = _versionsCache.values
          .where((v) =>
              v.platform == version.platform &&
              v.type == version.type &&
              v.isAvailable,)
          .toList();

      for (final v in sameTypeVersions) {
        await _firestore
            .collection('appVersions')
            .doc(v.id)
            .update({'isAvailable': false});

        _versionsCache[v.id] = v.copyWith(isAvailable: false);
      }

      // Активируем выбранную версию
      await _firestore
          .collection('appVersions')
          .doc(versionId)
          .update({'isAvailable': true});

      _versionsCache[versionId] = version.copyWith(isAvailable: true);

      if (kDebugMode) {
        debugPrint('Version activated: ${version.version}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка активации версии: $e');
      }
      rethrow;
    }
  }

  /// Начать обновление приложения
  Future<String> startUpdate({
    required String targetVersion,
    String? userId,
    String? deviceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (_currentVersion == null || _currentPlatform == null) {
        throw Exception('Не удалось определить текущую версию');
      }

      final updateId = _uuid.v4();
      final now = DateTime.now();

      final appUpdate = AppUpdate(
        id: updateId,
        currentVersion: _currentVersion!,
        targetVersion: targetVersion,
        platform: _currentPlatform!,
        userId: userId,
        deviceId: deviceId,
        metadata: metadata ?? {},
        startedAt: now,
      );

      await _firestore
          .collection('appUpdates')
          .doc(updateId)
          .set(appUpdate.toMap());
      _updatesCache[updateId] = appUpdate;

      if (kDebugMode) {
        debugPrint('Update started: $_currentVersion -> $targetVersion');
      }

      return updateId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка начала обновления: $e');
      }
      rethrow;
    }
  }

  /// Обновить прогресс обновления
  Future<void> updateProgress(String updateId, double progress,
      {UpdateStatus? status,}) async {
    try {
      final update = _updatesCache[updateId];
      if (update == null) {
        throw Exception('Обновление не найдено');
      }

      final updatedUpdate =
          update.copyWith(progress: progress, status: status ?? update.status);

      await _firestore.collection('appUpdates').doc(updateId).update({
        'progress': progress,
        if (status != null) 'status': status.toString().split('.').last,
      });

      _updatesCache[updateId] = updatedUpdate;

      if (kDebugMode) {
        debugPrint('Update progress: $updateId - ${(progress * 100).toInt()}%');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка обновления прогресса: $e');
      }
    }
  }

  /// Завершить обновление
  Future<void> completeUpdate(String updateId,
      {bool success = true, String? errorMessage,}) async {
    try {
      final update = _updatesCache[updateId];
      if (update == null) {
        throw Exception('Обновление не найдено');
      }

      final status = success ? UpdateStatus.completed : UpdateStatus.failed;
      final updatedUpdate = update.copyWith(
        status: status,
        errorMessage: errorMessage,
        completedAt: DateTime.now(),
      );

      await _firestore.collection('appUpdates').doc(updateId).update({
        'status': status.toString().split('.').last,
        'completedAt': Timestamp.fromDate(DateTime.now()),
        if (errorMessage != null) 'errorMessage': errorMessage,
      });

      _updatesCache[updateId] = updatedUpdate;

      if (kDebugMode) {
        debugPrint(
            'Update completed: $updateId - ${success ? 'success' : 'failed'}',);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка завершения обновления: $e');
      }
    }
  }

  /// Получить версии по платформе
  List<AppVersion> getVersionsByPlatform(String platform) =>
      _versionsCache.values
          .where((version) => version.platform == platform)
          .toList()
        ..sort((a, b) => b.releaseDate.compareTo(a.releaseDate));

  /// Получить версии по типу
  List<AppVersion> getVersionsByType(VersionType type) =>
      _versionsCache.values.where((version) => version.type == type).toList()
        ..sort((a, b) => b.releaseDate.compareTo(a.releaseDate));

  /// Получить доступные версии
  List<AppVersion> getAvailableVersions() => _versionsCache.values
      .where((version) => version.isCurrentlyAvailable)
      .toList()
    ..sort((a, b) => b.releaseDate.compareTo(a.releaseDate));

  /// Получить обновления пользователя
  List<AppUpdate> getUserUpdates(String userId) =>
      _updatesCache.values.where((update) => update.userId == userId).toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  /// Получить статистику версии
  VersionStatistics? getVersionStatistics(String version, String platform) {
    final key = '${version}_$platform';
    return _statisticsCache[key];
  }

  /// Обновить статистику версии
  Future<void> updateVersionStatistics({
    required String version,
    required String platform,
    required int totalUsers,
    required int activeUsers,
    required int crashCount,
    required double crashRate,
    required double averageSessionDuration,
    required int totalSessions,
  }) async {
    try {
      final key = '${version}_$platform';
      final now = DateTime.now();

      final statistics = VersionStatistics(
        version: version,
        platform: platform,
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        crashCount: crashCount,
        crashRate: crashRate,
        averageSessionDuration: averageSessionDuration,
        totalSessions: totalSessions,
        lastUpdated: now,
      );

      await _firestore
          .collection('versionStatistics')
          .doc(key)
          .set(statistics.toMap());
      _statisticsCache[key] = statistics;

      if (kDebugMode) {
        debugPrint('Version statistics updated: $version ($platform)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка обновления статистики версии: $e');
      }
    }
  }

  /// Получить текущую версию
  String? get currentVersion => _currentVersion;

  /// Получить текущий номер сборки
  String? get currentBuildNumber => _currentBuildNumber;

  /// Получить текущую платформу
  String? get currentPlatform => _currentPlatform;

  /// Получить информацию о пакете
  PackageInfo? get packageInfo => _packageInfo;

  /// Получить все версии
  List<AppVersion> getAllVersions() => _versionsCache.values.toList()
    ..sort((a, b) => b.releaseDate.compareTo(a.releaseDate));

  /// Получить все обновления
  List<AppUpdate> getAllUpdates() => _updatesCache.values.toList()
    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  /// Получить всю статистику
  List<VersionStatistics> getAllStatistics() => _statisticsCache.values.toList()
    ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

  /// Загрузить кэш версий
  Future<void> _loadVersionsCache() async {
    try {
      final snapshot = await _firestore.collection('appVersions').get();

      for (final doc in snapshot.docs) {
        final version = AppVersion.fromDocument(doc);
        _versionsCache[version.id] = version;
      }

      if (kDebugMode) {
        debugPrint('Loaded ${_versionsCache.length} versions');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка загрузки кэша версий: $e');
      }
    }
  }

  /// Загрузить кэш обновлений
  Future<void> _loadUpdatesCache() async {
    try {
      final snapshot =
          await _firestore.collection('appUpdates').limit(1000).get();

      for (final doc in snapshot.docs) {
        final update = AppUpdate.fromDocument(doc);
        _updatesCache[update.id] = update;
      }

      if (kDebugMode) {
        debugPrint('Loaded ${_updatesCache.length} updates');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка загрузки кэша обновлений: $e');
      }
    }
  }

  /// Загрузить кэш статистики
  Future<void> _loadStatisticsCache() async {
    try {
      final snapshot = await _firestore.collection('versionStatistics').get();

      for (final doc in snapshot.docs) {
        final statistics = VersionStatistics.fromDocument(doc);
        final key = '${statistics.version}_${statistics.platform}';
        _statisticsCache[key] = statistics;
      }

      if (kDebugMode) {
        debugPrint('Loaded ${_statisticsCache.length} statistics');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка загрузки кэша статистики: $e');
      }
    }
  }

  /// Закрыть сервис
  void dispose() {
    _versionsCache.clear();
    _updatesCache.clear();
    _statisticsCache.clear();
  }
}
