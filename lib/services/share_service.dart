import 'dart:io';

import 'package:event_marketplace_app/core/feature_flags.dart';
import 'package:event_marketplace_app/core/safe_log.dart';
import 'package:event_marketplace_app/models/booking.dart';
import 'package:event_marketplace_app/models/event.dart';
import 'package:event_marketplace_app/models/user.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Сервис для шаринга контента
class ShareService {
  /// Поделиться событием
  static Future<bool> shareEvent(Event event, {String? customMessage}) async {
    if (!FeatureFlags.shareEnabled) {
      SafeLog.warning('ShareService: Sharing is disabled');
      return false;
    }

    try {
      SafeLog.info('ShareService: Sharing event: ${event.title}');

      final message = customMessage ?? buildEventShareMessage(event);
      final subject = 'Событие: ${event.title}';

      await SharePlus.instance.share(message, subject: subject);

      SafeLog.info('ShareService: Event shared successfully');
      return true;
    } catch (e, stackTrace) {
      SafeLog.error('ShareService: Error sharing event', e, stackTrace);
      return false;
    }
  }

  /// Поделиться профилем пользователя
  static Future<bool> shareProfile(AppUser user,
      {String? customMessage,}) async {
    if (!FeatureFlags.shareEnabled) {
      SafeLog.warning('ShareService: Sharing is disabled');
      return false;
    }

    try {
      SafeLog.info('ShareService: Sharing profile: ${user.name}');

      final message = customMessage ?? buildProfileShareMessage(user);
      final subject = 'Профиль: ${user.name}';

      await SharePlus.instance.share(message, subject: subject);

      SafeLog.info('ShareService: Profile shared successfully');
      return true;
    } catch (e, stackTrace) {
      SafeLog.error('ShareService: Error sharing profile', e, stackTrace);
      return false;
    }
  }

  /// Поделиться бронированием
  static Future<bool> shareBooking(Booking booking,
      {String? customMessage,}) async {
    if (!FeatureFlags.shareEnabled) {
      SafeLog.warning('ShareService: Sharing is disabled');
      return false;
    }

    try {
      SafeLog.info('ShareService: Sharing booking: ${booking.eventTitle}');

      final message = customMessage ?? buildBookingShareMessage(booking);
      final subject = 'Бронирование: ${booking.eventTitle}';

      await SharePlus.instance.share(message, subject: subject);

      SafeLog.info('ShareService: Booking shared successfully');
      return true;
    } catch (e, stackTrace) {
      SafeLog.error('ShareService: Error sharing booking', e, stackTrace);
      return false;
    }
  }

  /// Поделиться текстом
  static Future<bool> shareText(String text, {String? subject}) async {
    if (!FeatureFlags.shareEnabled) {
      SafeLog.warning('ShareService: Sharing is disabled');
      return false;
    }

    try {
      SafeLog.info('ShareService: Sharing text');

      await SharePlus.instance.share(text, subject: subject);

      SafeLog.info('ShareService: Text shared successfully');
      return true;
    } catch (e, stackTrace) {
      SafeLog.error('ShareService: Error sharing text', e, stackTrace);
      return false;
    }
  }

  /// Поделиться файлом
  static Future<bool> shareFile(String filePath,
      {String? text, String? subject,}) async {
    if (!FeatureFlags.shareEnabled) {
      SafeLog.warning('ShareService: Sharing is disabled');
      return false;
    }

    try {
      SafeLog.info('ShareService: Sharing file: $filePath');

      final file = XFile(filePath);

      await SharePlus.instance
          .shareXFiles([file], text: text, subject: subject);

      SafeLog.info('ShareService: File shared successfully');
      return true;
    } catch (e, stackTrace) {
      SafeLog.error('ShareService: Error sharing file', e, stackTrace);
      return false;
    }
  }

  /// Поделиться несколькими файлами
  static Future<bool> shareFiles(List<String> filePaths,
      {String? text, String? subject,}) async {
    if (!FeatureFlags.shareEnabled) {
      SafeLog.warning('ShareService: Sharing is disabled');
      return false;
    }

    try {
      SafeLog.info('ShareService: Sharing ${filePaths.length} files');

      final files = filePaths.map(XFile.new).toList();

      await SharePlus.instance.shareXFiles(files, text: text, subject: subject);

      SafeLog.info('ShareService: Files shared successfully');
      return true;
    } catch (e, stackTrace) {
      SafeLog.error('ShareService: Error sharing files', e, stackTrace);
      return false;
    }
  }

