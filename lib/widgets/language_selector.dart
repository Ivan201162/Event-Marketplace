import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/app_localizations.dart';
import '../providers/locale_provider.dart';

/// Виджет для выбора языка
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({
    super.key,
    this.showLabel = true,
    this.showFlag = true,
    this.showNativeName = true,
    this.showEnglishName = false,
    this.showCode = false,
    this.isExpanded = false,
    this.padding,
    this.textStyle,
    this.iconColor,
    this.backgroundColor,
    this.borderRadius,
    this.onChanged,
  });
  final bool showLabel;
  final bool showFlag;
  final bool showNativeName;
  final bool showEnglishName;
  final bool showCode;
  final bool isExpanded;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Color? iconColor;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(l10n.language, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
        ],
        Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).cardColor,
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: isExpanded
              ? DropdownButtonHideUnderline(
                  child: DropdownButton<Locale>(
                    value: currentLocale,
                    isExpanded: true,
                    items: _buildLanguageItems(context),
                    onChanged: (locale) {
                      if (locale != null) {
                        ref.read(localeProvider.notifier).setLocale(locale);
                        onChanged?.call();
                      }
                    },
                    style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: iconColor ?? Theme.of(context).iconTheme.color,
                    ),
                  ),
                )
              : InkWell(
                  onTap: () => _showLanguageDialog(context, ref),
                  borderRadius: borderRadius ?? BorderRadius.circular(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showFlag) ...[_buildFlag(currentLocale), const SizedBox(width: 8)],
                      Text(
                        _getLanguageName(currentLocale, showNativeName, showEnglishName, showCode),
                        style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: iconColor ?? Theme.of(context).iconTheme.color,
                        size: 20,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<Locale>> _buildLanguageItems(BuildContext context) => [
        DropdownMenuItem(
          value: const Locale('ru', 'RU'),
          child: _buildLanguageItem(const Locale('ru', 'RU')),
        ),
        DropdownMenuItem(
          value: const Locale('en', 'US'),
          child: _buildLanguageItem(const Locale('en', 'US')),
        ),
      ];

  Widget _buildLanguageItem(Locale locale) => Row(
        children: [
          if (showFlag) ...[_buildFlag(locale), const SizedBox(width: 12)],
          Text(
            _getLanguageName(locale, showNativeName, showEnglishName, showCode),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      );

  Widget _buildFlag(Locale locale) {
    String flagEmoji;
    switch (locale.languageCode) {
      case 'ru':
        flagEmoji = '🇷🇺';
        break;
      case 'en':
        flagEmoji = '🇺🇸';
        break;
      default:
        flagEmoji = '🌐';
    }

    return Text(flagEmoji, style: const TextStyle(fontSize: 20));
  }

  String _getLanguageName(Locale locale, bool showNative, bool showEnglish, bool showCode) {
    if (showCode) {
      return locale.languageCode.toUpperCase();
    }

    switch (locale.languageCode) {
      case 'ru':
        if (showNative) return 'Русский';
        if (showEnglish) return 'Russian';
        return 'Русский';
      case 'en':
        if (showNative) return 'English';
        if (showEnglish) return 'English';
        return 'English';
      default:
        return locale.languageCode.toUpperCase();
    }
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              context,
              ref,
              const Locale('ru', 'RU'),
              '🇷🇺',
              'Русский',
              'Russian',
            ),
            const SizedBox(height: 8),
            _buildLanguageOption(
              context,
              ref,
              const Locale('en', 'US'),
              '🇺🇸',
              'English',
              'English',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref,
    Locale locale,
    String flag,
    String nativeName,
    String englishName,
  ) {
    final currentLocale = ref.watch(localeProvider);
    final isSelected = currentLocale == locale;

    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(nativeName),
      subtitle: Text(englishName),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      selected: isSelected,
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(locale);
        Navigator.of(context).pop();
        onChanged?.call();
      },
    );
  }
}

/// Компактный виджет для выбора языка
class CompactLanguageSelector extends ConsumerWidget {
  const CompactLanguageSelector({
    super.key,
    this.showFlag = true,
    this.showText = false,
    this.iconColor,
    this.onChanged,
  });
  final bool showFlag;
  final bool showText;
  final Color? iconColor;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return IconButton(
      onPressed: () => _showLanguageDialog(context, ref),
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showFlag) ...[_buildFlag(currentLocale), if (showText) const SizedBox(width: 4)],
          if (showText) ...[
            Text(
              _getLanguageCode(currentLocale),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
      tooltip: AppLocalizations.of(context).language,
    );
  }

  Widget _buildFlag(Locale locale) {
    String flagEmoji;
    switch (locale.languageCode) {
      case 'ru':
        flagEmoji = '🇷🇺';
        break;
      case 'en':
        flagEmoji = '🇺🇸';
        break;
      default:
        flagEmoji = '🌐';
    }

    return Text(flagEmoji, style: const TextStyle(fontSize: 16));
  }

  String _getLanguageCode(Locale locale) => locale.languageCode.toUpperCase();

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(context, ref, const Locale('ru', 'RU'), '🇷🇺', 'Русский'),
            const SizedBox(height: 8),
            _buildLanguageOption(context, ref, const Locale('en', 'US'), '🇺🇸', 'English'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref,
    Locale locale,
    String flag,
    String name,
  ) {
    final currentLocale = ref.watch(localeProvider);
    final isSelected = currentLocale == locale;

    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      selected: isSelected,
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(locale);
        Navigator.of(context).pop();
        onChanged?.call();
      },
    );
  }
}

/// Виджет для отображения текущего языка
class CurrentLanguageDisplay extends ConsumerWidget {
  const CurrentLanguageDisplay({
    super.key,
    this.showFlag = true,
    this.showName = true,
    this.showCode = false,
    this.textStyle,
    this.iconColor,
  });
  final bool showFlag;
  final bool showName;
  final bool showCode;
  final TextStyle? textStyle;
  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showFlag) ...[_buildFlag(currentLocale), const SizedBox(width: 8)],
        if (showName || showCode) ...[
          Text(
            _getLanguageDisplay(currentLocale),
            style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  Widget _buildFlag(Locale locale) {
    String flagEmoji;
    switch (locale.languageCode) {
      case 'ru':
        flagEmoji = '🇷🇺';
        break;
      case 'en':
        flagEmoji = '🇺🇸';
        break;
      default:
        flagEmoji = '🌐';
    }

    return Text(flagEmoji, style: const TextStyle(fontSize: 20));
  }

  String _getLanguageDisplay(Locale locale) {
    if (showCode) {
      return locale.languageCode.toUpperCase();
    }

    switch (locale.languageCode) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return locale.languageCode.toUpperCase();
    }
  }
}
