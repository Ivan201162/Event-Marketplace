import 'package:flutter/material.dart';

import '../models/idea.dart';

/// Карточка идеи в ленте
class IdeaCard extends StatelessWidget {
  final Idea idea;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  const IdeaCard({
    super.key,
    required this.idea,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onSave,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с аватаром автора
              _IdeaHeader(idea: idea),

              const SizedBox(height: 12),

              // Текст идеи
              Text(
                idea.text,
                style: const TextStyle(fontSize: 16),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Медиа контент
              if (idea.media.isNotEmpty) ...[
                const SizedBox(height: 12),
                _IdeaMedia(media: idea.media),
              ],

              // Теги
              if (idea.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                _IdeaTags(tags: idea.tags),
              ],

              const SizedBox(height: 16),

              // Действия
              _IdeaActions(
                idea: idea,
                onLike: onLike,
                onComment: onComment,
                onSave: onSave,
                onShare: onShare,
              ),

              const SizedBox(height: 8),

              // Статистика
              _IdeaStats(idea: idea),
            ],
          ),
        ),
      ),
    );
  }
}

/// Заголовок идеи с аватаром автора
class _IdeaHeader extends StatelessWidget {
  final Idea idea;

  const _IdeaHeader({required this.idea});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: idea.authorAvatar != null
              ? NetworkImage(idea.authorAvatar!)
              : null,
          child: idea.authorAvatar == null ? const Icon(Icons.person) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                idea.authorName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                _formatDate(idea.createdAt),
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
          onPressed: () => _showIdeaMenu(context),
        ),
      ],
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

  void _showIdeaMenu(BuildContext context) {
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

/// Медиа контент идеи
class _IdeaMedia extends StatelessWidget {
  final List<String> media;

  const _IdeaMedia({required this.media});

  @override
  Widget build(BuildContext context) {
    if (media.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
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
        ),
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
              margin: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
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
              ),
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Теги идеи
class _IdeaTags extends StatelessWidget {
  final List<String> tags;

  const _IdeaTags({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Действия с идеей
class _IdeaActions extends StatelessWidget {
  final Idea idea;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  const _IdeaActions({
    required this.idea,
    this.onLike,
    this.onComment,
    this.onSave,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            idea.isLiked ? Icons.favorite : Icons.favorite_border,
            color: idea.isLiked ? Colors.red : null,
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
            idea.isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: idea.isSaved ? Colors.blue : null,
          ),
          onPressed: onSave,
        ),
      ],
    );
  }
}

/// Статистика идеи
class _IdeaStats extends StatelessWidget {
  final Idea idea;

  const _IdeaStats({required this.idea});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (idea.likesCount > 0) ...[
          Text(
            '${idea.likesCount} ${_getLikesText(idea.likesCount)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
        ],
        if (idea.commentsCount > 0) ...[
          Text(
            '${idea.commentsCount} ${_getCommentsText(idea.commentsCount)}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(width: 16),
        ],
        if (idea.sharesCount > 0) ...[
          Text(
            '${idea.sharesCount} ${_getSharesText(idea.sharesCount)}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ],
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

  String _getSharesText(int count) {
    if (count == 1) return 'репост';
    if (count >= 2 && count <= 4) return 'репоста';
    return 'репостов';
  }
}
