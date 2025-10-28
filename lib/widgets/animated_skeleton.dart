import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Анимированный skeleton для загрузки контента
class AnimatedSkeleton extends StatefulWidget {

  const AnimatedSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.baseColor,
    this.highlightColor,
    this.child,
    this.isLoading = true,
  });
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final Widget? child;
  final bool isLoading;

  @override
  State<AnimatedSkeleton> createState() => _AnimatedSkeletonState();
}

class _AnimatedSkeletonState extends State<AnimatedSkeleton>
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

    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedSkeleton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
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
    if (!widget.isLoading && widget.child != null) {
      return widget.child!;
    }

    return Shimmer.fromColors(
      baseColor: widget.baseColor ?? Colors.grey[300]!,
      highlightColor: widget.highlightColor ?? Colors.grey[100]!,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton для карточки
class SkeletonCard extends StatelessWidget {

  const SkeletonCard({
    super.key,
    this.width,
    this.height,
    this.padding,
  });
  final double? width;
  final double? height;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? 120,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          AnimatedSkeleton(
            width: double.infinity,
            height: 20,
            borderRadius: 4,
          ),
          SizedBox(height: 12),
          // Описание
          AnimatedSkeleton(
            width: double.infinity,
            height: 16,
            borderRadius: 4,
          ),
          SizedBox(height: 8),
          AnimatedSkeleton(
            width: 200,
            height: 16,
            borderRadius: 4,
          ),
          Spacer(),
          // Кнопки
          Row(
            children: [
              Expanded(
                child: AnimatedSkeleton(
                  height: 40,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: AnimatedSkeleton(
                  height: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton для списка
class SkeletonList extends StatelessWidget {

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight,
    this.padding,
  });
  final int itemCount;
  final double? itemHeight;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SkeletonCard(
            height: itemHeight,
          ),
        );
      },
    );
  }
}

/// Skeleton для профиля
class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Аватар
          const AnimatedSkeleton(
            width: 80,
            height: 80,
            borderRadius: 40,
          ),
          const SizedBox(height: 16),
          // Имя
          const AnimatedSkeleton(
            width: 150,
            height: 24,
            borderRadius: 4,
          ),
          const SizedBox(height: 8),
          // Email
          const AnimatedSkeleton(
            width: 200,
            height: 16,
            borderRadius: 4,
          ),
          const SizedBox(height: 24),
          // Статистика
          Row(
            children: [
              Expanded(
                child: _SkeletonStatItem(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SkeletonStatItem(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SkeletonStatItem(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonStatItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          AnimatedSkeleton(
            width: 30,
            height: 20,
            borderRadius: 4,
          ),
          SizedBox(height: 8),
          AnimatedSkeleton(
            width: 60,
            height: 12,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }
}

/// Skeleton для чата
class SkeletonChatItem extends StatelessWidget {
  const SkeletonChatItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Row(
        children: [
          // Аватар
          AnimatedSkeleton(
            width: 50,
            height: 50,
            borderRadius: 25,
          ),
          SizedBox(width: 12),
          // Контент
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Имя и время
                Row(
                  children: [
                    Expanded(
                      child: AnimatedSkeleton(
                        width: 120,
                        height: 16,
                        borderRadius: 4,
                      ),
                    ),
                    AnimatedSkeleton(
                      width: 40,
                      height: 12,
                      borderRadius: 4,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Последнее сообщение
                AnimatedSkeleton(
                  width: double.infinity,
                  height: 14,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton для уведомлений
class SkeletonNotificationItem extends StatelessWidget {
  const SkeletonNotificationItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          // Иконка
          AnimatedSkeleton(
            width: 48,
            height: 48,
            borderRadius: 24,
          ),
          SizedBox(width: 12),
          // Контент
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSkeleton(
                  width: double.infinity,
                  height: 16,
                  borderRadius: 4,
                ),
                SizedBox(height: 8),
                AnimatedSkeleton(
                  width: 200,
                  height: 14,
                  borderRadius: 4,
                ),
                SizedBox(height: 4),
                AnimatedSkeleton(
                  width: 80,
                  height: 12,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
