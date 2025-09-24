import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_idea.dart';
import '../providers/event_ideas_providers.dart';

/// Нижний лист с фильтрами для идей
class IdeasFilterBottomSheet extends ConsumerStatefulWidget {
  const IdeasFilterBottomSheet({super.key});

  @override
  ConsumerState<IdeasFilterBottomSheet> createState() => _IdeasFilterBottomSheetState();
}

class _IdeasFilterBottomSheetState extends ConsumerState<IdeasFilterBottomSheet> {
  EventIdeaType? _selectedType;
  IdeasSortBy _selectedSort = IdeasSortBy.newest;
  RangeValues _budgetRange = const RangeValues(0, 1000000);
  RangeValues _guestsRange = const RangeValues(0, 1000);
  final List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentFilters();
  }

  void _loadCurrentFilters() {
    final filters = ref.read(ideasFiltersProvider);
    setState(() {
      _selectedType = filters.type;
      _selectedSort = filters.sortBy;
      _selectedTags.clear();
      _selectedTags.addAll(filters.tags);
      
      if (filters.minBudget != null && filters.maxBudget != null) {
        _budgetRange = RangeValues(
          filters.minBudget!.toDouble(),
          filters.maxBudget!.toDouble(),
        );
      }
      
      if (filters.minGuests != null && filters.maxGuests != null) {
        _guestsRange = RangeValues(
          filters.minGuests!.toDouble(),
          filters.maxGuests!.toDouble(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Фильтры',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Очистить все'),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Контент
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTypeFilter(theme),
                  const SizedBox(height: 24),
                  _buildSortFilter(theme),
                  const SizedBox(height: 24),
                  _buildBudgetFilter(theme),
                  const SizedBox(height: 24),
                  _buildGuestsFilter(theme),
                  const SizedBox(height: 24),
                  _buildTagsFilter(theme),
                  const SizedBox(height: 100), // Отступ для кнопок
                ],
              ),
            ),
          ),
          
          // Кнопки действий
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
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
                    onPressed: _applyFilters,
                    child: const Text('Применить'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Фильтр по типу мероприятия
  Widget _buildTypeFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Тип мероприятия',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EventIdeaType.values.map((type) {
            final isSelected = _selectedType == type;
            return FilterChip(
              label: Text(type.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedType = selected ? type : null;
                });
              },
              selectedColor: theme.primaryColor.withOpacity(0.2),
              checkmarkColor: theme.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Фильтр сортировки
  Widget _buildSortFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Сортировка',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...IdeasSortBy.values.map((sort) {
          final isSelected = _selectedSort == sort;
          return RadioListTile<IdeasSortBy>(
            title: Text(sort.displayName),
            value: sort,
            groupValue: _selectedSort,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedSort = value;
                });
              }
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          );
        }).toList(),
      ],
    );
  }

  /// Фильтр бюджета
  Widget _buildBudgetFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Бюджет',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        RangeSlider(
          values: _budgetRange,
          min: 0,
          max: 1000000,
          divisions: 20,
          labels: RangeLabels(
            '${_formatBudget(_budgetRange.start)}',
            '${_formatBudget(_budgetRange.end)}',
          ),
          onChanged: (values) {
            setState(() {
              _budgetRange = values;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'От ${_formatBudget(_budgetRange.start)}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'До ${_formatBudget(_budgetRange.end)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  /// Фильтр количества гостей
  Widget _buildGuestsFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Количество гостей',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        RangeSlider(
          values: _guestsRange,
          min: 0,
          max: 1000,
          divisions: 20,
          labels: RangeLabels(
            '${_guestsRange.start.round()}',
            '${_guestsRange.end.round()}',
          ),
          onChanged: (values) {
            setState(() {
              _guestsRange = values;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'От ${_guestsRange.start.round()}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'До ${_guestsRange.end.round()}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  /// Фильтр тегов
  Widget _buildTagsFilter(ThemeData theme) {
    // Популярные теги (в реальном приложении получать из провайдера)
    const popularTags = [
      'свадьба',
      'день рождения',
      'корпоратив',
      'выпускной',
      'романтично',
      'элегантно',
      'весело',
      'стильно',
      'современно',
      'классика',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Популярные теги',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: popularTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text('#$tag'),
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
              selectedColor: theme.primaryColor.withOpacity(0.2),
              checkmarkColor: theme.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Форматировать бюджет
  String _formatBudget(double value) {
    if (value < 1000) return '${value.round()} ₽';
    if (value < 1000000) return '${(value / 1000).toStringAsFixed(0)}K ₽';
    return '${(value / 1000000).toStringAsFixed(1)}M ₽';
  }

  /// Очистить все фильтры
  void _clearAllFilters() {
    setState(() {
      _selectedType = null;
      _selectedSort = IdeasSortBy.newest;
      _selectedTags.clear();
      _budgetRange = const RangeValues(0, 1000000);
      _guestsRange = const RangeValues(0, 1000);
    });
  }

  /// Применить фильтры
  void _applyFilters() {
    final filtersNotifier = ref.read(ideasFiltersProvider.notifier);
    
    filtersNotifier.updateType(_selectedType);
    filtersNotifier.updateTags(_selectedTags);
    filtersNotifier.updateSortBy(_selectedSort);
    
    // Применяем диапазоны только если они не равны начальным значениям
    if (_budgetRange.start > 0 || _budgetRange.end < 1000000) {
      filtersNotifier.updateBudget(
        _budgetRange.start.round(),
        _budgetRange.end.round(),
      );
    } else {
      filtersNotifier.updateBudget(null, null);
    }
    
    if (_guestsRange.start > 0 || _guestsRange.end < 1000) {
      filtersNotifier.updateGuests(
        _guestsRange.start.round(),
        _guestsRange.end.round(),
      );
    } else {
      filtersNotifier.updateGuests(null, null);
    }
    
    Navigator.of(context).pop();
  }
}
