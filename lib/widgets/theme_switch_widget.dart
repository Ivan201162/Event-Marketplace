import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive_utils.dart';
import '../providers/theme_provider.dart';

/// Виджет для переключения тем
class ThemeSwitchWidget extends ConsumerWidget {
  const ThemeSwitchWidget({
    super.key,
    this.showLabel = true,
    this.showDescription = true,
    this.padding,
  });
  final bool showLabel;
  final bool showDescription;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLabel) ...[
            Row(
              children: [
                Icon(
                  currentTheme.icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ResponsiveText(
                        'Тема приложения',
                        isTitle: true,
                      ),
                      if (showDescription)
                        ResponsiveText(
                          currentTheme.description,
                          isSubtitle: true,
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: currentTheme == AppThemeMode.dark,
                  onChanged: (value) {
                    if (value) {
                      themeNotifier.setDarkTheme();
                    } else {
                      themeNotifier.setLightTheme();
                    }
                  },
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  currentTheme.icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Switch(
                  value: currentTheme == AppThemeMode.dark,
                  onChanged: (value) {
                    if (value) {
                      themeNotifier.setDarkTheme();
                    } else {
                      themeNotifier.setLightTheme();
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Виджет для выбора темы из списка
class ThemeSelectorWidget extends ConsumerWidget {
  const ThemeSelectorWidget({
    super.key,
    this.showTitle = true,
    this.padding,
  });
  final bool showTitle;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final availableThemes = ref.watch(availableThemesProvider);

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            const ResponsiveText(
              'Выберите тему',
              isTitle: true,
            ),
            const SizedBox(height: 16),
          ],
          ...availableThemes.map(
            (theme) => _buildThemeOption(
              context,
              theme,
              currentTheme,
              themeNotifier,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    AppThemeMode theme,
    AppThemeMode currentTheme,
    ThemeNotifier themeNotifier,
  ) {
    final isSelected = theme == currentTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _selectTheme(theme, themeNotifier),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                theme.icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      theme.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ResponsiveText(
                      theme.description,
                      isSubtitle: true,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTheme(AppThemeMode theme, ThemeNotifier themeNotifier) {
    switch (theme) {
      case AppThemeMode.light:
        themeNotifier.setLightTheme();
        break;
      case AppThemeMode.dark:
        themeNotifier.setDarkTheme();
        break;
      case AppThemeMode.system:
        themeNotifier.setSystemTheme();
        break;
    }
  }
}

/// Виджет для быстрого переключения темы
class QuickThemeToggle extends ConsumerWidget {
  const QuickThemeToggle({
    super.key,
    this.size,
    this.iconColor,
  });
  final double? size;
  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final isDark = ref.watch(isDarkModeProvider);

    return IconButton(
      onPressed: themeNotifier.toggleTheme,
      icon: Icon(
        isDark ? Icons.light_mode : Icons.dark_mode,
        size: size ?? 24,
        color: iconColor ?? Theme.of(context).colorScheme.onSurface,
      ),
      tooltip:
          isDark ? 'Переключить на светлую тему' : 'Переключить на темную тему',
    );
  }
}

/// Виджет для отображения информации о текущей теме
class ThemeInfoWidget extends ConsumerWidget {
  const ThemeInfoWidget({
    super.key,
    this.showIcon = true,
    this.showDescription = true,
  });
  final bool showIcon;
  final bool showDescription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final themeColors = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeColors.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showIcon) ...[
                Icon(
                  currentTheme.icon,
                  color: themeColors.primary,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      'Текущая тема: ${currentTheme.name}',
                      isTitle: true,
                    ),
                    if (showDescription)
                      ResponsiveText(
                        currentTheme.description,
                        isSubtitle: true,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const ResponsiveText(
            'Цветовая схема:',
            isSubtitle: true,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildColorPreview('Основной', themeColors.primary),
              const SizedBox(width: 12),
              _buildColorPreview('Вторичный', themeColors.secondary),
              const SizedBox(width: 12),
              _buildColorPreview('Поверхность', themeColors.surface),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorPreview(String label, Color color) => Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      );
}

/// Виджет для настроек темы
class ThemeSettingsWidget extends ConsumerWidget {
  const ThemeSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveText(
            'Настройки темы',
            isTitle: true,
          ),
          const SizedBox(height: 16),
          const ThemeSelectorWidget(showTitle: false),
          const SizedBox(height: 24),
          const ThemeInfoWidget(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(themeProvider.notifier).setLightTheme(),
                icon: const Icon(Icons.light_mode),
                label: const Text('Светлая'),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(themeProvider.notifier).setDarkTheme(),
                icon: const Icon(Icons.dark_mode),
                label: const Text('Темная'),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(themeProvider.notifier).setSystemTheme(),
                icon: const Icon(Icons.brightness_auto),
                label: const Text('Системная'),
              ),
            ],
          ),
        ],
      );
}
