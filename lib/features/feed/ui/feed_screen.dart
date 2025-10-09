import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/feed_model.dart';
import '../providers/feed_providers.dart';
import 'create_post_screen.dart';
import 'feed_filters_bar.dart';
import 'feed_post_card.dart';

/// Экран ленты активности
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
  Widget build(BuildContext context) {
    final feedPosts = ref.watch(feedPostsProvider);
    final feedError = ref.watch(feedErrorProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Лента',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.black,
              size: 28,
            ),
            onPressed: () => _showCreatePostDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Все'),
            Tab(text: 'Подписки'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Панель фильтров
          const FeedFiltersBar(),

          // Контент ленты
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Вкладка "Все"
                _buildFeedContent(feedPosts, FeedFilter.all),
                // Вкладка "Подписки"
                _buildFeedContent(feedPosts, FeedFilter.subscriptions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedContent(
          AsyncValue<List<FeedPost>> feedPosts, FeedFilter filter,) =>
      feedPosts.when(
        data: (posts) {
          if (posts.isEmpty) {
            return _buildEmptyState(filter);
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Обновляем данные
              ref.invalidate(feedPostsProvider);
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return FeedPostCard(
                  post: post,
                  onLike: () => _handleLike(post.id),
                  onComment: () => _handleComment(post),
                  onShare: () => _handleShare(post),
                  onProfileTap: () => _handleProfileTap(post.authorId),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки ленты',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(feedPostsProvider);
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyState(FeedFilter filter) {
    String title;
    String subtitle;
    IconData icon;

    switch (filter) {
      case FeedFilter.subscriptions:
        title = 'Нет подписок';
        subtitle = 'Подпишитесь на специалистов, чтобы видеть их посты здесь';
        icon = Icons.person_add;
        break;
      case FeedFilter.photos:
        title = 'Нет фото';
        subtitle = 'В вашем городе пока нет фото постов';
        icon = Icons.photo_camera;
        break;
      case FeedFilter.videos:
        title = 'Нет видео';
        subtitle = 'В вашем городе пока нет видео постов';
        icon = Icons.videocam;
        break;
      default:
        title = 'Лента пуста';
        subtitle = 'Будьте первым, кто опубликует пост в вашем городе!';
        icon = Icons.feed;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          const SizedBox(height: 24),
          if (filter == FeedFilter.all)
            ElevatedButton.icon(
              onPressed: () => _showCreatePostDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Создать пост'),
            ),
        ],
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePostScreen(),
    );
  }

  void _handleLike(String postId) {
    ref.read(likePostProvider(postId).future);
  }

  void _handleComment(FeedPost post) {
    // TODO(developer): Открыть экран комментариев
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Комментарии будут добавлены позже')),
    );
  }

  void _handleShare(FeedPost post) {
    // TODO(developer): Реализовать функционал шаринга
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция шаринга будет добавлена позже')),
    );
  }

  void _handleProfileTap(String authorId) {
    // TODO(developer): Перейти к профилю автора
    context.push('/profile/$authorId');
  }
}
