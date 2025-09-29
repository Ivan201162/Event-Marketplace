import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Утилита для диагностики проблем аутентификации
class AuthDiagnostics {
  /// Получить информацию о текущей конфигурации Firebase
  static Map<String, String> getFirebaseConfig() {
    try {
      final app = Firebase.app();
      final options = app.options;

      return {
        'projectId': options.projectId ?? 'Не установлен',
        'apiKey': _maskApiKey(options.apiKey ?? 'Не установлен'),
        'authDomain': options.authDomain ?? 'Не установлен',
        'storageBucket': options.storageBucket ?? 'Не установлен',
        'messagingSenderId': options.messagingSenderId ?? 'Не установлен',
        'appId': options.appId ?? 'Не установлен',
      };
    } catch (e) {
      return {
        'error': 'Ошибка получения конфигурации: $e',
      };
    }
  }

  /// Получить информацию о текущем пользователе
  static Map<String, String> getCurrentUserInfo() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'status': 'Пользователь не авторизован'};
      }

      return {
        'uid': user.uid,
        'email': user.email ?? 'Не указан',
        'displayName': user.displayName ?? 'Не указано',
        'isAnonymous': user.isAnonymous.toString(),
        'emailVerified': user.emailVerified.toString(),
        'creationTime': user.metadata.creationTime?.toString() ?? 'Неизвестно',
        'lastSignInTime':
            user.metadata.lastSignInTime?.toString() ?? 'Неизвестно',
      };
    } catch (e) {
      return {
        'error': 'Ошибка получения информации о пользователе: $e',
      };
    }
  }

  /// Получить информацию о домене
  static Map<String, String> getDomainInfo() {
    try {
      // Для веб-платформы
      if (kIsWeb) {
        return {
          'origin': 'web',
          'userAgent': 'web',
          'platform': 'web',
        };
      }

      return {
        'platform': 'mobile',
      };
    } catch (e) {
      return {
        'error': 'Ошибка получения информации о домене: $e',
      };
    }
  }

  /// Проверить доступность провайдеров аутентификации
  static Map<String, bool> checkAuthProviders() {
    try {
      final auth = FirebaseAuth.instance;
      return {
        'emailPassword': true, // Всегда доступен
        'google': true, // Предполагаем, что настроен
        'anonymous': true, // Всегда доступен
        'vk': false, // Пока не настроен
      };
    } catch (e) {
      return {
        'error': false,
      };
    }
  }

  /// Маскировать API ключ для безопасности
  static String _maskApiKey(String apiKey) {
    if (apiKey.length <= 8) return '***';
    return '${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}';
  }

  /// Получить все диагностические данные
  static Map<String, dynamic> getAllDiagnostics() {
    return {
      'firebase': getFirebaseConfig(),
      'user': getCurrentUserInfo(),
      'domain': getDomainInfo(),
      'providers': checkAuthProviders(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Виджет для отображения диагностической информации
class AuthDiagnosticsBanner extends StatelessWidget {
  const AuthDiagnosticsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final diagnostics = AuthDiagnostics.getAllDiagnostics();

    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        border: Border.all(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'DEV: Диагностика аутентификации',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDiagnosticSection('Firebase', diagnostics['firebase']),
          _buildDiagnosticSection('Пользователь', diagnostics['user']),
          _buildDiagnosticSection('Провайдеры', diagnostics['providers']),
          const SizedBox(height: 8),
          Text(
            'Время: ${diagnostics['timestamp']}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticSection(String title, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title:',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        ...data.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: const TextStyle(fontSize: 12),
              ),
            )),
        const SizedBox(height: 4),
      ],
    );
  }
}
