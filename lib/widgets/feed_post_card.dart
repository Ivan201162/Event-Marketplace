import 'package:flutter/material.dart';

import '../models/post.dart';

/// Карточка поста в ленте
class FeedPostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;

  const FeedPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок поста с аватаром автора
          _PostHeader(post: post),

          // Текст поста
          if (post.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                post.text,
                style: const TextStyle(fontSize: 16),
              ),
            ),

          // Медиа контент
          if (post.media.isNotEmpty) _PostMedia(media: post.media),

          // Действия
          _PostActions(
            post: post,
            onLike: onLike,
            onComment: onComment,
            onShare: onShare,
            onSave: onSave,
          ),

          // Статистика
          _PostStats(post: post),
        ],
      ),
    );
  }
}

/// Заголовок поста с аватаром и именем автора
class _PostHeader extends StatelessWidget {
  final Post post;

  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: post.authorAvatar != null
                ? NetworkImage(post.authorAvatar!)
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
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showPostMenu(context),
          ),
        ],
      ),
    );
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

  void _showPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Пожаловаться'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Заблокировать'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

/// Медиа контент поста
class _PostMedia extends StatelessWidget {
  final List<String> media;

  const _PostMedia({required this.media});

  @override
  Widget build(BuildContext context) {
    if (media.length == 1) {
      return Image.network(
        media.first,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.broken_image, size: 64),
            ),
          );
        },
      );
    } else if (media.length > 1) {
      return SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: media.length,
          itemBuilder: (context, index) {
            return Container(
              width: 200,
              margin: const EdgeInsets.only(right: 4),
              child: Image.network(
                media[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Действия с постом
class _PostActions extends StatelessWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;

  const _PostActions({
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              post.isLiked ? Icons.favorite : Icons.favorite_border,
              color: post.isLiked ? Colors.red : null,
            ),
            onPressed: onLike,
          ),
          IconButton(
            icon: const Icon(Icons.comment_outlined),
            onPressed: onComment,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: onShare,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              post.isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: post.isSaved ? Colors.blue : null,
            ),
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}

/// Статистика поста
class _PostStats extends StatelessWidget {
  final Post post;

  const _PostStats({required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.likesCount > 0)
            Text(
              '${post.likesCount} ${_getLikesText(post.likesCount)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          if (post.commentsCount > 0)
            Text(
              '${post.commentsCount} ${_getCommentsText(post.commentsCount)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
        ],
      ),
    );
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
}
