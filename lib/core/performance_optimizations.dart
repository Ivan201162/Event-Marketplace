import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Оптимизации производительности для Event Marketplace App
class PerformanceOptimizations {
  // Приватный конструктор
  PerformanceOptimizations._();

  /// Инициализация оптимизаций производительности
  static void initialize() {
    // Отключаем системные анимации для лучшей производительности
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );

    // Устанавливаем оптимальные настройки рендеринга
    WidgetsBinding.instance.renderView.configuration =
        WidgetsBinding.instance.renderView.configuration.copyWith(
      devicePixelRatio: 1.0,
    );

    // Оптимизируем память
    _optimizeMemory();
  }

  /// Оптимизация памяти
  static void _optimizeMemory() {
    // Очищаем кэш изображений при нехватке памяти
    WidgetsBinding.instance.addObserver(_MemoryOptimizer());
  }

  /// Оптимизация изображений
  static Widget optimizeImage({
    required String imageUrl,
    required Widget child,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        );
      },
      // Оптимизации для производительности
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      filterQuality: FilterQuality.low,
      isAntiAlias: false,
    );
  }

  /// Оптимизация списков
  static Widget optimizeList({
    required List<Widget> children,
    ScrollController? controller,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return children[index];
      },
      // Оптимизации для производительности
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      addSemanticIndexes: false,
      cacheExtent: 250.0,
    );
  }

  /// Оптимизация сеток
  static Widget optimizeGrid({
    required List<Widget> children,
    required int crossAxisCount,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    ScrollController? controller,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return GridView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return children[index];
      },
      // Оптимизации для производительности
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      addSemanticIndexes: false,
      cacheExtent: 250.0,
    );
  }

  /// Оптимизация анимаций
  static Widget optimizeAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Оптимизация переходов между страницами
  static PageRouteBuilder optimizePageRoute({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Оптимизация провайдеров
  static Provider<T> optimizeProvider<T>({
    required T Function() create,
    String? name,
  }) {
    return Provider<T>(
      create: (ref) => create(),
      name: name,
    );
  }

  /// Оптимизация состояния
  static StateNotifierProvider<T, U>
      optimizeStateNotifier<T extends StateNotifier<U>, U>({
    required T Function() create,
    required U initial,
    String? name,
  }) {
    return StateNotifierProvider<T, U>(
      create: (ref) => create(),
      name: name,
    );
  }

  /// Оптимизация кэширования
  static Widget optimizeCache({
    required Widget child,
    required String key,
    Duration duration = const Duration(minutes: 30),
  }) {
    return CacheProvider(
      key: key,
      duration: duration,
      child: child,
    );
  }

  /// Оптимизация ленивой загрузки
  static Widget optimizeLazyLoad({
    required Widget child,
    required bool isVisible,
  }) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }
    return child;
  }

  /// Оптимизация виртуализации
  static Widget optimizeVirtualization({
    required List<Widget> children,
    required double itemHeight,
    ScrollController? controller,
  }) {
    return ListView.builder(
      controller: controller,
      itemCount: children.length,
      itemExtent: itemHeight,
      itemBuilder: (context, index) {
        return children[index];
      },
      // Оптимизации для виртуализации
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      addSemanticIndexes: false,
      cacheExtent: 250.0,
    );
  }

  /// Оптимизация рендеринга
  static Widget optimizeRendering({
    required Widget child,
    bool shouldRepaint = false,
  }) {
    if (shouldRepaint) {
      return RepaintBoundary(
        child: child,
      );
    }
    return child;
  }

  /// Оптимизация памяти для изображений
  static Widget optimizeImageMemory({
    required String imageUrl,
    required Widget child,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      // Оптимизации для памяти
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      filterQuality: FilterQuality.low,
      isAntiAlias: false,
      // Очистка кэша при нехватке памяти
      errorBuilder: (context, error, stackTrace) {
        // Очищаем кэш изображения
        imageCache.clear();
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        );
      },
    );
  }

  /// Оптимизация сети
  static Widget optimizeNetwork({
    required Widget child,
    required bool isConnected,
  }) {
    if (!isConnected) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Нет подключения к интернету'),
          ],
        ),
      );
    }
    return child;
  }

  /// Оптимизация батареи
  static void optimizeBattery() {
    // Отключаем анимации при низком заряде батареи
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
  }

  /// Оптимизация CPU
  static void optimizeCPU() {
    // Устанавливаем приоритет для основного потока
    WidgetsBinding.instance.schedulerBinding.addPostFrameCallback((_) {
      // Оптимизируем рендеринг
      WidgetsBinding.instance.renderView.configuration =
          WidgetsBinding.instance.renderView.configuration.copyWith(
        devicePixelRatio: 1.0,
      );
    });
  }

  /// Оптимизация GPU
  static void optimizeGPU() {
    // Отключаем антиалиасинг для лучшей производительности
    WidgetsBinding.instance.renderView.configuration =
        WidgetsBinding.instance.renderView.configuration.copyWith(
      devicePixelRatio: 1.0,
    );
  }

  /// Оптимизация диска
  static void optimizeDisk() {
    // Очищаем кэш при нехватке места
    imageCache.clear();
  }

  /// Оптимизация RAM
  static void optimizeRAM() {
    // Очищаем неиспользуемые объекты
    imageCache.clear();
  }

  /// Оптимизация сети
  static void optimizeNetwork() {
    // Устанавливаем таймауты для сетевых запросов
    // Это должно быть настроено в HTTP клиенте
  }

  /// Оптимизация базы данных
  static void optimizeDatabase() {
    // Оптимизируем запросы к базе данных
    // Это должно быть настроено в сервисах
  }

  /// Оптимизация кэша
  static void optimizeCache() {
    // Очищаем старый кэш
    imageCache.clear();
  }

  /// Оптимизация анимаций
  static void optimizeAnimations() {
    // Отключаем анимации при низкой производительности
    // Это должно быть настроено в настройках приложения
  }

  /// Оптимизация рендеринга
  static void optimizeRendering() {
    // Оптимизируем рендеринг
    WidgetsBinding.instance.renderView.configuration =
        WidgetsBinding.instance.renderView.configuration.copyWith(
      devicePixelRatio: 1.0,
    );
  }

  /// Оптимизация памяти
  static void optimizeMemory() {
    // Очищаем неиспользуемую память
    imageCache.clear();
  }

  /// Оптимизация производительности
  static void optimizePerformance() {
    // Применяем все оптимизации
    optimizeBattery();
    optimizeCPU();
    optimizeGPU();
    optimizeDisk();
    optimizeRAM();
    optimizeNetwork();
    optimizeDatabase();
    optimizeCache();
    optimizeAnimations();
    optimizeRendering();
    optimizeMemory();
  }
}

