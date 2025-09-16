import 'package:flutter/material.dart';
import 'dart:async';

/// Виджет с поддержкой свайпов
class SwipeableWidget extends StatefulWidget {
  final Widget child;
  final Widget? leftAction;
  final Widget? rightAction;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final double threshold;

  const SwipeableWidget({
    super.key,
    required this.child,
    this.leftAction,
    this.rightAction,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.threshold = 100.0,
  });

  @override
  State<SwipeableWidget> createState() => _SwipeableWidgetState();
}

class _SwipeableWidgetState extends State<SwipeableWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  double _dragExtent = 0.0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
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
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        children: [
          // Фоновые действия
          if (widget.leftAction != null || widget.rightAction != null)
            Positioned.fill(
              child: Row(
                children: [
                  if (widget.leftAction != null)
                    Expanded(
                      child: Container(
                        color: Colors.red.withOpacity(0.1),
                        child: widget.leftAction,
                      ),
                    ),
                  const Spacer(),
                  if (widget.rightAction != null)
                    Expanded(
                      child: Container(
                        color: Colors.green.withOpacity(0.1),
                        child: widget.rightAction,
                      ),
                    ),
                ],
              ),
            ),

          // Основной контент
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_dragExtent, 0),
                child: widget.child,
              );
            },
          ),
        ],
      ),
    );
  }

  void _onDragStart(DragStartDetails details) {
    _isAnimating = false;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;

    setState(() {
      _dragExtent += details.delta.dx;
      _dragExtent = _dragExtent.clamp(-200.0, 200.0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isAnimating) return;

    final velocity = details.velocity.pixelsPerSecond.dx;
    final shouldSwipeLeft = _dragExtent < -widget.threshold || velocity < -500;
    final shouldSwipeRight = _dragExtent > widget.threshold || velocity > 500;

    if (shouldSwipeLeft && widget.onSwipeLeft != null) {
      _animateSwipeLeft();
    } else if (shouldSwipeRight && widget.onSwipeRight != null) {
      _animateSwipeRight();
    } else {
      _animateBack();
    }
  }

  void _animateSwipeLeft() {
    _isAnimating = true;
    _controller.forward().then((_) {
      widget.onSwipeLeft?.call();
      _reset();
    });
  }

  void _animateSwipeRight() {
    _isAnimating = true;
    _controller.reverse().then((_) {
      widget.onSwipeRight?.call();
      _reset();
    });
  }

  void _animateBack() {
    _isAnimating = true;
    _controller.animateTo(0.0).then((_) {
      _reset();
    });
  }

  void _reset() {
    setState(() {
      _dragExtent = 0.0;
      _isAnimating = false;
    });
  }
}

/// Виджет с поддержкой долгого нажатия
class LongPressWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onLongPress;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final Duration duration;

  const LongPressWidget({
    super.key,
    required this.child,
    this.onLongPress,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<LongPressWidget> createState() => _LongPressWidgetState();
}

class _LongPressWidgetState extends State<LongPressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isLongPressing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    _isLongPressing = true;
    _controller.forward();
    widget.onLongPressStart?.call();

    Future.delayed(widget.duration, () {
      if (_isLongPressing) {
        widget.onLongPress?.call();
      }
    });
  }

  void _onTapUp(TapUpDetails details) {
    _onTapEnd();
  }

  void _onTapCancel() {
    _onTapEnd();
  }

  void _onTapEnd() {
    _isLongPressing = false;
    _controller.reverse();
    widget.onLongPressEnd?.call();
  }
}

/// Виджет с поддержкой пинча (зума)
class PinchZoomWidget extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final VoidCallback? onScaleStart;
  final VoidCallback? onScaleEnd;

  const PinchZoomWidget({
    super.key,
    required this.child,
    this.minScale = 0.5,
    this.maxScale = 3.0,
    this.onScaleStart,
    this.onScaleEnd,
  });

  @override
  State<PinchZoomWidget> createState() => _PinchZoomWidgetState();
}

