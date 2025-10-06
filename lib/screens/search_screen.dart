import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/app_navigator.dart';
import '../models/specialist.dart';
import '../providers/search_providers.dart';
import '../widgets/search/filters.dart';
import '../widgets/search/sorting.dart';
import '../widgets/specialist_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  bool _showSorting = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(searchQueryProvider.notifier).state = _searchController.text;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final isDesktop = MediaQuery.of(context).size.width > 1200;
    final specialistsAsync = ref.watch(filteredSpecialistsProvider);
    final searchStats = ref.watch(searchStatsProvider);
    final hasActiveFilters = ref.watch(hasActiveFiltersProvider);
    final activeFiltersCount = ref.watch(activeFiltersCountProvider);

    return Scaffold(
      appBar: AppNavigator.buildAppBar(
        context,
        title: 'Найди своего специалиста 🎯',
        actions: [
          if (hasActiveFilters)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$activeFiltersCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          IconButton(
            icon: Icon(_showSorting ? Icons.sort : Icons.sort),
            onPressed: () {
              setState(() {
                _showSorting = !_showSorting;
              });
            },
          ),
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск по имени, категории или услугам...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _searchController.clear,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {});
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // Быстрые фильтры
          const QuickFiltersWidget(),

          // Активные фильтры
          const ActiveFiltersWidget(),

          // Статистика поиска
          if (searchStats.totalCount > 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Найдено: ${searchStats.totalCount} специалистов',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  if (searchStats.priceRange != null)
                    Text(
                      'Цена: ${searchStats.priceRange!.minPrice.toInt()} - ${searchStats.priceRange!.maxPrice.toInt()}₽',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),

          // Сортировка
          if (_showSorting) const SearchSortingWidget(showTitle: false),

          // Фильтры
          if (_showFilters) const SearchFiltersWidget(showTitle: false),

          // Список специалистов
          Expanded(
            child: specialistsAsync.when(
              data: (specialists) {
                if (specialists.isEmpty) {
                  return _buildEmptyState();
                }

                return isTablet
                    ? _buildGridLayout(specialists)
                    : _buildListLayout(specialists);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Специалисты не найдены',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить параметры поиска',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(searchControllerProvider).clearFilters();
                _searchController.clear();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Сбросить фильтры'),
            ),
          ],
        ),
      );

  Widget _buildErrorState(String error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: TextStyle(
                fontSize: 18,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Перезагрузить данные
                ref.invalidate(allSpecialistsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      );

  Widget _buildListLayout(List<Specialist> specialists) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: specialists.length,
        itemBuilder: (context, index) {
          final specialist = specialists[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SpecialistCard(
              specialist: specialist,
              onTap: () {
                context.go('/specialist/${specialist.id}');
              },
            ),
          );
        },
      );

  Widget _buildGridLayout(List<Specialist> specialists) => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: specialists.length,
        itemBuilder: (context, index) {
          final specialist = specialists[index];
          return SpecialistCard(
            specialist: specialist,
            onTap: () {
              context.go('/specialist/${specialist.id}');
            },
          );
        },
      );
}
