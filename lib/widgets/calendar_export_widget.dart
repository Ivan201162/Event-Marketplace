import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../calendar/ics_export.dart';
import '../models/event.dart';
import '../models/booking.dart';
import '../core/feature_flags.dart';
import '../core/safe_log.dart';

/// Виджет для экспорта календаря
class CalendarExportWidget extends ConsumerWidget {
  final Event? event;
  final Booking? booking;
  final List<Event>? events;
  final List<Booking>? bookings;
  final String? title;
  final IconData? icon;
  final bool showAsButton;
  final bool showAsIconButton;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const CalendarExportWidget({
    super.key,
    this.event,
    this.booking,
    this.events,
    this.bookings,
    this.title,
    this.icon,
    this.showAsButton = false,
    this.showAsIconButton = false,
    this.onSuccess,
    this.onError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!FeatureFlags.calendarExportEnabled) {
      return const SizedBox.shrink();
    }

    if (showAsIconButton) {
      return _buildIconButton(context);
    } else if (showAsButton) {
      return _buildButton(context);
    } else {
      return _buildListTile(context);
    }
  }

  Widget _buildIconButton(BuildContext context) {
    return IconButton(
      onPressed: () => _exportCalendar(context),
      icon: Icon(icon ?? Icons.calendar_today),
      tooltip: title ?? 'Экспорт в календарь',
    );
  }

