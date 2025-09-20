import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monitoring.dart';
import '../services/monitoring_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран мониторинга и алертов
class MonitoringScreen extends ConsumerStatefulWidget {
  const MonitoringScreen({super.key});

  @override
  ConsumerState<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen> {
  final MonitoringService _monitoringService = MonitoringService();
  List<MonitoringMetric> _metrics = [];
  List<MonitoringAlert> _alerts = [];
  List<MonitoringDashboard> _dashboards = [];
  bool _isLoading = true;
  String _selectedTab = 'metrics';

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupStreams();
  }

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
        appBar: AppBar(title: const Text('Мониторинг и алерты')),
        body: Column(
          children: [
            // Вкладки
            _buildTabs(),

            // Контент
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedTab == 'metrics'
                      ? _buildMetricsTab()
                      : _selectedTab == 'alerts'
                          ? _buildAlertsTab()
                          : _buildDashboardsTab(),
            ),
          ],
        ),
      );

  Widget _buildTabs() => ResponsiveCard(
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton('metrics', 'Метрики', Icons.analytics),
            ),
            Expanded(
              child: _buildTabButton('alerts', 'Алерты', Icons.warning),
            ),
            Expanded(
              child: _buildTabButton('dashboards', 'Дашборды', Icons.dashboard),
            ),
          ],
        ),
      );

  Widget _buildTabButton(String tab, String title, IconData icon) {
    final isSelected = _selectedTab == tab;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = tab;
        });
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

  Widget _buildMetricsTab() => Column(
        children: [
          // Заголовок с фильтрами
          ResponsiveCard(
            child: Row(
              children: [
                Text(
                  'Метрики системы',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                DropdownButton<String?>(
                  hint: const Text('Все категории'),
                  items: const [
                    DropdownMenuItem<String?>(
                      child: Text('Все категории'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'system',
                      child: Text('Система'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'network',
                      child: Text('Сеть'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'database',
                      child: Text('База данных'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'users',
                      child: Text('Пользователи'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'errors',
                      child: Text('Ошибки'),
                    ),
                  ],
                  onChanged: (value) {
                    // TODO: Реализовать фильтрацию
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loadData,
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

  Widget _buildMetricCard(MonitoringMetric metric) {
    final typeColor = _getTypeColor(metric.type);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                metric.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      metric.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: typeColor),
                ),
                child: Text(
                  metric.type.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Значение
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Text(
              metric.formattedValue,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Метаданные
          Row(
            children: [
              _buildInfoChip('Категория', metric.category, Colors.blue),
              const SizedBox(width: 8),
              if (metric.source != null)
                _buildInfoChip('Источник', metric.source!, Colors.green),
            ],
          ),

          const SizedBox(height: 8),

          // Время
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Обновлено: ${_formatDateTime(metric.timestamp)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                Text(
                  'Алерты мониторинга',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showCreateAlertDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Создать алерт'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loadData,
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

  Widget _buildAlertCard(MonitoringAlert alert) {
    final severityColor = _getSeverityColor(alert.severity);
    final statusColor = _getStatusColor(alert.status);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                alert.severity.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      alert.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: severityColor),
                ),
                child: Text(
                  alert.severity.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: severityColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  alert.status.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleAlertAction(value, alert),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: ListTile(
                      leading: Icon(Icons.visibility),
                      title: Text('Просмотр'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Редактировать'),
                    ),
                  ),
                  if (alert.isTriggered)
                    const PopupMenuItem(
                      value: 'resolve',
                      child: ListTile(
                        leading: Icon(Icons.check),
                        title: Text('Решить'),
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'disable',
                    child: ListTile(
                      leading: Icon(Icons.block),
                      title: Text('Отключить'),
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Условие
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Условие: ${alert.formattedCondition}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Метаданные
          Row(
            children: [
              _buildInfoChip('Метрика', alert.metricName, Colors.blue),
              const SizedBox(width: 8),
              _buildInfoChip(
                'Каналы',
                '${alert.notificationChannels.length}',
                Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Время
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Создан: ${_formatDateTime(alert.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (alert.triggeredAt != null) ...[
                const Spacer(),
                Text(
                  'Сработал: ${_formatDateTime(alert.triggeredAt!)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardsTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                Text(
                  'Дашборды мониторинга',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showCreateDashboardDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Создать дашборд'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Обновить'),
                ),
              ],
            ),
          ),

          // Список дашбордов
          Expanded(
            child: _dashboards.isEmpty
                ? const Center(child: Text('Дашборды не найдены'))
                : ListView.builder(
                    itemCount: _dashboards.length,
                    itemBuilder: (context, index) {
                      final dashboard = _dashboards[index];
                      return _buildDashboardCard(dashboard);
                    },
                  ),
          ),
        ],
      );

  Widget _buildDashboardCard(MonitoringDashboard dashboard) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                const Icon(Icons.dashboard, size: 24, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dashboard.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        dashboard.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    dashboard.layout.displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (dashboard.isPublic)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text(
                      'Публичный',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleDashboardAction(value, dashboard),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('Просмотр'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Редактировать'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: ListTile(
                        leading: Icon(Icons.download),
                        title: Text('Экспорт'),
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Метаданные
            Row(
              children: [
                _buildInfoChip(
                  'Метрики',
                  '${dashboard.metricCount}',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  'Алерты',
                  '${dashboard.alertCount}',
                  Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Время
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Создан: ${_formatDateTime(dashboard.createdAt)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  'Обновлен: ${_formatDateTime(dashboard.updatedAt)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildInfoChip(String label, String value, Color color) => Container(
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

  Color _getTypeColor(MetricType type) {
    switch (type) {
      case MetricType.counter:
        return Colors.blue;
      case MetricType.gauge:
        return Colors.green;
      case MetricType.histogram:
        return Colors.orange;
      case MetricType.timer:
        return Colors.purple;
      case MetricType.rate:
        return Colors.red;
    }
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return Colors.green;
      case AlertSeverity.medium:
        return Colors.yellow;
      case AlertSeverity.high:
        return Colors.orange;
      case AlertSeverity.critical:
        return Colors.red;
    }
  }

  Color _getStatusColor(AlertStatus status) {
    switch (status) {
      case AlertStatus.active:
        return Colors.blue;
      case AlertStatus.triggered:
        return Colors.red;
      case AlertStatus.resolved:
        return Colors.green;
      case AlertStatus.disabled:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _monitoringService.initialize();
      setState(() {
        _metrics = _monitoringService.getAllMetrics();
        _alerts = _monitoringService.getAllAlerts();
        _dashboards = _monitoringService.getAllDashboards();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки данных: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupStreams() {
    _monitoringService.metricsStream.listen((metric) {
      setState(() {
        _metrics.insert(0, metric);
        if (_metrics.length > 100) {
          _metrics = _metrics.take(100).toList();
        }
      });
    });

    _monitoringService.alertsStream.listen((alert) {
      setState(() {
        final index = _alerts.indexWhere((a) => a.id == alert.id);
        if (index != -1) {
          _alerts[index] = alert;
        } else {
          _alerts.insert(0, alert);
        }
      });
    });
  }

  void _handleAlertAction(String action, MonitoringAlert alert) {
    switch (action) {
      case 'view':
        _viewAlert(alert);
        break;
      case 'edit':
        _editAlert(alert);
        break;
      case 'resolve':
        _resolveAlert(alert);
        break;
      case 'disable':
        _disableAlert(alert);
        break;
    }
  }

  void _viewAlert(MonitoringAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Алерт: ${alert.name}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Описание: ${alert.description}'),
              const SizedBox(height: 8),
              Text('Условие: ${alert.formattedCondition}'),
              Text('Серьезность: ${alert.severity.displayName}'),
              Text('Статус: ${alert.status.displayName}'),
              Text('Метрика: ${alert.metricName}'),
              if (alert.triggeredAt != null)
                Text('Сработал: ${_formatDateTime(alert.triggeredAt!)}'),
              if (alert.resolvedAt != null)
                Text('Решен: ${_formatDateTime(alert.resolvedAt!)}'),
              if (alert.notificationChannels.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Каналы уведомлений: ${alert.notificationChannels.join(', ')}',
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _editAlert(MonitoringAlert alert) {
    // TODO: Реализовать редактирование алерта
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Редактирование алерта "${alert.name}" будет реализовано'),
      ),
    );
  }

  void _resolveAlert(MonitoringAlert alert) {
    // TODO: Реализовать решение алерта
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Решение алерта "${alert.name}" будет реализовано'),
      ),
    );
  }

  void _disableAlert(MonitoringAlert alert) {
    // TODO: Реализовать отключение алерта
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Отключение алерта "${alert.name}" будет реализовано'),
      ),
    );
  }

  void _handleDashboardAction(String action, MonitoringDashboard dashboard) {
    switch (action) {
      case 'view':
        _viewDashboard(dashboard);
        break;
      case 'edit':
        _editDashboard(dashboard);
        break;
      case 'export':
        _exportDashboard(dashboard);
        break;
    }
  }

  void _viewDashboard(MonitoringDashboard dashboard) {
    // TODO: Реализовать просмотр дашборда
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Просмотр дашборда "${dashboard.name}" будет реализован'),
      ),
    );
  }

  void _editDashboard(MonitoringDashboard dashboard) {
    // TODO: Реализовать редактирование дашборда
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Редактирование дашборда "${dashboard.name}" будет реализовано',
        ),
      ),
    );
  }

  void _exportDashboard(MonitoringDashboard dashboard) {
    // TODO: Реализовать экспорт дашборда
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Экспорт дашборда "${dashboard.name}" будет реализован'),
      ),
    );
  }

  void _showCreateAlertDialog() {
    // TODO: Реализовать диалог создания алерта
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Создание алерта будет реализовано'),
      ),
    );
  }

  void _showCreateDashboardDialog() {
    // TODO: Реализовать диалог создания дашборда
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Создание дашборда будет реализовано'),
      ),
    );
  }
}
