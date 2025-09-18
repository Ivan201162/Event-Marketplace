import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/external_integration.dart';
import '../services/integration_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран управления интеграциями
class IntegrationManagementScreen extends ConsumerStatefulWidget {
  const IntegrationManagementScreen({super.key});

  @override
  ConsumerState<IntegrationManagementScreen> createState() =>
      _IntegrationManagementScreenState();
}

class _IntegrationManagementScreenState
    extends ConsumerState<IntegrationManagementScreen> {
  final IntegrationService _integrationService = IntegrationService();
  List<ExternalIntegration> _integrations = [];
  bool _isLoading = true;
  String _selectedTab = 'integrations';

  @override
  void initState() {
    super.initState();
    _loadIntegrations();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Управление интеграциями',
      body: Column(
        children: [
          // Вкладки
          _buildTabs(),

          // Контент
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 'integrations'
                    ? _buildIntegrationsTab()
                    : _selectedTab == 'create'
                        ? _buildCreateTab()
                        : _buildSyncHistoryTab(),
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
            child: _buildTabButton(
                'integrations', 'Интеграции', Icons.integration_instructions),
          ),
          Expanded(
            child: _buildTabButton('create', 'Создать', Icons.add),
          ),
          Expanded(
            child: _buildTabButton('history', 'История', Icons.history),
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

  Widget _buildIntegrationsTab() {
    return Column(
      children: [
        // Заголовок с кнопками
        ResponsiveCard(
          child: Row(
            children: [
              ResponsiveText(
                'Внешние интеграции',
                isTitle: true,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loadIntegrations,
                icon: const Icon(Icons.refresh),
                label: const Text('Обновить'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedTab = 'create';
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Создать интеграцию'),
              ),
            ],
          ),
        ),

        // Список интеграций
        Expanded(
          child: _integrations.isEmpty
              ? const Center(child: Text('Интеграции не найдены'))
              : ListView.builder(
                  itemCount: _integrations.length,
                  itemBuilder: (context, index) {
                    final integration = _integrations[index];
                    return _buildIntegrationCard(integration);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildIntegrationCard(ExternalIntegration integration) {
    final statusColor = _getStatusColor(integration.status);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                integration.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      integration.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      integration.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(integration.status),
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleIntegrationAction(value, integration),
                itemBuilder: (context) => [
                  if (integration.isActive) ...[
                    const PopupMenuItem(
                      value: 'deactivate',
                      child: ListTile(
                        leading: Icon(Icons.pause),
                        title: Text('Деактивировать'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'sync',
                      child: ListTile(
                        leading: Icon(Icons.sync),
                        title: Text('Синхронизировать'),
                      ),
                    ),
                  ] else ...[
                    const PopupMenuItem(
                      value: 'activate',
                      child: ListTile(
                        leading: Icon(Icons.play_arrow),
                        title: Text('Активировать'),
                      ),
                    ),
                  ],
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Редактировать'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'test',
                    child: ListTile(
                      leading: Icon(Icons.bug_report),
                      title: Text('Тестировать'),
                    ),
                  ),
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

          // Метаданные
          Row(
            children: [
              _buildInfoChip('Тип', integration.type.displayName, Colors.blue),
              const SizedBox(width: 8),
              _buildInfoChip('Аутентификация', integration.authType.displayName,
                  Colors.green),
            ],
          ),

          const SizedBox(height: 8),

          // URL
          Row(
            children: [
              const Icon(Icons.link, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  integration.baseUrl,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Статус синхронизации
          if (integration.lastSyncAt != null) ...[
            Row(
              children: [
                const Icon(Icons.sync, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Последняя синхронизация: ${_formatDateTime(integration.lastSyncAt!)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Ошибка
          if (integration.hasError) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                'Ошибка: ${integration.lastError}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Время создания
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Создана: ${_formatDateTime(integration.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      child: ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'Создать интеграцию',
              isTitle: true,
            ),

            const SizedBox(height: 16),

            // Форма создания интеграции
            _buildCreateIntegrationForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateIntegrationForm() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final baseUrlController = TextEditingController();
    IntegrationType selectedType = IntegrationType.api;
    AuthenticationType selectedAuthType = AuthenticationType.none;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            // Основная информация
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Название интеграции',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            TextField(
              controller: baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Базовый URL',
                border: OutlineInputBorder(),
                hintText: 'https://api.example.com',
              ),
            ),

            const SizedBox(height: 16),

            // Тип интеграции
            DropdownButtonFormField<IntegrationType>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Тип интеграции',
                border: OutlineInputBorder(),
              ),
              items: IntegrationType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Text(type.icon),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Тип аутентификации
            DropdownButtonFormField<AuthenticationType>(
              value: selectedAuthType,
              decoration: const InputDecoration(
                labelText: 'Тип аутентификации',
                border: OutlineInputBorder(),
              ),
              items: AuthenticationType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedAuthType = value!;
                });
              },
            ),

            const SizedBox(height: 24),

            // Кнопка создания
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _createIntegration(
                  nameController.text,
                  descriptionController.text,
                  baseUrlController.text,
                  selectedType,
                  selectedAuthType,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Создать интеграцию'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSyncHistoryTab() {
    return Column(
      children: [
        // Заголовок
        ResponsiveCard(
          child: Row(
            children: [
              ResponsiveText(
                'История синхронизации',
                isTitle: true,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loadIntegrations,
                icon: const Icon(Icons.refresh),
                label: const Text('Обновить'),
              ),
            ],
          ),
        ),

        // Список истории синхронизации
        Expanded(
          child: _integrations.isEmpty
              ? const Center(child: Text('Интеграции не найдены'))
              : ListView.builder(
                  itemCount: _integrations.length,
                  itemBuilder: (context, index) {
                    final integration = _integrations[index];
                    return _buildSyncHistoryCard(integration);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSyncHistoryCard(ExternalIntegration integration) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                integration.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  integration.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              _buildStatusChip(integration.status),
            ],
          ),

          const SizedBox(height: 12),

          // История синхронизации
          FutureBuilder<List<DataSync>>(
            future:
                _integrationService.getSyncHistory(integration.id, limit: 5),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final syncHistory = snapshot.data!;

              if (syncHistory.isEmpty) {
                return const Text('История синхронизации пуста');
              }

              return Column(
                children:
                    syncHistory.map((sync) => _buildSyncItem(sync)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSyncItem(DataSync sync) {
    final statusColor = _getSyncStatusColor(sync.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getSyncStatusIcon(sync.status),
                color: statusColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${sync.dataType} - ${sync.direction.displayName}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              Text(
                '${sync.syncedRecords}/${sync.totalRecords}',
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Прогресс
          if (sync.totalRecords > 0) ...[
            LinearProgressIndicator(
              value: sync.progressPercentage / 100,
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
            const SizedBox(height: 4),
          ],

          // Время
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Начало: ${_formatDateTime(sync.startedAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
              if (sync.completedAt != null) ...[
                const Spacer(),
                Text(
                  'Завершение: ${_formatDateTime(sync.completedAt!)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ],
          ),

          // Ошибка
          if (sync.hasError && sync.errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              'Ошибка: ${sync.errorMessage}',
              style: const TextStyle(color: Colors.red, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(IntegrationStatus status) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
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

  Color _getStatusColor(IntegrationStatus status) {
    switch (status) {
      case IntegrationStatus.active:
        return Colors.green;
      case IntegrationStatus.inactive:
        return Colors.grey;
      case IntegrationStatus.error:
        return Colors.red;
      case IntegrationStatus.maintenance:
        return Colors.orange;
      case IntegrationStatus.deprecated:
        return Colors.purple;
    }
  }

  Color _getSyncStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
        return Colors.orange;
      case SyncStatus.inProgress:
        return Colors.blue;
      case SyncStatus.completed:
        return Colors.green;
      case SyncStatus.failed:
        return Colors.red;
      case SyncStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getSyncStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
        return Icons.schedule;
      case SyncStatus.inProgress:
        return Icons.sync;
      case SyncStatus.completed:
        return Icons.check_circle;
      case SyncStatus.failed:
        return Icons.error;
      case SyncStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadIntegrations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _integrationService.initialize();
      final integrations = _integrationService.getIntegrations();
      setState(() {
        _integrations = integrations;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки интеграций: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleIntegrationAction(
      String action, ExternalIntegration integration) {
    switch (action) {
      case 'activate':
        _activateIntegration(integration);
        break;
      case 'deactivate':
        _deactivateIntegration(integration);
        break;
      case 'sync':
        _syncIntegration(integration);
        break;
      case 'edit':
        _editIntegration(integration);
        break;
      case 'test':
        _testIntegration(integration);
        break;
      case 'delete':
        _deleteIntegration(integration);
        break;
    }
  }

  Future<void> _activateIntegration(ExternalIntegration integration) async {
    try {
      await _integrationService.activateIntegration(integration.id);
      _loadIntegrations();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Интеграция "${integration.name}" активирована'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка активации интеграции: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deactivateIntegration(ExternalIntegration integration) async {
    try {
      await _integrationService.deactivateIntegration(integration.id);
      _loadIntegrations();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Интеграция "${integration.name}" деактивирована'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка деактивации интеграции: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _syncIntegration(ExternalIntegration integration) async {
    try {
      await _integrationService.performManualSync(integration.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Синхронизация "${integration.name}" запущена'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка синхронизации: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editIntegration(ExternalIntegration integration) {
    // TODO: Реализовать редактирование интеграции
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Редактирование интеграции "${integration.name}" будет реализовано'),
      ),
    );
  }

  void _testIntegration(ExternalIntegration integration) {
    // TODO: Реализовать тестирование интеграции
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Тестирование интеграции "${integration.name}" будет реализовано'),
      ),
    );
  }

  void _deleteIntegration(ExternalIntegration integration) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить интеграцию'),
        content: Text(
            'Вы уверены, что хотите удалить интеграцию "${integration.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _integrationService.deleteIntegration(integration.id);
                _loadIntegrations();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Интеграция удалена'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка удаления интеграции: $e'),
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

  Future<void> _createIntegration(
    String name,
    String description,
    String baseUrl,
    IntegrationType type,
    AuthenticationType authType,
  ) async {
    if (name.isEmpty || description.isEmpty || baseUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заполните все обязательные поля'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _integrationService.createIntegration(
        name: name,
        description: description,
        type: type,
        baseUrl: baseUrl,
        authType: authType,
      );

      _loadIntegrations();
      setState(() {
        _selectedTab = 'integrations';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Интеграция "$name" создана'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка создания интеграции: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
