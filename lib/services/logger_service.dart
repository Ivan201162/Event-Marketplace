import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Уровни логирования
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

/// Сервис для логирования приложения
class LoggerService {
  factory LoggerService() => _instance;
  LoggerService._internal();
  static final LoggerService _instance = LoggerService._internal();

  /// Минимальный уровень логирования
  LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  /// Установить минимальный уровень логирования
  void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Проверить, нужно ли логировать сообщение
  bool _shouldLog(LogLevel level) => level.index >= _minLevel.index;

  /// Получить строковое представление уровня логирования
  String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.fatal:
        return 'FATAL';
    }
  }

  /// Получить цвет для уровня логирования (для консоли)
  String _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '\x1B[37m'; // Белый
      case LogLevel.info:
        return '\x1B[36m'; // Голубой
      case LogLevel.warning:
        return '\x1B[33m'; // Желтый
      case LogLevel.error:
        return '\x1B[31m'; // Красный
      case LogLevel.fatal:
        return '\x1B[35m'; // Пурпурный
    }
  }

  /// Сброс цвета
  static const String _resetColor = '\x1B[0m';

  /// Основной метод логирования
  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (!_shouldLog(level)) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelString = _getLevelString(level);
    final levelColor = _getLevelColor(level);
    final tagString = tag != null ? '[$tag]' : '';

    // Формируем основное сообщение
    final logMessage = '$levelColor$levelString$_resetColor $tagString $message';

    // Добавляем данные, если есть
    if (data != null && data.isNotEmpty) {
      final dataString = data.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      developer.log('$logMessage | Data: $dataString');
    } else {
      developer.log(logMessage);
    }

    // Добавляем ошибку и стек, если есть
    if (error != null) {
      developer.log('Error: $error', level: level.index);
      if (stackTrace != null) {
        developer.log('Stack trace: $stackTrace', level: level.index);
      }
    }

    // В debug режиме также выводим в консоль
    if (kDebugMode) {
      print(logMessage);
      if (data != null && data.isNotEmpty) {
        print('Data: $data');
      }
      if (error != null) {
        print('Error: $error');
        if (stackTrace != null) {
          print('Stack trace: $stackTrace');
        }
      }
    }
  }

  /// Логирование отладочной информации
  void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  /// Логирование информационных сообщений
  void info(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  /// Логирование предупреждений
  void warning(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, tag: tag, data: data);
  }

  /// Логирование ошибок
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Логирование критических ошибок
  void fatal(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.fatal,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Логирование производительности
  void performance(
    String operation,
    Duration duration, {
    String? tag,
    Map<String, dynamic>? data,
  }) {
    final message = 'Performance: $operation took ${duration.inMilliseconds}ms';
    _log(LogLevel.info, message, tag: tag ?? 'PERFORMANCE', data: data);
  }

  /// Логирование пользовательских действий
  void userAction(String action, {String? userId, Map<String, dynamic>? data}) {
    final message = 'User action: $action';
    final actionData = <String, dynamic>{
      'action': action,
      if (userId != null) 'userId': userId,
      if (data != null) ...data,
    };
    _log(LogLevel.info, message, tag: 'USER_ACTION', data: actionData);
  }

  /// Логирование API запросов
  void apiRequest(
    String method,
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? body,
  }) {
    final message = 'API Request: $method $url';
    final requestData = <String, dynamic>{
      'method': method,
      'url': url,
      if (headers != null) 'headers': headers,
      if (body != null) 'body': body,
    };
    _log(LogLevel.info, message, tag: 'API_REQUEST', data: requestData);
  }

  /// Логирование API ответов
  void apiResponse(
    String method,
    String url,
    int statusCode, {
    Map<String, dynamic>? data,
  }) {
    final message = 'API Response: $method $url - $statusCode';
    final responseData = <String, dynamic>{
      'method': method,
      'url': url,
      'statusCode': statusCode,
      if (data != null) 'responseData': data,
    };
    _log(LogLevel.info, message, tag: 'API_RESPONSE', data: responseData);
  }

  /// Логирование ошибок API
  void apiError(
    String method,
    String url,
    Object error, {
    StackTrace? stackTrace,
  }) {
    final message = 'API Error: $method $url';
    _log(
      LogLevel.error,
      message,
      tag: 'API_ERROR',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Логирование навигации
  void navigation(String from, String to, {Map<String, dynamic>? data}) {
    final message = 'Navigation: $from -> $to';
    final navData = <String, dynamic>{
      'from': from,
      'to': to,
      if (data != null) ...data,
    };
    _log(LogLevel.info, message, tag: 'NAVIGATION', data: navData);
  }

  /// Логирование состояния приложения
  void appState(String state, {Map<String, dynamic>? data}) {
    final message = 'App State: $state';
    final stateData = <String, dynamic>{
      'state': state,
      if (data != null) ...data,
    };
    _log(LogLevel.info, message, tag: 'APP_STATE', data: stateData);
  }

  /// Логирование Firebase операций
  void firebase(
    String operation, {
    String? collection,
    String? documentId,
    Map<String, dynamic>? data,
  }) {
    final message = 'Firebase: $operation';
    final firebaseData = <String, dynamic>{
      'operation': operation,
      if (collection != null) 'collection': collection,
      if (documentId != null) 'documentId': documentId,
      if (data != null) ...data,
    };
    _log(LogLevel.info, message, tag: 'FIREBASE', data: firebaseData);
  }

  /// Логирование ошибок Firebase
  void firebaseError(
    String operation,
    Object error, {
    String? collection,
    String? documentId,
    StackTrace? stackTrace,
  }) {
    final message = 'Firebase Error: $operation';
    _log(
      LogLevel.error,
      message,
      tag: 'FIREBASE_ERROR',
      error: error,
      stackTrace: stackTrace,
      data: {
        'operation': operation,
        if (collection != null) 'collection': collection,
        if (documentId != null) 'documentId': documentId,
      },
    );
  }

  /// Логирование аутентификации
  void auth(String action, {String? userId, Map<String, dynamic>? data}) {
    final message = 'Auth: $action';
    final authData = <String, dynamic>{
      'action': action,
      if (userId != null) 'userId': userId,
      if (data != null) ...data,
    };
    _log(LogLevel.info, message, tag: 'AUTH', data: authData);
  }

  /// Логирование ошибок аутентификации
  void authError(
    String action,
    Object error, {
    String? userId,
    StackTrace? stackTrace,
  }) {
    final message = 'Auth Error: $action';
    _log(
      LogLevel.error,
      message,
      tag: 'AUTH_ERROR',
      error: error,
      stackTrace: stackTrace,
      data: {
        'action': action,
        if (userId != null) 'userId': userId,
      },
    );
  }

  /// Логирование платежей
  void payment(
    String action, {
    String? paymentId,
    String? amount,
    Map<String, dynamic>? data,
  }) {
    final message = 'Payment: $action';
    final paymentData = <String, dynamic>{
      'action': action,
      if (paymentId != null) 'paymentId': paymentId,
      if (amount != null) 'amount': amount,
      if (data != null) ...data,
    };
    _log(LogLevel.info, message, tag: 'PAYMENT', data: paymentData);
  }

  /// Логирование ошибок платежей
  void paymentError(
    String action,
    Object error, {
    String? paymentId,
    StackTrace? stackTrace,
  }) {
    final message = 'Payment Error: $action';
    _log(
      LogLevel.error,
      message,
      tag: 'PAYMENT_ERROR',
      error: error,
      stackTrace: stackTrace,
      data: {
        'action': action,
        if (paymentId != null) 'paymentId': paymentId,
      },
    );
  }

  /// Логирование уведомлений
  void notification(
    String action, {
    String? notificationId,
    String? userId,
    Map<String, dynamic>? data,
  }) {
    final message = 'Notification: $action';
    final notificationData = <String, dynamic>{
      'action': action,
      if (notificationId != null) 'notificationId': notificationId,
      if (userId != null) 'userId': userId,
      if (data != null) ...data,
    };
    _log(LogLevel.info, message, tag: 'NOTIFICATION', data: notificationData);
  }

  /// Логирование ошибок уведомлений
  void notificationError(
    String action,
    Object error, {
    String? notificationId,
    StackTrace? stackTrace,
  }) {
    final message = 'Notification Error: $action';
    _log(
      LogLevel.error,
      message,
      tag: 'NOTIFICATION_ERROR',
      error: error,
      stackTrace: stackTrace,
      data: {
        'action': action,
        if (notificationId != null) 'notificationId': notificationId,
      },
    );
  }

  /// Логирование календаря
  void calendar(
    String action, {
    String? specialistId,
    String? eventId,
    Map<String, dynamic>? data,
  }) {
    final message = 'Calendar: $action';
    final calendarData = <String, dynamic>{
      'action': action,
      if (specialistId != null) 'specialistId': specialistId,
      if (eventId != null) 'eventId': eventId,
      if (data != null) ...data,
    };
    _log(LogLevel.info, message, tag: 'CALENDAR', data: calendarData);
  }

  /// Логирование ошибок календаря
  void calendarError(
    String action,
    Object error, {
    String? specialistId,
    StackTrace? stackTrace,
  }) {
    final message = 'Calendar Error: $action';
    _log(
      LogLevel.error,
      message,
      tag: 'CALENDAR_ERROR',
      error: error,
      stackTrace: stackTrace,
      data: {
        'action': action,
        if (specialistId != null) 'specialistId': specialistId,
      },
    );
  }

  /// Логирование чатов
  void chat(
    String action, {
    String? chatId,
    String? messageId,
    String? userId,
    Map<String, dynamic>? data,
  }) {
    final message = 'Chat: $action';
    final chatData = <String, dynamic>{
      'action': action,
      if (chatId != null) 'chatId': chatId,
      if (messageId != null) 'messageId': messageId,
      if (userId != null) 'userId': userId,
      if (data != null) ...data,
    };
    _log(LogLevel.info, message, tag: 'CHAT', data: chatData);
  }

  /// Логирование ошибок чатов
  void chatError(
    String action,
    Object error, {
    String? chatId,
    StackTrace? stackTrace,
  }) {
    final message = 'Chat Error: $action';
    _log(
      LogLevel.error,
      message,
      tag: 'CHAT_ERROR',
      error: error,
      stackTrace: stackTrace,
      data: {
        'action': action,
        if (chatId != null) 'chatId': chatId,
      },
    );
  }

  /// Логирование отзывов
  void review(
    String action, {
    String? reviewId,
    String? specialistId,
    String? customerId,
    Map<String, dynamic>? data,
  }) {
    final message = 'Review: $action';
    final reviewData = <String, dynamic>{
      'action': action,
      if (reviewId != null) 'reviewId': reviewId,
      if (specialistId != null) 'specialistId': specialistId,
      if (customerId != null) 'customerId': customerId,
      if (data != null) ...data,
    };
    _log(LogLevel.info, message, tag: 'REVIEW', data: reviewData);
  }

  /// Логирование ошибок отзывов
  void reviewError(
    String action,
    Object error, {
    String? reviewId,
    StackTrace? stackTrace,
  }) {
    final message = 'Review Error: $action';
    _log(
      LogLevel.error,
      message,
      tag: 'REVIEW_ERROR',
      error: error,
      stackTrace: stackTrace,
      data: {
        'action': action,
        if (reviewId != null) 'reviewId': reviewId,
      },
    );
  }

  /// Логирование аналитики
  void analytics(
    String action, {
    String? metricName,
    Map<String, dynamic>? data,
  }) {
    final message = 'Analytics: $action';
    final analyticsData = <String, dynamic>{
      'action': action,
      if (metricName != null) 'metricName': metricName,
      if (data != null) ...data,
    };
    _log(LogLevel.info, message, tag: 'ANALYTICS', data: analyticsData);
  }

  /// Логирование ошибок аналитики
  void analyticsError(
    String action,
    Object error, {
    String? metricName,
    StackTrace? stackTrace,
  }) {
    final message = 'Analytics Error: $action';
    _log(
      LogLevel.error,
      message,
      tag: 'ANALYTICS_ERROR',
      error: error,
      stackTrace: stackTrace,
      data: {
        'action': action,
        if (metricName != null) 'metricName': metricName,
      },
    );
  }

  /// Логирование поиска
  void search(
    String action, {
    String? query,
    Map<String, dynamic>? filters,
    Map<String, dynamic>? data,
  }) {
    final message = 'Search: $action';
    final searchData = <String, dynamic>{
      'action': action,
      if (query != null) 'query': query,
      if (filters != null) 'filters': filters,
      if (data != null) ...data,
    };
    _log(LogLevel.info, message, tag: 'SEARCH', data: searchData);
  }

  /// Логирование ошибок поиска
  void searchError(
    String action,
    Object error, {
    String? query,
    StackTrace? stackTrace,
  }) {
    final message = 'Search Error: $action';
    _log(
      LogLevel.error,
      message,
      tag: 'SEARCH_ERROR',
      error: error,
      stackTrace: stackTrace,
      data: {
        'action': action,
        if (query != null) 'query': query,
      },
    );
  }

  /// Логирование бронирований
  void booking(
    String action, {
    String? bookingId,
    String? specialistId,
    String? customerId,
    Map<String, dynamic>? data,
  }) {
    final message = 'Booking: $action';
    final bookingData = <String, dynamic>{
      'action': action,
      if (bookingId != null) 'bookingId': bookingId,
      if (specialistId != null) 'specialistId': specialistId,
      if (customerId != null) 'customerId': customerId,
      if (data != null) ...data,
    };
    _log(LogLevel.info, message, tag: 'BOOKING', data: bookingData);
  }

  /// Логирование ошибок бронирований
  void bookingError(
    String action,
    Object error, {
    String? bookingId,
    StackTrace? stackTrace,
  }) {
    final message = 'Booking Error: $action';
    _log(
      LogLevel.error,
      message,
      tag: 'BOOKING_ERROR',
      error: error,
      stackTrace: stackTrace,
      data: {
        'action': action,
        if (bookingId != null) 'bookingId': bookingId,
      },
    );
  }
}
