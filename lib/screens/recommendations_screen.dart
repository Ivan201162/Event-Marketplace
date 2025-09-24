import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/event_idea.dart';
import '../models/specialist.dart';
import '../services/recommendation_service.dart';
import '../widgets/idea_card.dart';
import '../widgets/specialist_card.dart';
import '../core/constants/app_routes.dart';

/// Экран рекомендаций и идей мероприятий
class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen>
    with TickerProviderStateMixin {
  final RecommendationService _recommendationService = RecommendationService();

  late TabController _tabController;

  List<EventIdea> _ideas = [];
  List<EventIdea> _savedIdeas = [];
  List<Specialist> _crossSellRecommendations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  EventIdeaType? _selectedType;
  EventIdeaCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final futures = await Future.wait([
        _recommendationService.getEventIdeas(
          type: _selectedType,
          category: _selectedCategory,
          searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        ),
        _recommendationService
            .getSavedIdeas('current_user_id'), // TODO: Get from auth
        _recommendationService.getCrossSellRecommendations(
          selectedSpecialistIds: [], // TODO: Get from current booking
          customerId: 'current_user_id', // TODO: Get from auth
        ),
      ]);

      setState(() {
        _ideas = futures[0] as List<EventIdea>;
        _savedIdeas = futures[1] as List<EventIdea>;
        _crossSellRecommendations = (futures[2] as List).cast<Specialist>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рекомендации'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Идеи', icon: Icon(Icons.lightbulb_outline)),
            Tab(text: 'Мои идеи', icon: Icon(Icons.bookmark_outline)),
            Tab(text: 'Доп. услуги', icon: Icon(Icons.add_circle_outline)),
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
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIdeasTab(),
          _buildSavedIdeasTab(),
          _buildCrossSellTab(),
        ],
      ),
    );
  }

  Widget _buildIdeasTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ideas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Идеи не найдены',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Попробуйте изменить фильтры или поисковый запрос',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _ideas.length,
        itemBuilder: (context, index) {
          final idea = _ideas[index];
          return IdeaCard(
            idea: idea,
            onTap: () => _showIdeaDetails(idea),
            onSave: () => _saveIdea(idea),
            onLike: () => _likeIdea(idea),
            onFavorite: () => _saveIdea(idea),
          );
        },
      ),
    );
  }

  Widget _buildSavedIdeasTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_savedIdeas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Нет сохраненных идей',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Сохраняйте понравившиеся идеи для будущих мероприятий',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _savedIdeas.length,
        itemBuilder: (context, index) {
          final idea = _savedIdeas[index];
          return IdeaCard(
            idea: idea,
            onTap: () => _showIdeaDetails(idea),
            onSave: () => _unsaveIdea(idea),
            onLike: () => _likeIdea(idea),
            onFavorite: () => _unsaveIdea(idea),
          );
        },
      ),
    );
  }

  Widget _buildCrossSellTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_crossSellRecommendations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Нет рекомендаций',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Выберите специалистов, чтобы получить персональные рекомендации',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _crossSellRecommendations.length,
        itemBuilder: (context, index) {
          final specialist = _crossSellRecommendations[index];
          return SpecialistCard(
            specialist: specialist,
            onTap: () => context.push('/specialist/${specialist.id}'),
            showPrice: true,
          );
        },
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск идей'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Введите ключевые слова...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _searchQuery = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadData();
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Фильтры'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<EventIdeaType?>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Тип мероприятия',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Все типы'),
                  ),
                  ...EventIdeaType.values.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      )),
                ],
                onChanged: (value) => setState(() => _selectedType = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EventIdeaCategory?>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Все категории'),
                  ),
                  ...EventIdeaCategory.values
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category.displayName),
                          )),
                ],
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedType = null;
                  _selectedCategory = null;
                });
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('Сбросить'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadData();
              },
              child: const Text('Применить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showIdeaDetails(EventIdea idea) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    idea.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  idea.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child:
                        const Icon(Icons.image, size: 64, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                idea.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: idea.tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                        ))
                    .toList(),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _saveIdea(idea),
                      icon: const Icon(Icons.bookmark_outline),
                      label: const Text('Сохранить'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _likeIdea(idea),
                      icon: const Icon(Icons.favorite_outline),
                      label: const Text('Нравится'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveIdea(EventIdea idea) async {
    try {
      await _recommendationService.saveIdea('current_user_id', idea.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Идея сохранена')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
  }

  Future<void> _unsaveIdea(EventIdea idea) async {
    try {
      await _recommendationService.unsaveIdea('current_user_id', idea.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Идея удалена из избранного')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $e')),
        );
      }
    }
  }

  Future<void> _likeIdea(EventIdea idea) async {
    // TODO: Implement like functionality
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Функция лайков будет добавлена')),
      );
    }
  }
}
