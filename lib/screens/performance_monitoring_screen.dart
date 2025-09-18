import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/performance_metric.dart';
import '../services/performance_monitoring_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран мониторинга производительности
class PerformanceMonitoringScreen extends ConsumerStatefulWidget {
  const PerformanceMonitoringScreen({super.key});

  @override
  ConsumerState<PerformanceMonitoringScreen> createState() =>
      _PerformanceMonitoringScreenState();
}

class _PerformanceMonitoringScreenState
    extends ConsumerState<PerformanceMonitoringScreen> {
  final PerformanceMonitoringService _performanceService =
      PerformanceMonitoringService();
  List<PerformanceMetric> _metrics = [];
  List<PerformanceAlert> _alerts = [];
  Map<String, double> _currentMetrics = {};
  bool _isLoading = true;
  String _selectedTab = 'overview';

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCurrentMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Мониторинг производительности',
      body: Column(
        children: [
          // Вкладки
          _buildTabs(),

          // Контент
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 'overview'
                    ? _buildOverviewTab()
                    : _selectedTab == 'metrics'
                        ? _buildMetricsTab()
                        : _selectedTab == 'alerts'
                            ? _buildAlertsTab()
                            : _buildStatisticsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return ResponsiveCard(
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('overview', 'Обзор', Icons.dashboard),
          ),
          Expanded(
            child: _buildTabButton('metrics', 'Метрики', Icons.analytics),
          ),
          Expanded(
            child: _buildTabButton('alerts', 'Алерты', Icons.warning),
          ),
          Expanded(
            child: _buildTabButton('statistics', 'Статистика', Icons.bar_chart),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String title, IconData icon) {
    final isSelected = _selectedTab == tab;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = tab;
        });
        if (tab == 'statistics') {
          _loadStatistics();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? Colors.blue : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Текущие метрики
          ResponsiveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  'Текущие метрики',
                  isTitle: true,
                ),
                const SizedBox(height: 16),
                if (_currentMetrics.isEmpty)
                  const Center(child: Text('Метрики не загружены'))
                else
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    children: _currentMetrics.entries.map((entry) {
                      return _buildCurrentMetricCard(entry.key, entry.value);
                    }).toList(),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Активные алерты
          ResponsiveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ResponsiveText(
                      'Активные алерты',
                      isTitle: true,
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _loadAlerts,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Обновить'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_alerts.isEmpty)
                  const Center(child: Text('Активных алертов нет'))
                else
                  ..._alerts
                      .take(5)
                      .map((alert) => _buildAlertCard(alert))
                      .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMetricCard(String metricName, double value) {
    final category = _getMetricCategory(metricName);
    final color = _getMetricColor(category);
    final unit = _getMetricUnit(metricName);
    final formattedValue = _formatMetricValue(value, unit);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getMetricDisplayName(metricName),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formattedValue,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            category,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(PerformanceAlert alert) {
    final severityColor = _getSeverityColor(alert.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: severityColor),
      ),
      child: Row(
        children: [
          Icon(
            _getSeverityIcon(alert.severity),
            color: severityColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
                Text(
                  '${alert.metricName}: ${alert.currentValue.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _resolveAlert(alert.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: severityColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(60, 30),
            ),
            child: const Text('Решить', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsTab() {
    return Column(
      children: [
        // Заголовок с фильтрами
        ResponsiveCard(
          child: Row(
            children: [
              ResponsiveText(
                'Метрики производительности',
                isTitle: true,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loadMetrics,
                icon: const Icon(Icons.refresh),
                label: const Text('Обновить'),
              ),
            ],
          ),
        ),

        // Список метрик
        Expanded(
          child: _metrics.isEmpty
              ? const Center(child: Text('Метрики не найдены'))
              : ListView.builder(
                  itemCount: _metrics.length,
                  itemBuilder: (context, index) {
                    final metric = _metrics[index];
                    return _buildMetricCard(metric);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(PerformanceMetric metric) {
    final color = _getMetricColor(metric.category);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Icon(
                _getCategoryIcon(metric.category),
                color: color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ResponsiveText(
                  metric.name,
                  isTitle: true,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color),
                ),
                child: Text(
                  metric.formattedValue,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Описание
          if (metric.description != null) ...[
            Text(metric.description!),
            const SizedBox(height: 12),
          ],

          // Метаданные
          Row(
            children: [
              _buildInfoChip('Категория', metric.category, color),
              const SizedBox(width: 8),
              _buildInfoChip('Единица', metric.unit, Colors.grey),
            ],
          ),

          const SizedBox(height: 12),

          // Время
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                _formatDateTime(metric.timestamp),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return Column(
      children: [
        // Заголовок
        ResponsiveCard(
          child: Row(
            children: [
              ResponsiveText(
                'Алерты производительности',
                isTitle: true,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loadAlerts,
                icon: const Icon(Icons.refresh),
                label: const Text('Обновить'),
              ),
            ],
          ),
        ),

        // Список алертов
        Expanded(
          child: _alerts.isEmpty
              ? const Center(child: Text('Алерты не найдены'))
              : ListView.builder(
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final alert = _alerts[index];
                    return _buildAlertCard(alert);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    return FutureBuilder<List<PerformanceStatistics>>(
      future: _loadAllStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final statistics = snapshot.data!;

        return SingleChildScrollView(
          child: Column(
            children:
                statistics.map((stats) => _buildStatisticsCard(stats)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCard(PerformanceStatistics stats) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Статистика: ${stats.metricName}',
            isTitle: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Среднее',
                  stats.avgValue.toStringAsFixed(2),
                  Colors.blue,
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  'Максимум',
                  stats.maxValue.toStringAsFixed(2),
                  Colors.red,
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  'P95',
                  stats.p95Value.toStringAsFixed(2),
                  Colors.orange,
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Образцов',
                  '${stats.totalSamples}',
                  Colors.green,
                  Icons.analytics,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  'Тренд',
                  stats.trend,
                  _getTrendColor(stats.trend),
                  _getTrendIcon(stats.trend),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getMetricCategory(String metricName) {
    if (metricName.contains('memory')) return 'memory';
    if (metricName.contains('cpu')) return 'cpu';
    if (metricName.contains('network')) return 'network';
    if (metricName.contains('database')) return 'database';
    if (metricName.contains('frame')) return 'ui';
    return 'general';
  }

  Color _getMetricColor(String category) {
    switch (category) {
      case 'memory':
        return Colors.blue;
      case 'cpu':
        return Colors.red;
      case 'network':
        return Colors.green;
      case 'database':
        return Colors.orange;
      case 'ui':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getMetricUnit(String metricName) {
    if (metricName.contains('memory')) return 'bytes';
    if (metricName.contains('percentage')) return 'percentage';
    if (metricName.contains('time') || metricName.contains('latency'))
      return 'ms';
    return 'count';
  }

  String _getMetricDisplayName(String metricName) {
    switch (metricName) {
      case 'memory_used':
        return 'Память';
      case 'memory_usage_percentage':
        return 'Память %';
      case 'cpu_usage':
        return 'CPU';
      case 'network_latency':
        return 'Сеть';
      case 'database_query_time':
        return 'БД';
      case 'frame_time':
        return 'UI';
      default:
        return metricName;
    }
  }

  String _formatMetricValue(double value, String unit) {
    if (unit == 'bytes') {
      const units = ['B', 'KB', 'MB', 'GB'];
      int size = value.toInt();
      int unitIndex = 0;

      while (size >= 1024 && unitIndex < units.length - 1) {
        size ~/= 1024;
        unitIndex++;
      }

      return '$size ${units[unitIndex]}';
    } else if (unit == 'percentage') {
      return '${value.toStringAsFixed(1)}%';
    } else if (unit == 'ms') {
      if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(2)}s';
      }
      return '${value.toStringAsFixed(0)}ms';
    } else {
      return value.toStringAsFixed(2);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'memory':
        return Icons.memory;
      case 'cpu':
        return Icons.speed;
      case 'network':
        return Icons.wifi;
      case 'database':
        return Icons.storage;
      case 'ui':
        return Icons.phone_android;
      default:
        return Icons.analytics;
    }
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Colors.blue;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.error:
        return Colors.red;
      case AlertSeverity.critical:
        return Colors.purple;
    }
  }

  IconData _getSeverityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Icons.info;
      case AlertSeverity.warning:
        return Icons.warning;
      case AlertSeverity.error:
        return Icons.error;
      case AlertSeverity.critical:
        return Icons.dangerous;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'improving':
        return Colors.green;
      case 'worsening':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'improving':
        return Icons.trending_down;
      case 'worsening':
        return Icons.trending_up;
      default:
        return Icons.trending_flat;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadMetrics(),
        _loadAlerts(),
      ]);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentMetrics() async {
    try {
      final metrics = _performanceService.getCurrentMetrics();
      setState(() {
        _currentMetrics = metrics;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки текущих метрик: $e');
      }
    }
  }

  Future<void> _loadMetrics() async {
    try {
      final metrics = await _performanceService.getMetrics(limit: 50);
      setState(() {
        _metrics = metrics;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки метрик: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadAlerts() async {
    try {
      final alerts = await _performanceService.getActiveAlerts();
      setState(() {
        _alerts = alerts;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки алертов: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadStatistics() async {
    // Статистика загружается автоматически в _buildStatisticsTab()
  }

  Future<List<PerformanceStatistics>> _loadAllStatistics() async {
    try {
      final metricNames = [
        'memory_used',
        'cpu_usage',
        'network_latency',
        'database_query_time',
        'frame_time'
      ];
      final statistics = <PerformanceStatistics>[];

      for (final metricName in metricNames) {
        final stats = await _performanceService.getMetricStatistics(metricName);
        if (stats.totalSamples > 0) {
          statistics.add(stats);
        }
      }

      return statistics;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки статистики: $e');
      }
      return [];
    }
  }

  Future<void> _resolveAlert(String alertId) async {
    try {
      await _performanceService.resolveAlert(alertId);
      _loadAlerts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Алерт решен'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка решения алерта: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
