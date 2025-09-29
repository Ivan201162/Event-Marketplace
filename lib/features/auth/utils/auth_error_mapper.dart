import 'package:firebase_auth/firebase_auth.dart';

/// Маппер для преобразования ошибок аутентификации в понятные пользователю сообщения
class AuthErrorMapper {
  /// Преобразовать FirebaseAuthException в понятное сообщение
  static String mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Пользователь с таким email не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Email уже используется';
      case 'weak-password':
        return 'Пароль слишком слабый. Используйте минимум 6 символов';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'user-disabled':
        return 'Аккаунт заблокирован. Обратитесь в поддержку';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'operation-not-allowed':
        return 'Операция не разрешена. Проверьте настройки Firebase';
      case 'configuration-not-found':
        return 'Конфигурация Firebase не найдена. Проверьте настройки проекта';
      case 'network-request-failed':
        return 'Ошибка сети. Проверьте подключение к интернету';
      case 'invalid-credential':
        return 'Неверные учетные данные';
      case 'account-exists-with-different-credential':
        return 'Аккаунт уже существует с другими учетными данными';
      case 'invalid-verification-code':
        return 'Неверный код подтверждения';
      case 'invalid-verification-id':
        return 'Неверный ID подтверждения';
      case 'missing-verification-code':
        return 'Отсутствует код подтверждения';
      case 'missing-verification-id':
        return 'Отсутствует ID подтверждения';
      case 'quota-exceeded':
        return 'Превышена квота запросов';
      case 'credential-already-in-use':
        return 'Учетные данные уже используются';
      case 'requires-recent-login':
        return 'Требуется повторный вход для выполнения операции';
      case 'popup-closed-by-user':
        return 'Всплывающее окно закрыто пользователем';
      case 'popup-blocked':
        return 'Всплывающее окно заблокировано браузером. Разрешите всплывающие окна';
      case 'cancelled-popup-request':
        return 'Запрос всплывающего окна отменен';
      case 'web-storage-unsupported':
        return 'Веб-хранилище не поддерживается';
      case 'app-deleted':
        return 'Приложение удалено';
      case 'keychain-error':
        return 'Ошибка цепочки ключей';
      case 'internal-error':
        return 'Внутренняя ошибка сервера';
      case 'invalid-app-credential':
        return 'Неверные учетные данные приложения';
      case 'invalid-user-token':
        return 'Неверный токен пользователя';
      case 'network-request-failed':
        return 'Ошибка сетевого запроса';
      case 'user-token-expired':
        return 'Токен пользователя истек';
      case 'web-context-cancelled':
        return 'Веб-контекст отменен';
      case 'web-context-unavailable':
        return 'Веб-контекст недоступен';
      default:
        return 'Ошибка аутентификации: ${e.message ?? e.code}';
    }
  }

  /// Преобразовать общую ошибку в понятное сообщение
  static String mapGeneralError(dynamic error) {
    if (error is FirebaseAuthException) {
      return mapFirebaseAuthException(error);
    }

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Ошибка сети. Проверьте подключение к интернету';
    }

    if (errorString.contains('timeout')) {
      return 'Превышено время ожидания. Попробуйте еще раз';
    }

    if (errorString.contains('permission')) {
      return 'Недостаточно прав для выполнения операции';
    }

    if (errorString.contains('configuration')) {
      return 'Ошибка конфигурации. Обратитесь к администратору';
    }

    return 'Произошла ошибка: $error';
  }

  /// Получить рекомендации по исправлению ошибки
  static List<String> getErrorRecommendations(String errorCode) {
    switch (errorCode) {
      case 'configuration-not-found':
        return [
          'Проверьте настройки Firebase в консоли',
          'Убедитесь, что проект Firebase активен',
          'Проверьте правильность конфигурации firebase_options.dart',
        ];
      case 'operation-not-allowed':
        return [
          'Включите провайдер аутентификации в Firebase Console',
          'Перейдите в Authentication > Sign-in method',
          'Включите Email/Password, Google, или Anonymous',
        ];
      case 'popup-blocked':
        return [
          'Разрешите всплывающие окна в браузере',
          'Добавьте сайт в исключения блокировщика',
          'Попробуйте использовать режим redirect',
        ];
      case 'network-request-failed':
        return [
          'Проверьте подключение к интернету',
          'Попробуйте отключить VPN или прокси',
          'Проверьте настройки файрвола',
        ];
      case 'too-many-requests':
        return [
          'Подождите несколько минут',
          'Попробуйте сбросить пароль',
          'Обратитесь в поддержку при необходимости',
        ];
      default:
        return [
          'Попробуйте еще раз через несколько минут',
          'Проверьте правильность введенных данных',
          'Обратитесь в поддержку при повторных ошибках',
        ];
    }
  }

  /// Проверить, является ли ошибка критической
  static bool isCriticalError(String errorCode) {
    const criticalErrors = [
      'configuration-not-found',
      'app-deleted',
      'internal-error',
      'invalid-app-credential',
    ];
    return criticalErrors.contains(errorCode);
  }

  /// Проверить, можно ли повторить операцию
  static bool canRetry(String errorCode) {
    const nonRetryableErrors = [
      'configuration-not-found',
      'app-deleted',
      'invalid-app-credential',
      'user-disabled',
    ];
    return !nonRetryableErrors.contains(errorCode);
  }
}
