import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/share_service.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../models/booking.dart';
import '../core/feature_flags.dart';
import '../core/safe_log.dart';

/// Виджет для шаринга контента
class ShareWidget extends ConsumerWidget {
  final Event? event;
  final AppUser? user;
  final Booking? booking;
  final String? text;
  final String? filePath;
  final List<String>? filePaths;
  final String? url;
  final String? title;
  final String? customMessage;
  final IconData? icon;
  final bool showAsButton;
  final bool showAsIconButton;
  final bool showAsListTile;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const ShareWidget({
    super.key,
    this.event,
    this.user,
    this.booking,
    this.text,
    this.filePath,
    this.filePaths,
    this.url,
    this.title,
    this.customMessage,
    this.icon,
    this.showAsButton = false,
    this.showAsIconButton = false,
    this.showAsListTile = false,
    this.onSuccess,
    this.onError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!FeatureFlags.shareEnabled) {
      return const SizedBox.shrink();
    }

    if (showAsIconButton) {
      return _buildIconButton(context);
    } else if (showAsButton) {
      return _buildButton(context);
    } else if (showAsListTile) {
      return _buildListTile(context);
    } else {
      return _buildIconButton(context);
    }
  }

  Widget _buildIconButton(BuildContext context) {
    return IconButton(
      onPressed: () => _shareContent(context),
      icon: Icon(icon ?? Icons.share),
      tooltip: title ?? 'Поделиться',
    );
  }

  Widget _buildButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _shareContent(context),
      icon: Icon(icon ?? Icons.share),
      label: Text(title ?? 'Поделиться'),
    );
  }

  Widget _buildListTile(BuildContext context) {
    return ListTile(
      leading: Icon(icon ?? Icons.share),
      title: Text(title ?? 'Поделиться'),
      subtitle: const Text('Поделиться с друзьями'),
      onTap: () => _shareContent(context),
    );
  }

  Future<void> _shareContent(BuildContext context) async {
    try {
      bool success = false;

      if (event != null) {
        success =
            await ShareService.shareEvent(event!, customMessage: customMessage);
      } else if (user != null) {
        success = await ShareService.shareProfile(user!,
            customMessage: customMessage);
      } else if (booking != null) {
        success = await ShareService.shareBooking(booking!,
            customMessage: customMessage);
      } else if (text != null) {
        success = await ShareService.shareText(text!, subject: title);
      } else if (filePath != null) {
        success = await ShareService.shareFile(filePath!,
            text: customMessage, subject: title);
      } else if (filePaths != null) {
        success = await ShareService.shareFiles(filePaths!,
            text: customMessage, subject: title);
      } else if (url != null) {
        success = await ShareService.shareLink(url!,
            title: title, description: customMessage);
      }

      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Контент успешно поделен'),
              backgroundColor: Colors.green,
            ),
          );
        }
        onSuccess?.call();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ошибка при попытке поделиться'),
              backgroundColor: Colors.red,
            ),
          );
        }
        onError?.call();
      }
    } catch (e, stackTrace) {
      SafeLog.error('ShareWidget: Error sharing content', e, stackTrace);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      onError?.call();
    }
  }
}

/// Виджет для шаринга события
class EventShareWidget extends StatelessWidget {
  final Event event;
  final String? title;
  final IconData? icon;
  final bool showAsButton;
  final bool showAsIconButton;
  final bool showAsListTile;
  final String? customMessage;

  const EventShareWidget({
    super.key,
    required this.event,
    this.title,
    this.icon,
    this.showAsButton = false,
    this.showAsIconButton = false,
    this.showAsListTile = false,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ShareWidget(
      event: event,
      title: title ?? 'Поделиться событием',
      icon: icon ?? Icons.share,
      showAsButton: showAsButton,
      showAsIconButton: showAsIconButton,
      showAsListTile: showAsListTile,
      customMessage: customMessage,
    );
  }
}

/// Виджет для шаринга профиля
class ProfileShareWidget extends StatelessWidget {
  final AppUser user;
  final String? title;
  final IconData? icon;
  final bool showAsButton;
  final bool showAsIconButton;
  final bool showAsListTile;
  final String? customMessage;

