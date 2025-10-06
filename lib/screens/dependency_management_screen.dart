import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dependency_management.dart';
import '../services/dependency_management_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран управления зависимостями
class DependencyManagementScreen extends ConsumerStatefulWidget {
  const DependencyManagementScreen({super.key});

  @override
  ConsumerState<DependencyManagementScreen> createState() =>
      _DependencyManagementScreenState();
}

class _DependencyManagementScreenState
    extends ConsumerState<DependencyManagementScreen> {
  final DependencyManagementService _dependencyService =
      DependencyManagementService();
  List<Dependency> _dependencies = [];
  List<DependencyUpdate> _updates = [];
  bool _isLoading = true;
  String _selectedTab = 'dependencies';
  Map<String, dynamic> _analysis = {};

  // Фильтры
  DependencyType? _selectedType;
  DependencyStatus? _selectedStatus;
  UpdateType? _selectedUpdateType;
  UpdatePriority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupStreams();
  }

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
        appBar: AppBar(title: const Text('Управление зависимостями')),
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
                  : _selectedTab == 'dependencies'
                      ? _buildDependenciesTab()
                      : _buildUpdatesTab(),
            ),
          ],
        ),
      );

  Widget _buildTabs() => ResponsiveCard(
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                'dependencies',
                'Зависимости',
                Icons.inventory,
              ),
            ),
            Expanded(
              child:
                  _buildTabButton('updates', 'Обновления', Icons.system_update),
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

  Widget _buildFilters() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Фильтры',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Фильтр по типу
                DropdownButton<DependencyType?>(
                  value: _selectedType,
                  hint: const Text('Все типы'),
                  items: [
                    const DropdownMenuItem<DependencyType?>(
                      child: Text('Все типы'),
                    ),
                    ...DependencyType.values.map(
                      (type) => DropdownMenuItem<DependencyType?>(
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
                DropdownButton<DependencyStatus?>(
                  value: _selectedStatus,
                  hint: const Text('Все статусы'),
                  items: [
                    const DropdownMenuItem<DependencyStatus?>(
                      child: Text('Все статусы'),
                    ),
                    ...DependencyStatus.values.map(
                      (status) => DropdownMenuItem<DependencyStatus?>(
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

                // Фильтр по типу обновления
                if (_selectedTab == 'updates')
                  DropdownButton<UpdateType?>(
                    value: _selectedUpdateType,
                    hint: const Text('Все типы обновлений'),
                    items: [
                      const DropdownMenuItem<UpdateType?>(
                        child: Text('Все типы обновлений'),
                      ),
                      ...UpdateType.values.map(
                        (type) => DropdownMenuItem<UpdateType?>(
                          value: type,
                          child: Text('${type.icon} ${type.displayName}'),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedUpdateType = value;
                      });
                    },
                  ),

                // Фильтр по приоритету
                if (_selectedTab == 'updates')
                  DropdownButton<UpdatePriority?>(
                    value: _selectedPriority,
                    hint: const Text('Все приоритеты'),
                    items: [
                      const DropdownMenuItem<UpdatePriority?>(
                        child: Text('Все приоритеты'),
                      ),
                      ...UpdatePriority.values.map(
                        (priority) => DropdownMenuItem<UpdatePriority?>(
                          value: priority,
                          child: Text(
                            '${priority.icon} ${priority.displayName}',
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPriority = value;
                      });
                    },
                  ),

                // Кнопка сброса фильтров
                ElevatedButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('Сбросить'),
                ),

                // Кнопка проверки обновлений
                ElevatedButton.icon(
                  onPressed: _checkForUpdates,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Проверить обновления'),
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
          Text(
            'Анализ зависимостей',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAnalysisCard(
                  'Всего зависимостей',
                  '${_analysis['total'] ?? 0}',
                  Icons.inventory,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalysisCard(
                  'Устаревшие',
                  '${_analysis['outdated'] ?? 0}',
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalysisCard(
                  'Уязвимые',
                  '${_analysis['vulnerable'] ?? 0}',
                  Icons.warning,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalysisCard(
                  'Обновления доступны',
                  '${_analysis['updatesAvailable'] ?? 0}',
                  Icons.system_update,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) =>
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildDependenciesTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                Text(
                  'Зависимости',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddDependencyDialog,
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

          // Список зависимостей
          Expanded(
            child: _getFilteredDependencies().isEmpty
                ? const Center(child: Text('Зависимости не найдены'))
                : ListView.builder(
                    itemCount: _getFilteredDependencies().length,
                    itemBuilder: (context, index) {
                      final dependency = _getFilteredDependencies()[index];
                      return _buildDependencyCard(dependency);
                    },
                  ),
          ),
        ],
      );

  Widget _buildDependencyCard(Dependency dependency) {
    final typeColor = _getTypeColor(dependency.type);
    final statusColor = _getStatusColor(dependency.status);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                dependency.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dependency.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'v${dependency.version}',
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
                  dependency.type.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: typeColor,
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
                  dependency.status.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleDependencyAction(value, dependency),
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
                    value: 'update',
                    child: ListTile(
                      leading: Icon(Icons.system_update),
                      title: Text('Обновить'),
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Описание
          if (dependency.description != null)
            Text(
              dependency.description!,
              style: const TextStyle(fontSize: 14),
            ),

          const SizedBox(height: 12),

          // Метаданные
          Row(
            children: [
              if (dependency.latestVersion != null)
                _buildInfoChip(
                  'Последняя версия',
                  'v${dependency.latestVersion}',
                  Colors.green,
                ),
              const SizedBox(width: 8),
              _buildInfoChip(
                'Зависимости',
                '${dependency.dependencies.length}',
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                'Зависимые',
                '${dependency.dependents.length}',
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
                'Обновлен: ${_formatDateTime(dependency.updatedAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                Text(
                  'Обновления',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _checkForUpdates,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Проверить'),
                ),
              ],
            ),
          ),

          // Список обновлений
          Expanded(
            child: _getFilteredUpdates().isEmpty
                ? const Center(child: Text('Обновления не найдены'))
                : ListView.builder(
                    itemCount: _getFilteredUpdates().length,
                    itemBuilder: (context, index) {
                      final update = _getFilteredUpdates()[index];
                      return _buildUpdateCard(update);
                    },
                  ),
          ),
        ],
      );

  Widget _buildUpdateCard(DependencyUpdate update) {
    final typeColor = _getUpdateTypeColor(update.type);
    final priorityColor = _getPriorityColor(update.priority);
    final dependency = _dependencies.firstWhere(
      (d) => d.id == update.dependencyId,
      orElse: () => Dependency(
        id: '',
        name: 'Unknown',
        version: '',
        type: DependencyType.package,
        status: DependencyStatus.active,
        licenses: [],
        authors: [],
        metadata: {},
        dependencies: [],
        dependents: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: '',
        updatedBy: '',
      ),
    );

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                update.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dependency.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${update.currentVersion} → ${update.newVersion}',
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
                  update.type.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: priorityColor),
                ),
                child: Text(
                  update.priority.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: priorityColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleUpdateAction(value, update),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: ListTile(
                      leading: Icon(Icons.visibility),
                      title: Text('Просмотр'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'apply',
                    child: ListTile(
                      leading: Icon(Icons.check),
                      title: Text('Применить'),
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Детали обновления
          if (update.changelog != null)
            Text(
              update.changelog!,
              style: const TextStyle(fontSize: 14),
            ),

          const SizedBox(height: 12),

          // Метаданные
          Row(
            children: [
              if (update.securityFixes.isNotEmpty)
                _buildInfoChip(
                  'Исправления безопасности',
                  '${update.securityFixes.length}',
                  Colors.red,
                ),
              const SizedBox(width: 8),
              if (update.bugFixes.isNotEmpty)
                _buildInfoChip(
                  'Исправления ошибок',
                  '${update.bugFixes.length}',
                  Colors.orange,
                ),
              const SizedBox(width: 8),
              if (update.newFeatures.isNotEmpty)
                _buildInfoChip(
                  'Новые функции',
                  '${update.newFeatures.length}',
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
                'Выпущено: ${_formatDateTime(update.releaseDate)}',
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
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  Color _getTypeColor(DependencyType type) {
    switch (type) {
      case DependencyType.package:
        return Colors.blue;
      case DependencyType.library:
        return Colors.green;
      case DependencyType.framework:
        return Colors.purple;
      case DependencyType.tool:
        return Colors.orange;
      case DependencyType.service:
        return Colors.teal;
      case DependencyType.api:
        return Colors.cyan;
      case DependencyType.database:
        return Colors.brown;
      case DependencyType.cache:
        return Colors.indigo;
      case DependencyType.queue:
        return Colors.pink;
      case DependencyType.storage:
        return Colors.grey;
    }
  }

  Color _getStatusColor(DependencyStatus status) {
    switch (status) {
      case DependencyStatus.active:
        return Colors.green;
      case DependencyStatus.deprecated:
        return Colors.orange;
      case DependencyStatus.vulnerable:
        return Colors.red;
      case DependencyStatus.outdated:
        return Colors.yellow;
      case DependencyStatus.blocked:
        return Colors.red;
      case DependencyStatus.testing:
        return Colors.blue;
      case DependencyStatus.maintenance:
        return Colors.purple;
    }
  }

  Color _getUpdateTypeColor(UpdateType type) {
    switch (type) {
      case UpdateType.patch:
        return Colors.green;
      case UpdateType.minor:
        return Colors.blue;
      case UpdateType.major:
        return Colors.purple;
      case UpdateType.breaking:
        return Colors.red;
    }
  }

  Color _getPriorityColor(UpdatePriority priority) {
    switch (priority) {
      case UpdatePriority.low:
        return Colors.green;
      case UpdatePriority.medium:
        return Colors.yellow;
      case UpdatePriority.high:
        return Colors.orange;
      case UpdatePriority.critical:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

  List<Dependency> _getFilteredDependencies() {
    var filtered = _dependencies;

    if (_selectedType != null) {
      filtered = filtered.where((d) => d.type == _selectedType).toList();
    }

    if (_selectedStatus != null) {
      filtered = filtered.where((d) => d.status == _selectedStatus).toList();
    }

    return filtered;
  }

  List<DependencyUpdate> _getFilteredUpdates() {
    var filtered = _updates;

    if (_selectedUpdateType != null) {
      filtered = filtered.where((u) => u.type == _selectedUpdateType).toList();
    }

    if (_selectedPriority != null) {
      filtered =
          filtered.where((u) => u.priority == _selectedPriority).toList();
    }

    return filtered;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _dependencyService.initialize();
      setState(() {
        _dependencies = _dependencyService.getAllDependencies();
        _updates = _dependencyService.getUpdates();
      });

      _analysis = await _dependencyService.analyzeDependencies();
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
    _dependencyService.dependencyStream.listen((dependency) {
      setState(() {
        final index = _dependencies.indexWhere((d) => d.id == dependency.id);
        if (index != -1) {
          _dependencies[index] = dependency;
        } else {
          _dependencies.add(dependency);
        }
      });
    });

    _dependencyService.updateStream.listen((update) {
      setState(() {
        final index = _updates.indexWhere((u) => u.id == update.id);
        if (index != -1) {
          _updates[index] = update;
        } else {
          _updates.add(update);
        }
      });
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedType = null;
      _selectedStatus = null;
      _selectedUpdateType = null;
      _selectedPriority = null;
    });
  }

  Future<void> _checkForUpdates() async {
    try {
      final updates = await _dependencyService.checkForUpdates();
      setState(() {
        _updates = _dependencyService.getUpdates();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Найдено ${updates.length} обновлений'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка проверки обновлений: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleDependencyAction(String action, Dependency dependency) {
    switch (action) {
      case 'view':
        _viewDependency(dependency);
        break;
      case 'edit':
        _editDependency(dependency);
        break;
      case 'update':
        _updateDependency(dependency);
        break;
    }
  }

  void _handleUpdateAction(String action, DependencyUpdate update) {
    switch (action) {
      case 'view':
        _viewUpdate(update);
        break;
      case 'apply':
        _applyUpdate(update);
        break;
    }
  }

  void _viewDependency(Dependency dependency) {
    // TODO(developer): Реализовать просмотр зависимости
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Просмотр зависимости "${dependency.name}" будет реализован'),
      ),
    );
  }

  void _editDependency(Dependency dependency) {
    // TODO(developer): Реализовать редактирование зависимости
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Редактирование зависимости "${dependency.name}" будет реализовано',
        ),
      ),
    );
  }

  void _updateDependency(Dependency dependency) {
    // TODO(developer): Реализовать обновление зависимости
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Обновление зависимости "${dependency.name}" будет реализовано',
        ),
      ),
    );
  }

  void _viewUpdate(DependencyUpdate update) {
    // TODO(developer): Реализовать просмотр обновления
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Просмотр обновления будет реализован'),
      ),
    );
  }

  Future<void> _applyUpdate(DependencyUpdate update) async {
    try {
      final success = await _dependencyService.applyUpdate(update.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Обновление применено успешно'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка применения обновления'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка применения обновления: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddDependencyDialog() {
    // TODO(developer): Реализовать диалог добавления зависимости
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Добавление зависимости будет реализовано'),
      ),
    );
  }
}
