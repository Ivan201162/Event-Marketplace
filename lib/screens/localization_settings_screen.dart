import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/localization.dart';
import '../providers/localization_providers.dart';
import '../services/localization_service.dart';

/// Экран настроек локализации
class LocalizationSettingsScreen extends ConsumerStatefulWidget {
  const LocalizationSettingsScreen({super.key});

  @override
  ConsumerState<LocalizationSettingsScreen> createState() => _LocalizationSettingsScreenState();
}

class _LocalizationSettingsScreenState extends ConsumerState<LocalizationSettingsScreen> {
  final LocalizationService _localizationService = LocalizationService();

  @override
  void initState() {
    super.initState();
    // Инициализируем локализацию при загрузке экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localizationInitializationProvider);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Настройки языка'),
      actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshLocalization)],
    ),
    body: Consumer(
      builder: (context, ref, child) {
        final initializationAsync = ref.watch(localizationInitializationProvider);

        return initializationAsync.when(
          data: (_) => _buildContent(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildError(error),
        );
      },
    ),
  );

  Widget _buildContent() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Текущий язык
        _buildCurrentLanguage(),

        const SizedBox(height: 24),

        // Выбор языка
        _buildLanguageSelection(),

        const SizedBox(height: 24),

        // Дополнительные настройки
        _buildAdditionalSettings(),

        const SizedBox(height: 24),

        // Статистика локализации
        _buildLocalizationStats(),

        const SizedBox(height: 24),

        // Действия
        _buildActions(),
      ],
    ),
  );

  Widget _buildCurrentLanguage() => Consumer(
    builder: (context, ref, child) {
      final currentLanguage = ref.watch(currentLanguageProvider);
      final currentLocalization = ref.watch(currentLocalizationProvider);

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Текущий язык',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.language, color: Colors.blue, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentLocalization?.displayName ?? 'Русский',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentLocalization?.nativeName ?? 'Русский',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Код: $currentLanguage',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _buildLanguageSelection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Выберите язык', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, child) {
              final supportedLanguages = ref.watch(supportedLanguagesProvider);
              final currentLanguage = ref.watch(currentLanguageProvider);

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: supportedLanguages.length,
                itemBuilder: (context, index) {
                  final language = supportedLanguages[index];
                  final isSelected = language.languageCode == currentLanguage;

                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.language,
                        color: isSelected ? Colors.blue : Colors.grey,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      language.displayName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.blue : null,
                      ),
                    ),
                    subtitle: Text(language.nativeName, style: TextStyle(color: Colors.grey[600])),
                    trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                    onTap: () => _changeLanguage(language.languageCode),
                  );
                },
              );
            },
          ),
        ],
      ),
    ),
  );

  Widget _buildAdditionalSettings() => Consumer(
    builder: (context, ref, child) {
      final settings = ref.watch(localizationSettingsProvider);

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Дополнительные настройки',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Автоматическое определение языка
              SwitchListTile(
                title: const Text('Автоматическое определение языка'),
                subtitle: const Text('Определять язык системы автоматически'),
                value: settings?.autoDetectLanguage ?? true,
                onChanged: (value) {
                  _updateSettings(
                    settings?.copyWith(autoDetectLanguage: value, lastUpdated: DateTime.now()),
                  );
                },
              ),

              const Divider(),

              // Показывать родные названия
              SwitchListTile(
                title: const Text('Показывать родные названия'),
                subtitle: const Text('Отображать названия языков на их родном языке'),
                value: settings?.showNativeNames ?? false,
                onChanged: (value) {
                  _updateSettings(
                    settings?.copyWith(showNativeNames: value, lastUpdated: DateTime.now()),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _buildLocalizationStats() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Статистика локализации',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, child) {
              final allStatsAsync = ref.watch(allLocalizationStatsProvider);

              return allStatsAsync.when(
                data: (stats) {
                  if (stats.isEmpty) {
                    return const Center(child: Text('Нет данных о статистике'));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stats.length,
                    itemBuilder: (context, index) {
                      final stat = stats[index];
                      return _buildStatItem(stat);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Ошибка: $error')),
              );
            },
          ),
        ],
      ),
    ),
  );

  Widget _buildStatItem(LocalizationStats stat) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              stat.language.toUpperCase(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${stat.completionPercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: stat.completionPercentage >= 80
                    ? Colors.green
                    : stat.completionPercentage >= 50
                    ? Colors.orange
                    : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Прогресс-бар
        LinearProgressIndicator(
          value: stat.completionPercentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            stat.completionPercentage >= 80
                ? Colors.green
                : stat.completionPercentage >= 50
                ? Colors.orange
                : Colors.red,
          ),
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Переведено: ${stat.translatedKeys}/${stat.totalKeys}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (stat.missingKeys > 0)
              Text(
                'Отсутствует: ${stat.missingKeys}',
                style: TextStyle(fontSize: 12, color: Colors.red[600]),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _buildActions() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Действия', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Очистить кэш
          ListTile(
            leading: const Icon(Icons.clear_all, color: Colors.orange),
            title: const Text('Очистить кэш локализации'),
            subtitle: const Text('Удалить кэшированные переводы'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _clearCache,
          ),

          const Divider(),

          // Экспорт переводов
          ListTile(
            leading: const Icon(Icons.download, color: Colors.blue),
            title: const Text('Экспорт переводов'),
            subtitle: const Text('Скачать файлы переводов'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportTranslations,
          ),

          const Divider(),

          // Импорт переводов
          ListTile(
            leading: const Icon(Icons.upload, color: Colors.green),
            title: const Text('Импорт переводов'),
            subtitle: const Text('Загрузить файлы переводов'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _importTranslations,
          ),
        ],
      ),
    ),
  );

  Widget _buildError(Object error) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        const Text(
          'Ошибка загрузки локализации',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          error.toString(),
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _refreshLocalization, child: const Text('Повторить')),
      ],
    ),
  );

  Future<void> _changeLanguage(String languageCode) async {
    try {
      await ref.read(changeLanguageProvider(languageCode).future);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Язык изменён на $languageCode'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка изменения языка: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateSettings(LocalizationSettings? settings) async {
    if (settings == null) return;

    try {
      await ref.read(updateLocalizationSettingsProvider(settings).future);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Настройки сохранены'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения настроек: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _refreshLocalization() async {
    try {
      await ref.read(localizationInitializationProvider.future);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Локализация обновлена'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка обновления: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _clearCache() async {
    try {
      await ref.read(clearLocalizationCacheProvider.future);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Кэш очищен'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка очистки кэша: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _exportTranslations() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Экспорт переводов'),
        content: const Text('Функция экспорта переводов будет доступна в следующих обновлениях.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  void _importTranslations() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Импорт переводов'),
        content: const Text('Функция импорта переводов будет доступна в следующих обновлениях.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        ],
      ),
    );
  }
}
