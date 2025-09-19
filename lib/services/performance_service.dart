import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'logger_service.dart';
import 'monitoring_service.dart';

/// Сервис для оптимизации производительности приложения
class PerformanceService {
  factory PerformanceService() => _instance;
  PerformanceService._internal();
  static final PerformanceService _instance = PerformanceService._internal();

  final LoggerService _logger = LoggerService();
  final MonitoringService _monitoring = MonitoringService();

  final Map<String, Timer> _debounceTimers = {};
  final Map<String, Timer> _throttleTimers = {};
  final Map<String, bool> _throttleFlags = {};

  // Кэш для часто используемых данных
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);

  // Очередь для тяжелых операций
  final Queue<Future<void> Function()> _heavyOperationsQueue = Queue();
  bool _isProcessingQueue = false;

  // Настройки производительности
  int _maxConcurrentOperations = 3;
  int _currentOperations = 0;
  final Queue<Future<void> Function()> _operationQueue = Queue();

  /// Инициализация сервиса производительности
  void initialize() {
    _logger.info('Initializing performance service');
    _startCacheCleanup();
    _startQueueProcessor();
  }

  /// Дебаунс функция - выполняется только после паузы в вызовах
  void debounce(
    String key,
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(delay, () {
      callback();
      _debounceTimers.remove(key);
    });
  }

  /// Троттлинг функции - выполняется не чаще указанного интервала
  void throttle(
    String key,
    VoidCallback callback, {
    Duration interval = const Duration(milliseconds: 100),
  }) {
    if (_throttleFlags[key] ?? false) return;

    _throttleFlags[key] = true;
    callback();

    _throttleTimers[key]?.cancel();
    _throttleTimers[key] = Timer(interval, () {
      _throttleFlags[key] = false;
      _throttleTimers.remove(key);
    });
  }

  /// Кэширование результата функции
  Future<T> cache<T>(
    String key,
    Future<T> Function() computation, {
    Duration? expiration,
  }) async {
    final now = DateTime.now();
    final exp = expiration ?? _cacheExpiration;

    // Проверяем кэш
    if (_cache.containsKey(key) && _cacheTimestamps.containsKey(key)) {
      final cacheTime = _cacheTimestamps[key]!;
      if (now.difference(cacheTime) < exp) {
        _logger.debug('Cache hit for key: $key', tag: 'PERFORMANCE');
        return _cache[key] as T;
      } else {
        // Кэш истек
        _cache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }

    // Вычисляем и кэшируем результат
    _logger.debug('Cache miss for key: $key', tag: 'PERFORMANCE');
    final result = await computation();
    _cache[key] = result;
    _cacheTimestamps[key] = now;

    return result;
  }

  /// Очистка кэша
  void clearCache({String? key}) {
    if (key != null) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      _logger.debug('Cleared cache for key: $key', tag: 'PERFORMANCE');
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
      _logger.info('Cleared all cache', tag: 'PERFORMANCE');
    }
  }

  /// Получение статистики кэша
  Map<String, dynamic> getCacheStats() => {
        'size': _cache.length,
        'keys': _cache.keys.toList(),
        'hitRate': _calculateCacheHitRate(),
      };

  /// Выполнение операции с ограничением количества одновременных операций
  Future<T> executeWithLimit<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    if (_currentOperations >= _maxConcurrentOperations) {
      // Добавляем в очередь
      final completer = Completer<T>();
      _operationQueue.add(() async {
        try {
          final result = await operation();
          completer.complete(result);
        } catch (e) {
          completer.completeError(e);
        }
      });
      return completer.future;
    }

    _currentOperations++;
    final name =
        operationName ?? 'operation_${DateTime.now().millisecondsSinceEpoch}';

    try {
      _monitoring.startOperation(name);
      final result = await operation();
      _monitoring.endOperation(name);
      return result;
    } finally {
      _currentOperations--;
      _processOperationQueue();
    }
  }

  /// Добавление тяжелой операции в очередь
  void queueHeavyOperation(Future<void> Function() operation) {
    _heavyOperationsQueue.add(operation);
    _logger.debug('Queued heavy operation', tag: 'PERFORMANCE');
  }

  /// Выполнение операции в изоляте
  Future<T> executeInIsolate<T>(T Function() computation) async {
    final name = 'isolate_${DateTime.now().millisecondsSinceEpoch}';
    _monitoring.startOperation(name);

    try {
      final result = await compute(computation, null);
      _monitoring.endOperation(name);
      return result;
    } catch (e) {
      _monitoring.endOperation(name);
      rethrow;
    }
  }

  /// Оптимизация изображений
  Future<Uint8List> optimizeImage(
    Uint8List imageData, {
    int? maxWidth,
    int? maxHeight,
    int quality = 85,
  }) async =>
      executeInIsolate(() {
        // Здесь должна быть логика оптимизации изображений
        // Для примера возвращаем исходные данные
        return imageData;
      });

  /// Ленивая загрузка данных
  Future<List<T>> lazyLoad<T>({
    required Future<List<T>> Function(int offset, int limit) loader,
    int limit = 20,
    int initialOffset = 0,
  }) async {
    final key = 'lazy_load_${T.toString()}_${initialOffset}_$limit';

    return cache(key, () async => loader(initialOffset, limit));
  }

  /// Предзагрузка данных
  Future<void> preloadData<T>(List<Future<T> Function()> loaders) async {
    final futures = loaders.map(executeWithLimit);
    await Future.wait(futures);
    _logger.info('Preloaded ${loaders.length} data items', tag: 'PERFORMANCE');
  }

  /// Оптимизация списков
  List<T> optimizeList<T>(List<T> list, {int? maxItems}) {
    if (maxItems != null && list.length > maxItems) {
      _logger.debug(
        'Optimized list from ${list.length} to $maxItems items',
        tag: 'PERFORMANCE',
      );
      return list.take(maxItems).toList();
    }
    return list;
  }

  /// Оптимизация строк
  String optimizeString(String text, {int? maxLength}) {
    if (maxLength != null && text.length > maxLength) {
      return '${text.substring(0, maxLength)}...';
    }
    return text;
  }

  /// Оптимизация памяти
  void optimizeMemory() {
    _logger.info('Starting memory optimization', tag: 'PERFORMANCE');

    // Очищаем старый кэш
    _cleanupExpiredCache();

    // Очищаем завершенные таймеры
    _debounceTimers.removeWhere((key, timer) => !timer.isActive);
    _throttleTimers.removeWhere((key, timer) => !timer.isActive);

    // Принудительная сборка мусора (если доступна)
    if (kDebugMode) {
      // В debug режиме можно принудительно вызвать сборку мусора
      _logger.debug('Memory optimization completed', tag: 'PERFORMANCE');
    }
  }

  /// Получение статистики производительности
  Map<String, dynamic> getPerformanceStats() => {
        'cache': getCacheStats(),
        'operations': {
          'current': _currentOperations,
          'max': _maxConcurrentOperations,
          'queued': _operationQueue.length,
        },
        'heavyOperations': {
          'queued': _heavyOperationsQueue.length,
          'processing': _isProcessingQueue,
        },
        'timers': {
          'debounce': _debounceTimers.length,
          'throttle': _throttleTimers.length,
        },
      };

  /// Настройка параметров производительности
  void configure({
    int? maxConcurrentOperations,
    Duration? cacheExpiration,
  }) {
    if (maxConcurrentOperations != null) {
      _maxConcurrentOperations = maxConcurrentOperations;
      _logger.info(
        'Set max concurrent operations to $maxConcurrentOperations',
        tag: 'PERFORMANCE',
      );
    }

    if (cacheExpiration != null) {
      _cacheExpiration = cacheExpiration;
      _logger.info(
        'Set cache expiration to ${cacheExpiration.inMinutes} minutes',
        tag: 'PERFORMANCE',
      );
    }
  }

  /// Очистка ресурсов
  void dispose() {
    _logger.info('Disposing performance service', tag: 'PERFORMANCE');

    // Отменяем все таймеры
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    for (final timer in _throttleTimers.values) {
      timer.cancel();
    }

    _debounceTimers.clear();
    _throttleTimers.clear();
    _throttleFlags.clear();
    _cache.clear();
    _cacheTimestamps.clear();
    _heavyOperationsQueue.clear();
    _operationQueue.clear();
  }

  // Приватные методы

  void _startCacheCleanup() {
    Timer.periodic(const Duration(minutes: 1), (_) {
      _cleanupExpiredCache();
    });
  }

  void _startQueueProcessor() {
    Timer.periodic(const Duration(seconds: 1), (_) {
      _processHeavyOperationsQueue();
    });
  }

  void _cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiration) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      _logger.debug(
        'Cleaned up ${expiredKeys.length} expired cache entries',
        tag: 'PERFORMANCE',
      );
    }
  }

  void _processHeavyOperationsQueue() {
    if (_isProcessingQueue || _heavyOperationsQueue.isEmpty) return;

    _isProcessingQueue = true;
    final operation = _heavyOperationsQueue.removeFirst();

    operation().then((_) {
      _isProcessingQueue = false;
    }).catchError((e) {
      _logger.error('Heavy operation failed', tag: 'PERFORMANCE', error: e);
      _isProcessingQueue = false;
    });
  }

  void _processOperationQueue() {
    if (_operationQueue.isEmpty ||
        _currentOperations >= _maxConcurrentOperations) {
      return;
    }

    final operation = _operationQueue.removeFirst();
    _currentOperations++;

    operation().then((_) {
      _currentOperations--;
      _processOperationQueue();
    }).catchError((e) {
      _logger.error('Queued operation failed', tag: 'PERFORMANCE', error: e);
      _currentOperations--;
      _processOperationQueue();
    });
  }

  double _calculateCacheHitRate() {
    // Упрощенный расчет hit rate
    // В реальном приложении нужно отслеживать количество попаданий и промахов
    return _cache.isNotEmpty ? 0.8 : 0.0;
  }
}

/// Расширение для Future с оптимизацией производительности
extension PerformanceFutureExtension<T> on Future<T> {
  /// Выполнить с ограничением количества одновременных операций
  Future<T> withConcurrencyLimit({String? operationName}) =>
      PerformanceService()
          .executeWithLimit(() => this, operationName: operationName);

  /// Выполнить в изоляте
  Future<T> inIsolate() => PerformanceService().executeInIsolate(() => this);

  /// Кэшировать результат
  Future<T> cached(String key, {Duration? expiration}) =>
      PerformanceService().cache(key, () => this, expiration: expiration);
}

/// Расширение для List с оптимизацией
extension PerformanceListExtension<T> on List<T> {
  /// Оптимизировать список
  List<T> optimized({int? maxItems}) =>
      PerformanceService().optimizeList(this, maxItems: maxItems);
}

/// Расширение для String с оптимизацией
extension PerformanceStringExtension on String {
  /// Оптимизировать строку
  String optimized({int? maxLength}) =>
      PerformanceService().optimizeString(this, maxLength: maxLength);
}
