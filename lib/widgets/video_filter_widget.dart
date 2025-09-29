import 'package:flutter/material.dart';
import '../providers/specialist_profile_extended_providers.dart';

/// Виджет фильтрации видео
class VideoFilterWidget extends StatefulWidget {
  const VideoFilterWidget({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });
  final VideoFilters currentFilters;
  final void Function(VideoFilters) onFiltersChanged;

  @override
  State<VideoFilterWidget> createState() => _VideoFilterWidgetState();
}

class _VideoFilterWidgetState extends State<VideoFilterWidget> {
  late TextEditingController _searchController;
  late List<String> _selectedTags;
  late List<String> _selectedPlatforms;
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
    _selectedPlatforms = List.from(widget.currentFilters.selectedPlatforms);
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
                title: const Text('Фильтры видео'),
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
                          hintText: 'Поиск по названию, описанию или тегам',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Публичные видео
                      SwitchListTile(
                        title: const Text('Только публичные видео'),
                        subtitle: const Text(
                          'Показать только видео, доступные клиентам',
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
                            const Text('Показать видео за определённый период'),
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

                      // Платформы
                      const Text(
                        'Платформы',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPlatformFilters(),

                      const SizedBox(height: 16),

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

  Widget _buildPlatformFilters() {
    final platforms = [
      ('youtube', 'YouTube'),
      ('vimeo', 'Vimeo'),
      ('direct', 'Прямая загрузка'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Выберите платформы для фильтрации:',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: platforms
              .map(
                (platform) => FilterChip(
                  label: Text(platform.$2),
                  selected: _selectedPlatforms.contains(platform.$1),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedPlatforms.add(platform.$1);
                      } else {
                        _selectedPlatforms.remove(platform.$1);
                      }
                    });
                  },
                ),
              )
              .toList(),
        ),
        if (_selectedPlatforms.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Выбранные платформы:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _selectedPlatforms.map((platform) {
              final displayName = platforms
                  .firstWhere(
                    (p) => p.$1 == platform,
                    orElse: () => (platform, platform),
                  )
                  .$2;
              return Chip(
                label: Text(displayName),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _selectedPlatforms.remove(platform);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTagFilters() {
    final commonTags = [
      'портфолио',
      'работа',
      'мероприятие',
      'свадьба',
      'корпоратив',
      'фотосессия',
      'видеосъёмка',
      'дрон',
      'аэросъёмка',
      'таймлапс',
      'интервью',
      'репортаж',
      'документальный',
      'реклама',
      'презентация',
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
      _selectedPlatforms.clear();
      _showPublicOnly = true;
      _showByDate = false;
      _fromDate = null;
      _toDate = null;
    });
  }

  void _applyFilters() {
    final filters = VideoFilters(
      searchQuery: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      selectedTags: _selectedTags,
      selectedPlatforms: _selectedPlatforms,
      showPublicOnly: _showPublicOnly,
      showByDate: _showByDate,
      fromDate: _fromDate,
      toDate: _toDate,
    );

    widget.onFiltersChanged(filters);
    Navigator.pop(context);
  }
}
