import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../models/user_profile.dart';
import '../providers/user_profile_provider.dart';
import 'post_detail_screen.dart';

/// Виджет для отображения постов в виде сетки
class PostsGrid extends ConsumerWidget {
  const PostsGrid({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(userPostsProvider(userId));

    return postsAsync.when(
      data: (posts) => _buildPostsGrid(context, posts),
      loading: _buildLoadingGrid,
      error: (error, stack) => _buildErrorWidget(context, error.toString()),
    );
  }

  Widget _buildPostsGrid(BuildContext context, List<UserPost> posts) {
    if (posts.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO(developer): Обновить посты
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return _buildPostItem(context, post);
        },
      ),
    );
  }

  Widget _buildPostItem(BuildContext context, UserPost post) => GestureDetector(
        onTap: () => _openPostDetail(context, post),
        child: Container(
          decoration:
              BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Изображение или видео
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: post.isVideo
                    ? Stack(
                        children: [
                          if (post.thumbnailUrl != null)
                            CachedNetworkImage(
                              imageUrl: post.thumbnailUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.video_library),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.video_library),
                              ),
                            )
                          else
                            Container(
                                color: Colors.grey[300], child: const Icon(Icons.video_library)),
                          const Positioned(
                            bottom: 4,
                            right: 4,
                            child: Icon(Icons.play_circle_filled, color: Colors.white, size: 20),
                          ),
                        ],
                      )
                    : post.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: post.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey[300], child: const Icon(Icons.image)),
                            errorWidget: (context, url, error) =>
                                Container(color: Colors.grey[300], child: const Icon(Icons.image)),
                          )
                        : Container(color: Colors.grey[300], child: const Icon(Icons.image)),
              ),
              // Индикатор множественных медиа
              if (post.isVideo)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(Icons.video_library, color: Colors.white, size: 16),
                ),
              // Статистика поста
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.white, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            post.likes.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.comment, color: Colors.white, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            post.comments.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildLoadingGrid() => GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: 9,
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration:
                BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
          ),
        ),
      );

  Widget _buildEmptyState(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grid_on, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Пока нет постов',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Когда пользователь опубликует пост,\nон появится здесь',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildErrorWidget(BuildContext context, String error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки постов',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  void _openPostDetail(BuildContext context, UserPost post) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => PostDetailScreen(post: post)));
  }
}
