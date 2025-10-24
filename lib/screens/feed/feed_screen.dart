import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/feed_providers.dart';
import '../../widgets/stories_bar.dart';
import '../../widgets/feed_post_card.dart';

/// Экран ленты с Stories и постами
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  String _selectedSort = 'newest';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Загрузить больше постов
      ref.read(feedProvider.notifier).loadMorePosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Лента'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(feedProvider.notifier).refreshFeed();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Stories
            const SliverToBoxAdapter(
              child: StoriesBar(),
            ),
            
            // Посты
            feedState.when(
              data: (posts) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= posts.length) return null;
                    return FeedPostCard(
                      post: posts[index],
                      onLike: () => _likePost(posts[index].id),
                      onComment: () => _commentPost(posts[index].id),
                      onShare: () => _sharePost(posts[index].id),
                      onSave: () => _savePost(posts[index].id),
                    );
                  },
                  childCount: posts.length,
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Ошибка загрузки ленты: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(feedProvider.notifier).refreshFeed(),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Введите запрос...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(feedProvider.notifier).searchPosts(_searchQuery);
            },
            child: const Text('Найти'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Все'),
              leading: Radio<String>(
                value: 'all',
                groupValue: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value!),
              ),
            ),
            ListTile(
              title: const Text('Популярные'),
              leading: Radio<String>(
                value: 'popular',
                groupValue: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value!),
              ),
            ),
            ListTile(
              title: const Text('Недавние'),
              leading: Radio<String>(
                value: 'recent',
                groupValue: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(feedProvider.notifier).filterPosts(_selectedFilter);
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }

  void _likePost(String postId) {
    ref.read(feedProvider.notifier).likePost(postId);
  }

  void _commentPost(String postId) {
    // Открыть экран комментариев
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Открытие комментариев для поста $postId')),
    );
  }

  void _sharePost(String postId) {
    ref.read(feedProvider.notifier).sharePost(postId);
  }

  void _savePost(String postId) {
    ref.read(feedProvider.notifier).savePost(postId);
  }
}