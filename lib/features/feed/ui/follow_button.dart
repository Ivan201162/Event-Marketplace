import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_providers.dart';
// import '../providers/feed_providers.dart'; // Удален

/// Кнопка подписки/отписки
class FollowButton extends ConsumerWidget {
  const FollowButton({
    super.key,
    required this.targetUserId,
    this.size = FollowButtonSize.medium,
  });

  final String targetUserId;
  final FollowButtonSize size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final isFollowingAsync = ref.watch(isFollowingProvider(targetUserId));
    final isFollowing = false; // Заглушка

    // return isFollowingAsync.when(
    //   data: (isFollowing) => _buildButton(context, ref, isFollowing),
    //   loading: _buildLoadingButton,
    //   error: (_, __) => _buildErrorButton(context, ref),
    // );
    return _buildButton(context, ref, isFollowing);
  }

  Widget _buildButton(BuildContext context, WidgetRef ref, bool isFollowing) => ElevatedButton(
        onPressed: () => _handleFollow(context, ref, isFollowing),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing ? Colors.grey[300] : Colors.blue,
          foregroundColor: isFollowing ? Colors.grey[700] : Colors.white,
          padding: _getPadding(),
          minimumSize: _getMinimumSize(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          isFollowing ? 'Отписаться' : 'Подписаться',
          style: TextStyle(
            fontSize: _getFontSize(),
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _buildLoadingButton() => ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          padding: _getPadding(),
          minimumSize: _getMinimumSize(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: SizedBox(
          width: _getFontSize(),
          height: _getFontSize(),
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );

  Widget _buildErrorButton(BuildContext context, WidgetRef ref) => ElevatedButton(
        onPressed: () {
          // ref.invalidate(isFollowingProvider(targetUserId));
          // Заглушка - обновление состояния
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[100],
          foregroundColor: Colors.red[700],
          padding: _getPadding(),
          minimumSize: _getMinimumSize(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Ошибка',
          style: TextStyle(
            fontSize: _getFontSize(),
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Future<void> _handleFollow(
    BuildContext context,
    WidgetRef ref,
    bool isFollowing,
  ) async {
    try {
      if (isFollowing) {
        // await ref.read(unfollowUserProvider(targetUserId).future);
        await Future.delayed(const Duration(seconds: 1)); // Заглушка
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Вы отписались')),
          );
        }
      } else {
        // await ref.read(followUserProvider(targetUserId).future);
        await Future.delayed(const Duration(seconds: 1)); // Заглушка
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Вы подписались')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case FollowButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case FollowButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case FollowButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    }
  }

  Size _getMinimumSize() {
    switch (size) {
      case FollowButtonSize.small:
        return const Size(80, 32);
      case FollowButtonSize.medium:
        return const Size(100, 40);
      case FollowButtonSize.large:
        return const Size(120, 48);
    }
  }

  double _getFontSize() {
    switch (size) {
      case FollowButtonSize.small:
        return 12;
      case FollowButtonSize.medium:
        return 14;
      case FollowButtonSize.large:
        return 16;
    }
  }
}

/// Размеры кнопки подписки
enum FollowButtonSize {
  small,
  medium,
  large,
}

/// Кнопка подписки для карточки поста
class PostFollowButton extends ConsumerWidget {
  const PostFollowButton({
    super.key,
    required this.authorId,
  });

  final String authorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return currentUser.when(
      data: (user) {
        if (user == null || user.id == authorId) {
          return const SizedBox.shrink();
        }

        return FollowButton(
          targetUserId: authorId,
          size: FollowButtonSize.small,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
