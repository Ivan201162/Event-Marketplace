import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/feature_flags.dart';
import '../services/availability_filter_service.dart';

/// Экран фильтрации специалистов по занятости
class AvailabilityFilterScreen extends ConsumerStatefulWidget {
  const AvailabilityFilterScreen({super.key});

  @override
  ConsumerState<AvailabilityFilterScreen> createState() => _AvailabilityFilterScreenState();
}

class _AvailabilityFilterScreenState extends ConsumerState<AvailabilityFilterScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AvailabilityFilterService _filterService = AvailabilityFilterService();

  DateTime? _startDate;
  DateTime? _endDate;
  final List<int> _selectedHours = [];
  final List<String> _selectedDays = [];
  bool _onlyAvailable = true;

  List<SpecialistAvailability> _filteredSpecialists = [];
  bool _isLoading = false;

  final List<String> _daysOfWeek = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  final List<String> _dayNames = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAvailableSpecialists();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.availabilityFilterEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Фильтр по занятости'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Фильтр по занятости временно недоступен',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Фильтр по занятости'),
        backgroundColor: Colors.blue[50],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Фильтры', icon: Icon(Icons.filter_list)),
            Tab(text: 'Результаты', icon: Icon(Icons.search)),
            Tab(text: 'Календарь', icon: Icon(Icons.calendar_today)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFiltersTab(),
          _buildResultsTab(),
          _buildCalendarTab(),
        ],
      ),
    );
  }

  Widget _buildFiltersTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangeFilter(),
            const SizedBox(height: 24),
            _buildDaysFilter(),
            const SizedBox(height: 24),
            _buildHoursFilter(),
            const SizedBox(height: 24),
            _buildAvailabilityToggle(),
            const SizedBox(height: 32),
            _buildApplyButton(),
          ],
        ),
      );

  Widget _buildDateRangeFilter() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Период поиска',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      'Начальная дата',
                      _startDate,
                      (date) => setState(() => _startDate = date),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      'Конечная дата',
                      _endDate,
                      (date) => setState(() => _endDate = date),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildDateField(
    String label,
    DateTime? date,
    Function(DateTime?) onChanged,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              onChanged(selectedDate);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      date != null ? '${date.day}.${date.month}.${date.year}' : 'Выберите дату',
                      style: TextStyle(
                        color: date != null ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildDaysFilter() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Предпочитаемые дни',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Выберите дни недели, когда специалист должен быть доступен',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_daysOfWeek.length, (index) {
                  final day = _daysOfWeek[index];
                  final dayName = _dayNames[index];
                  final isSelected = _selectedDays.contains(day);

                  return FilterChip(
                    label: Text(dayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
                    selectedColor: Colors.blue[100],
                    checkmarkColor: Colors.blue[600],
                  );
                }),
              ),
            ],
          ),
        ),
      );

  Widget _buildHoursFilter() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Предпочитаемые часы',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Выберите часы дня, когда специалист должен быть доступен',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(12, (index) {
                  final hour = index + 8; // 8:00 - 19:00
                  final isSelected = _selectedHours.contains(hour);

                  return FilterChip(
                    label: Text('$hour:00'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedHours.add(hour);
                        } else {
                          _selectedHours.remove(hour);
                        }
                      });
                    },
                    selectedColor: Colors.green[100],
                    checkmarkColor: Colors.green[600],
                  );
                }),
              ),
            ],
          ),
        ),
      );

  Widget _buildAvailabilityToggle() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Дополнительные настройки',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Только доступные специалисты'),
                subtitle: const Text(
                  'Показать только специалистов с высокой доступностью',
                ),
                value: _onlyAvailable,
                onChanged: (value) {
                  setState(() {
                    _onlyAvailable = value;
                  });
                },
                secondary: Icon(
                  Icons.person_search,
                  color: _onlyAvailable ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildApplyButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _applyFilters,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: Text(_isLoading ? 'Поиск...' : 'Применить фильтры'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );

  Widget _buildResultsTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Поиск доступных специалистов...'),
          ],
        ),
      );
    }

    if (_filteredSpecialists.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Специалисты не найдены',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Попробуйте изменить параметры фильтра',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSpecialists.length,
      itemBuilder: (context, index) {
        final specialist = _filteredSpecialists[index];
        return _buildSpecialistCard(specialist);
      },
    );
  }

  Widget _buildSpecialistCard(SpecialistAvailability specialist) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: specialist.specialistPhoto != null
                        ? NetworkImage(specialist.specialistPhoto!)
                        : null,
                    child: specialist.specialistPhoto == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          specialist.specialistName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${specialist.availableSlots.length} доступных слотов',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getAvailabilityColor(specialist.availabilityScore),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(specialist.availabilityScore * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAvailabilityInfo(specialist),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showSpecialistDetails(specialist),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Подробнее'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _bookSpecialist(specialist),
                      icon: const Icon(Icons.book_online),
                      label: const Text('Забронировать'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildAvailabilityInfo(SpecialistAvailability specialist) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Доступные дни:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: specialist.availableDays.map((day) {
              final dayIndex = _daysOfWeek.indexOf(day);
              final dayName = dayIndex >= 0 ? _dayNames[dayIndex] : day;
              return Chip(
                label: Text(dayName),
                backgroundColor: Colors.blue[50],
                labelStyle: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Доступные часы: ${specialist.availableHours.join(', ')}:00',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      );

  Widget _buildCalendarTab() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Календарь занятости',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Функция будет добавлена в следующей версии',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );

  Color _getAvailabilityColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Future<void> _loadAvailableSpecialists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final filter = AvailabilityFilter(
        startDate: _startDate,
        endDate: _endDate,
        preferredHours: _selectedHours.isNotEmpty ? _selectedHours : null,
        preferredDays: _selectedDays.isNotEmpty ? _selectedDays : null,
        onlyAvailable: _onlyAvailable,
      );

      final specialists = await _filterService.getAvailableSpecialists(filter);

      setState(() {
        _filteredSpecialists = specialists;
        _isLoading = false;
      });

      // Переключаемся на вкладку результатов
      _tabController.animateTo(1);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _applyFilters() async {
    await _loadAvailableSpecialists();
  }

  void _showSpecialistDetails(SpecialistAvailability specialist) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Детали доступности',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: specialist.availableSlots.length,
                  itemBuilder: (context, index) {
                    final slot = specialist.availableSlots[index];
                    return ListTile(
                      leading: const Icon(Icons.schedule, color: Colors.green),
                      title: Text('${slot.day}.${slot.month}.${slot.year}'),
                      subtitle: Text('${slot.hour}:00'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _bookSpecialist(SpecialistAvailability specialist) {
    // TODO(developer): Реализовать бронирование специалиста
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция бронирования будет добавлена'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
