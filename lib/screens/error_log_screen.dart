import 'package:event_marketplace_app/models/app_error.dart';
import 'package:event_marketplace_app/services/error_logger_service.dart';
import 'package:event_marketplace_app/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран журнала ошибок
class ErrorLogScreen extends ConsumerStatefulWidget {
  const ErrorLogScreen({super.key});

  @override
  ConsumerState<ErrorLogScreen> createState() => _ErrorLogScreenState();
}

class _ErrorLogScreenState extends ConsumerState<ErrorLogScreen> {
  final ErrorLoggerService _errorLogger = ErrorLoggerService();
  List<AppError> _errors = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _selectedSort = 'timestamp';
  bool _showResolvedOnly = false;

  @override
  void initState() {
    super.initState();
    _loadErrors();
  }

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
        appBar: AppBar(title: const Text('Журнал ошибок')),
        body: Column(
          children: [
            // Фильтры и сортировка
            _buildFilters(),

            // Статистика
            _buildStatistics(),

            // Список ошибок
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errors.isEmpty
                      ? const Center(child: Text('Ошибки не найдены'))
                      : _buildErrorsList(),
            ),
          ],
        ),
      );

  Widget _buildFilters() => ResponsiveCard(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedFilter,
                    decoration: const InputDecoration(
                      labelText: 'Фильтр по типу',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Все')),
                      DropdownMenuItem(
                          value: 'flutter_error',
                          child: Text('Flutter ошибки'),),
                      DropdownMenuItem(
                          value: 'network_error',
                          child: Text('Сетевые ошибки'),),
                      DropdownMenuItem(
                          value: 'validation_error',
                          child: Text('Ошибки валидации'),),
                      DropdownMenuItem(
                          value: 'ui_error', child: Text('UI ошибки'),),
                      DropdownMenuItem(
                          value: 'user_error',
                          child: Text('Пользовательские ошибки'),),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                      });
                      _loadErrors();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSort,
                    decoration: const InputDecoration(
                      labelText: 'Сортировка',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'timestamp', child: Text('По времени'),),
                      DropdownMenuItem(
                          value: 'errorType', child: Text('По типу'),),
                      DropdownMenuItem(
                          value: 'screen', child: Text('По экрану'),),
                      DropdownMenuItem(
                          value: 'severity', child: Text('По критичности'),),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSort = value!;
                      });
                      _sortErrors();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _showResolvedOnly,
                  onChanged: (value) {
                    setState(() {
                      _showResolvedOnly = value ?? false;
                    });
                    _loadErrors();
                  },
                ),
                const Text('Показать только решенные'),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _exportErrors,
                  icon: const Icon(Icons.download),
                  label: const Text('Экспорт CSV'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _cleanupOldErrors,
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Очистить старые'),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildStatistics() => FutureBuilder<ErrorStatistics>(
        future: _errorLogger.getErrorStatistics(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final stats = snapshot.data!;

          return ResponsiveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Статистика ошибок',
                    style: Theme.of(context).textTheme.titleMedium,),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Всего ошибок',
                        '${stats.totalErrors}',
                        Colors.blue,
                        Icons.bug_report,
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        'Решено',
                        '${stats.resolvedErrors}',
                        Colors.green,
                        Icons.check_circle,
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        'Критических',
                        '${stats.criticalErrors}',
                        Colors.red,
                        Icons.warning,
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        'Недавних',
                        '${stats.recentErrors}',
                        Colors.orange,
                        Icons.schedule,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

  Widget _buildStatCard(
          String title, String value, Color color, IconData icon,) =>
      Container(
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
                  fontSize: 20, fontWeight: FontWeight.bold, color: color,),
            ),
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),),
          ],
        ),
      );

  Widget _buildErrorsList() => ListView.builder(
        itemCount: _errors.length,
        itemBuilder: (context, index) {
          final error = _errors[index];
          return _buildErrorCard(error);
        },
      );

  Widget _buildErrorCard(AppError error) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Icon(_getErrorIcon(error.errorType),
                    color: error.severity.color, size: 24,),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(error.errorType,
                        style: Theme.of(context).textTheme.titleMedium,),),
                _buildSeverityChip(error.severity),
                if (error.resolved) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Решено',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Сообщение об ошибке
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: error.severity.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: error.severity.color),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(error.shortDescription,
                      style: Theme.of(context).textTheme.bodyMedium,),
                  if (error.stackTrace != null) ...[
                    const SizedBox(height: 8),
                    ExpansionTile(
                      title: const Text('Stack Trace'),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            error.stackTrace!,
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 12,),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Метаданные
            Row(
              children: [
                Expanded(
                    child: _buildMetadataItem(
                        'Экран', error.screen, Icons.screen_share,),),
                Expanded(
                    child: _buildMetadataItem(
                        'Устройство', error.device, Icons.phone_android,),),
              ],
            ),

            if (error.userId != null) ...[
              const SizedBox(height: 8),
              _buildMetadataItem('Пользователь', error.userId!, Icons.person),
            ],

            const SizedBox(height: 12),

            // Время и действия
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${error.timestamp.day}.${error.timestamp.month}.${error.timestamp.year} ${error.timestamp.hour}:${error.timestamp.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                if (!error.resolved) ...[
                  ElevatedButton(
                    onPressed: () => _markAsResolved(error.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Решено'),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () => _markAsUnresolved(error.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Не решено'),
                  ),
                ],
              ],
            ),
          ],
        ),
      );

  Widget _buildSeverityChip(ErrorSeverity severity) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: severity.color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: severity.color),
        ),
        child: Text(
          severity.displayName,
          style: TextStyle(
              fontSize: 12, color: severity.color, fontWeight: FontWeight.bold,),
        ),
      );

  Widget _buildMetadataItem(String label, String value, IconData icon) => Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500,),),
                Text(label,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),),
              ],
            ),
          ),
        ],
      );

  IconData _getErrorIcon(String errorType) {
    switch (errorType) {
      case 'flutter_error':
        return Icons.error;
      case 'network_error':
        return Icons.wifi_off;
      case 'validation_error':
        return Icons.rule;
      case 'ui_error':
        return Icons.bug_report;
      case 'user_error':
        return Icons.person_off;
      default:
        return Icons.warning;
    }
  }

  Future<void> _loadErrors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<AppError> errors;

      if (_selectedFilter == 'all') {
        errors = await _errorLogger.getAllErrors(
          resolvedOnly: _showResolvedOnly,
          unresolvedOnly: !_showResolvedOnly && _showResolvedOnly,
        );
      } else {
        errors = await _errorLogger.getErrorsByType(_selectedFilter);
        if (_showResolvedOnly) {
          errors = errors.where((e) => e.resolved).toList();
        }
      }

      setState(() {
        _errors = errors;
        _isLoading = false;
      });

      _sortErrors();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
          content: Text('Ошибка загрузки: $e'), backgroundColor: Colors.red,),);
    }
  }

  void _sortErrors() {
    setState(() {
      switch (_selectedSort) {
        case 'timestamp':
          _errors.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        case 'errorType':
          _errors.sort((a, b) => a.errorType.compareTo(b.errorType));
        case 'screen':
          _errors.sort((a, b) => a.screen.compareTo(b.screen));
        case 'severity':
          _errors.sort((a, b) => b.severity.index.compareTo(a.severity.index));
      }
    });
  }

  Future<void> _markAsResolved(String errorId) async {
    try {
      await _errorLogger.markErrorAsResolved(errorId);
      _loadErrors();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка отмечена как решенная'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),);
    }
  }

  Future<void> _markAsUnresolved(String errorId) async {
    try {
      await _errorLogger.markErrorAsUnresolved(errorId);
      _loadErrors();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка отмечена как нерешенная'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),);
    }
  }

  Future<void> _exportErrors() async {
    try {
      final csv = await _errorLogger.exportErrorsToCSV(_errors);
      // TODO(developer): Реализовать сохранение файла
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Экспорт завершен'), backgroundColor: Colors.green,),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
          content: Text('Ошибка экспорта: $e'), backgroundColor: Colors.red,),);
    }
  }

  Future<void> _cleanupOldErrors() async {
    try {
      await _errorLogger.cleanupOldErrors();
      _loadErrors();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Старые ошибки очищены'),
            backgroundColor: Colors.green,),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
          content: Text('Ошибка очистки: $e'), backgroundColor: Colors.red,),);
    }
  }
}
