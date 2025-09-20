import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/version_management.dart';
import '../services/version_management_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран управления версиями и обновлениями
class VersionManagementScreen extends ConsumerStatefulWidget {
  const VersionManagementScreen({super.key});

  @override
  ConsumerState<VersionManagementScreen> createState() =>
      _VersionManagementScreenState();
}

class _VersionManagementScreenState
    extends ConsumerState<VersionManagementScreen> {
  final VersionManagementService _versionService = VersionManagementService();
  List<AppVersion> _versions = [];
  List<AppUpdate> _updates = [];
  List<VersionStatistics> _statistics = [];
  bool _isLoading = true;
  String _selectedTab = 'versions';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
        appBar: AppBar(title: const Text('Управление версиями')),
        body: Column(
          children: [
            // Вкладки
            _buildTabs(),

            // Контент
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedTab == 'versions'
                      ? _buildVersionsTab()
                      : _selectedTab == 'updates'
                          ? _buildUpdatesTab()
                          : _buildStatisticsTab(),
            ),
          ],
        ),
      );

  Widget _buildTabs() => ResponsiveCard(
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton('versions', 'Версии', Icons.apps),
            ),
            Expanded(
              child:
                  _buildTabButton('updates', 'Обновления', Icons.system_update),
            ),
            Expanded(
              child:
                  _buildTabButton('statistics', 'Статистика', Icons.analytics),
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

  Widget _buildVersionsTab() => Column(
        children: [
          // Заголовок с фильтрами
          ResponsiveCard(
            child: Row(
              children: [
                Text(
                  'Версии приложения',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                DropdownButton<String?>(
                  hint: const Text('Все платформы'),
                  items: const [
                    DropdownMenuItem<String?>(
                      child: Text('Все платформы'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'android',
                      child: Text('Android'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'ios',
                      child: Text('iOS'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'web',
                      child: Text('Web'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'windows',
                      child: Text('Windows'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'macos',
                      child: Text('macOS'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'linux',
                      child: Text('Linux'),
                    ),
                  ],
                  onChanged: (value) {
                    // TODO: Реализовать фильтрацию
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showCreateVersionDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Создать версию'),
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

          // Список версий
          Expanded(
            child: _versions.isEmpty
                ? const Center(child: Text('Версии не найдены'))
                : ListView.builder(
                    itemCount: _versions.length,
                    itemBuilder: (context, index) {
                      final version = _versions[index];
                      return _buildVersionCard(version);
                    },
                  ),
          ),
        ],
      );

  Widget _buildVersionCard(AppVersion version) {
    final typeColor = _getTypeColor(version.type);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                version.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      version.fullVersion,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Платформа: ${version.platform}',
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
                  version.type.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (version.isForced)
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
                    'Принудительная',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleVersionAction(value, version),
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
                  if (!version.isAvailable)
                    const PopupMenuItem(
                      value: 'activate',
                      child: ListTile(
                        leading: Icon(Icons.play_arrow),
                        title: Text('Активировать'),
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'statistics',
                    child: ListTile(
                      leading: Icon(Icons.analytics),
                      title: Text('Статистика'),
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Описание
          if (version.description != null) ...[
            Text(
              version.description!,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
          ],

          // Изменения
          if (version.features.isNotEmpty ||
              version.bugFixes.isNotEmpty ||
              version.breakingChanges.isNotEmpty) ...[
            Text(
              'Изменения:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              version.shortDescription,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],

          // Метаданные
          Row(
            children: [
              _buildInfoChip(
                'Статус',
                version.isAvailable ? 'Доступна' : 'Недоступна',
                version.isAvailable ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              if (version.downloadUrl != null)
                _buildInfoChip('Скачать', 'Да', Colors.blue),
            ],
          ),

          const SizedBox(height: 8),

          // Время
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Выпущена: ${_formatDateTime(version.releaseDate)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (version.expirationDate != null) ...[
                const Spacer(),
                Text(
                  'Истекает: ${_formatDateTime(version.expirationDate!)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
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
                  'Обновления приложения',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Обновить'),
                ),
              ],
            ),
          ),

          // Список обновлений
          Expanded(
            child: _updates.isEmpty
                ? const Center(child: Text('Обновления не найдены'))
                : ListView.builder(
                    itemCount: _updates.length,
                    itemBuilder: (context, index) {
                      final update = _updates[index];
                      return _buildUpdateCard(update);
                    },
                  ),
          ),
        ],
      );

  Widget _buildUpdateCard(AppUpdate update) {
    final statusColor = _getStatusColor(update.status);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                update.status.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${update.currentVersion} → ${update.targetVersion}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Платформа: ${update.platform}',
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
                  update.status.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Прогресс
          if (update.isInProgress) ...[
            LinearProgressIndicator(
              value: update.progress,
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Прогресс: ${(update.progress * 100).toInt()}%',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],

          // Ошибка
          if (update.hasError && update.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                'Ошибка: ${update.errorMessage}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Метаданные
          Row(
            children: [
              if (update.userId != null)
                _buildInfoChip('Пользователь', update.userId!, Colors.blue),
              if (update.deviceId != null) ...[
                const SizedBox(width: 8),
                _buildInfoChip('Устройство', update.deviceId!, Colors.green),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Время
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Начато: ${_formatDateTime(update.startedAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (update.completedAt != null) ...[
                const Spacer(),
                Text(
                  'Завершено: ${_formatDateTime(update.completedAt!)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                Text(
                  'Статистика версий',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Обновить'),
                ),
              ],
            ),
          ),

          // Список статистики
          Expanded(
            child: _statistics.isEmpty
                ? const Center(child: Text('Статистика не найдена'))
                : ListView.builder(
                    itemCount: _statistics.length,
                    itemBuilder: (context, index) {
                      final stats = _statistics[index];
                      return _buildStatisticsCard(stats);
                    },
                  ),
          ),
        ],
      );

  Widget _buildStatisticsCard(VersionStatistics stats) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                const Icon(Icons.analytics, size: 24, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Версия ${stats.version}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Платформа: ${stats.platform}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Основные метрики
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Всего пользователей',
                    '${stats.totalUsers}',
                    Colors.blue,
                    Icons.people,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Активных',
                    '${stats.activeUsers}',
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Крашей',
                    '${stats.crashCount}',
                    Colors.red,
                    Icons.bug_report,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Дополнительные метрики
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Краш-рейт',
                    '${(stats.crashRate * 100).toStringAsFixed(2)}%',
                    Colors.orange,
                    Icons.trending_down,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Средняя сессия',
                    stats.formattedSessionDuration,
                    Colors.purple,
                    Icons.timer,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Всего сессий',
                    '${stats.totalSessions}',
                    Colors.cyan,
                    Icons.timeline,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Прогресс-бар активных пользователей
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Активные пользователи: ${stats.activeUserPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: stats.activeUserPercentage / 100,
                  backgroundColor: Colors.grey.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Время обновления
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Обновлено: ${_formatDateTime(stats.lastUpdated)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
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

  Color _getTypeColor(VersionType type) {
    switch (type) {
      case VersionType.development:
        return Colors.orange;
      case VersionType.beta:
        return Colors.blue;
      case VersionType.release:
        return Colors.green;
      case VersionType.critical:
        return Colors.red;
      case VersionType.hotfix:
        return Colors.purple;
    }
  }

  Color _getStatusColor(UpdateStatus status) {
    switch (status) {
      case UpdateStatus.pending:
        return Colors.orange;
      case UpdateStatus.inProgress:
        return Colors.blue;
      case UpdateStatus.completed:
        return Colors.green;
      case UpdateStatus.failed:
        return Colors.red;
      case UpdateStatus.cancelled:
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
      await _versionService.initialize();
      setState(() {
        _versions = _versionService.getAllVersions();
        _updates = _versionService.getAllUpdates();
        _statistics = _versionService.getAllStatistics();
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

  void _handleVersionAction(String action, AppVersion version) {
    switch (action) {
      case 'view':
        _viewVersion(version);
        break;
      case 'edit':
        _editVersion(version);
        break;
      case 'activate':
        _activateVersion(version);
        break;
      case 'statistics':
        _viewVersionStatistics(version);
        break;
    }
  }

  void _viewVersion(AppVersion version) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Версия ${version.fullVersion}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (version.description != null) ...[
                Text('Описание: ${version.description}'),
                const SizedBox(height: 8),
              ],
              if (version.features.isNotEmpty) ...[
                const Text(
                  'Новые функции:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...version.features.map((feature) => Text('• $feature')),
                const SizedBox(height: 8),
              ],
              if (version.bugFixes.isNotEmpty) ...[
                const Text(
                  'Исправления:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...version.bugFixes.map((fix) => Text('• $fix')),
                const SizedBox(height: 8),
              ],
              if (version.breakingChanges.isNotEmpty) ...[
                const Text(
                  'Критические изменения:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...version.breakingChanges.map((change) => Text('• $change')),
                const SizedBox(height: 8),
              ],
              Text('Тип: ${version.type.displayName}'),
              Text('Платформа: ${version.platform}'),
              Text('Принудительная: ${version.isForced ? 'Да' : 'Нет'}'),
              Text('Доступна: ${version.isAvailable ? 'Да' : 'Нет'}'),
              Text('Дата выпуска: ${_formatDateTime(version.releaseDate)}'),
              if (version.expirationDate != null)
                Text('Истекает: ${_formatDateTime(version.expirationDate!)}'),
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

  void _editVersion(AppVersion version) {
    // TODO: Реализовать редактирование версии
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Редактирование версии "${version.version}" будет реализовано',
        ),
      ),
    );
  }

  void _activateVersion(AppVersion version) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Активировать версию'),
        content: Text('Активировать версию ${version.fullVersion}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _versionService.activateVersion(
                  version.id,
                  activatedBy:
                      'current_user', // TODO: Получить ID текущего пользователя
                );
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Версия активирована'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка активации версии: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Активировать'),
          ),
        ],
      ),
    );
  }

  void _viewVersionStatistics(AppVersion version) {
    // TODO: Реализовать просмотр статистики версии
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Статистика версии "${version.version}" будет реализована'),
      ),
    );
  }

  void _showCreateVersionDialog() {
    // TODO: Реализовать диалог создания версии
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Создание версии будет реализовано'),
      ),
    );
  }
}
