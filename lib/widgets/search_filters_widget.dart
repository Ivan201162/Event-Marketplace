import 'package:flutter/material.dart';

class SearchFiltersWidget extends StatefulWidget {
  final Map<String, dynamic> initialFilters;
  final Function(Map<String, dynamic>) onApplyFilters;

  const SearchFiltersWidget({
    super.key,
    required this.initialFilters,
    required this.onApplyFilters,
  });

  @override
  State<SearchFiltersWidget> createState() => _SearchFiltersWidgetState();
}

class _SearchFiltersWidgetState extends State<SearchFiltersWidget> {
  String _selectedCity = '';
  String _selectedCategory = '';
  RangeValues _priceRange = const RangeValues(0, 100000);
  String _selectedType = 'Физлицо';
  String _selectedSort = 'Рейтинг';

  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  final List<String> _cities = [
    'Москва',
    'Санкт-Петербург',
    'Казань',
    'Екатеринбург',
    'Новосибирск',
    'Нижний Новгород',
    'Самара',
    'Омск',
    'Ростов-на-Дону',
    'Уфа',
  ];

  final List<String> _categories = [
    'Ведущие',
    'DJ',
    'Фотографы',
    'Видеографы',
    'Декораторы',
    'Аниматоры',
    'Организатор мероприятий',
    'Музыканты',
    'Танцоры',
    'Кейтеринг',
  ];

  final List<String> _types = [
    'Физлицо',
    'Самозанятый',
    'ИП',
    'Студия(агентство)',
  ];

  final List<String> _sortOptions = [
    'Рейтинг',
    'Цена',
    'Популярность',
    'Дата регистрации',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialFilters['city'] ?? '';
    _selectedCategory = widget.initialFilters['category'] ?? '';
    _priceRange = widget.initialFilters['priceRange'] ?? const RangeValues(0, 100000);
    _selectedType = widget.initialFilters['type'] ?? 'Физлицо';
    _selectedSort = widget.initialFilters['sort'] ?? 'Рейтинг';

    _minPriceController.text = _priceRange.start.round().toString();
    _maxPriceController.text = _priceRange.end.round().toString();
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedCity = '';
      _selectedCategory = '';
      _priceRange = const RangeValues(0, 100000);
      _selectedType = 'Физлицо';
      _selectedSort = 'Рейтинг';
      _minPriceController.text = '0';
      _maxPriceController.text = '100000';
    });
  }

  void _applyFilters() {
    widget.onApplyFilters({
      'city': _selectedCity,
      'category': _selectedCategory,
      'priceRange': _priceRange,
      'type': _selectedType,
      'sort': _selectedSort,
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Фильтры поиска',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                // Город
                Text(
                  'Город',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCity.isEmpty ? null : _selectedCity,
                  decoration: const InputDecoration(
                    hintText: 'Выберите город',
                    border: OutlineInputBorder(),
                  ),
                  items: _cities
                      .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Категория
                Text(
                  'Категория',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory.isEmpty ? null : _selectedCategory,
                  decoration: const InputDecoration(
                    hintText: 'Выберите категорию',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map((category) =>
                          DropdownMenuItem(value: category, child: Text(category)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Цена от/до
                Text(
                  'Цена от/до',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'От',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _priceRange = RangeValues(
                              double.tryParse(value) ?? 0,
                              _priceRange.end,
                            );
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _maxPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'До',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _priceRange = RangeValues(
                              _priceRange.start,
                              double.tryParse(value) ?? 100000,
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 100000,
                  divisions: 100,
                  labels: RangeLabels(
                    _priceRange.start.round().toString(),
                    _priceRange.end.round().toString(),
                  ),
                  onChanged: (values) {
                    setState(() {
                      _priceRange = values;
                      _minPriceController.text = values.start.round().toString();
                      _maxPriceController.text = values.end.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Тип
                Text(
                  'Тип',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: _types
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value ?? 'Физлицо';
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Сортировка
                Text(
                  'Сортировка',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSort,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: _sortOptions
                      .map((sort) => DropdownMenuItem(value: sort, child: Text(sort)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSort = value ?? 'Рейтинг';
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetFilters,
                  child: const Text('Сбросить'),
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
        ],
      ),
    );
  }
}
