import 'package:event_marketplace_app/providers/theme_provider.dart';
import 'package:event_marketplace_app/services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Виджет для переключения темы
class ThemeSwitch extends ConsumerWidget {
  const ThemeSwitch({
    super.key,
    this.showLabel = true,
    this.showIcon = true,
    this.isExpanded = false,
    this.padding,
    this.textStyle,
    this.iconColor,
    this.backgroundColor,
    this.borderRadius,
    this.onChanged,
  });
  final bool showLabel;
  final bool showIcon;
  final bool isExpanded;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Color? iconColor;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text('Тема', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
        ],
        Container(
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).cardColor,
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: isExpanded
              ? DropdownButtonHideUnderline(
                  child: DropdownButton<ThemeMode>(
                    value: themeMode,
                    isExpanded: true,
                    items: _buildThemeItems(context),
                    onChanged: (mode) {
                      if (mode != null) {
                        _setThemeMode(ref, mode);
                        onChanged?.call();
                      }
                    },
                    style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
                    icon: Icon(Icons.arrow_drop_down,
                        color: Theme.of(context).iconTheme.color,),
                  ),
                )
              : InkWell(
                  onTap: () => _showThemeDialog(context, ref),
                  borderRadius: borderRadius ?? BorderRadius.circular(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showIcon) ...[
                        _buildThemeIcon(themeMode),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _getThemeName(themeMode),
                        style:
                            textStyle ?? Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).iconTheme.color,
                        size: 20,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<ThemeMode>> _buildThemeItems(BuildContext context) => [
        DropdownMenuItem(
            value: ThemeMode.light, child: _buildThemeItem(ThemeMode.light),),
        DropdownMenuItem(
            value: ThemeMode.dark, child: _buildThemeItem(ThemeMode.dark),),
        DropdownMenuItem(
            value: ThemeMode.system, child: _buildThemeItem(ThemeMode.system),),
      ];

  Widget _buildThemeItem(ThemeMode themeMode) => Row(
        children: [
          _buildThemeIcon(themeMode),
          const SizedBox(width: 12),
          Text(_getThemeName(themeMode), style: const TextStyle(fontSize: 16)),
        ],
      );

  Widget _buildThemeIcon(ThemeMode themeMode) {
    IconData icon;
    switch (themeMode) {
      case ThemeMode.light:
        icon = Icons.light_mode;
      case ThemeMode.dark:
        icon = Icons.dark_mode;
      case ThemeMode.system:
        icon = Icons.brightness_auto;
    }

    return Icon(icon, size: 20, color: Colors.grey[600]);
  }

  String _getThemeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Светлая';
      case ThemeMode.dark:
        return 'Темная';
      case ThemeMode.system:
        return 'Системная';
    }
  }

  void _setThemeMode(WidgetRef ref, ThemeMode themeMode) {
    final notifier = ref.read(themeProvider.notifier);
    switch (themeMode) {
      case ThemeMode.light:
        notifier.setLightTheme();
      case ThemeMode.dark:
        notifier.setDarkTheme();
      case ThemeMode.system:
        notifier.setSystemTheme();
    }

    // Логируем изменение темы
    AnalyticsService.logChangeTheme(themeMode.name);
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Выберите тему'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              dialogContext,
              ref,
              ThemeMode.light,
              Icons.light_mode,
              'Светлая',
              'Использовать светлую тему',
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              dialogContext,
              ref,
              ThemeMode.dark,
              Icons.dark_mode,
              'Темная',
              'Использовать темную тему',
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              dialogContext,
              ref,
              ThemeMode.system,
              Icons.brightness_auto,
              'Системная',
              'Следовать системным настройкам',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    ThemeMode themeMode,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final currentThemeMode = ref.watch(themeProvider);
    final isSelected = currentThemeMode == themeMode;

    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      selected: isSelected,
      onTap: () {
        _setThemeMode(ref, themeMode);
        Navigator.of(context).pop();
        onChanged?.call();
      },
    );
  }
}

