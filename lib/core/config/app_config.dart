import 'package:flutter/services.dart';

/// Конфигурация приложения для production режима
class AppConfig {
  static const bool kProduction = true;
  static const bool kUseDemoData = false;
  static const bool kAutoSeedOnStart = false;
  static const bool kShowFeedFab = false;
  static const bool kShowFeedStories = true; // Stories only in feed
  static const bool kEnableFollowingFeed = true; // feed = followed users only
  static const Duration kStoriesTtl = Duration(hours: 24);
  
  static bool get isProduction => kProduction && !kUseDemoData && !kAutoSeedOnStart;
  
  /// Web Client ID для Google Sign-In (из build.gradle resValue)
  static String get webClientId {
    try {
      // Получаем из Android ресурсов через platform channel или напрямую
      // Для Android используем значение из resValue
      return const String.fromEnvironment(
        'WEB_CLIENT_ID',
        defaultValue: '272201705683-6fsm13vno98kk64kar7tkqpscbfv6kqv.apps.googleusercontent.com',
      );
    } catch (e) {
      // Fallback на значение из google-services.json
      return '272201705683-6fsm13vno98kk64kar7tkqpscbfv6kqv.apps.googleusercontent.com';
    }
  }
  
  /// Получить webClientId из Android ресурсов
  static Future<String> getWebClientIdFromResources() async {
    try {
      const platform = MethodChannel('com.eventmarketplace.app/config');
      final result = await platform.invokeMethod<String>('getWebClientId');
      if (result != null && result.isNotEmpty) {
        return result;
      }
    } catch (e) {
      // Fallback
    }
    return webClientId;
  }
}

