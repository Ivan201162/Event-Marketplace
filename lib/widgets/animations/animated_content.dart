import 'package:flutter/material.dart';

/// Виджет для анимированного появления контента
class AnimatedContent extends StatefulWidget {
  const AnimatedContent({
    required this.child, super.key,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.animationType = AnimationType.fadeIn,
    this.offset = const Offset(0, 0.3),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final AnimationType animationType;
  final Offset offset;

  @override
  State<AnimatedContent> createState() => _AnimatedContentState();
}

class _AnimatedContentState extends State<AnimatedContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ),);

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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        switch (widget.animationType) {
          case AnimationType.fadeIn:
            return Opacity(
              opacity: _animation.value,
              child: widget.child,
            );
          case AnimationType.slideIn:
            return SlideTransition(
              position: Tween<Offset>(
                begin: widget.offset,
                end: Offset.zero,
              ).animate(_animation),
              child: widget.child,
            );
          case AnimationType.scaleIn:
            return ScaleTransition(
              scale: _animation,
              child: widget.child,
            );
          case AnimationType.fadeSlideIn:
            return FadeTransition(
              opacity: _animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: widget.offset,
                  end: Offset.zero,
                ).animate(_animation),
                child: widget.child,
              ),
            );
          case AnimationType.fadeScaleIn:
            return FadeTransition(
              opacity: _animation,
              child: ScaleTransition(
                scale: _animation,
                child: widget.child,
              ),
            );
        }
      },
    );
  }
}

/// Типы анимаций
enum AnimationType {
  fadeIn,
  slideIn,
  scaleIn,
  fadeSlideIn,
  fadeScaleIn,
}

/// Виджет для анимированного появления списка элементов
class AnimatedList extends StatefulWidget {
  const AnimatedList({
    required this.children, super.key,
    this.delay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.animationType = AnimationType.fadeSlideIn,
    this.offset = const Offset(0, 0.3),
  });

  final List<Widget> children;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final AnimationType animationType;
  final Offset offset;

  @override
  State<AnimatedList> createState() => _AnimatedListState();
}

class _AnimatedListState extends State<AnimatedList>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: widget.curve),
      );
    }).toList();

    // Запускаем анимации с задержкой
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(
        widget.delay * i,
        () {
          if (mounted) {
            _controllers[i].forward();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.children.length, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            switch (widget.animationType) {
              case AnimationType.fadeIn:
                return Opacity(
                  opacity: _animations[index].value,
                  child: widget.children[index],
                );
              case AnimationType.slideIn:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: widget.offset,
                    end: Offset.zero,
                  ).animate(_animations[index]),
                  child: widget.children[index],
                );
              case AnimationType.scaleIn:
                return ScaleTransition(
                  scale: _animations[index],
                  child: widget.children[index],
                );
              case AnimationType.fadeSlideIn:
                return FadeTransition(
                  opacity: _animations[index],
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: widget.offset,
                      end: Offset.zero,
                    ).animate(_animations[index]),
                    child: widget.children[index],
                  ),
                );
              case AnimationType.fadeScaleIn:
                return FadeTransition(
                  opacity: _animations[index],
                  child: ScaleTransition(
                    scale: _animations[index],
                    child: widget.children[index],
                  ),
                );
            }
          },
        );
      }),
    );
  }
}

/// Виджет для анимированного появления карточек
class AnimatedCard extends StatefulWidget {
  const AnimatedCard({
    required this.child, super.key,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.animationType = AnimationType.fadeSlideIn,
    this.offset = const Offset(0, 0.3),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final AnimationType animationType;
  final Offset offset;

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ),);

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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            (1 - _animation.value) * 20,
          ),
          child: Opacity(
            opacity: _animation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Виджет для анимированного появления кнопки
class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    required this.child, super.key,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.elasticOut,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;

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
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ),);

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
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Виджет для анимированного появления текста
class AnimatedText extends StatefulWidget {
  const AnimatedText({
    required this.text, super.key,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
    this.style,
    this.textAlign,
  });

  final String text;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  State<AnimatedText> createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ),);

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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _animation.value) * 20),
            child: Text(
              widget.text,
              style: widget.style,
              textAlign: widget.textAlign,
            ),
          ),
        );
      },
    );
  }
}
