import 'package:flutter/material.dart';

/// Виджет сортировки специалистов
class SpecialistsSortWidget extends StatelessWidget {
  const SpecialistsSortWidget({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

  final String selectedSort;
  final ValueChanged<String> onSortChanged;

  static const List<String> sortOptions = [
    'Рейтинг',
    'Цена (по возрастанию)',
    'Цена (по убыванию)',
    'Популярность',
    'Дата регистрации',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sort,
            size: 20,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Text(
            'Сортировка:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedSort,
                isDense: true,
                items: sortOptions.map((option) => DropdownMenuItem(
                    value: option,
                    child: Text(
                      option,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onSortChanged(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
