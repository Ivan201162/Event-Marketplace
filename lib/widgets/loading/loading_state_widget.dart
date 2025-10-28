import 'package:event_marketplace_app/widgets/loading/loading_indicators.dart';
import 'package:flutter/material.dart';

/// Виджет для отображения состояния загрузки
class LoadingStateWidget extends StatelessWidget {
  const LoadingStateWidget({
    super.key,
    this.message,
    this.size = 48,
    this.color,
    this.textStyle,
    this.padding = const EdgeInsets.all(24),
  });

  final String? message;
  final double size;
  final Color? color;
  final TextStyle? textStyle;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: message != null
            ? LoadingIndicators.withText(
                text: message!,
                size: size,
                color: color,
                textStyle: textStyle,
              )
            : LoadingIndicators.circular(
                size: size,
                color: color,
              ),
      ),
    );
  }
}

/// Виджет для отображения состояния загрузки в списке
class LoadingListWidget extends StatelessWidget {
  const LoadingListWidget({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 80,
    this.spacing = 8,
  });

  final int itemCount;
  final double itemHeight;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: spacing),
          child: LoadingIndicators.listItem(height: itemHeight),
        );
      },
    );
  }
}

/// Виджет для отображения состояния загрузки в сетке
class LoadingGridWidget extends StatelessWidget {
  const LoadingGridWidget({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 6,
    this.aspectRatio = 1.0,
    this.spacing = 8,
  });

  final int crossAxisCount;
  final int itemCount;
  final double aspectRatio;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return LoadingIndicators.card();
      },
    );
  }
}

/// Виджет для отображения состояния загрузки с скелетоном
class SkeletonLoadingWidget extends StatelessWidget {
  const SkeletonLoadingWidget({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: _SkeletonShimmer(),
    );
  }
}

/// Анимация скелетона
class _SkeletonShimmer extends StatefulWidget {
  @override
  State<_SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<_SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ),);
    _controller.repeat();
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Виджет для отображения состояния загрузки с прогрессом
class ProgressLoadingWidget extends StatelessWidget {
  const ProgressLoadingWidget({
    required this.progress, super.key,
    this.message,
    this.color,
    this.backgroundColor,
    this.textStyle,
  });

  final double progress;
  final String? message;
  final Color? color;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message != null) ...[
          Text(
            message!,
            style: textStyle ?? const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: backgroundColor ?? Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Theme.of(context).primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(progress * 100).toInt()}%',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
