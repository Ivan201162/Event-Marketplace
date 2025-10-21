import 'package:flutter/material.dart';

import '../models/specialist_filters.dart';

class AdvancedSearchFilters extends StatefulWidget {
  const AdvancedSearchFilters({super.key, required this.filters, required this.onFiltersChanged});
  final SpecialistFilters filters;
  final Function(SpecialistFilters) onFiltersChanged;

  @override
  State<AdvancedSearchFilters> createState() => _AdvancedSearchFiltersState();
}

class _AdvancedSearchFiltersState extends State<AdvancedSearchFilters> {
  late SpecialistFilters _currentFilters;
  late RangeValues _priceRange;
  late RangeValues _ratingRange;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.filters;
    _priceRange = RangeValues(_currentFilters.minPrice ?? 0, _currentFilters.maxPrice ?? 100000);
    _ratingRange = RangeValues(_currentFilters.minRating ?? 0, _currentFilters.maxRating ?? 5);
    _selectedDate = _currentFilters.availableDate;
  }

  @override
  Widget build(BuildContext context) => Container(
    height: MediaQuery.of(context).size.height * 0.8,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок
        Row(
          children: [
            const Text(
              'Фильтры поиска',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ],
        ),
        const Divider(),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Фильтр по цене
                _buildPriceFilter(),
                const SizedBox(height: 24),

                // Фильтр по рейтингу
                _buildRatingFilter(),
                const SizedBox(height: 24),

                // Фильтр по дате
                _buildDateFilter(),
                const SizedBox(height: 24),

                // Фильтр по городу
                _buildCityFilter(),
                const SizedBox(height: 24),

                // Фильтр по верификации
                _buildVerificationFilter(),
                const SizedBox(height: 24),

                // Фильтр по доступности
                _buildAvailabilityFilter(),
              ],
            ),
          ),
        ),

        // Кнопки действий
        _buildActionButtons(),
      ],
    ),
  );

  Widget _buildPriceFilter() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Цена за час (₽)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      RangeSlider(
        values: _priceRange,
        max: 100000,
        divisions: 100,
        labels: RangeLabels('${_priceRange.start.round()} ₽', '${_priceRange.end.round()} ₽'),
        onChanged: (values) {
          setState(() {
            _priceRange = values;
          });
        },
      ),
      const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text('0 ₽'), Text('100 000 ₽')],
      ),
    ],
  );

  Widget _buildRatingFilter() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Минимальный рейтинг',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Slider(
        value: _ratingRange.start,
        max: 5,
        divisions: 50,
        label: '${_ratingRange.start.toStringAsFixed(1)} ⭐',
        onChanged: (value) {
          setState(() {
            _ratingRange = RangeValues(value, _ratingRange.end);
          });
        },
      ),
      const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text('0 ⭐'), Text('5 ⭐')],
      ),
    ],
  );

  Widget _buildDateFilter() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Доступная дата', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      InkWell(
        onTap: _selectDate,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today),
              const SizedBox(width: 8),
              Text(
                _selectedDate != null
                    ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                    : 'Выберите дату',
              ),
              const Spacer(),
              if (_selectedDate != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedDate = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _buildCityFilter() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Город', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextField(
        decoration: const InputDecoration(hintText: 'Введите город', border: OutlineInputBorder()),
        onChanged: (value) {
          setState(() {
            _currentFilters = _currentFilters.copyWith(city: value.isEmpty ? null : value);
          });
        },
      ),
    ],
  );

  Widget _buildVerificationFilter() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Верификация', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      CheckboxListTile(
        title: const Text('Только верифицированные'),
        value: _currentFilters.isVerified ?? false,
        onChanged: (value) {
          setState(() {
            _currentFilters = _currentFilters.copyWith(isVerified: value);
          });
        },
      ),
    ],
  );

  Widget _buildAvailabilityFilter() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Доступность', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      CheckboxListTile(
        title: const Text('Только доступные сейчас'),
        value: _currentFilters.isAvailable ?? false,
        onChanged: (value) {
          setState(() {
            _currentFilters = _currentFilters.copyWith(isAvailable: value);
          });
        },
      ),
    ],
  );

  Widget _buildActionButtons() => Row(
    children: [
      Expanded(
        child: OutlinedButton(onPressed: _clearFilters, child: const Text('Очистить')),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: ElevatedButton(onPressed: _applyFilters, child: const Text('Применить')),
      ),
    ],
  );

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
    }
  }

  void _clearFilters() {
    setState(() {
      _currentFilters = const SpecialistFilters();
      _priceRange = const RangeValues(0, 100000);
      _ratingRange = const RangeValues(0, 5);
      _selectedDate = null;
    });
  }

  void _applyFilters() {
    final newFilters = _currentFilters.copyWith(
      minPrice: _priceRange.start > 0 ? _priceRange.start : null,
      maxPrice: _priceRange.end < 100000 ? _priceRange.end : null,
      minRating: _ratingRange.start > 0 ? _ratingRange.start : null,
      availableDate: _selectedDate,
    );

    widget.onFiltersChanged(newFilters);
    Navigator.pop(context);
  }
}
