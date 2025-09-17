import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/image_optimization_service.dart';
import '../services/video_optimization_service.dart';

/// Провайдер для управления кэшем изображений
final imageCacheProvider =
    StateNotifierProvider<ImageCacheNotifier, ImageCacheState>((ref) {
  return ImageCacheNotifier();
});

/// Провайдер для управления кэшем видео
final videoCacheProvider =
    StateNotifierProvider<VideoCacheNotifier, VideoCacheState>((ref) {
  return VideoCacheNotifier();
});

/// Провайдер для общего размера кэша
final totalCacheSizeProvider = FutureProvider<int>((ref) async {
  final imageCacheSize = await ImageOptimizationService.getImageCacheSize();
  final videoCacheSize = await VideoOptimizationService.getVideoCacheSize();
  return imageCacheSize + videoCacheSize;
});

/// Провайдер для отформатированного размера кэша
final formattedCacheSizeProvider = Provider<String>((ref) {
  final cacheSize = ref.watch(totalCacheSizeProvider);
  return cacheSize.when(
    data: (size) => ImageOptimizationService.formatBytes(size),
    loading: () => 'Загрузка...',
    error: (_, __) => 'Ошибка',
  );
});

/// Состояние кэша изображений
class ImageCacheState {
  final bool isLoading;
  final int cacheSize;
  final String? error;
  final List<String> cachedImages;

  const ImageCacheState({
    this.isLoading = false,
    this.cacheSize = 0,
    this.error,
    this.cachedImages = const [],
  });

  ImageCacheState copyWith({
    bool? isLoading,
    int? cacheSize,
    String? error,
    List<String>? cachedImages,
  }) {
    return ImageCacheState(
      isLoading: isLoading ?? this.isLoading,
      cacheSize: cacheSize ?? this.cacheSize,
      error: error ?? this.error,
      cachedImages: cachedImages ?? this.cachedImages,
    );
  }
}

/// Состояние кэша видео
class VideoCacheState {
  final bool isLoading;
  final int cacheSize;
  final String? error;
  final List<String> cachedVideos;

  const VideoCacheState({
    this.isLoading = false,
    this.cacheSize = 0,
    this.error,
    this.cachedVideos = const [],
  });

  VideoCacheState copyWith({
    bool? isLoading,
    int? cacheSize,
    String? error,
    List<String>? cachedVideos,
  }) {
    return VideoCacheState(
      isLoading: isLoading ?? this.isLoading,
      cacheSize: cacheSize ?? this.cacheSize,
      error: error ?? this.error,
      cachedVideos: cachedVideos ?? this.cachedVideos,
    );
  }
}

/// Нотификатор для кэша изображений
class ImageCacheNotifier extends StateNotifier<ImageCacheState> {
  ImageCacheNotifier() : super(const ImageCacheState()) {
    _loadCacheInfo();
  }

