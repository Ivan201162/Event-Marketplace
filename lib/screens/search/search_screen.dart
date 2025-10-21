import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/search_filters.dart';
import '../../providers/specialist_providers.dart';
import '../../widgets/search_filters_widget.dart';
import '../../widgets/specialist_card.dart';

/// Search screen for finding specialists
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final currentFilters = ref.read(searchFiltersProvider);
    final newFilters = currentFilters.copyWith(
      query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
    );

    ref.read(searchFiltersProvider.notifier).updateFilters(newFilters);
    setState(() => _isSearching = true);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchFiltersProvider.notifier).clearFilters();
    setState(() => _isSearching = false);
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: SearchFiltersWidget(
          initialFilters: ref.read(searchFiltersProvider),
          onApplyFilters: (filters) {
            ref.read(searchFiltersProvider.notifier).updateFilters(filters);
            setState(() => _isSearching = true);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchFilters = ref.watch(searchFiltersProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider(searchFilters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск специалистов'),
        actions: [IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilters)],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Поиск по имени, специализации, услугам...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _performSearch, child: const Text('Найти')),
              ],
            ),
          ),

          // Active filters
          if (searchFilters.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Активные фильтры (${searchFilters.activeFiltersCount})',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      TextButton(onPressed: _clearSearch, child: const Text('Очистить')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (searchFilters.query != null && searchFilters.query!.isNotEmpty)
                        _buildFilterChip('Поиск: ${searchFilters.query}', () {
                          final newFilters = searchFilters.copyWith();
                          ref.read(searchFiltersProvider.notifier).updateFilters(newFilters);
                        }),
                      if (searchFilters.city != null)
                        _buildFilterChip('Город: ${searchFilters.city}', () {
                          final newFilters = searchFilters.copyWith();
                          ref.read(searchFiltersProvider.notifier).updateFilters(newFilters);
                        }),
                      if (searchFilters.specialization != null)
                        _buildFilterChip('Специализация: ${searchFilters.specialization}', () {
                          final newFilters = searchFilters.copyWith();
                          ref.read(searchFiltersProvider.notifier).updateFilters(newFilters);
                        }),
                      if (searchFilters.minRating != null)
                        _buildFilterChip('Рейтинг: ${searchFilters.minRating}+', () {
                          final newFilters = searchFilters.copyWith();
                          ref.read(searchFiltersProvider.notifier).updateFilters(newFilters);
                        }),
                      if (searchFilters.minPrice != null || searchFilters.maxPrice != null)
                        _buildFilterChip(
                          'Цена: ${searchFilters.minPrice ?? 0}-${searchFilters.maxPrice ?? '∞'} ₽',
                          () {
                            final newFilters = searchFilters.copyWith();
                            ref.read(searchFiltersProvider.notifier).updateFilters(newFilters);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
          ],

          // Search results
          Expanded(
            child: searchResultsAsync.when(
              data: (specialists) {
                if (specialists.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: specialists.length,
                  itemBuilder: (context, index) {
                    final specialist = specialists[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SpecialistCard(
                        specialist: specialist,
                        onTap: () {
                          context.push('/specialist/${specialist.id}');
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Ошибка поиска', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _performSearch,
                      child: const Text('Попробовать снова'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onDeleted,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Специалисты не найдены', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Попробуйте изменить параметры поиска',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _clearSearch, child: const Text('Очистить фильтры')),
        ],
      ),
    );
  }
}
