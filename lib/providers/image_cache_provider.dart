import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Провайдер для управления кэшем изображений
final imageCacheProvider = Provider<ImageCacheManager>((ref) {
  return ImageCacheManager();
});

/// Менеджер кэша изображений
class ImageCacheManager {
  static const int _maxCacheSize = 100; // Максимальное количество изображений в кэше
  static const int _maxCacheBytes = 50 * 1024 * 1024; // 50MB

  /// Инициализация кэша изображений
  void initializeCache() {
    // Настройка кэша изображений
    PaintingBinding.instance.imageCache.maximumSize = _maxCacheSize;
    PaintingBinding.instance.imageCache.maximumSizeBytes = _maxCacheBytes;
    
    // Предварительная загрузка часто используемых изображений
    _preloadCommonImages();
  }

  /// Предварительная загрузка общих изображений
  void _preloadCommonImages() {
    // Здесь можно добавить предварительную загрузку
    // часто используемых изображений (логотипы, иконки и т.д.)
  }

  /// Очистка кэша изображений
  void clearCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// Очистка кэша при нехватке памяти
  void clearCacheIfNeeded() {
    final imageCache = PaintingBinding.instance.imageCache;
    if (imageCache.currentSizeBytes > _maxCacheBytes * 0.8) {
      clearCache();
    }
  }

  /// Получение информации о кэше
  Map<String, dynamic> getCacheInfo() {
    final imageCache = PaintingBinding.instance.imageCache;
    return {
      'currentSize': imageCache.currentSize,
      'currentSizeBytes': imageCache.currentSizeBytes,
      'maximumSize': imageCache.maximumSize,
      'maximumSizeBytes': imageCache.maximumSizeBytes,
    };
  }
}

/// Провайдер для предварительной загрузки изображений
final imagePreloadProvider = FutureProvider.family<void, String>((ref, imageUrl) async {
  try {
    await precacheImage(
      CachedNetworkImageProvider(imageUrl),
      ref.read(imageCacheProvider).initializeCache() as BuildContext,
    );
  } catch (e) {
    // Игнорируем ошибки предварительной загрузки
    debugPrint('Failed to preload image: $imageUrl, error: $e');
  }
});

/// Провайдер для управления памятью
final memoryManagerProvider = Provider<MemoryManager>((ref) {
  return MemoryManager();
});

/// Менеджер памяти
class MemoryManager {
  /// Проверка использования памяти и очистка при необходимости
  void checkMemoryUsage() {
    final imageCache = PaintingBinding.instance.imageCache;
    
    // Если кэш изображений занимает больше 80% от максимального размера
    if (imageCache.currentSizeBytes > imageCache.maximumSizeBytes * 0.8) {
      // Очищаем старые изображения
      imageCache.clearLiveImages();
    }
  }

  /// Принудительная очистка памяти
  void forceCleanup() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}
