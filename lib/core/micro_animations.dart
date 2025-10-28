import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';

/// Дополнительные микроанимации для улучшения UX
class MicroAnimations {
  
  /// Анимированная кнопка с эффектом пульсации
  static Widget pulseButton({
    required Widget child,
    required VoidCallback onPressed,
    Duration duration = const Duration(milliseconds: 1000),
    double scale = 1.05,
  }) {
    return _PulseAnimation(
      duration: duration,
      scale: scale,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: child,
        ),
      ),
    );
  }

  /// Анимированная карточка с эффектом наведения
  static Widget hoverCard({
    required Widget child,
    VoidCallback? onTap,
    Duration duration = const Duration(milliseconds: 200),
    double hoverScale = 1.02,
  }) {
    return _HoverAnimation(
      duration: duration,
      hoverScale: hoverScale,
      child: Card(
        elevation: 2,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: child,
              )
            : child,
      ),
    );
  }

  /// Анимированный список с эффектом волны
  static Widget waveList({
    required List<Widget> children,
    ScrollController? controller,
    EdgeInsets? padding,
    Duration delay = const Duration(milliseconds: 100),
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return _WaveAnimation(
          delay: Duration(milliseconds: delay.inMilliseconds * index),
          child: children[index],
        );
      },
    );
  }

  /// Анимированная иконка с эффектом вращения
  static Widget rotatingIcon({
    required IconData icon,
    required bool isActive,
    Duration duration = const Duration(milliseconds: 300),
    double size = 24,
    Color? color,
  }) {
    return _RotatingIcon(
      icon: icon,
      isActive: isActive,
      duration: duration,
      size: size,
      color: color,
    );
  }

  /// Анимированный прогресс-бар
  static Widget animatedProgress({
    required double progress,
    Duration duration = const Duration(milliseconds: 500),
    Color? backgroundColor,
    Color? progressColor,
    double height = 4,
  }) {
    return _AnimatedProgress(
      progress: progress,
      duration: duration,
      backgroundColor: backgroundColor ?? Colors.grey[300]!,
      progressColor: progressColor ?? AppTheme.primaryColor,
      height: height,
    );
  }

  /// Анимированная кнопка с эффектом загрузки
  static Widget loadingButton({
    required String text,
    required bool isLoading,
    required VoidCallback onPressed,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return _LoadingButton(
      text: text,
      isLoading: isLoading,
      onPressed: onPressed,
      icon: icon,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }

  /// Анимированное появление текста
  static Widget fadeInText({
    required String text,
    Duration duration = const Duration(milliseconds: 500),
    TextStyle? style,
    TextAlign? textAlign,
  }) {
    return _FadeInText(
      text: text,
      duration: duration,
      style: style,
      textAlign: textAlign,
    );
  }

  /// Анимированная карточка с эффектом масштабирования
  static Widget scaleCard({
    required Widget child,
    VoidCallback? onTap,
    Duration duration = const Duration(milliseconds: 200),
    double scale = 0.95,
  }) {
    return _ScaleCard(
      duration: duration,
      scale: scale,
      onTap: onTap,
      child: child,
    );
  }
}

/// Анимация пульсации
class _PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double scale;

  const _PulseAnimation({
    required this.child,
    required this.duration,
    required this.scale,
  });

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
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
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
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
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Анимация наведения
class _HoverAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double hoverScale;

  const _HoverAnimation({
    required this.child,
    required this.duration,
    required this.hoverScale,
  });

  @override
  State<_HoverAnimation> createState() => _HoverAnimationState();
}

class _HoverAnimationState extends State<_HoverAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: widget.hoverScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
        _controller.forward();
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Анимация волны
class _WaveAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _WaveAnimation({
    required this.child,
    required this.delay,
  });

  @override
  State<_WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<_WaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
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
          offset: Offset(0, 20 * (1 - _animation.value)),
          child: Opacity(
            opacity: _animation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Анимация вращения иконки
class _RotatingIcon extends StatefulWidget {
  final IconData icon;
  final bool isActive;
  final Duration duration;
  final double size;
  final Color? color;

  const _RotatingIcon({
    required this.icon,
    required this.isActive,
    required this.duration,
    required this.size,
    this.color,
  });

  @override
  State<_RotatingIcon> createState() => _RotatingIconState();
}

class _RotatingIconState extends State<_RotatingIcon>
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
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_RotatingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
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
        return Transform.rotate(
          angle: _animation.value * 2 * 3.14159,
          child: Icon(
            widget.icon,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}

/// Анимированный прогресс-бар
class _AnimatedProgress extends StatefulWidget {
  final double progress;
  final Duration duration;
  final Color backgroundColor;
  final Color progressColor;
  final double height;

  const _AnimatedProgress({
    required this.progress,
    required this.duration,
    required this.backgroundColor,
    required this.progressColor,
    required this.height,
  });

  @override
  State<_AnimatedProgress> createState() => _AnimatedProgressState();
}

class _AnimatedProgressState extends State<_AnimatedProgress>
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
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _animation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
      _controller.forward(from: 0);
    }
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
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _animation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.progressColor,
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Кнопка с анимацией загрузки
class _LoadingButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const _LoadingButton({
    required this.text,
    required this.isLoading,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.primaryColor,
          foregroundColor: textColor ?? Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
            ] else if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Анимированный текст
class _FadeInText extends StatefulWidget {
  final String text;
  final Duration duration;
  final TextStyle? style;
  final TextAlign? textAlign;

  const _FadeInText({
    required this.text,
    required this.duration,
    this.style,
    this.textAlign,
  });

  @override
  State<_FadeInText> createState() => _FadeInTextState();
}

class _FadeInTextState extends State<_FadeInText>
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
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
    _controller.forward();
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
          child: Text(
            widget.text,
            style: widget.style,
            textAlign: widget.textAlign,
          ),
        );
      },
    );
  }
}

/// Анимированная карточка с масштабированием
class _ScaleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double scale;

  const _ScaleCard({
    required this.child,
    this.onTap,
    required this.duration,
    required this.scale,
  });

  @override
  State<_ScaleCard> createState() => _ScaleCardState();
}

class _ScaleCardState extends State<_ScaleCard>
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
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
