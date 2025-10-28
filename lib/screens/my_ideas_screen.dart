import 'package:event_marketplace_app/models/event_idea.dart';
import 'package:event_marketplace_app/screens/idea_detail_screen.dart';
import 'package:event_marketplace_app/services/event_ideas_service.dart';
import 'package:event_marketplace_app/widgets/idea_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран моих сохраненных идей
class MyIdeasScreen extends ConsumerStatefulWidget {
  const MyIdeasScreen({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<MyIdeasScreen> createState() => _MyIdeasScreenState();
}

class _MyIdeasScreenState extends ConsumerState<MyIdeasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EventIdeasService _ideasService = EventIdeasService();

  List<EventIdea> _savedIdeas = [];
  List<EventIdea> _createdIdeas = [];
  bool _isLoading = true;
  String _searchQuery = '';
  EventIdeaCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final futures = await Future.wait([
        _ideasService.getFavoriteIdeas(widget.userId),
        _ideasService.getUserIdeas(widget.userId),
      ]);

      setState(() {
        _savedIdeas = futures[0];
        _createdIdeas = futures[1];
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Ошибка загрузки идей: $e');
    }
  }

  List<EventIdea> _getFilteredIdeas(List<EventIdea> ideas) =>
      ideas.where((idea) {
        final matchesSearch = _searchQuery.isEmpty ||
            idea.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            idea.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            idea.tags.any((tag) =>
                tag.toLowerCase().contains(_searchQuery.toLowerCase()),);

        final matchesCategory =
            _selectedCategory == null || idea.category == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Мои идеи'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Сохраненные', icon: Icon(Icons.bookmark)),
              Tab(text: 'Созданные', icon: Icon(Icons.create)),
            ],
          ),
          actions: [
            IconButton(
                onPressed: _showSearchDialog, icon: const Icon(Icons.search),),
            IconButton(
                onPressed: _showFilterDialog,
                icon: const Icon(Icons.filter_list),),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildSavedIdeasTab(), _buildCreatedIdeasTab()],
        ),
      );

  Widget _buildSavedIdeasTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredIdeas = _getFilteredIdeas(_savedIdeas);

    if (filteredIdeas.isEmpty) {
      return _buildEmptySavedIdeasState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filteredIdeas.length,
        itemBuilder: (context, index) {
          final idea = filteredIdeas[index];
          return IdeaCard(
            idea: idea,
            onTap: () => _navigateToIdeaDetail(idea),
            onLike: () => _toggleLike(idea),
          );
        },
      ),
    );
  }

  Widget _buildCreatedIdeasTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredIdeas = _getFilteredIdeas(_createdIdeas);

    if (filteredIdeas.isEmpty) {
      return _buildEmptyCreatedIdeasState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filteredIdeas.length,
        itemBuilder: (context, index) {
          final idea = filteredIdeas[index];
          return IdeaCard(
            idea: idea,
            onTap: () => _navigateToIdeaDetail(idea),
            onLike: () => _toggleLike(idea),
          );
        },
      ),
    );
  }

  Widget _buildEmptySavedIdeasState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет сохраненных идей',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,),
            ),
            const SizedBox(height: 8),
            Text(
              'Добавляйте понравившиеся идеи в избранное',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO(developer): Перейти к экрану идей
                _showErrorSnackBar('Переход к экрану идей');
              },
              icon: const Icon(Icons.lightbulb),
              label: const Text('Просмотреть идеи'),
            ),
          ],
        ),
      );

  Widget _buildEmptyCreatedIdeasState() => Center(
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
              'Нет созданных идей',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,),
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте свою первую идею для мероприятия',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO(developer): Перейти к экрану создания идеи
                _showErrorSnackBar('Переход к созданию идеи');
              },
              icon: const Icon(Icons.add),
              label: const Text('Создать идею'),
            ),
          ],
        ),
      );

  void _navigateToIdeaDetail(EventIdea idea) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (context) => IdeaDetailScreen(idea: idea),),
    ).then((_) {
      // Обновляем данные после возврата
      _loadData();
    });
  }

  Future<void> _toggleLike(EventIdea idea) async {
    try {
      final isLiked = await _ideasService.isIdeaLiked(idea.id, widget.userId);

      if (isLiked) {
        await _ideasService.unlikeIdea(idea.id, widget.userId);
      } else {
        await _ideasService.likeIdea(idea.id, widget.userId);
      }

      // Обновляем локальное состояние
      _updateIdeaInLists(
        idea.id,
        (idea) =>
            idea.copyWith(likes: isLiked ? idea.likes - 1 : idea.likes + 1),
      );
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка изменения лайка: $e');
    }
  }

  Future<void> _toggleFavorite(EventIdea idea) async {
    try {
      final isFavorite =
          await _ideasService.isIdeaInFavorites(idea.id, widget.userId);

      if (isFavorite) {
        await _ideasService.removeFromFavorites(idea.id, widget.userId);
        _savedIdeas.removeWhere((fav) => fav.id == idea.id);
      } else {
        await _ideasService.addToFavorites(idea.id, widget.userId);
        _savedIdeas.add(idea);
      }

      setState(() {});
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка изменения избранного: $e');
    }
  }

  void _updateIdeaInLists(
      String ideaId, EventIdea Function(EventIdea) updater,) {
    setState(() {
      // Обновляем в сохраненных
      final savedIndex = _savedIdeas.indexWhere((idea) => idea.id == ideaId);
      if (savedIndex != -1) {
        _savedIdeas[savedIndex] = updater(_savedIdeas[savedIndex]);
      }

      // Обновляем в созданных
      final createdIndex =
          _createdIdeas.indexWhere((idea) => idea.id == ideaId);
      if (createdIndex != -1) {
        _createdIdeas[createdIndex] = updater(_createdIdeas[createdIndex]);
      }
    });
  }

  void _showSearchDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск идей'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Введите поисковый запрос...',
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
              setState(() {
                _searchQuery = '';
              });
              Navigator.of(context).pop();
            },
            child: const Text('Очистить'),
          ),
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтр по категориям'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Все категории'),
              leading: Radio<EventIdeaCategory?>(
                value: null,
                groupValue: _selectedCategory,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
            ...EventIdeaCategory.values.map(
              (category) => ListTile(
                title: Row(
                  children: [
                    Text(category.emoji),
                    const SizedBox(width: 8),
                    Text(category.displayName),
                  ],
                ),
                leading: Radio<EventIdeaCategory?>(
                  value: category,
                  groupValue: _selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),),
        ],
      ),
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
