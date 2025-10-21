import 'package:flutter/material.dart';

/// Диалог фильтров для поиска специалистов
class FiltersDialog extends StatefulWidget {
  final String? selectedCity;
  final String? selectedCategory;

  const FiltersDialog({super.key, this.selectedCity, this.selectedCategory});

  @override
  State<FiltersDialog> createState() => _FiltersDialogState();
}

class _FiltersDialogState extends State<FiltersDialog> {
  String? _selectedCity;
  String? _selectedCategory;
  String? _selectedRating;
  String? _selectedType;

  final List<String> _cities = [
    'Москва',
    'Санкт-Петербург',
    'Новосибирск',
    'Екатеринбург',
    'Казань',
    'Нижний Новгород',
    'Челябинск',
    'Самара',
    'Омск',
    'Ростов-на-Дону',
  ];

  final List<String> _categories = [
    'Фотограф',
    'Видеограф',
    'Диджей',
    'Ведущий',
    'Декоратор',
    'Флорист',
    'Кейтеринг',
    'Аниматор',
    'Музыкант',
    'Танцор',
  ];

  final List<String> _ratings = ['Любой рейтинг', '4.5+ звезд', '4.0+ звезд', '3.5+ звезд'];

  final List<String> _types = ['Любой тип', 'Физическое лицо', 'ИП', 'Организация'];

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.selectedCity;
    _selectedCategory = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: theme.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    'Фильтры поиска',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
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
                    _buildFilterSection(
                      title: 'Город',
                      icon: Icons.location_on_outlined,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _cities.map((city) {
                          final isSelected = _selectedCity == city;
                          return FilterChip(
                            label: Text(city),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCity = selected ? city : null;
                              });
                            },
                            selectedColor: theme.primaryColor.withValues(alpha: 0.2),
                            checkmarkColor: theme.primaryColor,
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Категория
                    _buildFilterSection(
                      title: 'Категория',
                      icon: Icons.category_outlined,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          return FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? category : null;
                              });
                            },
                            selectedColor: theme.primaryColor.withValues(alpha: 0.2),
                            checkmarkColor: theme.primaryColor,
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Рейтинг
                    _buildFilterSection(
                      title: 'Рейтинг',
                      icon: Icons.star_outline,
                      child: Column(
                        children: _ratings.map((rating) {
                          final isSelected = _selectedRating == rating;
                          return ListTile(
                            title: Text(rating),
                            leading: Radio<String>(
                              value: rating,
                              groupValue: _selectedRating,
                              onChanged: (value) {
                                setState(() {
                                  _selectedRating = value;
                                });
                              },
                              activeColor: theme.primaryColor,
                            ),
                            onTap: () {
                              setState(() {
                                _selectedRating = rating;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Тип специалиста
                    _buildFilterSection(
                      title: 'Тип специалиста',
                      icon: Icons.person_outline,
                      child: Column(
                        children: _types.map((type) {
                          final isSelected = _selectedType == type;
                          return ListTile(
                            title: Text(type),
                            leading: Radio<String>(
                              value: type,
                              groupValue: _selectedType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value;
                                });
                              },
                            ),
                            onTap: () {
                              setState(() {
                                _selectedType = type;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Кнопки
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearFilters,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Сбросить'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Применить', style: TextStyle(color: Colors.white)),
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

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCity = null;
      _selectedCategory = null;
      _selectedRating = null;
      _selectedType = null;
    });
  }

  void _applyFilters() {
    Navigator.of(context).pop({
      'city': _selectedCity,
      'category': _selectedCategory,
      'rating': _selectedRating,
      'type': _selectedType,
    });
  }
}
