import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_idea.dart';
import '../models/idea_comment.dart';
import '../services/event_ideas_service.dart';
import '../widgets/idea_card.dart';
import '../widgets/idea_filter_chip.dart';
import '../widgets/idea_search_bar.dart';

/// Экран ленты идей мероприятий
class EventIdeasScreen extends ConsumerStatefulWidget {
  const EventIdeasScreen({super.key});

  @override
  ConsumerState<EventIdeasScreen> createState() => _EventIdeasScreenState();
}

class _EventIdeasScreenState extends ConsumerState<EventIdeasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EventIdeasService _ideasService = EventIdeasService();

  List<EventIdea> _ideas = [];
  List<EventIdea> _favoriteIdeas = [];
  List<EventIdea> _recommendedIdeas = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _searchQuery = '';
  EventIdeaCategory? _selectedCategory;

  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreIdeas();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final futures = await Future.wait([
        _ideasService.getPublishedIdeas(),
        _ideasService.getRecommendedIdeas(
          'current_user_id',
        ), // TODO(developer): Получить реальный ID
      ]);

      setState(() {
        _ideas = futures[0];
        _recommendedIdeas = futures[1];
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Ошибка загрузки идей: $e');
    }
  }

  Future<void> _loadMoreIdeas() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newIdeas = await _ideasService.getPublishedIdeas(
        lastDocument: _lastDocument,
        category: _selectedCategory,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _ideas.addAll(newIdeas);
        _isLoadingMore = false;
      });
    } on Exception catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      _showErrorSnackBar('Ошибка загрузки дополнительных идей: $e');
    }
  }

  Future<void> _loadFavoriteIdeas() async {
    try {
      final favorites = await _ideasService.getFavoriteIdeas(
        'current_user_id',
      ); // TODO(developer): Получить реальный ID
      setState(() {
        _favoriteIdeas = favorites;
      });
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка загрузки избранных идей: $e');
    }
  }

  Future<void> _onSearch(String query) async {
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });

    try {
      final ideas = await _ideasService.getPublishedIdeas(
        category: _selectedCategory,
        searchQuery: query.isNotEmpty ? query : null,
      );

      setState(() {
        _ideas = ideas;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Ошибка поиска: $e');
    }
  }

  Future<void> _onCategoryFilter(EventIdeaCategory? category) async {
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });

    try {
      final ideas = await _ideasService.getPublishedIdeas(
        category: category,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _ideas = ideas;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Ошибка фильтрации: $e');
    }
  }

  Future<void> _onRefresh() async {
    await _loadInitialData();
    if (_tabController.index == 1) {
      await _loadFavoriteIdeas();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Идеи для мероприятий'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          bottom: TabBar(
            controller: _tabController,
            onTap: (index) {
              if (index == 1 && _favoriteIdeas.isEmpty) {
                _loadFavoriteIdeas();
              }
            },
            tabs: const [
              Tab(text: 'Все идеи', icon: Icon(Icons.grid_view)),
              Tab(text: 'Избранное', icon: Icon(Icons.favorite)),
              Tab(text: 'Для вас', icon: Icon(Icons.recommend)),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _showAddIdeaDialog,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAllIdeasTab(),
            _buildFavoriteIdeasTab(),
            _buildRecommendedIdeasTab(),
          ],
        ),
      );

  Widget _buildAllIdeasTab() => Column(
        children: [
          // Поиск и фильтры
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                IdeaSearchBar(
                  onSearch: _onSearch,
                  initialValue: _searchQuery,
                ),
                const SizedBox(height: 12),
                IdeaFilterChip(
                  selectedCategory: _selectedCategory,
                  onCategorySelected: _onCategoryFilter,
                ),
              ],
            ),
          ),

          // Список идей
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _ideas.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
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
                            return IdeaCard(
                              idea: idea,
                              onTap: () => _navigateToIdeaDetail(idea),
                              onLike: () => _toggleLike(idea),
                              onFavorite: () => _toggleFavorite(idea),
                            );
                          },
                        ),
                      ),
          ),
        ],
      );

  Widget _buildFavoriteIdeasTab() => _favoriteIdeas.isEmpty
      ? _buildEmptyFavoritesState()
      : RefreshIndicator(
          onRefresh: _onRefresh,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _favoriteIdeas.length,
            itemBuilder: (context, index) {
              final idea = _favoriteIdeas[index];
              return IdeaCard(
                idea: idea,
                onTap: () => _navigateToIdeaDetail(idea),
                onLike: () => _toggleLike(idea),
                onFavorite: () => _toggleFavorite(idea),
              );
            },
          ),
        );

  Widget _buildRecommendedIdeasTab() => _recommendedIdeas.isEmpty
      ? _buildEmptyRecommendedState()
      : RefreshIndicator(
          onRefresh: _onRefresh,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _recommendedIdeas.length,
            itemBuilder: (context, index) {
              final idea = _recommendedIdeas[index];
              return IdeaCard(
                idea: idea,
                onTap: () => _navigateToIdeaDetail(idea),
                onLike: () => _toggleLike(idea),
                onFavorite: () => _toggleFavorite(idea),
              );
            },
          ),
        );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Идеи не найдены',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить фильтры или поисковый запрос',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildEmptyFavoritesState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет избранных идей',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Добавляйте понравившиеся идеи в избранное',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildEmptyRecommendedState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.recommend_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет рекомендаций',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Добавьте идеи в избранное, чтобы получать персональные рекомендации',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  void _navigateToIdeaDetail(EventIdea idea) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => IdeaDetailScreen(idea: idea),
      ),
    );
  }

  Future<void> _toggleLike(EventIdea idea) async {
    try {
      const userId = 'current_user_id'; // TODO(developer): Получить реальный ID
      final isLiked = await _ideasService.isIdeaLiked(idea.id, userId);

      if (isLiked) {
        await _ideasService.unlikeIdea(idea.id, userId);
      } else {
        await _ideasService.likeIdea(idea.id, userId);
      }

      // Обновляем локальное состояние
      _updateIdeaInLists(
        idea.id,
        (idea) => idea.copyWith(
          likes: isLiked ? idea.likes - 1 : idea.likes + 1,
        ),
      );
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка изменения лайка: $e');
    }
  }

  Future<void> _toggleFavorite(EventIdea idea) async {
    try {
      const userId = 'current_user_id'; // TODO(developer): Получить реальный ID
      final isFavorite = await _ideasService.isIdeaInFavorites(idea.id, userId);

      if (isFavorite) {
        await _ideasService.removeFromFavorites(idea.id, userId);
        _favoriteIdeas.removeWhere((fav) => fav.id == idea.id);
      } else {
        await _ideasService.addToFavorites(idea.id, userId);
        _favoriteIdeas.add(idea);
      }

      setState(() {});
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка изменения избранного: $e');
    }
  }

  void _updateIdeaInLists(
    String ideaId,
    EventIdea Function(EventIdea) updater,
  ) {
    setState(() {
      // Обновляем в основном списке
      final index = _ideas.indexWhere((idea) => idea.id == ideaId);
      if (index != -1) {
        _ideas[index] = updater(_ideas[index]);
      }

      // Обновляем в рекомендуемых
      final recommendedIndex = _recommendedIdeas.indexWhere((idea) => idea.id == ideaId);
      if (recommendedIndex != -1) {
        _recommendedIdeas[recommendedIndex] = updater(_recommendedIdeas[recommendedIndex]);
      }

      // Обновляем в избранных
      final favoriteIndex = _favoriteIdeas.indexWhere((idea) => idea.id == ideaId);
      if (favoriteIndex != -1) {
        _favoriteIdeas[favoriteIndex] = updater(_favoriteIdeas[favoriteIndex]);
      }
    });
  }

  void _showAddIdeaDialog() {
    // TODO(developer): Реализовать диалог добавления идеи
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Добавление идеи будет реализовано')),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Экран детального просмотра идеи
class IdeaDetailScreen extends StatefulWidget {
  const IdeaDetailScreen({super.key, required this.idea});

  final EventIdea idea;

  @override
  State<IdeaDetailScreen> createState() => _IdeaDetailScreenState();
}

class _IdeaDetailScreenState extends State<IdeaDetailScreen> {
  final EventIdeasService _ideasService = EventIdeasService();
  List<IdeaComment> _comments = [];
  bool _isLoadingComments = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _ideasService.getIdeaComments(widget.idea.id);
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } on Exception {
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.idea.title),
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Изображение
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  widget.idea.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

              // Контент
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок и категория
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.idea.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        Chip(
                          label: Text(widget.idea.category.displayName),
                          avatar: Text(widget.idea.category.emoji),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Описание
                    Text(
                      widget.idea.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),

                    const SizedBox(height: 16),

                    // Детали
                    _buildIdeaDetails(),

                    const SizedBox(height: 24),

                    // Комментарии
                    Text(
                      'Комментарии (${_comments.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),

                    const SizedBox(height: 12),

                    if (_isLoadingComments)
                      const Center(child: CircularProgressIndicator())
                    else if (_comments.isEmpty)
                      Text(
                        'Пока нет комментариев',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      )
                    else
                      ..._comments.map(_buildComment),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildIdeaDetails() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Детали',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (widget.idea.budget != null)
                _buildDetailRow(
                  'Бюджет',
                  '${widget.idea.budget!.toStringAsFixed(0)} ₽',
                ),
              if (widget.idea.duration != null)
                _buildDetailRow(
                  'Длительность',
                  '${widget.idea.duration} часов',
                ),
              if (widget.idea.guestCount != null)
                _buildDetailRow(
                  'Количество гостей',
                  '${widget.idea.guestCount} человек',
                ),
              if (widget.idea.location != null) _buildDetailRow('Локация', widget.idea.location!),
              if (widget.idea.season != null) _buildDetailRow('Сезон', widget.idea.season!),
              if (widget.idea.style != null) _buildDetailRow('Стиль', widget.idea.style!),
              if (widget.idea.tags.isNotEmpty) _buildDetailRow('Теги', widget.idea.tags.join(', ')),
            ],
          ),
        ),
      );

  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );

  Widget _buildComment(IdeaComment comment) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        comment.userAvatar != null ? NetworkImage(comment.userAvatar!) : null,
                    child:
                        comment.userAvatar == null ? Text(comment.userName[0].toUpperCase()) : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.userName,
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
                ],
              ),
              const SizedBox(height: 8),
              Text(
                comment.content,
                style: Theme.of(context).textTheme.bodyMedium,
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
