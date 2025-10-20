import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_optimization_service.dart';
import '../services/error_logging_service.dart';
import '../services/performance_testing_service.dart';

/// Экран для тестирования и мониторинга
class TestingMonitoringScreen extends ConsumerStatefulWidget {
  const TestingMonitoringScreen({super.key});

  @override
  ConsumerState<TestingMonitoringScreen> createState() => _TestingMonitoringScreenState();
}

class _TestingMonitoringScreenState extends ConsumerState<TestingMonitoringScreen> {
  final ErrorLoggingService _errorLogger = ErrorLoggingService();
  final PerformanceTestingService _performanceTester = PerformanceTestingService();
  final AppOptimizationService _optimizer = AppOptimizationService();

  bool _isRunningTests = false;
  Map<String, dynamic>? _testResults;
  Map<String, dynamic>? _cacheInfo;
  List<Map<String, dynamic>>? _recommendations;
  Map<String, dynamic>? _errorStats;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadCacheInfo(),
      _loadRecommendations(),
      _loadErrorStats(),
    ]);
  }

  Future<void> _loadCacheInfo() async {
    final info = await _optimizer.getCacheSize();
    if (mounted) {
      setState(() {
        _cacheInfo = info;
      });
    }
  }

  Future<void> _loadRecommendations() async {
    final recommendations = await _optimizer.getOptimizationRecommendations();
    if (mounted) {
      setState(() {
        _recommendations = recommendations;
      });
    }
  }

  Future<void> _loadErrorStats() async {
    final stats = await _errorLogger.getErrorStats();
    if (mounted) {
      setState(() {
        _errorStats = stats;
      });
    }
  }

  Future<void> _runPerformanceTests() async {
    setState(() {
      _isRunningTests = true;
    });

    try {
      final results = await _performanceTester.runFullPerformanceTest();
      if (mounted) {
        setState(() {
          _testResults = results;
          _isRunningTests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRunningTests = false;
        });
        _showErrorSnackBar('Ошибка при запуске тестов: $e');
      }
    }
  }

  Future<void> _clearCache() async {
    try {
      final result = await _optimizer.clearCache();
      if (result['success'] == true) {
        _showSuccessSnackBar(
          'Кэш очищен. Освобождено: ${result['freedSpaceMB']} МБ',
        );
        await _loadCacheInfo();
      } else {
        _showErrorSnackBar('Ошибка очистки кэша: ${result['error']}');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка очистки кэша: $e');
    }
  }

  Future<void> _applyRecommendation(String action) async {
    try {
      final result = await _optimizer.applyOptimizationRecommendation(action);
      if (result['success'] == true) {
        _showSuccessSnackBar('Рекомендация применена успешно');
        await _loadInitialData();
      } else {
        _showErrorSnackBar(
          'Ошибка применения рекомендации: ${result['error']}',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка применения рекомендации: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Тестирование и Мониторинг'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Кэш и оптимизация
              _buildCacheSection(),
              const SizedBox(height: 24),

              // Рекомендации по оптимизации
              _buildRecommendationsSection(),
              const SizedBox(height: 24),

              // Статистика ошибок
              _buildErrorStatsSection(),
              const SizedBox(height: 24),

              // Тесты производительности
              _buildPerformanceTestsSection(),
              const SizedBox(height: 24),

              // Результаты тестов
              if (_testResults != null) _buildTestResultsSection(),
            ],
          ),
        ),
      );

  Widget _buildCacheSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.storage, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Кэш и Оптимизация',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadCacheInfo,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_cacheInfo != null) ...[
                _buildInfoRow(
                  'Временный кэш',
                  '${_cacheInfo!['tempCacheSizeMB']} МБ',
                ),
                _buildInfoRow(
                  'Документы',
                  '${_cacheInfo!['documentsSizeMB']} МБ',
                ),
                _buildInfoRow(
                  'Общий размер',
                  '${_cacheInfo!['totalSizeMB']} МБ',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _clearCache,
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Очистить кэш'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ] else
                const CircularProgressIndicator(),
            ],
          ),
        ),
      );

  Widget _buildRecommendationsSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.amber),
                  const SizedBox(width: 8),
                  const Text(
                    'Рекомендации по Оптимизации',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadRecommendations,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_recommendations != null) ...[
                if (_recommendations!.isEmpty)
                  const Text('Нет рекомендаций по оптимизации')
                else
                  ..._recommendations!.map(
                    _buildRecommendationCard,
                  ),
              ] else
                const CircularProgressIndicator(),
            ],
          ),
        ),
      );

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final priority = recommendation['priority'] as String;
    final priorityColor = priority == 'high'
        ? Colors.red
        : priority == 'medium'
            ? Colors.orange
            : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(recommendation['description'] as String),
            if (recommendation['estimatedSavings'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Экономия: ${recommendation['estimatedSavings']}',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _applyRecommendation(recommendation['action'] as String),
                child: const Text('Применить'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorStatsSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bug_report, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text(
                    'Статистика Ошибок',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadErrorStats,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_errorStats != null) ...[
                _buildInfoRow('Всего ошибок', '${_errorStats!['totalErrors']}'),
                if (_errorStats!['errorsByScreen'] != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Ошибки по экранам:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...(_errorStats!['errorsByScreen'] as Map<String, dynamic>).entries.map(
                        (entry) => _buildInfoRow('  ${entry.key}', '${entry.value}'),
                      ),
                ],
              ] else
                const CircularProgressIndicator(),
            ],
          ),
        ),
      );

  Widget _buildPerformanceTestsSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.speed, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Тесты Производительности',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isRunningTests ? null : _runPerformanceTests,
                  icon: _isRunningTests
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(
                    _isRunningTests ? 'Запуск тестов...' : 'Запустить тесты',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildTestResultsSection() {
    if (_testResults == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Результаты Тестов',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Общее время', '${_testResults!['totalTime']} мс'),
            _buildInfoRow(
              'Статус',
              _testResults!['success'] ? 'Успешно' : 'Ошибка',
            ),
            const SizedBox(height: 16),
            if (_testResults!['tests'] != null) ...[
              const Text(
                'Детали тестов:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(_testResults!['tests'] as Map<String, dynamic>).entries.map(
                    (entry) => _buildTestResult(entry.key, entry.value),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestResult(String testName, Map<String, dynamic> result) {
    final success = result['success'] as bool? ?? false;
    final color = success ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                testName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          if (result['totalTime'] != null) _buildInfoRow('Время', '${result['totalTime']} мс'),
          if (result['error'] != null)
            Text(
              'Ошибка: ${result['error']}',
              style: TextStyle(color: Colors.red[700]),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
}
