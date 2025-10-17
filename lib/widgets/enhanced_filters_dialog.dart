import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EnhancedFiltersDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> initialFilters;
  final Function(Map<String, dynamic>) onApplyFilters;

  const EnhancedFiltersDialog({
    super.key,
    required this.initialFilters,
    required this.onApplyFilters,
  });

  @override
  ConsumerState<EnhancedFiltersDialog> createState() => _EnhancedFiltersDialogState();
}

class _EnhancedFiltersDialogState extends ConsumerState<EnhancedFiltersDialog> {
  late Map<String, dynamic> _filters;

  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  String? _selectedCategory;
  String? _selectedSpecialistType;

  final List<String> _categories = [
    'Все',
    'Свадьбы',
    'Корпоративы',
    'Дни рождения',
    'Детские праздники',
    'Выпускные',
    'Фотографы',
    'Видеографы',
    'DJ',
    'Ведущие',
    'Декораторы',
    'Аниматоры',
    'Организатор мероприятий',
  ];

  final List<String> _specialistTypes = [
    'Все',
    'В студии/агентстве',
    'Самозанятый',
    'ИП',
  ];

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.initialFilters);
    _initializeFilters();
  }

  void _initializeFilters() {
    _cityController.text = _filters['city'] ?? '';
    _minPriceController.text = _filters['minPrice']?.toString() ?? '';
    _maxPriceController.text = _filters['maxPrice']?.toString() ?? '';
    _selectedCategory = _filters['category'];
    _selectedSpecialistType = _filters['specialistType'];
  }

  @override
  void dispose() {
    _cityController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Фильтры поиска',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Содержимое
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCityFilter(),
                    const SizedBox(height: 20),
                    _buildCategoryFilter(),
                    const SizedBox(height: 20),
                    _buildPriceFilter(),
                    const SizedBox(height: 20),
                    _buildSpecialistTypeFilter(),
                  ],
                ),
              ),
            ),

            // Кнопки
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetFilters,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Сбросить'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Применить фильтры'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Город',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cityController,
          decoration: InputDecoration(
            hintText: 'Введите город',
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          onChanged: (value) {
            _filters['city'] = value.trim().isEmpty ? null : value.trim();
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['Москва', 'Санкт-Петербург', 'Казань', 'Екатеринбург']
              .map((city) => _buildCityChip(city))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCityChip(String city) {
    final isSelected = _cityController.text == city;
    return FilterChip(
      label: Text(city),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _cityController.text = selected ? city : '';
          _filters['city'] = selected ? city : null;
        });
      },
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Категория',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          decoration: InputDecoration(
            hintText: 'Выберите категорию',
            prefixIcon: const Icon(Icons.category),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(
              value: category == 'Все' ? null : category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
              _filters['category'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Цена (₽)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'От',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) {
                  final price = int.tryParse(value);
                  _filters['minPrice'] = price;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'До',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) {
                  final price = int.tryParse(value);
                  _filters['maxPrice'] = price;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecialistTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Тип специалиста',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedSpecialistType,
          decoration: InputDecoration(
            hintText: 'Выберите тип',
            prefixIcon: const Icon(Icons.business),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: _specialistTypes.map((type) {
            return DropdownMenuItem(
              value: type == 'Все' ? null : type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSpecialistType = value;
              _filters['specialistType'] = value;
            });
          },
        ),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _filters.clear();
      _cityController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedCategory = null;
      _selectedSpecialistType = null;
    });
  }

  void _applyFilters() {
    // Убираем пустые значения
    _filters.removeWhere((key, value) => value == null || value == '');
    widget.onApplyFilters(_filters);
    Navigator.of(context).pop();
  }
}
