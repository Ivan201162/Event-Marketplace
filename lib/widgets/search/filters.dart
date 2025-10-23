import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/specialist_filters.dart';
import '../../providers/search_providers.dart';

class SearchFiltersWidget extends ConsumerStatefulWidget {
  const SearchFiltersWidget(
      {super.key, this.onFiltersChanged, this.showTitle = true});
  final VoidCallback? onFiltersChanged;
  final bool showTitle;

  @override
  ConsumerState<SearchFiltersWidget> createState() =>
      _SearchFiltersWidgetState();
}

class _SearchFiltersWidgetState extends ConsumerState<SearchFiltersWidget> {
  late SpecialistFilters _currentFilters;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentFilters = ref.read(searchFiltersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = ref.watch(hasActiveFiltersProvider);
    final activeFiltersCount = ref.watch(activeFiltersCountProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Заголовок с кнопкой развернуть/свернуть
          ListTile(
            leading: const Icon(Icons.filter_list),
            title: widget.showTitle ? const Text('Фильтры') : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasActiveFilters) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon:
                      Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),

          // Содержимое фильтров
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCategoryFilter(),
                  const SizedBox(height: 16),
                  _buildPriceFilter(),
                  const SizedBox(height: 16),
                  _buildRatingFilter(),
                  const SizedBox(height: 16),
                  _buildCityFilter(),
                  const SizedBox(height: 16),
                  _buildDateFilter(),
                  const SizedBox(height: 16),
                  _buildVerificationFilter(),
                  const SizedBox(height: 16),
                  _buildAvailabilityFilter(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ref.watch(specialistCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Категория',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected = _currentFilters.subcategories.contains(category);
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _currentFilters = _currentFilters.copyWith(
                      subcategories: [
                        ..._currentFilters.subcategories,
                        category
                      ],
                    );
                  } else {
                    _currentFilters = _currentFilters.copyWith(
                      subcategories: _currentFilters.subcategories
                          .where((cat) => cat != category)
                          .toList(),
                    );
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Цена за час',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'От',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final price = double.tryParse(value);
                    if (price != null) {
                      setState(() {
                        _currentFilters =
                            _currentFilters.copyWith(minPrice: price);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'До',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final price = double.tryParse(value);
                    if (price != null) {
                      setState(() {
                        _currentFilters =
                            _currentFilters.copyWith(maxPrice: price);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Быстрые опции цены
          Wrap(
            spacing: 8,
            children: [
              _buildQuickPriceOption('До 5 000₽', null, 5000),
              _buildQuickPriceOption('5 000 - 15 000₽', 5000, 15000),
              _buildQuickPriceOption('15 000 - 30 000₽', 15000, 30000),
              _buildQuickPriceOption('От 30 000₽', 30000, null),
            ],
          ),
        ],
      );

  Widget _buildQuickPriceOption(
      String label, double? minPrice, double? maxPrice) {
    final isSelected = _currentFilters.minPrice == minPrice &&
        _currentFilters.maxPrice == maxPrice;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _currentFilters = _currentFilters.copyWith(
            minPrice: selected ? minPrice : null,
            maxPrice: selected ? maxPrice : null,
          );
        });
      },
    );
  }

  Widget _buildRatingFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Минимальный рейтинг',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _currentFilters.minRating ?? 0.0,
            max: 5,
            divisions: 50,
            label: (_currentFilters.minRating ?? 0.0).toStringAsFixed(1),
            onChanged: (value) {
              setState(() {
                _currentFilters = _currentFilters.copyWith(minRating: value);
              });
            },
          ),
          const SizedBox(height: 8),
          // Быстрые опции рейтинга
          Wrap(
            spacing: 8,
            children: [
              _buildQuickRatingOption('4.5+', 4.5),
              _buildQuickRatingOption('4.0+', 4),
              _buildQuickRatingOption('3.5+', 3.5),
              _buildQuickRatingOption('3.0+', 3),
            ],
          ),
        ],
      );

