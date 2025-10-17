import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/social_models.dart';
import '../services/supabase_service.dart';

/// Экран ленты идей/постов
class IdeasFeedScreen extends ConsumerStatefulWidget {
  const IdeasFeedScreen({super.key});

  @override
  ConsumerState<IdeasFeedScreen> createState() => _IdeasFeedScreenState();
}

class _IdeasFeedScreenState extends ConsumerState<IdeasFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Idea> _ideas = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _offset = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadIdeas();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreIdeas();
    }
  }

  Future<void> _loadIdeas() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _offset = 0;
      });

      final ideas = await SupabaseService.getIdeas(
        limit: _limit,
        offset: _offset,
      );

      setState(() {
        _ideas = ideas;
        _isLoading = false;
        _offset = ideas.length;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreIdeas() async {
    if (_isLoadingMore) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final ideas = await SupabaseService.getIdeas(
        limit: _limit,
        offset: _offset,
      );

      setState(() {
        _ideas.addAll(ideas);
        _isLoadingMore = false;
        _offset += ideas.length;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshIdeas() async {
    await _loadIdeas();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Идеи'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/ideas/create'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshIdeas,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки идей',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadIdeas,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_ideas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Нет идей',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Будьте первым, кто поделится идеей!',
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/ideas/create'),
              child: const Text('Создать идею'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _ideas.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _ideas.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final idea = _ideas[index];
        return _buildIdeaCard(idea);
      },
    );
  }

  Widget _buildIdeaCard(Idea idea) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с автором
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              backgroundImage:
                  idea.author?.avatarUrl != null ? NetworkImage(idea.author!.avatarUrl!) : null,
              child: idea.author?.avatarUrl == null
                  ? Icon(
                      Icons.person,
                      color: theme.primaryColor,
                    )
                  : null,
            ),
            title: Text(
              idea.author?.name ?? 'Неизвестный',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              _formatTime(idea.createdAt),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Text('Пожаловаться'),
                ),
              ],
            ),
          ),

          // Контент
          if (idea.content != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                idea.content!,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Медиа
          if (idea.mediaUrls.isNotEmpty) ...[
            _buildMediaContent(idea.mediaUrls),
            const SizedBox(height: 12),
          ],

          // Категория
          if (idea.category != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  idea.category!,
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Действия
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.favorite_border,
                  label: idea.likesCount.toString(),
                  onTap: () => _toggleLike(idea),
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: idea.commentsCount.toString(),
                  onTap: () => _showComments(idea),
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Поделиться',
                  onTap: () => _shareIdea(idea),
                ),
                const Spacer(),
                _buildActionButton(
                  icon: Icons.bookmark_border,
                  label: 'Сохранить',
                  onTap: () => _saveIdea(idea),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMediaContent(List<String> mediaUrls) {
    if (mediaUrls.length == 1) {
      return Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            mediaUrls.first,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, size: 48),
                ),
              );
            },
          ),
        ),
      );
    } else {
      return Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: mediaUrls.length,
          itemBuilder: (context, index) {
            return Container(
              width: 200,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  mediaUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 48),
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
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike(Idea idea) async {
    try {
      final isLiked = await SupabaseService.isIdeaLiked(idea.id);
      if (isLiked) {
        await SupabaseService.unlikeIdea(idea.id);
      } else {
        await SupabaseService.likeIdea(idea.id);
      }

      // Обновляем локальное состояние
      setState(() {
        final index = _ideas.indexWhere((i) => i.id == idea.id);
        if (index != -1) {
          _ideas[index] = idea.copyWith(
            likesCount: isLiked ? idea.likesCount - 1 : idea.likesCount + 1,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showComments(Idea idea) {
    // TODO: Показать экран комментариев
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Комментарии в разработке')),
    );
  }

  void _shareIdea(Idea idea) {
    // TODO: Реализовать шаринг
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Шаринг в разработке')),
    );
  }

  void _saveIdea(Idea idea) {
    // TODO: Реализовать сохранение
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сохранение в разработке')),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'сейчас';
    }
  }
}
