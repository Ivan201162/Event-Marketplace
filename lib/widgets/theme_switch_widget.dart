import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

/// Виджет для переключения темы
class ThemeSwitchWidget extends ConsumerWidget {
  const ThemeSwitchWidget({
    super.key,
    this.showLabel = true,
    this.compact = false,
  });

  final bool showLabel;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    if (compact) {
      return _buildCompactSwitch(context, themeMode, themeNotifier);
    }

    return _buildFullSwitch(context, themeMode, themeNotifier);
  }

  Widget _buildCompactSwitch(
    BuildContext context,
    ThemeMode themeMode,
    ThemeNotifier themeNotifier,
  ) =>
      IconButton(
        onPressed: () => themeNotifier.toggleTheme(),
        icon: Icon(_getThemeIcon(themeMode)),
        tooltip: _getThemeTooltip(themeMode),
      );

  Widget _buildFullSwitch(
    BuildContext context,
    ThemeMode themeMode,
    ThemeNotifier themeNotifier,
  ) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    _getThemeIcon(themeMode),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Тема',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (showLabel) ...[
                Text(
                  _getThemeDescription(themeMode),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
              ],
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode),
                    label: Text('Светлая'),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode),
                    label: Text('Темная'),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto),
                    label: Text('Система'),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (selection) {
                  final selectedTheme = selection.first;
                  switch (selectedTheme) {
                    case ThemeMode.light:
                      themeNotifier.setLightTheme();
                      break;
                    case ThemeMode.dark:
                      themeNotifier.setDarkTheme();
                      break;
                    case ThemeMode.system:
                      themeNotifier.setSystemTheme();
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      );

  IconData _getThemeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getThemeTooltip(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Переключить на темную тему';
      case ThemeMode.dark:
        return 'Переключить на системную тему';
      case ThemeMode.system:
        return 'Переключить на светлую тему';
    }
  }

  String _getThemeDescription(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Всегда использует светлую тему';
      case ThemeMode.dark:
        return 'Всегда использует темную тему';
      case ThemeMode.system:
        return 'Следует системным настройкам';
    }
  }
}

/// Простой переключатель темы для AppBar
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return IconButton(
      onPressed: themeNotifier.toggleTheme,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          _getThemeIcon(themeMode),
          key: ValueKey(themeMode),
        ),
      ),
      tooltip: _getThemeTooltip(themeMode),
    );
  }

  IconData _getThemeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getThemeTooltip(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Переключить на темную тему';
      case ThemeMode.dark:
        return 'Переключить на системную тему';
      case ThemeMode.system:
        return 'Переключить на светлую тему';
    }
  }
}

/// Виджет для отображения текущей темы
class ThemeIndicator extends ConsumerWidget {
  const ThemeIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getThemeIcon(themeMode),
            size: 16,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            _getThemeLabel(themeMode),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }

  IconData _getThemeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getThemeLabel(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Светлая';
      case ThemeMode.dark:
        return 'Темная';
      case ThemeMode.system:
        return 'Система';
    }
  }
}
