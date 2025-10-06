import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран отчетов
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final ReportService _reportService = ReportService();
  List<Report> _reports = [];
  List<ReportTemplate> _templates = [];
  bool _isLoading = true;
  String _selectedTab = 'reports';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
        appBar: AppBar(title: const Text('Отчеты и аналитика')),
        body: Column(
          children: [
            // Вкладки
            _buildTabs(),

            // Контент
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedTab == 'reports'
                      ? _buildReportsTab()
                      : _buildTemplatesTab(),
            ),
          ],
        ),
      );

  Widget _buildTabs() => ResponsiveCard(
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton('reports', 'Отчеты', Icons.assessment),
            ),
            Expanded(
              child: _buildTabButton('templates', 'Шаблоны', Icons.description),
            ),
            Expanded(
              child: _buildTabButton('create', 'Создать', Icons.add),
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
        if (tab == 'create') {
          _showCreateReportDialog();
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

  Widget _buildReportsTab() => Column(
        children: [
          // Заголовок с фильтрами
          ResponsiveCard(
            child: Row(
              children: [
                Text(
                  'Отчеты',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loadReports,
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

  Widget _buildReportCard(Report report) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Icon(
                  _getReportIcon(report.type),
                  color: _getReportColor(report.type),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _buildStatusChip(report.status),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleReportAction(value, report),
                  itemBuilder: (context) => [
                    if (report.isReady) ...[
                      const PopupMenuItem(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility),
                          title: Text('Просмотреть'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'download',
                        child: ListTile(
                          leading: Icon(Icons.download),
                          title: Text('Скачать'),
                        ),
                      ),
                    ],
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete),
                        title: Text('Удалить'),
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Описание
            Text(report.description),

            const SizedBox(height: 12),

            // Метаданные
            Row(
              children: [
                _buildInfoChip('Тип', report.type.name, Colors.blue),
                const SizedBox(width: 8),
                _buildInfoChip('Категория', report.category.name, Colors.green),
              ],
            ),

            const SizedBox(height: 12),

            // Время создания
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Создан: ${_formatDateTime(report.createdAt)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (report.generatedAt != null) ...[
                  const Spacer(),
                  Text(
                    'Сгенерирован: ${_formatDateTime(report.generatedAt!)}',
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ],
            ),

            // Ошибка
            if (report.hasError && report.errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  'Ошибка: ${report.errorMessage}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _buildTemplatesTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                Text(
                  'Шаблоны отчетов',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loadTemplates,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Обновить'),
                ),
              ],
            ),
          ),

          // Список шаблонов
          Expanded(
            child: _templates.isEmpty
                ? const Center(child: Text('Шаблоны не найдены'))
                : ListView.builder(
                    itemCount: _templates.length,
                    itemBuilder: (context, index) {
                      final template = _templates[index];
                      return _buildTemplateCard(template);
                    },
                  ),
          ),
        ],
      );

  Widget _buildTemplateCard(ReportTemplate template) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Icon(
                  _getReportIcon(template.type),
                  color: _getReportColor(template.type),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    template.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _createReportFromTemplate(template),
                  child: const Text('Создать отчет'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Описание
            Text(template.description),

            const SizedBox(height: 12),

            // Метаданные
            Row(
              children: [
                _buildInfoChip('Тип', template.type.name, Colors.blue),
                const SizedBox(width: 8),
                _buildInfoChip(
                  'Категория',
                  template.category.name,
                  Colors.green,
                ),
              ],
            ),

            // Обязательные параметры
            if (template.requiredParameters.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Обязательные параметры:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: template.requiredParameters
                    .map(
                      (param) => Chip(
                        label: Text(param),
                        backgroundColor: Colors.orange.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(fontSize: 12),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      );

  Widget _buildStatusChip(ReportStatus status) {
    Color color;
    String text;

    switch (status) {
      case ReportStatus.pending:
        color = Colors.orange;
        text = 'Ожидает';
        break;
      case ReportStatus.generating:
        color = Colors.blue;
        text = 'Генерируется';
        break;
      case ReportStatus.completed:
        color = Colors.green;
        text = 'Готов';
        break;
      case ReportStatus.failed:
        color = Colors.red;
        text = 'Ошибка';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
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
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  IconData _getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.bookings:
        return Icons.event;
      case ReportType.payments:
        return Icons.payment;
      case ReportType.users:
        return Icons.people;
      case ReportType.specialists:
        return Icons.person;
      case ReportType.analytics:
        return Icons.analytics;
      case ReportType.notifications:
        return Icons.notifications;
      case ReportType.errors:
        return Icons.error;
      case ReportType.performance:
        return Icons.speed;
      default:
        return Icons.assessment;
    }
  }

  Color _getReportColor(ReportType type) {
    switch (type) {
      case ReportType.bookings:
        return Colors.blue;
      case ReportType.payments:
        return Colors.green;
      case ReportType.users:
        return Colors.orange;
      case ReportType.specialists:
        return Colors.purple;
      case ReportType.analytics:
        return Colors.teal;
      case ReportType.notifications:
        return Colors.pink;
      case ReportType.errors:
        return Colors.red;
      case ReportType.performance:
        return Colors.indigo;
      default:
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
      await Future.wait([
        _loadReports(),
        _loadTemplates(),
      ]);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReports() async {
    try {
      final reports = await _reportService.getReports();
      setState(() {
        _reports = reports;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки отчетов: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await _reportService.getReportTemplates();
      setState(() {
        _templates = templates;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки шаблонов: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreateReportDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать отчет'),
        content: const Text('Выберите тип отчета для создания'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createCustomReport();
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  void _createCustomReport() {
    // TODO(developer): Реализовать создание пользовательского отчета
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Функция создания пользовательского отчета будет реализована'),
      ),
    );
  }

  void _createReportFromTemplate(ReportTemplate template) {
    // TODO(developer): Реализовать создание отчета по шаблону
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Создание отчета по шаблону "${template.name}" будет реализовано',
        ),
      ),
    );
  }

  void _handleReportAction(String action, Report report) {
    switch (action) {
      case 'view':
        _viewReport(report);
        break;
      case 'download':
        _downloadReport(report);
        break;
      case 'delete':
        _deleteReport(report);
        break;
    }
  }

  void _viewReport(Report report) {
    // TODO(developer): Реализовать просмотр отчета
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Просмотр отчета "${report.name}" будет реализован'),
      ),
    );
  }

  void _downloadReport(Report report) {
    // TODO(developer): Реализовать скачивание отчета
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Скачивание отчета "${report.name}" будет реализовано'),
      ),
    );
  }

  void _deleteReport(Report report) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить отчет'),
        content: Text('Вы уверены, что хотите удалить отчет "${report.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _reportService.deleteReport(report.id);
                _loadReports();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Отчет удален'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка удаления отчета: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