  /// Загрузить информацию о кэше
  Future<void> _loadCacheInfo() async {
    state = state.copyWith(isLoading: true);

    try {
      final cacheSize = await ImageOptimizationService.getImageCacheSize();
      state = state.copyWith(
        isLoading: false,
        cacheSize: cacheSize,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Очистить кэш изображений
  Future<void> clearCache() async {
    state = state.copyWith(isLoading: true);

    try {
      await ImageOptimizationService.clearImageCache();
      state = state.copyWith(
        isLoading: false,
        cacheSize: 0,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Обновить информацию о кэше
  Future<void> refreshCacheInfo() async {
    await _loadCacheInfo();
  }

  /// Получить отформатированный размер кэша
  String getFormattedCacheSize() {
    return ImageOptimizationService.formatBytes(state.cacheSize);
  }
}

/// Нотификатор для кэша видео
class VideoCacheNotifier extends StateNotifier<VideoCacheState> {
  VideoCacheNotifier() : super(const VideoCacheState()) {
    _loadCacheInfo();
  }

  /// Загрузить информацию о кэше
  Future<void> _loadCacheInfo() async {
    state = state.copyWith(isLoading: true);

    try {
      final cacheSize = await VideoOptimizationService.getVideoCacheSize();
      state = state.copyWith(
        isLoading: false,
        cacheSize: cacheSize,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Очистить кэш видео
  Future<void> clearCache() async {
    state = state.copyWith(isLoading: true);

    try {
      await VideoOptimizationService.clearVideoCache();
      state = state.copyWith(
        isLoading: false,
        cacheSize: 0,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Обновить информацию о кэше
  Future<void> refreshCacheInfo() async {
    await _loadCacheInfo();
  }

  /// Получить отформатированный размер кэша
  String getFormattedCacheSize() {
    return ImageOptimizationService.formatBytes(state.cacheSize);
  }
}

/// Провайдер для настроек оптимизации медиа
final mediaOptimizationSettingsProvider = StateNotifierProvider<
    MediaOptimizationSettingsNotifier, MediaOptimizationSettings>((ref) {
  return MediaOptimizationSettingsNotifier();
});

/// Настройки оптимизации медиа
class MediaOptimizationSettings {
  final bool enableImageCompression;
  final bool enableVideoCompression;
  final bool enableCaching;
  final int imageQuality;
  final int maxImageWidth;
  final int maxImageHeight;
  final int maxVideoSize;
  final bool autoClearCache;
  final int cacheMaxSize;

  const MediaOptimizationSettings({
    this.enableImageCompression = true,
    this.enableVideoCompression = true,
    this.enableCaching = true,
    this.imageQuality = 85,
    this.maxImageWidth = 1920,
    this.maxImageHeight = 1080,
    this.maxVideoSize = 100 * 1024 * 1024, // 100 MB
    this.autoClearCache = false,
    this.cacheMaxSize = 500 * 1024 * 1024, // 500 MB
  });

  MediaOptimizationSettings copyWith({
    bool? enableImageCompression,
    bool? enableVideoCompression,
    bool? enableCaching,
    int? imageQuality,
    int? maxImageWidth,
    int? maxImageHeight,
    int? maxVideoSize,
    bool? autoClearCache,
    int? cacheMaxSize,
  }) {
    return MediaOptimizationSettings(
      enableImageCompression:
          enableImageCompression ?? this.enableImageCompression,
      enableVideoCompression:
          enableVideoCompression ?? this.enableVideoCompression,
      enableCaching: enableCaching ?? this.enableCaching,
      imageQuality: imageQuality ?? this.imageQuality,
      maxImageWidth: maxImageWidth ?? this.maxImageWidth,
      maxImageHeight: maxImageHeight ?? this.maxImageHeight,
      maxVideoSize: maxVideoSize ?? this.maxVideoSize,
      autoClearCache: autoClearCache ?? this.autoClearCache,
      cacheMaxSize: cacheMaxSize ?? this.cacheMaxSize,
    );
  }
}

/// Нотификатор для настроек оптимизации медиа
class MediaOptimizationSettingsNotifier
    extends StateNotifier<MediaOptimizationSettings> {
  MediaOptimizationSettingsNotifier()
      : super(const MediaOptimizationSettings());

  /// Обновить настройки сжатия изображений
  void updateImageCompressionSettings({
    bool? enableCompression,
    int? quality,
    int? maxWidth,
    int? maxHeight,
  }) {
    state = state.copyWith(
      enableImageCompression: enableCompression,
      imageQuality: quality,
      maxImageWidth: maxWidth,
      maxImageHeight: maxHeight,
    );
  }

  /// Обновить настройки сжатия видео
  void updateVideoCompressionSettings({
    bool? enableCompression,
    int? maxSize,
  }) {
    state = state.copyWith(
      enableVideoCompression: enableCompression,
      maxVideoSize: maxSize,
    );
  }

  /// Обновить настройки кэширования
  void updateCachingSettings({
    bool? enableCaching,
    bool? autoClearCache,
    int? cacheMaxSize,
  }) {
    state = state.copyWith(
      enableCaching: enableCaching,
      autoClearCache: autoClearCache,
      cacheMaxSize: cacheMaxSize,
    );
  }

  /// Сбросить настройки к значениям по умолчанию
  void resetToDefaults() {
    state = const MediaOptimizationSettings();
  }

  /// Получить рекомендуемые настройки для устройства
  MediaOptimizationSettings getRecommendedSettings() {
    // TODO: Определить характеристики устройства и вернуть оптимальные настройки
    return const MediaOptimizationSettings(
      enableImageCompression: true,
      enableVideoCompression: true,
      enableCaching: true,
      imageQuality: 85,
      maxImageWidth: 1920,
      maxImageHeight: 1080,
      maxVideoSize: 100 * 1024 * 1024,
      autoClearCache: true,
      cacheMaxSize: 500 * 1024 * 1024,
    );
  }
}

/// Провайдер для статистики использования медиа
final mediaUsageStatsProvider =
    StateNotifierProvider<MediaUsageStatsNotifier, MediaUsageStats>((ref) {
  return MediaUsageStatsNotifier();
});

/// Статистика использования медиа
class MediaUsageStats {
  final int totalImagesLoaded;
  final int totalVideosLoaded;
  final int totalImagesCompressed;
  final int totalVideosCompressed;
  final int totalCacheHits;
  final int totalCacheMisses;
  final int totalBytesSaved;

  const MediaUsageStats({
    this.totalImagesLoaded = 0,
    this.totalVideosLoaded = 0,
    this.totalImagesCompressed = 0,
    this.totalVideosCompressed = 0,
    this.totalCacheHits = 0,
    this.totalCacheMisses = 0,
    this.totalBytesSaved = 0,
  });

  MediaUsageStats copyWith({
    int? totalImagesLoaded,
    int? totalVideosLoaded,
    int? totalImagesCompressed,
    int? totalVideosCompressed,
    int? totalCacheHits,
    int? totalCacheMisses,
    int? totalBytesSaved,
  }) {
    return MediaUsageStats(
      totalImagesLoaded: totalImagesLoaded ?? this.totalImagesLoaded,
      totalVideosLoaded: totalVideosLoaded ?? this.totalVideosLoaded,
      totalImagesCompressed:
          totalImagesCompressed ?? this.totalImagesCompressed,
      totalVideosCompressed:
          totalVideosCompressed ?? this.totalVideosCompressed,
      totalCacheHits: totalCacheHits ?? this.totalCacheHits,
      totalCacheMisses: totalCacheMisses ?? this.totalCacheMisses,
      totalBytesSaved: totalBytesSaved ?? this.totalBytesSaved,
    );
  }

  /// Получить процент попаданий в кэш
  double get cacheHitRate {
    final total = totalCacheHits + totalCacheMisses;
    if (total == 0) return 0.0;
    return (totalCacheHits / total) * 100;
  }

  /// Получить отформатированный размер сэкономленных данных
  String get formattedBytesSaved {
    return ImageOptimizationService.formatBytes(totalBytesSaved);
  }
}

/// Нотификатор для статистики использования медиа
class MediaUsageStatsNotifier extends StateNotifier<MediaUsageStats> {
  MediaUsageStatsNotifier() : super(const MediaUsageStats());

  /// Записать загрузку изображения
  void recordImageLoaded() {
    state = state.copyWith(
      totalImagesLoaded: state.totalImagesLoaded + 1,
    );
  }

  /// Записать загрузку видео
  void recordVideoLoaded() {
    state = state.copyWith(
      totalVideosLoaded: state.totalVideosLoaded + 1,
    );
  }

  /// Записать сжатие изображения
  void recordImageCompressed(int bytesSaved) {
    state = state.copyWith(
      totalImagesCompressed: state.totalImagesCompressed + 1,
      totalBytesSaved: state.totalBytesSaved + bytesSaved,
    );
  }

  /// Записать сжатие видео
  void recordVideoCompressed(int bytesSaved) {
    state = state.copyWith(
      totalVideosCompressed: state.totalVideosCompressed + 1,
      totalBytesSaved: state.totalBytesSaved + bytesSaved,
    );
  }

  /// Записать попадание в кэш
  void recordCacheHit() {
    state = state.copyWith(
      totalCacheHits: state.totalCacheHits + 1,
    );
  }

  /// Записать промах кэша
  void recordCacheMiss() {
    state = state.copyWith(
      totalCacheMisses: state.totalCacheMisses + 1,
    );
  }

  /// Сбросить статистику
  void resetStats() {
    state = const MediaUsageStats();
  }
}
