import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';

/// Виджет для переключения языка
class LanguageSwitchWidget extends ConsumerWidget {
  const LanguageSwitchWidget({
    super.key,
    this.showLabel = true,
    this.compact = false,
  });

  final bool showLabel;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);

    if (compact) {
      return _buildCompactSwitch(context, currentLocale, localeNotifier);
    }

    return _buildFullSwitch(context, currentLocale, localeNotifier);
  }

  Widget _buildCompactSwitch(
    BuildContext context,
    Locale currentLocale,
    LocaleNotifier localeNotifier,
  ) =>
      PopupMenuButton<Locale>(
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localeNotifier.getLocaleFlag(currentLocale),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 4),
            Text(
              localeNotifier.getLocaleName(currentLocale),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        onSelected: (locale) {
          switch (locale.languageCode) {
            case 'ru':
              localeNotifier.setRussian();
              break;
            case 'en':
              localeNotifier.setEnglish();
              break;
            case 'kk':
              localeNotifier.setKazakh();
              break;
          }
        },
        itemBuilder: (context) => localeNotifier.supportedLocales
            .map(
              (locale) => PopupMenuItem<Locale>(
                value: locale,
                child: Row(
                  children: [
                    Text(
                      localeNotifier.getLocaleFlag(locale),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(localeNotifier.getLocaleName(locale)),
                    if (locale == currentLocale) ...[
                      const Spacer(),
                      Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
            )
            .toList(),
      );

  Widget _buildFullSwitch(
    BuildContext context,
    Locale currentLocale,
    LocaleNotifier localeNotifier,
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
                    Icons.language,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Язык',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (showLabel) ...[
                Text(
                  'Выберите язык интерфейса',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
              ],
              ...localeNotifier.supportedLocales.map((locale) {
                final isSelected = locale == currentLocale;
                return ListTile(
                  leading: Text(
                    localeNotifier.getLocaleFlag(locale),
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(localeNotifier.getLocaleName(locale)),
                  trailing: isSelected
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  selected: isSelected,
                  onTap: () {
                    switch (locale.languageCode) {
                      case 'ru':
                        localeNotifier.setRussian();
                        break;
                      case 'en':
                        localeNotifier.setEnglish();
                        break;
                      case 'kk':
                        localeNotifier.setKazakh();
                        break;
                    }
                  },
                );
              }),
            ],
          ),
        ),
      );
}

/// Простой переключатель языка для AppBar
class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);

    return IconButton(
      onPressed: localeNotifier.toggleLocale,
      icon: Text(
        localeNotifier.getLocaleFlag(currentLocale),
        style: const TextStyle(fontSize: 20),
      ),
      tooltip: 'Переключить язык',
    );
  }
}

/// Виджет для отображения текущего языка
class LanguageIndicator extends ConsumerWidget {
  const LanguageIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final localeNotifier = ref.read(localeProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            localeNotifier.getLocaleFlag(currentLocale),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 4),
          Text(
            localeNotifier.getLocaleName(currentLocale),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}
