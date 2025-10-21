import 'package:flutter/material.dart';

/// Виджет для плавного появления с анимацией
class FadeInWidget extends StatefulWidget {
  const FadeInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.easeInOut,
    this.begin = 0.0,
    this.end = 1.0,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double begin;
  final double end;

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: widget.begin,
      end: widget.end,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _animation, child: widget.child);
}

/// Виджет для плавного появления с масштабированием
class ScaleInWidget extends StatefulWidget {
  const ScaleInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.easeInOut,
    this.begin = 0.0,
    this.end = 1.0,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double begin;
  final double end;

  @override
  State<ScaleInWidget> createState() => _ScaleInWidgetState();
}

class _ScaleInWidgetState extends State<ScaleInWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: widget.begin,
      end: widget.end,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(scale: _animation, child: widget.child);
}

/// Виджет для плавного появления с движением
class SlideInWidget extends StatefulWidget {
  const SlideInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.easeInOut,
    this.direction = SlideDirection.fromBottom,
    this.offset = 50.0,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final SlideDirection direction;
  final double offset;

  @override
  State<SlideInWidget> createState() => _SlideInWidgetState();
}

class _SlideInWidgetState extends State<SlideInWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    final beginOffset = _getBeginOffset();
    _animation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _getBeginOffset() {
    switch (widget.direction) {
      case SlideDirection.fromTop:
        return Offset(0, -widget.offset);
      case SlideDirection.fromBottom:
        return Offset(0, widget.offset);
      case SlideDirection.fromLeft:
        return Offset(-widget.offset, 0);
      case SlideDirection.fromRight:
        return Offset(widget.offset, 0);
    }
  }

  @override
  Widget build(BuildContext context) => SlideTransition(position: _animation, child: widget.child);
}

/// Направления для анимации слайда
enum SlideDirection { fromTop, fromBottom, fromLeft, fromRight }

/// Виджет для комбинированной анимации
class AnimatedEntranceWidget extends StatefulWidget {
  const AnimatedEntranceWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.curve = Curves.easeInOut,
    this.animationType = AnimationType.fadeIn,
    this.slideDirection = SlideDirection.fromBottom,
    this.slideOffset = 50.0,
    this.scaleBegin = 0.8,
    this.scaleEnd = 1.0,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final AnimationType animationType;
  final SlideDirection slideDirection;
  final double slideOffset;
  final double scaleBegin;
  final double scaleEnd;

  @override
  State<AnimatedEntranceWidget> createState() => _AnimatedEntranceWidgetState();
}

class _AnimatedEntranceWidgetState extends State<AnimatedEntranceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _scaleAnimation = Tween<double>(
      begin: widget.scaleBegin,
      end: widget.scaleEnd,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    final beginOffset = _getBeginOffset();
    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _getBeginOffset() {
    switch (widget.slideDirection) {
      case SlideDirection.fromTop:
        return Offset(0, -widget.slideOffset);
      case SlideDirection.fromBottom:
        return Offset(0, widget.slideOffset);
      case SlideDirection.fromLeft:
        return Offset(-widget.slideOffset, 0);
      case SlideDirection.fromRight:
        return Offset(widget.slideOffset, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    var animatedChild = widget.child;

    switch (widget.animationType) {
      case AnimationType.fadeIn:
        animatedChild = FadeTransition(opacity: _fadeAnimation, child: animatedChild);
        break;
      case AnimationType.scaleIn:
        animatedChild = ScaleTransition(scale: _scaleAnimation, child: animatedChild);
        break;
      case AnimationType.slideIn:
        animatedChild = SlideTransition(position: _slideAnimation, child: animatedChild);
        break;
      case AnimationType.fadeScaleIn:
        animatedChild = FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(scale: _scaleAnimation, child: animatedChild),
        );
        break;
      case AnimationType.fadeSlideIn:
        animatedChild = FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(position: _slideAnimation, child: animatedChild),
        );
        break;
      case AnimationType.scaleSlideIn:
        animatedChild = ScaleTransition(
          scale: _scaleAnimation,
          child: SlideTransition(position: _slideAnimation, child: animatedChild),
        );
        break;
      case AnimationType.allIn:
        animatedChild = FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SlideTransition(position: _slideAnimation, child: animatedChild),
          ),
        );
        break;
    }

    return animatedChild;
  }
}

/// Типы анимаций
enum AnimationType { fadeIn, scaleIn, slideIn, fadeScaleIn, fadeSlideIn, scaleSlideIn, allIn }

/// Виджет для анимации появления списка элементов
class AnimatedListWidget extends StatefulWidget {
  const AnimatedListWidget({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
    this.delay = const Duration(milliseconds: 100),
    this.curve = Curves.easeInOut,
    this.animationType = AnimationType.fadeSlideIn,
    this.slideDirection = SlideDirection.fromBottom,
    this.slideOffset = 30.0,
  });

  final List<Widget> children;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final AnimationType animationType;
  final SlideDirection slideDirection;
  final double slideOffset;

  @override
  State<AnimatedListWidget> createState() => _AnimatedListWidgetState();
}

class _AnimatedListWidgetState extends State<AnimatedListWidget> {
  @override
  Widget build(BuildContext context) => Column(
        children: widget.children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;

          return AnimatedEntranceWidget(
            duration: widget.duration,
            delay: Duration(milliseconds: widget.delay.inMilliseconds * index),
            curve: widget.curve,
            animationType: widget.animationType,
            slideDirection: widget.slideDirection,
            slideOffset: widget.slideOffset,
            child: child,
          );
        }).toList(),
      );
}

/// Виджет для анимации нажатия
class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.duration = const Duration(milliseconds: 150),
    this.scale = 0.95,
    this.curve = Curves.easeInOut,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;
  final double scale;
  final Curve curve;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 1,
      end: widget.scale,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: widget.onPressed != null ? _onTapDown : null,
        onTapUp: widget.onPressed != null ? _onTapUp : null,
        onTapCancel: widget.onPressed != null ? _onTapCancel : null,
        onTap: widget.onPressed,
        child: ScaleTransition(scale: _animation, child: widget.child),
      );
}

/// Виджет для анимации появления с задержкой
class StaggeredAnimationWidget extends StatefulWidget {
  const StaggeredAnimationWidget({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
    this.delay = const Duration(milliseconds: 100),
    this.curve = Curves.easeInOut,
    this.animationType = AnimationType.fadeSlideIn,
    this.slideDirection = SlideDirection.fromBottom,
    this.slideOffset = 30.0,
  });

  final List<Widget> children;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final AnimationType animationType;
  final SlideDirection slideDirection;
  final double slideOffset;

  @override
  State<StaggeredAnimationWidget> createState() => _StaggeredAnimationWidgetState();
}

class _StaggeredAnimationWidgetState extends State<StaggeredAnimationWidget> {
  @override
  Widget build(BuildContext context) => Column(
        children: widget.children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;

          return AnimatedEntranceWidget(
            duration: widget.duration,
            delay: Duration(milliseconds: widget.delay.inMilliseconds * index),
            curve: widget.curve,
            animationType: widget.animationType,
            slideDirection: widget.slideDirection,
            slideOffset: widget.slideOffset,
            child: child,
          );
        }).toList(),
      );
}
