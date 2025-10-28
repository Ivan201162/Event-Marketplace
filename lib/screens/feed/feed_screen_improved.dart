import 'package:event_marketplace_app/core/app_components.dart';
import 'package:event_marketplace_app/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Упрощенный экран ленты
class FeedScreenImproved extends ConsumerWidget {
  const FeedScreenImproved({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          // TODO: Implement refresh
          await Future.delayed(const Duration(seconds: 1));
        },
        child: CustomScrollView(
          slivers: [
            // Stories section
            SliverToBoxAdapter(
              child: Container(
                height: 100,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _StoryItem(
                        isOwn: index == 0,
                        userName:
                            index == 0 ? 'Ваша история' : 'Пользователь $index',
                        onTap: () {
                          // TODO: Open story
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            // Posts section
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _PostCard(
                    userName: 'Пользователь ${index + 1}',
                    postTime: '${index + 1}ч назад',
                    postContent:
                        'Это пример поста номер ${index + 1}. Здесь будет отображаться контент пользователей.',
                    likesCount: (index + 1) * 10,
                    commentsCount: (index + 1) * 3,
                    onLike: () {
                      // TODO: Implement like
                    },
                    onComment: () {
                      // TODO: Implement comment
                    },
                    onShare: () {
                      // TODO: Implement share
                    },
                  );
                },
                childCount: 20, // Mock data
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement create post
        },
        child: const Icon(Icons.add),
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
                        Theme.of(context).primaryColor.withValues(alpha: 0.7),
                      ],
                    ),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Center(
              child: isOwn
                  ? const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24,
                    )
                  : CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.grey[200],
                        child: Text(
                          userName.substring(0, 1).toUpperCase(),
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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {

  const _PostCard({
    required this.userName,
    required this.postTime,
    required this.postContent,
    required this.likesCount,
    required this.commentsCount,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });
  final String userName;
  final String postTime;
  final String postContent;
  final int likesCount;
  final int commentsCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

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
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    userName.substring(0, 1).toUpperCase(),
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
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        postTime,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // TODO: Show post options
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Content
            Text(
              postContent,
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: onLike,
                ),
                Text('$likesCount'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: onComment,
                ),
                Text('$commentsCount'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: onShare,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
