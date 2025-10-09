import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Скрипт для тестирования производительности приложения
class PerformanceTest {
  factory PerformanceTest() => _instance;
  PerformanceTest._internal();
  static final PerformanceTest _instance = PerformanceTest._internal();

  final List<PerformanceMetric> _metrics = [];
  final Map<String, Stopwatch> _activeTimers = {};

  /// Начать измерение производительности
  void startTimer(String operationName) {
    _activeTimers[operationName] = Stopwatch()..start();
  }

  /// Завершить измерение производительности
  void endTimer(String operationName) {
    final stopwatch = _activeTimers.remove(operationName);
    if (stopwatch != null) {
      stopwatch.stop();
      _metrics.add(
        PerformanceMetric(
          operationName: operationName,
          duration: stopwatch.elapsedMilliseconds,
          timestamp: DateTime.now(),
        ),
      );

      developer.log(
        'Performance: $operationName took ${stopwatch.elapsedMilliseconds}ms',
        name: 'PERFORMANCE_TEST',
      );
    }
  }

  /// Измерить производительность функции
  Future<T> measureFunction<T>(
    String operationName,
    Future<T> Function() function,
  ) async {
    startTimer(operationName);
    try {
      final result = await function();
      endTimer(operationName);
      return result;
    } catch (e) {
      endTimer(operationName);
      rethrow;
    }
  }

  /// Измерить производительность синхронной функции
  T measureSyncFunction<T>(
    String operationName,
    T Function() function,
  ) {
    startTimer(operationName);
    try {
      final result = function();
      endTimer(operationName);
      return result;
    } catch (e) {
      endTimer(operationName);
      rethrow;
    }
  }

  /// Получить статистику производительности
  PerformanceStats getStats() {
    if (_metrics.isEmpty) {
      return PerformanceStats.empty();
    }

    final durations = _metrics.map((m) => m.duration).toList();
    durations.sort();

    return PerformanceStats(
      totalOperations: _metrics.length,
      averageDuration: durations.reduce((a, b) => a + b) / durations.length,
      minDuration: durations.first,
      maxDuration: durations.last,
      medianDuration: durations[durations.length ~/ 2],
      p95Duration: durations[(durations.length * 0.95).round() - 1],
      p99Duration: durations[(durations.length * 0.99).round() - 1],
    );
  }

  /// Очистить метрики
  void clearMetrics() {
    _metrics.clear();
    _activeTimers.clear();
  }

  /// Экспорт метрик в файл
  Future<void> exportMetrics(String filePath) async {
    final file = File(filePath);
    final buffer = StringBuffer();

    buffer.writeln('Performance Metrics Export');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Platform: ${Platform.operatingSystem}');
    buffer.writeln('Debug Mode: $kDebugMode');
    buffer.writeln();

    final stats = getStats();
    buffer.writeln('Overall Statistics:');
    buffer.writeln('Total Operations: ${stats.totalOperations}');
    buffer.writeln(
      'Average Duration: ${stats.averageDuration.toStringAsFixed(2)}ms',
    );
    buffer.writeln('Min Duration: ${stats.minDuration}ms');
    buffer.writeln('Max Duration: ${stats.maxDuration}ms');
    buffer.writeln('Median Duration: ${stats.medianDuration}ms');
    buffer.writeln('95th Percentile: ${stats.p95Duration}ms');
    buffer.writeln('99th Percentile: ${stats.p99Duration}ms');
    buffer.writeln();

    buffer.writeln('Individual Metrics:');
    buffer.writeln('Operation Name | Duration (ms) | Timestamp');
    buffer.writeln('----------------------------------------');

    for (final metric in _metrics) {
      buffer.writeln(
        '${metric.operationName} | ${metric.duration} | ${metric.timestamp}',
      );
    }

    await file.writeAsString(buffer.toString());
    developer.log(
      'Performance metrics exported to: $filePath',
      name: 'PERFORMANCE_TEST',
    );
  }

