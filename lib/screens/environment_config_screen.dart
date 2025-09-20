import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/environment_config.dart';
import '../services/environment_config_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран управления конфигурацией окружения
class EnvironmentConfigScreen extends ConsumerStatefulWidget {
  const EnvironmentConfigScreen({super.key});

  @override
  ConsumerState<EnvironmentConfigScreen> createState() =>
      _EnvironmentConfigScreenState();
}

class _EnvironmentConfigScreenState
    extends ConsumerState<EnvironmentConfigScreen> {
  final EnvironmentConfigService _configService = EnvironmentConfigService();
  List<EnvironmentConfig> _environments = [];
  List<EnvironmentVariable> _variables = [];
  List<DeploymentConfig> _deployments = [];
  bool _isLoading = true;
  String _selectedTab = 'environments';
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupStreams();
  }

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
        appBar: AppBar(title: const Text('Управление конфигурацией окружения')),
        body: Column(
          children: [
            // Вкладки
            _buildTabs(),

            // Статистика
            _buildStatistics(),

            // Контент
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedTab == 'environments'
                      ? _buildEnvironmentsTab()
                      : _selectedTab == 'variables'
                          ? _buildVariablesTab()
                          : _buildDeploymentsTab(),
            ),
          ],
        ),
      );

  Widget _buildTabs() => ResponsiveCard(
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton('environments', 'Окружения', Icons.cloud),
            ),
            Expanded(
              child: _buildTabButton('variables', 'Переменные', Icons.settings),
            ),
            Expanded(
              child: _buildTabButton(
                'deployments',
                'Развертывания',
                Icons.rocket_launch,
              ),
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

  Widget _buildStatistics() {
    if (_statistics.isEmpty) return const SizedBox.shrink();

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Статистика конфигураций',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Окружения',
                  '${_statistics['environments']?['total'] ?? 0}',
                  Icons.cloud,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Переменные',
                  '${_statistics['variables']?['total'] ?? 0}',
                  Icons.settings,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Развертывания',
                  '${_statistics['deployments']?['total'] ?? 0}',
                  Icons.rocket_launch,
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

  Widget _buildEnvironmentsTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                Text(
                  'Конфигурации окружений',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showCreateEnvironmentDialog,
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

          // Список окружений
          Expanded(
            child: _environments.isEmpty
                ? const Center(child: Text('Окружения не найдены'))
                : ListView.builder(
                    itemCount: _environments.length,
                    itemBuilder: (context, index) {
                      final environment = _environments[index];
                      return _buildEnvironmentCard(environment);
                    },
                  ),
          ),
        ],
      );

  Widget _buildEnvironmentCard(EnvironmentConfig environment) {
    final typeColor = _getTypeColor(environment.type);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                environment.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      environment.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (environment.description != null)
                      Text(
                        environment.description!,
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
                  environment.type.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (environment.isActive)
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
                    'Активно',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleEnvironmentAction(value, environment),
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
                  if (!environment.isActive)
                    const PopupMenuItem(
                      value: 'activate',
                      child: ListTile(
                        leading: Icon(Icons.play_arrow),
                        title: Text('Активировать'),
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'export',
                    child: ListTile(
                      leading: Icon(Icons.download),
                      title: Text('Экспорт'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'validate',
                    child: ListTile(
                      leading: Icon(Icons.check_circle),
                      title: Text('Валидация'),
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Теги
          if (environment.tags.isNotEmpty) ...[
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: environment.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Метаданные
          Row(
            children: [
              _buildInfoChip(
                'Конфигурация',
                '${environment.config.length} параметров',
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                'Секреты',
                '${environment.secrets.length} секретов',
                Colors.red,
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
                'Создан: ${_formatDateTime(environment.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Spacer(),
              Text(
                'Обновлен: ${_formatDateTime(environment.updatedAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariablesTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                Text(
                  'Переменные окружения',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showCreateVariableDialog,
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

          // Список переменных
          Expanded(
            child: _variables.isEmpty
                ? const Center(child: Text('Переменные не найдены'))
                : ListView.builder(
                    itemCount: _variables.length,
                    itemBuilder: (context, index) {
                      final variable = _variables[index];
                      return _buildVariableCard(variable);
                    },
                  ),
          ),
        ],
      );

  Widget _buildVariableCard(EnvironmentVariable variable) {
    final typeColor = _getVariableTypeColor(variable.type);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                variable.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variable.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (variable.description != null)
                      Text(
                        variable.description!,
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
                  variable.type.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (variable.isSecret)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red),
                  ),
                  child: const Text(
                    'Секрет',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (variable.isRequired)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Text(
                    'Обязательно',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleVariableAction(value, variable),
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
            child: Text(
              variable.isSecret ? '••••••••' : variable.value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Метаданные
          Row(
            children: [
              if (variable.defaultValue != null)
                _buildInfoChip(
                  'По умолчанию',
                  variable.defaultValue!,
                  Colors.green,
                ),
              const SizedBox(width: 8),
              if (variable.allowedValues.isNotEmpty)
                _buildInfoChip(
                  'Допустимые значения',
                  '${variable.allowedValues.length}',
                  Colors.blue,
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
                'Создан: ${_formatDateTime(variable.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeploymentsTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                Text(
                  'Конфигурации развертывания',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showCreateDeploymentDialog,
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

          // Список развертываний
          Expanded(
            child: _deployments.isEmpty
                ? const Center(child: Text('Развертывания не найдены'))
                : ListView.builder(
                    itemCount: _deployments.length,
                    itemBuilder: (context, index) {
                      final deployment = _deployments[index];
                      return _buildDeploymentCard(deployment);
                    },
                  ),
          ),
        ],
      );

  Widget _buildDeploymentCard(DeploymentConfig deployment) {
    final statusColor = _getStatusColor(deployment.status);
    final environment = _environments.firstWhere(
      (env) => env.id == deployment.environmentId,
      orElse: () => EnvironmentConfig(
        id: '',
        name: 'Unknown',
        type: EnvironmentType.development,
        config: {},
        secrets: {},
        featureFlags: {},
        apiEndpoints: {},
        databaseConfig: {},
        cacheConfig: {},
        loggingConfig: {},
        monitoringConfig: {},
        securityConfig: {},
        isActive: false,
        tags: [],
        metadata: {},
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
                deployment.status.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${environment.name} v${deployment.version}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (deployment.description != null)
                      Text(
                        deployment.description!,
                        style: const TextStyle(fontSize: 14),
                      ),
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
                  deployment.status.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleDeploymentAction(value, deployment),
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
                'Зависимости',
                '${deployment.dependencies.length}',
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                'Проверки здоровья',
                '${deployment.healthChecks.length}',
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
                'Создан: ${_formatDateTime(deployment.createdAt)}',
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

  Color _getTypeColor(EnvironmentType type) {
    switch (type) {
      case EnvironmentType.development:
        return Colors.blue;
      case EnvironmentType.staging:
        return Colors.orange;
      case EnvironmentType.production:
        return Colors.green;
      case EnvironmentType.testing:
        return Colors.purple;
      case EnvironmentType.demo:
        return Colors.teal;
    }
  }

  Color _getVariableTypeColor(EnvironmentVariableType type) {
    switch (type) {
      case EnvironmentVariableType.string:
        return Colors.blue;
      case EnvironmentVariableType.number:
        return Colors.green;
      case EnvironmentVariableType.boolean:
        return Colors.orange;
      case EnvironmentVariableType.json:
        return Colors.purple;
      case EnvironmentVariableType.url:
        return Colors.teal;
      case EnvironmentVariableType.email:
        return Colors.cyan;
      case EnvironmentVariableType.password:
        return Colors.red;
      case EnvironmentVariableType.apiKey:
        return Colors.brown;
      case EnvironmentVariableType.token:
        return Colors.indigo;
    }
  }

  Color _getStatusColor(DeploymentStatus status) {
    switch (status) {
      case DeploymentStatus.draft:
        return Colors.grey;
      case DeploymentStatus.pending:
        return Colors.orange;
      case DeploymentStatus.deploying:
        return Colors.blue;
      case DeploymentStatus.deployed:
        return Colors.green;
      case DeploymentStatus.failed:
        return Colors.red;
      case DeploymentStatus.rolledBack:
        return Colors.purple;
      case DeploymentStatus.archived:
        return Colors.brown;
    }
  }

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _configService.initialize();
      setState(() {
        _environments = _configService.getAllEnvironmentConfigs();
        _variables = _configService.getAllEnvironmentVariables();
        _deployments = _configService.getAllDeploymentConfigs();
      });

      _statistics = await _configService.getConfigStatistics();
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
    _configService.environmentStream.listen((environment) {
      setState(() {
        final index = _environments.indexWhere((e) => e.id == environment.id);
        if (index != -1) {
          _environments[index] = environment;
        } else {
          _environments.add(environment);
        }
      });
    });

    _configService.variableStream.listen((variable) {
      setState(() {
        final index = _variables.indexWhere((v) => v.id == variable.id);
        if (index != -1) {
          _variables[index] = variable;
        } else {
          _variables.add(variable);
        }
      });
    });

    _configService.deploymentStream.listen((deployment) {
      setState(() {
        final index = _deployments.indexWhere((d) => d.id == deployment.id);
        if (index != -1) {
          _deployments[index] = deployment;
        } else {
          _deployments.add(deployment);
        }
      });
    });
  }

  void _handleEnvironmentAction(String action, EnvironmentConfig environment) {
    switch (action) {
      case 'view':
        _viewEnvironment(environment);
        break;
      case 'edit':
        _editEnvironment(environment);
        break;
      case 'activate':
        _activateEnvironment(environment);
        break;
      case 'export':
        _exportEnvironment(environment);
        break;
      case 'validate':
        _validateEnvironment(environment);
        break;
    }
  }

  void _handleVariableAction(String action, EnvironmentVariable variable) {
    switch (action) {
      case 'view':
        _viewVariable(variable);
        break;
      case 'edit':
        _editVariable(variable);
        break;
    }
  }

  void _handleDeploymentAction(String action, DeploymentConfig deployment) {
    switch (action) {
      case 'view':
        _viewDeployment(deployment);
        break;
      case 'edit':
        _editDeployment(deployment);
        break;
    }
  }

  void _viewEnvironment(EnvironmentConfig environment) {
    // TODO: Реализовать просмотр окружения
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Просмотр окружения "${environment.name}" будет реализован'),
      ),
    );
  }

  void _editEnvironment(EnvironmentConfig environment) {
    // TODO: Реализовать редактирование окружения
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Редактирование окружения "${environment.name}" будет реализовано',
        ),
      ),
    );
  }

  Future<void> _activateEnvironment(EnvironmentConfig environment) async {
    try {
      await _configService.activateEnvironmentConfig(environment.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Окружение "${environment.name}" активировано'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка активации: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportEnvironment(EnvironmentConfig environment) async {
    try {
      final exportData =
          await _configService.exportEnvironmentConfig(environment.id);
      // TODO: Реализовать сохранение файла
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Экспорт окружения "${environment.name}" завершен'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка экспорта: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _validateEnvironment(EnvironmentConfig environment) async {
    try {
      final errors =
          await _configService.validateEnvironmentConfig(environment.id);
      if (errors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Окружение "${environment.name}" валидно'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Ошибки валидации: ${environment.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: errors.map((error) => Text('• $error')).toList(),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка валидации: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewVariable(EnvironmentVariable variable) {
    // TODO: Реализовать просмотр переменной
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Просмотр переменной "${variable.key}" будет реализован'),
      ),
    );
  }

  void _editVariable(EnvironmentVariable variable) {
    // TODO: Реализовать редактирование переменной
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Редактирование переменной "${variable.key}" будет реализовано',
        ),
      ),
    );
  }

  void _viewDeployment(DeploymentConfig deployment) {
    // TODO: Реализовать просмотр развертывания
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Просмотр развертывания "${deployment.version}" будет реализован',
        ),
      ),
    );
  }

  void _editDeployment(DeploymentConfig deployment) {
    // TODO: Реализовать редактирование развертывания
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Редактирование развертывания "${deployment.version}" будет реализовано',
        ),
      ),
    );
  }

  void _showCreateEnvironmentDialog() {
    // TODO: Реализовать диалог создания окружения
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Создание окружения будет реализовано'),
      ),
    );
  }

  void _showCreateVariableDialog() {
    // TODO: Реализовать диалог создания переменной
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Создание переменной будет реализовано'),
      ),
    );
  }

  void _showCreateDeploymentDialog() {
    // TODO: Реализовать диалог создания развертывания
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Создание развертывания будет реализовано'),
      ),
    );
  }
}
