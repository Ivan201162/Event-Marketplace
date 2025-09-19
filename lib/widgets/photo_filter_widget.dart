import 'package:flutter/material.dart';
import '../providers/customer_profile_extended_providers.dart';

/// Виджет фильтрации фото
class PhotoFilterWidget extends StatefulWidget {
  const PhotoFilterWidget({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });
  final PhotoFilters currentFilters;
  final Function(PhotoFilters) onFiltersChanged;

  @override
  State<PhotoFilterWidget> createState() => _PhotoFilterWidgetState();
}

class _PhotoFilterWidgetState extends State<PhotoFilterWidget> {
  late TextEditingController _searchController;
  late List<String> _selectedTags;
  late bool _showPublicOnly;
  late bool _showByDate;
  late DateTime? _fromDate;
  late DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.currentFilters.searchQuery ?? '');
    _selectedTags = List.from(widget.currentFilters.selectedTags);
    _showPublicOnly = widget.currentFilters.showPublicOnly;
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
                title: const Text('Фильтры фото'),
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
                          hintText: 'Поиск по подписи или тегам',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Публичность
                      SwitchListTile(
                        title: const Text('Только публичные фото'),
                        subtitle: const Text(
                          'Показать только фото, доступные другим пользователям',
                        ),
                        value: _showPublicOnly,
                        onChanged: (value) {
                          setState(() {
                            _showPublicOnly = value;
                          });
                        },
                      ),

                      const Divider(),

                      // Фильтр по дате
                      SwitchListTile(
                        title: const Text('Фильтр по дате'),
                        subtitle:
                            const Text('Показать фото за определённый период'),
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

                      // Теги
                      const Text(
                        'Теги',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildTagFilters(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildTagFilters() {
    // Предустановленные теги для фильтрации
    final commonTags = [
      'декор',
      'цветы',
      'свечи',
      'гирлянды',
      'шары',
      'стол',
      'стулья',
      'скатерть',
      'посуда',
      'торт',
      'еда',
      'напитки',
      'фрукты',
      'музыка',
      'танцы',
      'игры',
      'конкурсы',
      'фото',
      'видео',
      'фон',
      'освещение',
      'природа',
      'интерьер',
      'улица',
      'дом',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Выберите теги для фильтрации:',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: commonTags
              .map(
                (tag) => FilterChip(
                  label: Text(tag),
                  selected: _selectedTags.contains(tag),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                ),
              )
              .toList(),
        ),
        if (_selectedTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Выбранные теги:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _selectedTags
                .map(
                  (tag) => Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        _selectedTags.remove(tag);
                      });
                    },
                  ),
                )
                .toList(),
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
      _selectedTags.clear();
      _showPublicOnly = false;
      _showByDate = false;
      _fromDate = null;
      _toDate = null;
    });
  }

  void _applyFilters() {
    final filters = PhotoFilters(
      searchQuery: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      selectedTags: _selectedTags,
      showPublicOnly: _showPublicOnly,
      showByDate: _showByDate,
      fromDate: _fromDate,
      toDate: _toDate,
    );

    widget.onFiltersChanged(filters);
    Navigator.pop(context);
  }
}
