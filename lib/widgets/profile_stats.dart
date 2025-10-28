import 'package:event_marketplace_app/models/user_profile.dart';
import 'package:flutter/material.dart';

/// Статистика профиля
class ProfileStats extends StatelessWidget {

  const ProfileStats({required this.profile, super.key});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Подписчики',
            value: profile.followersCount,
            onTap: () => _showFollowers(context),
          ),
          _StatItem(
            label: 'Подписки',
            value: profile.followingCount,
            onTap: () => _showFollowing(context),
          ),
          _StatItem(
            label: 'Посты',
            value: profile.postsCount,
            onTap: () => _showPosts(context),
          ),
          _StatItem(
            label: 'Идеи',
            value: profile.ideasCount,
            onTap: () => _showIdeas(context),
          ),
          _StatItem(
            label: 'Заявки',
            value: profile.requestsCount,
            onTap: () => _showRequests(context),
          ),
        ],
      ),
    );
  }

  void _showFollowers(BuildContext context) {
    // TODO: Показать список подписчиков
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Список подписчиков')),
    );
  }

  void _showFollowing(BuildContext context) {
    // TODO: Показать список подписок
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Список подписок')),
    );
  }

  void _showPosts(BuildContext context) {
    // TODO: Показать посты пользователя
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Посты пользователя')),
    );
  }

  void _showIdeas(BuildContext context) {
    // TODO: Показать идеи пользователя
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Идеи пользователя')),
    );
  }

  void _showRequests(BuildContext context) {
    // TODO: Показать заявки пользователя
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Заявки пользователя')),
    );
  }
}

/// Элемент статистики
class _StatItem extends StatelessWidget {

  const _StatItem({
    required this.label,
    required this.value,
    this.onTap,
  });
  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            _formatNumber(value),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }
}
