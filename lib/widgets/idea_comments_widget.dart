import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_idea.dart';
import '../providers/auth_providers.dart';
import '../services/event_idea_service.dart';

/// Виджет комментариев к идее
class IdeaCommentsWidget extends ConsumerStatefulWidget {
  const IdeaCommentsWidget({
    super.key,
    required this.ideaId,
  });

  final String ideaId;

  @override
  ConsumerState<IdeaCommentsWidget> createState() => _IdeaCommentsWidgetState();
}

class _IdeaCommentsWidgetState extends ConsumerState<IdeaCommentsWidget> {
  final EventIdeaService _ideaService = EventIdeaService();
  final TextEditingController _commentController = TextEditingController();

  List<IdeaComment> _comments = [];
  bool _isLoading = true;
  String? _error;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final comments = await _ideaService.getIdeaComments(widget.ideaId);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      await _ideaService.addComment(
        ideaId: widget.ideaId,
        authorId: currentUser.uid,
        text: _commentController.text.trim(),
        authorName: currentUser.displayName,
        authorAvatar: currentUser.photoURL,
      );

      _commentController.clear();
      await _loadComments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Комментарий добавлен'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Комментарии (${_comments.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // Поле ввода комментария
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Добавить комментарий...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
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
                  tooltip: 'Отправить',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Список комментариев
          Expanded(
            child: _buildCommentsList(),
          ),
        ],
      );

  Widget _buildCommentsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_comments.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadComments,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _comments.length,
        itemBuilder: (context, index) {
          final comment = _comments[index];
          return CommentCard(
            comment: comment,
            onLike: () => _likeComment(comment),
            onReply: () => _replyToComment(comment),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки комментариев',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadComments,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Пока нет комментариев',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Будьте первым, кто оставит комментарий!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Future<void> _likeComment(IdeaComment comment) async {
    try {
      await _ideaService.likeComment(comment.id);
      await _loadComments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _replyToComment(IdeaComment comment) {
    // Здесь можно добавить логику ответа на комментарий
    _commentController.text = '@${comment.authorName ?? 'Пользователь'} ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
  }
}

/// Карточка комментария
class CommentCard extends StatelessWidget {
  const CommentCard({
    super.key,
    required this.comment,
    this.onLike,
    this.onReply,
  });

  final IdeaComment comment;
  final VoidCallback? onLike;
  final VoidCallback? onReply;

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
                  // Аватар
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage:
                        comment.authorAvatar != null ? NetworkImage(comment.authorAvatar!) : null,
                    child: comment.authorAvatar == null
                        ? Text(
                            (comment.authorName ?? 'П').isNotEmpty
                                ? (comment.authorName ?? 'П')[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),

                  // Имя и время
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.authorName ?? 'Пользователь',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          comment.timeAgo,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Текст комментария
              Text(
                comment.text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 8),

              // Действия
              Row(
                children: [
                  // Лайк
                  GestureDetector(
                    onTap: onLike,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        if (comment.likes > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            comment.likes.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Ответ
                  if (onReply != null)
                    GestureDetector(
                      onTap: onReply,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.reply,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ответить',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // Количество ответов
                  if (comment.replies > 0)
                    Text(
                      '${comment.replies} ответов',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
}
