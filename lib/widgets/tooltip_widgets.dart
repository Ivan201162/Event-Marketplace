import 'package:flutter/material.dart';

/// Виджет с всплывающей подсказкой
class TooltipButton extends StatelessWidget {
  final String tooltip;
  final Widget child;
  final VoidCallback? onPressed;
  final String? message;
  final Duration? duration;
  final TooltipTriggerMode triggerMode;

  const TooltipButton({
    super.key,
    required this.tooltip,
    required this.child,
    this.onPressed,
    this.message,
    this.duration,
    this.triggerMode = TooltipTriggerMode.tap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      duration: duration ?? const Duration(seconds: 3),
      triggerMode: triggerMode,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      child: GestureDetector(
        onTap: onPressed,
        child: child,
      ),
    );
  }
}

/// Интерактивная подсказка с анимацией
class InteractiveTooltip extends StatefulWidget {
  final Widget child;
  final String title;
  final String description;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Duration? duration;

  const InteractiveTooltip({
    super.key,
    required this.child,
    required this.title,
    required this.description,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.duration,
  });

  @override
  State<InteractiveTooltip> createState() => _InteractiveTooltipState();
}

class _InteractiveTooltipState extends State<InteractiveTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
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

  void _showTooltip() {
    if (!_isVisible) {
      setState(() {
        _isVisible = true;
      });
      _controller.forward();
    }
  }

  void _hideTooltip() {
    if (_isVisible) {
      _controller.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isVisible = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showTooltip,
      onLongPress: _showTooltip,
      child: Stack(
        children: [
          widget.child,
          if (_isVisible)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: _buildTooltipContent(),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTooltipContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.black87,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              color: widget.textColor ?? Colors.white,
              size: 24,
            ),
            const SizedBox(height: 8),
          ],
          Text(
            widget.title,
            style: TextStyle(
              color: widget.textColor ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            widget.description,
            style: TextStyle(
              color: widget.textColor ?? Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: _hideTooltip,
                child: Text(
                  'Понятно',
                  style: TextStyle(
                    color: widget.textColor ?? Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  _hideTooltip();
                  // Здесь можно добавить действие "Больше не показывать"
                },
                child: Text(
                  'Больше не показывать',
                  style: TextStyle(
                    color: widget.textColor ?? Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Подсказка для новых пользователей
class OnboardingTooltip extends StatefulWidget {
  final Widget child;
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final bool showOnce;
  final String? storageKey;

  const OnboardingTooltip({
    super.key,
    required this.child,
    required this.title,
    required this.description,
    this.buttonText,
    this.onButtonPressed,
    this.showOnce = true,
    this.storageKey,
  });

  @override
  State<OnboardingTooltip> createState() => _OnboardingTooltipState();
}

class _OnboardingTooltipState extends State<OnboardingTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isVisible = false;
  bool _shouldShow = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _checkShouldShow();
  }

  Future<void> _checkShouldShow() async {
    if (widget.showOnce && widget.storageKey != null) {
      // Здесь должна быть проверка SharedPreferences
      // Для демонстрации всегда показываем
      _shouldShow = true;
    }
    
    if (_shouldShow) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _showTooltip();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showTooltip() {
    if (!_isVisible && _shouldShow) {
      setState(() {
        _isVisible = true;
      });
      _controller.forward();
    }
  }

  void _hideTooltip() {
    if (_isVisible) {
      _controller.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isVisible = false;
          });
        }
      });
    }
  }

  void _handleButtonPress() {
    if (widget.showOnce && widget.storageKey != null) {
      // Здесь должно быть сохранение в SharedPreferences
      // что подсказка больше не должна показываться
    }
    
    widget.onButtonPressed?.call();
    _hideTooltip();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isVisible)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: _buildTooltipContent(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTooltipContent() {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 48,
            color: Colors.amber,
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            widget.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (widget.showOnce)
                TextButton(
                  onPressed: _hideTooltip,
                  child: const Text('Пропустить'),
                ),
              ElevatedButton(
                onPressed: _handleButtonPress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(widget.buttonText ?? 'Понятно'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Подсказка с позиционированием
class PositionedTooltip extends StatefulWidget {
  final Widget child;
  final String message;
  final TooltipPosition position;
  final Duration? duration;
  final Color? backgroundColor;
  final Color? textColor;

  const PositionedTooltip({
    super.key,
    required this.child,
    required this.message,
    this.position = TooltipPosition.top,
    this.duration,
    this.backgroundColor,
    this.textColor,
  });

  @override
  State<PositionedTooltip> createState() => _PositionedTooltipState();
}

class _PositionedTooltipState extends State<PositionedTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showTooltip() {
    if (!_isVisible) {
      setState(() {
        _isVisible = true;
      });
      _controller.forward();
    }
  }

  void _hideTooltip() {
    if (_isVisible) {
      _controller.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isVisible = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showTooltip,
      onLongPress: _showTooltip,
      child: Stack(
        children: [
          widget.child,
          if (_isVisible)
            Positioned(
              top: widget.position == TooltipPosition.top ? 0 : null,
              bottom: widget.position == TooltipPosition.bottom ? 0 : null,
              left: widget.position == TooltipPosition.left ? 0 : null,
              right: widget.position == TooltipPosition.right ? 0 : null,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _animation.value,
                    child: _buildTooltip(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTooltip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        widget.message,
        style: TextStyle(
          color: widget.textColor ?? Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }
}

enum TooltipPosition {
  top,
  bottom,
  left,
  right,
}
