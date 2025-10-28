import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Анимированная кнопка с эффектами нажатия
class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    required this.onPressed, required this.child, super.key,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 2,
    this.borderRadius = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.hapticFeedback = true,
    this.scaleOnPress = true,
    this.scaleValue = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool hapticFeedback;
  final bool scaleOnPress;
  final double scaleValue;
  final Duration duration;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: widget.scaleValue,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && widget.scaleOnPress) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  void _handleTapCancel() {
    _handleTapEnd();
  }

  void _handleTapEnd() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTap() {
    if (widget.onPressed != null) {
      if (widget.hapticFeedback) {
        HapticFeedback.lightImpact();
      }
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Material(
              elevation: _isPressed ? widget.elevation * 0.5 : widget.elevation,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              color: widget.backgroundColor ?? Theme.of(context).primaryColor,
              child: Container(
                padding: widget.padding,
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: widget.foregroundColor ?? Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      );
}

/// Анимированная иконка с эффектами
class AnimatedIconButton extends StatefulWidget {
  const AnimatedIconButton({
    required this.icon, required this.onPressed, super.key,
    this.size = 24,
    this.color,
    this.hapticFeedback = true,
    this.scaleOnPress = true,
    this.scaleValue = 0.8,
    this.duration = const Duration(milliseconds: 150),
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;
  final bool hapticFeedback;
  final bool scaleOnPress;
  final double scaleValue;
  final Duration duration;

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: widget.scaleValue,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && widget.scaleOnPress) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  void _handleTapCancel() {
    _handleTapEnd();
  }

  void _handleTapEnd() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTap() {
    if (widget.onPressed != null) {
      if (widget.hapticFeedback) {
        HapticFeedback.lightImpact();
      }
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Icon(
              widget.icon,
              size: widget.size,
              color: widget.color ?? Theme.of(context).iconTheme.color,
            ),
          ),
        ),
      );
}

/// Анимированная кнопка лайка
class AnimatedLikeButton extends StatefulWidget {
  const AnimatedLikeButton({
    required this.isLiked, required this.onPressed, super.key,
    this.size = 24,
    this.likedColor = Colors.red,
    this.unlikedColor,
    this.hapticFeedback = true,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  final bool isLiked;
  final ValueChanged<bool> onPressed;
  final double size;
  final Color likedColor;
  final Color? unlikedColor;
  final bool hapticFeedback;
  final Duration animationDuration;

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: widget.animationDuration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _colorAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.hapticFeedback) {
      HapticFeedback.mediumImpact();
    }

    _controller.forward().then((_) {
      _controller.reverse();
    });

    widget.onPressed(!widget.isLiked);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Icon(
              widget.isLiked ? Icons.favorite : Icons.favorite_border,
              size: widget.size,
              color: widget.isLiked
                  ? widget.likedColor
                  : (widget.unlikedColor ?? Theme.of(context).iconTheme.color),
            ),
          ),
        ),
      );
}

/// Анимированная кнопка репоста
class AnimatedShareButton extends StatefulWidget {
  const AnimatedShareButton({
    required this.onPressed, super.key,
    this.size = 24,
    this.color,
    this.hapticFeedback = true,
    this.animationDuration = const Duration(milliseconds: 150),
  });

  final VoidCallback onPressed;
  final double size;
  final Color? color;
  final bool hapticFeedback;
  final Duration animationDuration;

  @override
  State<AnimatedShareButton> createState() => _AnimatedShareButtonState();
}

class _AnimatedShareButtonState extends State<AnimatedShareButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: widget.animationDuration, vsync: this);

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.hapticFeedback) {
      HapticFeedback.lightImpact();
    }

    _controller.forward().then((_) {
      _controller.reverse();
    });

    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) => Transform.rotate(
            angle: _rotationAnimation.value,
            child: Icon(
              Icons.share,
              size: widget.size,
              color: widget.color ?? Theme.of(context).iconTheme.color,
            ),
          ),
        ),
      );
}

/// Анимированная кнопка сохранения
class AnimatedSaveButton extends StatefulWidget {
  const AnimatedSaveButton({
    required this.isSaved, required this.onPressed, super.key,
    this.size = 24,
    this.savedColor = Colors.blue,
    this.unsavedColor,
    this.hapticFeedback = true,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  final bool isSaved;
  final ValueChanged<bool> onPressed;
  final double size;
  final Color savedColor;
  final Color? unsavedColor;
  final bool hapticFeedback;
  final Duration animationDuration;

  @override
  State<AnimatedSaveButton> createState() => _AnimatedSaveButtonState();
}

class _AnimatedSaveButtonState extends State<AnimatedSaveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: widget.animationDuration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.hapticFeedback) {
      HapticFeedback.lightImpact();
    }

    _controller.forward().then((_) {
      _controller.reverse();
    });

    widget.onPressed(!widget.isSaved);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Icon(
              widget.isSaved ? Icons.bookmark : Icons.bookmark_border,
              size: widget.size,
              color: widget.isSaved
                  ? widget.savedColor
                  : (widget.unsavedColor ?? Theme.of(context).iconTheme.color),
            ),
          ),
        ),
      );
}

/// Анимированная кнопка с пульсацией
class PulsingButton extends StatefulWidget {
  const PulsingButton({
    required this.child, super.key,
    this.onPressed,
    this.pulseDuration = const Duration(seconds: 2),
    this.scaleRange = 0.1,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Duration pulseDuration;
  final double scaleRange;
  final bool enabled;

  @override
  State<PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<PulsingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: widget.pulseDuration, vsync: this);

    _pulseAnimation = Tween<double>(
      begin: 1.0 - widget.scaleRange,
      end: 1.0 + widget.scaleRange,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulsingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) => Transform.scale(
              scale: _pulseAnimation.value, child: widget.child,),
        ),
      );
}
