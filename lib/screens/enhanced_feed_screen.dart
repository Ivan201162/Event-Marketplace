import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enhanced_feed_post.dart';
import '../providers/enhanced_feed_providers.dart';

class EnhancedFeedScreen extends ConsumerStatefulWidget {
  const EnhancedFeedScreen({super.key});

  @override
  ConsumerState<EnhancedFeedScreen> createState() => _EnhancedFeedScreenState();
}

class _EnhancedFeedScreenState extends ConsumerState<EnhancedFeedScreen> {
  @override
  Widget build(BuildContext context) {
    final feedNotifier = ref.watch(enhancedFeedProvider);
    final feedState = feedNotifier.state;

    return RefreshIndicator(
      onRefresh: () => feedNotifier.refreshFeed(),
      child: _buildFeedContent(feedState),
    );
  }

  Widget _buildFeedContent(EnhancedFeedState state) {
    if (state.isLoading && state.posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && state.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(enhancedFeedProvider).refreshFeed(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (state.posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.feed_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Лента пуста',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Здесь будут появляться новые посты',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.posts.length,
      itemBuilder: (context, index) {
        final post = state.posts[index];
        return _FeedPostCard(post: post);
      },
    );
  }
}

class _FeedPostCard extends ConsumerWidget {

  const _FeedPostCard({required this.post});
  final EnhancedFeedPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedNotifier = ref.read(enhancedFeedProvider);

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
                  child: post.authorAvatar == null
                      ? const Icon(Icons.person)
                      : null,
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
                  onSelected: (value) {
                    // Обработка действий с постом
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'save',
                      child: Text('Сохранить'),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Text('Поделиться'),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Text('Пожаловаться'),
                    ),
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
                    .map((tag) => Chip(
                          label: Text('#$tag'),
                          backgroundColor:
                              Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          labelStyle: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                          ),
                        ),)
                    .toList(),
              ),
            ),

          // Действия с постом
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => feedNotifier.toggleLike(post.id),
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
                  onPressed: () => feedNotifier.toggleSave(post.id),
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
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.error),
              ),
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
                child: Icon(
                  Icons.play_circle_filled,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      default:
        return Container(
          height: 200,
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.media),
          ),
        );
    }
  }

  Widget _buildMultipleMedia(List<FeedPostMedia> media) => GridView.builder(
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
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.error),
              ),
            ),
          ),
        ),
    );

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
