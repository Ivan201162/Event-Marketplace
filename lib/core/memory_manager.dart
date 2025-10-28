import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Менеджер памяти для отслеживания и освобождения ресурсов
class MemoryManager {
  factory MemoryManager() => _instance;
  MemoryManager._internal();
  static final MemoryManager _instance = MemoryManager._internal();

  final Set<ChangeNotifier> _trackedNotifiers = {};
  final Set<StreamSubscription<dynamic>> _trackedSubscriptions = {};
  final Set<Timer> _trackedTimers = {};
  final Set<AnimationController> _trackedControllers = {};

  /// Отслеживание ChangeNotifier
  void trackNotifier(ChangeNotifier notifier) {
    _trackedNotifiers.add(notifier);
  }

  /// Отслеживание StreamSubscription
  void trackSubscription(StreamSubscription<dynamic> subscription) {
    _trackedSubscriptions.add(subscription);
  }

  /// Отслеживание Timer
  void trackTimer(Timer timer) {
    _trackedTimers.add(timer);
  }

  /// Отслеживание AnimationController
  void trackController(AnimationController controller) {
    _trackedControllers.add(controller);
  }

  /// Освобождение всех ресурсов
  void disposeAll() {
    // Освобождаем ChangeNotifier
    for (final notifier in _trackedNotifiers) {
      try {
        notifier.dispose();
      } catch (e) {
        developer.log('Error disposing notifier: $e', name: 'MEMORY');
      }
    }
    _trackedNotifiers.clear();

    // Отменяем подписки
    for (final subscription in _trackedSubscriptions) {
      try {
        subscription.cancel();
      } catch (e) {
        developer.log('Error canceling subscription: $e', name: 'MEMORY');
      }
    }
    _trackedSubscriptions.clear();

    // Отменяем таймеры
    for (final timer in _trackedTimers) {
      try {
        timer.cancel();
      } catch (e) {
        developer.log('Error canceling timer: $e', name: 'MEMORY');
      }
    }
    _trackedTimers.clear();

    // Освобождаем контроллеры анимации
    for (final controller in _trackedControllers) {
      try {
        controller.dispose();
      } catch (e) {
        developer.log('Error disposing controller: $e', name: 'MEMORY');
      }
    }
    _trackedControllers.clear();
  }

  /// Проверка утечек памяти
  void checkMemoryLeaks() {
    if (kDebugMode) {
      developer.log(
        'Memory Manager Status:\n'
        'Tracked Notifiers: ${_trackedNotifiers.length}\n'
        'Tracked Subscriptions: ${_trackedSubscriptions.length}\n'
        'Tracked Timers: ${_trackedTimers.length}\n'
        'Tracked Controllers: ${_trackedControllers.length}',
        name: 'MEMORY',
      );
    }
  }

  /// Создание безопасного контроллера с автоматическим отслеживанием
  T createTrackedController<T extends ChangeNotifier>(T Function() factory) {
    final controller = factory();
    trackNotifier(controller);
    return controller;
  }

  /// Создание безопасной подписки с автоматическим отслеживанием
  StreamSubscription<T> createTrackedSubscription<T>(
    Stream<T> stream,
    void Function(T) onData, {
    Function? onError,
    void Function()? onDone,
  }) {
    final subscription =
        stream.listen(onData, onError: onError, onDone: onDone);
    trackSubscription(subscription);
    return subscription;
  }

  /// Создание безопасного таймера с автоматическим отслеживанием
  Timer createTrackedTimer(Duration duration, void Function() callback,
      {bool periodic = false,}) {
    final timer = periodic
        ? Timer.periodic(duration, (_) => callback())
        : Timer(duration, callback);
    trackTimer(timer);
    return timer;
  }
}

/// Миксин для автоматического управления памятью в виджетах
mixin MemoryManagerMixin<T extends StatefulWidget> on State<T> {
  final MemoryManager _memoryManager = MemoryManager();

  /// Создание отслеживаемого контроллера
  T createController<T extends ChangeNotifier>(T Function() factory) {
    final controller = factory();
    _memoryManager.trackNotifier(controller);
    return controller;
  }

  /// Создание отслеживаемой подписки
  StreamSubscription<U> createSubscription<U>(
    Stream<U> stream,
    void Function(U) onData, {
    Function? onError,
    void Function()? onDone,
  }) {
    final subscription =
        stream.listen(onData, onError: onError, onDone: onDone);
    _memoryManager.trackSubscription(subscription);
    return subscription;
  }

  /// Создание отслеживаемого таймера
  Timer createTimer(Duration duration, void Function() callback,
      {bool periodic = false,}) {
    final timer = periodic
        ? Timer.periodic(duration, (_) => callback())
        : Timer(duration, callback);
    _memoryManager.trackTimer(timer);
    return timer;
  }

  @override
  void dispose() {
    _memoryManager.disposeAll();
    super.dispose();
  }
}

/// Расширение для TextEditingController с автоматическим отслеживанием
extension TrackedTextEditingController on TextEditingController {
  /// Создание отслеживаемого TextEditingController
  static TextEditingController tracked() {
    final controller = TextEditingController();
    MemoryManager().trackNotifier(controller);
    return controller;
  }
}

/// Расширение для ScrollController с автоматическим отслеживанием
extension TrackedScrollController on ScrollController {
  /// Создание отслеживаемого ScrollController
  static ScrollController tracked() {
    final controller = ScrollController();
    MemoryManager().trackNotifier(controller);
    return controller;
  }
}

/// Расширение для AnimationController с автоматическим отслеживанием
extension TrackedAnimationController on AnimationController {
  /// Создание отслеживаемого AnimationController
  static AnimationController tracked({
    required TickerProvider vsync,
    Duration? duration,
    Duration? reverseDuration,
    double? value,
    String? debugLabel,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
  }) {
    final controller = AnimationController(
      vsync: vsync,
      duration: duration,
      reverseDuration: reverseDuration,
      value: value,
      debugLabel: debugLabel,
      lowerBound: lowerBound,
      upperBound: upperBound,
      animationBehavior: animationBehavior,
    );
    MemoryManager().trackController(controller);
    return controller;
  }
}
