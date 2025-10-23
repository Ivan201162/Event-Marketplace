import 'package:flutter/material.dart';

/// Анимированные переходы между страницами
class AnimatedPageTransitions {
  /// Плавное появление (fade-in)
  static Widget fadeTransition({
    required Widget child,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
  }) =>
      FadeTransition(opacity: animation, child: child);

  /// Слайд слева направо
  static Widget slideFromRight({
    required Widget child,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
  }) =>
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      );

  /// Слайд справа налево
  static Widget slideFromLeft({
    required Widget child,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
  }) =>
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      );

  /// Слайд снизу вверх
  static Widget slideFromBottom({
    required Widget child,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
  }) =>
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      );

  /// Масштабирование
  static Widget scaleTransition({
    required Widget child,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
  }) =>
      ScaleTransition(
        scale: Tween<double>(
          begin: 0,
          end: 1,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      );

  /// Комбинированный переход (fade + scale)
  static Widget fadeScaleTransition({
    required Widget child,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
  }) =>
      FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1,
          ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
          child: child,
        ),
      );

  /// Переход с поворотом
  static Widget rotationTransition({
    required Widget child,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
  }) =>
      RotationTransition(
        turns: Tween<double>(
          begin: 0,
          end: 1,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      );
}

/// Кастомный PageRouteBuilder с анимацией
class AnimatedPageRoute<T> extends PageRouteBuilder<T> {
  AnimatedPageRoute({
    required Widget page,
    PageTransitionType transitionType = PageTransitionType.fade,
    Duration duration = const Duration(milliseconds: 300),
    Duration reverseDuration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              _buildTransition(context, animation, secondaryAnimation, child,
                  transitionType),
        );

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    PageTransitionType transitionType,
  ) {
    switch (transitionType) {
      case PageTransitionType.fade:
        return AnimatedPageTransitions.fadeTransition(
          child: child,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
        );
      case PageTransitionType.slideFromRight:
        return AnimatedPageTransitions.slideFromRight(
          child: child,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
        );
      case PageTransitionType.slideFromLeft:
        return AnimatedPageTransitions.slideFromLeft(
          child: child,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
        );
      case PageTransitionType.slideFromBottom:
        return AnimatedPageTransitions.slideFromBottom(
          child: child,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
        );
      case PageTransitionType.scale:
        return AnimatedPageTransitions.scaleTransition(
          child: child,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
        );
      case PageTransitionType.fadeScale:
        return AnimatedPageTransitions.fadeScaleTransition(
          child: child,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
        );
      case PageTransitionType.rotation:
        return AnimatedPageTransitions.rotationTransition(
          child: child,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
        );
    }
  }
}

/// Типы переходов между страницами
enum PageTransitionType {
  fade,
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  scale,
  fadeScale,
  rotation,
}

/// Виджет для анимированного переключения контента
class AnimatedContentSwitcher extends StatelessWidget {
  const AnimatedContentSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.transitionType = AnimatedSwitcherTransitionType.fade,
  });

  final Widget child;
  final Duration duration;
  final AnimatedSwitcherTransitionType transitionType;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: duration,
        transitionBuilder: (child, animation) {
          switch (transitionType) {
            case AnimatedSwitcherTransitionType.fade:
              return FadeTransition(opacity: animation, child: child);
            case AnimatedSwitcherTransitionType.scale:
              return ScaleTransition(scale: animation, child: child);
            case AnimatedSwitcherTransitionType.slide:
              return SlideTransition(
                position:
                    Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                        .animate(animation),
                child: child,
              );
            case AnimatedSwitcherTransitionType.size:
              return SizeTransition(sizeFactor: animation, child: child);
          }
        },
        child: child,
      );
}

/// Типы переходов для AnimatedSwitcher
enum AnimatedSwitcherTransitionType { fade, scale, slide, size }

/// Виджет для анимированного появления элементов списка
class AnimatedListItem extends StatefulWidget {
  const AnimatedListItem({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
    this.animationType = ListItemAnimationType.fadeInUp,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final ListItemAnimationType animationType;

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

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
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          switch (widget.animationType) {
            case ListItemAnimationType.fadeInUp:
              return Transform.translate(
                offset: Offset(0, 20 * (1 - _animation.value)),
                child: Opacity(opacity: _animation.value, child: widget.child),
              );
            case ListItemAnimationType.fadeInLeft:
              return Transform.translate(
                offset: Offset(-20 * (1 - _animation.value), 0),
                child: Opacity(opacity: _animation.value, child: widget.child),
              );
            case ListItemAnimationType.fadeInRight:
              return Transform.translate(
                offset: Offset(20 * (1 - _animation.value), 0),
                child: Opacity(opacity: _animation.value, child: widget.child),
              );
            case ListItemAnimationType.scaleIn:
              return Transform.scale(
                scale: _animation.value,
                child: Opacity(opacity: _animation.value, child: widget.child),
              );
          }
        },
      );
}

/// Типы анимации для элементов списка
enum ListItemAnimationType { fadeInUp, fadeInLeft, fadeInRight, scaleIn }

/// Виджет для анимированного списка
class AnimatedListWidget extends StatelessWidget {
  const AnimatedListWidget({
    super.key,
    required this.children,
    this.delayBetweenItems = const Duration(milliseconds: 100),
    this.animationType = ListItemAnimationType.fadeInUp,
    this.duration = const Duration(milliseconds: 300),
  });

  final List<Widget> children;
  final Duration delayBetweenItems;
  final ListItemAnimationType animationType;
  final Duration duration;

  @override
  Widget build(BuildContext context) => Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;

          return AnimatedListItem(
            delay: Duration(
                milliseconds: delayBetweenItems.inMilliseconds * index),
            duration: duration,
            animationType: animationType,
            child: child,
          );
        }).toList(),
      );
}
