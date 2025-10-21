import 'package:flutter/material.dart';

/// Универсальные индикаторы загрузки
class LoadingIndicators {
  /// Простой круговой индикатор
  static Widget circular({
    double size = 24,
    Color? color,
    double strokeWidth = 2,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.blue),
      ),
    );
  }

  /// Индикатор загрузки с текстом
  static Widget withText({
    required String text,
    double size = 24,
    Color? color,
    TextStyle? textStyle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        circular(size: size, color: color),
        const SizedBox(height: 16),
        Text(
          text,
          style: textStyle ?? const TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Индикатор загрузки для кнопки
  static Widget button({
    double size = 20,
    Color? color,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.white),
      ),
    );
  }

  /// Индикатор загрузки для карточки
  static Widget card({
    double height = 200,
    double borderRadius = 12,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Индикатор загрузки для списка
  static Widget listItem({
    double height = 60,
    double borderRadius = 8,
  }) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Индикатор загрузки для изображения
  static Widget image({
    double? width,
    double? height,
    double borderRadius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Индикатор загрузки для аватара
  static Widget avatar({
    double radius = 20,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }

  /// Индикатор загрузки с анимацией пульсации
  static Widget pulse({
    double size = 24,
    Color? color,
  }) {
    return _PulseLoadingIndicator(
      size: size,
      color: color ?? Colors.blue,
    );
  }

  /// Индикатор загрузки с анимацией волны
  static Widget wave({
    double size = 24,
    Color? color,
  }) {
    return _WaveLoadingIndicator(
      size: size,
      color: color ?? Colors.blue,
    );
  }

  /// Индикатор загрузки с анимацией точек
  static Widget dots({
    double size = 24,
    Color? color,
  }) {
    return _DotsLoadingIndicator(
      size: size,
      color: color ?? Colors.blue,
    );
  }
}

/// Индикатор загрузки с анимацией пульсации
class _PulseLoadingIndicator extends StatefulWidget {
  const _PulseLoadingIndicator({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  State<_PulseLoadingIndicator> createState() => _PulseLoadingIndicatorState();
}

class _PulseLoadingIndicatorState extends State<_PulseLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
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
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(_animation.value),
          ),
        );
      },
    );
  }
}

/// Индикатор загрузки с анимацией волны
class _WaveLoadingIndicator extends StatefulWidget {
  const _WaveLoadingIndicator({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  State<_WaveLoadingIndicator> createState() => _WaveLoadingIndicatorState();
}

class _WaveLoadingIndicatorState extends State<_WaveLoadingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(controller);
    }).toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              width: widget.size / 3,
              height: widget.size * _animations[index].value,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Индикатор загрузки с анимацией точек
class _DotsLoadingIndicator extends StatefulWidget {
  const _DotsLoadingIndicator({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  State<_DotsLoadingIndicator> createState() => _DotsLoadingIndicatorState();
}

class _DotsLoadingIndicatorState extends State<_DotsLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.3,
            (index * 0.3) + 0.7,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              width: widget.size / 4,
              height: widget.size / 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(_animations[index].value),
              ),
            );
          },
        );
      }),
    );
  }
}
