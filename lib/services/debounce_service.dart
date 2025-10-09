import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Сервис для debounce операций
class DebounceService {
  factory DebounceService() => _instance;
  DebounceService._internal();
  static final DebounceService _instance = DebounceService._internal();

  final Map<String, Timer> _timers = {};

  /// Выполнить операцию с задержкой
  void debounce(
    String key,
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 500),
  }) {
    // Отменяем предыдущий таймер, если он существует
    _timers[key]?.cancel();
    
    // Создаем новый таймер
    _timers[key] = Timer(delay, () {
      callback();
      _timers.remove(key);
    });
  }

  /// Выполнить операцию с задержкой и возвратом Future
  Future<T> debounceFuture<T>(
    String key,
    Future<T> Function() callback, {
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    // Отменяем предыдущий таймер, если он существует
    _timers[key]?.cancel();
    
    final completer = Completer<T>();
    
    _timers[key] = Timer(delay, () async {
      try {
        final result = await callback();
        completer.complete(result);
      } on Exception catch (e) {
        completer.completeError(e);
      } finally {
        _timers.remove(key);
      }
    });
    
    return completer.future;
  }

  /// Отменить операцию
  void cancel(String key) {
    _timers[key]?.cancel();
    _timers.remove(key);
  }

  /// Отменить все операции
  void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  /// Проверить, есть ли активная операция
  bool isActive(String key) => _timers.containsKey(key);

  /// Получить количество активных операций
  int get activeCount => _timers.length;
}

/// Провайдер для DebounceService
final debounceServiceProvider = Provider<DebounceService>((ref) => DebounceService());
