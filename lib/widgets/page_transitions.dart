import 'package:flutter/material.dart';

/// Анимации переходов между экранами в стиле Material Design 3
class PageTransitions {
  /// Стандартный переход с Material 3 анимацией
  static Widget slideTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    Offset begin = const Offset(1, 0),
    Offset end = Offset.zero,
  }) =>
      SlideTransition(
        position: Tween<Offset>(
          begin: begin,
          end: end,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          ),
        ),
        child: child,
      );

  /// Переход с масштабированием
  static Widget scaleTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    double begin = 0.8,
    double end = 1.0,
  }) =>
      ScaleTransition(
        scale: Tween<double>(
          begin: begin,
          end: end,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          ),
        ),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );

  /// Переход с поворотом
  static Widget rotationTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    double begin = 0.0,
    double end = 1.0,
  }) =>
      RotationTransition(
        turns: Tween<double>(
          begin: begin,
          end: end,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          ),
        ),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );

  /// Переход с выдвижением снизу
  static Widget slideUpTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) =>
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          ),
        ),
        child: child,
      );

  /// Переход с выдвижением сверху
  static Widget slideDownTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) =>
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          ),
        ),
        child: child,
      );

  /// Переход с выдвижением слева
  static Widget slideLeftTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) =>
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          ),
        ),
        child: child,
      );

  /// Переход с выдвижением справа
  static Widget slideRightTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) =>
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          ),
        ),
        child: child,
      );

  /// Переход с разворотом
  static Widget flipTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) =>
      AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final isHalfway = animation.value >= 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(animation.value * 3.14159),
            child: isHalfway
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.14159),
                    child: child,
                  )
                : child,
          );
        },
        child: child,
      );

  /// Переход с зумом и поворотом
  static Widget zoomRotateTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) =>
      AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scale(animation.value)
            ..rotateZ(animation.value * 0.1),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
        child: child,
      );
}

/// Кастомный PageRouteBuilder с различными анимациями
class CustomPageRoute<T> extends PageRouteBuilder<T> {
  CustomPageRoute({
    required this.child,
    this.transitionType = PageTransitionType.slide,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCubic,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            switch (transitionType) {
              case PageTransitionType.slide:
                return PageTransitions.slideTransition(
                  context: context,
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  child: child,
                );
              case PageTransitionType.scale:
                return PageTransitions.scaleTransition(
                  context: context,
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  child: child,
                );
              case PageTransitionType.rotation:
                return PageTransitions.rotationTransition(
                  context: context,
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  child: child,
                );
              case PageTransitionType.slideUp:
                return PageTransitions.slideUpTransition(
                  context: context,
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  child: child,
                );
              case PageTransitionType.slideDown:
                return PageTransitions.slideDownTransition(
                  context: context,
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  child: child,
                );
              case PageTransitionType.slideLeft:
                return PageTransitions.slideLeftTransition(
                  context: context,
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  child: child,
                );
              case PageTransitionType.slideRight:
                return PageTransitions.slideRightTransition(
                  context: context,
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  child: child,
                );
              case PageTransitionType.flip:
                return PageTransitions.flipTransition(
                  context: context,
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  child: child,
                );
              case PageTransitionType.zoomRotate:
                return PageTransitions.zoomRotateTransition(
                  context: context,
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  child: child,
                );
              case PageTransitionType.fade:
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: curve,
                  ),
                  child: child,
                );
            }
          },
        );
  final Widget child;
  final PageTransitionType transitionType;
  final Duration duration;
  final Curve curve;
}

/// Типы переходов между страницами
enum PageTransitionType {
  slide,
  scale,
  rotation,
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  flip,
  zoomRotate,
  fade,
}

/// Расширение для Navigator с кастомными переходами
extension CustomNavigator on NavigatorState {
  /// Переход с кастомной анимацией
  Future<T?> pushWithTransition<T extends Object?>(
    Widget page, {
    PageTransitionType transitionType = PageTransitionType.slide,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOutCubic,
  }) =>
      push<T>(
        CustomPageRoute<T>(
          child: page,
          transitionType: transitionType,
          duration: duration,
          curve: curve,
        ),
      );

  /// Замена с кастомной анимацией
  Future<T?> pushReplacementWithTransition<T extends Object?, TO extends Object?>(
    Widget page, {
    PageTransitionType transitionType = PageTransitionType.slide,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOutCubic,
    TO? result,
  }) =>
      pushReplacement<T, TO>(
        CustomPageRoute<T>(
          child: page,
          transitionType: transitionType,
          duration: duration,
          curve: curve,
        ),
        result: result,
      );

  /// Переход с очисткой стека и кастомной анимацией
  Future<T?> pushAndRemoveUntilWithTransition<T extends Object?>(
    Widget page, {
    PageTransitionType transitionType = PageTransitionType.slide,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOutCubic,
    bool Function(Route<dynamic>)? predicate,
  }) =>
      pushAndRemoveUntil<T>(
        CustomPageRoute<T>(
          child: page,
          transitionType: transitionType,
          duration: duration,
          curve: curve,
        ),
        predicate ?? (route) => false,
      );
}

/// Виджет для анимированного появления контента
class AnimatedContent extends StatefulWidget {
  const AnimatedContent({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCubic,
    this.animationType = AnimationType.fadeIn,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final AnimationType animationType;

  @override
  State<AnimatedContent> createState() => _AnimatedContentState();
}

class _AnimatedContentState extends State<AnimatedContent> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    // Запускаем анимацию с задержкой
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.animationType) {
      case AnimationType.fadeIn:
        return FadeTransition(
          opacity: _animation,
          child: widget.child,
        );
      case AnimationType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(_animation),
          child: FadeTransition(
            opacity: _animation,
            child: widget.child,
          ),
        );
      case AnimationType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(_animation),
          child: FadeTransition(
            opacity: _animation,
            child: widget.child,
          ),
        );
      case AnimationType.scale:
        return ScaleTransition(
          scale: _animation,
          child: FadeTransition(
            opacity: _animation,
            child: widget.child,
          ),
        );
    }
  }
}

/// Типы анимации для контента
enum AnimationType {
  fadeIn,
  slideUp,
  slideDown,
  scale,
}
