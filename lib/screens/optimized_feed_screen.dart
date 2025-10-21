import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enhanced_feed_post.dart';
import '../providers/optimized_data_providers.dart';
import '../services/optimized_feed_service.dart';

/// Оптимизированная лента с реальными данными и обработкой состояний
class OptimizedFeedScreen extends ConsumerStatefulWidget {
  const OptimizedFeedScreen({super.key});

  @override
  ConsumerState<OptimizedFeedScreen> createState() => _OptimizedFeedScreenState();
}

class _OptimizedFeedScreenState extends ConsumerState<OptimizedFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final feedService = ref.read(optimizedFeedServiceProvider);
      final result = await feedService.getPosts(
        limit: 20,
        lastDocument: _lastDocument,
      );

      if (result.posts.isNotEmpty) {
        setState(() {
          _lastDocument = result.lastDocument;
        });
      }
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedProvider({'limit': 20}));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Лента'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshFeed(),
          ),
        ],
      ),
      body: feedAsync.when(
        data: (feedState) => _buildFeedContent(feedState),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildFeedContent(FeedState feedState) {
    if (feedState.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshFeed,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: feedState.posts.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < feedState.posts.length) {
            final post = feedState.posts[index];
            return _FeedPostCard(post: post);
          } else {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Загрузка ленты...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.feed_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Лента пуста',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Здесь будут появляться новые посты',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshFeed,
            icon: const Icon(Icons.refresh),
            label: const Text('Обновить'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки ленты',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshFeed,
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshFeed() async {
    setState(() {
      _lastDocument = null;
    });
    ref.invalidate(feedProvider);
  }
}

class _FeedPostCard extends ConsumerWidget {
  const _FeedPostCard({required this.post});
  final EnhancedFeedPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedService = ref.read(optimizedFeedServiceProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок поста
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.authorAvatar != null
                      ? CachedNetworkImageProvider(post.authorAvatar!)
                      : null,
                  child: post.authorAvatar == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDate(post.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handlePostAction(context, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'save', child: Text('Сохранить')),
                    const PopupMenuItem(value: 'share', child: Text('Поделиться')),
                    const PopupMenuItem(value: 'report', child: Text('Пожаловаться')),
                  ],
                ),
              ],
            ),
          ),

          // Контент поста
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.content,
                style: const TextStyle(fontSize: 14),
              ),
            ),

          // Медиа контент
          if (post.media.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              child: _buildMediaContent(post.media),
            ),

          // Теги
          if (post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: post.tags
                    .map(
                      (tag) => Chip(
                        label: Text('#$tag'),
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          // Действия с постом
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _toggleLike(feedService),
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: post.isLiked ? Colors.red : null,
                  ),
                ),
                Text('${post.likes}'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    // Открыть комментарии
                  },
                  icon: const Icon(Icons.comment_outlined),
                ),
                Text('${post.comments}'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    // Поделиться
                  },
                  icon: const Icon(Icons.share_outlined),
                ),
                Text('${post.shares}'),
                const Spacer(),
                IconButton(
                  onPressed: () => _toggleSave(feedService),
                  icon: Icon(
                    post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: post.isSaved ? Colors.amber : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent(List<FeedPostMedia> media) {
    if (media.length == 1) {
      return _buildSingleMedia(media.first);
    } else {
      return _buildMultipleMedia(media);
    }
  }

  Widget _buildSingleMedia(FeedPostMedia media) {
    switch (media.type) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: media.url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.error)),
            ),
          ),
        );
      case 'video':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: media.thumbnail ?? media.url,
                fit: BoxFit.cover,
                height: 200,
                width: double.infinity,
              ),
              const Center(
                child: Icon(Icons.play_circle_filled, size: 64, color: Colors.white),
              ),
            ],
          ),
        );
      default:
        return Container(
          height: 200,
          color: Colors.grey[300],
          child: const Center(child: Icon(Icons.media)),
        );
    }
  }

  Widget _buildMultipleMedia(List<FeedPostMedia> media) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: media[index].url,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.error)),
          ),
        ),
      ),
    );
  }

  void _handlePostAction(BuildContext context, String action) {
    switch (action) {
      case 'save':
        // TODO: Сохранить пост
        break;
      case 'share':
        // TODO: Поделиться постом
        break;
      case 'report':
        // TODO: Пожаловаться на пост
        break;
    }
  }

  void _toggleLike(OptimizedFeedService feedService) {
    // TODO: Получить userId из контекста
    feedService.toggleLike(post.id, 'current_user_id');
  }

  void _toggleSave(OptimizedFeedService feedService) {
    // TODO: Получить userId из контекста
    feedService.toggleSave(post.id, 'current_user_id');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'только что';
    }
  }
}