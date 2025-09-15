import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../providers/event_providers.dart';
import '../widgets/event_card.dart';
import 'event_detail_screen.dart';

/// Экран каталога мероприятий с поиском и фильтрацией
class EventsCatalogScreen extends ConsumerStatefulWidget {
  const EventsCatalogScreen({super.key});

  @override
  ConsumerState<EventsCatalogScreen> createState() => _EventsCatalogScreenState();
}

class _EventsCatalogScreenState extends ConsumerState<EventsCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  EventFilter _currentFilter = const EventFilter();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = ref.watch(filteredEventsProvider(_currentFilter));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Каталог мероприятий"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Поисковая строка
          _buildSearchBar(),
          
          // Фильтры
          if (_showFilters) _buildFiltersSection(),
          
          // Результаты поиска
          Expanded(
            child: _buildEventsList(filteredEvents),
          ),
        ],
      ),
    );
  }

  /// Построить поисковую строку
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Поиск мероприятий...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          setState(() {});
          _performSearch();
        },
        onSubmitted: (value) {
          _performSearch();
        },
      ),
    );
  }

  /// Построить секцию фильтров
  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Фильтры',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Сбросить'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Фильтр по категории
          _buildCategoryFilter(),
          
          const SizedBox(height: 16),
          
          // Фильтр по цене
          _buildPriceFilter(),
          
          const SizedBox(height: 16),
          
          // Фильтр по дате
          _buildDateFilter(),
        ],
      ),
    );
  }

  /// Фильтр по категории
  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Категория',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: EventCategory.values.map((category) {
            final isSelected = _currentFilter.categories?.contains(category) ?? false;
            return FilterChip(
              label: Text(category.categoryName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final categories = List<EventCategory>.from(_currentFilter.categories ?? []);
                  if (selected) {
                    categories.add(category);
                  } else {
                    categories.remove(category);
                  }
                  _currentFilter = _currentFilter.copyWith(
                    categories: categories.isEmpty ? null : categories,
                  );
                });
                _performSearch();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Фильтр по цене
  Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Цена',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'От (₽)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = double.tryParse(value);
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(
                      minPrice: price,
                    );
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'До (₽)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = double.tryParse(value);
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(
                      maxPrice: price,
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Фильтр по дате
  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Дата',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectStartDate(),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _currentFilter.startDate != null
                      ? '${_currentFilter.startDate!.day}.${_currentFilter.startDate!.month}.${_currentFilter.startDate!.year}'
                      : 'От даты',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectEndDate(),
                icon: const Icon(Icons.event_available, size: 16),
                label: Text(
                  _currentFilter.endDate != null
                      ? '${_currentFilter.endDate!.day}.${_currentFilter.endDate!.month}.${_currentFilter.endDate!.year}'
                      : 'До даты',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Построить список мероприятий
  Widget _buildEventsList(AsyncValue<List<Event>> eventsAsync) {
    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return _buildEmptyState();
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            _performSearch();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: EventCard(
                  event: event,
                  onTap: () => _navigateToEventDetail(event),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка мероприятий...'),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  /// Построить пустое состояние
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Мероприятия не найдены',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуйте изменить параметры поиска',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _clearFilters,
            child: const Text('Сбросить фильтры'),
          ),
        ],
      ),
    );
  }

  /// Выполнить поиск
  void _performSearch() {
    final query = _searchController.text.trim();
    
    setState(() {
      _currentFilter = _currentFilter.copyWith(
        searchQuery: query.isEmpty ? null : query,
      );
    });
  }

  /// Очистить фильтры
  void _clearFilters() {
    setState(() {
      _currentFilter = const EventFilter();
      _searchController.clear();
    });
    _performSearch();
  }

  /// Выбрать начальную дату
  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _currentFilter.startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _currentFilter = _currentFilter.copyWith(startDate: date);
      });
      _performSearch();
    }
  }

  /// Выбрать конечную дату
  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _currentFilter.endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _currentFilter.startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _currentFilter = _currentFilter.copyWith(endDate: date);
      });
      _performSearch();
    }
  }

  /// Перейти к деталям мероприятия
  void _navigateToEventDetail(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }
}
