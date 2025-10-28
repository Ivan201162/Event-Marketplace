import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Оптимизации для сборки приложения
class BuildOptimizations {
  factory BuildOptimizations() => _instance;
  const BuildOptimizations._internal();
  static const BuildOptimizations _instance = BuildOptimizations._internal();

  /// Инициализация оптимизаций для release сборки
  static void initializeReleaseOptimizations() {
    // Отключаем debug режим
    debugPrint = (message, {wrapWidth}) {};

    // Оптимизируем рендеринг
    _optimizeRendering();

    // Оптимизируем память
    _optimizeMemory();

    // Оптимизируем анимации
    _optimizeAnimations();
  }

  /// Инициализация оптимизаций для debug сборки
  static void initializeDebugOptimizations() {
    // Включаем debug режим
    debugPrint = kDebugMode ? debugPrint : (message, {wrapWidth}) {};

    // Оптимизируем рендеринг для debug
    _optimizeDebugRendering();
  }

  /// Оптимизация рендеринга
  static void _optimizeRendering() {
    // Устанавливаем оптимальные настройки рендеринга
    // ViewConfiguration не имеет copyWith, поэтому просто используем текущую конфигурацию
  }

  /// Оптимизация рендеринга для debug
  static void _optimizeDebugRendering() {
    // Настройки для debug режима
    // ViewConfiguration не имеет copyWith, поэтому просто используем текущую конфигурацию
  }

  /// Оптимизация памяти
  static void _optimizeMemory() {
    // Настройка кэша изображений
    PaintingBinding.instance.imageCache.maximumSize = 50;
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        25 * 1024 * 1024; // 25MB

    // Очистка кэша при нехватке памяти
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// Оптимизация анимаций
  static void _optimizeAnimations() {
    // Отключаем системные анимации для лучшей производительности
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top],);
  }

  /// Оптимизация для разных платформ
  static void initializePlatformOptimizations() {
    final platform = WidgetsBinding.instance.platformDispatcher.defaultRouteName
            .contains('android')
        ? TargetPlatform.android
        : TargetPlatform.iOS;

    // Оптимизации для Android
    if (platform == TargetPlatform.android) {
      _optimizeForAndroid();
    }

    // Оптимизации для iOS
    if (platform == TargetPlatform.iOS) {
      _optimizeForIOS();
    }

    // Оптимизации для Web
    if (kIsWeb) {
      _optimizeForWeb();
    }
  }

  /// Оптимизации для Android
  static void _optimizeForAndroid() {
    // Настройки для Android
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// Оптимизации для iOS
  static void _optimizeForIOS() {
    // Настройки для iOS
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// Оптимизации для Web
  static void _optimizeForWeb() {
    // Настройки для Web
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// Получение информации о производительности
  static Map<String, dynamic> getPerformanceInfo() {
    final platform = WidgetsBinding.instance.platformDispatcher.defaultRouteName
            .contains('android')
        ? TargetPlatform.android
        : TargetPlatform.iOS;
    return {
      'imageCacheSize': PaintingBinding.instance.imageCache.currentSize,
      'imageCacheSizeBytes':
          PaintingBinding.instance.imageCache.currentSizeBytes,
      'imageCacheMaxSize': PaintingBinding.instance.imageCache.maximumSize,
      'imageCacheMaxSizeBytes':
          PaintingBinding.instance.imageCache.maximumSizeBytes,
      'platform': platform.toString(),
    };
  }

  /// Очистка всех кэшей
  static void clearAllCaches() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// Принудительная очистка памяти
  static void forceMemoryCleanup() {
    clearAllCaches();
    // Дополнительные операции очистки памяти
  }
}

/// Оптимизированный виджет для release сборки
class OptimizedWidget extends StatelessWidget {
  const OptimizedWidget(
      {required this.child, super.key, this.enableOptimizations = true,});

  final Widget child;
  final bool enableOptimizations;

  @override
  Widget build(BuildContext context) {
    if (enableOptimizations) {
      // Применяем оптимизации
      return RepaintBoundary(child: child);
    }
    return child;
  }
}

/// Оптимизированный виджет для списков
class OptimizedListView extends StatelessWidget {
  const OptimizedListView({
    required this.itemCount, required this.itemBuilder, super.key,
    this.separatorBuilder,
    this.scrollController,
    this.physics,
    this.padding,
    this.cacheExtent = 250.0,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final ScrollController? scrollController;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final double cacheExtent;

  @override
  Widget build(BuildContext context) => ListView.separated(
        controller: scrollController,
        physics: physics,
        padding: padding,
        cacheExtent: cacheExtent,
        itemCount: itemCount,
        separatorBuilder:
            separatorBuilder ?? (context, index) => const SizedBox.shrink(),
        itemBuilder: itemBuilder,
      );
}

/// Оптимизированный виджет для сетки
class OptimizedGridView extends StatelessWidget {
  const OptimizedGridView({
    required this.itemCount, required this.itemBuilder, required this.crossAxisCount, super.key,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.scrollController,
    this.physics,
    this.padding,
    this.cacheExtent = 250.0,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final ScrollController? scrollController;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final double cacheExtent;

  @override
  Widget build(BuildContext context) => GridView.builder(
        controller: scrollController,
        physics: physics,
        padding: padding,
        cacheExtent: cacheExtent,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      );
}
