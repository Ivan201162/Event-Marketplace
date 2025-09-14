import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

/// Виджет для переключения темы
class ThemeSwitch extends ConsumerWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return PopupMenuButton<ThemeMode>(
      icon: Icon(
        _getThemeIcon(themeMode),
        color: context.colorScheme.onSurface,
      ),
      tooltip: 'Переключить тему',
      onSelected: (ThemeMode mode) {
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
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(
                Icons.light_mode,
                color: themeMode == ThemeMode.light 
                    ? context.colorScheme.primary 
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                'Светлая тема',
                style: TextStyle(
                  color: themeMode == ThemeMode.light 
                      ? context.colorScheme.primary 
                      : null,
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
                    ? context.colorScheme.primary 
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                'Тёмная тема',
                style: TextStyle(
                  color: themeMode == ThemeMode.dark 
                      ? context.colorScheme.primary 
                      : null,
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
                    ? context.colorScheme.primary 
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                'Системная тема',
                style: TextStyle(
                  color: themeMode == ThemeMode.system 
                      ? context.colorScheme.primary 
                      : null,
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

/// Простой переключатель темы в виде кнопки
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return AnimatedButton(
      onPressed: () => themeNotifier.toggleTheme(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Icon(
          _getThemeIcon(themeMode),
          color: context.colorScheme.onSurface,
        ),
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
}

/// Переключатель темы в виде Switch
class ThemeSwitchWidget extends ConsumerWidget {
  const ThemeSwitchWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final isDark = themeMode == ThemeMode.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.light_mode,
          color: isDark ? Colors.grey : context.colorScheme.primary,
        ),
        Switch(
          value: isDark,
          onChanged: (value) {
            if (value) {
              themeNotifier.setDarkTheme();
            } else {
              themeNotifier.setLightTheme();
            }
          },
          activeColor: context.colorScheme.primary,
        ),
        Icon(
          Icons.dark_mode,
          color: isDark ? context.colorScheme.primary : Colors.grey,
        ),
      ],
    );
  }
}
