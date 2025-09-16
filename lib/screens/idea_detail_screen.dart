import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/idea.dart';
import '../services/idea_service.dart';
import '../widgets/idea_comment_widget.dart';

/// Экран детального просмотра идеи
class IdeaDetailScreen extends ConsumerStatefulWidget {
  final Idea idea;
  final String userId;

  const IdeaDetailScreen({
    super.key,
    required this.idea,
    required this.userId,
  });

  @override
  ConsumerState<IdeaDetailScreen> createState() => _IdeaDetailScreenState();
}

class _IdeaDetailScreenState extends ConsumerState<IdeaDetailScreen> {
  final IdeaService _ideaService = IdeaService();
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  late Idea _idea;
  bool _isLoading = false;
  bool _showComments = false;

  @override
  void initState() {
    super.initState();
    _idea = widget.idea;
    _incrementViewsCount();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _incrementViewsCount() async {
    await _ideaService.incrementViewsCount(_idea.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Идея'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareIdea,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'save',
                child: ListTile(
                  leading: Icon(Icons.bookmark),
                  title: Text('Сохранить'),
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: ListTile(
                  leading: Icon(Icons.report),
                  title: Text('Пожаловаться'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображения
            if (_idea.images.isNotEmpty) _buildImagesSection(),

            // Основная информация
            _buildMainInfoSection(),

            // Действия
            _buildActionsSection(),

            // Комментарии
            _buildCommentsSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildImagesSection() {
    return Container(
      height: 300,
      child: PageView.builder(
        itemCount: _idea.images.length,
        itemBuilder: (context, index) {
          final image = _idea.images[index];
          return CachedNetworkImage(
            imageUrl: image.url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.error),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок и категория
          Row(
            children: [
              Expanded(
                child: Text(
                  _idea.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _idea.categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _idea.categoryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _idea.categoryIcon,
                      size: 16,
                      color: _idea.categoryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _idea.category,
                      style: TextStyle(
                        fontSize: 14,
                        color: _idea.categoryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Автор и дата
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: _idea.authorPhotoUrl != null
                    ? CachedNetworkImageProvider(_idea.authorPhotoUrl!)
                    : null,
                child: _idea.authorPhotoUrl == null
                    ? Text(
                        _idea.authorName.isNotEmpty
                            ? _idea.authorName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 16),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _idea.authorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDate(_idea.createdAt),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Описание
          Text(
            _idea.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          // Теги
          if (_idea.tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _idea.tags.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Лайк
          Expanded(
            child: _buildActionButton(
              icon: Icons.favorite,
              label: 'Лайк',
              count: _idea.likesCount,
              isActive: _idea.isLikedBy(widget.userId),
              onTap: _toggleLike,
            ),
          ),

          // Сохранение
          Expanded(
            child: _buildActionButton(
              icon: Icons.bookmark,
              label: 'Сохранить',
              count: _idea.savesCount,
              isActive: _idea.isSavedBy(widget.userId),
              onTap: _toggleSave,
            ),
          ),

          // Комментарии
          Expanded(
            child: _buildActionButton(
              icon: Icons.comment,
              label: 'Комментарии',
              count: _idea.commentsCount,
              isActive: _showComments,
              onTap: _toggleComments,
            ),
          ),

          // Шаринг
          Expanded(
            child: _buildActionButton(
              icon: Icons.share,
              label: 'Поделиться',
              count: 0,
              isActive: false,
              onTap: _shareIdea,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.blue : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.blue : Colors.grey[600],
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    if (!_showComments) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Комментарии',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Список комментариев
          StreamBuilder<List<IdeaComment>>(
            stream: _ideaService.getIdeaComments(_idea.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child:
                      Text('Ошибка загрузки комментариев: ${snapshot.error}'),
                );
              }

              final comments = snapshot.data ?? [];
              if (comments.isEmpty) {
                return const Center(
                  child: Text('Пока нет комментариев'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return IdeaCommentWidget(
                    comment: comment,
                    userId: widget.userId,
                    onLike: () => _likeComment(comment),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                hintText: 'Добавить комментарий...',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading ? null : _addComment,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _ideaService.likeIdea(_idea.id, widget.userId);
      if (success) {
        // Обновляем локальное состояние
        final updatedIdea = _idea.copyWith(
          likedBy: _idea.isLikedBy(widget.userId)
              ? _idea.likedBy.where((id) => id != widget.userId).toList()
              : [..._idea.likedBy, widget.userId],
          likesCount: _idea.isLikedBy(widget.userId)
              ? _idea.likesCount - 1
              : _idea.likesCount + 1,
        );
        setState(() {
          _idea = updatedIdea;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSave() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _ideaService.saveIdea(_idea.id, widget.userId);
      if (success) {
        // Обновляем локальное состояние
        final updatedIdea = _idea.copyWith(
          savedBy: _idea.isSavedBy(widget.userId)
              ? _idea.savedBy.where((id) => id != widget.userId).toList()
              : [..._idea.savedBy, widget.userId],
          savesCount: _idea.isSavedBy(widget.userId)
              ? _idea.savesCount - 1
              : _idea.savesCount + 1,
        );
        setState(() {
          _idea = updatedIdea;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleComments() {
    setState(() {
      _showComments = !_showComments;
    });

    if (_showComments) {
      // Прокручиваем к комментариям
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final commentId = await _ideaService.addComment(
        ideaId: _idea.id,
        authorId: widget.userId,
        authorName: 'Демо Пользователь', // TODO: Получить из контекста
        content: content,
      );

      if (commentId != null) {
        _commentController.clear();
        _showComments = true;
        setState(() {});
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка добавления комментария: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _likeComment(IdeaComment comment) async {
    // TODO: Реализовать лайк комментария
    _showInfoSnackBar('Лайк комментария пока не реализован');
  }

  void _shareIdea() {
    // TODO: Реализовать шаринг идеи
    _showInfoSnackBar('Идея скопирована в буфер обмена');
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'save':
        _toggleSave();
        break;
      case 'report':
        _showInfoSnackBar('Жалоба отправлена');
        break;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