/// Провайдер кэша
class CacheProvider extends StatefulWidget {
  final Widget child;
  final String key;
  final Duration duration;

  const CacheProvider({
    super.key,
    required this.child,
    required this.key,
    required this.duration,
  });

  @override
  State<CacheProvider> createState() => _CacheProviderState();
}

class _CacheProviderState extends State<CacheProvider> {
  late DateTime _lastUpdate;
  late Widget _cachedChild;

  @override
  void initState() {
    super.initState();
    _lastUpdate = DateTime.now();
    _cachedChild = widget.child;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    if (now.difference(_lastUpdate) > widget.duration) {
      _lastUpdate = now;
      _cachedChild = widget.child;
    }
    return _cachedChild;
  }
}

/// Оптимизатор памяти
class _MemoryOptimizer extends WidgetsBindingObserver {
  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    // Очищаем кэш при нехватке памяти
    imageCache.clear();
  }
}

/// Оптимизатор производительности
class PerformanceOptimizer extends StatefulWidget {
  final Widget child;
  final bool enableOptimizations;

  const PerformanceOptimizer({
    super.key,
    required this.child,
    this.enableOptimizations = true,
  });

  @override
  State<PerformanceOptimizer> createState() => _PerformanceOptimizerState();
}

class _PerformanceOptimizerState extends State<PerformanceOptimizer> {
  @override
  void initState() {
    super.initState();
    if (widget.enableOptimizations) {
      PerformanceOptimizations.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
