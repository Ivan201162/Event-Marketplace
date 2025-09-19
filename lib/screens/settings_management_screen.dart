import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';
import '../widgets/responsive_layout.dart';
import '../ui/ui.dart';

/// Экран управления настройками и конфигурацией
class SettingsManagementScreen extends ConsumerStatefulWidget {
  const SettingsManagementScreen({super.key});

  @override
  ConsumerState<SettingsManagementScreen> createState() =>
      _SettingsManagementScreenState();
}

class _SettingsManagementScreenState
    extends ConsumerState<SettingsManagementScreen> {
  final SettingsService _settingsService = SettingsService();
  List<AppSettings> _settings = [];
  List<AppConfiguration> _configurations = [];
  bool _isLoading = true;
  String _selectedTab = 'settings';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
        body: Column(
          children: [
            // Вкладки
            _buildTabs(),

            // Контент
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedTab == 'settings'
                      ? _buildSettingsTab()
                      : _selectedTab == 'configurations'
                          ? _buildConfigurationsTab()
                          : _buildHistoryTab(),
            ),
          ],
        ),
      );

  Widget _buildTabs() => ResponsiveCard(
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton('settings', 'Настройки', Icons.settings),
            ),
            Expanded(
              child:
                  _buildTabButton('configurations', 'Конфигурации', Icons.tune),
            ),
            Expanded(
              child: _buildTabButton('history', 'История', Icons.history),
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

  Widget _buildSettingsTab() => Column(
        children: [
          // Заголовок с фильтрами
          ResponsiveCard(
            child: Row(
              children: [
                const ResponsiveText(
                  'Настройки приложения',
                  isTitle: true,
                ),
                const Spacer(),
                DropdownButton<String?>(
                  value: _selectedCategory,
                  hint: const Text('Все категории'),
                  items: [
                    const DropdownMenuItem<String?>(
                      child: Text('Все категории'),
                    ),
                    ..._getCategories().map(
                      (category) => DropdownMenuItem<String?>(
                        value: category,
                        child: Text(category),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                    _loadSettingsByCategory();
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showCreateSettingDialog,
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

          // Список настроек
          Expanded(
            child: _settings.isEmpty
                ? const Center(child: Text('Настройки не найдены'))
                : ListView.builder(
                    itemCount: _settings.length,
                    itemBuilder: (context, index) {
                      final setting = _settings[index];
                      return _buildSettingCard(setting);
                    },
                  ),
          ),
        ],
      );

  Widget _buildSettingCard(AppSettings setting) {
    final typeColor = _getTypeColor(setting.type);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                setting.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      setting.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (setting.description != null)
                      Text(
                        setting.description!,
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
                  setting.type.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleSettingAction(value, setting),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Редактировать'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'history',
                    child: ListTile(
                      leading: Icon(Icons.history),
                      title: Text('История'),
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
              _formatSettingValue(setting.value),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Метаданные
          Row(
            children: [
              if (setting.category != null) ...[
                _buildInfoChip('Категория', setting.category!, Colors.blue),
                const SizedBox(width: 8),
              ],
              if (setting.isPublic)
                _buildInfoChip('Публичная', 'Да', Colors.green),
              if (setting.isRequired)
                _buildInfoChip('Обязательная', 'Да', Colors.orange),
            ],
          ),

          const SizedBox(height: 8),

          // Время
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Обновлено: ${_formatDateTime(setting.updatedAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (setting.updatedBy != null) ...[
                const Spacer(),
                Text(
                  'Кем: ${setting.updatedBy}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationsTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                const ResponsiveText(
                  'Конфигурации приложения',
                  isTitle: true,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showCreateConfigurationDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Создать конфигурацию'),
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

          // Список конфигураций
          Expanded(
            child: _configurations.isEmpty
                ? const Center(child: Text('Конфигурации не найдены'))
                : ListView.builder(
                    itemCount: _configurations.length,
                    itemBuilder: (context, index) {
                      final configuration = _configurations[index];
                      return _buildConfigurationCard(configuration);
                    },
                  ),
          ),
        ],
      );

  Widget _buildConfigurationCard(AppConfiguration configuration) {
    final typeColor = _getConfigurationTypeColor(configuration.type);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                configuration.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      configuration.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      configuration.description,
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
                  configuration.type.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (configuration.isActive)
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
                    'Активна',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleConfigurationAction(value, configuration),
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
                  if (!configuration.isActive)
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
              _buildInfoChip(
                'Параметров',
                '${configuration.config.length}',
                Colors.blue,
              ),
              if (configuration.environment != null) ...[
                const SizedBox(width: 8),
                _buildInfoChip(
                  'Окружение',
                  configuration.environment!,
                  Colors.green,
                ),
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
                'Создана: ${_formatDateTime(configuration.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Spacer(),
              Text(
                'Обновлена: ${_formatDateTime(configuration.updatedAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                const ResponsiveText(
                  'История изменений',
                  isTitle: true,
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

          // Список истории
          const Expanded(
            child: Center(
              child: Text('История изменений будет отображаться здесь'),
            ),
          ),
        ],
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

  Color _getTypeColor(SettingType type) {
    switch (type) {
      case SettingType.string:
        return Colors.blue;
      case SettingType.number:
        return Colors.green;
      case SettingType.boolean:
        return Colors.orange;
      case SettingType.array:
        return Colors.purple;
      case SettingType.object:
        return Colors.brown;
      case SettingType.color:
        return Colors.pink;
      case SettingType.url:
        return Colors.cyan;
      case SettingType.email:
        return Colors.indigo;
      case SettingType.date:
        return Colors.teal;
      case SettingType.json:
        return Colors.grey;
    }
  }

  Color _getConfigurationTypeColor(ConfigurationType type) {
    switch (type) {
      case ConfigurationType.general:
        return Colors.blue;
      case ConfigurationType.ui:
        return Colors.purple;
      case ConfigurationType.api:
        return Colors.green;
      case ConfigurationType.database:
        return Colors.orange;
      case ConfigurationType.security:
        return Colors.red;
      case ConfigurationType.notifications:
        return Colors.cyan;
      case ConfigurationType.payments:
        return Colors.green;
      case ConfigurationType.integrations:
        return Colors.indigo;
      case ConfigurationType.features:
        return Colors.pink;
      case ConfigurationType.environment:
        return Colors.brown;
    }
  }

  String _formatSettingValue(value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    if (value is Map || value is List) {
      return const JsonEncoder.withIndent('  ').convert(value);
    }
    return value.toString();
  }

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

  List<String> _getCategories() {
    final categories = <String>{};
    for (final setting in _settings) {
      if (setting.category != null) {
        categories.add(setting.category!);
      }
    }
    return categories.toList()..sort();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _settingsService.initialize();
      setState(() {
        _settings = _settingsService.getAllSettings();
        _configurations = _settingsService.getAllConfigurations();
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

  Future<void> _loadSettingsByCategory() async {
    if (_selectedCategory == null) {
      _loadData();
      return;
    }

    try {
      final settings =
          await _settingsService.getSettingsByCategory(_selectedCategory!);
      setState(() {
        _settings = settings;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки настроек по категории: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleSettingAction(String action, AppSettings setting) {
    switch (action) {
      case 'edit':
        _editSetting(setting);
        break;
      case 'history':
        _viewSettingHistory(setting);
        break;
      case 'export':
        _exportSetting(setting);
        break;
      case 'delete':
        _deleteSetting(setting);
        break;
    }
  }

  void _editSetting(AppSettings setting) {
    showDialog(
      context: context,
      builder: (context) => _buildEditSettingDialog(setting),
    );
  }

  Widget _buildEditSettingDialog(AppSettings setting) {
    final valueController =
        TextEditingController(text: _formatSettingValue(setting.value));

    return AlertDialog(
      title: Text('Редактировать настройку: ${setting.key}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Тип: ${setting.type.displayName}'),
          const SizedBox(height: 16),
          TextField(
            controller: valueController,
            decoration: const InputDecoration(
              labelText: 'Значение',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              // TODO: Парсинг значения в зависимости от типа
              await _settingsService.setSetting(
                setting.key,
                valueController.text,
                type: setting.type,
                description: setting.description,
                category: setting.category,
                isPublic: setting.isPublic,
                isRequired: setting.isRequired,
                validation: setting.validation,
                updatedBy:
                    'current_user', // TODO: Получить ID текущего пользователя
              );
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Настройка обновлена'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ошибка обновления настройки: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  void _viewSettingHistory(AppSettings setting) {
    // TODO: Реализовать просмотр истории настройки
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('История настройки "${setting.key}" будет реализована'),
      ),
    );
  }

  void _exportSetting(AppSettings setting) {
    // TODO: Реализовать экспорт настройки
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Экспорт настройки "${setting.key}" будет реализован'),
      ),
    );
  }

  void _deleteSetting(AppSettings setting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить настройку'),
        content:
            Text('Вы уверены, что хотите удалить настройку "${setting.key}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _settingsService.removeSetting(
                  setting.key,
                  removedBy:
                      'current_user', // TODO: Получить ID текущего пользователя
                );
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Настройка удалена'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка удаления настройки: $e'),
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

  void _handleConfigurationAction(
    String action,
    AppConfiguration configuration,
  ) {
    switch (action) {
      case 'view':
        _viewConfiguration(configuration);
        break;
      case 'edit':
        _editConfiguration(configuration);
        break;
      case 'activate':
        _activateConfiguration(configuration);
        break;
      case 'export':
        _exportConfiguration(configuration);
        break;
      case 'delete':
        _deleteConfiguration(configuration);
        break;
    }
  }

  void _viewConfiguration(AppConfiguration configuration) {
    // TODO: Реализовать просмотр конфигурации
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Просмотр конфигурации "${configuration.name}" будет реализован',
        ),
      ),
    );
  }

  void _editConfiguration(AppConfiguration configuration) {
    // TODO: Реализовать редактирование конфигурации
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Редактирование конфигурации "${configuration.name}" будет реализовано',
        ),
      ),
    );
  }

  void _activateConfiguration(AppConfiguration configuration) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Активировать конфигурацию'),
        content: Text('Активировать конфигурацию "${configuration.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _settingsService.activateConfiguration(
                  configuration.id,
                  activatedBy:
                      'current_user', // TODO: Получить ID текущего пользователя
                );
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Конфигурация активирована'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка активации конфигурации: $e'),
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

  void _exportConfiguration(AppConfiguration configuration) {
    // TODO: Реализовать экспорт конфигурации
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Экспорт конфигурации "${configuration.name}" будет реализован',
        ),
      ),
    );
  }

  void _deleteConfiguration(AppConfiguration configuration) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить конфигурацию'),
        content: Text(
          'Вы уверены, что хотите удалить конфигурацию "${configuration.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Реализовать удаление конфигурации
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Удаление конфигурации будет реализовано'),
                ),
              );
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

  void _showCreateSettingDialog() {
    // TODO: Реализовать диалог создания настройки
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Создание настройки будет реализовано'),
      ),
    );
  }

  void _showCreateConfigurationDialog() {
    // TODO: Реализовать диалог создания конфигурации
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Создание конфигурации будет реализовано'),
      ),
    );
  }
}
