import 'package:flutter/material.dart';

import '../models/idea_comment.dart';

/// Виджет комментария к идее
class IdeaCommentWidget extends StatelessWidget {
  const IdeaCommentWidget({
    super.key,
    required this.comment,
    this.onLike,
    this.onReply,
    this.onDelete,
    this.showReplies = true,
  });

  final IdeaComment comment;
  final VoidCallback? onLike;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final bool showReplies;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок комментария
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        comment.authorAvatar != null ? NetworkImage(comment.authorAvatar!) : null,
                    child: comment.authorAvatar == null
                        ? Text(
                            comment.authorName?.isNotEmpty == true
                                ? comment.authorName![0].toUpperCase()
                                : '?',
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.authorName ?? 'Unknown',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        Text(
                          _formatDate(comment.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      iconSize: 18,
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Содержимое комментария
              Text(
                comment.content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 8),

              // Действия
              Row(
                children: [
                  GestureDetector(
                    onTap: onLike,
                    child: Row(
                      children: [
                        Icon(
                          Icons.thumb_up_outlined,
                          size: 16,
                          color: (comment.likesCount ?? 0) > 0
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          comment.likesCount.toString(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: (comment.likesCount ?? 0) > 0
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (onReply != null && showReplies)
                    GestureDetector(
                      onTap: onReply,
                      child: Row(
                        children: [
                          Icon(
                            Icons.reply,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ответить',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  if (comment.updatedAt != comment.createdAt)
                    Text(
                      'изменено',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }
}

/// Виджет для добавления комментария
class AddCommentWidget extends StatefulWidget {
  const AddCommentWidget({
    super.key,
    required this.onCommentAdded,
    this.replyTo,
    this.hintText = 'Добавить комментарий...',
  });

  final Function(String) onCommentAdded;
  final IdeaComment? replyTo;
  final String hintText;

  @override
  State<AddCommentWidget> createState() => _AddCommentWidgetState();
}

class _AddCommentWidgetState extends State<AddCommentWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.replyTo != null) ...[
                Text(
                  'Ответ на комментарий ${widget.replyTo!.authorName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSubmitting ? null : _submitComment,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Future<void> _submitComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onCommentAdded(content);
      _controller.clear();
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

/// Виджет для отображения списка комментариев
class CommentsListWidget extends StatelessWidget {
  const CommentsListWidget({
    super.key,
    required this.comments,
    this.onCommentLike,
    this.onCommentReply,
    this.onCommentDelete,
    this.onAddComment,
    this.isLoading = false,
  });

  final List<IdeaComment> comments;
  final Function(IdeaComment)? onCommentLike;
  final Function(IdeaComment)? onCommentReply;
  final Function(IdeaComment)? onCommentDelete;
  final Function(String)? onAddComment;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Пока нет комментариев',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Будьте первым, кто оставит комментарий',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Поле для добавления комментария
        if (onAddComment != null)
          AddCommentWidget(
            onCommentAdded: onAddComment!,
          ),

        const SizedBox(height: 16),

        // Список комментариев
        Expanded(
          child: ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return IdeaCommentWidget(
                comment: comment,
                onLike: onCommentLike != null ? () => onCommentLike!(comment) : null,
                onReply: onCommentReply != null ? () => onCommentReply!(comment) : null,
                onDelete: onCommentDelete != null ? () => onCommentDelete!(comment) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
