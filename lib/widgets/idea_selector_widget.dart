import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_idea.dart';
import '../services/event_ideas_service.dart';
import '../widgets/idea_card.dart';

/// Виджет для выбора идей при создании заявки
class IdeaSelectorWidget extends ConsumerStatefulWidget {
  const IdeaSelectorWidget({
    super.key,
    required this.onIdeasSelected,
    this.selectedIdeas = const [],
    this.maxSelections = 5,
  });

  final Function(List<EventIdea>) onIdeasSelected;
  final List<EventIdea> selectedIdeas;
  final int maxSelections;

  @override
  ConsumerState<IdeaSelectorWidget> createState() => _IdeaSelectorWidgetState();
}

class _IdeaSelectorWidgetState extends ConsumerState<IdeaSelectorWidget> {
  final EventIdeasService _ideasService = EventIdeasService();
  List<EventIdea> _allIdeas = [];
  List<EventIdea> _filteredIdeas = [];
  List<EventIdea> _selectedIdeas = [];
  bool _isLoading = true;
  String _searchQuery = '';
  EventIdeaCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedIdeas = List.from(widget.selectedIdeas);
    _loadIdeas();
  }

  Future<void> _loadIdeas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ideas = await _ideasService.getPublishedIdeas();
      setState(() {
        _allIdeas = ideas;
        _filteredIdeas = ideas;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Ошибка загрузки идей: $e');
    }
  }

  void _filterIdeas() {
    setState(() {
      _filteredIdeas = _allIdeas.where((idea) {
        final matchesSearch = _searchQuery.isEmpty ||
            idea.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            idea.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            idea.tags.any(
              (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()),
            );

        final matchesCategory = _selectedCategory == null || idea.category == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _toggleIdeaSelection(EventIdea idea) {
    setState(() {
      if (_selectedIdeas.contains(idea)) {
        _selectedIdeas.remove(idea);
      } else if (_selectedIdeas.length < widget.maxSelections) {
        _selectedIdeas.add(idea);
      } else {
        _showErrorSnackBar('Максимум ${widget.maxSelections} идей');
      }
    });
    widget.onIdeasSelected(_selectedIdeas);
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                'Выберите идеи для заявки',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                '${_selectedIdeas.length}/${widget.maxSelections}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Поиск и фильтры
          _buildSearchAndFilters(),

          const SizedBox(height: 16),

          // Выбранные идеи
          if (_selectedIdeas.isNotEmpty) ...[
            _buildSelectedIdeas(),
            const SizedBox(height: 16),
          ],

          // Список идей
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredIdeas.isEmpty
                    ? _buildEmptyState()
                    : _buildIdeasGrid(),
          ),
        ],
      );

  Widget _buildSearchAndFilters() => Column(
        children: [
          // Поиск
          TextField(
            decoration: InputDecoration(
              hintText: 'Поиск идей...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filterIdeas();
            },
          ),

          const SizedBox(height: 12),

          // Фильтр по категориям
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: EventIdeaCategory.values.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('Все'),
                      selected: _selectedCategory == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = null;
                        });
                        _filterIdeas();
                      },
                    ),
                  );
                }

                final category = EventIdeaCategory.values[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(category.emoji),
                        const SizedBox(width: 4),
                        Text(category.displayName),
                      ],
                    ),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
                      });
                      _filterIdeas();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      );

  Widget _buildSelectedIdeas() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выбранные идеи:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedIdeas.length,
              itemBuilder: (context, index) {
                final idea = _selectedIdeas[index];
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            Expanded(
                              child: Image.network(
                                idea.imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                idea.title,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _toggleIdeaSelection(idea),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Theme.of(context).colorScheme.onError,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );

  Widget _buildIdeasGrid() => GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _filteredIdeas.length,
        itemBuilder: (context, index) {
          final idea = _filteredIdeas[index];
          final isSelected = _selectedIdeas.contains(idea);
          final canSelect = _selectedIdeas.length < widget.maxSelections || isSelected;

          return Stack(
            children: [
              IdeaCard(
                idea: idea,
                onTap: () => _toggleIdeaSelection(idea),
                onLike: () {}, // Заглушка
                onFavorite: () {}, // Заглушка
              ),
              if (isSelected)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              if (!canSelect)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.block,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );

  Widget _buildEmptyState() => Center(
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
              'Идеи не найдены',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить фильтры или поисковый запрос',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

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

/// Диалог выбора идей
class IdeaSelectorDialog extends StatelessWidget {
  const IdeaSelectorDialog({
    super.key,
    required this.onIdeasSelected,
    this.selectedIdeas = const [],
    this.maxSelections = 5,
  });

  final Function(List<EventIdea>) onIdeasSelected;
  final List<EventIdea> selectedIdeas;
  final int maxSelections;

  @override
  Widget build(BuildContext context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Заголовок
              Row(
                children: [
                  Text(
                    'Выберите идеи',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Виджет выбора идей
              Expanded(
                child: IdeaSelectorWidget(
                  onIdeasSelected: onIdeasSelected,
                  selectedIdeas: selectedIdeas,
                  maxSelections: maxSelections,
                ),
              ),

              const SizedBox(height: 16),

              // Кнопки
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Готово'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
