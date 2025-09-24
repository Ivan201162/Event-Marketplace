import 'package:flutter/material.dart';

import '../models/event_idea.dart';

/// Виджет фильтрации идей по категориям
class IdeaFilterChip extends StatelessWidget {
  const IdeaFilterChip({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final EventIdeaCategory? selectedCategory;
  final void Function(EventIdeaCategory?) onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Кнопка "Все"
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Все'),
              selected: selectedCategory == null,
              onSelected: (selected) {
                onCategorySelected(null);
              },
              selectedColor: theme.colorScheme.primaryContainer,
              checkmarkColor: theme.colorScheme.onPrimaryContainer,
              labelStyle: TextStyle(
                color: selectedCategory == null
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
                fontWeight: selectedCategory == null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),

          // Категории
          ...EventIdeaCategory.values.map((category) {
            final isSelected = selectedCategory == category;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Text(category.displayName),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  onCategorySelected(selected ? category : null);
                },
                selectedColor: theme.colorScheme.primaryContainer,
                checkmarkColor: theme.colorScheme.onPrimaryContainer,
                labelStyle: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
