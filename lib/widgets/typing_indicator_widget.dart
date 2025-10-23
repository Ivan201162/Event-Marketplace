import 'package:flutter/material.dart';
import '../services/typing_service.dart';

/// Виджет для отображения индикатора "печатает"
class TypingIndicatorWidget extends StatelessWidget {
  const TypingIndicatorWidget(
      {super.key, required this.typingUsers, this.currentUserId});

  final List<TypingUser> typingUsers;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    // Фильтруем текущего пользователя из списка
    final otherTypingUsers = typingUsers
        .where((user) => user.userId != currentUserId)
        .where((user) => user.isActive)
        .toList();

    if (otherTypingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildTypingAnimation(),
          const SizedBox(width: 8),
          _buildTypingText(otherTypingUsers),
        ],
      ),
    );
  }

  Widget _buildTypingAnimation() => SizedBox(
        width: 20,
        height: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_buildDot(0), _buildDot(1), _buildDot(2)],
        ),
      );

  Widget _buildDot(int index) => AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        width: 4,
        height: 4,
        decoration:
            const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          builder: (context, value, child) =>
              Opacity(opacity: (value + index * 0.2) % 1.0, child: child),
          onEnd: () {
            // Перезапускаем анимацию
          },
        ),
      );

  Widget _buildTypingText(List<TypingUser> users) {
    if (users.length == 1) {
      return Text(
        '${users.first.userName} печатает...',
        style: const TextStyle(
            color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
      );
    } else if (users.length == 2) {
      return Text(
        '${users.first.userName} и ${users.last.userName} печатают...',
        style: const TextStyle(
            color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
      );
    } else {
      return Text(
        '${users.length} пользователя печатают...',
        style: const TextStyle(
            color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
      );
    }
  }
}

/// Виджет для отображения индикатора печатания с анимацией
class AnimatedTypingIndicator extends StatefulWidget {
  const AnimatedTypingIndicator(
      {super.key, required this.typingUsers, this.currentUserId});

  final List<TypingUser> typingUsers;
  final String? currentUserId;

  @override
  State<AnimatedTypingIndicator> createState() =>
      _AnimatedTypingIndicatorState();
}

class _AnimatedTypingIndicatorState extends State<AnimatedTypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherTypingUsers = widget.typingUsers
        .where((user) => user.userId != widget.currentUserId)
        .where((user) => user.isActive)
        .toList();

    if (otherTypingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildAnimatedDots(),
            const SizedBox(width: 8),
            _buildTypingText(otherTypingUsers),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDots() => SizedBox(
        width: 20,
        height: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAnimatedDot(0),
            _buildAnimatedDot(1),
            _buildAnimatedDot(2)
          ],
        ),
      );

  Widget _buildAnimatedDot(int index) {
    final delay = index * 0.2;
    final animationValue = (_animation.value + delay) % 1.0;
    final opacity = (animationValue < 0.5)
        ? animationValue * 2
        : (1.0 - animationValue) * 2;

    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTypingText(List<TypingUser> users) {
    if (users.length == 1) {
      return Text(
        '${users.first.userName} печатает...',
        style: const TextStyle(
            color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
      );
    } else if (users.length == 2) {
      return Text(
        '${users.first.userName} и ${users.last.userName} печатают...',
        style: const TextStyle(
            color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
      );
    } else {
      return Text(
        '${users.length} пользователя печатают...',
        style: const TextStyle(
            color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
      );
    }
  }
}