  /// Поделиться ссылкой
  static Future<bool> shareLink(String url,
      {String? title, String? description,}) async {
    if (!FeatureFlags.shareEnabled) {
      SafeLog.warning('ShareService: Sharing is disabled');
      return false;
    }

    try {
      SafeLog.info('ShareService: Sharing link: $url');

      final message = _buildLinkShareMessage(url, title, description);
      final subject = title ?? 'Интересная ссылка';

      await SharePlus.instance.share(message, subject: subject);

      SafeLog.info('ShareService: Link shared successfully');
      return true;
    } catch (e, stackTrace) {
      SafeLog.error('ShareService: Error sharing link', e, stackTrace);
      return false;
    }
  }

  /// Открыть ссылку в браузере
  static Future<bool> openLink(String url) async {
    try {
      SafeLog.info('ShareService: Opening link: $url');

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        SafeLog.info('ShareService: Link opened successfully');
        return true;
      } else {
        SafeLog.warning('ShareService: Cannot launch URL: $url');
        return false;
      }
    } catch (e, stackTrace) {
      SafeLog.error('ShareService: Error opening link', e, stackTrace);
      return false;
    }
  }

  /// Открыть email клиент
  static Future<bool> openEmail(String email,
      {String? subject, String? body,}) async {
    try {
      SafeLog.info('ShareService: Opening email: $email');

      final uri = Uri(
          scheme: 'mailto',
          path: email,
          query: _buildEmailQuery(subject, body),);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        SafeLog.info('ShareService: Email opened successfully');
        return true;
      } else {
        SafeLog.warning('ShareService: Cannot launch email: $email');
        return false;
      }
    } catch (e, stackTrace) {
      SafeLog.error('ShareService: Error opening email', e, stackTrace);
      return false;
    }
  }

  /// Открыть телефон
  static Future<bool> openPhone(String phone) async {
    try {
      SafeLog.info('ShareService: Opening phone: $phone');

      final uri = Uri(scheme: 'tel', path: phone);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        SafeLog.info('ShareService: Phone opened successfully');
        return true;
      } else {
        SafeLog.warning('ShareService: Cannot launch phone: $phone');
        return false;
      }
    } catch (e, stackTrace) {
      SafeLog.error('ShareService: Error opening phone', e, stackTrace);
      return false;
    }
  }

  /// Открыть SMS
  static Future<bool> openSms(String phone, {String? message}) async {
    try {
      SafeLog.info('ShareService: Opening SMS: $phone');

      final uri = Uri(
        scheme: 'sms',
        path: phone,
        query: message != null ? 'body=${Uri.encodeComponent(message)}' : null,
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        SafeLog.info('ShareService: SMS opened successfully');
        return true;
      } else {
        SafeLog.warning('ShareService: Cannot launch SMS: $phone');
        return false;
      }
    } catch (e, stackTrace) {
      SafeLog.error('ShareService: Error opening SMS', e, stackTrace);
      return false;
    }
  }

  /// Построить сообщение для шаринга события
  static String buildEventShareMessage(Event event) {
    final buffer = StringBuffer();

    buffer.writeln('🎉 Интересное событие!');
    buffer.writeln();
    buffer.writeln('📅 ${event.title}');
    buffer.writeln('📅 ${_formatDate(event.date)}');

    if (event.location.isNotEmpty) {
      buffer.writeln('📍 ${event.location}');
    }

    if (event.description.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('📝 ${event.description}');
    }

    if (event.price > 0) {
      buffer.writeln();
      buffer.writeln('💰 Цена: ${event.price} руб.');
    }

    buffer.writeln();
    buffer.writeln('Скачайте приложение Event Marketplace для участия!');

    return buffer.toString();
  }

  /// Построить сообщение для шаринга профиля
  static String buildProfileShareMessage(AppUser user) {
    final buffer = StringBuffer();

    buffer.writeln('👤 Познакомьтесь с интересным человеком!');
    buffer.writeln();
    buffer.writeln('👋 ${user.name}');

    if (user.bio.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('📝 ${user.bio}');
    }

    if (user.specialties.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('🎯 Специализации: ${user.specialties.join(', ')}');
    }

    buffer.writeln();
    buffer.writeln('Скачайте приложение Event Marketplace для знакомства!');

    return buffer.toString();
  }

  /// Построить сообщение для шаринга бронирования
  static String buildBookingShareMessage(Booking booking) {
    final buffer = StringBuffer();

    buffer.writeln('🎫 Я забронировал место на событие!');
    buffer.writeln();
    buffer.writeln('📅 ${booking.eventTitle}');
    buffer.writeln('📅 ${_formatDate(booking.eventDate)}');
    buffer.writeln('👥 Участников: ${booking.participantsCount}');

    if (booking.notes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('📝 Примечания: ${booking.notes}');
    }

    buffer.writeln();
    buffer.writeln('Скачайте приложение Event Marketplace для участия!');

    return buffer.toString();
  }

  /// Построить сообщение для шаринга ссылки
  static String _buildLinkShareMessage(
      String url, String? title, String? description,) {
    final buffer = StringBuffer();

    if (title != null) {
      buffer.writeln('🔗 $title');
      buffer.writeln();
    }

    if (description != null) {
      buffer.writeln('📝 $description');
      buffer.writeln();
    }

    buffer.writeln('🔗 $url');

    return buffer.toString();
  }

  /// Построить query для email
  static String _buildEmailQuery(String? subject, String? body) {
    final params = <String>[];

    if (subject != null) {
      params.add('subject=${Uri.encodeComponent(subject)}');
    }

    if (body != null) {
      params.add('body=${Uri.encodeComponent(body)}');
    }

    return params.join('&');
  }

  /// Форматировать дату
  static String _formatDate(DateTime date) =>
      '${date.day}.${date.month}.${date.year} в ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  /// Проверить, доступен ли шаринг
  static bool get isEnabled => FeatureFlags.shareEnabled;

  /// Получить поддерживаемые платформы
  static List<String> get supportedPlatforms {
    if (kIsWeb) {
      return ['Web Share API', 'Copy to Clipboard'];
    } else if (Platform.isAndroid) {
      return ['Android Share', 'WhatsApp', 'Telegram', 'Email', 'SMS'];
    } else if (Platform.isIOS) {
      return ['iOS Share', 'WhatsApp', 'Telegram', 'Email', 'SMS', 'AirDrop'];
    } else {
      return ['System Share'];
    }
  }

  /// Получить информацию о шаринге
  static Map<String, dynamic> get shareInfo => {
        'isEnabled': isEnabled,
        'supportedPlatforms': supportedPlatforms,
        'isWeb': kIsWeb,
        'isAndroid': !kIsWeb && Platform.isAndroid,
        'isIOS': !kIsWeb && Platform.isIOS,
      };

  /// Построить сообщение для шаринга события
  static String buildEventShareMessage(Event event) {
    final buffer = StringBuffer();
    buffer.writeln('🎉 ${event.title}');
    buffer.writeln();
    buffer.writeln('📅 Дата: ${_formatDate(event.date)}');
    buffer.writeln('📍 Место: ${event.location}');
    buffer.writeln('💰 Цена: ${event.price} руб.');
    buffer.writeln();
    if (event.description.isNotEmpty) {
      buffer.writeln('📝 Описание:');
      buffer.writeln(event.description);
      buffer.writeln();
    }
    buffer.writeln('Присоединяйтесь к событию!');
    return buffer.toString();
  }

  /// Построить сообщение для шаринга профиля
  static String buildProfileShareMessage(AppUser user) {
    final buffer = StringBuffer();
    buffer.writeln('👤 ${user.name}');
    buffer.writeln();
    if (user.bio.isNotEmpty) {
      buffer.writeln('📝 О себе:');
      buffer.writeln(user.bio);
      buffer.writeln();
    }
    if (user.specialization.isNotEmpty) {
      buffer.writeln('🎯 Специализация: ${user.specialization}');
    }
    buffer.writeln();
    buffer.writeln('Посмотрите профиль этого специалиста!');
    return buffer.toString();
  }

  /// Построить сообщение для шаринга бронирования
  static String buildBookingShareMessage(Booking booking) {
    final buffer = StringBuffer();
    buffer.writeln('📋 Бронирование');
    buffer.writeln();
    buffer.writeln('🎉 Событие: ${booking.eventTitle}');
    buffer.writeln('📅 Дата: ${_formatDate(booking.eventDate)}');
    buffer.writeln('👤 Заказчик: ${booking.userName}');
    buffer.writeln('💰 Стоимость: ${booking.totalPrice} руб.');
    buffer.writeln();
    if (booking.notes.isNotEmpty) {
      buffer.writeln('📝 Примечания:');
      buffer.writeln(booking.notes);
      buffer.writeln();
    }
    buffer.writeln('Статус: ${_getBookingStatusText(booking.status)}');
    return buffer.toString();
  }

  /// Получить текст статуса бронирования
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
}

/// Расширения для удобства использования
extension EventShare on Event {
  /// Поделиться событием
  Future<bool> share({String? customMessage}) =>
      ShareService.shareEvent(this, customMessage: customMessage);
}

extension UserShare on AppUser {
  /// Поделиться профилем
  Future<bool> share({String? customMessage}) =>
      ShareService.shareProfile(this, customMessage: customMessage);
}

extension BookingShare on Booking {
  /// Поделиться бронированием
  Future<bool> share({String? customMessage}) =>
      ShareService.shareBooking(this, customMessage: customMessage);
}
