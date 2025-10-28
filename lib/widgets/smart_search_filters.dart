import 'package:event_marketplace_app/models/common_types.dart';
import 'package:flutter/material.dart';

// Временное определение для совместимости
enum SpecialistSortOption {
  rating,
  price,
  experience,
  reviews,
  name,
  dateAdded
}

extension SpecialistSortOptionExtension on SpecialistSortOption {
  String get label {
    switch (this) {
      case SpecialistSortOption.rating:
        return 'По рейтингу';
      case SpecialistSortOption.price:
        return 'По цене';
      case SpecialistSortOption.experience:
        return 'По опыту';
      case SpecialistSortOption.reviews:
        return 'По отзывам';
      case SpecialistSortOption.name:
        return 'По имени';
      case SpecialistSortOption.dateAdded:
        return 'По дате добавления';
    }
  }
}

/// Виджет фильтров для умного поиска
class SmartSearchFilters extends StatefulWidget {
  const SmartSearchFilters({
    required this.selectedCategory, required this.selectedCity, required this.minPrice, required this.maxPrice, required this.selectedDate, required this.selectedStyles, required this.selectedSort, required this.onCategoryChanged, required this.onCityChanged, required this.onPriceChanged, required this.onDateChanged, required this.onStylesChanged, required this.onSortChanged, super.key,
  });

  final SpecialistCategory? selectedCategory;
  final String? selectedCity;
  final double minPrice;
  final double maxPrice;
  final DateTime? selectedDate;
  final List<String> selectedStyles;
  final SpecialistSortOption? selectedSort;
  final ValueChanged<SpecialistCategory?> onCategoryChanged;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged2<double, double> onPriceChanged;
  final ValueChanged<DateTime?> onDateChanged;
  final ValueChanged<List<String>> onStylesChanged;
  final ValueChanged<SpecialistSortOption?> onSortChanged;

  @override
  State<SmartSearchFilters> createState() => _SmartSearchFiltersState();
}

class _SmartSearchFiltersState extends State<SmartSearchFilters> {
  final List<String> _availableStyles = [
    'классика',
    'современный',
    'юмор',
    'интерактив',
    'романтичный',
    'официальный',
    'креативный',
    'элегантный',
  ];

  final List<String> _availableCities = [
    'Москва',
    'Санкт-Петербург',
    'Екатеринбург',
    'Новосибирск',
    'Казань',
    'Нижний Новгород',
    'Челябинск',
    'Самара',
    'Омск',
    'Ростов-на-Дону',
  ];

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Фильтры',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                TextButton(
                    onPressed: _clearAllFilters, child: const Text('Сбросить'),),
              ],
            ),

            const SizedBox(height: 16),

            // Категория
            _buildCategoryFilter(),

            const SizedBox(height: 16),

            // Город
            _buildCityFilter(),

            const SizedBox(height: 16),

            // Бюджет
            _buildBudgetFilter(),

            const SizedBox(height: 16),

            // Дата
            _buildDateFilter(),

            const SizedBox(height: 16),

            // Стили
            _buildStylesFilter(),

            const SizedBox(height: 16),

            // Сортировка
            _buildSortFilter(),
          ],
        ),
      );

  /// Фильтр по категории
  Widget _buildCategoryFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Категория',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: 'Все',
                selected: widget.selectedCategory == null,
                onSelected: (selected) {
                  if (selected) {
                    widget.onCategoryChanged(null);
                  }
                },
              ),
              ...SpecialistCategory.values.map(
                (category) => _buildFilterChip(
                  label: category.displayName,
                  selected: widget.selectedCategory == category,
                  onSelected: (selected) {
                    if (selected) {
                      widget.onCategoryChanged(category);
                    } else {
                      widget.onCategoryChanged(null);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      );

  /// Фильтр по городу
  Widget _buildCityFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Город',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: widget.selectedCity,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text('Выберите город'),
            items: [
              const DropdownMenuItem<String>(child: Text('Все города')),
              ..._availableCities.map(
                (city) =>
                    DropdownMenuItem<String>(value: city, child: Text(city)),
              ),
            ],
            onChanged: widget.onCityChanged,
          ),
        ],
      );

  /// Фильтр по бюджету
  Widget _buildBudgetFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Бюджет',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'От ${widget.minPrice.toStringAsFixed(0)} ₽',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Expanded(
                child: Text(
                  'До ${widget.maxPrice.toStringAsFixed(0)} ₽',
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: RangeValues(widget.minPrice, widget.maxPrice),
            max: 100000,
            divisions: 20,
            labels: RangeLabels(
              '${widget.minPrice.toStringAsFixed(0)} ₽',
              '${widget.maxPrice.toStringAsFixed(0)} ₽',
            ),
            onChanged: (values) {
              widget.onPriceChanged(values.start, values.end);
            },
          ),
        ],
      );

  /// Фильтр по дате
  Widget _buildDateFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Дата мероприятия',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.selectedDate != null
                        ? '${widget.selectedDate!.day}.${widget.selectedDate!.month}.${widget.selectedDate!.year}'
                        : 'Выберите дату',
                    style: TextStyle(
                        color: widget.selectedDate != null
                            ? Colors.black
                            : Colors.grey,),
                  ),
                  const Spacer(),
                  if (widget.selectedDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => widget.onDateChanged(null),
                    ),
                ],
              ),
            ),
          ),
        ],
      );

  /// Фильтр по стилям
  Widget _buildStylesFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Стиль мероприятия',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableStyles
                .map(
                  (style) => _buildFilterChip(
                    label: style,
                    selected: widget.selectedStyles.contains(style),
                    onSelected: (selected) {
                      final newStyles =
                          List<String>.from(widget.selectedStyles);
                      if (selected) {
                        newStyles.add(style);
                      } else {
                        newStyles.remove(style);
                      }
                      widget.onStylesChanged(newStyles);
                    },
                  ),
                )
                .toList(),
          ),
        ],
      );

  /// Фильтр сортировки
  Widget _buildSortFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Сортировка',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),),
          const SizedBox(height: 8),
          DropdownButtonFormField<SpecialistSortOption>(
            initialValue: widget.selectedSort,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text('Выберите сортировку'),
            items: [
              const DropdownMenuItem<SpecialistSortOption>(
                  child: Text('По умолчанию'),),
              ...SpecialistSortOption.values.map(
                (sort) => DropdownMenuItem<SpecialistSortOption>(
                    value: sort, child: Text(sort.label),),
              ),
            ],
            onChanged: widget.onSortChanged,
          ),
        ],
      );

  /// Чип фильтра
  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) =>
      FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      );

  /// Выбрать дату
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      widget.onDateChanged(date);
    }
  }

  /// Очистить все фильтры
  void _clearAllFilters() {
    widget.onCategoryChanged(null);
    widget.onCityChanged(null);
    widget.onPriceChanged(0, 100000);
    widget.onDateChanged(null);
    widget.onStylesChanged([]);
    widget.onSortChanged(null);
  }
}

/// Тип для функции с двумя параметрами
typedef ValueChanged2<T1, T2> = void Function(T1 value1, T2 value2);
