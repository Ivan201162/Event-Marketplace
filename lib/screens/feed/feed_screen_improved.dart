import 'package:event_marketplace_app/core/config/app_config.dart';
import 'package:event_marketplace_app/models/post.dart';
import 'package:event_marketplace_app/models/story.dart';
import 'package:event_marketplace_app/services/feed_service.dart';
import 'package:event_marketplace_app/services/follow_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер Stories для ленты
final feedStoriesProvider = FutureProvider<List<Story>>((ref) {
  if (!AppConfig.kShowFeedStories) {
    return Future.value([]);
  }
  final feedService = FeedService();
  return feedService.getStories();
});

/// Провайдер ленты по подпискам
final followingFeedProvider = StreamProvider<List<Post>>((ref) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId == null) {
    return Stream.value([]);
  }
  final feedService = FeedService();
  
  return feedService.getFollowingFeed(currentUserId);
});

/// Экран ленты (только посты от подписок)
class FeedScreenImproved extends ConsumerWidget {
  const FeedScreenImproved({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPosts = ref.watch(followingFeedProvider);
    final asyncStories = AppConfig.kShowFeedStories 
        ? ref.watch(feedStoriesProvider)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Лента'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(followingFeedProvider);
          if (AppConfig.kShowFeedStories) {
            ref.invalidate(feedStoriesProvider);
          }
        },
        child: asyncPosts.when(
          data: (posts) {
            // Stories section (если включены в конфиге)
            Widget? storiesSection;
            if (AppConfig.kShowFeedStories && asyncStories != null) {
              storiesSection = asyncStories.when(
                data: (stories) {
                  if (stories.isEmpty) return null;
                  return Container(
                    height: 100,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: stories.length,
                      itemBuilder: (context, index) {
                        final story = stories[index];
                        return _StoryItem(
                          isOwn: false,
                          userName: story.authorName ?? 'Пользователь',
                          onTap: () {
                            // TODO: Open story viewer
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox(height: 100),
                error: (_, __) => null,
              );
            }

            // Empty state
            if (posts.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    if (storiesSection != null) storiesSection!,
                    const SizedBox(height: 40),
                    Icon(
                      Icons.feed_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Подпишитесь на специалистов, чтобы видеть посты',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            // Posts list
            return CustomScrollView(
              slivers: [
                if (storiesSection != null)
                  SliverToBoxAdapter(child: storiesSection!),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = posts[index];
                      return _PostCard(post: post);
                    },
                    childCount: posts.length,
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Ошибка загрузки ленты: $error',
                  style: TextStyle(color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(followingFeedProvider);
                  },
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  const _StoryItem({
    required this.isOwn,
    required this.userName,
    required this.onTap,
  });

  final bool isOwn;
  final String userName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isOwn
                    ? LinearGradient(
                        colors: [
                          Colors.grey[300]!,
                          Colors.grey[400]!,
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                      ),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: isOwn
                    ? const Icon(Icons.add, color: Colors.white, size: 24)
                    : CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.grey[200],
                          child: Text(
                            userName.isNotEmpty
                                ? userName.substring(0, 1).toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                userName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.authorAvatar != null && post.authorAvatar!.isNotEmpty
                      ? NetworkImage(post.authorAvatar!)
                      : null,
                  child: post.authorAvatar == null || post.authorAvatar!.isEmpty
                      ? Text(
                          post.authorName.isNotEmpty
                              ? post.authorName.substring(0, 1).toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatTime(post.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Content
            if (post.text.isNotEmpty)
              Text(post.text, style: const TextStyle(fontSize: 14)),
            if (post.media.isNotEmpty) ...[
              const SizedBox(height: 12),
              // Media carousel or single image
              SizedBox(
                height: 300,
                child: PageView.builder(
                  itemCount: post.media.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      post.media[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Actions
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: post.isLiked ? Colors.red : null,
                  ),
                  onPressed: () {
                    // TODO: Implement like
                  },
                ),
                Text('${post.likesCount}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {
                    // TODO: Implement comment
                  },
                ),
                Text('${post.commentsCount}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {
                    // TODO: Implement share
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

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
