import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/feature_flags.dart';
import '../providers/monitoring_providers.dart';

/// Виджет для отображения статуса мониторинга
class MonitoringStatusWidget extends ConsumerWidget {
  const MonitoringStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitoringState = ref.watch(monitoringStateProvider);
    final isAvailable = ref.watch(monitoringAvailableProvider);

    if (!isAvailable) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  monitoringState.isInitialized
                      ? Icons.monitor_heart
                      : Icons.monitor_heart_outlined,
                  color: monitoringState.isInitialized ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text('Мониторинг', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                _buildStatusChip(monitoringState.isInitialized),
              ],
            ),
            const SizedBox(height: 8),
            if (monitoringState.lastError != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Последняя ошибка: ${monitoringState.lastError}',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (monitoringState.activeTraces.isNotEmpty) ...[
              Text(
                'Активные трассировки: ${monitoringState.activeTraces.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                Text(
                  'Crashlytics: ${FeatureFlags.crashlyticsEnabled ? "Включен" : "Отключен"}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Text(
                  'Performance: ${FeatureFlags.performanceMonitoringEnabled ? "Включен" : "Отключен"}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isInitialized) => Chip(
        label: Text(isInitialized ? 'Активен' : 'Неактивен'),
        backgroundColor: isInitialized
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.orange.withValues(alpha: 0.2),
        labelStyle: TextStyle(color: isInitialized ? Colors.green : Colors.orange, fontSize: 12),
      );
}

/// Виджет для отображения метрик приложения
class AppMetricsWidget extends ConsumerWidget {
  const AppMetricsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(appMetricsProvider);
    final networkAsync = ref.watch(networkStatusProvider);
    final memoryAsync = ref.watch(memoryUsageProvider);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Метрики приложения', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),

            // Состояние сети
            networkAsync.when(
              data: (networkData) => _buildMetricRow(
                context,
                'Сеть',
                networkData['isConnected'] == true ? 'Подключена' : 'Отключена',
                networkData['isConnected'] == true ? Colors.green : Colors.red,
                Icons.wifi,
              ),
              loading: () => _buildLoadingRow(context, 'Сеть'),
              error: (error, stack) => _buildErrorRow(context, 'Сеть', error.toString()),
            ),

            const SizedBox(height: 8),

            // Использование памяти
            memoryAsync.when(
              data: (memoryData) => _buildMetricRow(
                context,
                'Память',
                '${(memoryData['rss'] / 1024 / 1024).toStringAsFixed(1)} MB',
                Colors.blue,
                Icons.memory,
              ),
              loading: () => _buildLoadingRow(context, 'Память'),
              error: (error, stack) => _buildErrorRow(context, 'Память', error.toString()),
            ),

            const SizedBox(height: 8),

            // Общие метрики
            metricsAsync.when(
              data: (metrics) => Column(
                children: [
                  if (metrics['activeTraces'] != null)
                    _buildMetricRow(
                      context,
                      'Активные трассировки',
                      '${(metrics['activeTraces'] as List).length}',
                      Colors.purple,
                      Icons.timeline,
                    ),
                ],
              ),
              loading: () => _buildLoadingRow(context, 'Метрики'),
              error: (error, stack) => _buildErrorRow(context, 'Метрики', error.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) =>
      Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      );

  Widget _buildLoadingRow(BuildContext context, String label) => Row(
        children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 8),
          Text('$label: Загрузка...', style: Theme.of(context).textTheme.bodyMedium),
        ],
      );

  Widget _buildErrorRow(BuildContext context, String label, String error) => Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: Ошибка - $error',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
            ),
          ),
        ],
      );
}

/// Виджет для управления мониторингом
class MonitoringControlWidget extends ConsumerWidget {
  const MonitoringControlWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitoringNotifier = ref.read(monitoringStateProvider.notifier);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Управление мониторингом', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: monitoringNotifier.updateMetrics,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Обновить метрики'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: monitoringNotifier.clearData,
                    icon: const Icon(Icons.clear),
                    label: const Text('Очистить данные'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _testError(context, monitoringNotifier),
              icon: const Icon(Icons.bug_report),
              label: const Text('Тестовая ошибка'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testError(BuildContext context, MonitoringStateNotifier notifier) {
    try {
      throw Exception('Тестовая ошибка для мониторинга');
    } catch (e, stackTrace) {
      notifier.recordError(e, stackTrace, reason: 'Тестовая ошибка');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Тестовая ошибка записана в мониторинг'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

/// Виджет для отображения логов мониторинга
class MonitoringLogsWidget extends ConsumerWidget {
  const MonitoringLogsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitoringState = ref.watch(monitoringStateProvider);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Логи мониторинга', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (monitoringState.lastError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Последняя ошибка',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(monitoringState.lastError!, style: Theme.of(context).textTheme.bodySmall),
                    if (monitoringState.lastErrorTime != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Время: ${monitoringState.lastErrorTime!.toLocal().toString()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Ошибок не обнаружено',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
