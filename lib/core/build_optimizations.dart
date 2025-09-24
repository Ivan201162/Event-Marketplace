import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Оптимизации для сборки приложения
class BuildOptimizations {
  static const BuildOptimizations _instance = BuildOptimizations._internal();
  factory BuildOptimizations() => _instance;
  const BuildOptimizations._internal();

  /// Инициализация оптимизаций для release сборки
  static void initializeReleaseOptimizations() {
    // Отключаем debug режим
    debugPrint = (String? message, {int? wrapWidth}) {};

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
    debugPrint = debugPrintThrottled;

    // Оптимизируем рендеринг для debug
    _optimizeDebugRendering();
  }

  /// Оптимизация рендеринга
  static void _optimizeRendering() {
    // Устанавливаем оптимальные настройки рендеринга
    WidgetsBinding.instance.renderView.configuration =
        WidgetsBinding.instance.renderView.configuration.copyWith(
      devicePixelRatio: 1.0, // Оптимизация для производительности
    );
  }

  /// Оптимизация рендеринга для debug
  static void _optimizeDebugRendering() {
    // Настройки для debug режима
    WidgetsBinding.instance.renderView.configuration =
        WidgetsBinding.instance.renderView.configuration.copyWith(
      devicePixelRatio: 1.0,
    );
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
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
  }

  /// Оптимизация для разных платформ
  static void initializePlatformOptimizations() {
    // Оптимизации для Android
    if (Theme.of(WidgetsBinding.instance.platformDispatcher.views.first)
            .platform ==
        TargetPlatform.android) {
      _optimizeForAndroid();
    }

    // Оптимизации для iOS
    if (Theme.of(WidgetsBinding.instance.platformDispatcher.views.first)
            .platform ==
        TargetPlatform.iOS) {
      _optimizeForIOS();
    }

    // Оптимизации для Web
    if (Theme.of(WidgetsBinding.instance.platformDispatcher.views.first)
            .platform ==
        TargetPlatform.web) {
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
    return {
      'imageCacheSize': PaintingBinding.instance.imageCache.currentSize,
      'imageCacheSizeBytes':
          PaintingBinding.instance.imageCache.currentSizeBytes,
      'imageCacheMaxSize': PaintingBinding.instance.imageCache.maximumSize,
      'imageCacheMaxSizeBytes':
          PaintingBinding.instance.imageCache.maximumSizeBytes,
      'platform':
          Theme.of(WidgetsBinding.instance.platformDispatcher.views.first)
              .platform
              .toString(),
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
  const OptimizedWidget({
    super.key,
    required this.child,
    this.enableOptimizations = true,
  });

  final Widget child;
  final bool enableOptimizations;

  @override
  Widget build(BuildContext context) {
    if (enableOptimizations) {
      // Применяем оптимизации
      return RepaintBoundary(
        child: child,
      );
    }
    return child;
  }
}

/// Оптимизированный виджет для списков
class OptimizedListView extends StatelessWidget {
  const OptimizedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
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
  Widget build(BuildContext context) {
    return ListView.separated(
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
}

/// Оптимизированный виджет для сетки
class OptimizedGridView extends StatelessWidget {
  const OptimizedGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.crossAxisCount,
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
  Widget build(BuildContext context) {
    return GridView.builder(
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
}
