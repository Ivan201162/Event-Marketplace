import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/backup.dart';
import '../services/backup_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран управления бэкапами
class BackupManagementScreen extends ConsumerStatefulWidget {
  const BackupManagementScreen({super.key});

  @override
  ConsumerState<BackupManagementScreen> createState() =>
      _BackupManagementScreenState();
}

class _BackupManagementScreenState
    extends ConsumerState<BackupManagementScreen> {
  final BackupService _backupService = BackupService();
  List<Backup> _backups = [];
  List<Restore> _restores = [];
  bool _isLoading = true;
  String _selectedTab = 'backups';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Управление бэкапами',
      body: Column(
        children: [
          // Вкладки
          _buildTabs(),

          // Контент
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 'backups'
                    ? _buildBackupsTab()
                    : _selectedTab == 'restores'
                        ? _buildRestoresTab()
                        : _buildStatisticsTab(),
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
            child: _buildTabButton('backups', 'Бэкапы', Icons.backup),
          ),
          Expanded(
            child: _buildTabButton('restores', 'Восстановления', Icons.restore),
          ),
          Expanded(
            child: _buildTabButton('statistics', 'Статистика', Icons.analytics),
          ),
          Expanded(
            child: _buildTabButton('create', 'Создать', Icons.add),
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
        if (tab == 'create') {
          _showCreateBackupDialog();
        } else if (tab == 'statistics') {
          _loadStatistics();
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

  Widget _buildBackupsTab() {
    return Column(
      children: [
        // Заголовок с кнопками
        ResponsiveCard(
          child: Row(
            children: [
              ResponsiveText(
                'Бэкапы',
                isTitle: true,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loadBackups,
                icon: const Icon(Icons.refresh),
                label: const Text('Обновить'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showCreateBackupDialog,
                icon: const Icon(Icons.add),
                label: const Text('Создать бэкап'),
              ),
            ],
          ),
        ),

        // Список бэкапов
        Expanded(
          child: _backups.isEmpty
              ? const Center(child: Text('Бэкапы не найдены'))
              : ListView.builder(
                  itemCount: _backups.length,
                  itemBuilder: (context, index) {
                    final backup = _backups[index];
                    return _buildBackupCard(backup);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBackupCard(Backup backup) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Icon(
                _getBackupIcon(backup.type),
                color: _getBackupColor(backup.type),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ResponsiveText(
                  backup.name,
                  isTitle: true,
                ),
              ),
              _buildStatusChip(backup.status),
              PopupMenuButton<String>(
                onSelected: (value) => _handleBackupAction(value, backup),
                itemBuilder: (context) => [
                  if (backup.isCompleted) ...[
                    const PopupMenuItem(
                      value: 'download',
                      child: ListTile(
                        leading: Icon(Icons.download),
                        title: Text('Скачать'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'restore',
                      child: ListTile(
                        leading: Icon(Icons.restore),
                        title: Text('Восстановить'),
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
          Text(backup.description),

          const SizedBox(height: 12),

          // Метаданные
          Row(
            children: [
              _buildInfoChip('Тип', backup.type.name, Colors.blue),
              const SizedBox(width: 8),
              if (backup.fileSize != null)
                _buildInfoChip(
                    'Размер', backup.formattedFileSize, Colors.green),
            ],
          ),

          const SizedBox(height: 8),

          // Коллекции
          if (backup.collections.isNotEmpty) ...[
            Text(
              'Коллекции:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: backup.collections.map((collection) {
                return Chip(
                  label: Text(collection),
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(fontSize: 12),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),

          // Время создания
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Создан: ${_formatDateTime(backup.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (backup.completedAt != null) ...[
                const Spacer(),
                Text(
                  'Завершен: ${_formatDateTime(backup.completedAt!)}',
                  style: const TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ],
          ),

          // Ошибка
          if (backup.hasError && backup.errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                'Ошибка: ${backup.errorMessage}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRestoresTab() {
    return Column(
      children: [
        // Заголовок
        ResponsiveCard(
          child: Row(
            children: [
              ResponsiveText(
                'Восстановления',
                isTitle: true,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loadRestores,
                icon: const Icon(Icons.refresh),
                label: const Text('Обновить'),
              ),
            ],
          ),
        ),

        // Список восстановлений
        Expanded(
          child: _restores.isEmpty
              ? const Center(child: Text('Восстановления не найдены'))
              : ListView.builder(
                  itemCount: _restores.length,
                  itemBuilder: (context, index) {
                    final restore = _restores[index];
                    return _buildRestoreCard(restore);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRestoreCard(Restore restore) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Icon(
                _getRestoreIcon(restore.type),
                color: _getRestoreColor(restore.type),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ResponsiveText(
                  restore.name,
                  isTitle: true,
                ),
              ),
              _buildStatusChip(restore.status),
            ],
          ),

          const SizedBox(height: 12),

          // Описание
          Text(restore.description),

          const SizedBox(height: 12),

          // Метаданные
          Row(
            children: [
              _buildInfoChip('Тип', restore.type.name, Colors.blue),
              const SizedBox(width: 8),
              _buildInfoChip(
                  'Бэкап ID', restore.backupId.substring(0, 8), Colors.green),
            ],
          ),

          const SizedBox(height: 8),

          // Коллекции
          if (restore.collections.isNotEmpty) ...[
            Text(
              'Коллекции:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: restore.collections.map((collection) {
                return Chip(
                  label: Text(collection),
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(fontSize: 12),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),

          // Время создания
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Создан: ${_formatDateTime(restore.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (restore.completedAt != null) ...[
                const Spacer(),
                Text(
                  'Завершен: ${_formatDateTime(restore.completedAt!)}',
                  style: const TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ],
          ),

          // Ошибка
          if (restore.hasError && restore.errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                'Ошибка: ${restore.errorMessage}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return FutureBuilder<BackupStatistics>(
      future: _backupService.getBackupStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;

        return SingleChildScrollView(
          child: Column(
            children: [
              // Основная статистика
              ResponsiveCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      'Статистика бэкапов',
                      isTitle: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Всего бэкапов',
                            '${stats.totalBackups}',
                            Colors.blue,
                            Icons.backup,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            'Успешных',
                            '${stats.successfulBackups}',
                            Colors.green,
                            Icons.check_circle,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            'Неудачных',
                            '${stats.failedBackups}',
                            Colors.red,
                            Icons.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Общий размер',
                            stats.formattedTotalSize,
                            Colors.purple,
                            Icons.storage,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            'Успешность',
                            '${stats.successRate.toStringAsFixed(1)}%',
                            Colors.teal,
                            Icons.trending_up,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Статистика по типам
              ResponsiveCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      'Бэкапы по типам',
                      isTitle: true,
                    ),
                    const SizedBox(height: 16),
                    ...stats.backupsByType.entries.map((entry) {
                      final percentage = stats.totalBackups > 0
                          ? (entry.value / stats.totalBackups) * 100
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key),
                                Text(
                                    '${entry.value} (${percentage.toStringAsFixed(1)}%)'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor:
                                  Colors.grey.withValues(alpha: 0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getBackupTypeColor(entry.key),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(dynamic status) {
    Color color;
    String text;

    if (status is BackupStatus) {
      switch (status) {
        case BackupStatus.pending:
          color = Colors.orange;
          text = 'Ожидает';
          break;
        case BackupStatus.inProgress:
          color = Colors.blue;
          text = 'В процессе';
          break;
        case BackupStatus.completed:
          color = Colors.green;
          text = 'Завершен';
          break;
        case BackupStatus.failed:
          color = Colors.red;
          text = 'Ошибка';
          break;
        case BackupStatus.cancelled:
          color = Colors.grey;
          text = 'Отменен';
          break;
      }
    } else if (status is RestoreStatus) {
      switch (status) {
        case RestoreStatus.pending:
          color = Colors.orange;
          text = 'Ожидает';
          break;
        case RestoreStatus.inProgress:
          color = Colors.blue;
          text = 'В процессе';
          break;
        case RestoreStatus.completed:
          color = Colors.green;
          text = 'Завершен';
          break;
        case RestoreStatus.failed:
          color = Colors.red;
          text = 'Ошибка';
          break;
        case RestoreStatus.cancelled:
          color = Colors.grey;
          text = 'Отменен';
          break;
      }
    } else {
      color = Colors.grey;
      text = status.toString();
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

  IconData _getBackupIcon(BackupType type) {
    switch (type) {
      case BackupType.full:
        return Icons.backup;
      case BackupType.incremental:
        return Icons.update;
      case BackupType.differential:
        return Icons.compare;
      case BackupType.selective:
        return Icons.checklist;
    }
  }

  Color _getBackupColor(BackupType type) {
    switch (type) {
      case BackupType.full:
        return Colors.blue;
      case BackupType.incremental:
        return Colors.green;
      case BackupType.differential:
        return Colors.orange;
      case BackupType.selective:
        return Colors.purple;
    }
  }

  IconData _getRestoreIcon(RestoreType type) {
    switch (type) {
      case RestoreType.full:
        return Icons.restore;
      case RestoreType.selective:
        return Icons.checklist;
      case RestoreType.pointInTime:
        return Icons.schedule;
    }
  }

  Color _getRestoreColor(RestoreType type) {
    switch (type) {
      case RestoreType.full:
        return Colors.blue;
      case RestoreType.selective:
        return Colors.green;
      case RestoreType.pointInTime:
        return Colors.orange;
    }
  }

  Color _getBackupTypeColor(String type) {
    switch (type) {
      case 'full':
        return Colors.blue;
      case 'incremental':
        return Colors.green;
      case 'differential':
        return Colors.orange;
      case 'selective':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadBackups(),
        _loadRestores(),
      ]);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBackups() async {
    try {
      final backups = await _backupService.getBackups();
      setState(() {
        _backups = backups;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки бэкапов: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadRestores() async {
    try {
      final restores = await _backupService.getRestores();
      setState(() {
        _restores = restores;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки восстановлений: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadStatistics() async {
    // Статистика загружается автоматически в _buildStatisticsTab()
  }

  void _showCreateBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать бэкап'),
        content: const Text('Выберите тип бэкапа для создания'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createBackup();
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  void _createBackup() {
    // TODO: Реализовать создание бэкапа
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция создания бэкапа будет реализована'),
      ),
    );
  }

  void _handleBackupAction(String action, Backup backup) {
    switch (action) {
      case 'download':
        _downloadBackup(backup);
        break;
      case 'restore':
        _restoreBackup(backup);
        break;
      case 'delete':
        _deleteBackup(backup);
        break;
    }
  }

  void _downloadBackup(Backup backup) {
    // TODO: Реализовать скачивание бэкапа
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Скачивание бэкапа "${backup.name}" будет реализовано'),
      ),
    );
  }

  void _restoreBackup(Backup backup) {
    // TODO: Реализовать восстановление из бэкапа
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Восстановление из бэкапа "${backup.name}" будет реализовано'),
      ),
    );
  }

  void _deleteBackup(Backup backup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить бэкап'),
        content: Text('Вы уверены, что хотите удалить бэкап "${backup.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _backupService.deleteBackup(backup.id);
                _loadBackups();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Бэкап удален'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка удаления бэкапа: $e'),
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