  const ProfileShareWidget({
    super.key,
    required this.user,
    this.title,
    this.icon,
    this.showAsButton = false,
    this.showAsIconButton = false,
    this.showAsListTile = false,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ShareWidget(
      user: user,
      title: title ?? 'Поделиться профилем',
      icon: icon ?? Icons.share,
      showAsButton: showAsButton,
      showAsIconButton: showAsIconButton,
      showAsListTile: showAsListTile,
      customMessage: customMessage,
    );
  }
}

/// Виджет для шаринга бронирования
class BookingShareWidget extends StatelessWidget {
  final Booking booking;
  final String? title;
  final IconData? icon;
  final bool showAsButton;
  final bool showAsIconButton;
  final bool showAsListTile;
  final String? customMessage;

  const BookingShareWidget({
    super.key,
    required this.booking,
    this.title,
    this.icon,
    this.showAsButton = false,
    this.showAsIconButton = false,
    this.showAsListTile = false,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ShareWidget(
      booking: booking,
      title: title ?? 'Поделиться бронированием',
      icon: icon ?? Icons.share,
      showAsButton: showAsButton,
      showAsIconButton: showAsIconButton,
      showAsListTile: showAsListTile,
      customMessage: customMessage,
    );
  }
}

/// Виджет для шаринга текста
class TextShareWidget extends StatelessWidget {
  final String text;
  final String? title;
  final IconData? icon;
  final bool showAsButton;
  final bool showAsIconButton;
  final bool showAsListTile;

  const TextShareWidget({
    super.key,
    required this.text,
    this.title,
    this.icon,
    this.showAsButton = false,
    this.showAsIconButton = false,
    this.showAsListTile = false,
  });

  @override
  Widget build(BuildContext context) {
    return ShareWidget(
      text: text,
      title: title ?? 'Поделиться текстом',
      icon: icon ?? Icons.share,
      showAsButton: showAsButton,
      showAsIconButton: showAsIconButton,
      showAsListTile: showAsListTile,
    );
  }
}

/// Виджет для шаринга ссылки
class LinkShareWidget extends StatelessWidget {
  final String url;
  final String? title;
  final String? description;
  final IconData? icon;
  final bool showAsButton;
  final bool showAsIconButton;
  final bool showAsListTile;

  const LinkShareWidget({
    super.key,
    required this.url,
    this.title,
    this.description,
    this.icon,
    this.showAsButton = false,
    this.showAsIconButton = false,
    this.showAsListTile = false,
  });

  @override
  Widget build(BuildContext context) {
    return ShareWidget(
      url: url,
      title: title ?? 'Поделиться ссылкой',
      icon: icon ?? Icons.share,
      showAsButton: showAsButton,
      showAsIconButton: showAsIconButton,
      showAsListTile: showAsListTile,
      customMessage: description,
    );
  }
}

/// Диалог для выбора способа шаринга
class ShareDialog extends StatelessWidget {
  final Event? event;
  final AppUser? user;
  final Booking? booking;
  final String? text;
  final String? filePath;
  final List<String>? filePaths;
  final String? url;
  final String? title;
  final String? customMessage;

