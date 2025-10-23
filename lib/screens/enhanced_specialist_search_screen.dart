import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist.dart';
import '../providers/specialist_providers.dart';
import '../widgets/specialist_card.dart';
import 'specialist_profile_screen.dart';

/// Улучшенный экран поиска специалистов с полным функционалом
class EnhancedSpecialistSearchScreen extends ConsumerStatefulWidget {
  const EnhancedSpecialistSearchScreen({super.key});

  @override
  ConsumerState<EnhancedSpecialistSearchScreen> createState() =>
      _EnhancedSpecialistSearchScreenState();
}

class _EnhancedSpecialistSearchScreenState
    extends ConsumerState<EnhancedSpecialistSearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  bool _showFilters = false;
  String _searchQuery = '';

  // Фильтры
  SpecialistCategory? _selectedCategory;
  ExperienceLevel? _selectedExperience;
  double _minPrice = 0;
  double _maxPrice = 10000;
  double _minRating = 0;
  String? _selectedLocation;
  DateTime? _selectedDate;
  SpecialistSorting _sorting = SpecialistSorting.rating;

  // Быстрые фильтры
  final Set<SpecialistCategory> _quickFilters = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Поиск специалистов'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list),
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Все специалисты'),
              Tab(text: 'Быстрые фильтры'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Поисковая строка
            _buildSearchBar(),

            // Фильтры
            if (_showFilters) _buildFiltersSection(),

            // Быстрые фильтры
            if (_tabController.index == 1) _buildQuickFilters(),

            // Результаты
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildAllSpecialistsTab(), _buildQuickFiltersTab()],
              ),
            ),
          ],
        ),
      );

  /// Построить поисковую строку
  Widget _buildSearchBar() => Container(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Поиск по имени, городу, категории...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      );

  /// Построить секцию фильтров
  Widget _buildFiltersSection() => Container(
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
                Text(
                  'Фильтры',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                    onPressed: _clearFilters, child: const Text('Сбросить')),
              ],
            ),
            const SizedBox(height: 16),

            // Фильтр по категории
            _buildCategoryFilter(),

            const SizedBox(height: 16),

            // Фильтр по цене
            _buildPriceFilter(),

            const SizedBox(height: 16),

            // Фильтр по рейтингу
            _buildRatingFilter(),

            const SizedBox(height: 16),

            // Фильтр по опыту
            _buildExperienceFilter(),

            const SizedBox(height: 16),

            // Фильтр по дате
            _buildDateFilter(),

            const SizedBox(height: 16),

            // Сортировка
            _buildSortingFilter(),
          ],
        ),
      );

  /// Построить фильтр по категории
  Widget _buildCategoryFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Категория', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<SpecialistCategory?>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), isDense: true),
            hint: const Text('Все категории'),
            items: [
              const DropdownMenuItem<SpecialistCategory?>(
                  child: Text('Все категории')),
              ...SpecialistCategory.values.map(
                (category) => DropdownMenuItem<SpecialistCategory?>(
                  value: category,
                  child: Row(
                    children: [
                      Text(category.icon),
                      const SizedBox(width: 8),
                      Text(category.displayName),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
          ),
        ],
      );

  /// Построить фильтр по цене
  Widget _buildPriceFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Цена за час', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue:
                      _minPrice > 0 ? _minPrice.toInt().toString() : '',
                  decoration: const InputDecoration(
                    labelText: 'От',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _minPrice = double.tryParse(value) ?? 0;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue:
                      _maxPrice < 10000 ? _maxPrice.toInt().toString() : '',
                  decoration: const InputDecoration(
                    labelText: 'До',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _maxPrice = double.tryParse(value) ?? 10000;
                  },
                ),
              ),
            ],
          ),
        ],
      );

  /// Построить фильтр по рейтингу
  Widget _buildRatingFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Минимальный рейтинг',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (index) => IconButton(
                icon: Icon(Icons.star,
                    color:
                        index < _minRating ? Colors.amber : Colors.grey[300]),
                onPressed: () {
                  setState(() {
                    _minRating = index + 1.0;
                  });
                },
              ),
            ),
          ),
        ],
      );

  /// Построить фильтр по опыту
  Widget _buildExperienceFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Уровень опыта', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ExperienceLevel.values
                .map(
                  (level) => FilterChip(
                    label: Text(level.displayName),
                    selected: _selectedExperience == level,
                    onSelected: (selected) {
                      setState(() {
                        _selectedExperience = selected ? level : null;
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ],
      );

  /// Построить фильтр по дате
  Widget _buildDateFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Доступная дата', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                        : 'Выберите дату',
                  ),
                  if (_selectedDate != null) ...[
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );

  /// Построить фильтр сортировки
  Widget _buildSortingFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Сортировка', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<SpecialistSorting>(
            initialValue: _sorting,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), isDense: true),
            items: SpecialistSorting.values
                .map(
                  (sorting) => DropdownMenuItem<SpecialistSorting>(
                    value: sorting,
                    child: Text(sorting.displayName),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _sorting = value;
                });
              }
            },
          ),
        ],
      );

  /// Построить быстрые фильтры
  Widget _buildQuickFilters() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          border: Border(
            top: BorderSide(color: Colors.blue[200]!),
            bottom: BorderSide(color: Colors.blue[200]!),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Популярные категории',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickFilterChip(
                    SpecialistCategory.photographer, '📸 Фотографы'),
                _buildQuickFilterChip(
                    SpecialistCategory.videographer, '🎥 Видеографы'),
                _buildQuickFilterChip(SpecialistCategory.host, '🎤 Ведущие'),
                _buildQuickFilterChip(SpecialistCategory.dj, '🎧 DJ'),
                _buildQuickFilterChip(
                    SpecialistCategory.decorator, '🎈 Декораторы'),
                _buildQuickFilterChip(
                    SpecialistCategory.musician, '🎵 Музыканты'),
                _buildQuickFilterChip(
                    SpecialistCategory.animator, '🎭 Аниматоры'),
                _buildQuickFilterChip(
                    SpecialistCategory.florist, '🌸 Флористы'),
              ],
            ),
          ],
        ),
      );

  /// Построить чип быстрого фильтра
  Widget _buildQuickFilterChip(SpecialistCategory category, String label) =>
      FilterChip(
        label: Text(label),
        selected: _quickFilters.contains(category),
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _quickFilters.add(category);
            } else {
              _quickFilters.remove(category);
            }
          });
        },
      );

  /// Построить вкладку всех специалистов
  Widget _buildAllSpecialistsTab() {
    final specialistsAsync = ref.watch(allSpecialistsProvider);

    return specialistsAsync.when(
      data: (specialists) {
        final filteredSpecialists = _filterAndSortSpecialists(specialists);

        if (filteredSpecialists.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allSpecialistsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredSpecialists.length,
            itemBuilder: (context, index) {
              final specialist = filteredSpecialists[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  curve: Curves.easeInOut,
                  child: FadeTransition(
                    opacity: const AlwaysStoppedAnimation(1),
                    child: SlideTransition(
                      position: const AlwaysStoppedAnimation(Offset.zero),
                      child: SpecialistCard(
                        specialist: specialist,
                        onTap: () => _navigateToSpecialistProfile(specialist),
                      ),
                    ),
                  ),
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
            Text('Загрузка специалистов...'),
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
              onPressed: () {
                ref.invalidate(allSpecialistsProvider);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  /// Построить вкладку быстрых фильтров
  Widget _buildQuickFiltersTab() {
    if (_quickFilters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Выберите категории для фильтрации',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text('Используйте быстрые фильтры выше',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    final specialistsAsync = ref.watch(allSpecialistsProvider);

    return specialistsAsync.when(
      data: (specialists) {
        final filteredSpecialists = specialists
            .where((specialist) => _quickFilters.contains(specialist.category))
            .toList();

        if (filteredSpecialists.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allSpecialistsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredSpecialists.length,
            itemBuilder: (context, index) {
              final specialist = filteredSpecialists[index];
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Ошибка загрузки: $error')),
    );
  }

  /// Построить пустое состояние
  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty || _hasActiveFilters()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Нет специалистов по запросу',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить поисковый запрос или фильтры',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: _clearFilters,
                child: const Text('Очистить фильтры')),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Начните поиск специалистов',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Используйте поисковую строку или фильтры',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// Фильтровать и сортировать специалистов
  List<Specialist> _filterAndSortSpecialists(List<Specialist> specialists) {
    final filtered = specialists.where((specialist) {
      // Фильтр по поисковому запросу
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final matchesName = specialist.name.toLowerCase().contains(searchLower);
        final matchesDescription =
            specialist.description?.toLowerCase().contains(searchLower) ??
                false;
        final matchesCategory =
            specialist.category.displayName.toLowerCase().contains(searchLower);
        final matchesLocation =
            specialist.location?.toLowerCase().contains(searchLower) ?? false;

        if (!matchesName &&
            !matchesDescription &&
            !matchesCategory &&
            !matchesLocation) {
          return false;
        }
      }

      // Фильтр по категории
      if (_selectedCategory != null &&
          specialist.category != _selectedCategory) {
        return false;
      }

      // Фильтр по цене
      if (specialist.price < _minPrice || specialist.price > _maxPrice) {
        return false;
      }

      // Фильтр по рейтингу
      if (specialist.rating < _minRating) {
        return false;
      }

      // Фильтр по опыту
      if (_selectedExperience != null &&
          specialist.experienceLevel != _selectedExperience) {
        return false;
      }

      // Фильтр по дате (упрощенная проверка)
      if (_selectedDate != null) {
        // TODO: Реализовать проверку доступности по дате
        // Пока возвращаем true для всех
      }

      return true;
    }).toList();

    // Сортировка
    switch (_sorting) {
      case SpecialistSorting.rating:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SpecialistSorting.priceAsc:
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SpecialistSorting.priceDesc:
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SpecialistSorting.experience:
        filtered
            .sort((a, b) => b.yearsOfExperience.compareTo(a.yearsOfExperience));
        break;
      case SpecialistSorting.reviews:
        filtered.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
    }

    return filtered;
  }

  /// Проверить наличие активных фильтров
  bool _hasActiveFilters() =>
      _selectedCategory != null ||
      _selectedExperience != null ||
      _minPrice > 0 ||
      _maxPrice < 10000 ||
      _minRating > 0 ||
      _selectedDate != null;

  /// Очистить все фильтры
  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedExperience = null;
      _minPrice = 0;
      _maxPrice = 10000;
      _minRating = 0;
      _selectedLocation = null;
      _selectedDate = null;
      _quickFilters.clear();
      _searchQuery = '';
      _searchController.clear();
    });
  }

  /// Выбрать дату
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  /// Перейти к профилю специалиста
  void _navigateToSpecialistProfile(Specialist specialist) {
    Navigator.of(context).push(
      MaterialPageRoute<SpecialistProfileScreen>(
        builder: (context) =>
            SpecialistProfileScreen(specialistId: specialist.id),
      ),
    );
  }
}

/// Типы сортировки специалистов
enum SpecialistSorting { rating, priceAsc, priceDesc, experience, reviews }

extension SpecialistSortingExtension on SpecialistSorting {
  String get displayName {
    switch (this) {
      case SpecialistSorting.rating:
        return 'По рейтингу';
      case SpecialistSorting.priceAsc:
        return 'По цене (возрастание)';
      case SpecialistSorting.priceDesc:
        return 'По цене (убывание)';
      case SpecialistSorting.experience:
        return 'По опыту';
      case SpecialistSorting.reviews:
        return 'По количеству отзывов';
    }
  }
}
