import 'dart:developer' as developer;
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'error_logging_service.dart';

/// Сервис для оптимизации веса приложения
class AppOptimizationService {
  factory AppOptimizationService() => _instance;
  AppOptimizationService._internal();
  static final AppOptimizationService _instance =
      AppOptimizationService._internal();

  final ErrorLoggingService _errorLogger = ErrorLoggingService();

  /// Получить размер кэша приложения
  Future<Map<String, dynamic>> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final appDocDir = await getApplicationDocumentsDirectory();

      final tempSize = await _getDirectorySize(tempDir);
      final docSize = await _getDirectorySize(appDocDir);

      return {
        'tempCacheSize': tempSize,
        'documentsSize': docSize,
        'totalSize': tempSize + docSize,
        'tempCacheSizeMB': (tempSize / (1024 * 1024)).toStringAsFixed(2),
        'documentsSizeMB': (docSize / (1024 * 1024)).toStringAsFixed(2),
        'totalSizeMB':
            ((tempSize + docSize) / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get cache size: $e',
        stackTrace: stackTrace.toString(),
        action: 'get_cache_size',
      );
      return {};
    }
  }

  /// Очистить кэш приложения
  Future<Map<String, dynamic>> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final appDocDir = await getApplicationDocumentsDirectory();

      final tempSizeBefore = await _getDirectorySize(tempDir);
      final docSizeBefore = await _getDirectorySize(appDocDir);

      // Очищаем временные файлы
      await _clearDirectory(tempDir);

      // Очищаем кэш изображений (но сохраняем важные данные)
      await _clearImageCache(appDocDir);

      final tempSizeAfter = await _getDirectorySize(tempDir);
      final docSizeAfter = await _getDirectorySize(appDocDir);

      final freedSpace =
          (tempSizeBefore + docSizeBefore) - (tempSizeAfter + docSizeAfter);

      return {
        'success': true,
        'freedSpace': freedSpace,
        'freedSpaceMB': (freedSpace / (1024 * 1024)).toStringAsFixed(2),
        'tempSizeBefore': tempSizeBefore,
        'tempSizeAfter': tempSizeAfter,
        'docSizeBefore': docSizeBefore,
        'docSizeAfter': docSizeAfter,
      };
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to clear cache: $e',
        stackTrace: stackTrace.toString(),
        action: 'clear_cache',
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Оптимизировать настройки приложения
  Future<Map<String, dynamic>> optimizeAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final optimizations = <String, dynamic>{};

      // Оптимизация настроек изображений
      optimizations['imageQuality'] = await _optimizeImageSettings(prefs);

      // Оптимизация настроек кэширования
      optimizations['cacheSettings'] = await _optimizeCacheSettings(prefs);

      // Оптимизация настроек уведомлений
      optimizations['notificationSettings'] =
          await _optimizeNotificationSettings(prefs);

      // Оптимизация настроек синхронизации
      optimizations['syncSettings'] = await _optimizeSyncSettings(prefs);

      await _errorLogger.logInfo(
        message: 'App settings optimized',
        action: 'optimize_settings',
        additionalData: optimizations,
      );

      return {'success': true, 'optimizations': optimizations};
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to optimize app settings: $e',
        stackTrace: stackTrace.toString(),
        action: 'optimize_settings',
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Получить рекомендации по оптимизации
  Future<List<Map<String, dynamic>>> getOptimizationRecommendations() async {
    try {
      final recommendations = <Map<String, dynamic>>[];

      // Проверяем размер кэша
      final cacheSize = await getCacheSize();
      final totalSizeMB = double.tryParse(cacheSize['totalSizeMB'] ?? '0') ?? 0;

      if (totalSizeMB > 100) {
        recommendations.add({
          'type': 'cache_cleanup',
          'priority': 'high',
          'title': 'Очистить кэш',
          'description':
              'Размер кэша составляет ${cacheSize['totalSizeMB']} МБ. Рекомендуется очистка.',
          'action': 'clear_cache',
          'estimatedSavings': '${(totalSizeMB * 0.7).toStringAsFixed(1)} МБ',
        });
      }

      // Проверяем настройки изображений
      final prefs = await SharedPreferences.getInstance();
      final imageQuality = prefs.getInt('image_quality') ?? 80;

      if (imageQuality > 90) {
        recommendations.add({
          'type': 'image_quality',
          'priority': 'medium',
          'title': 'Снизить качество изображений',
          'description':
              'Высокое качество изображений ($imageQuality%) увеличивает размер приложения.',
          'action': 'reduce_image_quality',
          'estimatedSavings': '20-30% размера изображений',
        });
      }

      // Проверяем настройки автосинхронизации
      final autoSync = prefs.getBool('auto_sync') ?? true;

      if (autoSync) {
        recommendations.add({
          'type': 'sync_settings',
          'priority': 'low',
          'title': 'Оптимизировать синхронизацию',
          'description':
              'Автоматическая синхронизация может расходовать трафик и батарею.',
          'action': 'optimize_sync',
          'estimatedSavings': 'Экономия трафика и батареи',
        });
      }

      // Проверяем настройки уведомлений
      final notificationFrequency =
          prefs.getString('notification_frequency') ?? 'all';

      if (notificationFrequency == 'all') {
        recommendations.add({
          'type': 'notifications',
          'priority': 'low',
          'title': 'Настроить уведомления',
          'description':
              'Слишком частые уведомления могут влиять на производительность.',
          'action': 'optimize_notifications',
          'estimatedSavings': 'Улучшение производительности',
        });
      }

      return recommendations;
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get optimization recommendations: $e',
        stackTrace: stackTrace.toString(),
        action: 'get_recommendations',
      );
      return [];
    }
  }

  /// Применить рекомендацию по оптимизации
  Future<Map<String, dynamic>> applyOptimizationRecommendation(
      String action) async {
    try {
      switch (action) {
        case 'clear_cache':
          return await clearCache();
        case 'reduce_image_quality':
          return await _reduceImageQuality();
        case 'optimize_sync':
          return await _optimizeSyncSettings();
        case 'optimize_notifications':
          final prefs = await SharedPreferences.getInstance();
          return await _optimizeNotificationSettings(prefs);
        default:
          return {
            'success': false,
            'error': 'Unknown optimization action: $action'
          };
      }
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to apply optimization recommendation: $e',
        stackTrace: stackTrace.toString(),
        action: 'apply_recommendation',
        additionalData: {'recommendationAction': action},
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Получить размер директории
  Future<int> _getDirectorySize(Directory directory) async {
    var size = 0;
    try {
      if (await directory.exists()) {
        await for (final entity in directory.list(recursive: true)) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    } catch (e) {
      developer.log('Error calculating directory size: $e');
    }
    return size;
  }

  /// Очистить директорию
  Future<void> _clearDirectory(Directory directory) async {
    try {
      if (await directory.exists()) {
        await for (final entity in directory.list()) {
          if (entity is File) {
            await entity.delete();
          } else if (entity is Directory) {
            await _clearDirectory(entity);
            await entity.delete();
          }
        }
      }
    } catch (e) {
      developer.log('Error clearing directory: $e');
    }
  }

  /// Очистить кэш изображений
  Future<void> _clearImageCache(Directory appDocDir) async {
    try {
      final imageCacheDir = Directory('${appDocDir.path}/image_cache');
      if (await imageCacheDir.exists()) {
        await _clearDirectory(imageCacheDir);
      }
    } catch (e) {
      developer.log('Error clearing image cache: $e');
    }
  }

  /// Оптимизировать настройки изображений
  Future<Map<String, dynamic>> _optimizeImageSettings(
      SharedPreferences prefs) async {
    try {
      // Устанавливаем оптимальное качество изображений
      await prefs.setInt('image_quality', 80);
      await prefs.setBool('compress_images', true);
      await prefs.setInt(
          'max_image_size', 1024); // Максимальный размер в пикселях

      return {'imageQuality': 80, 'compressImages': true, 'maxImageSize': 1024};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Оптимизировать настройки кэширования
  Future<Map<String, dynamic>> _optimizeCacheSettings(
      SharedPreferences prefs) async {
    try {
      // Устанавливаем оптимальные настройки кэширования
      await prefs.setInt('cache_duration_hours', 24);
      await prefs.setInt('max_cache_size_mb', 50);
      await prefs.setBool('auto_clear_cache', true);

      return {
        'cacheDurationHours': 24,
        'maxCacheSizeMB': 50,
        'autoClearCache': true
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Оптимизировать настройки уведомлений
  Future<Map<String, dynamic>> _optimizeNotificationSettings(
      SharedPreferences prefs) async {
    try {
      // Устанавливаем оптимальные настройки уведомлений
      await prefs.setString('notification_frequency', 'important');
      await prefs.setBool('vibration_enabled', false);
      await prefs.setBool('sound_enabled', true);

      return {
        'notificationFrequency': 'important',
        'vibrationEnabled': false,
        'soundEnabled': true,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Оптимизировать настройки синхронизации
  Future<Map<String, dynamic>> _optimizeSyncSettings(
      [SharedPreferences? prefs]) async {
    try {
      final prefsInstance = prefs ?? await SharedPreferences.getInstance();

      // Устанавливаем оптимальные настройки синхронизации
      await prefsInstance.setBool('auto_sync', false);
      await prefsInstance.setInt('sync_interval_hours', 6);
      await prefsInstance.setBool('sync_on_wifi_only', true);

      return {
        'autoSync': false,
        'syncIntervalHours': 6,
        'syncOnWifiOnly': true
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Снизить качество изображений
  Future<Map<String, dynamic>> _reduceImageQuality() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('image_quality', 70);
      await prefs.setBool('compress_images', true);

      return {'success': true, 'newImageQuality': 70, 'compressImages': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Получить статистику использования ресурсов
  Future<Map<String, dynamic>> getResourceUsageStats() async {
    try {
      final cacheSize = await getCacheSize();
      final prefs = await SharedPreferences.getInstance();

      return {
        'cacheSize': cacheSize,
        'imageQuality': prefs.getInt('image_quality') ?? 80,
        'autoSync': prefs.getBool('auto_sync') ?? true,
        'notificationFrequency':
            prefs.getString('notification_frequency') ?? 'all',
        'lastOptimization': prefs.getString('last_optimization'),
        'optimizationCount': prefs.getInt('optimization_count') ?? 0,
      };
    } catch (e, stackTrace) {
      await _errorLogger.logError(
        error: 'Failed to get resource usage stats: $e',
        stackTrace: stackTrace.toString(),
        action: 'get_resource_stats',
      );
      return {};
    }
  }
}
