import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/core/feature_flags.dart';
import 'package:event_marketplace_app/models/kpi_metrics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Сервис для управления KPI метриками
class KPIMetricsService {
  factory KPIMetricsService() => _instance;
  KPIMetricsService._internal();
  static final KPIMetricsService _instance = KPIMetricsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // Коллекции
  static const String _metricsCollection = 'kpi_metrics';
  static const String _dashboardsCollection = 'kpi_dashboards';
  static const String _reportsCollection = 'kpi_reports';

  // Потоки для real-time обновлений
  final StreamController<KPIMetric> _metricStreamController =
      StreamController<KPIMetric>.broadcast();
  final StreamController<KPIDashboard> _dashboardStreamController =
      StreamController<KPIDashboard>.broadcast();
  final StreamController<KPIReport> _reportStreamController =
      StreamController<KPIReport>.broadcast();

  // Кэш данных
  final Map<String, KPIMetric> _metricCache = {};
  final Map<String, KPIDashboard> _dashboardCache = {};
  final Map<String, KPIReport> _reportCache = {};

  bool _isInitialized = false;

  /// Инициализация сервиса
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadMetrics();
      await _loadDashboards();
      await _loadReports();
      _isInitialized = true;
    } catch (e) {
      await _crashlytics.recordError(e, null, fatal: true);
      rethrow;
    }
  }

  /// Загрузка метрик
  Future<void> _loadMetrics() async {
    try {
      final snapshot = await _firestore
          .collection(_metricsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in snapshot.docs) {
        final metric = KPIMetric.fromMap(doc.data());
        _metricCache[metric.id] = metric;
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Загрузка дашбордов
  Future<void> _loadDashboards() async {
    try {
      final snapshot = await _firestore.collection(_dashboardsCollection).get();

      for (final doc in snapshot.docs) {
        final dashboard = KPIDashboard.fromMap(doc.data());
        _dashboardCache[dashboard.id] = dashboard;
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Загрузка отчетов
  Future<void> _loadReports() async {
    try {
      final snapshot = await _firestore.collection(_reportsCollection).get();

      for (final doc in snapshot.docs) {
        final report = KPIReport.fromMap(doc.data());
        _reportCache[report.id] = report;
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Поток метрик
  Stream<KPIMetric> get metricStream => _metricStreamController.stream;

  /// Поток дашбордов
  Stream<KPIDashboard> get dashboardStream => _dashboardStreamController.stream;

  /// Поток отчетов
  Stream<KPIReport> get reportStream => _reportStreamController.stream;

  /// Создание метрики
  Future<KPIMetric> createMetric({
    required String name,
    required String description,
    required MetricType type,
    required MetricCategory category,
    required String unit,
    required double value,
    double? target,
    String? dataSource,
    Map<String, dynamic>? metadata,
    List<String>? tags,
  }) async {
    if (!FeatureFlags.kpiMetricsEnabled) {
      throw Exception('KPI metrics are disabled');
    }

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final metric = KPIMetric(
        id: _generateId(),
        name: name,
        description: description,
        type: type,
        category: category,
        unit: unit,
        value: value,
        target: target,
        status: _calculateStatus(value, target),
        timestamp: now,
        lastUpdated: now,
        dataSource: dataSource,
        metadata: metadata ?? {},
        tags: tags ?? [],
        isActive: true,
        createdBy: user.uid,
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_metricsCollection)
          .doc(metric.id)
          .set(metric.toMap());

      _metricCache[metric.id] = metric;
      _metricStreamController.add(metric);

      return metric;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Обновление метрики
  Future<KPIMetric> updateMetric({
    required String id,
    String? name,
    String? description,
    MetricType? type,
    MetricCategory? category,
    String? unit,
    double? value,
    double? target,
    String? dataSource,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    bool? isActive,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final existingMetric = _metricCache[id];
      if (existingMetric == null) throw Exception('Metric not found');

      final now = DateTime.now();
      final updatedMetric = existingMetric.copyWith(
        name: name,
        description: description,
        type: type,
        category: category,
        unit: unit,
        value: value,
        target: target,
        previousValue:
            value != null ? existingMetric.value : existingMetric.previousValue,
        change: value != null
            ? value - existingMetric.value
            : existingMetric.change,
        changePercentage: value != null && existingMetric.value != 0
            ? ((value - existingMetric.value) / existingMetric.value) * 100
            : existingMetric.changePercentage,
        status: value != null
            ? _calculateStatus(value, target ?? existingMetric.target)
            : existingMetric.status,
        lastUpdated: now,
        dataSource: dataSource,
        metadata: metadata,
        tags: tags,
        isActive: isActive,
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_metricsCollection)
          .doc(id)
          .update(updatedMetric.toMap());

      _metricCache[id] = updatedMetric;
      _metricStreamController.add(updatedMetric);

      return updatedMetric;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Получение метрики
  KPIMetric? getMetric(String id) => _metricCache[id];

  /// Получение всех метрик
  List<KPIMetric> getAllMetrics() => _metricCache.values.toList();

  /// Получение метрик по категории
  List<KPIMetric> getMetricsByCategory(MetricCategory category) =>
      _metricCache.values
          .where((metric) => metric.category == category)
          .toList();

  /// Получение метрик по типу
  List<KPIMetric> getMetricsByType(MetricType type) =>
      _metricCache.values.where((metric) => metric.type == type).toList();

  /// Получение метрик по статусу
  List<KPIMetric> getMetricsByStatus(MetricStatus status) =>
      _metricCache.values.where((metric) => metric.status == status).toList();

  /// Создание дашборда
  Future<KPIDashboard> createDashboard({
    required String name,
    required String description,
    required List<String> metricIds,
    required DashboardLayout layout,
    List<String>? tags,
    bool isPublic = false,
    bool isDefault = false,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final dashboard = KPIDashboard(
        id: _generateId(),
        name: name,
        description: description,
        metricIds: metricIds,
        layout: layout,
        tags: tags ?? [],
        isPublic: isPublic,
        isDefault: isDefault,
        settings: settings ?? {},
        createdAt: now,
        updatedAt: now,
        createdBy: user.uid,
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_dashboardsCollection)
          .doc(dashboard.id)
          .set(dashboard.toMap());

      _dashboardCache[dashboard.id] = dashboard;
      _dashboardStreamController.add(dashboard);

      return dashboard;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Обновление дашборда
  Future<KPIDashboard> updateDashboard({
    required String id,
    String? name,
    String? description,
    List<String>? metricIds,
    DashboardLayout? layout,
    List<String>? tags,
    bool? isPublic,
    bool? isDefault,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final existingDashboard = _dashboardCache[id];
      if (existingDashboard == null) throw Exception('Dashboard not found');

      final updatedDashboard = existingDashboard.copyWith(
        name: name,
        description: description,
        metricIds: metricIds,
        layout: layout,
        tags: tags,
        isPublic: isPublic,
        isDefault: isDefault,
        settings: settings,
        updatedAt: DateTime.now(),
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_dashboardsCollection)
          .doc(id)
          .update(updatedDashboard.toMap());

      _dashboardCache[id] = updatedDashboard;
      _dashboardStreamController.add(updatedDashboard);

      return updatedDashboard;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Получение дашборда
  KPIDashboard? getDashboard(String id) => _dashboardCache[id];

  /// Получение всех дашбордов
  List<KPIDashboard> getAllDashboards() => _dashboardCache.values.toList();

  /// Получение публичных дашбордов
  List<KPIDashboard> getPublicDashboards() =>
      _dashboardCache.values.where((dashboard) => dashboard.isPublic).toList();

  /// Получение дашборда по умолчанию
  KPIDashboard? getDefaultDashboard() => _dashboardCache.values
      .where((dashboard) => dashboard.isDefault)
      .firstOrNull;

  /// Создание отчета
  Future<KPIReport> createReport({
    required String name,
    required String description,
    required ReportType type,
    required List<String> metricIds,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? dashboardIds,
    String? template,
    Map<String, dynamic>? filters,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final report = KPIReport(
        id: _generateId(),
        name: name,
        description: description,
        type: type,
        metricIds: metricIds,
        dashboardIds: dashboardIds ?? [],
        startDate: startDate,
        endDate: endDate,
        template: template,
        filters: filters ?? {},
        settings: settings ?? {},
        status: ReportStatus.draft,
        createdAt: now,
        updatedAt: now,
        createdBy: user.uid,
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_reportsCollection)
          .doc(report.id)
          .set(report.toMap());

      _reportCache[report.id] = report;
      _reportStreamController.add(report);

      return report;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Генерация отчета
  Future<KPIReport> generateReport(String reportId) async {
    try {
      final report = _reportCache[reportId];
      if (report == null) throw Exception('Report not found');

      // Обновляем статус на "генерируется"
      final generatingReport = report.copyWith(
        status: ReportStatus.generating,
        updatedAt: DateTime.now(),
        updatedBy: _auth.currentUser?.uid ?? '',
      );

      await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .update(generatingReport.toMap());

      _reportCache[reportId] = generatingReport;
      _reportStreamController.add(generatingReport);

      // Имитируем генерацию отчета
      await Future.delayed(const Duration(seconds: 2));

      // Обновляем статус на "готов"
      final readyReport = generatingReport.copyWith(
        status: ReportStatus.ready,
        fileUrl: 'https://example.com/reports/$reportId.pdf',
        updatedAt: DateTime.now(),
        updatedBy: _auth.currentUser?.uid ?? '',
      );

      await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .update(readyReport.toMap());

      _reportCache[reportId] = readyReport;
      _reportStreamController.add(readyReport);

      return readyReport;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Получение отчета
  KPIReport? getReport(String id) => _reportCache[id];

  /// Получение всех отчетов
  List<KPIReport> getAllReports() => _reportCache.values.toList();

  /// Получение отчетов по статусу
  List<KPIReport> getReportsByStatus(ReportStatus status) =>
      _reportCache.values.where((report) => report.status == status).toList();

  /// Анализ метрик
  Future<Map<String, dynamic>> analyzeMetrics() async {
    try {
      final metrics = _metricCache.values;
      final dashboards = _dashboardCache.values;
      final reports = _reportCache.values;

      return {
        'metrics': {
          'total': metrics.length,
          'byCategory': _groupMetricsByCategory(metrics),
          'byType': _groupMetricsByType(metrics),
          'byStatus': _groupMetricsByStatus(metrics),
          'averageValue': metrics.isNotEmpty
              ? metrics.map((m) => m.value).reduce((a, b) => a + b) /
                  metrics.length
              : 0.0,
          'targetsMet': metrics
              .where((m) => m.target != null && m.value >= m.target!)
              .length,
        },
        'dashboards': {
          'total': dashboards.length,
          'public': dashboards.where((d) => d.isPublic).length,
          'default': dashboards.where((d) => d.isDefault).length,
        },
        'reports': {
          'total': reports.length,
          'byStatus': _groupReportsByStatus(reports),
          'byType': _groupReportsByType(reports),
        },
      };
    } catch (e) {
      await _crashlytics.recordError(e, null);
      return {};
    }
  }

  /// Группировка метрик по категории
  Map<String, int> _groupMetricsByCategory(List<KPIMetric> metrics) {
    final groups = <String, int>{};
    for (final metric in metrics) {
      groups[metric.category.value] = (groups[metric.category.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка метрик по типу
  Map<String, int> _groupMetricsByType(List<KPIMetric> metrics) {
    final groups = <String, int>{};
    for (final metric in metrics) {
      groups[metric.type.value] = (groups[metric.type.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка метрик по статусу
  Map<String, int> _groupMetricsByStatus(List<KPIMetric> metrics) {
    final groups = <String, int>{};
    for (final metric in metrics) {
      groups[metric.status.value] = (groups[metric.status.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка отчетов по статусу
  Map<String, int> _groupReportsByStatus(List<KPIReport> reports) {
    final groups = <String, int>{};
    for (final report in reports) {
      groups[report.status.value] = (groups[report.status.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка отчетов по типу
  Map<String, int> _groupReportsByType(List<KPIReport> reports) {
    final groups = <String, int>{};
    for (final report in reports) {
      groups[report.type.value] = (groups[report.type.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Расчет статуса метрики
  MetricStatus _calculateStatus(double value, double? target) {
    if (target == null) return MetricStatus.normal;

    final percentage = (value / target) * 100;

    if (percentage >= 100) return MetricStatus.normal;
    if (percentage >= 80) return MetricStatus.warning;
    if (percentage >= 50) return MetricStatus.critical;
    return MetricStatus.error;
  }

  /// Экспорт метрик
  Future<String> exportMetrics({String format = 'json'}) async {
    try {
      final metrics = _metricCache.values;
      final dashboards = _dashboardCache.values;
      final reports = _reportCache.values;

      final exportData = {
        'metrics': metrics.map((m) => m.toMap()).toList(),
        'dashboards': dashboards.map((d) => d.toMap()).toList(),
        'reports': reports.map((r) => r.toMap()).toList(),
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

    // Заголовки для метрик
    buffer.writeln('Metrics:');
    buffer.writeln('Name,Type,Category,Value,Target,Status,Unit');

    for (final metric in data['metrics']) {
      buffer.writeln(
        '${metric['name']},${metric['type']},${metric['category']},${metric['value']},${metric['target'] ?? 'N/A'},${metric['status']},${metric['unit']}',
      );
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
    await _metricStreamController.close();
    await _dashboardStreamController.close();
    await _reportStreamController.close();
  }
}
