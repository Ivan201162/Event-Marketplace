import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:event_marketplace_app/widgets/monitoring_widgets.dart';
import 'package:event_marketplace_app/providers/monitoring_providers.dart';
import 'package:event_marketplace_app/core/feature_flags.dart';

/// Экран мониторинга приложения
class MonitoringScreen extends ConsumerStatefulWidget {
  const MonitoringScreen({super.key});

  @override
  ConsumerState<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen> {
  @override
  void initState() {
    super.initState();
    // Инициализация мониторинга при открытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(monitoringStateProvider.notifier).updateMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final monitoringState = ref.watch(monitoringStateProvider);
    final isAvailable = ref.watch(monitoringAvailableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мониторинг'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(monitoringStateProvider.notifier).updateMetrics();
            },
          ),
        ],
      ),
      body: isAvailable
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Статус мониторинга
                  const MonitoringStatusWidget(),

                  const SizedBox(height: 16),

                  // Метрики приложения
                  const AppMetricsWidget(),

                  const SizedBox(height: 16),

                  // Управление мониторингом
                  const MonitoringControlWidget(),

                  const SizedBox(height: 16),

                  // Логи мониторинга
                  const MonitoringLogsWidget(),

                  const SizedBox(height: 16),

                  // Информация о функциях
                  _buildFeatureInfo(context),
                ],
              ),
            )
          : _buildUnavailableWidget(context),
    );
  }

  Widget _buildUnavailableWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monitor_heart_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Мониторинг недоступен',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Включите Crashlytics или Performance Monitoring в настройках',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Назад'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureInfo(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Информация о функциях',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildFeatureRow(
              context,
              'Crashlytics',
              FeatureFlags.crashlyticsEnabled,
              'Отслеживание ошибок и сбоев',
            ),
            const SizedBox(height: 8),
            _buildFeatureRow(
              context,
              'Performance Monitoring',
              FeatureFlags.performanceMonitoringEnabled,
              'Мониторинг производительности',
            ),
            const SizedBox(height: 8),
            _buildFeatureRow(
              context,
              'Analytics',
              FeatureFlags.analyticsEnabled,
              'Аналитика пользователей',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Статус инициализации',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    monitoringState.isInitialized
                        ? 'Мониторинг успешно инициализирован'
                        : 'Мониторинг не инициализирован',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context,
    String name,
    bool isEnabled,
    String description,
  ) {
    return Row(
      children: [
        Icon(
          isEnabled ? Icons.check_circle : Icons.cancel,
          color: isEnabled ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        Chip(
          label: Text(isEnabled ? 'Включен' : 'Отключен'),
          backgroundColor: isEnabled
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isEnabled ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
