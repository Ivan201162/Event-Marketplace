import 'package:event_marketplace_app/models/release_management.dart';
import 'package:event_marketplace_app/services/release_management_service.dart';
import 'package:event_marketplace_app/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран управления релизами
class ReleaseManagementScreen extends ConsumerStatefulWidget {
  const ReleaseManagementScreen({super.key});

  @override
  ConsumerState<ReleaseManagementScreen> createState() =>
      _ReleaseManagementScreenState();
}

class _ReleaseManagementScreenState
    extends ConsumerState<ReleaseManagementScreen> {
  final ReleaseManagementService _releaseService = ReleaseManagementService();
  List<Release> _releases = [];
  List<ReleasePlan> _plans = [];
  List<Deployment> _deployments = [];
  bool _isLoading = true;
  String _selectedTab = 'releases';
  Map<String, dynamic> _analysis = {};

  // Фильтры
  ReleaseType? _selectedType;
  ReleaseStatus? _selectedStatus;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupStreams();
  }

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
        appBar: AppBar(title: const Text('Управление релизами')),
        body: Column(
          children: [
            // Вкладки
            _buildTabs(),

            // Поиск и фильтры
            _buildSearchAndFilters(),

            // Анализ
            _buildAnalysis(),

            // Контент
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedTab == 'releases'
                      ? _buildReleasesTab()
                      : _selectedTab == 'plans'
                          ? _buildPlansTab()
                          : _buildDeploymentsTab(),
            ),
          ],
        ),
      );

  Widget _buildTabs() => ResponsiveCard(
        child: Row(
          children: [
            Expanded(
                child:
                    _buildTabButton('releases', 'Релизы', Icons.rocket_launch),),
            Expanded(
                child: _buildTabButton('plans', 'Планы', Icons.assignment),),
            Expanded(
                child: _buildTabButton(
                    'deployments', 'Деплои', Icons.cloud_upload,),),
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
              color: isSelected
                  ? Colors.blue
                  : Colors.grey.withValues(alpha: 0.3),),
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

  Widget _buildSearchAndFilters() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Поиск и фильтры',
                style: Theme.of(context).textTheme.titleMedium,),
            const SizedBox(height: 16),

            // Поиск
            TextField(
              decoration: const InputDecoration(
                hintText: 'Поиск по версии, названию или описанию...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Фильтры
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Фильтр по типу
                DropdownButton<ReleaseType?>(
                  value: _selectedType,
                  hint: const Text('Все типы'),
                  items: [
                    const DropdownMenuItem<ReleaseType?>(
                        child: Text('Все типы'),),
                    ...ReleaseType.values.map(
                      (type) => DropdownMenuItem<ReleaseType?>(
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
                DropdownButton<ReleaseStatus?>(
                  value: _selectedStatus,
                  hint: const Text('Все статусы'),
                  items: [
                    const DropdownMenuItem<ReleaseStatus?>(
                        child: Text('Все статусы'),),
                    ...ReleaseStatus.values.map(
                      (status) => DropdownMenuItem<ReleaseStatus?>(
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
          Text('Анализ релизов',
              style: Theme.of(context).textTheme.titleMedium,),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAnalysisCard(
                  'Всего релизов',
                  '${_analysis['releases']?['total'] ?? 0}',
                  Icons.rocket_launch,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalysisCard(
                  'Выпущено',
                  '${_analysis['releases']?['released'] ?? 0}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalysisCard(
                  'Планов',
                  '${_analysis['plans']?['total'] ?? 0}',
                  Icons.assignment,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalysisCard(
                  'Деплоев',
                  '${_analysis['deployments']?['total'] ?? 0}',
                  Icons.cloud_upload,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(
          String title, String value, IconData icon, Color color,) =>
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
                  fontSize: 24, fontWeight: FontWeight.bold, color: color,),
            ),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,),
          ],
        ),
      );

  Widget _buildReleasesTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                Text('Релизы', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showCreateReleaseDialog,
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

          // Список релизов
          Expanded(
            child: _getFilteredReleases().isEmpty
                ? const Center(child: Text('Релизы не найдены'))
                : ListView.builder(
                    itemCount: _getFilteredReleases().length,
                    itemBuilder: (context, index) {
                      final release = _getFilteredReleases()[index];
                      return _buildReleaseCard(release);
                    },
                  ),
          ),
        ],
      );

  Widget _buildReleaseCard(Release release) {
    final typeColor = _getTypeColor(release.type);
    final statusColor = _getStatusColor(release.status);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(release.type.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      release.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16,),
                    ),
                    Text(
                      'v${release.version}',
                      style: const TextStyle(
                          fontSize: 14, fontFamily: 'monospace',),
                    ),
                    if (release.description != null)
                      Text(
                        release.description!,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                  release.type.displayName,
                  style: TextStyle(
                      fontSize: 12,
                      color: typeColor,
                      fontWeight: FontWeight.bold,),
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
                  release.status.displayName,
                  style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleReleaseAction(value, release),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('Просмотр'),),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Редактировать'),),
                  ),
                  if (release.status == ReleaseStatus.draft)
                    const PopupMenuItem(
                      value: 'publish',
                      child: ListTile(
                          leading: Icon(Icons.publish),
                          title: Text('Опубликовать'),),
                    ),
                  const PopupMenuItem(
                    value: 'deploy',
                    child: ListTile(
                        leading: Icon(Icons.cloud_upload),
                        title: Text('Деплой'),),
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
              if (release.features.isNotEmpty)
                _buildInfoChip(
                    'Функции', '${release.features.length}', Colors.blue,),
              const SizedBox(width: 8),
              if (release.bugFixes.isNotEmpty)
                _buildInfoChip(
                    'Исправления', '${release.bugFixes.length}', Colors.green,),
              const SizedBox(width: 8),
              if (release.breakingChanges.isNotEmpty)
                _buildInfoChip('Breaking', '${release.breakingChanges.length}',
                    Colors.red,),
            ],
          ),

          const SizedBox(height: 8),

          // Теги
          if (release.tags.isNotEmpty) ...[
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: release.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2,),
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
                'Создан: ${_formatDateTime(release.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (release.releasedDate != null) ...[
                const Spacer(),
                const Icon(Icons.publish, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Выпущен: ${_formatDateTime(release.releasedDate!)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlansTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                Text('Планы релизов',
                    style: Theme.of(context).textTheme.titleMedium,),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showCreatePlanDialog,
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

          // Список планов
          Expanded(
            child: _plans.isEmpty
                ? const Center(child: Text('Планы не найдены'))
                : ListView.builder(
                    itemCount: _plans.length,
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      return _buildPlanCard(plan);
                    },
                  ),
          ),
        ],
      );

  Widget _buildPlanCard(ReleasePlan plan) {
    final typeColor = _getTypeColor(plan.type);
    final statusColor = _getPlanStatusColor(plan.status);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(plan.type.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16,),
                    ),
                    Text(
                      'v${plan.version}',
                      style: const TextStyle(
                          fontSize: 14, fontFamily: 'monospace',),
                    ),
                    Text(
                      plan.description,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                  plan.type.displayName,
                  style: TextStyle(
                      fontSize: 12,
                      color: typeColor,
                      fontWeight: FontWeight.bold,),
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
                  plan.status.displayName,
                  style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handlePlanAction(value, plan),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('Просмотр'),),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Редактировать'),),
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
                  'Релизы', '${plan.releaseIds.length}', Colors.blue,),
              const SizedBox(width: 8),
              _buildInfoChip(
                  'Этапы', '${plan.milestones.length}', Colors.green,),
            ],
          ),

          const SizedBox(height: 8),

          // Время
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Создан: ${_formatDateTime(plan.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (plan.targetDate != null) ...[
                const Spacer(),
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Цель: ${_formatDateTime(plan.targetDate!)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
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
                Text('Деплои', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Обновить'),
                ),
              ],
            ),
          ),

          // Список деплоев
          Expanded(
            child: _deployments.isEmpty
                ? const Center(child: Text('Деплои не найдены'))
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

  Widget _buildDeploymentCard(Deployment deployment) {
    final statusColor = _getDeploymentStatusColor(deployment.status);
    final release = _releaseService.getRelease(deployment.releaseId);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(deployment.status.icon,
                  style: const TextStyle(fontSize: 24),),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deployment.environment,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16,),
                    ),
                    if (release != null)
                      Text(
                        'Релиз: ${release.name} v${release.version}',
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
                      fontWeight: FontWeight.bold,),
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
                        title: Text('Просмотр'),),
                  ),
                  if (deployment.status == DeploymentStatus.pending)
                    const PopupMenuItem(
                      value: 'start',
                      child: ListTile(
                          leading: Icon(Icons.play_arrow),
                          title: Text('Запустить'),),
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
              _buildInfoChip('Логи', '${deployment.logs.length}', Colors.blue),
              const SizedBox(width: 8),
              if (deployment.startedAt != null)
                _buildInfoChip('Начат', _formatDateTime(deployment.startedAt!),
                    Colors.green,),
              if (deployment.completedAt != null)
                _buildInfoChip('Завершен',
                    _formatDateTime(deployment.completedAt!), Colors.orange,),
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
              fontSize: 12, color: color, fontWeight: FontWeight.w500,),
        ),
      );

  Color _getTypeColor(ReleaseType type) {
    switch (type) {
      case ReleaseType.major:
        return Colors.red;
      case ReleaseType.minor:
        return Colors.blue;
      case ReleaseType.patch:
        return Colors.green;
      case ReleaseType.hotfix:
        return Colors.orange;
      case ReleaseType.alpha:
        return Colors.purple;
      case ReleaseType.beta:
        return Colors.teal;
      case ReleaseType.rc:
        return Colors.indigo;
    }
  }

  Color _getStatusColor(ReleaseStatus status) {
    switch (status) {
      case ReleaseStatus.draft:
        return Colors.grey;
      case ReleaseStatus.scheduled:
        return Colors.blue;
      case ReleaseStatus.inProgress:
        return Colors.orange;
      case ReleaseStatus.testing:
        return Colors.purple;
      case ReleaseStatus.ready:
        return Colors.green;
      case ReleaseStatus.released:
        return Colors.green;
      case ReleaseStatus.cancelled:
        return Colors.red;
      case ReleaseStatus.failed:
        return Colors.red;
    }
  }

  Color _getPlanStatusColor(PlanStatus status) {
    switch (status) {
      case PlanStatus.draft:
        return Colors.grey;
      case PlanStatus.active:
        return Colors.blue;
      case PlanStatus.completed:
        return Colors.green;
      case PlanStatus.cancelled:
        return Colors.red;
      case PlanStatus.onHold:
        return Colors.orange;
    }
  }

  Color _getDeploymentStatusColor(DeploymentStatus status) {
    switch (status) {
      case DeploymentStatus.pending:
        return Colors.grey;
      case DeploymentStatus.inProgress:
        return Colors.blue;
      case DeploymentStatus.completed:
        return Colors.green;
      case DeploymentStatus.failed:
        return Colors.red;
      case DeploymentStatus.cancelled:
        return Colors.orange;
      case DeploymentStatus.rolledBack:
        return Colors.purple;
    }
  }

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

  List<Release> _getFilteredReleases() {
    var filtered = _releases;

    // Поиск
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (release) =>
                release.name
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                release.version
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                (release.description
                        ?.toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ??
                    false),
          )
          .toList();
    }

    // Фильтры
    if (_selectedType != null) {
      filtered =
          filtered.where((release) => release.type == _selectedType).toList();
    }

    if (_selectedStatus != null) {
      filtered = filtered
          .where((release) => release.status == _selectedStatus)
          .toList();
    }

    return filtered;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _releaseService.initialize();
      setState(() {
        _releases = _releaseService.getAllReleases();
        _plans = _releaseService.getAllPlans();
        _deployments = _releaseService.getAllDeployments();
      });

      _analysis = await _releaseService.analyzeReleases();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка загрузки данных: $e'),
            backgroundColor: Colors.red,),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupStreams() {
    _releaseService.releaseStream.listen((release) {
      setState(() {
        final index = _releases.indexWhere((r) => r.id == release.id);
        if (index != -1) {
          _releases[index] = release;
        } else {
          _releases.add(release);
        }
      });
    });

    _releaseService.planStream.listen((plan) {
      setState(() {
        final index = _plans.indexWhere((p) => p.id == plan.id);
        if (index != -1) {
          _plans[index] = plan;
        } else {
          _plans.add(plan);
        }
      });
    });

    _releaseService.deploymentStream.listen((deployment) {
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

  void _resetFilters() {
    setState(() {
      _selectedType = null;
      _selectedStatus = null;
      _searchQuery = '';
    });
  }

  void _handleReleaseAction(String action, Release release) {
    switch (action) {
      case 'view':
        _viewRelease(release);
      case 'edit':
        _editRelease(release);
      case 'publish':
        _publishRelease(release);
      case 'deploy':
        _deployRelease(release);
    }
  }

  void _handlePlanAction(String action, ReleasePlan plan) {
    switch (action) {
      case 'view':
        _viewPlan(plan);
      case 'edit':
        _editPlan(plan);
    }
  }

  void _handleDeploymentAction(String action, Deployment deployment) {
    switch (action) {
      case 'view':
        _viewDeployment(deployment);
      case 'start':
        _startDeployment(deployment);
    }
  }

  void _viewRelease(Release release) {
    // TODO(developer): Реализовать просмотр релиза
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(
        content: Text('Просмотр релиза "${release.name}" будет реализован'),),);
  }

  void _editRelease(Release release) {
    // TODO(developer): Реализовать редактирование релиза
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Редактирование релиза "${release.name}" будет реализовано',),),
    );
  }

  Future<void> _publishRelease(Release release) async {
    try {
      await _releaseService.updateRelease(
        id: release.id,
        status: ReleaseStatus.released,
        releasedDate: DateTime.now(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Релиз "${release.name}" опубликован'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка публикации релиза: $e'),
            backgroundColor: Colors.red,),
      );
    }
  }

  Future<void> _deployRelease(Release release) async {
    try {
      await _releaseService.createDeployment(
          releaseId: release.id, environment: 'production',);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Деплой релиза "${release.name}" создан'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка создания деплоя: $e'),
            backgroundColor: Colors.red,),
      );
    }
  }

  void _viewPlan(ReleasePlan plan) {
    // TODO(developer): Реализовать просмотр плана
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(
        content: Text('Просмотр плана "${plan.name}" будет реализован'),),);
  }

  void _editPlan(ReleasePlan plan) {
    // TODO(developer): Реализовать редактирование плана
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Редактирование плана "${plan.name}" будет реализовано'),),
    );
  }

  void _viewDeployment(Deployment deployment) {
    // TODO(developer): Реализовать просмотр деплоя
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        const SnackBar(content: Text('Просмотр деплоя будет реализован')),);
  }

  Future<void> _startDeployment(Deployment deployment) async {
    try {
      await _releaseService.startDeployment(deployment.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Деплой запущен'), backgroundColor: Colors.green,),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка запуска деплоя: $e'),
            backgroundColor: Colors.red,),
      );
    }
  }

  void _showCreateReleaseDialog() {
    // TODO(developer): Реализовать диалог создания релиза
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        const SnackBar(content: Text('Создание релиза будет реализовано')),);
  }

  void _showCreatePlanDialog() {
    // TODO(developer): Реализовать диалог создания плана
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        const SnackBar(content: Text('Создание плана будет реализовано')),);
  }
}
