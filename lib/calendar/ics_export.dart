import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/feature_flags.dart';
import '../core/safe_log.dart';
import '../models/booking.dart';
import '../models/event.dart';

/// Сервис для экспорта событий в формат iCalendar (.ics)
class IcsExportService {
  // Приватный конструктор для предотвращения создания экземпляров
  IcsExportService._();

  /// Экспортировать событие в файл .ics
  static Future<String?> exportEventToIcs(Event event) async {
    if (!FeatureFlags.calendarExportEnabled) {
      SafeLog.warning('IcsExportService: Calendar export is disabled');
      return null;
    }

    try {
      SafeLog.info('IcsExportService: Exporting event to ICS: ${event.title}');

      // Создаем содержимое .ics файла
      final icsContent = _generateIcsContent(event);

      // Сохраняем файл
      final fileName = '${_sanitizeFileName(event.title)}.ics';
      final file = await _saveIcsFile(fileName, icsContent);

      SafeLog.info(
        'IcsExportService: Event exported successfully to: ${file.path}',
      );

      return file.path;
    } on Exception catch (e, stackTrace) {
      SafeLog.error(
        'IcsExportService: Error exporting event to ICS',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// Экспортировать бронирование в файл .ics
  static Future<String?> exportBookingToIcs(Booking booking) async {
    if (!FeatureFlags.calendarExportEnabled) {
      SafeLog.warning('IcsExportService: Calendar export is disabled');
      return null;
    }

    try {
      SafeLog.info(
        'IcsExportService: Exporting booking to ICS: ${booking.eventTitle}',
      );

      // Создаем содержимое .ics файла
      final icsContent = _generateBookingIcsContent(booking);

      // Сохраняем файл
      final fileName = '${_sanitizeFileName(booking.eventTitle ?? 'booking')}_booking.ics';
      final file = await _saveIcsFile(fileName, icsContent);

      SafeLog.info(
        'IcsExportService: Booking exported successfully to: ${file.path}',
      );

      return file.path;
    } on Exception catch (e, stackTrace) {
      SafeLog.error(
        'IcsExportService: Error exporting booking to ICS',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// Экспортировать несколько событий в один файл .ics
  static Future<String?> exportEventsToIcs(List<Event> events) async {
    if (!FeatureFlags.calendarExportEnabled) {
      SafeLog.warning('IcsExportService: Calendar export is disabled');
      return null;
    }

    if (events.isEmpty) {
      SafeLog.warning('IcsExportService: No events to export');
      return null;
    }

    try {
      SafeLog.info(
        'IcsExportService: Exporting ${events.length} events to ICS',
      );

      // Создаем содержимое .ics файла
      final icsContent = _generateMultipleEventsIcsContent(events);

      // Сохраняем файл
      final fileName = 'events_export_${DateTime.now().millisecondsSinceEpoch}.ics';
      final file = await _saveIcsFile(fileName, icsContent);

      SafeLog.info(
        'IcsExportService: Events exported successfully to: ${file.path}',
      );

      return file.path;
    } on Exception catch (e, stackTrace) {
      SafeLog.error(
        'IcsExportService: Error exporting events to ICS',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// Экспортировать несколько бронирований в один файл .ics
  static Future<String?> exportBookingsToIcs(List<Booking> bookings) async {
    if (!FeatureFlags.calendarExportEnabled) {
      SafeLog.warning('IcsExportService: Calendar export is disabled');
      return null;
    }

    if (bookings.isEmpty) {
      SafeLog.warning('IcsExportService: No bookings to export');
      return null;
    }

    try {
      SafeLog.info(
        'IcsExportService: Exporting ${bookings.length} bookings to ICS',
      );

      // Создаем содержимое .ics файла
      final icsContent = _generateMultipleBookingsIcsContent(bookings);

      // Сохраняем файл
      final fileName = 'bookings_export_${DateTime.now().millisecondsSinceEpoch}.ics';
      final file = await _saveIcsFile(fileName, icsContent);

      SafeLog.info(
        'IcsExportService: Bookings exported successfully to: ${file.path}',
      );

      return file.path;
    } on Exception catch (e, stackTrace) {
      SafeLog.error(
        'IcsExportService: Error exporting bookings to ICS',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// Поделиться файлом .ics
  static Future<bool> shareIcsFile(String filePath, {String? subject}) async {
    if (!FeatureFlags.calendarExportEnabled) {
      SafeLog.warning('IcsExportService: Calendar export is disabled');
      return false;
    }

    try {
      SafeLog.info('IcsExportService: Sharing ICS file: $filePath');

      final file = File(filePath);
      if (!file.existsSync()) {
        SafeLog.error('IcsExportService: File does not exist: $filePath');
        return false;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [filePath],
          subject: subject ?? 'Календарное событие',
          text: 'Экспорт календарного события',
        ),
      );

      SafeLog.info('IcsExportService: ICS file shared successfully');
      return true;
    } on Exception catch (e, stackTrace) {
      SafeLog.error('IcsExportService: Error sharing ICS file', e, stackTrace);
      return false;
    }
  }

  /// Экспортировать и поделиться событием
  static Future<bool> exportAndShareEvent(Event event) async {
    final filePath = await exportEventToIcs(event);
    if (filePath != null) {
      return shareIcsFile(filePath, subject: 'Событие: ${event.title}');
    }
    return false;
  }

  /// Экспортировать и поделиться бронированием
  static Future<bool> exportAndShareBooking(Booking booking) async {
    final filePath = await exportBookingToIcs(booking);
    if (filePath != null) {
      return shareIcsFile(
        filePath,
        subject: 'Бронирование: ${booking.eventTitle}',
      );
    }
    return false;
  }

  /// Экспортировать и поделиться несколькими событиями
  static Future<bool> exportAndShareEvents(List<Event> events) async {
    final filePath = await exportEventsToIcs(events);
    if (filePath != null) {
      return shareIcsFile(
        filePath,
        subject: 'Экспорт событий (${events.length})',
      );
    }
    return false;
  }

  /// Экспортировать и поделиться несколькими бронированиями
  static Future<bool> exportAndShareBookings(List<Booking> bookings) async {
    final filePath = await exportBookingsToIcs(bookings);
    if (filePath != null) {
      return shareIcsFile(
        filePath,
        subject: 'Экспорт бронирований (${bookings.length})',
      );
    }
    return false;
  }

  /// Сохранить .ics файл
  static Future<File> _saveIcsFile(String fileName, String content) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    return file;
  }

  /// Очистить имя файла от недопустимых символов
  static String _sanitizeFileName(String fileName) => fileName
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .substring(0, fileName.length > 50 ? 50 : fileName.length);

  /// Построить описание для бронирования
  static String _buildBookingDescription(Booking booking) {
    final buffer = StringBuffer();

    buffer
      ..writeln('Бронирование события')
      ..writeln()
      ..writeln('Событие: ${booking.eventTitle}')
      ..writeln('Участников: ${booking.participantsCount}')
      ..writeln('Цена: ${booking.totalPrice} руб.');

    if (booking.notes != null && booking.notes!.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Примечания: ${booking.notes}');
    }

    if (booking.organizerName != null) {
      buffer
        ..writeln()
        ..writeln('Организатор: ${booking.organizerName}');
    }

    buffer
      ..writeln()
      ..writeln('Статус: ${_getBookingStatusText(booking.status)}');

    return buffer.toString();
  }

  /// Получить текстовое описание статуса бронирования
  static String _getBookingStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Ожидает подтверждения';
      case BookingStatus.confirmed:
        return 'Подтверждено';
      case BookingStatus.cancelled:
        return 'Отменено';
      case BookingStatus.completed:
        return 'Завершено';
      case BookingStatus.rejected:
        return 'Отклонено';
    }
  }

  /// Проверить, доступен ли экспорт календаря
  static bool get isEnabled => FeatureFlags.calendarExportEnabled;

  /// Получить информацию о поддерживаемых форматах
  static List<String> get supportedFormats => ['ICS (iCalendar)'];

  /// Получить максимальное количество событий для экспорта
  static int get maxEventsPerExport => 100;

  /// Проверить, можно ли экспортировать указанное количество событий
  static bool canExportEvents(int count) => isEnabled && count > 0 && count <= maxEventsPerExport;

  /// Генерировать содержимое .ics файла для события
  static String _generateIcsContent(Event event) {
    final buffer = StringBuffer();

    buffer
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//Event Marketplace//Event Calendar//EN')
      ..writeln('BEGIN:VEVENT')
      ..writeln('UID:${event.id}@eventmarketplace.com')
      ..writeln('DTSTART:${_formatDateTime(event.date)}')
      ..writeln(
        'DTEND:${_formatDateTime(event.date.add(const Duration(hours: 2)))}',
      )
      ..writeln('SUMMARY:${event.title}');
    buffer.writeln('DESCRIPTION:${event.description}');
    if (event.location.isNotEmpty) {
      buffer.writeln('LOCATION:${event.location}');
    }
    buffer
      ..writeln('STATUS:CONFIRMED')
      ..writeln('CREATED:${_formatDateTime(DateTime.now())}')
      ..writeln('LAST-MODIFIED:${_formatDateTime(DateTime.now())}')
      ..writeln('END:VEVENT')
      ..writeln('END:VCALENDAR');

    return buffer.toString();
  }

  /// Генерировать содержимое .ics файла для бронирования
  static String _generateBookingIcsContent(Booking booking) {
    final buffer = StringBuffer();

    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//Event Marketplace//Booking Calendar//EN');
    buffer.writeln('BEGIN:VEVENT');
    buffer.writeln('UID:${booking.id}@eventmarketplace.com');
    buffer.writeln('DTSTART:${_formatDateTime(booking.eventDate)}');
    buffer.writeln(
      'DTEND:${_formatDateTime(booking.endDate ?? booking.eventDate.add(const Duration(hours: 2)))}',
    );
    buffer.writeln('SUMMARY:${booking.eventTitle}');
    buffer.writeln('DESCRIPTION:${_buildBookingDescription(booking)}');
    if (booking.notes != null && booking.notes!.isNotEmpty) {
      buffer.writeln('LOCATION:${booking.notes}');
    }
    buffer.writeln('STATUS:${_getBookingStatusText(booking.status)}');
    buffer.writeln('CREATED:${_formatDateTime(booking.createdAt)}');
    buffer.writeln(
      'LAST-MODIFIED:${_formatDateTime(booking.updatedAt ?? booking.createdAt)}',
    );
    buffer.writeln('END:VEVENT');
    buffer.writeln('END:VCALENDAR');

    return buffer.toString();
  }

  /// Генерировать содержимое .ics файла для множественных событий
  static String _generateMultipleEventsIcsContent(List<Event> events) {
    final buffer = StringBuffer();

    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//Event Marketplace//Events Calendar//EN');

    for (final event in events) {
      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:${event.id}@eventmarketplace.com');
      buffer.writeln('DTSTART:${_formatDateTime(event.date)}');
      buffer.writeln(
        'DTEND:${_formatDateTime(event.date.add(const Duration(hours: 2)))}',
      );
      buffer.writeln('SUMMARY:${event.title}');
      buffer.writeln('DESCRIPTION:${event.description}');
      if (event.location.isNotEmpty) {
        buffer.writeln('LOCATION:${event.location}');
      }
      buffer.writeln('STATUS:CONFIRMED');
      buffer.writeln('CREATED:${_formatDateTime(DateTime.now())}');
      buffer.writeln('LAST-MODIFIED:${_formatDateTime(DateTime.now())}');
      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');

    return buffer.toString();
  }

  /// Генерировать содержимое .ics файла для множественных бронирований
  static String _generateMultipleBookingsIcsContent(List<Booking> bookings) {
    final buffer = StringBuffer();

    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//Event Marketplace//Bookings Calendar//EN');

    for (final booking in bookings) {
      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:${booking.id}@eventmarketplace.com');
      buffer.writeln('DTSTART:${_formatDateTime(booking.eventDate)}');
      buffer.writeln(
        'DTEND:${_formatDateTime(booking.endDate ?? booking.eventDate.add(const Duration(hours: 2)))}',
      );
      buffer.writeln('SUMMARY:${booking.eventTitle}');
      buffer.writeln('DESCRIPTION:${_buildBookingDescription(booking)}');
      if (booking.notes != null && booking.notes!.isNotEmpty) {
        buffer.writeln('LOCATION:${booking.notes}');
      }
      buffer.writeln('STATUS:${_getBookingStatusText(booking.status)}');
      buffer.writeln('CREATED:${_formatDateTime(booking.createdAt)}');
      buffer.writeln(
        'LAST-MODIFIED:${_formatDateTime(booking.updatedAt ?? booking.createdAt)}',
      );
      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');

    return buffer.toString();
  }

  /// Форматировать дату и время для .ics
  static String _formatDateTime(DateTime dateTime) =>
      '${dateTime.year.toString().padLeft(4, '0')}${dateTime.month.toString().padLeft(2, '0')}${dateTime.day.toString().padLeft(2, '0')}T${dateTime.hour.toString().padLeft(2, '0')}${dateTime.minute.toString().padLeft(2, '0')}${dateTime.second.toString().padLeft(2, '0')}Z';
}

/// Расширения для удобства использования
extension EventIcsExport on Event {
  /// Экспортировать событие в .ics
  Future<String?> exportToIcs() => IcsExportService.exportEventToIcs(this);

  /// Экспортировать и поделиться событием
  Future<bool> exportAndShare() => IcsExportService.exportAndShareEvent(this);
}

extension BookingIcsExport on Booking {
  /// Экспортировать бронирование в .ics
  Future<String?> exportToIcs() => IcsExportService.exportBookingToIcs(this);

  /// Экспортировать и поделиться бронированием
  Future<bool> exportAndShare() => IcsExportService.exportAndShareBooking(this);
}

extension EventsIcsExport on List<Event> {
  /// Экспортировать события в .ics
  Future<String?> exportToIcs() => IcsExportService.exportEventsToIcs(this);

  /// Экспортировать и поделиться событиями
  Future<bool> exportAndShare() => IcsExportService.exportAndShareEvents(this);
}

extension BookingsIcsExport on List<Booking> {
  /// Экспортировать бронирования в .ics
  Future<String?> exportToIcs() => IcsExportService.exportBookingsToIcs(this);

  /// Экспортировать и поделиться бронированиями
  Future<bool> exportAndShare() => IcsExportService.exportAndShareBookings(this);
}
