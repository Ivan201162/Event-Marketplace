import 'package:flutter/material.dart';

/// Виджет фильтров для идей
class IdeaFilters extends StatelessWidget {

  const IdeaFilters({
    required this.selectedFilter, required this.selectedSort, required this.onFilterChanged, required this.onSortChanged, super.key,
  });
  final String selectedFilter;
  final String selectedSort;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Фильтры по типу
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Все',
                    isSelected: selectedFilter == 'all',
                    onSelected: () => onFilterChanged('all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Популярные',
                    isSelected: selectedFilter == 'popular',
                    onSelected: () => onFilterChanged('popular'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Новые',
                    isSelected: selectedFilter == 'new',
                    onSelected: () => onFilterChanged('new'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Тренды',
                    isSelected: selectedFilter == 'trending',
                    onSelected: () => onFilterChanged('trending'),
                  ),
                ],
              ),
            ),
          ),

          // Сортировка
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: onSortChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'newest',
                child: Text('Новые'),
              ),
              const PopupMenuItem(
                value: 'oldest',
                child: Text('Старые'),
              ),
              const PopupMenuItem(
                value: 'popular',
                child: Text('Популярные'),
              ),
              const PopupMenuItem(
                value: 'trending',
                child: Text('Тренды'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Чип фильтра
class _FilterChip extends StatelessWidget {

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }
}
