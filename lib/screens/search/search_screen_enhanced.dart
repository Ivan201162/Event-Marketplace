import 'package:event_marketplace_app/models/user.dart' show UserRole;
import 'package:event_marketplace_app/providers/search_providers.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:event_marketplace_app/widgets/specialist_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Улучшенный экран поиска специалистов
class SearchScreenEnhanced extends ConsumerStatefulWidget {
  const SearchScreenEnhanced({super.key});

  @override
  ConsumerState<SearchScreenEnhanced> createState() => _SearchScreenEnhancedState();
}

class _SearchScreenEnhancedState extends ConsumerState<SearchScreenEnhanced> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  String? _selectedCity;
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugLog("SEARCH_OPENED");
    });
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      ref.read(searchQueryProvider.notifier).updateQuery(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final filters = ref.read(searchFiltersProvider);
    ref.read(searchFiltersProvider.notifier)
      ..updateLocation(_selectedCity)
      ..updatePrice(_minPrice, _maxPrice)
      ..updateRating(_minRating);
    
    debugLog("SEARCH_FILTER_APPLIED");
    setState(() => _showFilters = false);
  }

  void _clearFilters() {
    setState(() {
      _selectedCity = null;
      _selectedCategory = null;
      _minPrice = null;
      _maxPrice = null;
      _minRating = null;
    });
    ref.read(searchFiltersProvider.notifier)
      ..updateLocation(null)
      ..updatePrice(null, null)
      ..updateRating(null);
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(filteredSpecialistsProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_showFilters) {
          setState(() => _showFilters = false);
        } else {
          context.go('/main');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Поиск специалистов'),
          actions: [
            IconButton(
              icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
              onPressed: () {
                setState(() => _showFilters = !_showFilters);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Поиск
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск по имени, username...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).clearQuery();
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),

            // Фильтры
            if (_showFilters)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Фильтры', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Сбросить'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Город
                    TextFormField(
                      initialValue: _selectedCity,
                      decoration: const InputDecoration(
                        labelText: 'Город',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => setState(() => _selectedCity = v.isEmpty ? null : v),
                    ),
                    const SizedBox(height: 8),
                    // Рейтинг
                    TextFormField(
                      initialValue: _minRating?.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Мин. рейтинг (1-5)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        setState(() {
                          _minRating = v.isEmpty ? null : double.tryParse(v);
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // Цена
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _minPrice?.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Цена от',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) {
                              setState(() {
                                _minPrice = v.isEmpty ? null : double.tryParse(v);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: _maxPrice?.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Цена до',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) {
                              setState(() {
                                _maxPrice = v.isEmpty ? null : double.tryParse(v);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        child: const Text('Применить'),
                      ),
                    ),
                  ],
                ),
              ),

            // Результаты
            Expanded(
              child: searchResultsAsync.when(
                data: (specialists) {
                  final filteredSpecialists = specialists
                      .where((s) => s.role == UserRole.specialist)
                      .toList();

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    debugLog("SEARCH_RESULT_COUNT:${filteredSpecialists.length}");
                  });

                  if (_searchController.text.trim().isEmpty && 
                      _selectedCity == null && 
                      _minPrice == null && 
                      _maxPrice == null && 
                      _minRating == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Введите имя или используйте фильтр',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (filteredSpecialists.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Ничего не найдено',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredSpecialists.length,
                    itemBuilder: (context, index) {
                      final specialist = filteredSpecialists[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SpecialistCard(
                          specialist: specialist,
                          onTap: () {
                            context.push('/profile/${specialist.userId}');
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
                        onPressed: () {
                          ref.invalidate(filteredSpecialistsProvider);
                        },
                        child: const Text('Попробовать снова'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
