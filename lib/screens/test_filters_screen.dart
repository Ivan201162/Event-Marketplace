import 'package:event_marketplace_app/models/specialist.dart';
import 'package:event_marketplace_app/models/specialist_filters.dart' as filters;
import 'package:event_marketplace_app/services/test_data_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TestFiltersScreen extends ConsumerStatefulWidget {
  const TestFiltersScreen({super.key});

  @override
  ConsumerState<TestFiltersScreen> createState() => _TestFiltersScreenState();
}

class _TestFiltersScreenState extends ConsumerState<TestFiltersScreen> {
  List<Specialist> _allSpecialists = [];
  List<Specialist> _filteredSpecialists = [];
  filters.SpecialistFilters _currentFilters = const filters.SpecialistFilters();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTestData();
  }

  void _loadTestData() {
    setState(() {
      _isLoading = true;
    });

    // Имитируем загрузку
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _allSpecialists = TestDataService.generateTestSpecialists();
        _filteredSpecialists = _allSpecialists;
        _isLoading = false;
      });
    });
  }

  void _applyFilters(filters.SpecialistFilters filterFilters) {
    setState(() {
      _currentFilters = filterFilters;
      _filteredSpecialists = _filterSpecialists(_allSpecialists, filterFilters);
    });
  }

  List<Specialist> _filterSpecialists(
    List<Specialist> specialists,
    filters.SpecialistFilters filterFilters,
  ) {
    final filtered = specialists.where((specialist) {
      // Фильтр по цене
      if (filterFilters.minPrice != null &&
          specialist.hourlyRate < filterFilters.minPrice!) {
        return false;
      }
      if (filterFilters.maxPrice != null &&
          specialist.hourlyRate > filterFilters.maxPrice!) {
        return false;
      }

      // Фильтр по рейтингу
      if (filterFilters.minRating != null &&
          specialist.rating < filterFilters.minRating!) {
        return false;
      }
      if (filterFilters.maxRating != null &&
          specialist.rating > filterFilters.maxRating!) {
        return false;
      }

      // Фильтр по городу
      if (filterFilters.city != null &&
          filterFilters.city!.isNotEmpty &&
          !specialist.location
              .toLowerCase()
              .contains(filterFilters.city!.toLowerCase())) {
        return false;
      }

      // Фильтр по верификации
      if (filterFilters.isVerified != null &&
          specialist.isVerified != filterFilters.isVerified) {
        return false;
      }

      // Фильтр по доступности
      if (filterFilters.isAvailable != null &&
          specialist.isAvailable != filterFilters.isAvailable) {
        return false;
      }

      // Фильтр по поисковому запросу
      if (filterFilters.searchQuery != null &&
          filterFilters.searchQuery!.isNotEmpty) {
        final query = filterFilters.searchQuery!.toLowerCase();
        if (!specialist.name.toLowerCase().contains(query) &&
            !specialist.description.toLowerCase().contains(query) &&
            !specialist.services
                .any((service) => service.toLowerCase().contains(query))) {
          return false;
        }
      }

      return true;
    }).toList();

    // Сортировка
    if (filterFilters.sortBy != null) {
      filtered.sort((a, b) {
        var comparison = 0;
        switch (filterFilters.sortBy!.value) {
          case 'rating':
            comparison = a.rating.compareTo(b.rating);
          case 'price':
            comparison = a.hourlyRate.compareTo(b.hourlyRate);
          case 'experience':
            comparison = a.yearsOfExperience.compareTo(b.yearsOfExperience);
          case 'reviews':
            comparison = a.reviewCount.compareTo(b.reviewCount);
          case 'name':
            comparison = a.name.compareTo(b.name);
          case 'dateAdded':
            comparison = a.createdAt.compareTo(b.createdAt);
        }
        return filterFilters.sortAscending ? comparison : -comparison;
      });
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Тест фильтров'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTestData,
              tooltip: 'Обновить данные',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Панель фильтров
                  _buildFiltersPanel(),

                  // Результаты
                  Expanded(child: _buildResults()),
                ],
              ),
      );

  Widget _buildFiltersPanel() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            // Быстрые фильтры
            _buildQuickFilters(),

            const SizedBox(height: 16),

            // Информация о результатах
            _buildResultsInfo(),
          ],
        ),
      );

  Widget _buildQuickFilters() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildFilterChip(
            label: 'Цена: 5-10k',
            isSelected: _currentFilters.minPrice == 5000 &&
                _currentFilters.maxPrice == 10000,
            onTap: () => _applyFilters(const filters.SpecialistFilters(
                minPrice: 5000, maxPrice: 10000,),),
          ),
          _buildFilterChip(
            label: 'Рейтинг: 4.5+',
            isSelected: _currentFilters.minRating == 4.5,
            onTap: () =>
                _applyFilters(const filters.SpecialistFilters(minRating: 4.5)),
          ),
          _buildFilterChip(
            label: 'Москва',
            isSelected: _currentFilters.city == 'Москва',
            onTap: () =>
                _applyFilters(const filters.SpecialistFilters(city: 'Москва')),
          ),
          _buildFilterChip(
            label: 'Верифицированные',
            isSelected: _currentFilters.isVerified ?? false,
            onTap: () => _applyFilters(
                const filters.SpecialistFilters(isVerified: true),),
          ),
          _buildFilterChip(
            label: 'Доступные',
            isSelected: _currentFilters.isAvailable ?? false,
            onTap: () => _applyFilters(
                const filters.SpecialistFilters(isAvailable: true),),
          ),
          _buildFilterChip(
            label: 'По цене ↑',
            isSelected:
                _currentFilters.sortBy == filters.SpecialistSortOption.price &&
                    _currentFilters.sortAscending,
            onTap: () => _applyFilters(
              const filters.SpecialistFilters(
                sortBy: filters.SpecialistSortOption.price,
                sortAscending: true,
              ),
            ),
          ),
          _buildFilterChip(
            label: 'По рейтингу ↓',
            isSelected:
                _currentFilters.sortBy == filters.SpecialistSortOption.rating &&
                    !_currentFilters.sortAscending,
            onTap: () => _applyFilters(
              const filters.SpecialistFilters(
                  sortBy: filters.SpecialistSortOption.rating,),
            ),
          ),
          _buildFilterChip(
            label: 'Сбросить',
            isSelected: false,
            onTap: () => _applyFilters(const filters.SpecialistFilters()),
          ),
        ],
      );

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) =>
      FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        checkmarkColor: Theme.of(context).colorScheme.primary,
      );

  Widget _buildResultsInfo() => Row(
        children: [
          Text(
            'Найдено: ${_filteredSpecialists.length} из ${_allSpecialists.length}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          if (_currentFilters.hasActiveFilters)
            Text(
              'Активных фильтров: ${_currentFilters.activeFiltersCount}',
              style: Theme.of(
                context,
              )
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
        ],
      );

  Widget _buildResults() {
    if (_filteredSpecialists.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Специалисты не найдены'),
            Text('Попробуйте изменить фильтры'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSpecialists.length,
      itemBuilder: (context, index) {
        final specialist = _filteredSpecialists[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(child: Text(specialist.name[0])),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              specialist.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold,),
                            ),
                            Text(
                              specialist.category.displayName,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${specialist.hourlyRate} ₽/час',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold,),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 16,),
                              Text(
                                  '${specialist.rating} (${specialist.reviewCount})',),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(specialist.bio,
                      maxLines: 2, overflow: TextOverflow.ellipsis,),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.grey[600],),
                      Text(specialist.location),
                      const Spacer(),
                      if (specialist.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2,),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Верифицирован',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2,),
                        decoration: BoxDecoration(
                          color: specialist.isAvailable
                              ? Colors.green
                              : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          specialist.isAvailable ? 'Доступен' : 'Занят',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12,),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
