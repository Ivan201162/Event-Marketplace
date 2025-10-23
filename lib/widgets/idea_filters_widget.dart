import 'package:flutter/material.dart';

import '../models/idea_category.dart';

class IdeaFiltersWidget extends StatefulWidget {
  const IdeaFiltersWidget({
    super.key,
    required this.selectedCategory,
    required this.selectedTags,
    required this.onFiltersChanged,
  });
  final IdeaCategory? selectedCategory;
  final List<String> selectedTags;
  final void Function(IdeaCategory?, List<String>) onFiltersChanged;

  @override
  State<IdeaFiltersWidget> createState() => _IdeaFiltersWidgetState();
}

class _IdeaFiltersWidgetState extends State<IdeaFiltersWidget> {
  IdeaCategory? _selectedCategory;
  List<String> _selectedTags = [];
  final List<String> _popularTags = [
    'свадьба',
    'день рождения',
    'корпоратив',
    'фотосессия',
    'оформление',
    'цветы',
    'музыка',
    'кейтеринг',
    'декор',
    'праздник',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _selectedTags = List.from(widget.selectedTags);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Фильтры идей'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Категории
              _buildCategorySection(),

              const SizedBox(height: 24),

              // Популярные теги
              _buildTagsSection(),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: _clearFilters, child: const Text('Очистить')),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
              onPressed: _applyFilters, child: const Text('Применить')),
        ],
      );

  Widget _buildCategorySection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Категория',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <IdeaCategory>[].map((IdeaCategory category) {
              final bool isSelected = _selectedCategory == category;
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category.icon),
                    const SizedBox(width: 4),
                    Text(category.name)
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? category : null;
                  });
                },
                backgroundColor: isSelected
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.2)
                    : null,
                selectedColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2),
                checkmarkColor: Theme.of(context).colorScheme.primary,
              );
            }).toList(),
          ),
        ],
      );

  Widget _buildTagsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Популярные теги',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularTags.map((String tag) {
              final bool isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
                backgroundColor: isSelected
                    ? Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.2)
                    : null,
                selectedColor: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.2),
                checkmarkColor: Theme.of(context).colorScheme.secondary,
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Поле для добавления собственного тега
          TextField(
            decoration: InputDecoration(
              hintText: 'Добавить тег',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                  icon: const Icon(Icons.add), onPressed: _addCustomTag),
            ),
            onSubmitted: _addCustomTag,
          ),
        ],
      );

  void _addCustomTag([String? tag]) {
    final controller = TextEditingController(text: tag ?? '');

    if (tag == null) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Добавить тег'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Введите тег',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () {
                final newTag = controller.text.trim();
                if (newTag.isNotEmpty) {
                  _addTag(newTag);
                  Navigator.pop(context);
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      );
    } else {
      _addTag(tag);
    }
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedTags.clear();
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_selectedCategory, _selectedTags);
    Navigator.pop(context);
  }
}

/// Виджет для отображения активных фильтров
class ActiveFiltersWidget extends StatelessWidget {
  const ActiveFiltersWidget({
    super.key,
    required this.selectedCategory,
    required this.selectedTags,
    required this.onFiltersChanged,
  });
  final IdeaCategory? selectedCategory;
  final List<String> selectedTags;
  final void Function(IdeaCategory?, List<String>) onFiltersChanged;

  @override
  Widget build(BuildContext context) {
    if (selectedCategory == null && selectedTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (selectedCategory != null)
            _buildFilterChip(
              context,
              label:
                  '${selectedCategory!.icon} ${selectedCategory!.displayName}',
              onRemove: () => onFiltersChanged(null, selectedTags),
            ),
          ...selectedTags.map(
            (String tag) => _buildFilterChip(
              context,
              label: tag,
              onRemove: () {
                final newTags = List<String>.from(selectedTags);
                newTags.remove(tag);
                onFiltersChanged(selectedCategory, newTags);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required VoidCallback onRemove,
  }) =>
      Container(
        margin: const EdgeInsets.only(right: 8),
        child: Chip(
          label: Text(label),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: onRemove,
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      );
}
