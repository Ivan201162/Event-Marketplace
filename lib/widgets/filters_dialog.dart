import 'package:flutter/material.dart';

/// Модальное окно с фильтрами поиска специалистов
class FiltersDialog extends StatefulWidget {
  const FiltersDialog({
    super.key,
    this.initialFilters,
    this.onApplyFilters,
  });

  final Map<String, dynamic>? initialFilters;
  final Function(Map<String, dynamic>)? onApplyFilters;

  @override
  State<FiltersDialog> createState() => _FiltersDialogState();
}

class _FiltersDialogState extends State<FiltersDialog> {
  String? _selectedCity;
  String? _selectedCategory;
  double _minRating = 0.0;
  double _maxRating = 5.0;
  String? _specialistType;
  RangeValues _priceRange = const RangeValues(0, 100000);

  final List<String> _cities = [
    'Москва',
    'Санкт-Петербург',
    'Казань',
    'Екатеринбург',
    'Новосибирск',
    'Краснодар',
    'Нижний Новгород',
    'Челябинск',
    'Самара',
    'Омск',
  ];

  final List<String> _categories = [
    'Фотограф',
    'Видеограф',
    'DJ',
    'Ведущий',
    'Декоратор',
    'Флорист',
    'Аниматор',
    'Кейтеринг',
    'Звукорежиссер',
    'Осветитель',
  ];

  final List<String> _specialistTypes = [
    'Любой',
    'Физическое лицо',
    'Студия/Агентство',
    'Частный специалист',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialFilters != null) {
      _selectedCity = widget.initialFilters!['city'];
      _selectedCategory = widget.initialFilters!['category'];
      _minRating = widget.initialFilters!['minRating'] ?? 0.0;
      _maxRating = widget.initialFilters!['maxRating'] ?? 5.0;
      _specialistType = widget.initialFilters!['specialistType'];
      _priceRange = RangeValues(
        widget.initialFilters!['minPrice']?.toDouble() ?? 0.0,
        widget.initialFilters!['maxPrice']?.toDouble() ?? 100000.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.tune,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Фильтры поиска',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
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
                    // Город
                    _buildSectionTitle('📍 Город'),
                    _buildDropdown(
                      value: _selectedCity,
                      items: _cities,
                      hint: 'Выберите город',
                      onChanged: (value) {
                        setState(() {
                          _selectedCity = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Категория
                    _buildSectionTitle('🧰 Категория'),
                    _buildDropdown(
                      value: _selectedCategory,
                      items: _categories,
                      hint: 'Выберите категорию',
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Рейтинг
                    _buildSectionTitle('⭐ Рейтинг'),
                    Row(
                      children: [
                        Expanded(
                          child: Text('От: ${_minRating.toStringAsFixed(1)}'),
                        ),
                        Expanded(
                          flex: 2,
                          child: RangeSlider(
                            values: RangeValues(_minRating, _maxRating),
                            min: 0.0,
                            max: 5.0,
                            divisions: 50,
                            onChanged: (values) {
                              setState(() {
                                _minRating = values.start;
                                _maxRating = values.end;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: Text('До: ${_maxRating.toStringAsFixed(1)}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Тип специалиста
                    _buildSectionTitle('👤 Тип специалиста'),
                    _buildDropdown(
                      value: _specialistType,
                      items: _specialistTypes,
                      hint: 'Выберите тип',
                      onChanged: (value) {
                        setState(() {
                          _specialistType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Ценовой диапазон
                    _buildSectionTitle('💰 Ценовой диапазон'),
                    Text(
                      'От ${_priceRange.start.round()} до ${_priceRange.end.round()} ₽',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 100000,
                      divisions: 100,
                      onChanged: (values) {
                        setState(() {
                          _priceRange = values;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Кнопки
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearFilters,
                      child: const Text('Сбросить'),
                    ),
                  ),
                  const SizedBox(width: 12),
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCity = null;
      _selectedCategory = null;
      _minRating = 0.0;
      _maxRating = 5.0;
      _specialistType = null;
      _priceRange = const RangeValues(0, 100000);
    });
  }

  void _applyFilters() {
    final filters = {
      'city': _selectedCity,
      'category': _selectedCategory,
      'minRating': _minRating,
      'maxRating': _maxRating,
      'specialistType': _specialistType,
      'minPrice': _priceRange.start,
      'maxPrice': _priceRange.end,
    };

    widget.onApplyFilters?.call(filters);
    Navigator.of(context).pop();
  }
}

