import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/auth_providers.dart';
import '../data/feed_model.dart';
import 'feed_video_player.dart';
import 'follow_button.dart';

/// Карточка поста в ленте
class FeedPostCard extends ConsumerWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onProfileTap,
  });

  final FeedPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isLiked = currentUser.when(
      data: (user) => user != null && post.likedBy.contains(user.id),
      loading: () => false,
      error: (_, __) => false,
    );
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок поста (автор)
          _buildPostHeader(context),

          // Описание поста
          if (post.description.isNotEmpty) _buildPostDescription(),

          // Медиа контент
          if (post.mediaUrl.isNotEmpty) _buildMediaContent(context),

          // Действия (лайки, комментарии, шаринг)
          _buildPostActions(context, isLiked),

          // Статистика
          _buildPostStats(),
        ],
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Аватар автора
            GestureDetector(
              onTap: onProfileTap,
              child: CircleAvatar(
                radius: 20,
                backgroundImage: post.authorAvatar.isNotEmpty
                    ? CachedNetworkImageProvider(post.authorAvatar)
                    : null,
                child: post.authorAvatar.isEmpty
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
            ),

            const SizedBox(width: 12),

            // Информация об авторе
            Expanded(
              child: GestureDetector(
                onTap: onProfileTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.authorCity,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(post.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Кнопка подписки или меню поста
            Row(
              children: [
                PostFollowButton(authorId: post.authorId),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'report':
                        _showReportDialog(context);
                        break;
                      case 'hide':
                        _hidePost(context);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.report, size: 20),
                          SizedBox(width: 8),
                          Text('Пожаловаться'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'hide',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_off, size: 20),
                          SizedBox(width: 8),
                          Text('Скрыть'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildPostDescription() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          post.description,
          style: const TextStyle(fontSize: 16),
        ),
      );

  Widget _buildMediaContent(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 12),
        child: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(12)),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: post.type == PostType.video
                ? FeedVideoPlayer(
                    videoUrl: post.mediaUrl,
                    thumbnailUrl:
                        post.mediaUrl, // TODO(developer): Добавить превью
                  )
                : GestureDetector(
                    onTap: () => _showImageFullscreen(context),
                    child: CachedNetworkImage(
                      imageUrl: post.mediaUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.error, color: Colors.red),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      );

  Widget _buildPostActions(BuildContext context, bool isLiked) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Лайк
            _buildActionButton(
              icon: isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : Colors.grey[600],
              onTap: onLike,
            ),

            const SizedBox(width: 16),

            // Комментарии
            _buildActionButton(
              icon: Icons.chat_bubble_outline,
              onTap: onComment,
            ),

            const SizedBox(width: 16),

            // Шаринг
            _buildActionButton(
              icon: Icons.share,
              onTap: onShare,
            ),

            const Spacer(),

            // Категории
            if (post.taggedCategories.isNotEmpty)
              Wrap(
                spacing: 4,
                children: post.taggedCategories
                    .take(2)
                    .map(
                      (category) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      );

  Widget _buildPostStats() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.likes > 0)
              Text(
                '${post.likes} ${_getLikesText(post.likes)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            if (post.commentsCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${post.commentsCount} ${_getCommentsText(post.commentsCount)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _buildActionButton({
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Icon(
          icon,
          color: color ?? Colors.grey[600],
          size: 24,
        ),
      );

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return DateFormat('d MMM', 'ru').format(date);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м';
    } else {
      return 'только что';
    }
  }

  String _getLikesText(int count) {
    if (count == 1) return 'лайк';
    if (count >= 2 && count <= 4) return 'лайка';
    return 'лайков';
  }

  String _getCommentsText(int count) {
    if (count == 1) return 'комментарий';
    if (count >= 2 && count <= 4) return 'комментария';
    return 'комментариев';
  }

  void _showImageFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: Hero(
              tag: post.id,
              child: CachedNetworkImage(
                imageUrl: post.mediaUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error, color: Colors.red, size: 50),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Пожаловаться на пост'),
        content: const Text('Выберите причину жалобы'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Жалоба отправлена')),
              );
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  void _hidePost(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Пост скрыт')),
    );
  }
}
