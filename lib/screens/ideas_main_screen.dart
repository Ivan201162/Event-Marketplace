import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/idea.dart';
import '../services/idea_service.dart';
import '../widgets/idea_widget.dart';
import 'create_idea_screen.dart';
import 'idea_categories_screen.dart';
import 'idea_collections_screen.dart';
import 'idea_detail_screen.dart';
import 'idea_search_screen.dart';
import 'saved_ideas_screen.dart';
import 'top_ideas_screen.dart';

/// Главный экран идей
class IdeasMainScreen extends ConsumerStatefulWidget {
  const IdeasMainScreen({
    super.key,
    this.userId,
  });
  final String? userId;

  @override
  ConsumerState<IdeasMainScreen> createState() => _IdeasMainScreenState();
}

class _IdeasMainScreenState extends ConsumerState<IdeasMainScreen> {
  final IdeaService _ideaService = IdeaService();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Идеи'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchScreen,
            ),
            IconButton(
              icon: const Icon(Icons.collections_bookmark),
              onPressed: _showCollectionsScreen,
            ),
          ],
        ),
        body: Column(
          children: [
            // Быстрые действия
            _buildQuickActions(),

            // Топ идеи недели
            _buildTopIdeasSection(),

            // Категории
            _buildCategoriesSection(),

            // Последние идеи
            Expanded(
              child: _buildRecentIdeasSection(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createIdea,
          child: const Icon(Icons.add),
        ),
      );

  Widget _buildQuickActions() => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.trending_up,
                title: 'Топ идеи',
                color: Colors.orange,
                onTap: _showTopIdeasScreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.bookmark,
                title: 'Сохраненные',
                color: Colors.blue,
                onTap: _showSavedIdeasScreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.collections_bookmark,
                title: 'Коллекции',
                color: Colors.green,
                onTap: _showCollectionsScreen,
              ),
            ),
          ],
        ),
      );

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildTopIdeasSection() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Топ идеи недели',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _showTopIdeasScreen,
                  child: const Text('Все'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: StreamBuilder<List<Idea>>(
                stream: _ideaService.getTopIdeasOfWeek(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final ideas = snapshot.data ?? [];
                  if (ideas.isEmpty) {
                    return const Center(
                      child: Text('Нет топ идей'),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: ideas.length,
                    itemBuilder: (context, index) {
                      final idea = ideas[index];
                      return Container(
                        width: 300,
                        margin: const EdgeInsets.only(right: 12),
                        child: IdeaWidget(
                          idea: idea,
                          onTap: () => _showIdeaDetail(idea),
                          onLike: () => _likeIdea(idea),
                          onSave: () => _saveIdea(idea),
                          onShare: () => _shareIdea(idea),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildCategoriesSection() => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Категории',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _showCategoriesScreen,
                  child: const Text('Все'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _getCategories().length,
                itemBuilder: (context, index) {
                  final category = _getCategories()[index];
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    child: _buildCategoryCard(category),
                  );
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildCategoryCard(String category) => Card(
        child: InkWell(
          onTap: () => _showCategoryIdeas(category),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildRecentIdeasSection() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Последние идеи',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Idea>>(
                stream: _ideaService.getIdeas(const IdeaFilter()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final ideas = snapshot.data ?? [];
                  if (ideas.isEmpty) {
                    return const Center(
                      child: Text('Нет идей'),
                    );
                  }

                  return ListView.builder(
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
            ),
          ],
        ),
      );

  List<String> _getCategories() => [
        'Декор',
        'Еда',
        'Развлечения',
        'Фото',
        'Музыка',
        'Одежда',
        'Подарки',
      ];

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

  void _createIdea() {
    if (widget.userId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreateIdeaScreen(
            userId: widget.userId!,
          ),
        ),
      );
    }
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

  void _showTopIdeasScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TopIdeasScreen(
          userId: widget.userId,
        ),
      ),
    );
  }

  void _showSavedIdeasScreen() {
    if (widget.userId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SavedIdeasScreen(
            userId: widget.userId!,
          ),
        ),
      );
    }
  }

  void _showCollectionsScreen() {
    if (widget.userId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => IdeaCollectionsScreen(
            userId: widget.userId!,
          ),
        ),
      );
    }
  }

  void _showCategoriesScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IdeaCategoriesScreen(
          userId: widget.userId,
        ),
      ),
    );
  }

  void _showSearchScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IdeaSearchScreen(
          userId: widget.userId,
        ),
      ),
    );
  }

  void _showCategoryIdeas(String category) {
    // TODO: Реализовать экран идей по категории
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Идеи категории: $category')),
    );
  }
}
