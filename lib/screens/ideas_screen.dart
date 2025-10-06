import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/app_navigator.dart';

class IdeasScreen extends ConsumerStatefulWidget {
  const IdeasScreen({super.key});

  @override
  ConsumerState<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends ConsumerState<IdeasScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'Все';
  bool _isGridView = true;

  final List<String> _categories = [
    'Все',
    'Свадьбы',
    'Дни рождения',
    'Корпоративы',
    'Детские праздники',
    'Выпускные',
    'Юбилеи',
  ];

  final List<Map<String, dynamic>> _ideas = [
    {
      'id': '1',
      'title': 'Романтическая свадьба в саду',
      'category': 'Свадьбы',
      'image': 'https://via.placeholder.com/300x200/FF6B6B/FFFFFF?text=Wedding',
      'likes': 124,
      'saves': 89,
      'isLiked': false,
      'isSaved': false,
    },
    {
      'id': '2',
      'title': 'Детский день рождения с аниматорами',
      'category': 'Детские праздники',
      'image': 'https://via.placeholder.com/300x200/4ECDC4/FFFFFF?text=Kids',
      'likes': 67,
      'saves': 45,
      'isLiked': true,
      'isSaved': false,
    },
    {
      'id': '3',
      'title': 'Корпоратив в стиле 80-х',
      'category': 'Корпоративы',
      'image':
          'https://via.placeholder.com/300x200/45B7D1/FFFFFF?text=Corporate',
      'likes': 203,
      'saves': 156,
      'isLiked': false,
      'isSaved': true,
    },
    {
      'id': '4',
      'title': 'Выпускной в стиле Гарри Поттера',
      'category': 'Выпускные',
      'image':
          'https://via.placeholder.com/300x200/96CEB4/FFFFFF?text=Graduation',
      'likes': 89,
      'saves': 67,
      'isLiked': true,
      'isSaved': true,
    },
    {
      'id': '5',
      'title': 'Юбилей в винтажном стиле',
      'category': 'Юбилеи',
      'image':
          'https://via.placeholder.com/300x200/FFEAA7/FFFFFF?text=Anniversary',
      'likes': 145,
      'saves': 98,
      'isLiked': false,
      'isSaved': false,
    },
    {
      'id': '6',
      'title': 'День рождения в стиле пиратов',
      'category': 'Дни рождения',
      'image': 'https://via.placeholder.com/300x200/DDA0DD/FFFFFF?text=Pirate',
      'likes': 78,
      'saves': 56,
      'isLiked': true,
      'isSaved': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredIdeas {
    if (_selectedCategory == 'Все') {
      return _ideas;
    }
    return _ideas
        .where((idea) => idea['category'] == _selectedCategory)
        .toList();
  }

  void _toggleLike(String ideaId) {
    setState(() {
      final ideaIndex = _ideas.indexWhere((idea) => idea['id'] == ideaId);
      if (ideaIndex != -1) {
        final idea = _ideas[ideaIndex];
        final isLiked = idea['isLiked'] as bool;
        _ideas[ideaIndex] = {
          ...idea,
          'isLiked': !isLiked,
          'likes': (idea['likes'] as int) + (isLiked ? -1 : 1),
        };
      }
    });
  }

  void _toggleSave(String ideaId) {
    setState(() {
      final ideaIndex = _ideas.indexWhere((idea) => idea['id'] == ideaId);
      if (ideaIndex != -1) {
        final idea = _ideas[ideaIndex];
        final isSaved = idea['isSaved'] as bool;
        _ideas[ideaIndex] = {
          ...idea,
          'isSaved': !isSaved,
          'saves': (idea['saves'] as int) + (isSaved ? -1 : 1),
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Идеи для мероприятий'),
          leading: AppNavigator.buildBackButton(context),
          actions: [
            IconButton(
              icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Все идеи'),
              Tab(text: 'Сохраненные'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Фильтры по категориям
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            // Список идей
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIdeasList(_filteredIdeas),
                  _buildIdeasList(
                    _ideas.where((idea) => idea['isSaved'] == true).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.push('/create-idea');
          },
          child: const Icon(Icons.add),
        ),
      );

  Widget _buildIdeasList(List<Map<String, dynamic>> ideas) {
    if (ideas.isEmpty) {
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
            Text(
              'Попробуйте другую категорию',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_isGridView) {
      return GridView.builder(
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
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ideas.length,
        itemBuilder: (context, index) {
          final idea = ideas[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildIdeaCard(idea, isList: true),
          );
        },
      );
    }
  }

  Widget _buildIdeaCard(Map<String, dynamic> idea, {bool isList = false}) =>
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            context.push('/idea/${idea['id']}');
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Изображение
              Expanded(
                flex: isList ? 2 : 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    image: DecorationImage(
                      image: NetworkImage(idea['image']),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        // Обработка ошибки загрузки изображения
                      },
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Категория
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            idea['category'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      // Кнопка сохранения
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          onPressed: () => _toggleSave(idea['id']),
                          icon: Icon(
                            idea['isSaved']
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color:
                                idea['isSaved'] ? Colors.amber : Colors.white,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Информация
              Expanded(
                flex: isList ? 1 : 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        idea['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const Spacer(),

                      // Статистика
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _toggleLike(idea['id']),
                            icon: Icon(
                              idea['isLiked']
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: idea['isLiked'] ? Colors.red : Colors.grey,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Text(
                            '${idea['likes']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.bookmark_border,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${idea['saves']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              context.push(
                                  '/search?idea=${Uri.encodeComponent(idea['title'])}&category=${Uri.encodeComponent(idea['category'])}');
                            },
                            child: const Text(
                              'Найти специалистов',
                              style: TextStyle(fontSize: 12),
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
        ),
      );
}
