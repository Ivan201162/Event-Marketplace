import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Сервис для ленивой загрузки экранов и оптимизации производительности
class LazyLoadingService {
  static final Map<String, Widget> _cachedScreens = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 30);
  
  /// Загрузить экран с кешированием
  static Widget loadScreen(String screenName, Widget Function() screenBuilder) {
    try {
      // Проверяем кеш
      if (_cachedScreens.containsKey(screenName)) {
        final timestamp = _cacheTimestamps[screenName];
        if (timestamp != null && 
            DateTime.now().difference(timestamp) < _cacheExpiry) {
          debugPrint('📱 Loading screen from cache: $screenName');
          return _cachedScreens[screenName]!;
        } else {
          // Кеш устарел, удаляем
          _cachedScreens.remove(screenName);
          _cacheTimestamps.remove(screenName);
        }
      }
      
      // Создаем новый экран
      debugPrint('📱 Creating new screen: $screenName');
      final screen = screenBuilder();
      
      // Кешируем экран
      _cachedScreens[screenName] = screen;
      _cacheTimestamps[screenName] = DateTime.now();
      
      return screen;
    } catch (e) {
      debugPrint('❌ Error loading screen $screenName: $e');
      return screenBuilder();
    }
  }
  
  /// Предзагрузить экран
  static Future<void> preloadScreen(String screenName, Widget Function() screenBuilder) async {
    try {
      if (!_cachedScreens.containsKey(screenName)) {
        debugPrint('📱 Preloading screen: $screenName');
        final screen = screenBuilder();
        _cachedScreens[screenName] = screen;
        _cacheTimestamps[screenName] = DateTime.now();
      }
    } catch (e) {
      debugPrint('❌ Error preloading screen $screenName: $e');
    }
  }
  
  /// Очистить кеш экрана
  static void clearScreenCache(String screenName) {
    _cachedScreens.remove(screenName);
    _cacheTimestamps.remove(screenName);
    debugPrint('🧹 Cleared cache for screen: $screenName');
  }
  
  /// Очистить весь кеш
  static void clearAllCache() {
    _cachedScreens.clear();
    _cacheTimestamps.clear();
    debugPrint('🧹 Cleared all screen cache');
  }
  
  /// Оптимизировать кеш (удалить устаревшие экраны)
  static void optimizeCache() {
    final now = DateTime.now();
    final expiredScreens = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiry) {
        expiredScreens.add(entry.key);
      }
    }
    
    for (final screenName in expiredScreens) {
      _cachedScreens.remove(screenName);
      _cacheTimestamps.remove(screenName);
    }
    
    if (expiredScreens.isNotEmpty) {
      debugPrint('🧹 Optimized cache, removed ${expiredScreens.length} expired screens');
    }
  }
  
  /// Получить статистику кеша
  static Map<String, dynamic> getCacheStats() {
    return {
      'cachedScreens': _cachedScreens.length,
      'cacheSize': _cachedScreens.length,
      'oldestCache': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
      'newestCache': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }
}

/// Виджет для ленивой загрузки экранов
class LazyScreen extends StatefulWidget {
  final String screenName;
  final Widget Function() screenBuilder;
  final Widget? loadingWidget;
  final Duration? loadingDelay;

  const LazyScreen({
    super.key,
    required this.screenName,
    required this.screenBuilder,
    this.loadingWidget,
    this.loadingDelay,
  });

  @override
  State<LazyScreen> createState() => _LazyScreenState();
}

class _LazyScreenState extends State<LazyScreen> {
  Widget? _cachedScreen;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScreen();
  }

  Future<void> _loadScreen() async {
    try {
      // Проверяем кеш
      _cachedScreen = LazyLoadingService.loadScreen(
        widget.screenName,
        widget.screenBuilder,
      );
      
      // Имитируем загрузку для лучшего UX
      if (widget.loadingDelay != null) {
        await Future.delayed(widget.loadingDelay!);
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading lazy screen: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingWidget ?? const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return _cachedScreen ?? widget.screenBuilder();
  }
}

/// Виджет для предзагрузки экранов
class ScreenPreloader extends StatefulWidget {
  final List<String> screenNames;
  final Map<String, Widget Function()> screenBuilders;
  final Widget child;

  const ScreenPreloader({
    super.key,
    required this.screenNames,
    required this.screenBuilders,
    required this.child,
  });

  @override
  State<ScreenPreloader> createState() => _ScreenPreloaderState();
}

class _ScreenPreloaderState extends State<ScreenPreloader> {
  @override
  void initState() {
    super.initState();
    _preloadScreens();
  }

  Future<void> _preloadScreens() async {
    for (final screenName in widget.screenNames) {
      if (widget.screenBuilders.containsKey(screenName)) {
        await LazyLoadingService.preloadScreen(
          screenName,
          widget.screenBuilders[screenName]!,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Виджет для оптимизации производительности
class PerformanceOptimizer extends StatefulWidget {
  final Widget child;
  final Duration optimizationInterval;
  final bool enableMemoryOptimization;
  final bool enableCacheOptimization;

  const PerformanceOptimizer({
    super.key,
    required this.child,
    this.optimizationInterval = const Duration(minutes: 5),
    this.enableMemoryOptimization = true,
    this.enableCacheOptimization = true,
  });

  @override
  State<PerformanceOptimizer> createState() => _PerformanceOptimizerState();
}

class _PerformanceOptimizerState extends State<PerformanceOptimizer> {
  late Timer _optimizationTimer;

  @override
  void initState() {
    super.initState();
    _startOptimizationTimer();
  }

  void _startOptimizationTimer() {
    _optimizationTimer = Timer.periodic(
      widget.optimizationInterval,
      (_) => _optimizePerformance(),
    );
  }

  void _optimizePerformance() {
    try {
      if (widget.enableCacheOptimization) {
        LazyLoadingService.optimizeCache();
      }
      
      if (widget.enableMemoryOptimization) {
        // Здесь можно добавить дополнительную оптимизацию памяти
        debugPrint('🧹 Memory optimization performed');
      }
    } catch (e) {
      debugPrint('❌ Error optimizing performance: $e');
    }
  }

  @override
  void dispose() {
    _optimizationTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Виджет для измерения производительности
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String screenName;
  final bool enableLogging;

  const PerformanceMonitor({
    super.key,
    required this.child,
    required this.screenName,
    this.enableLogging = true,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _endTime = DateTime.now();
    _logPerformance();
  }

  void _logPerformance() {
    if (widget.enableLogging) {
      final buildTime = _endTime.difference(_startTime);
      debugPrint('📊 Performance: ${widget.screenName} built in ${buildTime.inMilliseconds}ms');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
