import 'package:flutter/material.dart';

/// Сервис для управления анимациями в приложении
class AnimationService {
  static final Map<String, AnimationController> _controllers = {};
  static final Map<String, Animation<double>> _animations = {};

  /// Создать контроллер анимации
  static AnimationController createController({
    required String key,
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 300),
    Duration? reverseDuration,
  }) {
    if (_controllers.containsKey(key)) {
      _controllers[key]!.dispose();
    }

    final controller = AnimationController(
      duration: duration,
      reverseDuration: reverseDuration,
      vsync: vsync,
    );

    _controllers[key] = controller;
    return controller;
  }

  /// Создать анимацию
  static Animation<double> createAnimation({
    required String key,
    required AnimationController controller,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.easeInOut,
  }) {
    final animation = Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));

    _animations[key] = animation;
    return animation;
  }

  /// Получить контроллер анимации
  static AnimationController? getController(String key) {
    return _controllers[key];
  }

  /// Получить анимацию
  static Animation<double>? getAnimation(String key) {
    return _animations[key];
  }

  /// Запустить анимацию
  static Future<void> forward(String key) async {
    final controller = _controllers[key];
    if (controller != null && !controller.isAnimating) {
      await controller.forward();
    }
  }

  /// Запустить анимацию в обратном направлении
  static Future<void> reverse(String key) async {
    final controller = _controllers[key];
    if (controller != null && !controller.isAnimating) {
      await controller.reverse();
    }
  }

  /// Переключить анимацию
  static Future<void> toggle(String key) async {
    final controller = _controllers[key];
    if (controller != null) {
      if (controller.isCompleted) {
        await controller.reverse();
      } else {
        await controller.forward();
      }
    }
  }

  /// Сбросить анимацию
  static void reset(String key) {
    final controller = _controllers[key];
    if (controller != null) {
      controller.reset();
    }
  }

  /// Освободить ресурсы анимации
  static void dispose(String key) {
    final controller = _controllers[key];
    if (controller != null) {
      controller.dispose();
      _controllers.remove(key);
      _animations.remove(key);
    }
  }

  /// Освободить все ресурсы
  static void disposeAll() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _animations.clear();
  }

  /// Создать анимацию появления
  static Animation<double> createFadeIn({
    required String key,
    required AnimationController controller,
    Duration delay = Duration.zero,
  }) {
    return createAnimation(
      key: key,
      controller: controller,
      begin: 0.0,
      end: 1.0,
      curve: Curves.easeIn,
    );
  }

  /// Создать анимацию исчезновения
  static Animation<double> createFadeOut({
    required String key,
    required AnimationController controller,
  }) {
    return createAnimation(
      key: key,
      controller: controller,
      begin: 1.0,
      end: 0.0,
      curve: Curves.easeOut,
    );
  }

  /// Создать анимацию масштабирования
  static Animation<double> createScale({
    required String key,
    required AnimationController controller,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.elasticOut,
  }) {
    return createAnimation(
      key: key,
      controller: controller,
      begin: begin,
      end: end,
      curve: curve,
    );
  }

  /// Создать анимацию слайда
  static Animation<Offset> createSlide({
    required String key,
    required AnimationController controller,
    Offset begin = const Offset(0.0, 1.0),
    Offset end = Offset.zero,
    Curve curve = Curves.easeOutCubic,
  }) {
    final animation = Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));

    _animations[key] = animation as Animation<double>;
    return animation;
  }

  /// Создать анимацию поворота
  static Animation<double> createRotation({
    required String key,
    required AnimationController controller,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.easeInOut,
  }) {
    return createAnimation(
      key: key,
      controller: controller,
      begin: begin,
      end: end,
      curve: curve,
    );
  }

  /// Создать анимацию блеска (shimmer)
  static Animation<double> createShimmer({
    required String key,
    required AnimationController controller,
    double begin = -1.0,
    double end = 2.0,
    Curve curve = Curves.easeInOut,
  }) {
    return createAnimation(
      key: key,
      controller: controller,
      begin: begin,
      end: end,
      curve: curve,
    );
  }

  /// Создать анимацию пульсации
  static Animation<double> createPulse({
    required String key,
    required AnimationController controller,
    double begin = 0.8,
    double end = 1.2,
    Curve curve = Curves.easeInOut,
  }) {
    return createAnimation(
      key: key,
      controller: controller,
      begin: begin,
      end: end,
      curve: curve,
    );
  }

  /// Создать анимацию качания
  static Animation<double> createWiggle({
    required String key,
    required AnimationController controller,
    double begin = -0.1,
    double end = 0.1,
    Curve curve = Curves.elasticInOut,
  }) {
    return createAnimation(
      key: key,
      controller: controller,
      begin: begin,
      end: end,
      curve: curve,
    );
  }

  /// Создать анимацию подпрыгивания
  static Animation<double> createBounce({
    required String key,
    required AnimationController controller,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.bounceOut,
  }) {
    return createAnimation(
      key: key,
      controller: controller,
      begin: begin,
      end: end,
      curve: curve,
    );
  }

  /// Создать анимацию эластичности
  static Animation<double> createElastic({
    required String key,
    required AnimationController controller,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.elasticOut,
  }) {
    return createAnimation(
      key: key,
      controller: controller,
      begin: begin,
      end: end,
      curve: curve,
    );
  }

  /// Создать анимацию затухания
  static Animation<double> createFade({
    required String key,
    required AnimationController controller,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.easeInOut,
  }) {
    return createAnimation(
      key: key,
      controller: controller,
      begin: begin,
      end: end,
      curve: curve,
    );
  }

  /// Создать анимацию с задержкой
  static Future<void> forwardWithDelay(String key, Duration delay) async {
    await Future.delayed(delay);
    await forward(key);
  }

  /// Создать последовательность анимаций
  static Future<void> playSequence(List<String> keys, {Duration delay = const Duration(milliseconds: 100)}) async {
    for (final key in keys) {
      await forward(key);
      await Future.delayed(delay);
    }
  }

  /// Создать анимацию с повторением
  static void repeat(String key, {int? count}) {
    final controller = _controllers[key];
    if (controller != null) {
      controller.repeat(count: count);
    }
  }

  /// Остановить повторение
  static void stopRepeat(String key) {
    final controller = _controllers[key];
    if (controller != null) {
      controller.stop();
    }
  }

  /// Проверить, активна ли анимация
  static bool isAnimating(String key) {
    final controller = _controllers[key];
    return controller?.isAnimating ?? false;
  }

  /// Проверить, завершена ли анимация
  static bool isCompleted(String key) {
    final controller = _controllers[key];
    return controller?.isCompleted ?? false;
  }

  /// Получить статус анимации
  static AnimationStatus? getStatus(String key) {
    final controller = _controllers[key];
    return controller?.status;
  }
}