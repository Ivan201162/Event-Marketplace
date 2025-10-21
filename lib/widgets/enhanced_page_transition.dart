import 'package:flutter/material.dart';
import '../core/navigation_animations.dart';

/// Улучшенные переходы между страницами с поддержкой жестов
class EnhancedPageTransition extends StatefulWidget {
  const EnhancedPageTransition({
    super.key,
    required this.child,
    this.enableSwipeBack = true,
    this.enableSwipeDown = false,
    this.onSwipeBack,
    this.onSwipeDown,
    this.swipeThreshold = 50.0,
  });
  final Widget child;
  final bool enableSwipeBack;
  final bool enableSwipeDown;
  final VoidCallback? onSwipeBack;
  final VoidCallback? onSwipeDown;
  final double swipeThreshold;

  @override
  State<EnhancedPageTransition> createState() => _EnhancedPageTransitionState();
}

class _EnhancedPageTransitionState extends State<EnhancedPageTransition>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );

    if (widget.enableSwipeBack) {
      content = SwipeBackGestureDetector(
        onSwipeBack: widget.onSwipeBack,
        threshold: widget.swipeThreshold,
        child: content,
      );
    }

    if (widget.enableSwipeDown) {
      content = SwipeDownGestureDetector(
        onSwipeDown: widget.onSwipeDown,
        threshold: widget.swipeThreshold,
        child: content,
      );
    }

    return content;
  }
}

/// Виджет для анимированного появления контента
class AnimatedContent extends StatefulWidget {
  const AnimatedContent({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.type = AnimationType.fadeIn,
  });
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final AnimationType type;

  @override
  State<AnimatedContent> createState() => _AnimatedContentState();
}

class _AnimatedContentState extends State<AnimatedContent> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);

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
    switch (widget.type) {
      case AnimationType.fadeIn:
        return FadeTransition(opacity: _animation, child: widget.child);
      case AnimationType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(_animation),
          child: FadeTransition(opacity: _animation, child: widget.child),
        );
      case AnimationType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(_animation),
          child: FadeTransition(opacity: _animation, child: widget.child),
        );
      case AnimationType.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0),
            end: Offset.zero,
          ).animate(_animation),
          child: FadeTransition(opacity: _animation, child: widget.child),
        );
      case AnimationType.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.3, 0),
            end: Offset.zero,
          ).animate(_animation),
          child: FadeTransition(opacity: _animation, child: widget.child),
        );
      case AnimationType.scale:
        return ScaleTransition(
          scale: _animation,
          child: FadeTransition(opacity: _animation, child: widget.child),
        );
      case AnimationType.rotation:
        return RotationTransition(
          turns: _animation,
          child: ScaleTransition(scale: _animation, child: widget.child),
        );
    }
  }
}

/// Типы анимаций
enum AnimationType { fadeIn, slideUp, slideDown, slideLeft, slideRight, scale, rotation }

/// Виджет для анимированного списка
class AnimatedList extends StatefulWidget {
  const AnimatedList({
    super.key,
    required this.children,
    this.itemDelay = const Duration(milliseconds: 100),
    this.itemDuration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.itemType = AnimationType.slideUp,
  });
  final List<Widget> children;
  final Duration itemDelay;
  final Duration itemDuration;
  final Curve curve;
  final AnimationType itemType;

  @override
  State<AnimatedList> createState() => _AnimatedListState();
}

class _AnimatedListState extends State<AnimatedList> {
  @override
  Widget build(BuildContext context) => Column(
        children: widget.children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;

          return AnimatedContent(
            delay: Duration(milliseconds: index * widget.itemDelay.inMilliseconds),
            duration: widget.itemDuration,
            curve: widget.curve,
            type: widget.itemType,
            child: child,
          );
        }).toList(),
      );
}

/// Виджет для анимированной сетки
class AnimatedGrid extends StatefulWidget {
  const AnimatedGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.itemDelay = const Duration(milliseconds: 100),
    this.itemDuration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.itemType = AnimationType.scale,
  });
  final List<Widget> children;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final Duration itemDelay;
  final Duration itemDuration;
  final Curve curve;
  final AnimationType itemType;

  @override
  State<AnimatedGrid> createState() => _AnimatedGridState();
}

class _AnimatedGridState extends State<AnimatedGrid> {
  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          crossAxisSpacing: widget.crossAxisSpacing,
          mainAxisSpacing: widget.mainAxisSpacing,
        ),
        itemCount: widget.children.length,
        itemBuilder: (context, index) => AnimatedContent(
          delay: Duration(milliseconds: index * widget.itemDelay.inMilliseconds),
          duration: widget.itemDuration,
          curve: widget.curve,
          type: widget.itemType,
          child: widget.children[index],
        ),
      );
}

/// Виджет для анимированной кнопки
class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.duration = const Duration(milliseconds: 150),
    this.curve = Curves.easeInOut,
    this.scale = 0.95,
  });
  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;
  final Curve curve;
  final double scale;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: widget.scale,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onPressed,
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
      );
}
