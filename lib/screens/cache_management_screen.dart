import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cache_item.dart';
import '../services/cache_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран управления кэшем
class CacheManagementScreen extends ConsumerStatefulWidget {
  const CacheManagementScreen({super.key});

  @override
  ConsumerState<CacheManagementScreen> createState() => _CacheManagementScreenState();
}

class _CacheManagementScreenState extends ConsumerState<CacheManagementScreen> {
  final CacheService _cacheService = CacheService();
  CacheStatistics? _statistics;
  CacheConfig? _config;
  bool _isLoading = true;
  String _selectedTab = 'overview';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
    appBar: AppBar(title: const Text('Управление кэшем')),
    body: Column(
      children: [
        // Вкладки
        _buildTabs(),

        // Контент
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedTab == 'overview'
              ? _buildOverviewTab()
              : _selectedTab == 'items'
              ? _buildItemsTab()
              : _selectedTab == 'config'
              ? _buildConfigTab()
              : _buildStatisticsTab(),
        ),
      ],
    ),
  );

  Widget _buildTabs() => ResponsiveCard(
    child: Row(
      children: [
        Expanded(child: _buildTabButton('overview', 'Обзор', Icons.dashboard)),
        Expanded(child: _buildTabButton('items', 'Элементы', Icons.list)),
        Expanded(child: _buildTabButton('config', 'Настройки', Icons.settings)),
        Expanded(child: _buildTabButton('statistics', 'Статистика', Icons.analytics)),
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
        if (tab == 'statistics') {
          _loadStatistics();
        }
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

  Widget _buildOverviewTab() => SingleChildScrollView(
    child: Column(
      children: [
        // Основная статистика
        ResponsiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Обзор кэша', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              if (_statistics == null)
                const Center(child: Text('Статистика не загружена'))
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Элементы',
                        '${_statistics!.totalItems}',
                        Colors.blue,
                        Icons.storage,
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        'Размер',
                        _statistics!.formattedTotalSize,
                        Colors.green,
                        Icons.folder,
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        'Hit Rate',
                        '${(_statistics!.hitRate * 100).toStringAsFixed(1)}%',
                        Colors.orange,
                        Icons.trending_up,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Действия
        ResponsiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Действия', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _clearExpired,
                      icon: const Icon(Icons.cleaning_services),
                      label: const Text('Очистить истекшие'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Очистить все'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Обновить'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showCacheInfo,
                      icon: const Icon(Icons.info),
                      label: const Text('Информация'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildItemsTab() => Column(
    children: [
      // Заголовок
      ResponsiveCard(
        child: Row(
          children: [
            Text('Элементы кэша', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Обновить'),
            ),
          ],
        ),
      ),

      // Список элементов
      Expanded(
        child: FutureBuilder<List<String>>(
          future: _getCacheKeys(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final keys = snapshot.data!;

            if (keys.isEmpty) {
              return const Center(child: Text('Кэш пуст'));
            }

            return ListView.builder(
              itemCount: keys.length,
              itemBuilder: (context, index) {
                final key = keys[index];
                return _buildCacheItemCard(key);
              },
            );
          },
        ),
      ),
    ],
  );

  Widget _buildCacheItemCard(String key) => FutureBuilder<dynamic>(
    future: _cacheService.get(key),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const SizedBox.shrink();
      }

      final data = snapshot.data;
      final isValid = _cacheService.containsKey(key);

      return ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.error,
                  color: isValid ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    key,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleItemAction(value, key),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: ListTile(leading: Icon(Icons.visibility), title: Text('Просмотр')),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: ListTile(leading: Icon(Icons.delete), title: Text('Удалить')),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Данные
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                data.toString(),
                style: const TextStyle(fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _buildConfigTab() => SingleChildScrollView(
    child: ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Настройки кэша', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (_config == null)
            const Center(child: Text('Конфигурация не загружена'))
          else
            Column(
              children: [
                // Основные настройки
                _buildConfigSection('Основные настройки', [
                  _buildConfigItem('Включен', _config!.enabled ? 'Да' : 'Нет'),
                  _buildConfigItem(
                    'Максимальный размер',
                    '${(_config!.maxSize / 1024 / 1024).toStringAsFixed(1)} MB',
                  ),
                  _buildConfigItem('Максимум элементов', '${_config!.maxItems}'),
                  _buildConfigItem('TTL по умолчанию', '${_config!.defaultTTL.inMinutes} мин'),
                ]),

                const SizedBox(height: 16),

                // Дополнительные настройки
                _buildConfigSection('Дополнительные настройки', [
                  _buildConfigItem('Сжатие', _config!.enableCompression ? 'Включено' : 'Отключено'),
                  _buildConfigItem(
                    'Шифрование',
                    _config!.enableEncryption ? 'Включено' : 'Отключено',
                  ),
                  _buildConfigItem(
                    'Статистика',
                    _config!.enableStatistics ? 'Включена' : 'Отключена',
                  ),
                  _buildConfigItem(
                    'Логирование',
                    _config!.enableLogging ? 'Включено' : 'Отключено',
                  ),
                ]),

                const SizedBox(height: 16),

                // Политика вытеснения
                _buildConfigSection('Политика вытеснения', [
                  _buildConfigItem('Политика', _config!.evictionPolicy.displayName),
                  _buildConfigItem('Описание', _config!.evictionPolicy.description),
                ]),

                const SizedBox(height: 16),

                // Исключенные ключи
                if (_config!.excludedKeys.isNotEmpty) ...[
                  _buildConfigSection(
                    'Исключенные ключи',
                    _config!.excludedKeys.map((key) => _buildConfigItem('Ключ', key)).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Кнопки управления
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _resetConfig,
                        icon: const Icon(Icons.restore),
                        label: const Text('Сбросить настройки'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showConfigDialog,
                        icon: const Icon(Icons.edit),
                        label: const Text('Изменить настройки'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    ),
  );

  Widget _buildConfigSection(String title, List<Widget> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 8),
      ...items,
    ],
  );

  Widget _buildConfigItem(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        const Text(': '),
        Expanded(child: Text(value)),
      ],
    ),
  );

  Widget _buildStatisticsTab() => SingleChildScrollView(
    child: Column(
      children: [
        // Основная статистика
        ResponsiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Статистика кэша', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              if (_statistics == null)
                const Center(child: Text('Статистика не загружена'))
              else
                Column(
                  children: [
                    // Основные метрики
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Всего элементов',
                            '${_statistics!.totalItems}',
                            Colors.blue,
                            Icons.storage,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            'Действительных',
                            '${_statistics!.validItems}',
                            Colors.green,
                            Icons.check_circle,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            'Истекших',
                            '${_statistics!.expiredItems}',
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
                            _statistics!.formattedTotalSize,
                            Colors.purple,
                            Icons.folder,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            'Hit Rate',
                            '${(_statistics!.hitRate * 100).toStringAsFixed(1)}%',
                            Colors.orange,
                            Icons.trending_up,
                          ),
                        ),
                        Expanded(
                          child: _buildStatCard(
                            'Эффективность',
                            _statistics!.efficiency,
                            _getEfficiencyColor(_statistics!.efficiency),
                            Icons.analytics,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Детальная статистика
                    Text(
                      'Детальная статистика:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 8),

                    _buildStatRow('Попадания в кэш', '${_statistics!.hitCount}'),
                    _buildStatRow('Промахи кэша', '${_statistics!.missCount}'),
                    _buildStatRow('Средний возраст', _formatDuration(_statistics!.averageAge)),
                    _buildStatRow(
                      'Среднее время до истечения',
                      _formatDuration(_statistics!.averageTimeToExpiry),
                    ),

                    const SizedBox(height: 16),

                    // Элементы по типам
                    if (_statistics!.itemsByType.isNotEmpty) ...[
                      Text(
                        'Элементы по типам:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      ..._statistics!.itemsByType.entries.map(
                        (entry) => _buildStatRow(entry.key, '${entry.value}'),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Рекомендации
                    if (_statistics!.needsCleanup) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Рекомендуется очистка кэша',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _clearExpired,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Очистить'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildStatCard(String title, String value, Color color, IconData icon) => Container(
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildStatRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Color _getEfficiencyColor(String efficiency) {
    switch (efficiency) {
      case 'Отличная':
        return Colors.green;
      case 'Хорошая':
        return Colors.blue;
      case 'Удовлетворительная':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}д ${duration.inHours % 24}ч';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}ч ${duration.inMinutes % 60}м';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}м ${duration.inSeconds % 60}с';
    } else {
      return '${duration.inSeconds}с';
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _cacheService.initialize();
      _config = _cacheService.config;
      await _loadStatistics();
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

  Future<void> _loadStatistics() async {
    try {
      _statistics = await _cacheService.getStatistics();
      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка загрузки статистики: $e');
      }
    }
  }

  Future<List<String>> _getCacheKeys() async {
    try {
      return _cacheService.getAllKeys();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка получения ключей кэша: $e');
      }
      return [];
    }
  }

  void _handleItemAction(String action, String key) {
    switch (action) {
      case 'view':
        _viewCacheItem(key);
        break;
      case 'remove':
        _removeCacheItem(key);
        break;
    }
  }

  void _viewCacheItem(String key) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Элемент кэша: $key'),
        content: FutureBuilder<dynamic>(
          future: _cacheService.get(key),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text('Данные не найдены');
            }
            return SingleChildScrollView(child: Text(snapshot.data.toString()));
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  void _removeCacheItem(String key) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить элемент'),
        content: Text('Вы уверены, что хотите удалить элемент "$key"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _cacheService.remove(key);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Элемент удален'), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка удаления: $e'), backgroundColor: Colors.red),
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

  Future<void> _clearExpired() async {
    try {
      await _cacheService.clearExpired();
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Истекшие элементы очищены'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка очистки: $e'), backgroundColor: Colors.red));
    }
  }

  void _clearAll() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить весь кэш'),
        content: const Text(
          'Вы уверены, что хотите очистить весь кэш? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _cacheService.clear();
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Кэш очищен'), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка очистки: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  void _showCacheInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Информация о кэше'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Размер кэша: ${_statistics?.formattedTotalSize ?? 'Неизвестно'}'),
            Text('Количество элементов: ${_statistics?.totalItems ?? 0}'),
            Text(
              'Hit Rate: ${_statistics != null ? (_statistics!.hitRate * 100).toStringAsFixed(1) : '0'}%',
            ),
            Text('Эффективность: ${_statistics?.efficiency ?? 'Неизвестно'}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  void _resetConfig() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить настройки'),
        content: const Text(
          'Вы уверены, что хотите сбросить настройки кэша к значениям по умолчанию?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _cacheService.updateConfig(const CacheConfig());
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Настройки сброшены'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка сброса: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }

  void _showConfigDialog() {
    // TODO(developer): Реализовать диалог изменения настроек
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Функция изменения настроек будет реализована')));
  }
}
