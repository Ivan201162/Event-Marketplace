import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kpi_metrics.dart';
import '../services/kpi_metrics_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран управления KPI метриками
class KPIMetricsScreen extends ConsumerStatefulWidget {
  const KPIMetricsScreen({super.key});

  @override
  ConsumerState<KPIMetricsScreen> createState() => _KPIMetricsScreenState();
}

class _KPIMetricsScreenState extends ConsumerState<KPIMetricsScreen> {
  final KPIMetricsService _kpiService = KPIMetricsService();
  List<KPIMetric> _metrics = [];
  List<KPIDashboard> _dashboards = [];
  List<KPIReport> _reports = [];
  bool _isLoading = true;
  String _selectedTab = 'metrics';
  Map<String, dynamic> _analysis = {};

  // Фильтры
  MetricCategory? _selectedCategory;
  MetricType? _selectedType;
  MetricStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupStreams();
  }

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
    appBar: AppBar(title: const Text('KPI метрики и аналитика')),
    body: Column(
      children: [
        // Вкладки
        _buildTabs(),

        // Фильтры
        _buildFilters(),

        // Анализ
        _buildAnalysis(),

        // Контент
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedTab == 'metrics'
              ? _buildMetricsTab()
              : _selectedTab == 'dashboards'
              ? _buildDashboardsTab()
              : _buildReportsTab(),
        ),
      ],
    ),
  );

  Widget _buildTabs() => ResponsiveCard(
    child: Row(
      children: [
        Expanded(child: _buildTabButton('metrics', 'Метрики', Icons.analytics)),
        Expanded(child: _buildTabButton('dashboards', 'Дашборды', Icons.dashboard)),
        Expanded(child: _buildTabButton('reports', 'Отчеты', Icons.assessment)),
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
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 24),
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

  Widget _buildFilters() => ResponsiveCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Фильтры', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Фильтр по категории
            DropdownButton<MetricCategory?>(
              value: _selectedCategory,
              hint: const Text('Все категории'),
              items: [
                const DropdownMenuItem<MetricCategory?>(child: Text('Все категории')),
                ...MetricCategory.values.map(
                  (category) => DropdownMenuItem<MetricCategory?>(
                    value: category,
                    child: Text('${category.icon} ${category.displayName}'),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),

            // Фильтр по типу
            DropdownButton<MetricType?>(
              value: _selectedType,
              hint: const Text('Все типы'),
              items: [
                const DropdownMenuItem<MetricType?>(child: Text('Все типы')),
                ...MetricType.values.map(
                  (type) => DropdownMenuItem<MetricType?>(
                    value: type,
                    child: Text('${type.icon} ${type.displayName}'),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
            ),

            // Фильтр по статусу
            DropdownButton<MetricStatus?>(
              value: _selectedStatus,
              hint: const Text('Все статусы'),
              items: [
                const DropdownMenuItem<MetricStatus?>(child: Text('Все статусы')),
                ...MetricStatus.values.map(
                  (status) => DropdownMenuItem<MetricStatus?>(
                    value: status,
                    child: Text('${status.icon} ${status.displayName}'),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),

            // Кнопка сброса фильтров
            ElevatedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Сбросить'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildAnalysis() {
    if (_analysis.isEmpty) return const SizedBox.shrink();

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Анализ KPI', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAnalysisCard(
                  'Всего метрик',
                  '${_analysis['metrics']?['total'] ?? 0}',
                  Icons.analytics,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalysisCard(
                  'Целей достигнуто',
                  '${_analysis['metrics']?['targetsMet'] ?? 0}',
                  Icons.flag,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalysisCard(
                  'Дашбордов',
                  '${_analysis['dashboards']?['total'] ?? 0}',
                  Icons.dashboard,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalysisCard(
                  'Отчетов',
                  '${_analysis['reports']?['total'] ?? 0}',
                  Icons.assessment,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(String title, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _buildMetricsTab() => Column(
    children: [
      // Заголовок
      ResponsiveCard(
        child: Row(
          children: [
            Text('KPI метрики', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _showAddMetricDialog,
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
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
        child: _getFilteredMetrics().isEmpty
            ? const Center(child: Text('Метрики не найдены'))
            : ListView.builder(
                itemCount: _getFilteredMetrics().length,
                itemBuilder: (context, index) {
                  final metric = _getFilteredMetrics()[index];
                  return _buildMetricCard(metric);
                },
              ),
      ),
    ],
  );

  Widget _buildMetricCard(KPIMetric metric) {
    final typeColor = _getTypeColor(metric.type);
    final categoryColor = _getCategoryColor(metric.category);
    final statusColor = _getStatusColor(metric.status);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(metric.type.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(metric.description, style: const TextStyle(fontSize: 14)),
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
                  style: TextStyle(fontSize: 12, color: typeColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: categoryColor),
                ),
                child: Text(
                  metric.category.displayName,
                  style: TextStyle(fontSize: 12, color: categoryColor, fontWeight: FontWeight.bold),
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
                  metric.status.displayName,
                  style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMetricAction(value, metric),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: ListTile(leading: Icon(Icons.visibility), title: Text('Просмотр')),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(leading: Icon(Icons.edit), title: Text('Редактировать')),
                  ),
                ],
                child: const Icon(Icons.more_vert),
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
            child: Row(
              children: [
                Text(
                  '${metric.value} ${metric.unit}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (metric.target != null) ...[
                  const Spacer(),
                  Text(
                    'Цель: ${metric.target} ${metric.unit}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Изменения
          if (metric.change != null || metric.changePercentage != null) ...[
            Row(
              children: [
                if (metric.change != null)
                  _buildInfoChip(
                    'Изменение',
                    '${metric.change!.toStringAsFixed(2)} ${metric.unit}',
                    Colors.blue,
                  ),
                const SizedBox(width: 8),
                if (metric.changePercentage != null)
                  _buildInfoChip(
                    'Процент',
                    '${metric.changePercentage!.toStringAsFixed(1)}%',
                    Colors.green,
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Теги
          if (metric.tags.isNotEmpty) ...[
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: metric.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(tag, style: const TextStyle(fontSize: 10)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],

          // Время
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Обновлен: ${_formatDateTime(metric.lastUpdated ?? metric.timestamp)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
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
            Text('KPI дашборды', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _showCreateDashboardDialog,
              icon: const Icon(Icons.add),
              label: const Text('Создать'),
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

  Widget _buildDashboardCard(KPIDashboard dashboard) => ResponsiveCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок
        Row(
          children: [
            Text(dashboard.layout.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dashboard.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(dashboard.description, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  'Публичный',
                  style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            if (dashboard.isDefault)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Text(
                  'По умолчанию',
                  style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleDashboardAction(value, dashboard),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: ListTile(leading: Icon(Icons.visibility), title: Text('Просмотр')),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(leading: Icon(Icons.edit), title: Text('Редактировать')),
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
            _buildInfoChip('Метрики', '${dashboard.metricIds.length}', Colors.blue),
            const SizedBox(width: 8),
            _buildInfoChip('Теги', '${dashboard.tags.length}', Colors.green),
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
          ],
        ),
      ],
    ),
  );

  Widget _buildReportsTab() => Column(
    children: [
      // Заголовок
      ResponsiveCard(
        child: Row(
          children: [
            Text('KPI отчеты', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _showCreateReportDialog,
              icon: const Icon(Icons.add),
              label: const Text('Создать'),
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

      // Список отчетов
      Expanded(
        child: _reports.isEmpty
            ? const Center(child: Text('Отчеты не найдены'))
            : ListView.builder(
                itemCount: _reports.length,
                itemBuilder: (context, index) {
                  final report = _reports[index];
                  return _buildReportCard(report);
                },
              ),
      ),
    ],
  );

  Widget _buildReportCard(KPIReport report) {
    final statusColor = _getReportStatusColor(report.status);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(report.type.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(report.description, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  report.status.displayName,
                  style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleReportAction(value, report),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: ListTile(leading: Icon(Icons.visibility), title: Text('Просмотр')),
                  ),
                  if (report.status == ReportStatus.draft)
                    const PopupMenuItem(
                      value: 'generate',
                      child: ListTile(leading: Icon(Icons.play_arrow), title: Text('Генерировать')),
                    ),
                  if (report.status == ReportStatus.ready && report.fileUrl != null)
                    const PopupMenuItem(
                      value: 'download',
                      child: ListTile(leading: Icon(Icons.download), title: Text('Скачать')),
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
              _buildInfoChip('Метрики', '${report.metricIds.length}', Colors.blue),
              const SizedBox(width: 8),
              _buildInfoChip('Дашборды', '${report.dashboardIds.length}', Colors.green),
              const SizedBox(width: 8),
              _buildInfoChip(
                'Период',
                _formatDateRange(report.startDate, report.endDate),
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
                'Создан: ${_formatDateTime(report.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color),
    ),
    child: Text(
      '$label: $value',
      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
    ),
  );

  Color _getTypeColor(MetricType type) {
    switch (type) {
      case MetricType.counter:
        return Colors.blue;
      case MetricType.gauge:
        return Colors.green;
      case MetricType.histogram:
        return Colors.purple;
      case MetricType.timer:
        return Colors.orange;
      case MetricType.rate:
        return Colors.red;
      case MetricType.percentage:
        return Colors.teal;
      case MetricType.ratio:
        return Colors.indigo;
      case MetricType.average:
        return Colors.cyan;
      case MetricType.sum:
        return Colors.lime;
      case MetricType.min:
        return Colors.pink;
      case MetricType.max:
        return Colors.brown;
    }
  }

  Color _getCategoryColor(MetricCategory category) {
    switch (category) {
      case MetricCategory.business:
        return Colors.blue;
      case MetricCategory.technical:
        return Colors.green;
      case MetricCategory.user:
        return Colors.purple;
      case MetricCategory.performance:
        return Colors.orange;
      case MetricCategory.security:
        return Colors.red;
      case MetricCategory.financial:
        return Colors.yellow;
      case MetricCategory.operational:
        return Colors.teal;
      case MetricCategory.quality:
        return Colors.indigo;
      case MetricCategory.compliance:
        return Colors.cyan;
      case MetricCategory.innovation:
        return Colors.lime;
    }
  }

  Color _getStatusColor(MetricStatus status) {
    switch (status) {
      case MetricStatus.normal:
        return Colors.green;
      case MetricStatus.warning:
        return Colors.orange;
      case MetricStatus.critical:
        return Colors.red;
      case MetricStatus.error:
        return Colors.red;
      case MetricStatus.unknown:
        return Colors.grey;
    }
  }

  Color _getReportStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.draft:
        return Colors.grey;
      case ReportStatus.generating:
        return Colors.blue;
      case ReportStatus.ready:
        return Colors.green;
      case ReportStatus.failed:
        return Colors.red;
      case ReportStatus.archived:
        return Colors.brown;
    }
  }

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

  String _formatDateRange(DateTime startDate, DateTime endDate) =>
      '${startDate.day}.${startDate.month} - ${endDate.day}.${endDate.month}';

  List<KPIMetric> _getFilteredMetrics() {
    var filtered = _metrics;

    if (_selectedCategory != null) {
      filtered = filtered.where((m) => m.category == _selectedCategory).toList();
    }

    if (_selectedType != null) {
      filtered = filtered.where((m) => m.type == _selectedType).toList();
    }

    if (_selectedStatus != null) {
      filtered = filtered.where((m) => m.status == _selectedStatus).toList();
    }

    return filtered;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _kpiService.initialize();
      setState(() {
        _metrics = _kpiService.getAllMetrics();
        _dashboards = _kpiService.getAllDashboards();
        _reports = _kpiService.getAllReports();
      });

      _analysis = await _kpiService.analyzeMetrics();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupStreams() {
    _kpiService.metricStream.listen((metric) {
      setState(() {
        final index = _metrics.indexWhere((m) => m.id == metric.id);
        if (index != -1) {
          _metrics[index] = metric;
        } else {
          _metrics.add(metric);
        }
      });
    });

    _kpiService.dashboardStream.listen((dashboard) {
      setState(() {
        final index = _dashboards.indexWhere((d) => d.id == dashboard.id);
        if (index != -1) {
          _dashboards[index] = dashboard;
        } else {
          _dashboards.add(dashboard);
        }
      });
    });

    _kpiService.reportStream.listen((report) {
      setState(() {
        final index = _reports.indexWhere((r) => r.id == report.id);
        if (index != -1) {
          _reports[index] = report;
        } else {
          _reports.add(report);
        }
      });
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedType = null;
      _selectedStatus = null;
    });
  }

  void _handleMetricAction(String action, KPIMetric metric) {
    switch (action) {
      case 'view':
        _viewMetric(metric);
        break;
      case 'edit':
        _editMetric(metric);
        break;
    }
  }

  void _handleDashboardAction(String action, KPIDashboard dashboard) {
    switch (action) {
      case 'view':
        _viewDashboard(dashboard);
        break;
      case 'edit':
        _editDashboard(dashboard);
        break;
    }
  }

  void _handleReportAction(String action, KPIReport report) {
    switch (action) {
      case 'view':
        _viewReport(report);
        break;
      case 'generate':
        _generateReport(report);
        break;
      case 'download':
        _downloadReport(report);
        break;
    }
  }

  void _viewMetric(KPIMetric metric) {
    // TODO(developer): Реализовать просмотр метрики
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Просмотр метрики "${metric.name}" будет реализован')));
  }

  void _editMetric(KPIMetric metric) {
    // TODO(developer): Реализовать редактирование метрики
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Редактирование метрики "${metric.name}" будет реализовано')),
    );
  }

  void _viewDashboard(KPIDashboard dashboard) {
    // TODO(developer): Реализовать просмотр дашборда
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Просмотр дашборда "${dashboard.name}" будет реализован')),
    );
  }

  void _editDashboard(KPIDashboard dashboard) {
    // TODO(developer): Реализовать редактирование дашборда
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Редактирование дашборда "${dashboard.name}" будет реализовано')),
    );
  }

  void _viewReport(KPIReport report) {
    // TODO(developer): Реализовать просмотр отчета
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Просмотр отчета "${report.name}" будет реализован')));
  }

  Future<void> _generateReport(KPIReport report) async {
    try {
      await _kpiService.generateReport(report.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Генерация отчета "${report.name}" запущена'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка генерации отчета: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _downloadReport(KPIReport report) {
    // TODO(developer): Реализовать скачивание отчета
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Скачивание отчета "${report.name}" будет реализовано')));
  }

  void _showAddMetricDialog() {
    // TODO(developer): Реализовать диалог добавления метрики
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Добавление метрики будет реализовано')));
  }

  void _showCreateDashboardDialog() {
    // TODO(developer): Реализовать диалог создания дашборда
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Создание дашборда будет реализовано')));
  }

  void _showCreateReportDialog() {
    // TODO(developer): Реализовать диалог создания отчета
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Создание отчета будет реализовано')));
  }
}
