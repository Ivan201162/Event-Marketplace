import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Централизованный обработчик ошибок приложения
class ErrorHandler {
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();
  static final ErrorHandler _instance = ErrorHandler._internal();

  /// Обработка различных типов ошибок
  static String handleError(error, {String? context}) {
    try {
      if (error is FirebaseAuthException) {
        return _handleFirebaseAuthError(error, context);
      } else if (error is FirebaseException) {
        return _handleFirebaseError(error, context);
      } else if (error is SocketException) {
        return _handleNetworkError(error, context);
      } else if (error is HttpException) {
        return _handleHttpError(error, context);
      } else if (error is FormatException) {
        return _handleFormatError(error, context);
      } else if (error is StateError) {
        return _handleStateError(error, context);
      } else if (error is ArgumentError) {
        return _handleArgumentError(error, context);
      } else if (error is RangeError) {
        return _handleRangeError(error, context);
      } else if (error is TypeError) {
        return _handleTypeError(error, context);
      } else if (error is UnimplementedError) {
        return _handleUnimplementedError(error, context);
      } else if (error is UnsupportedError) {
        return _handleUnsupportedError(error, context);
      } else if (error is Exception) {
        return _handleGenericException(error, context);
      } else {
        return _handleUnknownError(error, context);
      }
    } on Exception catch (e) {
      // Если обработка ошибки сама вызвала ошибку
      return 'Критическая ошибка в обработчике ошибок: ${e.toString()}';
    }
  }

  /// Обработка ошибок Firebase Auth
  static String _handleFirebaseAuthError(
    FirebaseAuthException error,
    String? context,
  ) {
    String message;
    final code = error.code;
    const type = 'FIREBASE_AUTH';

    switch (code) {
      case 'user-not-found':
        message = 'Пользователь не найден';
        break;
      case 'wrong-password':
        message = 'Неверный пароль';
        break;
      case 'email-already-in-use':
        message = 'Email уже используется';
        break;
      case 'weak-password':
        message = 'Пароль слишком слабый';
        break;
      case 'invalid-email':
        message = 'Неверный формат email';
        break;
      case 'user-disabled':
        message = 'Пользователь заблокирован';
        break;
      case 'too-many-requests':
        message = 'Слишком много попыток. Попробуйте позже';
        break;
      case 'operation-not-allowed':
        message = 'Операция не разрешена';
        break;
      case 'invalid-credential':
        message = 'Неверные учетные данные';
        break;
      case 'account-exists-with-different-credential':
        message = 'Аккаунт уже существует с другими учетными данными';
        break;
      case 'credential-already-in-use':
        message = 'Учетные данные уже используются';
        break;
      case 'invalid-verification-code':
        message = 'Неверный код подтверждения';
        break;
      case 'invalid-verification-id':
        message = 'Неверный ID подтверждения';
        break;
      case 'missing-verification-code':
        message = 'Отсутствует код подтверждения';
        break;
      case 'missing-verification-id':
        message = 'Отсутствует ID подтверждения';
        break;
      case 'network-request-failed':
        message = 'Ошибка сети. Проверьте подключение к интернету';
        break;
      case 'requires-recent-login':
        message = 'Требуется повторный вход';
        break;
      default:
        message =
            'Ошибка аутентификации: ${error.message ?? 'Неизвестная ошибка'}';
    }

    _logError(error, context, type, code);
    return message;
  }

  /// Обработка ошибок Firebase
  static String _handleFirebaseError(FirebaseException error, String? context) {
    String message;
    final code = error.code;
    const type = 'FIREBASE';

    switch (code) {
      case 'permission-denied':
        message = 'Доступ запрещен';
        break;
      case 'unavailable':
        message = 'Сервис временно недоступен';
        break;
      case 'deadline-exceeded':
        message = 'Превышено время ожидания';
        break;
      case 'resource-exhausted':
        message = 'Исчерпаны ресурсы';
        break;
      case 'failed-precondition':
        message = 'Не выполнено предварительное условие';
        break;
      case 'aborted':
        message = 'Операция прервана';
        break;
      case 'out-of-range':
        message = 'Значение вне допустимого диапазона';
        break;
      case 'unimplemented':
        message = 'Функция не реализована';
        break;
      case 'internal':
        message = 'Внутренняя ошибка сервера';
        break;
      case 'data-loss':
        message = 'Потеря данных';
        break;
      case 'unauthenticated':
        message = 'Пользователь не аутентифицирован';
        break;
      default:
        message = 'Ошибка Firebase: ${error.message ?? 'Неизвестная ошибка'}';
    }

    _logError(error, context, type, code);
    return message;
  }

  /// Обработка сетевых ошибок
  static String _handleNetworkError(SocketException error, String? context) {
    String message;
    const type = 'NETWORK';

    if (error.osError?.errorCode == 7) {
      message = 'Нет подключения к интернету';
    } else if (error.osError?.errorCode == 110) {
      message = 'Превышено время ожидания соединения';
    } else if (error.osError?.errorCode == 111) {
      message = 'Соединение отклонено';
    } else {
      message = 'Ошибка сети: ${error.message}';
    }

    _logError(
      error,
      context,
      type,
      error.osError?.errorCode.toString() ?? 'UNKNOWN',
    );
    return message;
  }

