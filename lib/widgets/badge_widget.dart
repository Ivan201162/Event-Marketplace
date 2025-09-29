import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/badge.dart' as badge_model;
import '../providers/badge_providers.dart';
import 'animated_page_transition.dart';

/// Виджет для отображения бейджа
class BadgeWidget extends StatelessWidget {
  const BadgeWidget({
    super.key,
    required this.badge,
    this.size = 60,
    this.showTitle = false,
    this.showDescription = false,
    this.onTap,
  });
  final badge_model.Badge badge;
  final double size;
  final bool showTitle;
  final bool showDescription;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AnimatedButton(
        onPressed: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _parseColor(badge.color),
            borderRadius: BorderRadius.circular(size / 2),
            boxShadow: [
              BoxShadow(
                color: _parseColor(badge.color).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              badge.icon,
              style: TextStyle(
                fontSize: size * 0.4,
              ),
            ),
          ),
        ),
      );

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}

/// Виджет для отображения бейджа с информацией
class BadgeInfoWidget extends StatelessWidget {
  const BadgeInfoWidget({
    super.key,
    required this.badge,
    this.isCompact = false,
  });
  final badge_model.Badge badge;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactView(context);
    } else {
      return _buildFullView(context);
    }
  }

  Widget _buildCompactView(BuildContext context) => AnimatedCard(
        child: Row(
          children: [
            BadgeWidget(
              badge: badge,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    badge.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildFullView(BuildContext context) => AnimatedCard(
        child: Column(
          children: [
            BadgeWidget(
              badge: badge,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              badge.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(badge.earnedAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      );

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} нед. назад';
    } else {
      return '${(difference.inDays / 30).floor()} мес. назад';
    }
  }
}

/// Виджет для отображения коллекции бейджей
class BadgeCollectionWidget extends ConsumerWidget {
  const BadgeCollectionWidget({
    super.key,
    required this.userId,
    this.category,
    this.limit,
    this.showTitle = true,
  });
  final String userId;
  final badge_model.BadgeCategory? category;
  final int? limit;
  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(userBadgesProvider(userId));

    return badgesAsync.when(
      data: (badges) {
        var filteredBadges = badges.visible;

        if (category != null) {
          filteredBadges = filteredBadges.byCategory(category!);
        }

        if (limit != null) {
          filteredBadges = filteredBadges.take(limit!).toList();
        }

        if (filteredBadges.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Text(
                _getTitle(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
            ],
            if (category == null)
              _buildGridLayout(
                context,
                filteredBadges.cast<badge_model.Badge>(),
              )
            else
              _buildListLayout(
                context,
                filteredBadges.cast<badge_model.Badge>(),
              ),
          ],
        );
      },
      loading: () => _buildLoadingState(context),
      error: (error, stack) => _buildErrorState(context, error),
    );
  }

  Widget _buildGridLayout(
    BuildContext context,
    List<badge_model.Badge> badges,
  ) =>
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: badges
            .map(
              (badge) => BadgeWidget(
                badge: badge,
                size: 50,
                onTap: () => _showBadgeDetails(context, badge),
              ),
            )
            .toList()
            .cast<Widget>(),
      );

  Widget _buildListLayout(
    BuildContext context,
    List<badge_model.Badge> badges,
  ) =>
      Column(
        children: badges
            .map(
              (badge) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BadgeInfoWidget(
                  badge: badge,
                  isCompact: true,
                ),
              ),
            )
            .toList()
            .cast<Widget>(),
      );

  Widget _buildEmptyState(BuildContext context) => Center(
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Пока нет бейджей',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Выполняйте задания, чтобы получить бейджи!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildLoadingState(BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      );

  Widget _buildErrorState(BuildContext context, Object error) => Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки бейджей',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ),
      );

  String _getTitle() {
    if (category == null) return 'Бейджи';

    switch (category!) {
      case badge_model.BadgeCategory.specialist:
        return 'Бейджи специалиста';
      case badge_model.BadgeCategory.customer:
        return 'Бейджи заказчика';
      case badge_model.BadgeCategory.general:
        return 'Общие бейджи';
    }
  }

  void _showBadgeDetails(BuildContext context, badge_model.Badge badge) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(badge.title),
        content: BadgeInfoWidget(badge: badge),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения статистики бейджей
class BadgeStatsWidget extends ConsumerWidget {
  const BadgeStatsWidget({
    super.key,
    required this.userId,
  });
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userBadgeStatsProvider(userId));

    return statsAsync.when(
      data: (stats) => _buildStats(context, stats),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildError(context, error),
    );
  }

  Widget _buildStats(BuildContext context, badge_model.BadgeStats stats) =>
      AnimatedCard(
        child: Column(
          children: [
            Text(
              'Статистика бейджей',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'Всего',
                  stats.totalBadges,
                  Icons.emoji_events,
                ),
                _buildStatItem(
                  context,
                  'Специалист',
                  stats.specialistBadges,
                  Icons.person,
                ),
                _buildStatItem(
                  context,
                  'Заказчик',
                  stats.customerBadges,
                  Icons.event,
                ),
                _buildStatItem(
                  context,
                  'Общие',
                  stats.generalBadges,
                  Icons.star,
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildStatItem(
    BuildContext context,
    String label,
    int count,
    IconData icon,
  ) =>
      Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
        ],
      );

  Widget _buildError(BuildContext context, Object error) => Center(
        child: Text(
          'Ошибка загрузки статистики',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      );
}

/// Виджет для отображения таблицы лидеров по бейджам
class BadgeLeaderboardWidget extends ConsumerWidget {
  const BadgeLeaderboardWidget({
    super.key,
    this.limit = 10,
  });
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(badgeLeaderboardProvider(limit));

    return leaderboardAsync.when(
      data: (leaderboard) => _buildLeaderboard(context, leaderboard),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildError(context, error),
    );
  }

  Widget _buildLeaderboard(
    BuildContext context,
    List<badge_model.BadgeLeaderboardEntry> leaderboard,
  ) {
    if (leaderboard.isEmpty) {
      return _buildEmptyState(context);
    }

    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Таблица лидеров',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...leaderboard.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            return _buildLeaderboardItem(context, index + 1, user);
          }),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(
    BuildContext context,
    int position,
    badge_model.BadgeLeaderboardEntry user,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getPositionColor(position),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  position.toString(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundImage: user.userAvatar != null
                  ? NetworkImage(user.userAvatar!)
                  : null,
              child: user.userAvatar == null
                  ? Text(user.userName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.userName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    '${user.badgeCount} бейджей',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyState(BuildContext context) => Center(
        child: Text(
          'Таблица лидеров пуста',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
        ),
      );

  Widget _buildError(BuildContext context, Object error) => Center(
        child: Text(
          'Ошибка загрузки таблицы лидеров',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      );

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return Colors.blue;
    }
  }
}
