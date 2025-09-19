import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

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
          Text(
            'Тема',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).cardColor,
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: isExpanded
              ? DropdownButtonHideUnderline(
                  child: DropdownButton<AppThemeMode>(
                    value: themeMode,
                    isExpanded: true,
                    items: _buildThemeItems(context),
                    onChanged: (mode) {
                      if (mode != null) {
                        _setAppThemeMode(ref, mode);
                        onChanged?.call();
                      }
                    },
                    style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).iconTheme.color,
                    ),
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

  List<DropdownMenuItem<AppThemeMode>> _buildThemeItems(BuildContext context) =>
      [
        DropdownMenuItem(
          value: AppThemeMode.light,
          child: _buildThemeItem(AppThemeMode.light),
        ),
        DropdownMenuItem(
          value: AppThemeMode.dark,
          child: _buildThemeItem(AppThemeMode.dark),
        ),
        DropdownMenuItem(
          value: AppThemeMode.system,
          child: _buildThemeItem(AppThemeMode.system),
        ),
      ];

  Widget _buildThemeItem(AppThemeMode themeMode) => Row(
        children: [
          _buildThemeIcon(themeMode),
          const SizedBox(width: 12),
          Text(
            _getThemeName(themeMode),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      );

  Widget _buildThemeIcon(AppThemeMode themeMode) {
    IconData icon;
    switch (themeMode) {
      case AppThemeMode.light:
        icon = Icons.light_mode;
        break;
      case AppThemeMode.dark:
        icon = Icons.dark_mode;
        break;
      case AppThemeMode.system:
        icon = Icons.brightness_auto;
        break;
    }

    return Icon(
      icon,
      size: 20,
      color: Colors.grey[600],
    );
  }

  String _getThemeName(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.light:
        return 'Светлая';
      case AppThemeMode.dark:
        return 'Темная';
      case AppThemeMode.system:
        return 'Системная';
    }
  }

  void _setAppThemeMode(WidgetRef ref, AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.light:
        ref.read(themeProvider.notifier).setLightTheme();
        break;
      case AppThemeMode.dark:
        ref.read(themeProvider.notifier).setDarkTheme();
        break;
      case AppThemeMode.system:
        ref.read(themeProvider.notifier).setSystemTheme();
        break;
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Выберите тему'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              dialogContext,
              ref,
              AppThemeMode.light,
              Icons.light_mode,
              'Светлая',
              'Использовать светлую тему',
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              dialogContext,
              ref,
              AppThemeMode.dark,
              Icons.dark_mode,
              'Темная',
              'Использовать темную тему',
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              dialogContext,
              ref,
              AppThemeMode.system,
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
    AppThemeMode AppThemeMode,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final currentAppThemeMode = ref.watch(themeProvider);
    final isSelected = currentAppThemeMode == AppThemeMode;

    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      selected: isSelected,
      onTap: () {
        _setAppThemeMode(ref, AppThemeMode);
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

  Widget _buildThemeIcon(AppThemeMode themeMode) {
    IconData icon;
    switch (themeMode) {
      case AppThemeMode.light:
        icon = Icons.light_mode;
        break;
      case AppThemeMode.dark:
        icon = Icons.dark_mode;
        break;
      case AppThemeMode.system:
        icon = Icons.brightness_auto;
        break;
    }

    return Icon(
      icon,
      size: 20,
      color: iconColor ?? Colors.grey[600],
    );
  }

  String _getThemeCode(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.light:
        return 'L';
      case AppThemeMode.dark:
        return 'D';
      case AppThemeMode.system:
        return 'A';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Выберите тему'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              dialogContext,
              ref,
              AppThemeMode.light,
              Icons.light_mode,
              'Светлая',
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              dialogContext,
              ref,
              AppThemeMode.dark,
              Icons.dark_mode,
              'Темная',
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              dialogContext,
              ref,
              AppThemeMode.system,
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
    AppThemeMode themeMode,
    IconData icon,
    String title,
  ) {
    final currentAppThemeMode = ref.watch(themeProvider);
    final isSelected = currentAppThemeMode == themeMode;

    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(title),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      selected: isSelected,
      onTap: () {
        switch (themeMode) {
          case AppThemeMode.light:
            ref.read(themeProvider.notifier).setLightTheme();
            break;
          case AppThemeMode.dark:
            ref.read(themeProvider.notifier).setDarkTheme();
            break;
          case AppThemeMode.system:
            ref.read(themeProvider.notifier).setSystemTheme();
            break;
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
        if (showIcon) ...[
          _buildThemeIcon(themeMode),
          const SizedBox(width: 8),
        ],
        if (showName || showCode) ...[
          Text(
            _getThemeDisplay(themeMode),
            style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  Widget _buildThemeIcon(AppThemeMode themeMode) {
    IconData icon;
    switch (themeMode) {
      case AppThemeMode.light:
        icon = Icons.light_mode;
        break;
      case AppThemeMode.dark:
        icon = Icons.dark_mode;
        break;
      case AppThemeMode.system:
        icon = Icons.brightness_auto;
        break;
    }

    return Icon(
      icon,
      size: 20,
      color: Colors.grey[600],
    );
  }

  String _getThemeDisplay(AppThemeMode themeMode) {
    if (showCode) {
      switch (themeMode) {
        case AppThemeMode.light:
          return 'L';
        case AppThemeMode.dark:
          return 'D';
        case AppThemeMode.system:
          return 'A';
      }
    }

    switch (themeMode) {
      case AppThemeMode.light:
        return 'Светлая';
      case AppThemeMode.dark:
        return 'Темная';
      case AppThemeMode.system:
        return 'Системная';
    }
  }
}

/// Виджет для быстрого переключения между светлой и темной темой
class QuickThemeToggle extends ConsumerWidget {
  const QuickThemeToggle({
    super.key,
    this.showTooltip = true,
    this.iconColor,
    this.onChanged,
  });
  final bool showTooltip;
  final Color? iconColor;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == AppThemeMode.dark;

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
