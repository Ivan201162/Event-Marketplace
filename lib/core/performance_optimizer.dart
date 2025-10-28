import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Сервис для оптимизации производительности приложения
class PerformanceOptimizer {
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();
  static final PerformanceOptimizer _instance =
      PerformanceOptimizer._internal();

  final Map<String, DateTime> _lastRequestTimes = {};
  final Map<String, int> _requestCounts = {};
  final Map<String, Timer> _debounceTimers = {};

  // Кэш для изображений
  final Map<String, ImageProvider> _imageCache = {};

  // Ограничения для предотвращения спама
  static const int _maxRequestsPerMinute = 30;
  static const Duration _requestCooldown = Duration(seconds: 2);

  /// Инициализация оптимизатора производительности
  static Future<void> initialize() async {
    // Настройка глобального обработчика ошибок
    FlutterError.onError = (details) {
      developer.log(
        'Flutter Error: ${details.exception}',
        name: 'PERFORMANCE',
        error: details.exception,
        stackTrace: details.stack,
      );

      // Отправляем в Crashlytics в продакшене
      if (!kDebugMode) {
        try {
          // FirebaseCrashlytics.instance.recordFlutterFatalError(details);
          developer.log('Fatal Error: ${details.exception}', name: 'CRASH');
        } catch (e) {
          developer.log('Failed to record crash: $e', name: 'CRASH');
        }
      }
    };

    // Обработчик ошибок в изолятах
    PlatformDispatcher.instance.onError = (error, stack) {
      developer.log('Platform Error: $error',
          name: 'PERFORMANCE', error: error, stackTrace: stack,);

      if (!kDebugMode) {
        try {
          // FirebaseCrashlytics.instance.recordError(error, stack);
          developer.log('Platform Error: $error', name: 'CRASH');
        } catch (e) {
          developer.log('Failed to record platform error: $e', name: 'CRASH');
        }
      }

      return true;
    };

    // Настройка производительности для мобильных устройств
    if (!kIsWeb) {
      // Включаем аппаратное ускорение
      // WidgetsBinding.instance.renderView.configuration =
      //     WidgetsBinding.instance.renderView.configuration.copyWith(
      //   devicePixelRatio: WidgetsBinding.instance.renderView.configuration.devicePixelRatio,
      // );
    }
  }

  /// Проверка лимита запросов
  bool canMakeRequest(String requestType) {
    final now = DateTime.now();
    final lastRequest = _lastRequestTimes[requestType];
    final requestCount = _requestCounts[requestType] ?? 0;

    // Сброс счетчика каждую минуту
    if (lastRequest != null && now.difference(lastRequest).inMinutes >= 1) {
      _requestCounts[requestType] = 0;
    }

    // Проверка лимита
    if (requestCount >= _maxRequestsPerMinute) {
      developer.log('Request limit exceeded for $requestType',
          name: 'PERFORMANCE',);
      return false;
    }

    // Проверка кулдауна
    if (lastRequest != null && now.difference(lastRequest) < _requestCooldown) {
      return false;
    }

    // Обновляем счетчики
    _lastRequestTimes[requestType] = now;
    _requestCounts[requestType] = requestCount + 1;

    return true;
  }

  /// Дебаунс для предотвращения частых вызовов
  void debounce(
    String key,
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(delay, callback);
  }

  /// Кэширование изображений
  ImageProvider? getCachedImage(String url) => _imageCache[url];

  /// Добавление изображения в кэш
  void cacheImage(String url, ImageProvider provider) {
    _imageCache[url] = provider;

    // Ограничиваем размер кэша
    if (_imageCache.length > 100) {
      final keys = _imageCache.keys.toList();
      for (var i = 0; i < 20; i++) {
        _imageCache.remove(keys[i]);
      }
    }
  }

  /// Очистка кэша
  void clearCache() {
    _imageCache.clear();
    _lastRequestTimes.clear();
    _requestCounts.clear();

    // Отменяем все таймеры
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
  }

  /// Оптимизация списков для больших данных
  List<T> optimizeList<T>(List<T> list, {int? maxItems}) {
    if (maxItems != null && list.length > maxItems) {
      return list.take(maxItems).toList();
    }
    return list;
  }

  /// Измерение производительности
  Future<T> measurePerformance<T>(
      String operationName, Future<T> Function() operation,) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();
      stopwatch.stop();

      developer.log(
        'Performance: $operationName took ${stopwatch.elapsedMilliseconds}ms',
        name: 'PERFORMANCE',
      );

      return result;
    } catch (e) {
      stopwatch.stop();

      developer.log(
        'Performance Error: $operationName failed after ${stopwatch.elapsedMilliseconds}ms',
        name: 'PERFORMANCE',
        error: e,
      );

      rethrow;
    }
  }

  /// Оптимизация Firebase запросов
  dynamic optimizeFirebaseQuery(dynamic query,
      {int? limit, bool useCache = true,}) {
    // Добавляем лимит если не указан
    if (limit != null && query != null) {
      // query = query.limit(limit);
    }

    return query;
  }

  /// Проверка памяти
  void checkMemoryUsage() {
    if (kDebugMode) {
      developer.log('Memory: Image cache size: ${_imageCache.length}',
          name: 'PERFORMANCE',);
    }
  }
}

/// Расширение для Future с оптимизацией
extension PerformanceFutureExtension<T> on Future<T> {
  /// Выполнить с измерением производительности
  Future<T> withPerformanceMeasurement(String operationName) =>
      PerformanceOptimizer().measurePerformance(operationName, () => this);

  /// Выполнить с дебаунсом
  Future<T> withDebounce(String key,
      {Duration delay = const Duration(milliseconds: 300),}) {
    final completer = Completer<T>();

    PerformanceOptimizer().debounce(key, () {
      then(completer.complete).catchError(completer.completeError);
    }, delay: delay,);

    return completer.future;
  }
}

/// Расширение для List с оптимизацией
extension PerformanceListExtension<T> on List<T> {
  /// Оптимизировать список
  List<T> optimized({int? maxItems}) =>
      PerformanceOptimizer().optimizeList(this, maxItems: maxItems);
}

/// Расширение для Query с оптимизацией
extension PerformanceQueryExtension on dynamic {
  /// Оптимизировать Firebase запрос
  dynamic optimized({int? limit, bool useCache = true}) =>
      PerformanceOptimizer()
          .optimizeFirebaseQuery(this, limit: limit, useCache: useCache);
}
