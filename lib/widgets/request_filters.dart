import 'package:flutter/material.dart';

/// Виджет фильтров для заявок
class RequestFilters extends StatelessWidget {
  final String selectedFilter;
  final String selectedSort;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSortChanged;

  const RequestFilters({
    super.key,
    required this.selectedFilter,
    required this.selectedSort,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Фильтры по статусу
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
                    label: 'Открытые',
                    isSelected: selectedFilter == 'open',
                    onSelected: () => onFilterChanged('open'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'В работе',
                    isSelected: selectedFilter == 'in_progress',
                    onSelected: () => onFilterChanged('in_progress'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Завершённые',
                    isSelected: selectedFilter == 'done',
                    onSelected: () => onFilterChanged('done'),
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
                value: 'budget_high',
                child: Text('Бюджет: высокий'),
              ),
              const PopupMenuItem(
                value: 'budget_low',
                child: Text('Бюджет: низкий'),
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
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

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
