import 'package:flutter/material.dart';
import '../providers/customer_profile_extended_providers.dart';

/// Виджет фильтрации заметок
class NoteFilterWidget extends StatefulWidget {
  const NoteFilterWidget({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });
  final NoteFilters currentFilters;
  final Function(NoteFilters) onFiltersChanged;

  @override
  State<NoteFilterWidget> createState() => _NoteFilterWidgetState();
}

class _NoteFilterWidgetState extends State<NoteFilterWidget> {
  late TextEditingController _searchController;
  late List<String> _selectedTags;
  late bool _showPinnedOnly;
  late bool _showByDate;
  late DateTime? _fromDate;
  late DateTime? _toDate;
  late String? _eventId;
  late String? _specialistId;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.currentFilters.searchQuery ?? '');
    _selectedTags = List.from(widget.currentFilters.selectedTags);
    _showPinnedOnly = widget.currentFilters.showPinnedOnly;
    _showByDate = widget.currentFilters.showByDate;
    _fromDate = widget.currentFilters.fromDate;
    _toDate = widget.currentFilters.toDate;
    _eventId = widget.currentFilters.eventId;
    _specialistId = widget.currentFilters.specialistId;
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
                title: const Text('Фильтры заметок'),
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
                          hintText: 'Поиск по заголовку, содержимому или тегам',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Закреплённые заметки
                      SwitchListTile(
                        title: const Text('Только закреплённые заметки'),
                        subtitle: const Text('Показать только важные заметки'),
                        value: _showPinnedOnly,
                        onChanged: (value) {
                          setState(() {
                            _showPinnedOnly = value;
                          });
                        },
                      ),

                      const Divider(),

                      // Фильтр по дате
                      SwitchListTile(
                        title: const Text('Фильтр по дате'),
                        subtitle: const Text(
                          'Показать заметки за определённый период',
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

                      // Связь с событиями и специалистами
                      const Text(
                        'Связь с объектами',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      ListTile(
                        leading: const Icon(Icons.event),
                        title: const Text('Связанные с событием'),
                        subtitle: Text(
                          _eventId != null ? 'ID: $_eventId' : 'Все заметки',
                        ),
                        trailing: _eventId != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _eventId = null;
                                  });
                                },
                              )
                            : const Icon(Icons.arrow_forward_ios),
                        onTap: _selectEvent,
                      ),

                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Связанные со специалистом'),
                        subtitle: Text(
                          _specialistId != null
                              ? 'ID: $_specialistId'
                              : 'Все заметки',
                        ),
                        trailing: _specialistId != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _specialistId = null;
                                  });
                                },
                              )
                            : const Icon(Icons.arrow_forward_ios),
                        onTap: _selectSpecialist,
                      ),

                      const Divider(),

                      // Теги
                      const Text(
                        'Теги',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
      'важно',
      'идея',
      'бюджет',
      'дата',
      'место',
      'гости',
      'декор',
      'еда',
      'музыка',
      'фото',
      'видео',
      'подарки',
      'планирование',
      'список',
      'напоминание',
      'контакт',
      'договор',
      'оплата',
      'отзыв',
      'рекомендация',
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

  void _selectEvent() {
    // TODO: Реализовать выбор события из списка
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Выбор события будет добавлен в следующей версии'),
      ),
    );
  }

  void _selectSpecialist() {
    // TODO: Реализовать выбор специалиста из списка
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Выбор специалиста будет добавлен в следующей версии'),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedTags.clear();
      _showPinnedOnly = false;
      _showByDate = false;
      _fromDate = null;
      _toDate = null;
      _eventId = null;
      _specialistId = null;
    });
  }

  void _applyFilters() {
    final filters = NoteFilters(
      searchQuery: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      selectedTags: _selectedTags,
      showPinnedOnly: _showPinnedOnly,
      showByDate: _showByDate,
      fromDate: _fromDate,
      toDate: _toDate,
      eventId: _eventId,
      specialistId: _specialistId,
    );

    widget.onFiltersChanged(filters);
    Navigator.pop(context);
  }
}
