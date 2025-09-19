import 'package:flutter/material.dart';
import '../providers/specialist_profile_extended_providers.dart';

/// Виджет фильтрации FAQ
class FAQFilterWidget extends StatefulWidget {
  const FAQFilterWidget({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });
  final FAQFilters currentFilters;
  final Function(FAQFilters) onFiltersChanged;

  @override
  State<FAQFilterWidget> createState() => _FAQFilterWidgetState();
}

class _FAQFilterWidgetState extends State<FAQFilterWidget> {
  late TextEditingController _searchController;
  late List<String> _selectedCategories;
  late bool _showPublishedOnly;
  late bool _showByDate;
  late DateTime? _fromDate;
  late DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.currentFilters.searchQuery ?? '');
    _selectedCategories = List.from(widget.currentFilters.selectedCategories);
    _showPublishedOnly = widget.currentFilters.showPublishedOnly;
    _showByDate = widget.currentFilters.showByDate;
    _fromDate = widget.currentFilters.fromDate;
    _toDate = widget.currentFilters.toDate;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            children: [
              AppBar(
                title: const Text('Фильтры FAQ'),
                actions: [
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Сбросить'),
                  ),
                  TextButton(
                    onPressed: _applyFilters,
                    child: const Text('Применить'),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Поиск
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Поиск',
                          hintText: 'Поиск по вопросу, ответу или категории',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Опубликованные вопросы
                      SwitchListTile(
                        title: const Text('Только опубликованные вопросы'),
                        subtitle: const Text(
                          'Показать только вопросы, доступные клиентам',
                        ),
                        value: _showPublishedOnly,
                        onChanged: (value) {
                          setState(() {
                            _showPublishedOnly = value;
                          });
                        },
                      ),

                      const Divider(),

                      // Фильтр по дате
                      SwitchListTile(
                        title: const Text('Фильтр по дате'),
                        subtitle: const Text(
                          'Показать вопросы за определённый период',
                        ),
                        value: _showByDate,
                        onChanged: (value) {
                          setState(() {
                            _showByDate = value;
                          });
                        },
                      ),

                      if (_showByDate) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                title: const Text('От'),
                                subtitle: Text(
                                  _fromDate != null
                                      ? '${_fromDate!.day}.${_fromDate!.month}.${_fromDate!.year}'
                                      : 'Не выбрано',
                                ),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: _selectFromDate,
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                title: const Text('До'),
                                subtitle: Text(
                                  _toDate != null
                                      ? '${_toDate!.day}.${_toDate!.month}.${_toDate!.year}'
                                      : 'Не выбрано',
                                ),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: _selectToDate,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const Divider(),

                      // Категории
                      const Text(
                        'Категории',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCategoryFilters(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildCategoryFilters() {
    final categories = [
      ('general', 'Общие вопросы'),
      ('pricing', 'Цены и оплата'),
      ('booking', 'Бронирование'),
      ('services', 'Услуги'),
      ('equipment', 'Оборудование'),
      ('cancellation', 'Отмена и возврат'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Выберите категории для фильтрации:',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: categories
              .map(
                (category) => FilterChip(
                  label: Text(category.$2),
                  selected: _selectedCategories.contains(category.$1),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category.$1);
                      } else {
                        _selectedCategories.remove(category.$1);
                      }
                    });
                  },
                ),
              )
              .toList(),
        ),
        if (_selectedCategories.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Выбранные категории:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _selectedCategories.map((category) {
              final displayName = categories
                  .firstWhere(
                    (c) => c.$1 == category,
                    orElse: () => (category, category),
                  )
                  .$2;
              return Chip(
                label: Text(displayName),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _selectedCategories.remove(category);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _selectFromDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _fromDate = date;
        // Если выбранная дата больше конечной, сбрасываем конечную
        if (_toDate != null && _fromDate!.isAfter(_toDate!)) {
          _toDate = null;
        }
      });
    }
  }

  Future<void> _selectToDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _toDate = date;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategories.clear();
      _showPublishedOnly = true;
      _showByDate = false;
      _fromDate = null;
      _toDate = null;
    });
  }

  void _applyFilters() {
    final filters = FAQFilters(
      searchQuery: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      selectedCategories: _selectedCategories,
      showPublishedOnly: _showPublishedOnly,
      showByDate: _showByDate,
      fromDate: _fromDate,
      toDate: _toDate,
    );

    widget.onFiltersChanged(filters);
    Navigator.pop(context);
  }
}
