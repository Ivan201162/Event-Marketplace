import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/idea.dart';
import '../providers/optimized_data_providers.dart';
import '../services/optimized_ideas_service.dart';

/// Оптимизированная лента идей с реальными данными и обработкой состояний
class OptimizedIdeasScreen extends ConsumerStatefulWidget {
  const OptimizedIdeasScreen({super.key});

  @override
  ConsumerState<OptimizedIdeasScreen> createState() =>
      _OptimizedIdeasScreenState();
}

class _OptimizedIdeasScreenState extends ConsumerState<OptimizedIdeasScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'all';
  String _sortBy = 'newest';
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreIdeas();
    }
  }

  Future<void> _loadMoreIdeas() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final ideasService = ref.read(optimizedIdeasServiceProvider);
      await ideasService.loadMoreIdeas();
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ideasAsync = ref.watch(ideasProvider({
      'category': _selectedCategory,
      'sortBy': _sortBy,
    }));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Идеи'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshIdeas,
          ),
        ],
      ),
      body: Column(
        children: [
          // Категории
          _buildCategoriesFilter(),

          // Сортировка
          _buildSortOptions(),

          // Список идей
          Expanded(
            child: ideasAsync.when(
              data: (ideasState) => _buildIdeasContent(ideasState),
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewIdea,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoriesFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip('all', 'Все'),
          _buildCategoryChip('design', 'Дизайн'),
          _buildCategoryChip('marketing', 'Маркетинг'),
          _buildCategoryChip('events', 'События'),
          _buildCategoryChip('business', 'Бизнес'),
          _buildCategoryChip('technology', 'Технологии'),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildSortOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Сортировка: '),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _sortBy,
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
              });
            },
            items: const [
              DropdownMenuItem(value: 'newest', child: Text('Новые')),
              DropdownMenuItem(value: 'popular', child: Text('Популярные')),
              DropdownMenuItem(value: 'trending', child: Text('В тренде')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdeasContent(IdeasState ideasState) {
    if (ideasState.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshIdeas,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: ideasState.ideas.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < ideasState.ideas.length) {
            final idea = ideasState.ideas[index];
            return _IdeaCard(idea: idea);
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Загрузка идей...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Создайте первую идею',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewIdea,
            icon: const Icon(Icons.add),
            label: const Text('Создать идею'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки идей',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshIdeas,
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры идей'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Категория'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Все')),
                DropdownMenuItem(value: 'design', child: Text('Дизайн')),
                DropdownMenuItem(value: 'marketing', child: Text('Маркетинг')),
                DropdownMenuItem(value: 'events', child: Text('События')),
                DropdownMenuItem(value: 'business', child: Text('Бизнес')),
                DropdownMenuItem(
                    value: 'technology', child: Text('Технологии')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: const InputDecoration(labelText: 'Сортировка'),
              items: const [
                DropdownMenuItem(value: 'newest', child: Text('Новые')),
                DropdownMenuItem(value: 'popular', child: Text('Популярные')),
                DropdownMenuItem(value: 'trending', child: Text('В тренде')),
              ],
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }

  void _createNewIdea() {
    // TODO: Открыть экран создания идеи
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция создания идеи в разработке')),
    );
  }

  Future<void> _refreshIdeas() async {
    ref.invalidate(ideasProvider);
  }
}

class _IdeaCard extends ConsumerWidget {
  const _IdeaCard({required this.idea});
  final Idea idea;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideasService = ref.read(optimizedIdeasServiceProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Изображение идеи
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: idea.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: idea.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.error)),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.lightbulb_outline)),
                    ),
            ),
          ),

          // Контент идеи
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок
                  Text(
                    idea.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Описание
                  Expanded(
                    child: Text(
                      idea.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Действия
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _toggleLike(ideasService),
                        icon: Icon(
                          idea.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: idea.isLiked ? Colors.red : null,
                          size: 20,
                        ),
                      ),
                      Text('${idea.likes}',
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _toggleSave(ideasService),
                        icon: Icon(
                          idea.isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: idea.isSaved ? Colors.amber : null,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(idea.createdAt),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
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
    );
  }

  void _toggleLike(OptimizedIdeasService ideasService) {
    // TODO: Получить userId из контекста
    ideasService.toggleLike(idea.id, 'current_user_id');
  }

  void _toggleSave(OptimizedIdeasService ideasService) {
    // TODO: Получить userId из контекста
    ideasService.toggleSave(idea.id, 'current_user_id');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}д';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м';
    } else {
      return 'сейчас';
    }
  }
}
