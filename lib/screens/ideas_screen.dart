import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/feature_flags.dart';
import '../core/constants/app_routes.dart';
import '../models/idea.dart';
import '../models/event_idea.dart';
import '../models/user.dart';
import '../services/idea_service.dart';
import '../services/recommendation_service.dart';

/// Экран идей в стиле Pinterest с бесконечной прокруткой
class IdeasScreen extends ConsumerStatefulWidget {
  const IdeasScreen({super.key});

  @override
  ConsumerState<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends ConsumerState<IdeasScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final IdeaService _ideaService = IdeaService();
  final RecommendationService _recommendationService = RecommendationService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  String? _selectedCategory;
  List<Idea> _ideas = [];
  List<Idea> _recommendedIdeas = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  DocumentSnapshot? _lastDocument;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.ideasEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Идеи'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Раздел идей временно недоступен',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Идеи'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Все'),
            Tab(text: 'Рекомендации'),
            Tab(text: 'Популярные'),
            Tab(text: 'Свадьба'),
            Tab(text: 'День рождения'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateIdeaDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllIdeasTab(),
          _buildRecommendedIdeasTab(),
          _buildPopularIdeasTab(),
          _buildCategoryIdeasTab('Свадьба'),
          _buildCategoryIdeasTab('День рождения'),
        ],
      ),
    );
  }

  // Методы для загрузки данных
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final ideas = await _ideaService.getPublicIdeas(limit: 20).first;
      setState(() {
        _ideas = ideas;
        _isLoading = false;
        _hasMoreData = ideas.length >= 20;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка загрузки идей: $e');
    }
  }

  Future<void> _loadMoreIdeas() async {
    if (_isLoading || !_hasMoreData) return;
    
    setState(() => _isLoading = true);
    try {
      final newIdeas = await _ideaService.getPublicIdeas(
        limit: 20,
        lastDocument: _lastDocument,
      ).first;
      
      setState(() {
        _ideas.addAll(newIdeas);
        _isLoading = false;
        _hasMoreData = newIdeas.length >= 20;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка загрузки дополнительных идей: $e');
    }
  }

  Future<void> _loadRecommendedIdeas() async {
    if (_currentUserId == null) return;
    
    try {
      final recommendations = await _recommendationService.getRecommendedIdeas(
        _currentUserId!,
        limit: 20,
      );
      setState(() {
        _recommendedIdeas = recommendations;
      });
    } catch (e) {
      _showErrorSnackBar('Ошибка загрузки рекомендаций: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreIdeas();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Повторить',
          textColor: Colors.white,
          onPressed: _loadInitialData,
        ),
      ),
    );
  }

  // Новые методы для построения табов
  Widget _buildAllIdeasTab() {
    if (_isLoading && _ideas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ideas.isEmpty) {
      return _buildEmptyState('Нет идей', 'Пока что никто не поделился идеями');
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: _buildPinterestGrid(_ideas),
    );
  }

  Widget _buildRecommendedIdeasTab() {
    if (_currentUserId == null) {
      return _buildEmptyState(
        'Войдите в аккаунт',
        'Для получения персональных рекомендаций необходимо войти в аккаунт',
      );
    }

    if (_recommendedIdeas.isEmpty) {
      return _buildEmptyState(
        'Нет рекомендаций',
        'Мы подберем идеи специально для вас на основе ваших предпочтений',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendedIdeas,
      child: _buildPinterestGrid(_recommendedIdeas),
    );
  }

  Widget _buildPopularIdeasTab() {
    return StreamBuilder<List<Idea>>(
      stream: _ideaService.getPopularIdeas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState('Ошибка загрузки популярных идей: ${snapshot.error}');
        }

        final ideas = snapshot.data ?? [];
        if (ideas.isEmpty) {
          return _buildEmptyState('Нет популярных идей', 'Пока что нет идей с большим количеством лайков');
        }

        return _buildPinterestGrid(ideas);
      },
    );
  }

  Widget _buildCategoryIdeasTab(String category) {
    return StreamBuilder<List<Idea>>(
      stream: _ideaService.getIdeasByCategory(category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState('Ошибка загрузки идей категории: ${snapshot.error}');
        }

        final ideas = snapshot.data ?? [];
        if (ideas.isEmpty) {
          return _buildEmptyState('Нет идей в категории', 'В категории "$category" пока нет идей');
        }

        return _buildPinterestGrid(ideas);
      },
    );
  }

  Widget _buildPinterestGrid(List<Idea> ideas) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childCount: ideas.length,
            itemBuilder: (context, index) {
              final idea = ideas[index];
              return _buildIdeaCard(idea);
            },
          ),
        ),
        if (_isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Ошибка',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdeaCard(Idea idea) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showIdeaDetails(idea),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (idea.images.isNotEmpty)
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    Image.network(
                      idea.images.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 48, color: Colors.grey),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          idea.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    idea.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    idea.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: idea.authorAvatar != null
                            ? NetworkImage(idea.authorAvatar!)
                            : null,
                        child: idea.authorAvatar == null
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          idea.authorName,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildActionButton(
                        icon: idea.likedBy.contains(_currentUserId ?? '')
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: idea.likedBy.contains(_currentUserId ?? '')
                            ? Colors.red
                            : Colors.grey,
                        count: idea.likesCount,
                        onPressed: () => _toggleLike(idea),
                      ),
                      const SizedBox(width: 16),
                      _buildActionButton(
                        icon: idea.savedBy.contains(_currentUserId ?? '')
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: idea.savedBy.contains(_currentUserId ?? '')
                            ? Colors.blue
                            : Colors.grey,
                        count: idea.savesCount,
                        onPressed: () => _toggleSave(idea),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.share, size: 20),
                        onPressed: () => _shareIdea(idea),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск идей'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Введите ключевые слова...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performSearch();
            },
            child: const Text('Поиск'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Категория',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Все категории')),
                DropdownMenuItem(value: 'Свадьба', child: Text('Свадьба')),
                DropdownMenuItem(value: 'День рождения', child: Text('День рождения')),
                DropdownMenuItem(value: 'Корпоратив', child: Text('Корпоратив')),
                DropdownMenuItem(value: 'Праздник', child: Text('Праздник')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedCategory = null;
              });
            },
            child: const Text('Сбросить'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyFilters();
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }

  void _performSearch() {
    if (_searchQuery.isEmpty) return;
    
    // TODO: Реализовать поиск с навигацией к результатам
    context.push('${AppRoutes.ideas}/search?q=${Uri.encodeComponent(_searchQuery)}');
  }

  void _applyFilters() {
    // TODO: Применить фильтры и обновить список
    _loadInitialData();
  }

  void _showCreateIdeaDialog() {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Для создания идеи необходимо войти в аккаунт'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Перейти к экрану создания идеи
    context.push(AppRoutes.createIdea);
  }

  void _showIdeaDetails(Idea idea) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (idea.images.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(idea.images.first),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                idea.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                idea.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: idea.authorAvatar != null
                        ? NetworkImage(idea.authorAvatar!)
                        : null,
                    child: idea.authorAvatar == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        idea.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${idea.createdAt.day}.${idea.createdAt.month}.${idea.createdAt.year}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      idea.likedBy.contains('current_user_id')
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: idea.likedBy.contains('current_user_id')
                          ? Colors.red
                          : Colors.grey,
                    ),
                    onPressed: () => _toggleLike(idea),
                  ),
                  Text('${idea.likesCount}'),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      idea.savedBy.contains('current_user_id')
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: idea.savedBy.contains('current_user_id')
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    onPressed: () => _toggleSave(idea),
                  ),
                  Text('${idea.savesCount}'),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.comment),
                    onPressed: () => _showComments(idea),
                  ),
                  Text('${idea.commentsCount}'),
                ],
              ),
              const SizedBox(height: 16),
              if (idea.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: idea.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          backgroundColor: Colors.blue.withOpacity(0.1),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLike(Idea idea) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Для лайка необходимо войти в аккаунт'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _ideaService.toggleLike(idea.id, _currentUserId!);
      
      // Обновляем локальное состояние
      setState(() {
        final index = _ideas.indexWhere((i) => i.id == idea.id);
        if (index != -1) {
          final updatedIdea = idea.copyWith(
            likedBy: idea.likedBy.contains(_currentUserId!)
                ? idea.likedBy.where((id) => id != _currentUserId).toList()
                : [...idea.likedBy, _currentUserId!],
            likesCount: idea.likedBy.contains(_currentUserId!)
                ? idea.likesCount - 1
                : idea.likesCount + 1,
          );
          _ideas[index] = updatedIdea;
        }
      });
    } catch (e) {
      _showErrorSnackBar('Ошибка при лайке: $e');
    }
  }

  Future<void> _toggleSave(Idea idea) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Для сохранения необходимо войти в аккаунт'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _ideaService.toggleSave(idea.id, _currentUserId!);
      
      // Обновляем локальное состояние
      setState(() {
        final index = _ideas.indexWhere((i) => i.id == idea.id);
        if (index != -1) {
          final updatedIdea = idea.copyWith(
            savedBy: idea.savedBy.contains(_currentUserId!)
                ? idea.savedBy.where((id) => id != _currentUserId).toList()
                : [...idea.savedBy, _currentUserId!],
            savesCount: idea.savedBy.contains(_currentUserId!)
                ? idea.savesCount - 1
                : idea.savesCount + 1,
          );
          _ideas[index] = updatedIdea;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            idea.savedBy.contains(_currentUserId!)
                ? 'Идея удалена из сохраненных'
                : 'Идея сохранена',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Ошибка при сохранении: $e');
    }
  }

  void _shareIdea(Idea idea) {
    // TODO: Реализовать шаринг
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ссылка на идею скопирована в буфер обмена'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

/// Виджет для создания сетки в стиле Pinterest
class MasonryGridView extends StatelessWidget {
  const MasonryGridView.count({
    super.key,
    required this.crossAxisCount,
    required this.itemCount,
    required this.itemBuilder,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
  });
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) => CustomScrollView(
        slivers: [
          SliverMasonryGrid.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childCount: itemCount,
            itemBuilder: itemBuilder,
          ),
        ],
      );
}

/// Простая реализация SliverMasonryGrid
class SliverMasonryGrid extends StatelessWidget {
  const SliverMasonryGrid.count({
    super.key,
    required this.crossAxisCount,
    required this.childCount,
    required this.itemBuilder,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
  });
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final int childCount;
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) => SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: EdgeInsets.only(
              bottom: mainAxisSpacing,
              right: (index + 1) % crossAxisCount == 0 ? 0 : crossAxisSpacing,
            ),
            child: itemBuilder(context, index),
          ),
          childCount: childCount,
        ),
      );
}