/// Компактный виджет для переключения темы
class CompactThemeSwitch extends ConsumerWidget {
  const CompactThemeSwitch({
    super.key,
    this.showIcon = true,
    this.showText = false,
    this.iconColor,
    this.onChanged,
  });
  final bool showIcon;
  final bool showText;
  final Color? iconColor;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return IconButton(
      onPressed: () => _showThemeDialog(context, ref),
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            _buildThemeIcon(themeMode),
            if (showText) const SizedBox(width: 4),
          ],
          if (showText) ...[
            Text(
              _getThemeCode(themeMode),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
      tooltip: 'Переключить тему',
    );
  }

  Widget _buildThemeIcon(ThemeMode themeMode) {
    IconData icon;
    switch (themeMode) {
      case ThemeMode.light:
        icon = Icons.light_mode;
      case ThemeMode.dark:
        icon = Icons.dark_mode;
      case ThemeMode.system:
        icon = Icons.brightness_auto;
    }

    return Icon(icon, size: 20, color: iconColor ?? Colors.grey[600]);
  }

  String _getThemeCode(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'L';
      case ThemeMode.dark:
        return 'D';
      case ThemeMode.system:
        return 'A';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Выберите тему'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(dialogContext, ref, ThemeMode.light,
                Icons.light_mode, 'Светлая',),
            const SizedBox(height: 8),
            _buildThemeOption(
                dialogContext, ref, ThemeMode.dark, Icons.dark_mode, 'Темная',),
            const SizedBox(height: 8),
            _buildThemeOption(
              dialogContext,
              ref,
              ThemeMode.system,
              Icons.brightness_auto,
              'Системная',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    ThemeMode themeMode,
    IconData icon,
    String title,
  ) {
    final currentThemeMode = ref.watch(themeProvider);
    final isSelected = currentThemeMode == themeMode;

    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(title),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      selected: isSelected,
      onTap: () {
        final notifier = ref.read(themeProvider.notifier);
        switch (themeMode) {
          case ThemeMode.light:
            notifier.setLightTheme();
          case ThemeMode.dark:
            notifier.setDarkTheme();
          case ThemeMode.system:
            notifier.setSystemTheme();
        }
        Navigator.of(context).pop();
        onChanged?.call();
      },
    );
  }
}

/// Виджет для отображения текущей темы
class CurrentThemeDisplay extends ConsumerWidget {
  const CurrentThemeDisplay({
    super.key,
    this.showIcon = true,
    this.showName = true,
    this.showCode = false,
    this.textStyle,
    this.iconColor,
  });
  final bool showIcon;
  final bool showName;
  final bool showCode;
  final TextStyle? textStyle;
  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[_buildThemeIcon(themeMode), const SizedBox(width: 8)],
        if (showName || showCode) ...[
          Text(
            _getThemeDisplay(themeMode),
            style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  Widget _buildThemeIcon(ThemeMode themeMode) {
    IconData icon;
    switch (themeMode) {
      case ThemeMode.light:
        icon = Icons.light_mode;
      case ThemeMode.dark:
        icon = Icons.dark_mode;
      case ThemeMode.system:
        icon = Icons.brightness_auto;
    }

    return Icon(icon, size: 20, color: Colors.grey[600]);
  }

  String _getThemeDisplay(ThemeMode themeMode) {
    if (showCode) {
      switch (themeMode) {
        case ThemeMode.light:
          return 'L';
        case ThemeMode.dark:
          return 'D';
        case ThemeMode.system:
          return 'A';
      }
    }

    switch (themeMode) {
      case ThemeMode.light:
        return 'Светлая';
      case ThemeMode.dark:
        return 'Темная';
      case ThemeMode.system:
        return 'Системная';
    }
  }
}

/// Виджет для быстрого переключения между светлой и темной темой
class QuickThemeToggle extends ConsumerWidget {
  const QuickThemeToggle(
      {super.key, this.showTooltip = true, this.iconColor, this.onChanged,});
  final bool showTooltip;
  final Color? iconColor;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return IconButton(
      onPressed: () {
        ref.read(themeProvider.notifier).toggleTheme();
        onChanged?.call();
      },
      icon: Icon(
        isDark ? Icons.light_mode : Icons.dark_mode,
        color: Theme.of(context).iconTheme.color,
      ),
      tooltip: showTooltip
          ? (isDark
              ? 'Переключить на светлую тему'
              : 'Переключить на темную тему')
          : null,
    );
  }
}
