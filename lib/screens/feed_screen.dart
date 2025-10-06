import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../widgets/modern_navigation_bar.dart';

/// Экран ленты контента
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Лента'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: context.surfaceColor,
          foregroundColor: context.textPrimary,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: context.primaryColor,
            labelColor: context.primaryColor,
            unselectedLabelColor: context.textSecondary,
            tabs: const [
              Tab(text: 'Для вас'),
              Tab(text: 'Подписки'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // TODO(developer): Поиск в ленте
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // TODO(developer): Уведомления
              },
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildForYouTab(),
            _buildFollowingTab(),
          ],
        ),
        floatingActionButton: ModernFAB(
          onPressed: () {
            // TODO: Реализовать создание поста
          },
          tooltip: 'Создать пост',
        ),
      );

  Widget _buildForYouTab() => CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildStoriesSection(),
          _buildPostsSection(),
        ],
      );

  Widget _buildFollowingTab() => CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildStoriesSection(),
          _buildPostsSection(),
        ],
      );

  Widget _buildStoriesSection() => SliverToBoxAdapter(
        child: Container(
          height: 120,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 10,
            itemBuilder: (context, index) => _buildStoryItem(index),
          ),
        ),
      );

  Widget _buildStoryItem(int index) {
    final isAddStory = index == 0;

    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (isAddStory) {
                // TODO(developer): Добавить сторис
              } else {
                // TODO(developer): Просмотр сторис
              }
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isAddStory ? null : BrandColors.primaryGradient,
                color: isAddStory
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : null,
                border: Border.all(
                  color:
                      isAddStory ? context.textSecondary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: isAddStory
                  ? Icon(
                      Icons.add,
                      color: context.textSecondary,
                      size: 24,
                    )
                  : ClipOval(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ClipOval(
                          child: Container(
                            color: context.primaryColor,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAddStory ? 'Ваша история' : 'Пользователь $index',
            style: context.textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() => SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildPostCard(index),
          childCount: 20,
        ),
      );

  Widget _buildPostCard(int index) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPostHeader(index),
                const SizedBox(height: 12),
                _buildPostContent(index),
                const SizedBox(height: 12),
                _buildPostActions(index),
              ],
            ),
          ),
        ),
      );

  Widget _buildPostHeader(int index) => Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: context.primaryColor,
            child: Text(
              'U$index',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Пользователь $index',
                  style: context.textTheme.titleMedium,
                ),
                Text(
                  '2 часа назад',
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO(developer): Меню поста
            },
          ),
        ],
      );

  Widget _buildPostContent(int index) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Это пример поста в ленте. Здесь может быть текст, фото или видео. '
            'Пользователи могут делиться своими идеями и опытом.',
            style: context.textTheme.bodyMedium,
          ),
          if (index % 3 == 0) ...[
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 48,
                  color: context.textSecondary,
                ),
              ),
            ),
          ],
        ],
      );

  Widget _buildPostActions(int index) => Row(
        children: [
          IconButton(
            icon: Icon(
              index % 2 == 0 ? Icons.favorite : Icons.favorite_border,
              color: index % 2 == 0 ? Colors.red : context.textSecondary,
            ),
            onPressed: () {
              // TODO(developer): Лайк поста
            },
          ),
          Text(
            '${index * 3 + 12}',
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(
              Icons.chat_bubble_outline,
              color: context.textSecondary,
            ),
            onPressed: () {
              // TODO(developer): Комментарии
            },
          ),
          Text(
            '${index + 5}',
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(
              Icons.share_outlined,
              color: context.textSecondary,
            ),
            onPressed: () {
              // TODO(developer): Поделиться
            },
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.bookmark_border,
              color: context.textSecondary,
            ),
            onPressed: () {
              // TODO(developer): Сохранить
            },
          ),
        ],
      );
}
