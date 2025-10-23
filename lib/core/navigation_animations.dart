import 'package:flutter/material.dart';

/// Анимации переходов для улучшения UX навигации
class NavigationAnimations {
  /// Стандартная анимация перехода с масштабированием
  static Route<T> createScaleRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) =>
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final scaleAnimation = Tween<double>(
            begin: 0,
            end: 1,
          ).animate(CurvedAnimation(parent: animation, curve: curve));

          final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: animation,
              curve: Interval(0, 0.8, curve: curve),
            ),
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },
      );

  /// Анимация перехода с движением снизу вверх
  static Route<T> createSlideUpRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) =>
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve));

          final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: animation,
              curve: Interval(0, 0.8, curve: curve),
            ),
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(position: slideAnimation, child: child),
          );
        },
      );

  /// Анимация перехода с движением справа налево
  static Route<T> createSlideRightRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) =>
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slideAnimation = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve));

          final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: animation,
              curve: Interval(0, 0.8, curve: curve),
            ),
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(position: slideAnimation, child: child),
          );
        },
      );

  /// Анимация перехода с поворотом
  static Route<T> createRotationRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOut,
  }) =>
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final rotationAnimation = Tween<double>(
            begin: 0,
            end: 1,
          ).animate(CurvedAnimation(parent: animation, curve: curve));

          final scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: animation,
              curve: Interval(0, 0.8, curve: curve),
            ),
          );

          return RotationTransition(
            turns: rotationAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },
      );

  /// Анимация перехода с эффектом куба
  static Route<T> createCubeRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeInOut,
  }) =>
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final rotationAnimation = Tween<double>(
            begin: 0,
            end: 1,
          ).animate(CurvedAnimation(parent: animation, curve: curve));

          return Transform(
            alignment: Alignment.centerRight,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(
                  rotationAnimation.value * 1.5708), // 90 градусов в радианах
            child: child,
          );
        },
      );

  /// Анимация перехода с эффектом веера
  static Route<T> createFanRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOut,
  }) =>
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final rotationAnimation = Tween<double>(
            begin: 0,
            end: 1,
          ).animate(CurvedAnimation(parent: animation, curve: curve));

          return Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(-rotationAnimation.value * 1.5708),
            child: child,
          );
        },
      );

  /// Анимация перехода с эффектом зума
  static Route<T> createZoomRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) =>
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final scaleAnimation = Tween<double>(
            begin: 0,
            end: 1,
          ).animate(CurvedAnimation(parent: animation, curve: curve));

          final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: animation,
              curve: Interval(0, 0.6, curve: curve),
            ),
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },
      );

  /// Анимация перехода с эффектом волны
  static Route<T> createWaveRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 600),
    Curve curve = Curves.easeInOut,
  }) =>
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: animation, curve: Curves.elasticOut));

          final scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
            CurvedAnimation(
              parent: animation,
              curve: Interval(0, 0.8, curve: curve),
            ),
          );

          return SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },
      );
}

/// Расширения для удобного использования анимаций
extension NavigationAnimationsExtension on NavigatorState {
  /// Переход с анимацией масштабирования
  Future<T?> pushWithScale<T extends Object?>(Widget page) =>
      push<T>(NavigationAnimations.createScaleRoute(page));

  /// Переход с анимацией движения снизу вверх
  Future<T?> pushWithSlideUp<T extends Object?>(Widget page) =>
      push<T>(NavigationAnimations.createSlideUpRoute(page));

  /// Переход с анимацией движения справа налево
  Future<T?> pushWithSlideRight<T extends Object?>(Widget page) =>
      push<T>(NavigationAnimations.createSlideRightRoute(page));

  /// Переход с анимацией поворота
  Future<T?> pushWithRotation<T extends Object?>(Widget page) =>
      push<T>(NavigationAnimations.createRotationRoute(page));

  /// Переход с анимацией куба
  Future<T?> pushWithCube<T extends Object?>(Widget page) =>
      push<T>(NavigationAnimations.createCubeRoute(page));

  /// Переход с анимацией веера
  Future<T?> pushWithFan<T extends Object?>(Widget page) =>
      push<T>(NavigationAnimations.createFanRoute(page));

  /// Переход с анимацией зума
  Future<T?> pushWithZoom<T extends Object?>(Widget page) =>
      push<T>(NavigationAnimations.createZoomRoute(page));

  /// Переход с анимацией волны
  Future<T?> pushWithWave<T extends Object?>(Widget page) =>
      push<T>(NavigationAnimations.createWaveRoute(page));
}

/// Виджет для поддержки жестов свайп назад
class SwipeBackGestureDetector extends StatelessWidget {
  const SwipeBackGestureDetector({
    super.key,
    required this.child,
    this.onSwipeBack,
    this.threshold = 50.0,
  });
  final Widget child;
  final VoidCallback? onSwipeBack;
  final double threshold;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
            // Свайп вправо - возврат назад
            if (details.primaryVelocity! > threshold) {
              if (onSwipeBack != null) {
                onSwipeBack!();
              } else {
                Navigator.of(context).pop();
              }
            }
          }
        },
        child: child,
      );
}

/// Виджет для поддержки жестов свайп вниз (закрытие модальных окон)
class SwipeDownGestureDetector extends StatelessWidget {
  const SwipeDownGestureDetector({
    super.key,
    required this.child,
    this.onSwipeDown,
    this.threshold = 50.0,
  });
  final Widget child;
  final VoidCallback? onSwipeDown;
  final double threshold;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
            // Свайп вниз - закрытие
            if (details.primaryVelocity! > threshold) {
              if (onSwipeDown != null) {
                onSwipeDown!();
              } else {
                Navigator.of(context).pop();
              }
            }
          }
        },
        child: child,
      );
}
