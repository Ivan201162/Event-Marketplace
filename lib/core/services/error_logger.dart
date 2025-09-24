import 'package:cloud_firestore/cloud_firestore.dart';

import '../logger.dart';

/// Сервис для логирования ошибок аутентификации
class ErrorLogger {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'errors_log';

  /// Записать ошибку аутентификации
  static Future<void> logAuthError({
    required String source,
    required String message,
    required String platform,
    String? stackTrace,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final errorData = {
        'source': source,
        'message': message,
        'platform': platform,
        'stackTrace': stackTrace,
        'additionalData': additionalData,
        'createdAt': FieldValue.serverTimestamp(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _firestore.collection(_collectionName).add(errorData);

      AppLogger.logE('Auth error logged: $message', source);
    } catch (e) {
      AppLogger.logE('Failed to log auth error', 'ErrorLogger', e);
    }
  }

  /// Получить дружелюбное сообщение об ошибке
  static String getFriendlyErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'Пользователь с таким email уже существует. Попробуйте войти или восстановить пароль.';
    } else if (error.contains('weak-password')) {
      return 'Пароль слишком слабый. Используйте минимум 6 символов.';
    } else if (error.contains('invalid-email')) {
      return 'Некорректный email адрес. Проверьте правильность ввода.';
    } else if (error.contains('user-not-found')) {
      return 'Пользователь не найден. Проверьте email или зарегистрируйтесь.';
    } else if (error.contains('wrong-password')) {
      return 'Неверный пароль. Проверьте правильность ввода.';
    } else if (error.contains('too-many-requests')) {
      return 'Слишком много попыток входа. Попробуйте позже.';
    } else if (error.contains('network-request-failed')) {
      return 'Ошибка сети. Проверьте подключение к интернету.';
    } else if (error.contains('popup-blocked')) {
      return 'Всплывающее окно заблокировано браузером. Разрешите всплывающие окна для этого сайта.';
    } else if (error.contains('api-key-not-valid')) {
      return 'Ошибка конфигурации. Обратитесь к администратору.';
    } else if (error.contains('vk')) {
      return 'Ошибка входа через ВКонтакте. Попробуйте другой способ входа.';
    } else if (error.contains('google')) {
      return 'Ошибка входа через Google. Проверьте, что всплывающие окна не заблокированы.';
    } else {
      return 'Произошла ошибка. Попробуйте еще раз или обратитесь в поддержку.';
    }
  }

  /// Получить сообщение об успехе
  static String getSuccessMessage(String action) {
    switch (action) {
      case 'register':
        return 'Регистрация успешна! Добро пожаловать!';
      case 'login':
        return 'Вход выполнен успешно!';
      case 'guest':
        return 'Вход как гость выполнен!';
      case 'google':
        return 'Вход через Google выполнен успешно!';
      case 'vk':
        return 'Вход через ВКонтакте выполнен успешно!';
      case 'reset':
        return 'Письмо для сброса пароля отправлено на ваш email.';
      default:
        return 'Операция выполнена успешно!';
    }
  }
}
