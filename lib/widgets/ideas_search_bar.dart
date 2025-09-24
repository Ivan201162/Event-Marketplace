import 'package:flutter/material.dart';

/// Поисковая строка для идей
class IdeasSearchBar extends StatefulWidget {
  const IdeasSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    this.hintText = 'Поиск идей...',
    this.showFilters = false,
    this.onFilterTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final String hintText;
  final bool showFilters;
  final VoidCallback? onFilterTap;

  @override
  State<IdeasSearchBar> createState() => _IdeasSearchBarState();
}

class _IdeasSearchBarState extends State<IdeasSearchBar> {
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Иконка поиска
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Icon(
              Icons.search,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          
          // Поле ввода
          Expanded(
            child: TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _isSearching = value.isNotEmpty;
                });
              },
              onSubmitted: widget.onSearch,
            ),
          ),
          
          // Кнопка очистки
          if (_isSearching)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              onPressed: () {
                widget.controller.clear();
                setState(() {
                  _isSearching = false;
                });
                widget.onSearch('');
              },
            ),
          
          // Кнопка фильтров
          if (widget.showFilters)
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              onPressed: widget.onFilterTap,
            ),
        ],
      ),
    );
  }
}

/// Быстрый поиск с популярными тегами
class QuickSearchWidget extends StatelessWidget {
  const QuickSearchWidget({
    super.key,
    required this.popularTags,
    required this.onTagSelected,
  });

  final List<String> popularTags;
  final ValueChanged<String> onTagSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (popularTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Популярные теги',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: popularTags.length,
            itemBuilder: (context, index) {
              final tag = popularTags[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text('#$tag'),
                  onPressed: () => onTagSelected(tag),
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Результаты поиска
class SearchResultsWidget extends StatelessWidget {
  const SearchResultsWidget({
    super.key,
    required this.query,
    required this.resultsCount,
    this.onClearSearch,
  });

  final String query;
  final int resultsCount;
  final VoidCallback? onClearSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Найдено $resultsCount результатов по запросу "$query"',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          if (onClearSearch != null)
            TextButton(
              onPressed: onClearSearch,
              child: const Text('Очистить'),
            ),
        ],
      ),
    );
  }
}
