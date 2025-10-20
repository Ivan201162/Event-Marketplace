import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/post.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feed_providers.dart';
import '../../widgets/post_card.dart';

/// Feed screen with posts
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsStreamProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Лента'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Create new post
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Создание поста пока не реализовано')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(postsStreamProvider);
            },
          ),
        ],
      ),
      body: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.feed_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Пока нет постов',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Будьте первым, кто поделится новостью!',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(postsStreamProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostCard(
                  post: post,
                  onTap: () {
                    // TODO: Navigate to post detail
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Пост: ${post.text ?? 'Без текста'}')),
                    );
                  },
                  onLike: () => _handleLike(post),
                  onComment: () {
                    // TODO: Navigate to comments
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Комментарии пока не реализованы')),
                    );
                  },
                  onShare: () {
                    // TODO: Share post
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Поделиться пока не реализовано')),
                    );
                  },
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
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки ленты',
                style: TextStyle(fontSize: 18, color: Colors.red[700]),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(postsStreamProvider);
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLike(Post post) {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Войдите в аккаунт для лайков')),
      );
      return;
    }

    final postService = ref.read(postServiceProvider);
    if (post.isLikedBy(currentUser.uid)) {
      postService.unlikePost(post.id, currentUser.uid);
    } else {
      postService.likePost(post.id, currentUser.uid);
    }
  }
}