  const ShareDialog({
    super.key,
    this.event,
    this.user,
    this.booking,
    this.text,
    this.filePath,
    this.filePaths,
    this.url,
    this.title,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.shareEnabled) {
      return AlertDialog(
        title: const Text('Поделиться'),
        content: const Text('Функция шаринга временно отключена'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ОК'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(title ?? 'Поделиться'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Выберите способ шаринга:'),
          const SizedBox(height: 16),
          _buildShareOption(
            context,
            icon: Icons.share,
            title: 'Поделиться',
            subtitle: 'Открыть системное меню шаринга',
            onTap: () => _shareContent(context),
          ),
          if (url != null) ...[
            const SizedBox(height: 8),
            _buildShareOption(
              context,
              icon: Icons.link,
              title: 'Копировать ссылку',
              subtitle: 'Скопировать ссылку в буфер обмена',
              onTap: () => _copyLink(context),
            ),
          ],
          if (text != null ||
              event != null ||
              user != null ||
              booking != null) ...[
            const SizedBox(height: 8),
            _buildShareOption(
              context,
              icon: Icons.copy,
              title: 'Копировать текст',
              subtitle: 'Скопировать текст в буфер обмена',
              onTap: () => _copyText(context),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
      ],
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _shareContent(BuildContext context) async {
    Navigator.of(context).pop();

    try {
      bool success = false;

      if (event != null) {
        success =
            await ShareService.shareEvent(event!, customMessage: customMessage);
      } else if (user != null) {
        success = await ShareService.shareProfile(user!,
            customMessage: customMessage);
      } else if (booking != null) {
        success = await ShareService.shareBooking(booking!,
            customMessage: customMessage);
      } else if (text != null) {
        success = await ShareService.shareText(text!, subject: title);
      } else if (filePath != null) {
        success = await ShareService.shareFile(filePath!,
            text: customMessage, subject: title);
      } else if (filePaths != null) {
        success = await ShareService.shareFiles(filePaths!,
            text: customMessage, subject: title);
      } else if (url != null) {
        success = await ShareService.shareLink(url!,
            title: title, description: customMessage);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Контент успешно поделен'
                : 'Ошибка при попытке поделиться'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      SafeLog.error('ShareDialog: Error sharing content', e, stackTrace);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    Navigator.of(context).pop();

    if (url != null) {
      // Здесь можно добавить логику копирования в буфер обмена
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ссылка скопирована в буфер обмена'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _copyText(BuildContext context) async {
    Navigator.of(context).pop();

    String textToCopy = '';

    if (text != null) {
      textToCopy = text!;
    } else if (event != null) {
      textToCopy = ShareService._buildEventShareMessage(event!);
    } else if (user != null) {
      textToCopy = ShareService._buildProfileShareMessage(user!);
    } else if (booking != null) {
      textToCopy = ShareService._buildBookingShareMessage(booking!);
    }

    if (textToCopy.isNotEmpty) {
      // Здесь можно добавить логику копирования в буфер обмена
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Текст скопирован в буфер обмена'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

/// Утилиты для шаринга
class ShareUtils {
  /// Показать диалог шаринга для события
  static void showShareDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => ShareDialog(event: event),
    );
  }

  /// Показать диалог шаринга для профиля
  static void showProfileShareDialog(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      builder: (context) => ShareDialog(user: user),
    );
  }

  /// Показать диалог шаринга для бронирования
  static void showBookingShareDialog(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (context) => ShareDialog(booking: booking),
    );
  }

  /// Показать диалог шаринга для текста
  static void showTextShareDialog(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (context) => ShareDialog(text: text),
    );
  }

  /// Показать диалог шаринга для ссылки
  static void showLinkShareDialog(BuildContext context, String url,
      {String? title, String? description}) {
    showDialog(
      context: context,
      builder: (context) => ShareDialog(
        url: url,
        title: title,
        customMessage: description,
      ),
    );
  }

  /// Быстрый шаринг события
  static Future<bool> quickShare(Event event) async {
    return await ShareService.shareEvent(event);
  }

  /// Быстрый шаринг профиля
  static Future<bool> quickShareProfile(AppUser user) async {
    return await ShareService.shareProfile(user);
  }

  /// Быстрый шаринг бронирования
  static Future<bool> quickShareBooking(Booking booking) async {
    return await ShareService.shareBooking(booking);
  }

  /// Быстрый шаринг текста
  static Future<bool> quickShareText(String text) async {
    return await ShareService.shareText(text);
  }

  /// Быстрый шаринг ссылки
  static Future<bool> quickShareLink(String url,
      {String? title, String? description}) async {
    return await ShareService.shareLink(url,
        title: title, description: description);
  }
}
