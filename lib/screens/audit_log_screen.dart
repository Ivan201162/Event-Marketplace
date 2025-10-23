import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_log.dart';
import '../services/audit_logging_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран аудита логов
class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  final AuditLoggingService _auditService = AuditLoggingService();
  List<AuditLog> _auditLogs = [];
  List<SystemLog> _systemLogs = [];
  bool _isLoading = true;
  String _selectedTab = 'audit';
  Map<String, dynamic> _statistics = {};

  // Фильтры
  String? _selectedUserId;
  String? _selectedAction;
  String? _selectedResource;
  AuditLogLevel? _selectedLevel;
  AuditLogCategory? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupStreams();
  }

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
        appBar: AppBar(title: const Text('Аудит и логирование')),
        body: Column(
          children: [
            // Вкладки
            _buildTabs(),

            // Фильтры
            _buildFilters(),

            // Статистика
            _buildStatistics(),

            // Контент
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedTab == 'audit'
                      ? _buildAuditLogsTab()
                      : _buildSystemLogsTab(),
            ),
          ],
        ),
      );

  Widget _buildTabs() => ResponsiveCard(
        child: Row(
          children: [
            Expanded(
                child:
                    _buildTabButton('audit', 'Аудит действий', Icons.security)),
            Expanded(
                child: _buildTabButton(
                    'system', 'Системные логи', Icons.bug_report)),
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
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected
                  ? Colors.blue
                  : Colors.grey.withValues(alpha: 0.3)),
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
                // Фильтр по пользователю
                DropdownButton<String?>(
                  value: _selectedUserId,
                  hint: const Text('Все пользователи'),
                  items: const [
                    DropdownMenuItem<String?>(child: Text('Все пользователи')),
                    // TODO(developer): Загрузить список пользователей
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedUserId = value;
                    });
                    _loadData();
                  },
                ),

                // Фильтр по действию
                DropdownButton<String?>(
                  value: _selectedAction,
                  hint: const Text('Все действия'),
                  items: const [
                    DropdownMenuItem<String?>(child: Text('Все действия')),
                    DropdownMenuItem<String?>(
                        value: 'create', child: Text('Создание')),
                    DropdownMenuItem<String?>(
                        value: 'update', child: Text('Обновление')),
                    DropdownMenuItem<String?>(
                        value: 'delete', child: Text('Удаление')),
                    DropdownMenuItem<String?>(
                        value: 'login', child: Text('Вход')),
                    DropdownMenuItem<String?>(
                        value: 'logout', child: Text('Выход')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAction = value;
                    });
                    _loadData();
                  },
                ),

                // Фильтр по ресурсу
                DropdownButton<String?>(
                  value: _selectedResource,
                  hint: const Text('Все ресурсы'),
                  items: const [
                    DropdownMenuItem<String?>(child: Text('Все ресурсы')),
                    DropdownMenuItem<String?>(
                        value: 'user', child: Text('Пользователь')),
                    DropdownMenuItem<String?>(
                        value: 'booking', child: Text('Бронирование')),
                    DropdownMenuItem<String?>(
                        value: 'specialist', child: Text('Специалист')),
                    DropdownMenuItem<String?>(
                        value: 'payment', child: Text('Платеж')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedResource = value;
                    });
                    _loadData();
                  },
                ),

                // Фильтр по уровню
                DropdownButton<AuditLogLevel?>(
                  value: _selectedLevel,
                  hint: const Text('Все уровни'),
                  items: [
                    const DropdownMenuItem<AuditLogLevel?>(
                        child: Text('Все уровни')),
                    ...AuditLogLevel.values.map(
                      (level) => DropdownMenuItem<AuditLogLevel?>(
                        value: level,
                        child: Text('${level.icon} ${level.displayName}'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedLevel = value;
                    });
                    _loadData();
                  },
                ),

                // Фильтр по категории
                DropdownButton<AuditLogCategory?>(
                  value: _selectedCategory,
                  hint: const Text('Все категории'),
                  items: [
                    const DropdownMenuItem<AuditLogCategory?>(
                        child: Text('Все категории')),
                    ...AuditLogCategory.values.map(
                      (category) => DropdownMenuItem<AuditLogCategory?>(
                        value: category,
                        child: Text('${category.icon} ${category.displayName}'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                    _loadData();
                  },
                ),

                // Кнопка сброса фильтров
                ElevatedButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('Сбросить'),
                ),

                // Кнопка экспорта
                ElevatedButton.icon(
                  onPressed: _exportLogs,
                  icon: const Icon(Icons.download),
                  label: const Text('Экспорт'),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildStatistics() {
    if (_statistics.isEmpty) return const SizedBox.shrink();

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Статистика', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Всего аудита логов',
                  '${_statistics['auditLogs']?['total'] ?? 0}',
                  Icons.security,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Всего системных логов',
                  '${_statistics['systemLogs']?['total'] ?? 0}',
                  Icons.bug_report,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Успешность действий',
                  '${((_statistics['auditLogs']?['successRate'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
          String title, String value, IconData icon, Color color) =>
      Container(
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
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _buildAuditLogsTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                Text('Аудит действий пользователей',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Обновить'),
                ),
              ],
            ),
          ),

          // Список аудита логов
          Expanded(
            child: _auditLogs.isEmpty
                ? const Center(child: Text('Аудит логи не найдены'))
                : ListView.builder(
                    itemCount: _auditLogs.length,
                    itemBuilder: (context, index) {
                      final log = _auditLogs[index];
                      return _buildAuditLogCard(log);
                    },
                  ),
          ),
        ],
      );

  Widget _buildAuditLogCard(AuditLog log) {
    final levelColor = _getLevelColor(log.level);
    final categoryColor = _getCategoryColor(log.category);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(log.level.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.action,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${log.resource}: ${log.resourceId}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: levelColor),
                ),
                child: Text(
                  log.level.displayName,
                  style: TextStyle(
                      fontSize: 12,
                      color: levelColor,
                      fontWeight: FontWeight.bold),
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
                  log.category.displayName,
                  style: TextStyle(
                      fontSize: 12,
                      color: categoryColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleAuditLogAction(value, log),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('Просмотр')),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: ListTile(
                        leading: Icon(Icons.download), title: Text('Экспорт')),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Детали
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Пользователь: ${log.userEmail}'),
                if (log.description != null)
                  Text('Описание: ${log.description}'),
                if (log.errorMessage != null)
                  Text('Ошибка: ${log.errorMessage}',
                      style: const TextStyle(color: Colors.red)),
                Text('Статус: ${log.isSuccess ? "Успешно" : "Ошибка"}'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Метаданные
          Row(
            children: [
              _buildInfoChip('IP', log.ipAddress ?? 'N/A', Colors.blue),
              const SizedBox(width: 8),
              _buildInfoChip('Сессия', log.sessionId ?? 'N/A', Colors.green),
            ],
          ),

          const SizedBox(height: 8),

          // Время
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Время: ${_formatDateTime(log.timestamp)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemLogsTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                Text('Системные логи',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Обновить'),
                ),
              ],
            ),
          ),

          // Список системных логов
          Expanded(
            child: _systemLogs.isEmpty
                ? const Center(child: Text('Системные логи не найдены'))
                : ListView.builder(
                    itemCount: _systemLogs.length,
                    itemBuilder: (context, index) {
                      final log = _systemLogs[index];
                      return _buildSystemLogCard(log);
                    },
                  ),
          ),
        ],
      );

  Widget _buildSystemLogCard(SystemLog log) {
    final levelColor = _getSystemLevelColor(log.level);
    final categoryColor = _getSystemCategoryColor(log.category);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(log.level.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.component,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(log.message, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: levelColor),
                ),
                child: Text(
                  log.level.displayName,
                  style: TextStyle(
                      fontSize: 12,
                      color: levelColor,
                      fontWeight: FontWeight.bold),
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
                  log.category.displayName,
                  style: TextStyle(
                      fontSize: 12,
                      color: categoryColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleSystemLogAction(value, log),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('Просмотр')),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: ListTile(
                        leading: Icon(Icons.download), title: Text('Экспорт')),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Детали
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (log.context != null) Text('Контекст: ${log.context}'),
                if (log.stackTrace != null)
                  Text('Stack Trace: ${log.stackTrace}',
                      style: const TextStyle(color: Colors.red)),
                if (log.sessionId != null) Text('Сессия: ${log.sessionId}'),
                if (log.requestId != null) Text('Запрос: ${log.requestId}'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Время
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Время: ${_formatDateTime(log.timestamp)}',
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
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      );

  Color _getLevelColor(AuditLogLevel level) {
    switch (level) {
      case AuditLogLevel.debug:
        return Colors.grey;
      case AuditLogLevel.info:
        return Colors.blue;
      case AuditLogLevel.warning:
        return Colors.orange;
      case AuditLogLevel.error:
        return Colors.red;
      case AuditLogLevel.critical:
        return Colors.purple;
    }
  }

  Color _getCategoryColor(AuditLogCategory category) {
    switch (category) {
      case AuditLogCategory.authentication:
        return Colors.blue;
      case AuditLogCategory.authorization:
        return Colors.green;
      case AuditLogCategory.userManagement:
        return Colors.orange;
      case AuditLogCategory.bookingManagement:
        return Colors.purple;
      case AuditLogCategory.paymentProcessing:
        return Colors.red;
      case AuditLogCategory.specialistManagement:
        return Colors.teal;
      case AuditLogCategory.contentManagement:
        return Colors.brown;
      case AuditLogCategory.systemConfiguration:
        return Colors.indigo;
      case AuditLogCategory.security:
        return Colors.red;
      case AuditLogCategory.dataExport:
        return Colors.cyan;
      case AuditLogCategory.dataImport:
        return Colors.lime;
      case AuditLogCategory.apiAccess:
        return Colors.pink;
      case AuditLogCategory.general:
        return Colors.grey;
    }
  }

  Color _getSystemLevelColor(SystemLogLevel level) {
    switch (level) {
      case SystemLogLevel.trace:
        return Colors.grey;
      case SystemLogLevel.debug:
        return Colors.grey;
      case SystemLogLevel.info:
        return Colors.blue;
      case SystemLogLevel.warning:
        return Colors.orange;
      case SystemLogLevel.error:
        return Colors.red;
      case SystemLogLevel.fatal:
        return Colors.purple;
    }
  }

  Color _getSystemCategoryColor(SystemLogCategory category) {
    switch (category) {
      case SystemLogCategory.database:
        return Colors.blue;
      case SystemLogCategory.network:
        return Colors.green;
      case SystemLogCategory.authentication:
        return Colors.orange;
      case SystemLogCategory.authorization:
        return Colors.purple;
      case SystemLogCategory.businessLogic:
        return Colors.red;
      case SystemLogCategory.externalApi:
        return Colors.teal;
      case SystemLogCategory.fileSystem:
        return Colors.brown;
      case SystemLogCategory.cache:
        return Colors.indigo;
      case SystemLogCategory.queue:
        return Colors.cyan;
      case SystemLogCategory.scheduler:
        return Colors.lime;
      case SystemLogCategory.general:
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
      await _auditService.initialize();

      if (_selectedTab == 'audit') {
        _auditLogs = await _auditService.getAuditLogs(
          userId: _selectedUserId,
          action: _selectedAction,
          resource: _selectedResource,
          level: _selectedLevel,
          category: _selectedCategory,
          startDate: _startDate,
          endDate: _endDate,
        );
      } else {
        _systemLogs = await _auditService.getSystemLogs(
          level: _selectedLevel != null
              ? SystemLogLevel.fromString(_selectedLevel!.value)
              : null,
          startDate: _startDate,
          endDate: _endDate,
        );
      }

      _statistics = await _auditService.getLogStatistics(
          startDate: _startDate, endDate: _endDate);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка загрузки данных: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupStreams() {
    _auditService.auditLogStream.listen((log) {
      setState(() {
        _auditLogs.insert(0, log);
        if (_auditLogs.length > 100) {
          _auditLogs = _auditLogs.take(100).toList();
        }
      });
    });

    _auditService.systemLogStream.listen((log) {
      setState(() {
        _systemLogs.insert(0, log);
        if (_systemLogs.length > 100) {
          _systemLogs = _systemLogs.take(100).toList();
        }
      });
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedUserId = null;
      _selectedAction = null;
      _selectedResource = null;
      _selectedLevel = null;
      _selectedCategory = null;
      _startDate = null;
      _endDate = null;
    });
    _loadData();
  }

  Future<void> _exportLogs() async {
    try {
      final startDate =
          _startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final endDate = _endDate ?? DateTime.now();

      final exportData = await _auditService.exportLogs(
        startDate: startDate,
        endDate: endDate,
        includeAuditLogs: _selectedTab == 'audit',
        includeSystemLogs: _selectedTab == 'system',
      );

      // TODO(developer): Реализовать сохранение файла
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Экспорт завершен. Размер: ${exportData.length} символов')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
          content: Text('Ошибка экспорта: $e'), backgroundColor: Colors.red));
    }
  }

  void _handleAuditLogAction(String action, AuditLog log) {
    switch (action) {
      case 'view':
        _viewAuditLog(log);
        break;
      case 'export':
        _exportSingleLog(log);
        break;
    }
  }

  void _handleSystemLogAction(String action, SystemLog log) {
    switch (action) {
      case 'view':
        _viewSystemLog(log);
        break;
      case 'export':
        _exportSingleSystemLog(log);
        break;
    }
  }

  void _viewAuditLog(AuditLog log) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Аудит лог: ${log.action}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Пользователь: ${log.userEmail}'),
              Text('Действие: ${log.action}'),
              Text('Ресурс: ${log.resource}'),
              Text('ID ресурса: ${log.resourceId}'),
              Text('Уровень: ${log.level.displayName}'),
              Text('Категория: ${log.category.displayName}'),
              Text('Время: ${_formatDateTime(log.timestamp)}'),
              Text('Статус: ${log.isSuccess ? "Успешно" : "Ошибка"}'),
              if (log.description != null) Text('Описание: ${log.description}'),
              if (log.errorMessage != null) Text('Ошибка: ${log.errorMessage}'),
              if (log.ipAddress != null) Text('IP: ${log.ipAddress}'),
              if (log.userAgent != null) Text('User Agent: ${log.userAgent}'),
              if (log.sessionId != null) Text('Сессия: ${log.sessionId}'),
              if (log.oldData != null) ...[
                const SizedBox(height: 8),
                const Text('Старые данные:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(log.oldData.toString()),
              ],
              if (log.newData != null) ...[
                const SizedBox(height: 8),
                const Text('Новые данные:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(log.newData.toString()),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть')),
        ],
      ),
    );
  }

  void _viewSystemLog(SystemLog log) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Системный лог: ${log.component}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Компонент: ${log.component}'),
              Text('Сообщение: ${log.message}'),
              Text('Уровень: ${log.level.displayName}'),
              Text('Категория: ${log.category.displayName}'),
              Text('Время: ${_formatDateTime(log.timestamp)}'),
              if (log.context != null) Text('Контекст: ${log.context}'),
              if (log.stackTrace != null) ...[
                const SizedBox(height: 8),
                const Text('Stack Trace:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(log.stackTrace!),
              ],
              if (log.sessionId != null) Text('Сессия: ${log.sessionId}'),
              if (log.requestId != null) Text('Запрос: ${log.requestId}'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть')),
        ],
      ),
    );
  }

  void _exportSingleLog(AuditLog log) {
    // TODO(developer): Реализовать экспорт отдельного лога
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(
        content: Text('Экспорт лога "${log.action}" будет реализован')));
  }

  void _exportSingleSystemLog(SystemLog log) {
    // TODO(developer): Реализовать экспорт отдельного системного лога
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Экспорт системного лога "${log.component}" будет реализован')),
    );
  }
}
