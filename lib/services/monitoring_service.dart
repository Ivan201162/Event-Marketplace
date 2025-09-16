import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:event_marketplace_app/services/logger_service.dart';

/// Сервис для мониторинга производительности и состояния приложения
class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();

  final LoggerService _logger = LoggerService();
  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, int> _operationCounts = {};
  final Map<String, Duration> _operationTotalTimes = {};
  final List<PerformanceMetric> _performanceMetrics = [];
  final List<ErrorMetric> _errorMetrics = [];
  final List<MemoryMetric> _memoryMetrics = [];

  Timer? _memoryMonitoringTimer;
  Timer? _performanceCleanupTimer;

  bool _isMonitoring = false;

  /// Начать мониторинг
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _logger.info('Starting application monitoring');

    // Запускаем мониторинг памяти каждые 30 секунд
    _memoryMonitoringTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _collectMemoryMetrics();
    });

    // Очищаем старые метрики каждые 5 минут
    _performanceCleanupTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _cleanupOldMetrics();
    });

    // Мониторим ошибки Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      _recordError('Flutter Error', details.exception, details.stack);
    };

    // Мониторим ошибки платформы
    PlatformDispatcher.instance.onError = (error, stack) {
      _recordError('Platform Error', error, stack);
      return true;
    };
  }

  /// Остановить мониторинг
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _logger.info('Stopping application monitoring');

    _memoryMonitoringTimer?.cancel();
    _performanceCleanupTimer?.cancel();
    _memoryMonitoringTimer = null;
    _performanceCleanupTimer = null;
  }

  /// Начать отслеживание операции
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
    _operationCounts[operationName] =
        (_operationCounts[operationName] ?? 0) + 1;

    _logger.debug('Started operation: $operationName', tag: 'MONITORING');
  }

  /// Завершить отслеживание операции
  void endOperation(String operationName, {Map<String, dynamic>? metadata}) {
    final startTime = _operationStartTimes.remove(operationName);
    if (startTime == null) {
      _logger.warning('Operation $operationName was not started',
          tag: 'MONITORING');
      return;
    }

    final duration = DateTime.now().difference(startTime);
    _operationTotalTimes[operationName] =
        (_operationTotalTimes[operationName] ?? Duration.zero) + duration;

    final metric = PerformanceMetric(
      operationName: operationName,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    _performanceMetrics.add(metric);
    _logger.performance(operationName, duration,
        tag: 'MONITORING', data: metadata);

    // Если операция заняла больше 1 секунды, логируем предупреждение
    if (duration.inMilliseconds > 1000) {
      _logger.warning(
          'Slow operation detected: $operationName took ${duration.inMilliseconds}ms',
          tag: 'MONITORING',
          data: metadata);
    }
  }

  /// Записать ошибку
  void _recordError(String errorType, Object error, StackTrace? stack) {
    final errorMetric = ErrorMetric(
      errorType: errorType,
      error: error.toString(),
      timestamp: DateTime.now(),
      stackTrace: stack?.toString(),
    );

    _errorMetrics.add(errorMetric);
    _logger.error('Error recorded: $errorType',
        tag: 'MONITORING', error: error, stackTrace: stack);
  }

  /// Собрать метрики памяти
  void _collectMemoryMetrics() {
    try {
      final memoryUsage = ProcessInfo.currentRss;
      final memoryMetric = MemoryMetric(
        memoryUsage: memoryUsage,
        timestamp: DateTime.now(),
      );

      _memoryMetrics.add(memoryMetric);
      _logger.debug('Memory usage: ${memoryUsage ~/ 1024 / 1024}MB',
          tag: 'MONITORING');

      // Если использование памяти превышает 200MB, логируем предупреждение
      if (memoryUsage > 200 * 1024 * 1024) {
        _logger.warning(
            'High memory usage detected: ${memoryUsage ~/ 1024 / 1024}MB',
            tag: 'MONITORING');
      }
    } catch (e) {
      _logger.error('Failed to collect memory metrics',
          tag: 'MONITORING', error: e);
    }
  }

  /// Очистить старые метрики
  void _cleanupOldMetrics() {
    final cutoffTime = DateTime.now().subtract(Duration(hours: 1));

    _performanceMetrics
        .removeWhere((metric) => metric.timestamp.isBefore(cutoffTime));
    _errorMetrics
        .removeWhere((metric) => metric.timestamp.isBefore(cutoffTime));
    _memoryMetrics
        .removeWhere((metric) => metric.timestamp.isBefore(cutoffTime));

    _logger.debug('Cleaned up old metrics', tag: 'MONITORING');
  }

  /// Получить статистику производительности
  Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{};

    for (final operation in _operationCounts.keys) {
      final count = _operationCounts[operation] ?? 0;
      final totalTime = _operationTotalTimes[operation] ?? Duration.zero;
      final averageTime = count > 0 ? totalTime.inMilliseconds / count : 0;

      stats[operation] = {
        'count': count,
        'totalTime': totalTime.inMilliseconds,
        'averageTime': averageTime,
      };
    }

    return stats;
  }

  /// Получить статистику ошибок
  Map<String, dynamic> getErrorStats() {
    final stats = <String, dynamic>{};
    final errorTypes = <String, int>{};

    for (final error in _errorMetrics) {
      errorTypes[error.errorType] = (errorTypes[error.errorType] ?? 0) + 1;
    }

    stats['totalErrors'] = _errorMetrics.length;
    stats['errorTypes'] = errorTypes;
    stats['recentErrors'] = _errorMetrics
        .where((e) =>
            e.timestamp.isAfter(DateTime.now().subtract(Duration(minutes: 5))))
        .length;

    return stats;
  }

  /// Получить статистику памяти
  Map<String, dynamic> getMemoryStats() {
    if (_memoryMetrics.isEmpty) return {};

    final currentMemory = _memoryMetrics.last.memoryUsage;
    final maxMemory = _memoryMetrics
        .map((m) => m.memoryUsage)
        .reduce((a, b) => a > b ? a : b);
    final minMemory = _memoryMetrics
        .map((m) => m.memoryUsage)
        .reduce((a, b) => a < b ? a : b);
    final avgMemory =
        _memoryMetrics.map((m) => m.memoryUsage).reduce((a, b) => a + b) /
            _memoryMetrics.length;

    return {
      'current': currentMemory,
      'max': maxMemory,
      'min': minMemory,
      'average': avgMemory,
      'samples': _memoryMetrics.length,
    };
  }

  /// Получить общую статистику
  Map<String, dynamic> getOverallStats() {
    return {
      'performance': getPerformanceStats(),
      'errors': getErrorStats(),
      'memory': getMemoryStats(),
      'isMonitoring': _isMonitoring,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Получить метрики производительности
  List<PerformanceMetric> getPerformanceMetrics() =>
      List.unmodifiable(_performanceMetrics);

  /// Получить метрики ошибок
  List<ErrorMetric> getErrorMetrics() => List.unmodifiable(_errorMetrics);

  /// Получить метрики памяти
  List<MemoryMetric> getMemoryMetrics() => List.unmodifiable(_memoryMetrics);

  /// Очистить все метрики
  void clearMetrics() {
    _performanceMetrics.clear();
    _errorMetrics.clear();
    _memoryMetrics.clear();
    _operationStartTimes.clear();
    _operationCounts.clear();
    _operationTotalTimes.clear();

    _logger.info('Cleared all metrics', tag: 'MONITORING');
  }

  /// Экспортировать метрики в JSON
  Map<String, dynamic> exportMetrics() {
    return {
      'performance': _performanceMetrics.map((m) => m.toJson()).toList(),
      'errors': _errorMetrics.map((e) => e.toJson()).toList(),
      'memory': _memoryMetrics.map((m) => m.toJson()).toList(),
      'stats': getOverallStats(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }
}

/// Метрика производительности
class PerformanceMetric {
  final String operationName;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceMetric({
    required this.operationName,
    required this.duration,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'operationName': operationName,
      'duration': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Метрика ошибки
class ErrorMetric {
  final String errorType;
  final String error;
  final DateTime timestamp;
  final String? stackTrace;

  ErrorMetric({
    required this.errorType,
    required this.error,
    required this.timestamp,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() {
    return {
      'errorType': errorType,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
      'stackTrace': stackTrace,
    };
  }
}

/// Метрика памяти
class MemoryMetric {
  final int memoryUsage;
  final DateTime timestamp;

  MemoryMetric({
    required this.memoryUsage,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'memoryUsage': memoryUsage,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Расширение для мониторинга операций
extension MonitoringExtension on Future<T> {
  /// Отслеживать выполнение Future операции
  Future<T> monitor(String operationName,
      {Map<String, dynamic>? metadata}) async {
    final monitoring = MonitoringService();
    monitoring.startOperation(operationName);

    try {
      final result = await this;
      monitoring.endOperation(operationName, metadata: metadata);
      return result;
    } catch (e, stack) {
      monitoring.endOperation(operationName, metadata: metadata);
      monitoring._recordError('Operation Error', e, stack);
      rethrow;
    }
  }
}

/// Расширение для мониторинга Stream операций
extension StreamMonitoringExtension<T> on Stream<T> {
  /// Отслеживать выполнение Stream операции
  Stream<T> monitor(String operationName, {Map<String, dynamic>? metadata}) {
    final monitoring = MonitoringService();
    monitoring.startOperation(operationName);

    return this.map((data) {
      monitoring.endOperation(operationName, metadata: metadata);
      return data;
    }).handleError((error, stack) {
      monitoring.endOperation(operationName, metadata: metadata);
      monitoring._recordError('Stream Error', error, stack);
      throw error;
    });
  }
}