  Widget _buildQuickRatingOption(String label, double rating) {
    final isSelected = _currentFilters.minRating == rating;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _currentFilters =
              _currentFilters.copyWith(minRating: selected ? rating : null);
        });
      },
    );
  }

  Widget _buildCityFilter() {
    final citiesAsync = ref.watch(citiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Город',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _currentFilters.city,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            hintText: 'Выберите город',
          ),
          items: [
            const DropdownMenuItem<String>(child: Text('Все города')),
            ...citiesAsync.map((city) =>
                DropdownMenuItem<String>(value: city, child: Text(city))),
          ],
          onChanged: (value) {
            setState(() {
              _currentFilters = _currentFilters.copyWith(city: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Доступная дата',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _currentFilters.availableDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  _currentFilters =
                      _currentFilters.copyWith(availableDate: date);
                });
              }
            },
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
                    _currentFilters.availableDate != null
                        ? '${_currentFilters.availableDate!.day}.${_currentFilters.availableDate!.month}.${_currentFilters.availableDate!.year}'
                        : 'Выберите дату',
                    style: TextStyle(
                      color: _currentFilters.availableDate != null
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  if (_currentFilters.availableDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          _currentFilters = _currentFilters.copyWith();
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildVerificationFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Верификация',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilterChip(
                  label: const Text('Только верифицированные'),
                  selected: _currentFilters.isVerified ?? false,
                  onSelected: (selected) {
                    setState(() {
                      _currentFilters = _currentFilters.copyWith(
                          isVerified: selected ? true : null);
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildAvailabilityFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Доступность',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilterChip(
                  label: const Text('Только доступные'),
                  selected: _currentFilters.isAvailable ?? false,
                  onSelected: (selected) {
                    setState(() {
                      _currentFilters = _currentFilters.copyWith(
                          isAvailable: selected ? true : null);
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildActionButtons() => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Сбросить'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _applyFilters,
              icon: const Icon(Icons.search),
              label: const Text('Применить'),
            ),
          ),
        ],
      );

  void _applyFilters() {
    ref.read(searchFiltersProvider.notifier).updateFilters(_currentFilters);
    widget.onFiltersChanged?.call();
  }

  void _clearFilters() {
    setState(() {
      _currentFilters = const SpecialistFilters();
    });
    ref.read(searchFiltersProvider.notifier).updateFilters(_currentFilters);
    widget.onFiltersChanged?.call();
  }
}

/// Виджет для быстрого доступа к фильтрам
class QuickFiltersWidget extends ConsumerWidget {
  const QuickFiltersWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildQuickFilter(
              context,
              ref,
              'Высокий рейтинг',
              Icons.star,
              () => ref.read(searchFiltersProvider.notifier).updateFilters(
                  ref.read(searchFiltersProvider).copyWith(minRating: 4.5)),
            ),
            const SizedBox(width: 8),
            _buildQuickFilter(
              context,
              ref,
              'До 10 000₽',
              Icons.attach_money,
              () => ref.read(searchFiltersProvider.notifier).updateFilters(
                  ref.read(searchFiltersProvider).copyWith(maxPrice: 10000)),
            ),
            const SizedBox(width: 8),
            _buildQuickFilter(
              context,
              ref,
              'Верифицированные',
              Icons.verified,
              () => ref.read(searchFiltersProvider.notifier).updateFilters(
                  ref.read(searchFiltersProvider).copyWith(isVerified: true)),
            ),
            const SizedBox(width: 8),
            _buildQuickFilter(
              context,
              ref,
              'Доступные',
              Icons.check_circle,
              () => ref.read(searchFiltersProvider.notifier).updateFilters(
                  ref.read(searchFiltersProvider).copyWith(isAvailable: true)),
            ),
          ],
        ),
      );

  Widget _buildQuickFilter(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) =>
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
}

/// Виджет для отображения активных фильтров
class ActiveFiltersWidget extends ConsumerWidget {
  const ActiveFiltersWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(searchFiltersProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    final activeFilters = <Widget>[];

    // Поисковый запрос
    if (searchQuery.isNotEmpty) {
      activeFilters.add(
        _buildFilterChip(
          'Поиск: "$searchQuery"',
          Icons.search,
          () => ref.read(searchQueryProvider.notifier).updateQuery(''),
        ),
      );
    }

    // Цена
    if (filters.minPrice != null || filters.maxPrice != null) {
      var priceText = '';
      if (filters.minPrice != null && filters.maxPrice != null) {
        priceText =
            '${filters.minPrice!.toInt()} - ${filters.maxPrice!.toInt()}₽';
      } else if (filters.minPrice != null) {
        priceText = 'От ${filters.minPrice!.toInt()}₽';
      } else if (filters.maxPrice != null) {
        priceText = 'До ${filters.maxPrice!.toInt()}₽';
      }

      activeFilters.add(
        _buildFilterChip(
          priceText,
          Icons.attach_money,
          () => ref
              .read(searchFiltersProvider.notifier)
              .updateFilters(filters.copyWith()),
        ),
      );
    }

    // Рейтинг
    if (filters.minRating != null) {
      activeFilters.add(
        _buildFilterChip(
          'Рейтинг ${filters.minRating!.toStringAsFixed(1)}+',
          Icons.star,
          () => ref
              .read(searchFiltersProvider.notifier)
              .updateFilters(filters.copyWith()),
        ),
      );
    }

    // Город
    if (filters.location != null && filters.location!.isNotEmpty) {
      activeFilters.add(
        _buildFilterChip(
          filters.location!,
          Icons.location_on,
          () => ref.read(searchFiltersProvider.notifier).updateLocation(null),
        ),
      );
    }

    // Подкатегории
    for (final subcategory in filters.subcategories) {
      activeFilters.add(
        _buildFilterChip(subcategory, Icons.category, () {
          final newSubcategories =
              filters.subcategories.where((cat) => cat != subcategory).toList();
          ref
              .read(searchFiltersProvider.notifier)
              .updateFilters(filters.copyWith(subcategories: newSubcategories));
        }),
      );
    }

    // Верификация
    if (filters.isVerified ?? false) {
      activeFilters.add(
        _buildFilterChip(
          'Верифицированные',
          Icons.verified,
          () => ref
              .read(searchFiltersProvider.notifier)
              .updateFilters(filters.copyWith()),
        ),
      );
    }

    // Доступность
    if (filters.isAvailable ?? false) {
      activeFilters.add(
        _buildFilterChip(
          'Доступные',
          Icons.check_circle,
          () => ref
              .read(searchFiltersProvider.notifier)
              .updateFilters(filters.copyWith()),
        ),
      );
    }

    // Дата
    if (filters.availableDate != null) {
      final date = filters.availableDate!;
      activeFilters.add(
        _buildFilterChip(
          '${date.day}.${date.month}.${date.year}',
          Icons.calendar_today,
          () => ref
              .read(searchFiltersProvider.notifier)
              .updateFilters(filters.copyWith()),
        ),
      );
    }

    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Активные фильтры:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  ref.read(searchFiltersProvider.notifier).clearFilters();
                  ref.read(searchQueryProvider.notifier).clearQuery();
                },
                child: const Text('Очистить все'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: activeFilters),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, VoidCallback onRemove) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.blue.shade700),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close, size: 14, color: Colors.blue.shade700),
            ),
          ],
        ),
      );
}
