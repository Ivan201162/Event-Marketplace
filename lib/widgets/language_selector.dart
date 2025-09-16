import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_providers.dart';
import '../generated/l10n/app_localizations.dart';

/// Виджет для выбора языка
class LanguageSelector extends ConsumerWidget {
  final bool showAsDialog;
  final bool showAsDropdown;
  final EdgeInsets? padding;
  final TextStyle? textStyle;
  final Color? iconColor;

  const LanguageSelector({
    super.key,
    this.showAsDialog = false,
    this.showAsDropdown = false,
    this.padding,
    this.textStyle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final languageName = ref.watch(languageNameProvider);
    final l10n = ref.watch(localizedStringsProvider);

    if (showAsDialog) {
      return _buildDialogButton(context, ref, languageName, l10n);
    } else if (showAsDropdown) {
      return _buildDropdown(context, ref, currentLocale, l10n);
    } else {
      return _buildListTile(context, ref, languageName, l10n);
    }
  }

  Widget _buildDialogButton(BuildContext context, WidgetRef ref, String languageName, AppLocalizations l10n) {
    return ListTile(
      leading: Icon(
        Icons.language,
        color: iconColor ?? Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        l10n.language,
        style: textStyle ?? Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        languageName,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => _showLanguageDialog(context, ref, l10n),
    );
  }

  Widget _buildDropdown(BuildContext context, WidgetRef ref, Locale currentLocale, AppLocalizations l10n) {
    final languageList = ref.watch(languageListProvider);

    return DropdownButton<Locale>(
      value: currentLocale,
      items: languageList.map((language) {
        return DropdownMenuItem<Locale>(
          value: Locale(language['code']!, ''),
          child: Text(language['name']!),
        );
      }).toList(),
      onChanged: (Locale? newLocale) {
        if (newLocale != null) {
          ref.read(localeProvider.notifier).setLocale(newLocale);
        }
      },
      underline: Container(),
      icon: Icon(
        Icons.arrow_drop_down,
        color: iconColor ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildListTile(BuildContext context, WidgetRef ref, String languageName, AppLocalizations l10n) {
    return ListTile(
      leading: Icon(
        Icons.language,
        color: iconColor ?? Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        l10n.language,
        style: textStyle ?? Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        languageName,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => _showLanguageDialog(context, ref, l10n),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => LanguageDialog(l10n: l10n),
    );
  }
}

/// Диалог выбора языка
class LanguageDialog extends ConsumerWidget {
  final AppLocalizations l10n;

  const LanguageDialog({
    super.key,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final languageList = ref.watch(languageListProvider);

    return AlertDialog(
      title: Text(l10n.language),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: languageList.map((language) {
          final locale = Locale(language['code']!, '');
          final isSelected = locale.languageCode == currentLocale.languageCode;

          return RadioListTile<Locale>(
            title: Text(language['name']!),
            value: locale,
            groupValue: currentLocale,
            onChanged: (Locale? value) {
              if (value != null) {
                ref.read(localeProvider.notifier).setLocale(value);
                Navigator.of(context).pop();
              }
            },
            activeColor: Theme.of(context).colorScheme.primary,
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

/// Компактный селектор языка
class CompactLanguageSelector extends ConsumerWidget {
  final bool showIcon;
  final bool showText;
  final double? iconSize;
  final TextStyle? textStyle;

  const CompactLanguageSelector({
    super.key,
    this.showIcon = true,
    this.showText = true,
    this.iconSize,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final languageName = ref.watch(languageNameProvider);

    return GestureDetector(
      onTap: () => _toggleLanguage(ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                Icons.language,
                size: iconSize ?? 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
            ],
            if (showText)
              Text(
                languageName,
                style: textStyle ?? Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  void _toggleLanguage(WidgetRef ref) {
    ref.read(localeProvider.notifier).toggleLanguage();
  }
}

/// Виджет для отображения текущего языка
class CurrentLanguageDisplay extends ConsumerWidget {
  final bool showIcon;
  final TextStyle? textStyle;
  final Color? iconColor;

  const CurrentLanguageDisplay({
    super.key,
    this.showIcon = true,
    this.textStyle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageName = ref.watch(languageNameProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(
            Icons.language,
            size: 16,
            color: iconColor ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          languageName,
          style: textStyle ?? Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

/// Виджет для быстрого переключения языка
class QuickLanguageToggle extends ConsumerWidget {
  final bool showIcon;
  final bool showText;
  final double? iconSize;
  final TextStyle? textStyle;

  const QuickLanguageToggle({
    super.key,
    this.showIcon = true,
    this.showText = true,
    this.iconSize,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isRussian = ref.watch(isRussianProvider);

    return IconButton(
      onPressed: () => _toggleLanguage(ref),
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.language,
              size: iconSize ?? 20,
            ),
            const SizedBox(width: 4),
          ],
          if (showText)
            Text(
              isRussian ? 'EN' : 'RU',
              style: textStyle ?? Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      tooltip: isRussian ? 'Switch to English' : 'Переключить на русский',
    );
  }

  void _toggleLanguage(WidgetRef ref) {
    ref.read(localeProvider.notifier).toggleLanguage();
  }
}