  Widget _buildButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _exportCalendar(context),
      icon: Icon(icon ?? Icons.calendar_today),
      label: Text(title ?? 'Экспорт в календарь'),
    );
  }

  Widget _buildListTile(BuildContext context) {
    return ListTile(
      leading: Icon(icon ?? Icons.calendar_today),
      title: Text(title ?? 'Экспорт в календарь'),
      subtitle: const Text('Сохранить в календарное приложение'),
      onTap: () => _exportCalendar(context),
    );
  }

  Future<void> _exportCalendar(BuildContext context) async {
    try {
      bool success = false;

      if (event != null) {
        success = await IcsExportService.exportAndShareEvent(event!);
      } else if (booking != null) {
        success = await IcsExportService.exportAndShareBooking(booking!);
      } else if (events != null && events!.isNotEmpty) {
        success = await IcsExportService.exportAndShareEvents(events!);
      } else if (bookings != null && bookings!.isNotEmpty) {
        success = await IcsExportService.exportAndShareBookings(bookings!);
      }

      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Событие экспортировано в календарь'),
              backgroundColor: Colors.green,
            ),
          );
        }
        onSuccess?.call();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ошибка экспорта в календарь'),
              backgroundColor: Colors.red,
            ),
          );
        }
        onError?.call();
      }
    } catch (e, stackTrace) {
      SafeLog.error(
          'CalendarExportWidget: Error exporting calendar', e, stackTrace);

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

/// Виджет для экспорта одного события
class EventCalendarExportWidget extends StatelessWidget {
  final Event event;
  final String? title;
  final IconData? icon;
  final bool showAsButton;
  final bool showAsIconButton;

  const EventCalendarExportWidget({
    super.key,
    required this.event,
    this.title,
    this.icon,
    this.showAsButton = false,
    this.showAsIconButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return CalendarExportWidget(
      event: event,
      title: title ?? 'Экспорт события',
      icon: icon ?? Icons.calendar_today,
      showAsButton: showAsButton,
      showAsIconButton: showAsIconButton,
    );
  }
}

/// Виджет для экспорта одного бронирования
class BookingCalendarExportWidget extends StatelessWidget {
  final Booking booking;
  final String? title;
  final IconData? icon;
  final bool showAsButton;
  final bool showAsIconButton;

  const BookingCalendarExportWidget({
    super.key,
    required this.booking,
    this.title,
    this.icon,
    this.showAsButton = false,
    this.showAsIconButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return CalendarExportWidget(
      booking: booking,
      title: title ?? 'Экспорт бронирования',
      icon: icon ?? Icons.calendar_today,
      showAsButton: showAsButton,
      showAsIconButton: showAsIconButton,
    );
  }
}

/// Виджет для экспорта нескольких событий
class EventsCalendarExportWidget extends StatelessWidget {
  final List<Event> events;
  final String? title;
  final IconData? icon;
  final bool showAsButton;
  final bool showAsIconButton;

  const EventsCalendarExportWidget({
    super.key,
    required this.events,
    this.title,
    this.icon,
    this.showAsButton = false,
    this.showAsIconButton = false,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    return CalendarExportWidget(
      events: events,
      title: title ?? 'Экспорт событий (${events.length})',
      icon: icon ?? Icons.calendar_today,
      showAsButton: showAsButton,
      showAsIconButton: showAsIconButton,
    );
  }
}

/// Виджет для экспорта нескольких бронирований
class BookingsCalendarExportWidget extends StatelessWidget {
  final List<Booking> bookings;
  final String? title;
  final IconData? icon;
  final bool showAsButton;
  final bool showAsIconButton;

  const BookingsCalendarExportWidget({
    super.key,
    required this.bookings,
    this.title,
    this.icon,
    this.showAsButton = false,
    this.showAsIconButton = false,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const SizedBox.shrink();
    }

    return CalendarExportWidget(
      bookings: bookings,
      title: title ?? 'Экспорт бронирований (${bookings.length})',
      icon: icon ?? Icons.calendar_today,
      showAsButton: showAsButton,
      showAsIconButton: showAsIconButton,
    );
  }
}

/// Диалог для выбора типа экспорта
class CalendarExportDialog extends StatelessWidget {
  final Event? event;
  final Booking? booking;
  final List<Event>? events;
  final List<Booking>? bookings;

  const CalendarExportDialog({
    super.key,
    this.event,
    this.booking,
    this.events,
    this.bookings,
  });

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.calendarExportEnabled) {
      return AlertDialog(
        title: const Text('Экспорт календаря'),
        content: const Text('Экспорт календаря временно отключен'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ОК'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Экспорт в календарь'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Выберите формат экспорта:'),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('iCalendar (.ics)'),
            subtitle:
                const Text('Совместим с большинством календарных приложений'),
            onTap: () => _exportIcs(context),
          ),
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

  Future<void> _exportIcs(BuildContext context) async {
    Navigator.of(context).pop();

    try {
      bool success = false;

      if (event != null) {
        success = await IcsExportService.exportAndShareEvent(event!);
      } else if (booking != null) {
        success = await IcsExportService.exportAndShareBooking(booking!);
      } else if (events != null && events!.isNotEmpty) {
        success = await IcsExportService.exportAndShareEvents(events!);
      } else if (bookings != null && bookings!.isNotEmpty) {
        success = await IcsExportService.exportAndShareBookings(bookings!);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Событие экспортировано в календарь'
                : 'Ошибка экспорта в календарь'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      SafeLog.error(
          'CalendarExportDialog: Error exporting calendar', e, stackTrace);

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
}

/// Утилиты для экспорта календаря
class CalendarExportUtils {
  /// Показать диалог экспорта для события
  static void showExportDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => CalendarExportDialog(event: event),
    );
  }

  /// Показать диалог экспорта для бронирования
  static void showExportDialog(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (context) => CalendarExportDialog(booking: booking),
    );
  }

  /// Показать диалог экспорта для событий
  static void showExportDialog(BuildContext context, List<Event> events) {
    showDialog(
      context: context,
      builder: (context) => CalendarExportDialog(events: events),
    );
  }

  /// Показать диалог экспорта для бронирований
  static void showExportDialog(BuildContext context, List<Booking> bookings) {
    showDialog(
      context: context,
      builder: (context) => CalendarExportDialog(bookings: bookings),
    );
  }

  /// Быстрый экспорт события
  static Future<bool> quickExport(Event event) async {
    return await IcsExportService.exportAndShareEvent(event);
  }

  /// Быстрый экспорт бронирования
  static Future<bool> quickExport(Booking booking) async {
    return await IcsExportService.exportAndShareBooking(booking);
  }

  /// Быстрый экспорт событий
  static Future<bool> quickExport(List<Event> events) async {
    return await IcsExportService.exportAndShareEvents(events);
  }

  /// Быстрый экспорт бронирований
  static Future<bool> quickExport(List<Booking> bookings) async {
    return await IcsExportService.exportAndShareBookings(bookings);
  }
}
