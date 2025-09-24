import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../models/event_idea.dart';
import '../providers/event_ideas_providers.dart';
import '../widgets/event_idea_card.dart';
import '../widgets/ideas_filter_bottom_sheet.dart';
import '../widgets/ideas_search_bar.dart';

/// Экран идей мероприятий в стиле Pinterest
class EventIdeasScreen extends ConsumerStatefulWidget {
  const EventIdeasScreen({super.key});

  @override
  ConsumerState<EventIdeasScreen> createState() => _EventIdeasScreenState();
}

class _EventIdeasScreenState extends ConsumerState<EventIdeasScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ref.watch(ideasFiltersProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Идеи для мероприятий'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: theme.primaryColor,
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color,
          tabs: const [
            Tab(text: 'Все'),
            Tab(text: 'Рекомендуемые'),
            Tab(text: 'Популярные'),
            Tab(text: 'Мои'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (filters.hasFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllIdeasTab(),
          _buildFeaturedIdeasTab(),
          _buildPopularIdeasTab(),
          _buildMyIdeasTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateIdeaDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Вкладка всех идей
  Widget _buildAllIdeasTab() {
    final ideasAsync = ref.watch(filteredIdeasProvider);

    return ideasAsync.when(
      data: (ideas) => _buildIdeasGrid(ideas),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки идей',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(filteredIdeasProvider),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  /// Вкладка рекомендуемых идей
  Widget _buildFeaturedIdeasTab() {
    final ideasAsync = ref.watch(featuredIdeasProvider);

    return ideasAsync.when(
      data: (ideas) => _buildIdeasGrid(ideas),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error),
    );
  }

  /// Вкладка популярных идей
  Widget _buildPopularIdeasTab() {
    final ideasAsync = ref.watch(popularIdeasProvider);

    return ideasAsync.when(
      data: (ideas) => _buildIdeasGrid(ideas),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error),
    );
  }

  /// Вкладка моих идей
  Widget _buildMyIdeasTab() {
    // TODO: Получить ID текущего пользователя
    const userId = 'current_user_id';
    final ideasAsync = ref.watch(userIdeasProvider(userId));

    return ideasAsync.when(
      data: (ideas) => _buildIdeasGrid(ideas),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error),
    );
  }

  /// Сетка идей в стиле Pinterest
  Widget _buildIdeasGrid(List<EventIdea> ideas) {
    if (ideas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Идей пока нет',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Будьте первым, кто поделится своей идеей!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showCreateIdeaDialog(context),
              child: const Text('Создать идею'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(filteredIdeasProvider);
      },
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childCount: ideas.length,
              itemBuilder: (BuildContext context, int index) {
                final idea = ideas[index];
                return EventIdeaCard(
                  idea: idea,
                  onTap: () => _showIdeaDetails(context, idea),
                  onLike: () => _handleLike(idea),
                  onSave: () => _handleSave(idea),
                  onShare: () => _handleShare(idea),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Виджет ошибки
  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(filteredIdeasProvider),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  /// Показать диалог поиска
  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск идей'),
        content: IdeasSearchBar(
          controller: _searchController,
          onSearch: (query) {
            ref.read(ideasFiltersProvider.notifier).updateSearchQuery(query);
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  /// Показать нижний лист фильтров
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const IdeasFilterBottomSheet(),
    );
  }

  /// Показать диалог создания идеи
  void _showCreateIdeaDialog(BuildContext context) {
    // TODO: Реализовать диалог создания идеи
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Создание идеи будет реализовано в следующем шаге'),
      ),
    );
  }

  /// Показать детали идеи
  void _showIdeaDetails(BuildContext context, EventIdea idea) {
    // TODO: Реализовать экран деталей идеи
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Детали идеи: ${idea.title}'),
      ),
    );
  }

  /// Обработать лайк
  void _handleLike(EventIdea idea) {
    // TODO: Получить ID текущего пользователя
    const userId = 'current_user_id';
    final service = ref.read(eventIdeasServiceProvider);
    
    service.likeIdea(idea.id, userId).then((_) {
      // Обновляем локальное состояние
      final likedIdeas = ref.read(likedIdeasProvider.notifier);
      if (idea.isLikedBy(userId)) {
        likedIdeas.removeLike(idea.id);
      } else {
        likedIdeas.addLike(idea.id);
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка лайка: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    });
  }

  /// Обработать сохранение
  void _handleSave(EventIdea idea) {
    // TODO: Получить ID текущего пользователя
    const userId = 'current_user_id';
    final service = ref.read(eventIdeasServiceProvider);
    
    service.saveIdea(idea.id, userId).then((_) {
      // Обновляем локальное состояние
      final favoriteIdeas = ref.read(favoriteIdeasProvider.notifier);
      if (idea.isSavedBy(userId)) {
        favoriteIdeas.removeFromFavorites(idea.id);
      } else {
        favoriteIdeas.addToFavorites(idea.id);
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    });
  }

  /// Обработать поделиться
  void _handleShare(EventIdea idea) {
    // TODO: Реализовать функционал поделиться
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Поделиться идеей: ${idea.title}'),
      ),
    );
  }
}
