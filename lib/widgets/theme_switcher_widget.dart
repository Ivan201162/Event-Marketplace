import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

/// Виджет для переключения тем
class ThemeSwitcherWidget extends ConsumerWidget {
  const ThemeSwitcherWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return PopupMenuButton<ThemeMode>(
      icon: Icon(_getThemeIcon(themeMode),
          color: Theme.of(context).colorScheme.onSurface),
      tooltip: 'Переключить тему',
      onSelected: (mode) {
        switch (mode) {
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
      itemBuilder: (context) => [
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(
                Icons.light_mode,
                color: themeMode == ThemeMode.light
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              Text(
                'Светлая',
                style: TextStyle(
                  color: themeMode == ThemeMode.light
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: themeMode == ThemeMode.light
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.dark,
          child: Row(
            children: [
              Icon(
                Icons.dark_mode,
                color: themeMode == ThemeMode.dark
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              Text(
                'Тёмная',
                style: TextStyle(
                  color: themeMode == ThemeMode.dark
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: themeMode == ThemeMode.dark
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.system,
          child: Row(
            children: [
              Icon(
                Icons.brightness_auto,
                color: themeMode == ThemeMode.system
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              Text(
                'Автоматическая',
                style: TextStyle(
                  color: themeMode == ThemeMode.system
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: themeMode == ThemeMode.system
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
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
}

/// Простой переключатель тем (кнопка)
class SimpleThemeSwitcher extends ConsumerWidget {
  const SimpleThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return IconButton(
      icon: Icon(_getThemeIcon(themeMode)),
      onPressed: themeNotifier.toggleTheme,
      tooltip: 'Переключить тему',
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
}
