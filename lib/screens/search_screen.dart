import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/specialist_providers.dart';
import '../models/specialist.dart';
import '../widgets/specialist_card.dart';
import '../widgets/search_filters_widget.dart';
import 'specialist_profile_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final searchStats = ref.watch(searchStatsProvider);
    final searchHistory = ref.watch(searchHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Поиск специалистов"),
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
          
          // Статистика поиска
          if (searchStats.hasActiveFilters || searchResults.hasValue)
            _buildSearchStats(searchStats),
          
          // Фильтры
          if (_showFilters) _buildFiltersSection(),
          
          // Результаты поиска
          Expanded(
            child: _buildSearchResults(searchResults, searchHistory),
          ),
        ],
      ),
    );
  }

  /// Построить поисковую строку
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Поиск специалистов...",
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
              if (value.length >= 2) {
                _performSearch();
              }
            },
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                ref.read(searchHistoryProvider.notifier).addToHistory(value);
                _performSearch();
              }
            },
          ),
          
          // История поиска
          if (_searchController.text.isEmpty && ref.watch(searchHistoryProvider).isNotEmpty)
            _buildSearchHistory(),
        ],
      ),
    );
  }

  /// Построить историю поиска
  Widget _buildSearchHistory() {
    final history = ref.watch(searchHistoryProvider);
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: history.length,
        itemBuilder: (context, index) {
          final query = history[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(query),
              onPressed: () {
                _searchController.text = query;
                _performSearch();
              },
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                ref.read(searchHistoryProvider.notifier).removeFromHistory(query);
              },
            ),
          );
        },
      ),
    );
  }

  /// Построить статистику поиска
  Widget _buildSearchStats(SearchStats stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Найдено: ${stats.totalResults} специалистов',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          if (stats.hasActiveFilters)
            TextButton(
              onPressed: () {
                ref.read(specialistFiltersProvider.notifier).state = const SpecialistFilters();
                _performSearch();
              },
              child: const Text('Сбросить фильтры'),
            ),
        ],
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
      child: SearchFiltersWidget(
        onFiltersChanged: (filters) {
          ref.read(specialistFiltersProvider.notifier).state = filters;
          _performSearch();
        },
      ),
    );
  }

  /// Построить результаты поиска
  Widget _buildSearchResults(AsyncValue<List<Specialist>> searchResults, List<String> searchHistory) {
    return searchResults.when(
      data: (specialists) {
        if (specialists.isEmpty) {
          return _buildEmptyState(searchHistory);
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            _performSearch();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: specialists.length,
            itemBuilder: (context, index) {
              final specialist = specialists[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SpecialistCard(
                  specialist: specialist,
                  onTap: () => _navigateToSpecialistProfile(specialist),
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
            Text('Поиск специалистов...'),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка поиска: $error'),
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
  Widget _buildEmptyState(List<String> searchHistory) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Специалисты не найдены',
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
          if (searchHistory.isNotEmpty) ...[
            const Text('Недавние поиски:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: searchHistory.take(5).map((query) {
                return ActionChip(
                  label: Text(query),
                  onPressed: () {
                    _searchController.text = query;
                    _performSearch();
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Выполнить поиск
  void _performSearch() {
    final query = _searchController.text.trim();
    final currentFilters = ref.read(specialistFiltersProvider);
    
    final updatedFilters = currentFilters.copyWith(
      searchQuery: query.isEmpty ? null : query,
    );
    
    ref.read(specialistFiltersProvider.notifier).state = updatedFilters;
    
    if (query.isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).addToHistory(query);
    }
  }

  /// Перейти к профилю специалиста
  void _navigateToSpecialistProfile(Specialist specialist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SpecialistProfileScreen(specialistId: specialist.id),
      ),
    );
  }
}