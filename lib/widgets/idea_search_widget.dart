import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_idea.dart';
import '../services/event_idea_service.dart';
import 'event_idea_card.dart';

/// Виджет поиска идей
class IdeaSearchWidget extends ConsumerStatefulWidget {
  const IdeaSearchWidget({super.key});

  @override
  ConsumerState<IdeaSearchWidget> createState() => _IdeaSearchWidgetState();
}

class _IdeaSearchWidgetState extends ConsumerState<IdeaSearchWidget> {
  final EventIdeaService _ideaService = EventIdeaService();
  final TextEditingController _searchController = TextEditingController();

  List<EventIdea> _searchResults = [];
  List<String> _popularTags = [];
  List<String> _categories = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _error;

  final List<String> _defaultCategories = [
    'Свадьба',
    'День рождения',
    'Корпоратив',
    'Детский праздник',
    'Выпускной',
    'Юбилей',
    'Новый год',
    'Другое',
  ];

  @override
  void initState() {
    super.initState();
    _loadPopularTags();
    _categories = _defaultCategories;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPopularTags() async {
    try {
      final tags = await _ideaService.getPopularTags();
      setState(() {
        _popularTags = tags;
      });
    } catch (e) {
      debugPrint('Error loading popular tags: $e');
    }
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final results = await _ideaService.getAllIdeas(
        searchQuery: _searchController.text.trim(),
        limit: 50,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  Future<void> _searchByCategory(String category) async {
    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final results = await _ideaService.getAllIdeas(category: category, limit: 50);

      setState(() {
        _searchResults = results;
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  Future<void> _searchByTag(String tag) async {
    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final results = await _ideaService.getAllIdeas(tags: [tag], limit: 50);

      setState(() {
        _searchResults = results;
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      // Поисковая строка
      _buildSearchBar(),

      // Фильтры
      _buildFilters(),

      // Результаты поиска
      Expanded(child: _buildSearchResults()),
    ],
  );

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.all(16),
    child: TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Поиск идей мероприятий...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  _performSearch();
                },
                icon: const Icon(Icons.clear),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      onChanged: (value) {
        setState(() {});
        if (value.trim().isNotEmpty) {
          _performSearch();
        }
      },
      onSubmitted: (_) => _performSearch(),
    ),
  );

  Widget _buildFilters() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Категории
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Категории',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      onSelected: (selected) {
                        if (selected) {
                          _searchByCategory(category);
                        } else {
                          _performSearch();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 16),

      // Популярные теги
      if (_popularTags.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Популярные теги',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _popularTags.length,
                  itemBuilder: (context, index) {
                    final tag = _popularTags[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('#$tag'),
                        onSelected: (selected) {
                          if (selected) {
                            _searchByTag(tag);
                          } else {
                            _performSearch();
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    ],
  );

  Widget _buildSearchResults() {
    if (!_hasSearched) {
      return _buildEmptyState();
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResultsState();
    }

    return RefreshIndicator(
      onRefresh: _performSearch,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        padding: const EdgeInsets.all(16),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final idea = _searchResults[index];
          return EventIdeaCard(
            idea: idea,
            onTap: () => _viewIdea(idea),
            onLike: () => _toggleLike(idea),
            onComment: () => _viewIdea(idea),
            onShare: () => _shareIdea(idea),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'Поиск идей мероприятий',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          'Введите ключевые слова или выберите категорию',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildErrorState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text('Ошибка поиска', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          _error!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _performSearch, child: const Text('Повторить')),
      ],
    ),
  );

  Widget _buildNoResultsState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'Ничего не найдено',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          'Попробуйте изменить поисковый запрос или выбрать другую категорию',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            _searchController.clear();
            _performSearch();
          },
          child: const Text('Очистить поиск'),
        ),
      ],
    ),
  );

  void _viewIdea(EventIdea idea) {
    // Здесь можно открыть детальный просмотр идеи
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(idea.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (idea.hasImages) ...[
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: idea.images.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          idea.images[index],
                          width: 150,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(idea.description),
              const SizedBox(height: 16),
              if (idea.tags.isNotEmpty) ...[
                const Text('Теги:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  children: idea.tags
                      .map(
                        (tag) =>
                            Chip(label: Text('#$tag'), labelStyle: const TextStyle(fontSize: 12)),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  Future<void> _toggleLike(EventIdea idea) async {
    try {
      await _ideaService.likeIdea(idea.id);
      _performSearch();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    }
  }

  void _shareIdea(EventIdea idea) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция шаринга будет добавлена позже'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
