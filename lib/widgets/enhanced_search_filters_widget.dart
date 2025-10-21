import 'package:flutter/material.dart';

import '../models/common_types.dart';

/// Улучшенный виджет фильтров поиска
class EnhancedSearchFiltersWidget extends StatefulWidget {
  const EnhancedSearchFiltersWidget({
    super.key,
    required this.onFiltersChanged,
    this.initialFilters,
  });

  final Function(SearchFilters) onFiltersChanged;
  final SearchFilters? initialFilters;

  @override
  State<EnhancedSearchFiltersWidget> createState() => _EnhancedSearchFiltersWidgetState();
}

class _EnhancedSearchFiltersWidgetState extends State<EnhancedSearchFiltersWidget> {
  late SearchFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters ?? const SearchFilters();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      border: Border(
        top: BorderSide(color: Colors.grey[300]!),
        bottom: BorderSide(color: Colors.grey[300]!),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Фильтры',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: _clearFilters, child: const Text('Сбросить')),
          ],
        ),
        const SizedBox(height: 16),

        // Категории
        _buildCategoryFilter(),

        const SizedBox(height: 16),

        // Цена
        _buildPriceFilter(),

        const SizedBox(height: 16),

        // Рейтинг
        _buildRatingFilter(),

        const SizedBox(height: 16),

        // Опыт
        _buildExperienceFilter(),

        const SizedBox(height: 16),

        // Локация
        _buildLocationFilter(),

        const SizedBox(height: 16),

        // Дата
        _buildDateFilter(),

        const SizedBox(height: 16),

        // Сортировка
        _buildSortingFilter(),
      ],
    ),
  );

  Widget _buildCategoryFilter() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Категория', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      DropdownButtonFormField<SpecialistCategory?>(
        initialValue: _filters.category,
        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
        hint: const Text('Все категории'),
        items: [
          const DropdownMenuItem<SpecialistCategory?>(child: Text('Все категории')),
          ...SpecialistCategory.values.map(
            (category) => DropdownMenuItem<SpecialistCategory?>(
              value: category,
              child: Row(
                children: [
                  Text(category.icon),
                  const SizedBox(width: 8),
                  Text(category.displayName),
                ],
              ),
            ),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _filters = _filters.copyWith(category: value);
          });
          widget.onFiltersChanged(_filters);
        },
      ),
    ],
  );

  Widget _buildPriceFilter() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Цена за час', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: _filters.minPrice > 0 ? _filters.minPrice.toInt().toString() : '',
              decoration: const InputDecoration(
                labelText: 'От',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final minPrice = double.tryParse(value) ?? 0;
                setState(() {
                  _filters = _filters.copyWith(minPrice: minPrice);
                });
                widget.onFiltersChanged(_filters);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              initialValue: _filters.maxPrice < 10000 ? _filters.maxPrice.toInt().toString() : '',
              decoration: const InputDecoration(
                labelText: 'До',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final maxPrice = double.tryParse(value) ?? 10000;
                setState(() {
                  _filters = _filters.copyWith(maxPrice: maxPrice);
                });
                widget.onFiltersChanged(_filters);
              },
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildRatingFilter() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Минимальный рейтинг', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      Row(
        children: List.generate(
          5,
          (index) => IconButton(
            icon: Icon(
              Icons.star,
              color: index < _filters.minRating ? Colors.amber : Colors.grey[300],
            ),
            onPressed: () {
              setState(() {
                _filters = _filters.copyWith(minRating: index + 1.0);
              });
              widget.onFiltersChanged(_filters);
            },
          ),
        ),
      ),
    ],
  );

  Widget _buildExperienceFilter() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Уровень опыта', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: ExperienceLevel.values
            .map(
              (level) => FilterChip(
                label: Text(level.displayName),
                selected: _filters.experienceLevel == level,
                onSelected: (selected) {
                  setState(() {
                    _filters = _filters.copyWith(experienceLevel: selected ? level : null);
                  });
                  widget.onFiltersChanged(_filters);
                },
              ),
            )
            .toList(),
      ),
    ],
  );

  Widget _buildLocationFilter() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Город', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      TextFormField(
        initialValue: _filters.location,
        decoration: const InputDecoration(
          hintText: 'Введите город',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (value) {
          setState(() {
            _filters = _filters.copyWith(location: value.isEmpty ? null : value);
          });
          widget.onFiltersChanged(_filters);
        },
      ),
    ],
  );

  Widget _buildDateFilter() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Доступная дата', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      InkWell(
        onTap: _selectDate,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today),
              const SizedBox(width: 8),
              Text(
                _filters.availableDate != null
                    ? '${_filters.availableDate!.day}.${_filters.availableDate!.month}.${_filters.availableDate!.year}'
                    : 'Выберите дату',
              ),
              if (_filters.availableDate != null) ...[
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _filters = _filters.copyWith();
                    });
                    widget.onFiltersChanged(_filters);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    ],
  );

  Widget _buildSortingFilter() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Сортировка', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      DropdownButtonFormField<SpecialistSorting>(
        initialValue: _filters.sorting,
        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
        items: SpecialistSorting.values
            .map(
              (sorting) => DropdownMenuItem<SpecialistSorting>(
                value: sorting,
                child: Text(sorting.displayName),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _filters = _filters.copyWith(sorting: value);
            });
            widget.onFiltersChanged(_filters);
          }
        },
      ),
    ],
  );

  void _clearFilters() {
    setState(() {
      _filters = const SearchFilters();
    });
    widget.onFiltersChanged(_filters);
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _filters.availableDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _filters = _filters.copyWith(availableDate: date);
      });
      widget.onFiltersChanged(_filters);
    }
  }
}

/// Модель фильтров поиска
class SearchFilters {
  const SearchFilters({
    this.category,
    this.minPrice = 0,
    this.maxPrice = 10000,
    this.minRating = 0,
    this.experienceLevel,
    this.location,
    this.availableDate,
    this.sorting = SpecialistSorting.rating,
  });

  final SpecialistCategory? category;
  final double minPrice;
  final double maxPrice;
  final double minRating;
  final ExperienceLevel? experienceLevel;
  final String? location;
  final DateTime? availableDate;
  final SpecialistSorting sorting;

  SearchFilters copyWith({
    SpecialistCategory? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    ExperienceLevel? experienceLevel,
    String? location,
    DateTime? availableDate,
    SpecialistSorting? sorting,
  }) => SearchFilters(
    category: category ?? this.category,
    minPrice: minPrice ?? this.minPrice,
    maxPrice: maxPrice ?? this.maxPrice,
    minRating: minRating ?? this.minRating,
    experienceLevel: experienceLevel ?? this.experienceLevel,
    location: location ?? this.location,
    availableDate: availableDate ?? this.availableDate,
    sorting: sorting ?? this.sorting,
  );

  bool get hasActiveFilters =>
      category != null ||
      minPrice > 0 ||
      maxPrice < 10000 ||
      minRating > 0 ||
      experienceLevel != null ||
      location != null ||
      availableDate != null;
}

/// Типы сортировки специалистов
enum SpecialistSorting { rating, priceAsc, priceDesc, experience, reviews }

extension SpecialistSortingExtension on SpecialistSorting {
  String get displayName {
    switch (this) {
      case SpecialistSorting.rating:
        return 'По рейтингу';
      case SpecialistSorting.priceAsc:
        return 'По цене (возрастание)';
      case SpecialistSorting.priceDesc:
        return 'По цене (убывание)';
      case SpecialistSorting.experience:
        return 'По опыту';
      case SpecialistSorting.reviews:
        return 'По количеству отзывов';
    }
  }
}
