import 'package:flutter/material.dart';

/// Виджет фильтров специалистов
class SpecialistsFiltersWidget extends StatelessWidget {
  const SpecialistsFiltersWidget({
    super.key,
    required this.selectedCategory,
    required this.selectedCity,
    required this.minPrice,
    required this.maxPrice,
    required this.onCategoryChanged,
    required this.onCityChanged,
    required this.onPriceRangeChanged,
  });

  final String selectedCategory;
  final String selectedCity;
  final double minPrice;
  final double maxPrice;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onCityChanged;
  final void Function(double, double) onPriceRangeChanged;

  static const List<String> categories = [
    'Все',
    'Фотографы',
    'Видеографы',
    'Организаторы',
    'Декораторы',
    'Музыканты',
    'Аниматоры',
    'Кейтеринг',
    'Транспорт',
  ];

  static const List<String> cities = [
    'Все города',
    'Москва',
    'Санкт-Петербург',
    'Новосибирск',
    'Екатеринбург',
    'Казань',
    'Нижний Новгород',
    'Челябинск',
    'Самара',
    'Омск',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Категории
          Text(
            'Категория',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: categories.map((category) {
              final isSelected = category == selectedCategory;
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onCategoryChanged(category);
                  }
                },
                selectedColor: theme.primaryColor.withValues(alpha: 0.2),
                checkmarkColor: theme.primaryColor,
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Города
          Text(
            'Город',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedCity,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: cities
                .map(
                  (city) => DropdownMenuItem(
                    value: city,
                    child: Text(city),
                  ),
                )
                .toList(),
            onChanged: (city) {
              if (city != null) {
                onCityChanged(city);
              }
            },
          ),

          const SizedBox(height: 16),

          // Диапазон цен
          Text(
            'Диапазон цен',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: minPrice.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'От',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    final price = double.tryParse(value) ?? 0;
                    onPriceRangeChanged(price, maxPrice);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: maxPrice.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'До',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    final price = double.tryParse(value) ?? 100000;
                    onPriceRangeChanged(minPrice, price);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
