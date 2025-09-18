import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../models/release_management.dart';
import '../core/feature_flags.dart';

/// Сервис для управления релизами
class ReleaseManagementService {
  static final ReleaseManagementService _instance =
      ReleaseManagementService._internal();
  factory ReleaseManagementService() => _instance;
  ReleaseManagementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // Коллекции
  static const String _releasesCollection = 'releases';
  static const String _plansCollection = 'release_plans';
  static const String _deploymentsCollection = 'deployments';

  // Потоки для real-time обновлений
  final StreamController<Release> _releaseStreamController =
      StreamController<Release>.broadcast();
  final StreamController<ReleasePlan> _planStreamController =
      StreamController<ReleasePlan>.broadcast();
  final StreamController<Deployment> _deploymentStreamController =
      StreamController<Deployment>.broadcast();

  // Кэш данных
  final Map<String, Release> _releaseCache = {};
  final Map<String, ReleasePlan> _planCache = {};
  final Map<String, Deployment> _deploymentCache = {};

  bool _isInitialized = false;

  /// Инициализация сервиса
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadReleases();
      await _loadPlans();
      await _loadDeployments();
      _isInitialized = true;
    } catch (e) {
      await _crashlytics.recordError(e, null, fatal: true);
      rethrow;
    }
  }

  /// Загрузка релизов
  Future<void> _loadReleases() async {
    try {
      final snapshot = await _firestore
          .collection(_releasesCollection)
          .orderBy('createdAt', descending: true)
          .get();

      for (final doc in snapshot.docs) {
        final release = Release.fromMap(doc.data());
        _releaseCache[release.id] = release;
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Загрузка планов
  Future<void> _loadPlans() async {
    try {
      final snapshot = await _firestore.collection(_plansCollection).get();

      for (final doc in snapshot.docs) {
        final plan = ReleasePlan.fromMap(doc.data());
        _planCache[plan.id] = plan;
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Загрузка деплоев
  Future<void> _loadDeployments() async {
    try {
      final snapshot =
          await _firestore.collection(_deploymentsCollection).get();

      for (final doc in snapshot.docs) {
        final deployment = Deployment.fromMap(doc.data());
        _deploymentCache[deployment.id] = deployment;
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Поток релизов
  Stream<Release> get releaseStream => _releaseStreamController.stream;

  /// Поток планов
  Stream<ReleasePlan> get planStream => _planStreamController.stream;

  /// Поток деплоев
  Stream<Deployment> get deploymentStream => _deploymentStreamController.stream;

  /// Создание релиза
  Future<Release> createRelease({
    required String version,
    required String name,
    String? description,
    required ReleaseType type,
    String? branch,
    String? commitHash,
    List<String>? features,
    List<String>? bugFixes,
    List<String>? breakingChanges,
    List<String>? dependencies,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    bool isPreRelease = false,
    bool isDraft = true,
    String? releaseNotes,
    DateTime? scheduledDate,
  }) async {
    if (!FeatureFlags.releaseManagementEnabled) {
      throw Exception('Release management is disabled');
    }

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final release = Release(
        id: _generateId(),
        version: version,
        name: name,
        description: description,
        type: type,
        status: ReleaseStatus.draft,
        branch: branch,
        commitHash: commitHash,
        features: features ?? [],
        bugFixes: bugFixes ?? [],
        breakingChanges: breakingChanges ?? [],
        dependencies: dependencies ?? [],
        metadata: metadata ?? {},
        tags: tags ?? [],
        isPreRelease: isPreRelease,
        isDraft: isDraft,
        releaseNotes: releaseNotes,
        scheduledDate: scheduledDate,
        createdAt: now,
        updatedAt: now,
        createdBy: user.uid,
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_releasesCollection)
          .doc(release.id)
          .set(release.toMap());

      _releaseCache[release.id] = release;
      _releaseStreamController.add(release);

      return release;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Обновление релиза
  Future<Release> updateRelease({
    required String id,
    String? version,
    String? name,
    String? description,
    ReleaseType? type,
    ReleaseStatus? status,
    String? branch,
    String? commitHash,
    List<String>? features,
    List<String>? bugFixes,
    List<String>? breakingChanges,
    List<String>? dependencies,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    bool? isPreRelease,
    bool? isDraft,
    String? releaseNotes,
    String? downloadUrl,
    String? changelogUrl,
    DateTime? scheduledDate,
    DateTime? releasedDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final existingRelease = _releaseCache[id];
      if (existingRelease == null) throw Exception('Release not found');

      final now = DateTime.now();
      final updatedRelease = existingRelease.copyWith(
        version: version,
        name: name,
        description: description,
        type: type,
        status: status,
        branch: branch,
        commitHash: commitHash,
        features: features,
        bugFixes: bugFixes,
        breakingChanges: breakingChanges,
        dependencies: dependencies,
        metadata: metadata,
        tags: tags,
        isPreRelease: isPreRelease,
        isDraft: isDraft,
        releaseNotes: releaseNotes,
        downloadUrl: downloadUrl,
        changelogUrl: changelogUrl,
        scheduledDate: scheduledDate,
        releasedDate: releasedDate,
        updatedAt: now,
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_releasesCollection)
          .doc(id)
          .update(updatedRelease.toMap());

      _releaseCache[id] = updatedRelease;
      _releaseStreamController.add(updatedRelease);

      return updatedRelease;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Получение релиза
  Release? getRelease(String id) {
    return _releaseCache[id];
  }

  /// Получение всех релизов
  List<Release> getAllReleases() {
    return _releaseCache.values.toList();
  }

  /// Получение релизов по типу
  List<Release> getReleasesByType(ReleaseType type) {
    return _releaseCache.values
        .where((release) => release.type == type)
        .toList();
  }

  /// Получение релизов по статусу
  List<Release> getReleasesByStatus(ReleaseStatus status) {
    return _releaseCache.values
        .where((release) => release.status == status)
        .toList();
  }

  /// Получение последнего релиза
  Release? getLatestRelease() {
    final releases = _releaseCache.values
        .where((release) => release.status == ReleaseStatus.released)
        .toList();

    if (releases.isEmpty) return null;

    releases.sort((a, b) =>
        b.releasedDate?.compareTo(a.releasedDate ?? DateTime(1970)) ?? 0);
    return releases.first;
  }

  /// Создание плана релиза
  Future<ReleasePlan> createReleasePlan({
    required String name,
    required String description,
    required String version,
    required ReleaseType type,
    List<String>? releaseIds,
    List<String>? milestones,
    Map<String, dynamic>? requirements,
    DateTime? targetDate,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final plan = ReleasePlan(
        id: _generateId(),
        name: name,
        description: description,
        version: version,
        type: type,
        releaseIds: releaseIds ?? [],
        milestones: milestones ?? [],
        requirements: requirements ?? {},
        targetDate: targetDate,
        status: PlanStatus.draft,
        notes: notes,
        createdAt: now,
        updatedAt: now,
        createdBy: user.uid,
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_plansCollection)
          .doc(plan.id)
          .set(plan.toMap());

      _planCache[plan.id] = plan;
      _planStreamController.add(plan);

      return plan;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Обновление плана релиза
  Future<ReleasePlan> updateReleasePlan({
    required String id,
    String? name,
    String? description,
    String? version,
    ReleaseType? type,
    List<String>? releaseIds,
    List<String>? milestones,
    Map<String, dynamic>? requirements,
    DateTime? targetDate,
    DateTime? actualDate,
    PlanStatus? status,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final existingPlan = _planCache[id];
      if (existingPlan == null) throw Exception('Plan not found');

      final updatedPlan = existingPlan.copyWith(
        name: name,
        description: description,
        version: version,
        type: type,
        releaseIds: releaseIds,
        milestones: milestones,
        requirements: requirements,
        targetDate: targetDate,
        actualDate: actualDate,
        status: status,
        notes: notes,
        updatedAt: DateTime.now(),
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_plansCollection)
          .doc(id)
          .update(updatedPlan.toMap());

      _planCache[id] = updatedPlan;
      _planStreamController.add(updatedPlan);

      return updatedPlan;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Получение плана
  ReleasePlan? getPlan(String id) {
    return _planCache[id];
  }

  /// Получение всех планов
  List<ReleasePlan> getAllPlans() {
    return _planCache.values.toList();
  }

  /// Получение планов по статусу
  List<ReleasePlan> getPlansByStatus(PlanStatus status) {
    return _planCache.values.where((plan) => plan.status == status).toList();
  }

  /// Создание деплоя
  Future<Deployment> createDeployment({
    required String releaseId,
    required String environment,
    Map<String, dynamic>? config,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final deployment = Deployment(
        id: _generateId(),
        releaseId: releaseId,
        environment: environment,
        status: DeploymentStatus.pending,
        config: config ?? {},
        logs: [],
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
      _deploymentStreamController.add(deployment);

      return deployment;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Обновление деплоя
  Future<Deployment> updateDeployment({
    required String id,
    DeploymentStatus? status,
    String? buildUrl,
    String? deployUrl,
    Map<String, dynamic>? config,
    List<String>? logs,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final existingDeployment = _deploymentCache[id];
      if (existingDeployment == null) throw Exception('Deployment not found');

      final updatedDeployment = existingDeployment.copyWith(
        status: status,
        buildUrl: buildUrl,
        deployUrl: deployUrl,
        config: config,
        logs: logs,
        startedAt: startedAt,
        completedAt: completedAt,
        errorMessage: errorMessage,
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

  /// Получение деплоя
  Deployment? getDeployment(String id) {
    return _deploymentCache[id];
  }

  /// Получение всех деплоев
  List<Deployment> getAllDeployments() {
    return _deploymentCache.values.toList();
  }

  /// Получение деплоев по релизу
  List<Deployment> getDeploymentsByRelease(String releaseId) {
    return _deploymentCache.values
        .where((deployment) => deployment.releaseId == releaseId)
        .toList();
  }

  /// Получение деплоев по окружению
  List<Deployment> getDeploymentsByEnvironment(String environment) {
    return _deploymentCache.values
        .where((deployment) => deployment.environment == environment)
        .toList();
  }

  /// Получение деплоев по статусу
  List<Deployment> getDeploymentsByStatus(DeploymentStatus status) {
    return _deploymentCache.values
        .where((deployment) => deployment.status == status)
        .toList();
  }

  /// Запуск деплоя
  Future<Deployment> startDeployment(String deploymentId) async {
    try {
      final deployment = _deploymentCache[deploymentId];
      if (deployment == null) throw Exception('Deployment not found');

      final now = DateTime.now();
      final updatedDeployment = deployment.copyWith(
        status: DeploymentStatus.inProgress,
        startedAt: now,
        updatedAt: now,
        updatedBy: _auth.currentUser?.uid ?? '',
      );

      await _firestore
          .collection(_deploymentsCollection)
          .doc(deploymentId)
          .update({
        'status': DeploymentStatus.inProgress.value,
        'startedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'updatedBy': _auth.currentUser?.uid ?? '',
      });

      _deploymentCache[deploymentId] = updatedDeployment;
      _deploymentStreamController.add(updatedDeployment);

      // Имитируем процесс деплоя
      _simulateDeployment(deploymentId);

      return updatedDeployment;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Имитация деплоя
  Future<void> _simulateDeployment(String deploymentId) async {
    try {
      await Future.delayed(const Duration(seconds: 3));

      final deployment = _deploymentCache[deploymentId];
      if (deployment == null) return;

      final now = DateTime.now();
      final updatedDeployment = deployment.copyWith(
        status: DeploymentStatus.completed,
        completedAt: now,
        updatedAt: now,
        updatedBy: _auth.currentUser?.uid ?? '',
      );

      await _firestore
          .collection(_deploymentsCollection)
          .doc(deploymentId)
          .update({
        'status': DeploymentStatus.completed.value,
        'completedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'updatedBy': _auth.currentUser?.uid ?? '',
      });

      _deploymentCache[deploymentId] = updatedDeployment;
      _deploymentStreamController.add(updatedDeployment);
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Анализ релизов
  Future<Map<String, dynamic>> analyzeReleases() async {
    try {
      final releases = _releaseCache.values;
      final plans = _planCache.values;
      final deployments = _deploymentCache.values;

      return {
        'releases': {
          'total': releases.length,
          'byType': _groupReleasesByType(releases),
          'byStatus': _groupReleasesByStatus(releases),
          'released':
              releases.where((r) => r.status == ReleaseStatus.released).length,
          'draft':
              releases.where((r) => r.status == ReleaseStatus.draft).length,
          'scheduled':
              releases.where((r) => r.status == ReleaseStatus.scheduled).length,
        },
        'plans': {
          'total': plans.length,
          'byStatus': _groupPlansByStatus(plans),
          'active': plans.where((p) => p.status == PlanStatus.active).length,
          'completed':
              plans.where((p) => p.status == PlanStatus.completed).length,
        },
        'deployments': {
          'total': deployments.length,
          'byStatus': _groupDeploymentsByStatus(deployments),
          'byEnvironment': _groupDeploymentsByEnvironment(deployments),
          'successful': deployments
              .where((d) => d.status == DeploymentStatus.completed)
              .length,
          'failed': deployments
              .where((d) => d.status == DeploymentStatus.failed)
              .length,
        },
      };
    } catch (e) {
      await _crashlytics.recordError(e, null);
      return {};
    }
  }

  /// Группировка релизов по типу
  Map<String, int> _groupReleasesByType(List<Release> releases) {
    final Map<String, int> groups = {};
    for (final release in releases) {
      groups[release.type.value] = (groups[release.type.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка релизов по статусу
  Map<String, int> _groupReleasesByStatus(List<Release> releases) {
    final Map<String, int> groups = {};
    for (final release in releases) {
      groups[release.status.value] = (groups[release.status.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка планов по статусу
  Map<String, int> _groupPlansByStatus(List<ReleasePlan> plans) {
    final Map<String, int> groups = {};
    for (final plan in plans) {
      groups[plan.status.value] = (groups[plan.status.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка деплоев по статусу
  Map<String, int> _groupDeploymentsByStatus(List<Deployment> deployments) {
    final Map<String, int> groups = {};
    for (final deployment in deployments) {
      groups[deployment.status.value] =
          (groups[deployment.status.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка деплоев по окружению
  Map<String, int> _groupDeploymentsByEnvironment(
      List<Deployment> deployments) {
    final Map<String, int> groups = {};
    for (final deployment in deployments) {
      groups[deployment.environment] =
          (groups[deployment.environment] ?? 0) + 1;
    }
    return groups;
  }

  /// Экспорт релизов
  Future<String> exportReleases({String format = 'json'}) async {
    try {
      final releases = _releaseCache.values;
      final plans = _planCache.values;
      final deployments = _deploymentCache.values;

      final exportData = {
        'releases': releases.map((r) => r.toMap()).toList(),
        'plans': plans.map((p) => p.toMap()).toList(),
        'deployments': deployments.map((d) => d.toMap()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
      };

      if (format == 'json') {
        return jsonEncode(exportData);
      } else if (format == 'csv') {
        return _convertToCSV(exportData);
      } else {
        throw ArgumentError('Unsupported format: $format');
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Конвертация в CSV
  String _convertToCSV(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    // Заголовки для релизов
    buffer.writeln('Releases:');
    buffer.writeln('Version,Name,Type,Status,Released Date');

    for (final release in data['releases']) {
      buffer.writeln(
          '${release['version']},${release['name']},${release['type']},${release['status']},${release['releasedDate'] ?? 'N/A'}');
    }

    return buffer.toString();
  }

  /// Генерация уникального ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (1000 + (9999 - 1000) * (DateTime.now().microsecond / 1000000))
            .round()
            .toString();
  }

  /// Закрытие сервиса
  Future<void> dispose() async {
    await _releaseStreamController.close();
    await _planStreamController.close();
    await _deploymentStreamController.close();
  }
}
