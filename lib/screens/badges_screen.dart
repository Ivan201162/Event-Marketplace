import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../models/badge.dart' as models;
import '../widgets/badge_widget.dart';
import '../widgets/animated_page_transition.dart' as custom;

/// Экран бейджей и достижений
class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    // final userRole = ref.watch(currentUserRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бейджи и достижения'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Все', icon: Icon(Icons.emoji_events)),
            Tab(text: 'Специалист', icon: Icon(Icons.person)),
            Tab(text: 'Заказчик', icon: Icon(Icons.event)),
            Tab(text: 'Лидеры', icon: Icon(Icons.leaderboard)),
          ],
        ),
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Пользователь не найден'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAllBadgesTab(user.id),
              _buildCategoryBadgesTab(user.id, models.BadgeCategory.specialist),
              _buildCategoryBadgesTab(user.id, models.BadgeCategory.customer),
              _buildLeaderboardTab(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Ошибка загрузки: $error'),
        ),
      ),
    );
  }

  /// Вкладка со всеми бейджами
  Widget _buildAllBadgesTab(String userId) {
    return custom.AnimatedList(
      children: [
        // Статистика
        Padding(
          padding: const EdgeInsets.all(16),
          child: BadgeStatsWidget(userId: userId),
        ),

        // Последние бейджи
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Последние бейджи',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              BadgeCollectionWidget(
                userId: userId,
                limit: 6,
                showTitle: false,
              ),
            ],
          ),
        ),

        // Все бейджи
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Все бейджи',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              BadgeCollectionWidget(
                userId: userId,
                showTitle: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Вкладка с бейджами по категории
  Widget _buildCategoryBadgesTab(String userId, models.BadgeCategory category) {
    return custom.AnimatedList(
      children: [
        // Информация о категории
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildCategoryInfo(category),
        ),

        // Бейджи категории
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: BadgeCollectionWidget(
            userId: userId,
            category: category,
            showTitle: false,
          ),
        ),
      ],
    );
  }

  /// Вкладка с таблицей лидеров
  Widget _buildLeaderboardTab() {
    return custom.AnimatedList(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: BadgeLeaderboardWidget(limit: 20),
        ),
      ],
    );
  }

  /// Информация о категории бейджей
  Widget _buildCategoryInfo(models.BadgeCategory category) {
    final info = _getCategoryInfo(category);

    return custom.AnimatedCard(
      child: Column(
        children: [
          Icon(
            info.icon,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            info.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            info.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Получить информацию о категории
  CategoryInfo _getCategoryInfo(models.BadgeCategory category) {
    switch (category) {
      case models.BadgeCategory.specialist:
        return CategoryInfo(
          title: 'Бейджи специалиста',
          description:
              'Получайте бейджи за качественную работу и достижения в профессии',
          icon: Icons.person,
        );
      case models.BadgeCategory.customer:
        return CategoryInfo(
          title: 'Бейджи заказчика',
          description:
              'Зарабатывайте бейджи за активность и организацию мероприятий',
          icon: Icons.event,
        );
      case models.BadgeCategory.general:
        return CategoryInfo(
          title: 'Общие бейджи',
          description: 'Специальные бейджи за участие в жизни сообщества',
          icon: Icons.star,
        );
    }
  }
}

/// Информация о категории
class CategoryInfo {
  final String title;
  final String description;
  final IconData icon;

  const CategoryInfo({
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Экран детального просмотра бейджа
class BadgeDetailScreen extends StatelessWidget {
  final models.Badge badge;

  const BadgeDetailScreen({
    super.key,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали бейджа'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: AnimatedList(
        children: [
          // Основная информация
          Padding(
            padding: const EdgeInsets.all(16),
            child: BadgeInfoWidget(badge: badge),
          ),

          // Дополнительная информация
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildAdditionalInfo(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(BuildContext context) {
    return custom.AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Дополнительная информация',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            'Тип бейджа',
            badge.type.info.category.name,
            Icons.category,
          ),
          _buildInfoRow(
            context,
            'Дата получения',
            _formatDate(badge.earnedAt),
            Icons.calendar_today,
          ),
          _buildInfoRow(
            context,
            'Видимость',
            badge.isVisible ? 'Видимый' : 'Скрытый',
            Icons.visibility,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
