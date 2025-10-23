import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/search_filters.dart';
import '../models/specialist.dart';
import '../models/specialist_filters.dart';
import '../providers/specialist_providers.dart';
import '../widgets/advanced_search_filters.dart';
import '../widgets/specialist_card.dart';

class AdvancedSearchScreen extends ConsumerStatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  ConsumerState<AdvancedSearchScreen> createState() =>
      _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends ConsumerState<AdvancedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  SpecialistFilters _filters = const SpecialistFilters();
  List<Specialist> _specialists = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSpecialists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final searchFilters = SearchFilters(
        query: _filters.searchQuery,
        city: _filters.city,
        minRating: _filters.minRating,
        minPrice: _filters.minPrice?.toInt(),
        maxPrice: _filters.maxPrice?.toInt(),
        isAvailable: true,
      );
      final specialists = await ref
          .read(specialistServiceProvider)
          .searchSpecialists(searchFilters);
      setState(() {
        _specialists = specialists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
      }
    }
  }

  void _updateFilters(SpecialistFilters newFilters) {
    setState(() {
      _filters = newFilters;
    });
    _loadSpecialists();
  }

  void _clearFilters() {
    setState(() {
      _filters = const SpecialistFilters();
      _searchController.clear();
    });
    _loadSpecialists();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Расширенный поиск'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            if (_filters.hasActiveFilters)
              IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: _clearFilters,
                tooltip: 'Очистить фильтры',
              ),
            IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFiltersDialog),
          ],
        ),
        body: Column(
          children: [
            // Поисковая строка
            _buildSearchBar(),

            // Индикатор активных фильтров
            if (_filters.hasActiveFilters) _buildActiveFiltersIndicator(),

            // Результаты поиска
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _specialists.isEmpty
                      ? _buildEmptyState()
                      : _buildResultsList(),
            ),
          ],
        ),
      );

  Widget _buildSearchBar() => Container(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Поиск специалистов...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _updateFilters(_filters.copyWith());
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) {
            _updateFilters(
                _filters.copyWith(searchQuery: value.isEmpty ? null : value));
          },
        ),
      );

  Widget _buildActiveFiltersIndicator() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.filter_alt,
                size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Активных фильтров: ${_filters.activeFiltersCount}',
              style: Theme.of(
                context,
              )
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const Spacer(),
            TextButton(onPressed: _clearFilters, child: const Text('Очистить')),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('Специалисты не найдены',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить параметры поиска',
              style: Theme.of(
                context,
              )
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _clearFilters,
                child: const Text('Сбросить фильтры')),
          ],
        ),
      );

  Widget _buildResultsList() => Column(
        children: [
          // Сортировка
          _buildSortingOptions(),

          // Список специалистов
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _specialists.length,
              itemBuilder: (context, index) {
                final specialist = _specialists[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SpecialistCard(
                    specialist: specialist,
                    onTap: () => _navigateToSpecialistProfile(specialist),
                  ),
                );
              },
            ),
          ),
        ],
      );

  Widget _buildSortingOptions() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Text('Сортировка:'),
            const SizedBox(width: 8),
            DropdownButton<SpecialistSortOption>(
              value: _filters.sortBy,
              hint: const Text('По умолчанию'),
              items: SpecialistSortOption.values
                  .map((option) => DropdownMenuItem(
                      value: option, child: Text(option.label)))
                  .toList(),
              onChanged: (value) {
                _updateFilters(_filters.copyWith(sortBy: value));
              },
            ),
            const Spacer(),
            if (_filters.sortBy != null)
              IconButton(
                icon: Icon(_filters.sortAscending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward),
                onPressed: () {
                  _updateFilters(_filters.copyWith(
                      sortAscending: !_filters.sortAscending));
                },
                tooltip:
                    _filters.sortAscending ? 'По возрастанию' : 'По убыванию',
              ),
          ],
        ),
      );

  void _showFiltersDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AdvancedSearchFilters(
          filters: _filters, onFiltersChanged: _updateFilters),
    );
  }

  void _navigateToSpecialistProfile(Specialist specialist) {
    // TODO(developer): Navigate to specialist profile
    Navigator.pushNamed(context, '/specialist-profile',
        arguments: specialist.id);
  }
}
