import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_idea.dart';
import '../providers/ideas_providers.dart';
import '../providers/auth_providers.dart';

class IdeasScreen extends ConsumerStatefulWidget {
  const IdeasScreen({super.key});

  @override
  ConsumerState<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends ConsumerState<IdeasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Фильтры
  String? _selectedCategory;
  String? _selectedEventType;
  String? _selectedBudget;
  String? _selectedSeason;
  String? _selectedVenue;

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
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Идеи для мероприятий'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Все идеи'),
            Tab(text: 'Популярные'),
            Tab(text: 'Последние'),
            Tab(text: 'Мои сохраненные'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltersDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateIdeaDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          _buildSearchBar(),
          
          // Контент
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllIdeasTab(),
                _buildPopularIdeasTab(),
                _buildRecentIdeasTab(),
                _buildSavedIdeasTab(currentUser?.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Поиск идей...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        onSubmitted: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildAllIdeasTab() {
    final ideasAsync = ref.watch(publicIdeasProvider);

    return ideasAsync.when(
      data: (ideas) {
        final filteredIdeas = _filterIdeas(ideas);
        return _buildIdeasGrid(filteredIdeas);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки идей: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(publicIdeasProvider);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularIdeasTab() {
    final ideasAsync = ref.watch(popularIdeasProvider);

    return ideasAsync.when(
      data: (ideas) => _buildIdeasGrid(ideas),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки популярных идей: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(popularIdeasProvider);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentIdeasTab() {
    final ideasAsync = ref.watch(recentIdeasProvider);

    return ideasAsync.when(
      data: (ideas) => _buildIdeasGrid(ideas),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки последних идей: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(recentIdeasProvider);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedIdeasTab(String? userId) {
    if (userId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Войдите в аккаунт, чтобы просматривать сохраненные идеи'),
          ],
        ),
      );
    }

    final ideasAsync = ref.watch(savedIdeasProvider(userId));

    return ideasAsync.when(
      data: (ideas) {
        if (ideas.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Нет сохраненных идей'),
                SizedBox(height: 8),
                Text('Сохраняйте понравившиеся идеи для быстрого доступа'),
              ],
            ),
          );
        }
        return _buildIdeasGrid(ideas);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки сохраненных идей: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(savedIdeasProvider(userId));
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdeasGrid(List<EventIdea> ideas) {
    if (ideas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Идеи не найдены'),
            SizedBox(height: 8),
            Text('Попробуйте изменить фильтры или поисковый запрос'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(publicIdeasProvider);
        ref.invalidate(popularIdeasProvider);
        ref.invalidate(recentIdeasProvider);
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: ideas.length,
        itemBuilder: (context, index) {
          final idea = ideas[index];
          return _buildIdeaCard(idea);
        },
      ),
    );
  }

  Widget _buildIdeaCard(EventIdea idea) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showIdeaDetails(idea),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                ),
                child: idea.imageUrls.isNotEmpty
                    ? Image.network(
                        idea.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image, size: 48, color: Colors.grey);
                        },
                      )
                    : const Icon(Icons.image, size: 48, color: Colors.grey),
              ),
            ),
            
            // Контент
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      idea.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    Text(
                      idea.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        Icon(Icons.favorite, size: 14, color: Colors.red[300]),
                        const SizedBox(width: 4),
                        Text(
                          '${idea.likesCount}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.bookmark, size: 14, color: Colors.blue[300]),
                        const SizedBox(width: 4),
                        Text(
                          '${idea.savesCount}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<EventIdea> _filterIdeas(List<EventIdea> ideas) {
    var filtered = ideas;

    // Поиск по тексту
    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      filtered = filtered.where((idea) {
        return idea.title.toLowerCase().contains(searchLower) ||
               idea.description.toLowerCase().contains(searchLower) ||
               idea.tags.any((tag) => tag.toLowerCase().contains(searchLower));
      }).toList();
    }

    // Фильтры
    if (_selectedCategory != null) {
      filtered = filtered.where((idea) => idea.category == _selectedCategory).toList();
    }
    if (_selectedEventType != null) {
      filtered = filtered.where((idea) => idea.eventType == _selectedEventType).toList();
    }
    if (_selectedBudget != null) {
      filtered = filtered.where((idea) => idea.budget == _selectedBudget).toList();
    }
    if (_selectedSeason != null) {
      filtered = filtered.where((idea) => idea.season == _selectedSeason).toList();
    }
    if (_selectedVenue != null) {
      filtered = filtered.where((idea) => idea.venue == _selectedVenue).toList();
    }

    return filtered;
  }

  void _showIdeaDetails(EventIdea idea) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Expanded(
                    child: Text(
                      idea.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Изображения
              if (idea.imageUrls.isNotEmpty) ...[
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: idea.imageUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            idea.imageUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image, size: 48, color: Colors.grey);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Описание
              Text(
                idea.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              
              // Теги
              if (idea.tags.isNotEmpty) ...[
                Text(
                  'Теги:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: idea.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              // Действия
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _likeIdea(idea),
                      icon: const Icon(Icons.favorite_border),
                      label: const Text('Лайк'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _saveIdea(idea),
                      icon: const Icon(Icons.bookmark_border),
                      label: const Text('Сохранить'),
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

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Категория
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Категория'),
                items: EventIdeaCategories.categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Тип мероприятия
              DropdownButtonFormField<String>(
                value: _selectedEventType,
                decoration: const InputDecoration(labelText: 'Тип мероприятия'),
                items: EventIdeaCategories.eventTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEventType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Бюджет
              DropdownButtonFormField<String>(
                value: _selectedBudget,
                decoration: const InputDecoration(labelText: 'Бюджет'),
                items: EventIdeaCategories.budgets.map((budget) {
                  return DropdownMenuItem(
                    value: budget,
                    child: Text(budget),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBudget = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = null;
                _selectedEventType = null;
                _selectedBudget = null;
                _selectedSeason = null;
                _selectedVenue = null;
              });
            },
            child: const Text('Сбросить'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showCreateIdeaDialog() {
    // TODO: Реализовать создание новой идеи
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Создание идеи будет реализовано позже')),
    );
  }

  void _likeIdea(EventIdea idea) {
    // TODO: Реализовать лайк идеи
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Лайк будет реализован позже')),
    );
  }

  void _saveIdea(EventIdea idea) {
    // TODO: Реализовать сохранение идеи
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сохранение будет реализовано позже')),
    );
  }
}
