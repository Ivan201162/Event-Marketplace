import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для управления офлайн-режимом
class OfflineService {
  static const String _cacheVersionKey = 'cache_version';
  static const String _lastSyncKey = 'last_sync';
  static const String _offlineModeKey = 'offline_mode';
  static const int _currentCacheVersion = 1;

  /// Проверить подключение к интернету
  static Future<bool> isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Ошибка проверки подключения: $e');
      return false;
    }
  }

  /// Получить статус офлайн-режима
  static Future<bool> isOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_offlineModeKey) ?? false;
  }

  /// Установить офлайн-режим
  static Future<void> setOfflineMode(bool isOffline) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineModeKey, isOffline);
  }

  /// Получить версию кэша
  static Future<int> getCacheVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cacheVersionKey) ?? 0;
  }

  /// Обновить версию кэша
  static Future<void> updateCacheVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cacheVersionKey, _currentCacheVersion);
  }

  /// Получить время последней синхронизации
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Обновить время последней синхронизации
  static Future<void> updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncTime, DateTime.now().millisecondsSinceEpoch);
  }

  /// Сохранить данные в кэш
  static Future<void> saveToCache(String key, Map<String, dynamic> data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(path.join(directory.path, 'offline_cache'));

      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final file = File(path.join(cacheDir.path, '$key.json'));
      final jsonString = jsonEncode(data);
      await file.writeAsString(jsonString);

      debugPrint('Данные сохранены в кэш: $key');
    } catch (e) {
      debugPrint('Ошибка сохранения в кэш: $e');
    }
  }

  /// Загрузить данные из кэша
  static Future<Map<String, dynamic>?> loadFromCache(String key) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(path.join(directory.path, 'offline_cache'));

      if (!await cacheDir.exists()) {
        return null;
      }

      final file = File(path.join(cacheDir.path, '$key.json'));
      if (!await file.exists()) {
        return null;
      }

      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      debugPrint('Данные загружены из кэша: $key');
      return data;
    } catch (e) {
      debugPrint('Ошибка загрузки из кэша: $e');
      return null;
    }
  }

  /// Удалить данные из кэша
  static Future<void> removeFromCache(String key) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(path.join(directory.path, 'offline_cache'));

      if (!await cacheDir.exists()) {
        return;
      }

      final file = File(path.join(cacheDir.path, '$key.json'));
      if (await file.exists()) {
        await file.delete();
        debugPrint('Данные удалены из кэша: $key');
      }
    } catch (e) {
      debugPrint('Ошибка удаления из кэша: $e');
    }
  }

  /// Очистить весь кэш
  static Future<void> clearCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(path.join(directory.path, 'offline_cache'));

      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        debugPrint('Кэш очищен');
      }
    } catch (e) {
      debugPrint('Ошибка очистки кэша: $e');
    }
  }

  /// Получить размер кэша
  static Future<int> getCacheSize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(path.join(directory.path, 'offline_cache'));

      if (!await cacheDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Ошибка получения размера кэша: $e');
      return 0;
    }
  }

  /// Получить список ключей в кэше
  static Future<List<String>> getCacheKeys() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(path.join(directory.path, 'offline_cache'));

      if (!await cacheDir.exists()) {
        return [];
      }

      final keys = <String>[];
      await for (final entity in cacheDir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          final fileName = path.basename(entity.path);
          final key =
              fileName.substring(0, fileName.length - 5); // Убираем .json
          keys.add(key);
        }
      }

      return keys;
    } catch (e) {
      debugPrint('Ошибка получения ключей кэша: $e');
      return [];
    }
  }

  /// Проверить, устарел ли кэш
  static Future<bool> isCacheStale() async {
    try {
      final cacheVersion = await getCacheVersion();
      final lastSync = await getLastSyncTime();

      // Кэш устарел, если версия не совпадает или прошло больше 24 часов
      if (cacheVersion != _currentCacheVersion) {
        return true;
      }

      if (lastSync != null) {
        final now = DateTime.now();
        final difference = now.difference(lastSync);
        return difference.inHours > 24;
      }

      return true;
    } catch (e) {
      debugPrint('Ошибка проверки актуальности кэша: $e');
      return true;
    }
  }

  /// Синхронизировать данные
  static Future<void> syncData() async {
    try {
      final isOnline = await OfflineService.isOnline();
      if (!isOnline) {
        debugPrint('Нет подключения к интернету для синхронизации');
        return;
      }

      // TODO: Реализовать синхронизацию с сервером
      debugPrint('Синхронизация данных...');

      // Обновляем время последней синхронизации
      await updateLastSyncTime();
      await updateCacheVersion();

      debugPrint('Синхронизация завершена');
    } catch (e) {
      debugPrint('Ошибка синхронизации: $e');
    }
  }

  /// Форматировать размер в читаемый вид
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Ключи для кэширования данных
class CacheKeys {
  static const String userProfile = 'user_profile';
  static const String specialists = 'specialists';
  static const String bookings = 'bookings';
  static const String events = 'events';
  static const String reviews = 'reviews';
  static const String categories = 'categories';
  static const String settings = 'settings';
  static const String notifications = 'notifications';
  static const String chatMessages = 'chat_messages';
  static const String feedPosts = 'feed_posts';
  static const String stories = 'stories';
  static const String subscriptions = 'subscriptions';
}

