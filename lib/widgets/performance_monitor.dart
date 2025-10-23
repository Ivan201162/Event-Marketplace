import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/performance_provider.dart';

/// Виджет для мониторинга производительности
class PerformanceMonitor extends ConsumerWidget {
  const PerformanceMonitor({
    super.key,
    this.showDetails = false,
    this.position = PerformanceMonitorPosition.topRight,
  });

  final bool showDetails;
  final PerformanceMonitorPosition position;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceNotifier =
        ref.watch<PerformanceNotifier>(performanceProvider);
    final state = performanceNotifier.state;
    final needsOptimization = ref.watch<bool>(needsOptimizationProvider);

    if (!showDetails && !needsOptimization) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: position == PerformanceMonitorPosition.topRight ? 50 : null,
      bottom: position == PerformanceMonitorPosition.bottomRight ? 50 : null,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDetails) ...[
              _buildDetailRow('FPS', '${state.fps.toInt()}'),
              _buildDetailRow('Memory', '${state.memoryUsage}%'),
              _buildDetailRow('Battery', '${state.batteryLevel}%'),
              _buildDetailRow(
                  'Connection', _getConnectionSpeedText(state.connectionSpeed)),
              const SizedBox(height: 4),
            ],
            _buildStatusIndicator(needsOptimization),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: ',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  Widget _buildStatusIndicator(bool needsOptimization) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: needsOptimization ? Colors.red : Colors.green,
          shape: BoxShape.circle,
        ),
      );

  String _getConnectionSpeedText(ConnectionSpeed speed) {
    switch (speed) {
      case ConnectionSpeed.slow:
        return 'Slow';
      case ConnectionSpeed.medium:
        return 'Medium';
      case ConnectionSpeed.fast:
        return 'Fast';
    }
  }
}

/// Позиция монитора производительности
enum PerformanceMonitorPosition { topRight, bottomRight }

/// Виджет для отображения рекомендаций по оптимизации
class OptimizationRecommendations extends ConsumerWidget {
  const OptimizationRecommendations({super.key, this.maxHeight = 200});

  final double maxHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(optimizationRecommendationsProvider);

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Рекомендации по оптимизации:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: recommendations.length,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(recommendations[index]),
                dense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Виджет для управления оптимизацией
class OptimizationControls extends ConsumerWidget {
  const OptimizationControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceNotifier =
        ref.watch<PerformanceNotifier>(performanceProvider);
    final state = performanceNotifier.state;
    final notifier = performanceNotifier;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Управление оптимизацией',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildOptimizationLevelSelector(state, notifier),
            const SizedBox(height: 16),
            _buildActionButtons(notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationLevelSelector(
          PerformanceState state, PerformanceNotifier notifier) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Уровень оптимизации:'),
          const SizedBox(height: 8),
          DropdownButton<OptimizationLevel>(
            value: state.optimizationLevel,
            onChanged: (level) {
              if (level != null) {
                notifier.setOptimizationLevel(level);
              }
            },
            items: OptimizationLevel.values
                .map(
                  (level) => DropdownMenuItem(
                      value: level,
                      child: Text(_getOptimizationLevelText(level))),
                )
                .toList(),
          ),
        ],
      );

  Widget _buildActionButtons(PerformanceNotifier notifier) => Row(
        children: [
          ElevatedButton(
              onPressed: () => notifier.clearCache(),
              child: const Text('Очистить кэш')),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => notifier.forceCleanup(),
            child: const Text('Очистить память'),
          ),
        ],
      );

  String _getOptimizationLevelText(OptimizationLevel level) {
    switch (level) {
      case OptimizationLevel.low:
        return 'Низкий';
      case OptimizationLevel.normal:
        return 'Нормальный';
      case OptimizationLevel.high:
        return 'Высокий';
      case OptimizationLevel.maximum:
        return 'Максимальный';
    }
  }
}

/// Виджет для отображения статистики производительности
class PerformanceStats extends ConsumerWidget {
  const PerformanceStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceNotifier =
        ref.watch<PerformanceNotifier>(performanceProvider);
    final state = performanceNotifier.state;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статистика производительности',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
                'FPS', '${state.fps.toInt()}', _getFPSColor(state.fps)),
            _buildStatRow('Память', '${state.memoryUsage}%',
                _getMemoryColor(state.memoryUsage)),
            _buildStatRow(
              'Батарея',
              '${state.batteryLevel}%',
              _getBatteryColor(state.batteryLevel),
            ),
            _buildStatRow(
              'Соединение',
              _getConnectionSpeedText(state.connectionSpeed),
              _getConnectionColor(state.connectionSpeed),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

  Color _getFPSColor(double fps) {
    if (fps >= 50) {
      return Colors.green;
    }
    if (fps >= 30) {
      return Colors.orange;
    }
    return Colors.red;
  }

  Color _getMemoryColor(int usage) {
    if (usage < 50) {
      return Colors.green;
    }
    if (usage < 80) {
      return Colors.orange;
    }
    return Colors.red;
  }

  Color _getBatteryColor(int level) {
    if (level > 50) {
      return Colors.green;
    }
    if (level > 20) {
      return Colors.orange;
    }
    return Colors.red;
  }

  Color _getConnectionColor(ConnectionSpeed speed) {
    switch (speed) {
      case ConnectionSpeed.fast:
        return Colors.green;
      case ConnectionSpeed.medium:
        return Colors.orange;
      case ConnectionSpeed.slow:
        return Colors.red;
    }
  }

  String _getConnectionSpeedText(ConnectionSpeed speed) {
    switch (speed) {
      case ConnectionSpeed.slow:
        return 'Медленно';
      case ConnectionSpeed.medium:
        return 'Средне';
      case ConnectionSpeed.fast:
        return 'Быстро';
    }
  }
}
