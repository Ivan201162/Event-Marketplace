import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Сервис для логирования ошибок и аналитики
class ErrorLoggingService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Логирует ошибку в Crashlytics
  static Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    try {
      if (reason != null) {
        await _crashlytics.setCustomKey('error_reason', reason);
      }
      
      await _crashlytics.recordError(
        error,
        stackTrace,
        fatal: fatal,
        information: [
          'Error logged at: ${DateTime.now().toIso8601String()}',
          'Platform: ${defaultTargetPlatform.name}',
        ],
      );
      
      debugPrint('📊 Error logged to Crashlytics: $error');
    } catch (e) {
      debugPrint('❌ Failed to log error to Crashlytics: $e');
    }
  }

  /// Логирует пользовательское событие
  static Future<void> logUserAction(String action, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: action,
        parameters: parameters,
      );
      
      debugPrint('📈 User action logged: $action');
    } catch (e) {
      debugPrint('❌ Failed to log user action: $e');
    }
  }

  /// Логирует ошибку аутентификации
  static Future<void> logAuthError(String error, String method) async {
    await logError(
      'Auth Error: $error',
      StackTrace.current,
      reason: 'Authentication failed in $method',
    );
    
    await logUserAction('auth_error', parameters: {
      'error_message': error,
      'method': method,
    });
  }

  /// Логирует ошибку Firestore
  static Future<void> logFirestoreError(String error, String operation) async {
    await logError(
      'Firestore Error: $error',
      StackTrace.current,
      reason: 'Firestore operation failed: $operation',
    );
    
    await logUserAction('firestore_error', parameters: {
      'error_message': error,
      'operation': operation,
    });
  }

  /// Логирует ошибку Storage
  static Future<void> logStorageError(String error, String operation) async {
    await logError(
      'Storage Error: $error',
      StackTrace.current,
      reason: 'Storage operation failed: $operation',
    );
    
    await logUserAction('storage_error', parameters: {
      'error_message': error,
      'operation': operation,
    });
  }

  /// Логирует ошибку UI
  static Future<void> logUIError(String error, String screen) async {
    await logError(
      'UI Error: $error',
      StackTrace.current,
      reason: 'UI error in screen: $screen',
    );
    
    await logUserAction('ui_error', parameters: {
      'error_message': error,
      'screen': screen,
    });
  }

  /// Логирует ошибку роутинга
  static Future<void> logRoutingError(String error, String route) async {
    await logError(
      'Routing Error: $error',
      StackTrace.current,
      reason: 'Navigation failed to route: $route',
    );
    
    await logUserAction('routing_error', parameters: {
      'error_message': error,
      'route': route,
    });
  }

  /// Логирует успешное действие пользователя
  static Future<void> logSuccess(String action, {Map<String, dynamic>? parameters}) async {
    await logUserAction('success_$action', parameters: parameters);
  }

  /// Логирует начало сессии
  static Future<void> logSessionStart() async {
    await logUserAction('session_start', parameters: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Логирует конец сессии
  static Future<void> logSessionEnd() async {
    await logUserAction('session_end', parameters: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Устанавливает пользовательские данные для Crashlytics
  static Future<void> setUserData({
    required String userId,
    String? email,
    String? name,
  }) async {
    try {
      await _crashlytics.setUserIdentifier(userId);
      if (email != null) {
        await _crashlytics.setCustomKey('user_email', email);
      }
      if (name != null) {
        await _crashlytics.setCustomKey('user_name', name);
      }
      
      debugPrint('👤 User data set for Crashlytics: $userId');
    } catch (e) {
      debugPrint('❌ Failed to set user data: $e');
    }
  }

  /// Очищает пользовательские данные
  static Future<void> clearUserData() async {
    try {
      await _crashlytics.setUserIdentifier('');
      await _crashlytics.setCustomKey('user_email', '');
      await _crashlytics.setCustomKey('user_name', '');
      
      debugPrint('🧹 User data cleared from Crashlytics');
    } catch (e) {
      debugPrint('❌ Failed to clear user data: $e');
    }
  }
}