/// Менеджер офлайн-данных для конкретных экранов
class OfflineDataManager {
  final String screenKey;

  OfflineDataManager(this.screenKey);

  /// Сохранить данные экрана
  Future<void> saveScreenData(Map<String, dynamic> data) async {
    await OfflineService.saveToCache('${screenKey}_data', data);
  }

  /// Загрузить данные экрана
  Future<Map<String, dynamic>?> loadScreenData() async {
    return await OfflineService.loadFromCache('${screenKey}_data');
  }

  /// Сохранить состояние экрана
  Future<void> saveScreenState(Map<String, dynamic> state) async {
    await OfflineService.saveToCache('${screenKey}_state', state);
  }

  /// Загрузить состояние экрана
  Future<Map<String, dynamic>?> loadScreenState() async {
    return await OfflineService.loadFromCache('${screenKey}_state');
  }

  /// Очистить данные экрана
  Future<void> clearScreenData() async {
    await OfflineService.removeFromCache('${screenKey}_data');
    await OfflineService.removeFromCache('${screenKey}_state');
  }
}

/// Утилиты для работы с офлайн-режимом
class OfflineUtils {
  /// Получить сообщение о статусе подключения
  static String getConnectionStatusMessage(bool isOnline) {
    return isOnline ? 'Подключено к интернету' : 'Работа в офлайн-режиме';
  }

  /// Получить иконку статуса подключения
  static String getConnectionStatusIcon(bool isOnline) {
    return isOnline ? '🌐' : '📱';
  }

  /// Получить цвет статуса подключения
  static int getConnectionStatusColor(bool isOnline) {
    return isOnline ? 0xFF4CAF50 : 0xFFFF9800; // Зеленый : Оранжевый
  }

  /// Проверить, можно ли выполнить операцию в офлайн-режиме
  static bool canPerformOffline(String operation) {
    const offlineOperations = [
      'view_profile',
      'view_bookings',
      'view_events',
      'view_reviews',
      'view_categories',
      'view_settings',
      'view_notifications',
      'view_chat_messages',
      'view_feed_posts',
      'view_stories',
      'view_subscriptions',
    ];

    return offlineOperations.contains(operation);
  }

  /// Получить сообщение об ограничениях офлайн-режима
  static String getOfflineLimitationMessage(String operation) {
    switch (operation) {
      case 'create_booking':
        return 'Создание бронирований недоступно в офлайн-режиме';
      case 'send_message':
        return 'Отправка сообщений недоступна в офлайн-режиме';
      case 'upload_media':
        return 'Загрузка медиафайлов недоступна в офлайн-режиме';
      case 'sync_data':
        return 'Синхронизация данных недоступна в офлайн-режиме';
      default:
        return 'Операция недоступна в офлайн-режиме';
    }
  }

  /// Получить рекомендации для офлайн-режима
  static List<String> getOfflineRecommendations() {
    return [
      'Проверьте подключение к интернету',
      'Некоторые функции могут быть ограничены',
      'Данные будут синхронизированы при восстановлении связи',
      'Используйте кэшированные данные для просмотра',
    ];
  }
}