class _PinchZoomWidgetState extends State<PinchZoomWidget> {
  double _scale = 1.0;
  double _previousScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _previousOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      child: Transform(
        transform: Matrix4.identity()
          ..translate(_offset.dx, _offset.dy)
          ..scale(_scale),
        child: widget.child,
      ),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _previousScale = _scale;
    _previousOffset = _offset;
    widget.onScaleStart?.call();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_previousScale * details.scale)
          .clamp(widget.minScale, widget.maxScale);

      final newOffset =
          _previousOffset + details.focalPoint - details.localFocalPoint;
      _offset = newOffset;
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    widget.onScaleEnd?.call();
  }
}

/// Виджет с поддержкой двойного нажатия
class DoubleTapWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onSingleTap;
  final Duration doubleTapTimeout;

  const DoubleTapWidget({
    super.key,
    required this.child,
    this.onDoubleTap,
    this.onSingleTap,
    this.doubleTapTimeout = const Duration(milliseconds: 300),
  });

  @override
  State<DoubleTapWidget> createState() => _DoubleTapWidgetState();
}

class _DoubleTapWidgetState extends State<DoubleTapWidget> {
  int _tapCount = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: widget.child,
    );
  }

  void _onTap() {
    _tapCount++;

    if (_tapCount == 1) {
      _timer = Timer(widget.doubleTapTimeout, () {
        if (_tapCount == 1) {
          widget.onSingleTap?.call();
        }
        _tapCount = 0;
      });
    } else if (_tapCount == 2) {
      _timer?.cancel();
      widget.onDoubleTap?.call();
      _tapCount = 0;
    }
  }
}

/// Виджет с поддержкой перетаскивания
class DraggableWidget extends StatefulWidget {
  final Widget child;
  final Widget? feedback;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;
  final bool canDrag;

  const DraggableWidget({
    super.key,
    required this.child,
    this.feedback,
    this.onDragStarted,
    this.onDragEnd,
    this.canDrag = true,
  });

  @override
  State<DraggableWidget> createState() => _DraggableWidgetState();
}

class _DraggableWidgetState extends State<DraggableWidget> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.canDrag) {
      return widget.child;
    }

    return Draggable(
      data: widget.child,
      feedback: widget.feedback ?? widget.child,
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: widget.child,
      ),
      onDragStarted: () {
        setState(() {
          _isDragging = true;
        });
        widget.onDragStarted?.call();
      },
      onDragEnd: (details) {
        setState(() {
          _isDragging = false;
        });
        widget.onDragEnd?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isDragging
            ? (Matrix4.identity()..scale(1.05))
            : Matrix4.identity(),
        child: widget.child,
      ),
    );
  }
}

/// Виджет с поддержкой сброса
class DismissibleWidget extends StatelessWidget {
  final Widget child;
  final String key;
  final VoidCallback? onDismissed;
  final Widget? background;
  final Widget? secondaryBackground;
  final DismissDirection direction;

  const DismissibleWidget({
    super.key,
    required this.child,
    required this.key,
    this.onDismissed,
    this.background,
    this.secondaryBackground,
    this.direction = DismissDirection.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(key),
      direction: direction,
      background: background ??
          Container(
            color: Colors.red,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
      secondaryBackground: secondaryBackground ??
          Container(
            color: Colors.green,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.archive, color: Colors.white),
          ),
      onDismissed: (direction) {
        onDismissed?.call();
      },
      child: child,
    );
  }
}

/// Виджет с поддержкой жестов
class GestureDetectorWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onPanStart;
  final VoidCallback? onPanUpdate;
  final VoidCallback? onPanEnd;
  final VoidCallback? onScaleStart;
  final VoidCallback? onScaleUpdate;
  final VoidCallback? onScaleEnd;

  const GestureDetectorWidget({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      onPanStart: onPanStart != null ? (_) => onPanStart!() : null,
      onPanUpdate: onPanUpdate != null ? (_) => onPanUpdate!() : null,
      onPanEnd: onPanEnd != null ? (_) => onPanEnd!() : null,
      onScaleStart: onScaleStart != null ? (_) => onScaleStart!() : null,
      onScaleUpdate: onScaleUpdate != null ? (_) => onScaleUpdate!() : null,
      onScaleEnd: onScaleEnd != null ? (_) => onScaleEnd!() : null,
      child: child,
    );
  }
}
