import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/recommendation_providers.dart';
import '../providers/auth_providers.dart';
import '../models/recommendation.dart';
import '../widgets/recommendation_widget.dart';
import '../widgets/animated_page_transition.dart' as app_transitions;

/// Экран рекомендаций
class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen>
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Рекомендации'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshRecommendations(),
            tooltip: 'Обновить рекомендации',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Для вас', icon: Icon(Icons.person)),
            Tab(text: 'Популярные', icon: Icon(Icons.trending_up)),
            Tab(text: 'Рядом', icon: Icon(Icons.location_on)),
            Tab(text: 'Новые', icon: Icon(Icons.new_releases)),
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
              _buildPersonalRecommendationsTab(user.id),
              _buildPopularRecommendationsTab(user.id),
              _buildNearbyRecommendationsTab(user.id),
              _buildNewRecommendationsTab(user.id),
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

  /// Вкладка персональных рекомендаций
  Widget _buildPersonalRecommendationsTab(String userId) {
    return app_transitions.AnimatedList(
      children: [
        // Статистика рекомендаций
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildRecommendationStats(userId),
        ),

        // Персональные рекомендации
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: RecommendationCollectionWidget(
            userId: userId,
            title: 'Рекомендации для вас',
            showTitle: true,
          ),
        ),
      ],
    );
  }

  /// Вкладка популярных рекомендаций
  Widget _buildPopularRecommendationsTab(String userId) {
    return app_transitions.AnimatedList(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: RecommendationCollectionWidget(
            userId: userId,
            type: RecommendationType.popularInCategory,
            title: 'Популярные специалисты',
            showTitle: true,
          ),
        ),
      ],
    );
  }

  /// Вкладка рекомендаций рядом
  Widget _buildNearbyRecommendationsTab(String userId) {
    return app_transitions.AnimatedList(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: RecommendationCollectionWidget(
            userId: userId,
            type: RecommendationType.nearby,
            title: 'Специалисты рядом с вами',
            showTitle: true,
          ),
        ),
      ],
    );
  }

  /// Вкладка новых рекомендаций
  Widget _buildNewRecommendationsTab(String userId) {
    return app_transitions.AnimatedList(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: RecommendationCollectionWidget(
            userId: userId,
            type: RecommendationType.trending,
            title: 'Новые и трендовые',
            showTitle: true,
          ),
        ),
      ],
    );
  }

  /// Статистика рекомендаций
  Widget _buildRecommendationStats(String userId) {
    final statsAsync = ref.watch(recommendationStatsProvider(userId));

    return statsAsync.when(
      data: (stats) => AnimatedCard(
        child: Column(
          children: [
            Text(
              'Ваши рекомендации',
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
                  stats.totalRecommendations.toString(),
                  Icons.recommend,
                ),
                _buildStatItem(
                  context,
                  'Средняя оценка',
                  '${(stats.averageScore * 100).toInt()}%',
                  Icons.star,
                ),
                _buildStatItem(
                  context,
                  'Типов',
                  stats.byType.length.toString(),
                  Icons.category,
                ),
              ],
            ),
            if (stats.topTypes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Популярные типы:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: stats.topTypes.take(3).map((type) {
                  final typeInfo = type.info;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _parseColor(typeInfo.color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(typeInfo.icon),
                        const SizedBox(width: 4),
                        Text(
                          typeInfo.title,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _parseColor(typeInfo.color),
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  /// Элемент статистики
  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
      ],
    );
  }

  /// Обновить рекомендации
  void _refreshRecommendations() {
    final currentUser = ref.read(currentUserProvider);
    currentUser.whenData((user) {
      if (user != null) {
        ref.read(recommendationManagerProvider).refreshRecommendations(user.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Рекомендации обновляются...')),
        );
      }
    });
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}

/// Экран настроек рекомендаций
class RecommendationSettingsScreen extends ConsumerWidget {
  const RecommendationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки рекомендаций'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: AnimatedList(
        children: [
          // Настройки типов рекомендаций
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildRecommendationTypesSettings(context),
          ),

          // Настройки фильтров
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildFiltersSettings(context),
          ),

          // Действия
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildActions(context, ref),
          ),
        ],
      ),
    );
  }

  /// Настройки типов рекомендаций
  Widget _buildRecommendationTypesSettings(BuildContext context) {
    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Типы рекомендаций',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...RecommendationType.values.map((type) {
            final typeInfo = type.info;
            return _buildRecommendationTypeSwitch(
              context,
              type,
              typeInfo,
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Переключатель типа рекомендации
  Widget _buildRecommendationTypeSwitch(
    BuildContext context,
    RecommendationType type,
    RecommendationTypeInfo typeInfo,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _parseColor(typeInfo.color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              typeInfo.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeInfo.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  typeInfo.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: true, // Здесь будет реальное значение из настроек
            onChanged: (value) {
              // Здесь будет логика изменения настроек
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  /// Настройки фильтров
  Widget _buildFiltersSettings(BuildContext context) {
    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Фильтры',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildFilterItem(
            context,
            'Ценовой диапазон',
            'От 1000 до 10000 ₽/ч',
            Icons.attach_money,
          ),
          _buildFilterItem(
            context,
            'Рейтинг',
            'От 4.0 звёзд',
            Icons.star,
          ),
          _buildFilterItem(
            context,
            'Местоположение',
            'В радиусе 50 км',
            Icons.location_on,
          ),
          _buildFilterItem(
            context,
            'Доступность',
            'Доступны сейчас',
            Icons.schedule,
          ),
        ],
      ),
    );
  }

  /// Элемент фильтра
  Widget _buildFilterItem(
      BuildContext context, String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Здесь будет логика настройки фильтра
        },
      ),
    );
  }

  /// Действия
  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return AnimatedCard(
      child: Column(
        children: [
          _buildActionButton(
            context,
            'Сбросить настройки',
            'Вернуть настройки по умолчанию',
            Icons.restore,
            () => _resetSettings(context),
          ),
          _buildActionButton(
            context,
            'Очистить историю',
            'Удалить историю просмотров',
            Icons.clear_all,
            () => _clearHistory(context, ref),
          ),
        ],
      ),
    );
  }

  /// Кнопка действия
  Widget _buildActionButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.error),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  /// Сбросить настройки
  void _resetSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить настройки'),
        content: const Text(
          'Вы уверены, что хотите сбросить все настройки рекомендаций?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Настройки сброшены')),
              );
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }

  /// Очистить историю
  void _clearHistory(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить историю'),
        content: const Text(
          'Вы уверены, что хотите удалить всю историю просмотров?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(recommendationInteractionProvider.notifier)
                  .clearInteractions();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('История очищена')),
              );
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}
