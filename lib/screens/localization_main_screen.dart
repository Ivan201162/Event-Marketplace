import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'localization_settings_screen.dart';
import 'translation_management_screen.dart';

/// Главный экран локализации
class LocalizationMainScreen extends ConsumerWidget {
  const LocalizationMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(
          title: const Text('Локализация'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Основные настройки
            _buildSection(
              title: 'Основные настройки',
              children: [
                _buildSettingsTile(
                  icon: Icons.language,
                  title: 'Настройки языка',
                  subtitle: 'Выбор языка и дополнительные настройки',
                  onTap: () => _navigateToScreen(
                    context,
                    const LocalizationSettingsScreen(),
                  ),
                ),
                _buildSettingsTile(
                  icon: Icons.translate,
                  title: 'Управление переводами',
                  subtitle: 'Редактирование и управление переводами',
                  onTap: () => _navigateToScreen(
                    context,
                    const TranslationManagementScreen(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Статистика
            _buildSection(
              title: 'Статистика локализации',
              children: [
                _buildStatsCard(),
              ],
            ),

            const SizedBox(height: 24),

            // Быстрые действия
            _buildSection(
              title: 'Быстрые действия',
              children: [
                _buildQuickActionTile(
                  icon: Icons.download,
                  title: 'Экспорт переводов',
                  subtitle: 'Скачать файлы переводов',
                  color: Colors.blue,
                  onTap: () => _exportTranslations(context),
                ),
                _buildQuickActionTile(
                  icon: Icons.upload,
                  title: 'Импорт переводов',
                  subtitle: 'Загрузить файлы переводов',
                  color: Colors.green,
                  onTap: () => _importTranslations(context),
                ),
                _buildQuickActionTile(
                  icon: Icons.clear_all,
                  title: 'Очистить кэш',
                  subtitle: 'Удалить кэшированные переводы',
                  color: Colors.orange,
                  onTap: () => _clearCache(context),
                ),
                _buildQuickActionTile(
                  icon: Icons.refresh,
                  title: 'Обновить переводы',
                  subtitle: 'Загрузить последние переводы',
                  color: Colors.purple,
                  onTap: () => _refreshTranslations(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Информация
            _buildSection(
              title: 'Информация',
              children: [
                _buildInfoCard(),
              ],
            ),
          ],
        ),
      );

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      );

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );

  Widget _buildStatsCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Общая статистика',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Статистика по языкам
              Consumer(
                builder: (context, ref, child) {
                  final allStatsAsync = ref.watch(allLocalizationStatsProvider);

                  return allStatsAsync.when(
                    data: (stats) {
                      if (stats.isEmpty) {
                        return const Center(
                          child: Text('Нет данных о статистике'),
                        );
                      }

                      return Column(
                        children: stats
                            .map(
                              (stat) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    // Язык
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          stat.language.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    // Информация
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${stat.completionPercentage.toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: stat.completionPercentage >=
                                                          80
                                                      ? Colors.green
                                                      : stat.completionPercentage >=
                                                              50
                                                          ? Colors.orange
                                                          : Colors.red,
                                                ),
                                              ),
                                              Text(
                                                '${stat.translatedKeys}/${stat.totalKeys}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          LinearProgressIndicator(
                                            value:
                                                stat.completionPercentage / 100,
                                            backgroundColor: Colors.grey[300],
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              stat.completionPercentage >= 80
                                                  ? Colors.green
                                                  : stat.completionPercentage >=
                                                          50
                                                      ? Colors.orange
                                                      : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Center(
                      child: Text('Ошибка: $error'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildInfoCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'О локализации',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Приложение поддерживает множественные языки и позволяет пользователям выбирать предпочитаемый язык интерфейса.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                'Поддерживаемые языки:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, child) {
                  final supportedLanguages =
                      ref.watch(supportedLanguagesProvider);

                  return Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: supportedLanguages
                        .map(
                          (language) => Chip(
                            label: Text(language.displayName),
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                            labelStyle: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Функции:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Автоматическое определение языка системы'),
                  Text('• Ручной выбор языка'),
                  Text('• Управление переводами'),
                  Text('• Экспорт/импорт переводов'),
                  Text('• Статистика локализации'),
                  Text('• Кэширование переводов'),
                ],
              ),
            ],
          ),
        ),
      );

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => screen),
    );
  }

  void _exportTranslations(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Экспорт переводов'),
        content: const Text(
          'Функция экспорта переводов будет доступна в следующих обновлениях приложения.',
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

  void _importTranslations(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Импорт переводов'),
        content: const Text(
          'Функция импорта переводов будет доступна в следующих обновлениях приложения.',
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

  void _clearCache(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить кэш'),
        content: const Text(
          'Вы уверены, что хотите очистить кэш локализации? Это может временно замедлить работу приложения.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO(developer): Реализовать очистку кэша
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Кэш очищен'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  void _refreshTranslations(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Обновить переводы'),
        content: const Text('Загрузить последние переводы с сервера?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO(developer): Реализовать обновление переводов
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Переводы обновлены'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Обновить'),
          ),
        ],
      ),
    );
  }
}
