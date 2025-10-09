import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Виджет фильтров для поиска специалистов на главном экране
class HomeSearchFiltersWidget extends ConsumerStatefulWidget {
  const HomeSearchFiltersWidget({
    super.key,
    required this.onFiltersChanged,
  });

  final Function(Map<String, dynamic>) onFiltersChanged;

  @override
  ConsumerState<HomeSearchFiltersWidget> createState() =>
      _HomeSearchFiltersWidgetState();
}

class _HomeSearchFiltersWidgetState
    extends ConsumerState<HomeSearchFiltersWidget> {
  // Фильтры
  double _minPrice = 0;
  double _maxPrice = 10000;
  double _minRating = 0;
  String? _selectedCity;
  DateTime? _selectedDate;
  String? _selectedCategory;

  // Список городов
  final List<String> _cities = [
    'Москва',
    'Санкт-Петербург',
    'Казань',
    'Екатеринбург',
    'Новосибирск',
    'Нижний Новгород',
    'Челябинск',
    'Самара',
    'Омск',
    'Ростов-на-Дону',
  ];

  // Список категорий
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Ведущие', 'value': 'host'},
    {'name': 'DJ', 'value': 'dj'},
    {'name': 'Фотографы', 'value': 'photographer'},
    {'name': 'Видеографы', 'value': 'videographer'},
    {'name': 'Декораторы', 'value': 'decorator'},
    {'name': 'Аниматоры', 'value': 'animator'},
  ];

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с кнопкой сброса
            Row(
              children: [
                const Icon(Icons.filter_list, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Фильтры',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Сбросить'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Фильтр по цене
            _buildPriceFilter(),

            const SizedBox(height: 16),

            // Фильтр по рейтингу
            _buildRatingFilter(),

            const SizedBox(height: 16),

            // Фильтр по городу
            _buildCityFilter(),

            const SizedBox(height: 16),

            // Фильтр по категории
            _buildCategoryFilter(),

            const SizedBox(height: 16),

            // Фильтр по дате
            _buildDateFilter(),
          ],
        ),
      );

  /// Фильтр по цене
  Widget _buildPriceFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Цена: ${_minPrice.toInt()}₽ - ${_maxPrice.toInt()}₽',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            max: 10000,
            divisions: 20,
            onChanged: (values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
              _notifyFiltersChanged();
            },
          ),
        ],
      );

  /// Фильтр по рейтингу
  Widget _buildRatingFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Минимальный рейтинг: ${_minRating.toStringAsFixed(1)}⭐',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _minRating,
            max: 5,
            divisions: 10,
            onChanged: (value) {
              setState(() {
                _minRating = value;
              });
              _notifyFiltersChanged();
            },
          ),
        ],
      );

  /// Фильтр по городу
  Widget _buildCityFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Город',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedCity,
            decoration: const InputDecoration(
              hintText: 'Выберите город',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem<String>(
                child: Text('Все города'),
              ),
              ..._cities.map(
                (city) => DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCity = value;
              });
              _notifyFiltersChanged();
            },
          ),
        ],
      );

  /// Фильтр по категории
  Widget _buildCategoryFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Категория',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              hintText: 'Выберите категорию',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem<String>(
                child: Text('Все категории'),
              ),
              ..._categories.map(
                (category) => DropdownMenuItem<String>(
                  value: category['value'],
                  child: Text(category['name']),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
              _notifyFiltersChanged();
            },
          ),
        ],
      );

  /// Фильтр по дате
  Widget _buildDateFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Дата мероприятия',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
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
                    _selectedDate != null
                        ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                        : 'Выберите дату',
                    style: TextStyle(
                      color: _selectedDate != null
                          ? Colors.black
                          : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (_selectedDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                        });
                        _notifyFiltersChanged();
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      );

  /// Выбор даты
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      _notifyFiltersChanged();
    }
  }

  /// Сброс фильтров
  void _resetFilters() {
    setState(() {
      _minPrice = 0;
      _maxPrice = 10000;
      _minRating = 0;
      _selectedCity = null;
      _selectedDate = null;
      _selectedCategory = null;
    });
    _notifyFiltersChanged();
  }

  /// Уведомить об изменении фильтров
  void _notifyFiltersChanged() {
    widget.onFiltersChanged({
      'minPrice': _minPrice,
      'maxPrice': _maxPrice,
      'minRating': _minRating,
      'city': _selectedCity,
      'date': _selectedDate,
      'category': _selectedCategory,
    });
  }
}
