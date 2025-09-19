import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:page_transition/page_transition.dart';

/// Анимированные переходы между страницами
class AnimatedPageTransitions {
  /// Переход с анимацией скольжения влево
  static PageTransition slideLeftTransition({
    required Widget child,
    required BuildContext context,
    Duration duration = const Duration(milliseconds: 300),
  }) =>
      PageTransition(
        child: child,
        type: PageTransitionType.leftToRight,
        duration: duration,
        reverseDuration: duration,
      );

  /// Переход с анимацией скольжения вправо
  static PageTransition slideRightTransition({
    required Widget child,
    required BuildContext context,
    Duration duration = const Duration(milliseconds: 300),
  }) =>
      PageTransition(
        child: child,
        type: PageTransitionType.rightToLeft,
        duration: duration,
        reverseDuration: duration,
      );

  /// Переход с анимацией появления снизу
  static PageTransition slideUpTransition({
    required Widget child,
    required BuildContext context,
    Duration duration = const Duration(milliseconds: 300),
  }) =>
      PageTransition(
        child: child,
        type: PageTransitionType.bottomToTop,
        duration: duration,
        reverseDuration: duration,
      );

  /// Переход с анимацией масштабирования
  static PageTransition scaleTransition({
    required Widget child,
    required BuildContext context,
    Duration duration = const Duration(milliseconds: 300),
  }) =>
      PageTransition(
        child: child,
        type: PageTransitionType.scale,
        alignment: Alignment.center,
        duration: duration,
        reverseDuration: duration,
      );

  /// Переход с анимацией поворота
  static PageTransition rotateTransition({
    required Widget child,
    required BuildContext context,
    Duration duration = const Duration(milliseconds: 300),
  }) =>
      PageTransition(
        child: child,
        type: PageTransitionType.rotate,
        alignment: Alignment.center,
        duration: duration,
        reverseDuration: duration,
      );

  /// Переход с анимацией затухания
  static PageTransition fadeTransition({
    required Widget child,
    required BuildContext context,
    Duration duration = const Duration(milliseconds: 300),
  }) =>
      PageTransition(
        child: child,
        type: PageTransitionType.fade,
        duration: duration,
        reverseDuration: duration,
      );
}

/// Анимированный виджет для появления элементов
class AnimatedAppearance extends StatelessWidget {
  const AnimatedAppearance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.offset = const Offset(0, 20),
    this.opacity = 0.0,
  });
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final double opacity;

  @override
  Widget build(BuildContext context) => child
      .animate()
      .fadeIn(
        duration: duration,
        delay: delay,
        begin: opacity,
      )
      .slideY(
        duration: duration,
        delay: delay,
        begin: offset.dy / 100,
      )
      .slideX(
        duration: duration,
        delay: delay,
        begin: offset.dx / 100,
      );
}

/// Анимированная кнопка с эффектом нажатия
class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.duration = const Duration(milliseconds: 150),
    this.scale = 0.95,
  });
  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;
  final double scale;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: widget.scale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onPressed?.call();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          ),
        ),
      );
}

/// Анимированная карточка с эффектом наведения
class AnimatedCard extends StatefulWidget {
  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding,
    this.elevation = 2.0,
    this.color,
    this.borderRadius,
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double elevation;
  final Color? color;
  final BorderRadius? borderRadius;

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation + 4.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _elevationAnimation,
        builder: (context, child) => Card(
          margin: widget.margin,
          elevation: _elevationAnimation.value,
          color: widget.color,
          shape: RoundedRectangleBorder(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) => _controller.reverse(),
            onTapCancel: () => _controller.reverse(),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(16),
              child: widget.child,
            ),
          ),
        ),
      );
}

/// Анимированный список с эффектом появления элементов
class AnimatedList extends StatelessWidget {
  const AnimatedList({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 600),
    this.controller,
    this.padding,
  });
  final List<Widget> children;
  final Duration delay;
  final Duration duration;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => ListView.builder(
        controller: controller,
        padding: padding,
        itemCount: children.length,
        itemBuilder: (context, index) => AnimatedAppearance(
          delay: Duration(milliseconds: delay.inMilliseconds * index),
          duration: duration,
          child: children[index],
        ),
      );
}
