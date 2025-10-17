import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/localization_providers.dart';
import '../services/localization_service.dart';

/// Экран управления переводами
class TranslationManagementScreen extends ConsumerStatefulWidget {
  const TranslationManagementScreen({super.key});

  @override
  ConsumerState<TranslationManagementScreen> createState() => _TranslationManagementScreenState();
}

class _TranslationManagementScreenState extends ConsumerState<TranslationManagementScreen> {
  final LocalizationService _localizationService = LocalizationService();
  String _selectedLanguage = 'ru';
  String _searchQuery = '';
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Управление переводами'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addTranslation,
            ),
          ],
        ),
        body: Column(
          children: [
            // Фильтры
            _buildFilters(),

            // Список переводов
            Expanded(
              child: _buildTranslationsList(),
            ),
          ],
        ),
      );

  Widget _buildFilters() => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Выбор языка
            Row(
              children: [
                const Text('Язык: '),
                const SizedBox(width: 8),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final supportedLanguages = ref.watch(supportedLanguagesProvider);

                      return DropdownButton<String>(
                        value: _selectedLanguage,
                        isExpanded: true,
                        items: supportedLanguages
                            .map(
                              (language) => DropdownMenuItem<String>(
                                value: language.languageCode,
                                child: Text(language.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLanguage = value ?? 'ru';
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Поиск и категория
            Row(
              children: [
                // Поиск
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Поиск по ключу или значению...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // Категория
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Все')),
                      DropdownMenuItem(value: 'general', child: Text('Общие')),
                      DropdownMenuItem(
                        value: 'navigation',
                        child: Text('Навигация'),
                      ),
                      DropdownMenuItem(value: 'events', child: Text('События')),
                      DropdownMenuItem(
                        value: 'profile',
                        child: Text('Профиль'),
                      ),
                      DropdownMenuItem(
                        value: 'settings',
                        child: Text('Настройки'),
                      ),
                      DropdownMenuItem(
                        value: 'notifications',
                        child: Text('Уведомления'),
                      ),
                      DropdownMenuItem(value: 'errors', child: Text('Ошибки')),
                      DropdownMenuItem(value: 'success', child: Text('Успех')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value ?? 'all';
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildTranslationsList() => Consumer(
        builder: (context, ref, child) {
          final currentLocalization = ref.watch(currentLocalizationProvider);

          if (currentLocalization == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final translations = _filterTranslations(currentLocalization.translations);

          if (translations.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: translations.length,
            itemBuilder: (context, index) {
              final entry = translations.entries.elementAt(index);
              return _buildTranslationItem(entry.key, entry.value);
            },
          );
        },
      );

  Widget _buildEmptyState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.translate,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Нет переводов',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Попробуйте изменить фильтры или добавить новые переводы',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildTranslationItem(String key, String value) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ExpansionTile(
          title: Text(
            key,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ключ
                  _buildInfoRow('Ключ', key),

                  const SizedBox(height: 8),

                  // Значение
                  _buildInfoRow('Значение', value),

                  const SizedBox(height: 8),

                  // Категория
                  _buildInfoRow('Категория', _getCategoryFromKey(key)),

                  const SizedBox(height: 16),

                  // Действия
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _editTranslation(key, value),
                          icon: const Icon(Icons.edit),
                          label: const Text('Редактировать'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyTranslation(key, value),
                          icon: const Icon(Icons.copy),
                          label: const Text('Копировать'),
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

  Widget _buildInfoRow(String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      );

  Map<String, String> _filterTranslations(Map<String, String> translations) {
    var filtered = translations;

    // Фильтр по поисковому запросу
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = Map.fromEntries(
        filtered.entries.where(
          (entry) =>
              entry.key.toLowerCase().contains(query) || entry.value.toLowerCase().contains(query),
        ),
      );
    }

    // Фильтр по категории
    if (_selectedCategory != 'all') {
      filtered = Map.fromEntries(
        filtered.entries.where(
          (entry) => _getCategoryFromKey(entry.key) == _selectedCategory,
        ),
      );
    }

    return filtered;
  }

  String _getCategoryFromKey(String key) {
    if (key.startsWith('app_') ||
        key.startsWith('loading') ||
        key.startsWith('error') ||
        key.startsWith('success')) {
      return 'general';
    } else if (key.startsWith('home') ||
        key.startsWith('events') ||
        key.startsWith('profile') ||
        key.startsWith('settings')) {
      return 'navigation';
    } else if (key.startsWith('event_')) {
      return 'events';
    } else if (key.startsWith('profile_')) {
      return 'profile';
    } else if (key.startsWith('language') ||
        key.startsWith('theme') ||
        key.startsWith('notifications_settings')) {
      return 'settings';
    } else if (key.startsWith('notification_') ||
        key.startsWith('push_') ||
        key.startsWith('email_') ||
        key.startsWith('sms_')) {
      return 'notifications';
    } else if (key.startsWith('error_')) {
      return 'errors';
    } else if (key.startsWith('success_')) {
      return 'success';
    }
    return 'general';
  }

  void _addTranslation() {
    showDialog<void>(
      context: context,
      builder: (context) => _TranslationDialog(
        language: _selectedLanguage,
        onSave: (key, value) {
          // TODO(developer): Реализовать добавление перевода
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Функция добавления перевода будет доступна в следующих обновлениях',
              ),
            ),
          );
        },
      ),
    );
  }

  void _editTranslation(String key, String value) {
    showDialog<void>(
      context: context,
      builder: (context) => _TranslationDialog(
        language: _selectedLanguage,
        initialKey: key,
        initialValue: value,
        onSave: (newKey, newValue) {
          // TODO(developer): Реализовать редактирование перевода
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Функция редактирования перевода будет доступна в следующих обновлениях',
              ),
            ),
          );
        },
      ),
    );
  }

  void _copyTranslation(String key, String value) {
    // TODO(developer): Реализовать копирование перевода
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Функция копирования перевода будет доступна в следующих обновлениях',
        ),
      ),
    );
  }
}

/// Диалог для добавления/редактирования перевода
class _TranslationDialog extends StatefulWidget {
  const _TranslationDialog({
    required this.language,
    this.initialKey,
    this.initialValue,
    required this.onSave,
  });
  final String language;
  final String? initialKey;
  final String? initialValue;
  final Function(String key, String value) onSave;

  @override
  State<_TranslationDialog> createState() => _TranslationDialogState();
}

class _TranslationDialogState extends State<_TranslationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _keyController;
  late TextEditingController _valueController;
  String _selectedCategory = 'general';

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.initialKey ?? '');
    _valueController = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(
          widget.initialKey == null ? 'Добавить перевод' : 'Редактировать перевод',
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Категория
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('Общие')),
                  DropdownMenuItem(
                    value: 'navigation',
                    child: Text('Навигация'),
                  ),
                  DropdownMenuItem(value: 'events', child: Text('События')),
                  DropdownMenuItem(value: 'profile', child: Text('Профиль')),
                  DropdownMenuItem(value: 'settings', child: Text('Настройки')),
                  DropdownMenuItem(
                    value: 'notifications',
                    child: Text('Уведомления'),
                  ),
                  DropdownMenuItem(value: 'errors', child: Text('Ошибки')),
                  DropdownMenuItem(value: 'success', child: Text('Успех')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? 'general';
                  });
                },
              ),

              const SizedBox(height: 16),

              // Ключ
              TextFormField(
                controller: _keyController,
                decoration: const InputDecoration(
                  labelText: 'Ключ',
                  border: OutlineInputBorder(),
                  hintText: 'например: button_save',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите ключ';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Значение
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Значение',
                  border: OutlineInputBorder(),
                  hintText: 'Текст перевода',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите значение';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: _saveTranslation,
            child: const Text('Сохранить'),
          ),
        ],
      );

  void _saveTranslation() {
    if (_formKey.currentState!.validate()) {
      final key = _selectedCategory == 'general'
          ? _keyController.text
          : '${_selectedCategory}_${_keyController.text}';
      final value = _valueController.text;

      widget.onSave(key, value);
      Navigator.pop(context);
    }
  }
}
