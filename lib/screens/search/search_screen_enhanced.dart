import 'package:event_marketplace_app/models/search_filters.dart' as search_filters;
import 'package:event_marketplace_app/models/user.dart' show UserRole;
import 'package:event_marketplace_app/providers/search_providers.dart';
import 'package:event_marketplace_app/providers/specialist_providers.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:event_marketplace_app/widgets/specialist_card.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Улучшенный экран поиска специалистов
class SearchScreenEnhanced extends ConsumerStatefulWidget {
  const SearchScreenEnhanced({super.key});

  @override
  ConsumerState<SearchScreenEnhanced> createState() => _SearchScreenEnhancedState();
}

enum SearchState { idle, loading, error, results }

class _SearchScreenEnhancedState extends ConsumerState<SearchScreenEnhanced> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  String? _selectedCity;
  List<String> _selectedCategories = [];
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  int? _minExperience;
  DateTime? _availableDate;
  String? _format; // 'solo' or 'team'
  SearchState _searchState = SearchState.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugLog("SEARCH_OPENED");
      // Firebase Analytics
      FirebaseAnalytics.instance.logEvent(
        name: 'search_opened',
      ).catchError((e) => debugPrint('Analytics error: $e'));
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
    ref.read(searchFiltersProvider.notifier)
      ..updateLocation(_selectedCity)
      ..updatePriceRange(_minPrice, _maxPrice)
      ..updateRating(_minRating);
    if (_selectedCategories.isNotEmpty) {
      ref.read(searchFiltersProvider.notifier).updateCategory(_selectedCategories.first);
    }
    
    debugLog("SEARCH_FILTER_APPLIED");
    
    // Firebase Analytics
    FirebaseAnalytics.instance.logEvent(
      name: 'apply_filter',
      parameters: {
        'city': _selectedCity ?? '',
        'categories_count': _selectedCategories.length,
      },
    ).catchError((e) => debugPrint('Analytics error: $e'));
    setState(() => _showFilters = false);
    // Перезапускаем поиск
    ref.invalidate(filteredSpecialistsProvider);
    ref.refresh(filteredSpecialistsProvider);
  }

  void _clearFilters() {
    setState(() {
      _selectedCity = null;
      _selectedCategories = [];
      _minPrice = null;
      _maxPrice = null;
      _minRating = null;
      _minExperience = null;
      _availableDate = null;
      _format = null;
    });
    ref.read(searchFiltersProvider.notifier)
      ..updateLocation(null)
      ..updatePriceRange(null, null)
      ..updateRating(null);
    ref.invalidate(filteredSpecialistsProvider);
    ref.refresh(filteredSpecialistsProvider);
  }

  void _showSaveFilterDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сохранить фильтр'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Название фильтра',
            hintText: 'Например: Фотографы в Москве',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите название фильтра')),
                );
                return;
              }
              _saveCurrentFilter(name);
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _saveCurrentFilter(String name) {
    final filter = search_filters.SearchFilters(
      city: _selectedCity,
      specialization: _selectedCategories.isNotEmpty ? _selectedCategories.first : null,
      minRating: _minRating,
      minPrice: _minPrice?.toInt(),
      maxPrice: _maxPrice?.toInt(),
    );
    
    ref.read(savedFiltersProvider.notifier).addFilter(filter, name);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Фильтр "$name" сохранён')),
    );
  }

  void _showSavedFilters() {
    final savedFilters = ref.read(savedFiltersProvider);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Сохранённые фильтры',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (savedFilters.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Нет сохранённых фильтров'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                itemCount: savedFilters.length,
                itemBuilder: (context, index) {
                  final filter = savedFilters[index];
                  return ListTile(
                    title: Text('Фильтр ${index + 1}'),
                    subtitle: Text(
                      '${filter.city ?? ''} ${filter.specialization ?? ''}'.trim(),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        // TODO: Удалить фильтр (нужен filterId)
                        Navigator.pop(context);
                      },
                    ),
                    onTap: () {
                      _loadFilter(filter as search_filters.SearchFilters);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _loadFilter(search_filters.SearchFilters filter) {
    setState(() {
      _selectedCity = filter.city;
      _selectedCategories = filter.specialization != null ? [filter.specialization!] : [];
      _minPrice = filter.minPrice?.toDouble();
      _maxPrice = filter.maxPrice?.toDouble();
      _minRating = filter.minRating;
    });
    
    ref.read(searchFiltersProvider.notifier)
      ..updateLocation(filter.city)
      ..updatePriceRange(filter.minPrice?.toDouble(), filter.maxPrice?.toDouble())
      ..updateRating(filter.minRating);
    
    ref.invalidate(filteredSpecialistsProvider);
    ref.refresh(filteredSpecialistsProvider);
    
    debugLog("SEARCH_FILTER_LOADED");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Фильтр загружен')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(filteredSpecialistsProvider);

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_showFilters) {
          setState(() => _showFilters = false);
        } else {
          context.pop(); // Возвращаемся на предыдущий экран
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
                        Row(
                          children: [
                            TextButton(
                              onPressed: _clearFilters,
                              child: const Text('Сбросить'),
                            ),
                            TextButton(
                              onPressed: _showSaveFilterDialog,
                              child: const Text('Сохранить фильтр'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.bookmark),
                              onPressed: _showSavedFilters,
                              tooltip: 'Сохранённые фильтры',
                            ),
                          ],
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
                    // Категории (multi-select)
                    const Text('Категории', style: TextStyle(fontWeight: FontWeight.w500)),
                    Wrap(
                      spacing: 8,
                      children: const [
                        'ведущий', 'диджей', 'фотограф', 'видеограф', 'организатор мероприятий',
                        'аниматор', 'агенство праздников', 'аренда аппаратуры', 'аренда костюмов',
                        'аренда платьев', 'декоратор', 'флорист', 'пиротехник', 'свет',
                        'звукорежиссёр', 'кавер-бэнд', 'музыкант', 'вокалист', 'ведущий аукционов',
                        'тамада', 'сценарист', 'постановщик', 'координатор', 'детский аниматор',
                        'иллюзионист', 'фокусник', 'хореограф', 'хостес', 'промо-персонал'
                      ].map((cat) {
                        return FilterChip(
                          label: Text(cat),
                          selected: _selectedCategories.contains(cat),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(cat);
                              } else {
                                _selectedCategories.remove(cat);
                              }
                            });
                          },
                        );
                      }).toList(),
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
                    // Опыт (лет)
                    TextFormField(
                      initialValue: _minExperience?.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Опыт (лет)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        setState(() {
                          _minExperience = v.isEmpty ? null : int.tryParse(v);
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
                    const SizedBox(height: 8),
                    // Формат (соло/команда)
                    const Text('Формат', style: TextStyle(fontWeight: FontWeight.w500)),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Соло'),
                          selected: _format == 'solo',
                          onSelected: (selected) {
                            setState(() => _format = selected ? 'solo' : null);
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Команда'),
                          selected: _format == 'team',
                          onSelected: (selected) {
                            setState(() => _format = selected ? 'team' : null);
                          },
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
              child: RefreshIndicator(
                onRefresh: () async {
                  try {
                    setState(() => _searchState = SearchState.loading);
                    ref.invalidate(filteredSpecialistsProvider);
                    ref.refresh(filteredSpecialistsProvider);
                    await Future.delayed(const Duration(milliseconds: 500));
                    debugLog("REFRESH_OK:search");
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Обновлено'), duration: Duration(seconds: 1)),
                      );
                    }
                  } catch (e) {
                    debugLog("REFRESH_ERR:search:$e");
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка обновления: $e')),
                      );
                    }
                  }
                },
                child: searchResultsAsync.when(
                data: (specialists) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _searchState = SearchState.results);
                      debugLog("SEARCH_RESULT_COUNT:${specialists.length}");
                      // Firebase Analytics
                      FirebaseAnalytics.instance.logEvent(
                        name: 'search_result',
                        parameters: {'result_count': specialists.length},
                      ).catchError((e) => debugPrint('Analytics error: $e'));
                    }
                  });

                  // Фильтруем только специалистов (role == 'specialist')
                  final filteredSpecialists = specialists.toList();

                  if (_searchController.text.trim().isEmpty && 
                      _selectedCity == null && 
                      _selectedCategories.isEmpty &&
                      _minPrice == null && 
                      _maxPrice == null && 
                      _minRating == null &&
                      _minExperience == null &&
                      _format == null) {
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
                loading: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _searchState = SearchState.loading);
                  });
                  return const Center(child: CircularProgressIndicator());
                },
                error: (error, stack) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _searchState = SearchState.error);
                  });
                  final isFailedPrecondition = error.toString().contains('failed-precondition') ||
                      error.toString().contains('FAILED_PRECONDITION');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Ошибка поиска', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          isFailedPrecondition
                              ? 'Идёт подготовка индексов, попробуйте через минуту'
                              : error.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: _searchState == SearchState.loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh),
                          label: const Text('Попробовать снова'),
                          onPressed: _searchState == SearchState.loading
                              ? null
                              : () {
                                  debugLog("SEARCH_RETRY");
                                  setState(() => _searchState = SearchState.loading);
                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    if (mounted) {
                                      ref.invalidate(filteredSpecialistsProvider);
                                      ref.refresh(filteredSpecialistsProvider);
                                    }
                                  });
                                },
                        ),
                      ],
                    ),
                  );
                },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
