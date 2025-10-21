import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/specialist_categories.dart';
import '../models/specialist_filters.dart';

/// Bottom Sheet с фильтрами для специалистов
class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.onFiltersChanged,
    required this.categoryId,
  });
  final SpecialistFilters initialFilters;
  final Function(SpecialistFilters) onFiltersChanged;
  final String categoryId;

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late SpecialistFilters _currentFilters;
  late RangeValues _priceRangeValues;
  late RangeValues _ratingRangeValues;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.initialFilters;
    _priceRangeValues = RangeValues(
      _currentFilters.minPrice ?? 0,
      _currentFilters.maxPrice ?? 100000,
    );
    _ratingRangeValues = RangeValues(
      _currentFilters.minRating ?? 1,
      _currentFilters.maxRating ?? 5,
    );
    _searchController.text = _currentFilters.searchQuery ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    widget.onFiltersChanged(_currentFilters);
  }

  void _resetFilters() {
    setState(() {
      _currentFilters = const SpecialistFilters();
      _priceRangeValues = const RangeValues(0, 100000);
      _ratingRangeValues = const RangeValues(1, 5);
      _searchController.clear();
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = SpecialistCategoryInfo.getById(widget.categoryId);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                if (category != null) ...[
                  Text(category.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Фильтры',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (category != null)
                        Text(
                          category.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Содержимое фильтров
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Поиск
                  _buildSearchSection(theme),
                  const SizedBox(height: 24),

                  // Фильтр по цене
                  _buildPriceFilter(theme),
                  const SizedBox(height: 24),

                  // Фильтр по рейтингу
                  _buildRatingFilter(theme),
                  const SizedBox(height: 24),

                  // Фильтр по дате
                  _buildDateFilter(theme),
                  const SizedBox(height: 24),

                  // Фильтр по городу
                  _buildCityFilter(theme),
                  const SizedBox(height: 24),

                  // Дополнительные фильтры
                  _buildAdditionalFilters(theme),
                  const SizedBox(height: 32),

                  // Кнопки действий
                  _buildActionButtons(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Поиск', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Поиск по имени или описанию...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        onChanged: (value) {
          setState(() {
            _currentFilters = _currentFilters.copyWith(searchQuery: value.isEmpty ? null : value);
          });
        },
      ),
    ],
  );

  Widget _buildPriceFilter(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Ценовой диапазон',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        'от ${_priceRangeValues.start.toInt()} ₽ до ${_priceRangeValues.end.toInt()} ₽',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      RangeSlider(
        values: _priceRangeValues,
        max: 100000,
        divisions: 100,
        labels: RangeLabels(
          '${_priceRangeValues.start.toInt()} ₽',
          '${_priceRangeValues.end.toInt()} ₽',
        ),
        onChanged: (values) {
          setState(() {
            _priceRangeValues = values;
            _currentFilters = _currentFilters.copyWith(
              minPrice: values.start,
              maxPrice: values.end,
            );
          });
        },
      ),
      // Быстрые опции цены
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: PriceFilterOption.options.map((option) {
          final isSelected =
              _currentFilters.minPrice == option.minPrice &&
              _currentFilters.maxPrice == option.maxPrice;
          return FilterChip(
            label: Text(option.label),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _currentFilters = _currentFilters.copyWith(
                    minPrice: option.minPrice,
                    maxPrice: option.maxPrice,
                  );
                  _priceRangeValues = RangeValues(option.minPrice ?? 0, option.maxPrice ?? 100000);
                } else {
                  _currentFilters = _currentFilters.copyWith();
                  _priceRangeValues = const RangeValues(0, 100000);
                }
              });
            },
          );
        }).toList(),
      ),
    ],
  );

  Widget _buildRatingFilter(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Рейтинг', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(
        'от ${_ratingRangeValues.start.toStringAsFixed(1)} до ${_ratingRangeValues.end.toStringAsFixed(1)} звезд',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      RangeSlider(
        values: _ratingRangeValues,
        min: 1,
        max: 5,
        divisions: 8,
        labels: RangeLabels(
          _ratingRangeValues.start.toStringAsFixed(1),
          _ratingRangeValues.end.toStringAsFixed(1),
        ),
        onChanged: (values) {
          setState(() {
            _ratingRangeValues = values;
            _currentFilters = _currentFilters.copyWith(
              minRating: values.start,
              maxRating: values.end,
            );
          });
        },
      ),
      // Быстрые опции рейтинга
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: RatingFilterOption.options.map((option) {
          final isSelected = _currentFilters.minRating == option.minRating;
          return FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(option.label),
              ],
            ),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _currentFilters = _currentFilters.copyWith(minRating: option.minRating);
                  _ratingRangeValues = RangeValues(option.minRating, 5);
                } else {
                  _currentFilters = _currentFilters.copyWith();
                  _ratingRangeValues = const RangeValues(1, 5);
                }
              });
            },
          );
        }).toList(),
      ),
    ],
  );

  Widget _buildDateFilter(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Доступная дата',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      InkWell(
        onTap: () async {
          final selectedDate = await showDatePicker(
            context: context,
            initialDate: _currentFilters.availableDate ?? DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (selectedDate != null) {
            setState(() {
              _currentFilters = _currentFilters.copyWith(availableDate: selectedDate);
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _currentFilters.availableDate != null
                      ? DateFormat('dd.MM.yyyy').format(_currentFilters.availableDate!)
                      : 'Выберите дату',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              if (_currentFilters.availableDate != null)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _currentFilters = _currentFilters.copyWith();
                    });
                  },
                  icon: const Icon(Icons.clear),
                ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _buildCityFilter(ThemeData theme) {
    final cities = ['Москва', 'Санкт-Петербург', 'Новосибирск', 'Екатеринбург', 'Казань'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Город', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _currentFilters.city,
          hint: const Text('Все города'),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          items: [
            const DropdownMenuItem(child: Text('Все города')),
            ...cities.map((city) => DropdownMenuItem(value: city, child: Text(city))),
          ],
          onChanged: (value) {
            setState(() {
              _currentFilters = _currentFilters.copyWith(city: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalFilters(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Дополнительно',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      CheckboxListTile(
        title: const Text('Только верифицированные'),
        subtitle: const Text('Показать только проверенных специалистов'),
        value: _currentFilters.isVerified ?? false,
        onChanged: (value) {
          setState(() {
            _currentFilters = _currentFilters.copyWith(isVerified: value);
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
      ),
      CheckboxListTile(
        title: const Text('Только доступные'),
        subtitle: const Text('Показать только свободных специалистов'),
        value: _currentFilters.isAvailable ?? false,
        onChanged: (value) {
          setState(() {
            _currentFilters = _currentFilters.copyWith(isAvailable: value);
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
      ),
    ],
  );

  Widget _buildActionButtons(ThemeData theme) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _resetFilters,
          icon: const Icon(Icons.refresh),
          label: const Text('Сбросить'),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () {
            _applyFilters();
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.check),
          label: const Text('Применить'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
      ),
    ],
  );
}
