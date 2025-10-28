import 'package:event_marketplace_app/models/user.dart';
import 'package:flutter/material.dart';

/// Виджет статистики профиля
class ProfileStatsWidget extends StatelessWidget {
  const ProfileStatsWidget(
      {required this.user, required this.isCurrentUser, super.key,});

  final AppUser user;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Статистика для специалистов
          if (user.isSpecialist) ...[
            Expanded(
              child: _buildStatItem(
                theme,
                'Заказы',
                '0', // TODO: Получить из данных
                Icons.work_outline,
              ),
            ),
            Container(width: 1, height: 40, color: theme.dividerColor),
            Expanded(
              child: _buildStatItem(
                theme,
                'Рейтинг',
                '4.8', // TODO: Получить из данных
                Icons.star_outline,
              ),
            ),
            Container(width: 1, height: 40, color: theme.dividerColor),
            Expanded(
              child: _buildStatItem(
                theme,
                'Отзывы',
                '0', // TODO: Получить из данных
                Icons.rate_review_outlined,
              ),
            ),
          ] else ...[
            // Статистика для клиентов
            Expanded(
              child: _buildStatItem(
                theme,
                'Заказы',
                '0', // TODO: Получить из данных
                Icons.shopping_bag_outlined,
              ),
            ),
            Container(width: 1, height: 40, color: theme.dividerColor),
            Expanded(
              child: _buildStatItem(
                theme,
                'Избранное',
                '0', // TODO: Получить из данных
                Icons.favorite_outline,
              ),
            ),
            Container(width: 1, height: 40, color: theme.dividerColor),
            Expanded(
              child: _buildStatItem(
                theme,
                'Отзывы',
                '0', // TODO: Получить из данных
                Icons.rate_review_outlined,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
          ThemeData theme, String label, String value, IconData icon,) =>
      Column(
        children: [
          Icon(icon, color: theme.primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      );
}