  /// Обработка HTTP ошибок
  static String _handleHttpError(HttpException error, String? context) {
    final message = 'Ошибка HTTP: ${error.message}';
    const type = 'HTTP';

    _logError(error, context, type, 'HTTP_ERROR');
    return message;
  }

  /// Обработка ошибок формата
  static String _handleFormatError(FormatException error, String? context) {
    final message = 'Ошибка формата данных: ${error.message}';
    const type = 'FORMAT';

    _logError(error, context, type, 'FORMAT_ERROR');
    return message;
  }

  /// Обработка ошибок состояния
  static String _handleStateError(StateError error, String? context) {
    final message = 'Ошибка состояния: ${error.message}';
    const type = 'STATE';

    _logError(error, context, type, 'STATE_ERROR');
    return message;
  }

  /// Обработка ошибок аргументов
  static String _handleArgumentError(ArgumentError error, String? context) {
    final message = 'Ошибка аргумента: ${error.message}';
    const type = 'ARGUMENT';

    _logError(error, context, type, 'ARGUMENT_ERROR');
    return message;
  }

  /// Обработка ошибок диапазона
  static String _handleRangeError(RangeError error, String? context) {
    final message = 'Ошибка диапазона: ${error.message}';
    const type = 'RANGE';

    _logError(error, context, type, 'RANGE_ERROR');
    return message;
  }

  /// Обработка ошибок типа
  static String _handleTypeError(TypeError error, String? context) {
    final message = 'Ошибка типа: ${error.toString()}';
    const type = 'TYPE';

    _logError(error, context, type, 'TYPE_ERROR');
    return message;
  }

  /// Обработка ошибок нереализованных функций
  static String _handleUnimplementedError(
    UnimplementedError error,
    String? context,
  ) {
    final message = 'Функция не реализована: ${error.message}';
    const type = 'UNIMPLEMENTED';

    _logError(error, context, type, 'UNIMPLEMENTED_ERROR');
    return message;
  }

  /// Обработка ошибок неподдерживаемых операций
  static String _handleUnsupportedError(
    UnsupportedError error,
    String? context,
  ) {
    final message = 'Неподдерживаемая операция: ${error.message}';
    const type = 'UNSUPPORTED';

    _logError(error, context, type, 'UNSUPPORTED_ERROR');
    return message;
  }

  /// Обработка общих исключений
  static String _handleGenericException(Exception error, String? context) {
    final message = 'Ошибка: ${error.toString()}';
    const type = 'EXCEPTION';

    _logError(error, context, type, 'GENERIC_EXCEPTION');
    return message;
  }

  /// Обработка неизвестных ошибок
  static String _handleUnknownError(error, String? context) {
    final message = 'Неизвестная ошибка: ${error.toString()}';
    const type = 'UNKNOWN';

    _logError(error, context, type, 'UNKNOWN_ERROR');
    return message;
  }

  /// Логирование ошибки
  static void _logError(
    error,
    String? context,
    String type,
    String code,
  ) {
    final timestamp = DateTime.now().toIso8601String();
    final errorInfo = {
      'timestamp': timestamp,
      'type': type,
      'code': code,
      'context': context ?? 'Unknown',
      'error': error.toString(),
      'stackTrace': error is Error ? error.stackTrace?.toString() : null,
    };

    // Логирование в консоль в debug режиме
    if (kDebugMode) {
      debugPrint('ERROR [$type]: $errorInfo');
    }

    // Здесь можно добавить отправку ошибок в сервис аналитики
    // например, Firebase Crashlytics, Sentry и т.д.
    _sendToAnalytics(errorInfo);
  }

  /// Отправка ошибки в аналитику
  static void _sendToAnalytics(Map<String, dynamic> errorInfo) {
    // Mock implementation
    // В реальном приложении здесь будет отправка в Firebase Crashlytics
    // или другой сервис аналитики
    if (kDebugMode) {
      debugPrint('Sending error to analytics: $errorInfo');
    }
  }

  /// Проверка типа ошибки
  static bool isNetworkError(error) =>
      error is SocketException ||
      error is HttpException ||
      (error is FirebaseException && error.code == 'network-request-failed');

  /// Проверка ошибки аутентификации
  static bool isAuthError(error) => error is FirebaseAuthException;

  /// Проверка ошибки разрешений
  static bool isPermissionError(error) =>
      error is FirebaseException && error.code == 'permission-denied';

  /// Получение пользовательского сообщения об ошибке
  static String getUserFriendlyMessage(error) {
    final message = handleError(error);

    // Дополнительная обработка для пользовательского интерфейса
    if (isNetworkError(error)) {
      return 'Проверьте подключение к интернету и попробуйте снова';
    } else if (isAuthError(error)) {
      return 'Ошибка входа. Проверьте данные и попробуйте снова';
    } else if (isPermissionError(error)) {
      return 'Недостаточно прав для выполнения операции';
    }

    return message;
  }

  /// Создание отчета об ошибке
  static Map<String, dynamic> createErrorReport(
    error, {
    String? context,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final message = handleError(error, context: context);

    return {
      'timestamp': timestamp,
      'context': context ?? 'Unknown',
      'errorType': error.runtimeType.toString(),
      'errorMessage': message,
      'originalError': error.toString(),
      'stackTrace': error is Error ? error.stackTrace?.toString() : null,
      'platform': defaultTargetPlatform.name,
      'isDebug': kDebugMode,
    };
  }
}
