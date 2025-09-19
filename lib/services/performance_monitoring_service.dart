import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/performance_metric.dart';

/// Сервис мониторинга производительности
class PerformanceMonitoringService {
  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Uuid _uuid = const Uuid();

  static final PerformanceMonitoringService _instance =
      PerformanceMonitoringService._internal();

  Timer? _monitoringTimer;
  String? _currentSessionId;
  String? _currentUserId;
  String? _deviceId;
  final Map<String, double> _currentMetrics = {};
  final List<PerformanceAlert> _activeAlerts = [];

  /// Инициализация сервиса мониторинга
  Future<void> initialize() async {
    try {
      _deviceId = await _getDeviceId();
      _currentSessionId = _uuid.v4();

      // Запускаем мониторинг
      _startMonitoring();

      if (kDebugMode) {
        print('Performance monitoring initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка инициализации мониторинга производительности: $e');
      }
    }
  }

  /// Установить текущего пользователя
  void setUserId(String? userId) {
    _currentUserId = userId;
  }

  /// Запустить мониторинг
  void _startMonitoring() {
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _collectMetrics();
    });
  }

  /// Остановить мониторинг
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Собрать метрики производительности
  Future<void> _collectMetrics() async {
    try {
      final now = DateTime.now();

      // Собираем различные метрики
      await Future.wait([
        _collectMemoryMetrics(now),
        _collectCPUMetrics(now),
        _collectNetworkMetrics(now),
        _collectDatabaseMetrics(now),
        _collectUIMetrics(now),
      ]);

      // Проверяем алерты
      await _checkAlerts();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка сбора метрик: $e');
      }
    }
  }

  /// Собрать метрики памяти
  Future<void> _collectMemoryMetrics(DateTime timestamp) async {
    try {
      // Получаем информацию о памяти устройства
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        final totalMemory = androidInfo.totalMemory;
        final availableMemory = androidInfo.availableMemory;
        final usedMemory = totalMemory - availableMemory;

        await _recordMetric(
          name: 'memory_used',
          category: 'memory',
          value: usedMemory.toDouble(),
          unit: 'bytes',
          description: 'Используемая память',
          timestamp: timestamp,
          metadata: {
            'totalMemory': totalMemory,
            'availableMemory': availableMemory,
            'platform': 'android',
          },
        );

        await _recordMetric(
          name: 'memory_usage_percentage',
          category: 'memory',
          value: (usedMemory / totalMemory) * 100,
          unit: 'percentage',
          description: 'Процент использования памяти',
          timestamp: timestamp,
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;

        await _recordMetric(
          name: 'memory_available',
          category: 'memory',
          value: iosInfo.availableMemory.toDouble(),
          unit: 'bytes',
          description: 'Доступная память',
          timestamp: timestamp,
          metadata: {
            'platform': 'ios',
            'model': iosInfo.model,
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка сбора метрик памяти: $e');
      }
    }
  }

  /// Собрать метрики CPU
  Future<void> _collectCPUMetrics(DateTime timestamp) async {
    try {
      // Симуляция метрик CPU (в реальном приложении нужно использовать нативные плагины)
      final cpuUsage = _simulateCPUUsage();

      await _recordMetric(
        name: 'cpu_usage',
        category: 'cpu',
        value: cpuUsage,
        unit: 'percentage',
        description: 'Использование CPU',
        timestamp: timestamp,
        metadata: {
          'platform': defaultTargetPlatform.name,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка сбора метрик CPU: $e');
      }
    }
  }

  /// Собрать метрики сети
  Future<void> _collectNetworkMetrics(DateTime timestamp) async {
    try {
      // Симуляция метрик сети
      final networkLatency = _simulateNetworkLatency();

      await _recordMetric(
        name: 'network_latency',
        category: 'network',
        value: networkLatency,
        unit: 'ms',
        description: 'Задержка сети',
        timestamp: timestamp,
        metadata: {
          'connectionType':
              'wifi', // В реальном приложении получать из connectivity_plus
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка сбора метрик сети: $e');
      }
    }
  }

  /// Собрать метрики базы данных
  Future<void> _collectDatabaseMetrics(DateTime timestamp) async {
    try {
      // Симуляция метрик базы данных
      final queryTime = _simulateDatabaseQueryTime();

      await _recordMetric(
        name: 'database_query_time',
        category: 'database',
        value: queryTime,
        unit: 'ms',
        description: 'Время выполнения запроса к БД',
        timestamp: timestamp,
        metadata: {
          'queryType': 'read',
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка сбора метрик базы данных: $e');
      }
    }
  }

  /// Собрать метрики UI
  Future<void> _collectUIMetrics(DateTime timestamp) async {
    try {
      // Симуляция метрик UI
      final frameTime = _simulateFrameTime();

      await _recordMetric(
        name: 'frame_time',
        category: 'ui',
        value: frameTime,
        unit: 'ms',
        description: 'Время отрисовки кадра',
        timestamp: timestamp,
        metadata: {
          'fps': 1000 / frameTime,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка сбора метрик UI: $e');
      }
    }
  }

  /// Записать метрику
  Future<void> _recordMetric({
    required String name,
    required String category,
    required double value,
    required String unit,
    required String description,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final metric = PerformanceMetric(
        id: _uuid.v4(),
        name: name,
        category: category,
        value: value,
        unit: unit,
        description: description,
        metadata: metadata ?? {},
        timestamp: timestamp,
        sessionId: _currentSessionId,
        userId: _currentUserId,
        deviceId: _deviceId,
      );

      // Сохраняем в Firestore
      await _firestore.collection('performanceMetrics').add(metric.toMap());

      // Обновляем текущие метрики
      _currentMetrics[name] = value;

      if (kDebugMode) {
        print('Performance metric recorded: $name = ${metric.formattedValue}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка записи метрики: $e');
      }
    }
  }

  /// Проверить алерты
  Future<void> _checkAlerts() async {
    try {
      for (final entry in _currentMetrics.entries) {
        final metricName = entry.key;
        final value = entry.value;

        // Проверяем пороговые значения
        final threshold = _getThreshold(metricName);
        if (value > threshold) {
          await _createAlert(metricName, value, threshold);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка проверки алертов: $e');
      }
    }
  }

  /// Создать алерт
  Future<void> _createAlert(
    String metricName,
    double value,
    double threshold,
  ) async {
    try {
      // Проверяем, не создан ли уже алерт для этой метрики
      final existingAlert = _activeAlerts.firstWhere(
        (alert) => alert.metricName == metricName && alert.isActive,
        orElse: () => PerformanceAlert(
          id: '',
          metricName: '',
          category: '',
          threshold: 0,
          currentValue: 0,
          severity: AlertSeverity.info,
          message: '',
          triggeredAt: DateTime.now(),
        ),
      );

      if (existingAlert.id.isNotEmpty) return; // Алерт уже существует

      final severity = _getAlertSeverity(metricName, value, threshold);
      final message = _generateAlertMessage(metricName, value, threshold);

      final alert = PerformanceAlert(
        id: _uuid.v4(),
        metricName: metricName,
        category: _getMetricCategory(metricName),
        threshold: threshold,
        currentValue: value,
        severity: severity,
        message: message,
        triggeredAt: DateTime.now(),
        metadata: {
          'sessionId': _currentSessionId,
          'userId': _currentUserId,
          'deviceId': _deviceId,
        },
      );

      // Сохраняем алерт
      await _firestore.collection('performanceAlerts').add(alert.toMap());
      _activeAlerts.add(alert);

      if (kDebugMode) {
        print('Performance alert created: $message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка создания алерта: $e');
      }
    }
  }

  /// Получить пороговое значение для метрики
  double _getThreshold(String metricName) {
    switch (metricName) {
      case 'memory_used':
        return 100 * 1024 * 1024; // 100MB
      case 'memory_usage_percentage':
        return 80; // 80%
      case 'cpu_usage':
        return 80; // 80%
      case 'network_latency':
        return 1000; // 1s
      case 'database_query_time':
        return 500; // 500ms
      case 'frame_time':
        return 16; // 16ms (60fps)
      default:
        return 100;
    }
  }

  /// Получить серьезность алерта
  AlertSeverity _getAlertSeverity(
    String metricName,
    double value,
    double threshold,
  ) {
    final ratio = value / threshold;

    if (ratio > 2) return AlertSeverity.critical;
    if (ratio > 1.5) return AlertSeverity.error;
    if (ratio > 1.2) return AlertSeverity.warning;
    return AlertSeverity.info;
  }

  /// Сгенерировать сообщение алерта
  String _generateAlertMessage(
    String metricName,
    double value,
    double threshold,
  ) {
    final metric = PerformanceMetric(
      id: '',
      name: metricName,
      category: _getMetricCategory(metricName),
      value: value,
      unit: _getMetricUnit(metricName),
      timestamp: DateTime.now(),
    );

    return '${metric.formattedValue} превышает пороговое значение ${threshold.toStringAsFixed(0)}';
  }

  /// Получить категорию метрики
  String _getMetricCategory(String metricName) {
    if (metricName.contains('memory')) return 'memory';
    if (metricName.contains('cpu')) return 'cpu';
    if (metricName.contains('network')) return 'network';
    if (metricName.contains('database')) return 'database';
    if (metricName.contains('frame')) return 'ui';
    return 'general';
  }

  /// Получить единицу измерения метрики
  String _getMetricUnit(String metricName) {
    if (metricName.contains('memory')) return 'bytes';
    if (metricName.contains('percentage')) return 'percentage';
    if (metricName.contains('time') || metricName.contains('latency')) {
      return 'ms';
    }
    return 'count';
  }

  /// Симуляция использования CPU
  double _simulateCPUUsage() {
    // В реальном приложении получать из нативных плагинов
    return 20 + (DateTime.now().millisecond % 60);
  }

  /// Симуляция задержки сети
  double _simulateNetworkLatency() {
    // В реальном приложении измерять реальную задержку
    return 50 + (DateTime.now().millisecond % 100);
  }

  /// Симуляция времени запроса к БД
  double _simulateDatabaseQueryTime() {
    // В реальном приложении измерять реальное время запросов
    return 10 + (DateTime.now().millisecond % 50);
  }

  /// Симуляция времени отрисовки кадра
  double _simulateFrameTime() {
    // В реальном приложении получать из Flutter Performance
    return 8 + (DateTime.now().millisecond % 20);
  }

  /// Получить ID устройства
  Future<String> _getDeviceId() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      } else {
        return 'unknown';
      }
    } catch (e) {
      return 'unknown';
    }
  }

  /// Получить метрики за период
  Future<List<PerformanceMetric>> getMetrics({
    String? metricName,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var query = _firestore.collection('performanceMetrics');

      if (metricName != null) {
        query = query.where('name', isEqualTo: metricName);
      }
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (startDate != null) {
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          'timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      final snapshot =
          await query.orderBy('timestamp', descending: true).limit(limit).get();

      return snapshot.docs.map(PerformanceMetric.fromDocument).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения метрик: $e');
      }
      return [];
    }
  }

  /// Получить статистику метрики
  Future<PerformanceStatistics> getMetricStatistics(
    String metricName, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final metrics = await getMetrics(
        metricName: metricName,
        startDate: startDate,
        endDate: endDate,
        limit: 1000,
      );

      return PerformanceStatistics.fromMetrics(
        metricName,
        _getMetricCategory(metricName),
        metrics,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения статистики метрики: $e');
      }
      return PerformanceStatistics.fromMetrics(metricName, 'general', []);
    }
  }

  /// Получить активные алерты
  Future<List<PerformanceAlert>> getActiveAlerts() async {
    try {
      final snapshot = await _firestore
          .collection('performanceAlerts')
          .where('isActive', isEqualTo: true)
          .orderBy('triggeredAt', descending: true)
          .get();

      return snapshot.docs.map(PerformanceAlert.fromDocument).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения активных алертов: $e');
      }
      return [];
    }
  }

  /// Решить алерт
  Future<void> resolveAlert(String alertId) async {
    try {
      await _firestore.collection('performanceAlerts').doc(alertId).update({
        'isActive': false,
        'resolvedAt': Timestamp.fromDate(DateTime.now()),
      });

      _activeAlerts.removeWhere((alert) => alert.id == alertId);
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка решения алерта: $e');
      }
    }
  }

  /// Получить текущие метрики
  Map<String, double> getCurrentMetrics() => Map.from(_currentMetrics);

  /// Очистить старые метрики
  Future<void> cleanupOldMetrics({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final snapshot = await _firestore
          .collection('performanceMetrics')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка очистки старых метрик: $e');
      }
    }
  }

  /// Закрыть сервис
  void dispose() {
    stopMonitoring();
  }
}
