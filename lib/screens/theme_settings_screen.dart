import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeSettings = ref.watch(themeSettingsProvider);
    final predefinedColors = ref.watch(predefinedColorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки темы'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Режим темы
            _buildSection(
              title: 'Режим темы',
              children: [
                _buildThemeModeCard(
                  context: context,
                  ref: ref,
                  currentMode: themeMode,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Основной цвет
            _buildSection(
              title: 'Основной цвет',
              children: [
                _buildColorPicker(
                  context: context,
                  ref: ref,
                  currentColor: themeSettings.primaryColor,
                  predefinedColors: predefinedColors,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Дополнительные настройки
            _buildSection(
              title: 'Дополнительные настройки',
              children: [
                _buildSwitchTile(
                  title: 'Использовать системную тему',
                  subtitle:
                      'Автоматически переключаться между светлой и темной темой',
                  value: themeSettings.useSystemTheme,
                  onChanged: (value) {
                    ref
                        .read(themeSettingsProvider.notifier)
                        .setUseSystemTheme(value);
                  },
                ),
                const SizedBox(height: 8),
                _buildSwitchTile(
                  title: 'Material Design 3',
                  subtitle: 'Использовать новую версию Material Design',
                  value: themeSettings.useMaterial3,
                  onChanged: (value) {
                    ref
                        .read(themeSettingsProvider.notifier)
                        .setUseMaterial3(value);
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Предварительный просмотр
            _buildSection(
              title: 'Предварительный просмотр',
              children: [
                _buildThemePreview(context),
              ],
            ),

            const SizedBox(height: 24),

            // Кнопки действий
            _buildActionButtons(context, ref),
          ],
        ),
      ),
    );
  }

  /// Построить секцию
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
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
  }

  /// Построить карточку режима темы
  Widget _buildThemeModeCard({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeMode currentMode,
  }) {
    return Card(
      child: Column(
        children: [
          _buildThemeModeOption(
            context: context,
            ref: ref,
            mode: ThemeMode.light,
            title: 'Светлая тема',
            subtitle: 'Всегда использовать светлую тему',
            icon: Icons.light_mode,
            isSelected: currentMode == ThemeMode.light,
          ),
          const Divider(height: 1),
          _buildThemeModeOption(
            context: context,
            ref: ref,
            mode: ThemeMode.dark,
            title: 'Темная тема',
            subtitle: 'Всегда использовать темную тему',
            icon: Icons.dark_mode,
            isSelected: currentMode == ThemeMode.dark,
          ),
          const Divider(height: 1),
          _buildThemeModeOption(
            context: context,
            ref: ref,
            mode: ThemeMode.system,
            title: 'Системная тема',
            subtitle: 'Следовать настройкам системы',
            icon: Icons.brightness_auto,
            isSelected: currentMode == ThemeMode.system,
          ),
        ],
      ),
    );
  }

  /// Построить опцию режима темы
  Widget _buildThemeModeOption({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing:
          isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      selected: isSelected,
      onTap: () {
        ref.read(themeProvider.notifier).setTheme(mode);
      },
    );
  }

  /// Построить выбор цвета
  Widget _buildColorPicker({
    required BuildContext context,
    required WidgetRef ref,
    required Color currentColor,
    required List<Color> predefinedColors,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Выберите основной цвет',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Предустановленные цвета
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: predefinedColors.map((color) {
                final isSelected = color.value == currentColor.value;
                return GestureDetector(
                  onTap: () {
                    ref
                        .read(themeSettingsProvider.notifier)
                        .setPrimaryColor(color);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.grey,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Текущий цвет
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: currentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: currentColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: currentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Текущий цвет: ${_getColorName(currentColor)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Построить переключатель
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeThumbColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// Построить предварительный просмотр темы
  Widget _buildThemePreview(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Предварительный просмотр',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Пример AppBar
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'AppBar',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Пример карточки
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Заголовок карточки',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Описание карточки',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Пример кнопки
            ElevatedButton(
              onPressed: () {},
              child: const Text('Кнопка'),
            ),
          ],
        ),
      ),
    );
  }

  /// Построить кнопки действий
  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _resetToDefault(context, ref),
            icon: const Icon(Icons.restore),
            label: const Text('Сбросить к умолчанию'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _exportTheme(context, ref),
            icon: const Icon(Icons.download),
            label: const Text('Экспортировать настройки'),
          ),
        ),
      ],
    );
  }

  /// Сбросить к умолчанию
  void _resetToDefault(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить настройки'),
        content: const Text(
            'Вы уверены, что хотите сбросить все настройки темы к умолчанию?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(themeProvider.notifier).setTheme(ThemeMode.system);
              ref
                  .read(themeSettingsProvider.notifier)
                  .setPrimaryColor(Colors.deepPurple);
              ref.read(themeSettingsProvider.notifier).setUseSystemTheme(true);
              ref.read(themeSettingsProvider.notifier).setUseMaterial3(true);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Настройки сброшены к умолчанию'),
                ),
              );
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }

  /// Экспортировать настройки
  void _exportTheme(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.read(themeSettingsProvider);
    final themeMode = ref.read(themeProvider);

    // TODO: Реализовать экспорт настроек
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Экспорт настроек будет реализован в следующем шаге'),
      ),
    );
  }

  /// Получить название цвета
  String _getColorName(Color color) {
    if (color == Colors.deepPurple) return 'Глубокий фиолетовый';
    if (color == Colors.blue) return 'Синий';
    if (color == Colors.green) return 'Зеленый';
    if (color == Colors.orange) return 'Оранжевый';
    if (color == Colors.red) return 'Красный';
    if (color == Colors.pink) return 'Розовый';
    if (color == Colors.teal) return 'Бирюзовый';
    if (color == Colors.indigo) return 'Индиго';
    if (color == Colors.cyan) return 'Голубой';
    if (color == Colors.amber) return 'Янтарный';
    return 'Пользовательский';
  }
}
