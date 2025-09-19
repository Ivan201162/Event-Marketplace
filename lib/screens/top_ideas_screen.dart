import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/idea.dart';
import '../services/idea_service.dart';
import '../widgets/idea_widget.dart';
import 'idea_detail_screen.dart';

/// Экран топ идей
class TopIdeasScreen extends ConsumerStatefulWidget {
  const TopIdeasScreen({
    super.key,
    this.userId,
  });
  final String? userId;

  @override
  ConsumerState<TopIdeasScreen> createState() => _TopIdeasScreenState();
}

class _TopIdeasScreenState extends ConsumerState<TopIdeasScreen> {
  final IdeaService _ideaService = IdeaService();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Топ идеи'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {}),
            ),
          ],
        ),
        body: StreamBuilder<List<Idea>>(
          stream: _ideaService.getTopIdeasOfWeek(),
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
                    Text('Ошибка: ${snapshot.error}'),
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
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: ideas.length,
              itemBuilder: (context, index) {
                final idea = ideas[index];
                return IdeaWidget(
                  idea: idea,
                  onTap: () => _showIdeaDetail(idea),
                  onLike: () => _likeIdea(idea),
                  onSave: () => _saveIdea(idea),
                  onShare: () => _shareIdea(idea),
                );
              },
            );
          },
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.trending_up, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Нет топ идей',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Пока нет популярных идей за эту неделю',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Перейти к экрану идей
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Переход к экрану идей')),
                );
              },
              icon: const Icon(Icons.lightbulb),
              label: const Text('Просмотреть все идеи'),
            ),
          ],
        ),
      );

  void _showIdeaDetail(Idea idea) {
    if (widget.userId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => IdeaDetailScreen(
            idea: idea,
            userId: widget.userId!,
          ),
        ),
      );
    }
  }

  void _likeIdea(Idea idea) {
    if (widget.userId != null) {
      _ideaService.likeIdea(idea.id, widget.userId!);
    }
  }

  void _saveIdea(Idea idea) {
    if (widget.userId != null) {
      _ideaService.saveIdea(idea.id, widget.userId!);
    }
  }

  void _shareIdea(Idea idea) {
    // TODO: Реализовать шаринг идеи
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Идея скопирована в буфер обмена')),
    );
  }
}

/// Экран категорий идей
class IdeaCategoriesScreen extends ConsumerStatefulWidget {
  const IdeaCategoriesScreen({
    super.key,
    this.userId,
  });
  final String? userId;

  @override
  ConsumerState<IdeaCategoriesScreen> createState() =>
      _IdeaCategoriesScreenState();
}

class _IdeaCategoriesScreenState extends ConsumerState<IdeaCategoriesScreen> {
  final IdeaService _ideaService = IdeaService();

  final List<String> _categories = [
    'Декор',
    'Еда',
    'Развлечения',
    'Фото',
    'Музыка',
    'Одежда',
    'Подарки',
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Категории идей'),
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return _buildCategoryCard(category);
          },
        ),
      );

  Widget _buildCategoryCard(String category) => Card(
        child: InkWell(
          onTap: () => _showCategoryIdeas(category),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: 48,
                  color: _getCategoryColor(category),
                ),
                const SizedBox(height: 12),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'декор':
        return Icons.home;
      case 'еда':
        return Icons.restaurant;
      case 'развлечения':
        return Icons.celebration;
      case 'фото':
        return Icons.camera_alt;
      case 'музыка':
        return Icons.music_note;
      case 'одежда':
        return Icons.checkroom;
      case 'подарки':
        return Icons.card_giftcard;
      default:
        return Icons.lightbulb;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'декор':
        return Colors.pink;
      case 'еда':
        return Colors.orange;
      case 'развлечения':
        return Colors.purple;
      case 'фото':
        return Colors.blue;
      case 'музыка':
        return Colors.green;
      case 'одежда':
        return Colors.red;
      case 'подарки':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  void _showCategoryIdeas(String category) {
    // TODO: Реализовать экран идей по категории
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Идеи категории: $category')),
    );
  }
}

/// Экран поиска идей
class IdeaSearchScreen extends ConsumerStatefulWidget {
  const IdeaSearchScreen({
    super.key,
    this.userId,
  });
  final String? userId;

  @override
  ConsumerState<IdeaSearchScreen> createState() => _IdeaSearchScreenState();
}

class _IdeaSearchScreenState extends ConsumerState<IdeaSearchScreen> {
  final IdeaService _ideaService = IdeaService();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  List<Idea> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Поиск идей'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск идей...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _performSearch,
                  ),
                ),
                onSubmitted: (_) => _performSearch(),
              ),
            ),
          ),
        ),
        body: _isSearching
            ? const Center(child: CircularProgressIndicator())
            : _searchResults.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final idea = _searchResults[index];
                      return IdeaWidget(
                        idea: idea,
                        onTap: () => _showIdeaDetail(idea),
                        onLike: () => _likeIdea(idea),
                        onSave: () => _saveIdea(idea),
                        onShare: () => _shareIdea(idea),
                      );
                    },
                  ),
      );

  Widget _buildEmptyState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Поиск идей',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Введите поисковый запрос для поиска идей',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    // TODO: Реализовать поиск идей
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isSearching = false;
        _searchResults = []; // Заглушка
      });
    });
  }

  void _showIdeaDetail(Idea idea) {
    if (widget.userId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => IdeaDetailScreen(
            idea: idea,
            userId: widget.userId!,
          ),
        ),
      );
    }
  }

  void _likeIdea(Idea idea) {
    if (widget.userId != null) {
      _ideaService.likeIdea(idea.id, widget.userId!);
    }
  }

  void _saveIdea(Idea idea) {
    if (widget.userId != null) {
      _ideaService.saveIdea(idea.id, widget.userId!);
    }
  }

  void _shareIdea(Idea idea) {
    // TODO: Реализовать шаринг идеи
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Идея скопирована в буфер обмена')),
    );
  }
}