  /// Тест производительности виджетов
  Future<void> testWidgetPerformance() async {
    developer.log(
      'Starting widget performance test...',
      name: 'PERFORMANCE_TEST',
    );

    // Тест создания виджетов
    await measureFunction('Widget Creation', () async {
      for (var i = 0; i < 1000; i++) {
        Container(
          width: 100,
          height: 100,
          color: Colors.blue,
          child: Text('Test $i'),
        );
      }
    });

    // Тест анимаций
    await measureFunction('Animation Creation', () async {
      for (var i = 0; i < 100; i++) {
        AnimationController(
          duration: const Duration(seconds: 1),
          vsync: _TestTickerProvider(),
        );
      }
    });

    // Тест изображений
    await measureFunction('Image Widget Creation', () async {
      for (var i = 0; i < 500; i++) {
        Image.network('https://example.com/image$i.jpg');
      }
    });
  }

  /// Тест производительности памяти
  void testMemoryPerformance() {
    developer.log(
      'Starting memory performance test...',
      name: 'PERFORMANCE_TEST',
    );

    final stopwatch = Stopwatch()..start();

    // Создаем много объектов
    final list = <String>[];
    for (var i = 0; i < 100000; i++) {
      list.add('Test string $i');
    }

    stopwatch.stop();
    developer.log(
      'Memory test: Created 100,000 strings in ${stopwatch.elapsedMilliseconds}ms',
      name: 'PERFORMANCE_TEST',
    );

    // Очищаем память
    list.clear();
  }

  /// Тест производительности сети
  Future<void> testNetworkPerformance() async {
    developer.log(
      'Starting network performance test...',
      name: 'PERFORMANCE_TEST',
    );

    // Тест HTTP запросов
    await measureFunction('HTTP Request', () async {
      final client = HttpClient();
      try {
        final request =
            await client.getUrl(Uri.parse('https://httpbin.org/get'));
        final response = await request.close();
        await response.drain<List<int>>();
      } finally {
        client.close();
      }
    });
  }
}

/// Метрика производительности
class PerformanceMetric {
  const PerformanceMetric({
    required this.operationName,
    required this.duration,
    required this.timestamp,
  });

  final String operationName;
  final int duration; // в миллисекундах
  final DateTime timestamp;
}

/// Статистика производительности
class PerformanceStats {
  const PerformanceStats({
    required this.totalOperations,
    required this.averageDuration,
    required this.minDuration,
    required this.maxDuration,
    required this.medianDuration,
    required this.p95Duration,
    required this.p99Duration,
  });

  factory PerformanceStats.empty() => const PerformanceStats(
        totalOperations: 0,
        averageDuration: 0,
        minDuration: 0,
        maxDuration: 0,
        medianDuration: 0,
        p95Duration: 0,
        p99Duration: 0,
      );

  final int totalOperations;
  final double averageDuration;
  final int minDuration;
  final int maxDuration;
  final int medianDuration;
  final int p95Duration;
  final int p99Duration;

  @override
  String toString() => 'PerformanceStats('
      'totalOperations: $totalOperations, '
      'averageDuration: ${averageDuration.toStringAsFixed(2)}ms, '
      'minDuration: ${minDuration}ms, '
      'maxDuration: ${maxDuration}ms, '
      'medianDuration: ${medianDuration}ms, '
      'p95Duration: ${p95Duration}ms, '
      'p99Duration: ${p99Duration}ms'
      ')';
}

/// Заглушка для TickerProvider для тестов
class _TestTickerProvider extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

/// Расширение для Future с измерением производительности
extension PerformanceTestFutureExtension<T> on Future<T> {
  /// Измерить производительность Future
  Future<T> withPerformanceTest(String operationName) =>
      PerformanceTest().measureFunction(operationName, () => this);
}

/// Расширение для синхронных функций с измерением производительности
extension PerformanceTestSyncExtension<T> on T Function() {
  /// Измерить производительность синхронной функции
  T withPerformanceTest(String operationName) =>
      PerformanceTest().measureSyncFunction(operationName, this);
}
