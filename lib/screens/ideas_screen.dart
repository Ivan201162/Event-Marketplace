import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/idea.dart';
import '../services/idea_service.dart';
import '../widgets/idea_widget.dart';
import 'create_idea_screen.dart';
import 'idea_detail_screen.dart';

/// Экран идей
class IdeasScreen extends ConsumerStatefulWidget {
  final String? userId;

  const IdeasScreen({
    super.key,
    this.userId,
  });

  @override
  ConsumerState<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends ConsumerState<IdeasScreen> {
  final IdeaService _ideaService = IdeaService();
  
  IdeaFilter _filter = const IdeaFilter();
  String _searchQuery = '';
  String _selectedCategory = '';

  final List<String> _categories = [
    'Все',
    'Декор',
    'Еда',
    'Развлечения',
    'Фото',
    'Музыка',
    'Одежда',
    'Подарки',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Идеи'),
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
      body: Column(
        children: [
          // Категории
          _buildCategorySelector(),
          
          // Статистика
          _buildStatsSection(),
          
          // Список идей
          Expanded(
            child: _buildIdeasList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createIdea,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : '';
                  _filter = _filter.copyWith(
                    category: selected && category != 'Все' ? category : null,
                  );
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSection() {
    return FutureBuilder<IdeaStats>(
      future: _ideaService.getIdeaStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data ?? IdeaStats.empty();
        if (stats.totalIdeas == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Идей',
                      stats.totalIdeas.toString(),
                      Icons.lightbulb,
                      Colors.amber,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Лайков',
                      stats.totalLikes.toString(),
                      Icons.favorite,
                      Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Просмотров',
                      stats.totalViews.toString(),
                      Icons.visibility,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Сохранений',
                      stats.totalSaves.toString(),
                      Icons.bookmark,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildIdeasList() {
    return StreamBuilder<List<Idea>>(
      stream: _ideaService.getIdeas(_filter),
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
        final filteredIdeas = _filterIdeas(ideas);

        if (filteredIdeas.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: filteredIdeas.length,
          itemBuilder: (context, index) {
            final idea = filteredIdeas[index];
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Нет идей',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Создайте первую идею или измените фильтры',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _createIdea,
            icon: const Icon(Icons.add),
            label: const Text('Создать идею'),
          ),
        ],
      ),
    );
  }

  List<Idea> _filterIdeas(List<Idea> ideas) {
    if (_searchQuery.isEmpty) return ideas;
    
    final query = _searchQuery.toLowerCase();
    return ideas.where((idea) {
      return idea.title.toLowerCase().contains(query) ||
             idea.description.toLowerCase().contains(query) ||
             idea.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
  }

  void _createIdea() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateIdeaScreen(
          userId: widget.userId ?? 'demo_user_id',
        ),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _showIdeaDetail(Idea idea) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IdeaDetailScreen(
          idea: idea,
          userId: widget.userId ?? 'demo_user_id',
        ),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {});
      }
    });
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

  void _showSearchDialog() {
    showDialog(
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
              _filter = _filter.copyWith(searchQuery: value);
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Поиск'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        filter: _filter,
        onFilterChanged: (newFilter) {
          setState(() {
            _filter = newFilter;
          });
        },
      ),
    );
  }
}

/// Диалог фильтра идей
class _FilterDialog extends StatefulWidget {
  final IdeaFilter filter;
  final Function(IdeaFilter) onFilterChanged;

  const _FilterDialog({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late IdeaFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Фильтр идей'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Тип идеи
          DropdownButtonFormField<IdeaType>(
            value: _filter.type,
            decoration: const InputDecoration(
              labelText: 'Тип идеи',
              border: OutlineInputBorder(),
            ),
            items: IdeaType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getTypeText(type)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _filter = _filter.copyWith(type: value);
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Сортировка
          DropdownButtonFormField<IdeaSortBy>(
            value: _filter.sortBy,
            decoration: const InputDecoration(
              labelText: 'Сортировка',
              border: OutlineInputBorder(),
            ),
            items: IdeaSortBy.values.map((sort) {
              return DropdownMenuItem(
                value: sort,
                child: Text(_getSortText(sort)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _filter = _filter.copyWith(sortBy: value);
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Порядок сортировки
          SwitchListTile(
            title: const Text('По возрастанию'),
            value: _filter.sortAscending,
            onChanged: (value) {
              setState(() {
                _filter = _filter.copyWith(sortAscending: value);
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
        ElevatedButton(
          onPressed: () {
            widget.onFilterChanged(_filter);
            Navigator.pop(context);
          },
          child: const Text('Применить'),
        ),
      ],
    );
  }

  String _getTypeText(IdeaType type) {
    switch (type) {
      case IdeaType.general:
        return 'Общие';
      case IdeaType.wedding:
        return 'Свадьба';
      case IdeaType.birthday:
        return 'День рождения';
      case IdeaType.corporate:
        return 'Корпоратив';
      case IdeaType.holiday:
        return 'Праздник';
      case IdeaType.other:
        return 'Другое';
    }
  }

  String _getSortText(IdeaSortBy sort) {
    switch (sort) {
      case IdeaSortBy.date:
        return 'По дате';
      case IdeaSortBy.likes:
        return 'По лайкам';
      case IdeaSortBy.views:
        return 'По просмотрам';
      case IdeaSortBy.saves:
        return 'По сохранениям';
      case IdeaSortBy.comments:
        return 'По комментариям';
      case IdeaSortBy.title:
        return 'По названию';
    }
  }
}