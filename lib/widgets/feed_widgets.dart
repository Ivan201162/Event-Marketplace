import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feed_post.dart';
import '../providers/feed_providers.dart';

/// Виджет поста в ленте
class FeedPostWidget extends ConsumerWidget {
  const FeedPostWidget({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
  });
  final FeedPost post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок поста
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: post.specialistPhotoUrl != null
                        ? CachedNetworkImageProvider(post.specialistPhotoUrl!)
                        : null,
                    child: post.specialistPhotoUrl == null ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.specialistName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatTimeAgo(post.createdAt),
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
              const SizedBox(height: 12),

              // Содержимое поста
              if (post.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    post.content,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

              // Медиа контент
              if (post.mediaUrls.isNotEmpty) _buildMediaContent(),

              // Теги
              if (post.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    children: post.tags
                        .map(
                          (tag) => Chip(
                            label: Text('#$tag'),
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                            labelStyle: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),

              const SizedBox(height: 12),

              // Действия
              Row(
                children: [
                  _buildActionButton(
                    icon: post.isLikedBy('current_user') ? Icons.favorite : Icons.favorite_border,
                    label: post.likes.toString(),
                    color: post.isLikedBy('current_user') ? Colors.red : Colors.grey,
                    onTap: onLike,
                  ),
                  const SizedBox(width: 24),
                  _buildActionButton(
                    icon: Icons.comment_outlined,
                    label: post.comments.toString(),
                    onTap: onComment,
                  ),
                  const SizedBox(width: 24),
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    label: post.shares.toString(),
                    onTap: onShare,
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildMediaContent() {
    if (post.mediaUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: post.mediaUrls.first,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
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
              child: Icon(Icons.error, color: Colors.grey),
            ),
          ),
        ),
      );
    } else if (post.mediaUrls.length > 1) {
      return SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: post.mediaUrls.length,
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(
              right: index < post.mediaUrls.length - 1 ? 8 : 0,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: post.mediaUrls[index],
                fit: BoxFit.cover,
                width: 200,
                height: 200,
                placeholder: (context, url) => Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color ?? Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color ?? Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );

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

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн назад';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }
}

/// Виджет комментариев к посту
class PostCommentsWidget extends ConsumerStatefulWidget {
  const PostCommentsWidget({
    super.key,
    required this.postId,
  });
  final String postId;

  @override
  ConsumerState<PostCommentsWidget> createState() => _PostCommentsWidgetState();
}

class _PostCommentsWidgetState extends ConsumerState<PostCommentsWidget> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Комментарии',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Список комментариев
            Expanded(
              child: commentsAsync.when(
                data: (comments) {
                  if (comments.isEmpty) {
                    return const Center(
                      child: Text('Пока нет комментариев'),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CommentWidget(comment: comment),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text('Ошибка: $error'),
                ),
              ),
            ),

            // Поле ввода комментария
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Написать комментарий...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addComment,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      final service = ref.read(feedServiceProvider);
      final comment = FeedComment(
        id: '', // Будет сгенерирован Firestore
        postId: widget.postId,
        userId: 'current_user', // TODO(developer): Получить реальный ID пользователя
        userName: 'Пользователь', // TODO(developer): Получить реальное имя пользователя
        content: _commentController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await service.addComment(comment);

      _commentController.clear();
      ref.invalidate(postCommentsProvider(widget.postId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка добавления комментария: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Виджет комментария
class CommentWidget extends ConsumerWidget {
  const CommentWidget({
    super.key,
    required this.comment,
  });
  final FeedComment comment;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: comment.userPhotoUrl != null
                ? CachedNetworkImageProvider(comment.userPhotoUrl!)
                : null,
            radius: 16,
            child: comment.userPhotoUrl == null ? const Icon(Icons.person, size: 16) : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.content,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatTimeAgo(comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => _likeComment(ref),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            comment.isLikedBy('current_user')
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 14,
                            color:
                                comment.isLikedBy('current_user') ? Colors.red : Colors.grey[600],
                          ),
                          if (comment.likesCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              comment.likesCount.toString(),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  Future<void> _likeComment(WidgetRef ref) async {
    try {
      final service = ref.read(feedServiceProvider);
      await service.likeComment(
        comment.id,
        'current_user', // TODO(developer): Получить реальный ID пользователя
      );
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else {
      return '${difference.inDays} дн назад';
    }
  }
}
