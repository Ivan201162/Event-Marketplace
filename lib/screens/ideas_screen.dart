import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/feature_flags.dart';
import '../models/idea.dart';
import '../services/idea_service.dart';

/// Экран идей в стиле Pinterest
class IdeasScreen extends ConsumerStatefulWidget {
  const IdeasScreen({super.key});

  @override
  ConsumerState<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends ConsumerState<IdeasScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final IdeaService _ideaService = IdeaService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Все'),
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
            icon: const Icon(Icons.add),
            onPressed: _showCreateIdeaDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIdeasList(),
          _buildPopularIdeasList(),
          _buildCategoryIdeasList(IdeaCategory.wedding.name),
          _buildCategoryIdeasList(IdeaCategory.birthday.name),
        ],
      ),
    );
  }

  Widget _buildIdeasList() => StreamBuilder<List<Idea>>(
        stream: _ideaService.getPublicIdeas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Ошибка загрузки идей: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final ideas = snapshot.data ?? [];
          if (ideas.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Пока нет идей'),
                ],
              ),
            );
          }

          return _buildPinterestGrid(ideas);
        },
      );

  Widget _buildPopularIdeasList() => StreamBuilder<List<Idea>>(
        stream: _ideaService.getPopularIdeas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Ошибка загрузки популярных идей: ${snapshot.error}'),
            );
          }

          final ideas = snapshot.data ?? [];
          return _buildPinterestGrid(ideas);
        },
      );

  Widget _buildCategoryIdeasList(String category) => StreamBuilder<List<Idea>>(
        stream: _ideaService.getIdeasByCategory(category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Ошибка загрузки идей категории: ${snapshot.error}'),
            );
          }

          final ideas = snapshot.data ?? [];
          return _buildPinterestGrid(ideas);
        },
      );

  Widget _buildPinterestGrid(List<Idea> ideas) => Padding(
        padding: const EdgeInsets.all(8),
        child: MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          itemCount: ideas.length,
          itemBuilder: (context, index) {
            final idea = ideas[index];
            return _buildIdeaCard(idea);
          },
        ),
      );

  Widget _buildIdeaCard(Idea idea) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showIdeaDetails(idea),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (idea.images.isNotEmpty)
                AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    idea.images.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child:
                          const Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
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
                        IconButton(
                          icon: Icon(
                            idea.likedBy.contains(
                              'current_user_id',
                            ) // TODO: Получить реальный ID
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: idea.likedBy.contains('current_user_id')
                                ? Colors.red
                                : Colors.grey,
                          ),
                          onPressed: () => _toggleLike(idea),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Text('${idea.likesCount}'),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(
                            idea.savedBy.contains(
                              'current_user_id',
                            ) // TODO: Получить реальный ID
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: idea.savedBy.contains('current_user_id')
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          onPressed: () => _toggleSave(idea),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Text('${idea.savesCount}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

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

  void _performSearch() {
    // TODO: Реализовать поиск
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Поиск: $_searchQuery')),
    );
  }

  void _showCreateIdeaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать идею'),
        content: const Text(
          'Функция создания идей будет добавлена в следующих версиях',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
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

  void _toggleLike(Idea idea) {
    // TODO: Реализовать лайк
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция лайков будет добавлена')),
    );
  }

  void _toggleSave(Idea idea) {
    // TODO: Реализовать сохранение
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция сохранения будет добавлена')),
    );
  }

  void _showComments(Idea idea) {
    // TODO: Реализовать комментарии
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция комментариев будет добавлена')),
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
