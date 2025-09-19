import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/search_filters.dart';
import '../providers/advanced_search_providers.dart';

/// Виджет расширенных фильтров поиска
class AdvancedSearchFilters extends ConsumerStatefulWidget {
  const AdvancedSearchFilters({super.key});

  @override
  ConsumerState<AdvancedSearchFilters> createState() =>
      _AdvancedSearchFiltersState();
}

class _AdvancedSearchFiltersState extends ConsumerState<AdvancedSearchFilters> {
  late SpecialistSearchFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = ref.read(searchStateNotifierProvider).filters;
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Фильтры поиска',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Сбросить'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Категории
            _buildCategoryFilter(),
            const SizedBox(height: 16),

            // Услуги
            _buildServiceFilter(),
            const SizedBox(height: 16),

            // Локации
            _buildLocationFilter(),
            const SizedBox(height: 16),

            // Рейтинг
            _buildRatingFilter(),
            const SizedBox(height: 16),

            // Цена
            _buildPriceFilter(),
            const SizedBox(height: 16),

            // Дополнительные фильтры
            _buildAdditionalFilters(),
            const SizedBox(height: 24),

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _applyFilters,
                    child: const Text('Применить'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _searchWithFilters,
                    child: const Text('Найти'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildCategoryFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Категории',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, child) {
              final categoriesAsync = ref.watch(popularCategoriesProvider);
              return categoriesAsync.when(
                data: (categories) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((category) {
                    final isSelected = _filters.categories.contains(category);
                    return FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _filters = _filters.copyWith(
                              categories: [..._filters.categories, category],
                            );
                          } else {
                            _filters = _filters.copyWith(
                              categories: _filters.categories
                                  .where((c) => c != category)
                                  .toList(),
                            );
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Ошибка загрузки категорий'),
              );
            },
          ),
        ],
      );

  Widget _buildServiceFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Услуги', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, child) {
              final servicesAsync = ref.watch(popularServicesProvider);
              return servicesAsync.when(
                data: (services) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: services.map((service) {
                    final isSelected = _filters.services.contains(service);
                    return FilterChip(
                      label: Text(service),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _filters = _filters.copyWith(
                              services: [..._filters.services, service],
                            );
                          } else {
                            _filters = _filters.copyWith(
                              services: _filters.services
                                  .where((s) => s != service)
                                  .toList(),
                            );
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Ошибка загрузки услуг'),
              );
            },
          ),
        ],
      );

  Widget _buildLocationFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Локации', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, child) {
              final locationsAsync = ref.watch(availableLocationsProvider);
              return locationsAsync.when(
                data: (locations) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: locations.map((location) {
                    final isSelected = _filters.locations.contains(location);
                    return FilterChip(
                      label: Text(location),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _filters = _filters.copyWith(
                              locations: [..._filters.locations, location],
                            );
                          } else {
                            _filters = _filters.copyWith(
                              locations: _filters.locations
                                  .where((l) => l != location)
                                  .toList(),
                            );
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Ошибка загрузки локаций'),
              );
            },
          ),
        ],
      );

  Widget _buildRatingFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Рейтинг: ${_filters.minRating.toStringAsFixed(1)} - ${_filters.maxRating.toStringAsFixed(1)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          RangeSlider(
            values: RangeValues(_filters.minRating, _filters.maxRating),
            max: 5,
            divisions: 50,
            onChanged: (values) {
              setState(() {
                _filters = _filters.copyWith(
                  minRating: values.start,
                  maxRating: values.end,
                );
              });
            },
          ),
        ],
      );

  Widget _buildPriceFilter() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Цена: ${_filters.minPrice} - ${_filters.maxPrice} ₽',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          RangeSlider(
            values: RangeValues(
              _filters.minPrice.toDouble(),
              _filters.maxPrice.toDouble(),
            ),
            max: 100000,
            divisions: 100,
            onChanged: (values) {
              setState(() {
                _filters = _filters.copyWith(
                  minPrice: values.start.round(),
                  maxPrice: values.end.round(),
                );
              });
            },
          ),
        ],
      );

  Widget _buildAdditionalFilters() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Дополнительно',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Доступен сейчас'),
                selected: _filters.isAvailableNow,
                onSelected: (selected) {
                  setState(() {
                    _filters = _filters.copyWith(isAvailableNow: selected);
                  });
                },
              ),
              FilterChip(
                label: const Text('Есть портфолио'),
                selected: _filters.hasPortfolio,
                onSelected: (selected) {
                  setState(() {
                    _filters = _filters.copyWith(hasPortfolio: selected);
                  });
                },
              ),
              FilterChip(
                label: const Text('Верифицирован'),
                selected: _filters.isVerified,
                onSelected: (selected) {
                  setState(() {
                    _filters = _filters.copyWith(isVerified: selected);
                  });
                },
              ),
              FilterChip(
                label: const Text('Есть отзывы'),
                selected: _filters.hasReviews,
                onSelected: (selected) {
                  setState(() {
                    _filters = _filters.copyWith(hasReviews: selected);
                  });
                },
              ),
            ],
          ),
        ],
      );

  void _resetFilters() {
    setState(() {
      _filters = const SpecialistSearchFilters();
    });
  }

  void _applyFilters() {
    ref.read(searchStateNotifierProvider.notifier).updateFilters(_filters);
    Navigator.of(context).pop();
  }

  void _searchWithFilters() {
    ref.read(searchStateNotifierProvider.notifier).updateFilters(_filters);
    ref.read(searchStateNotifierProvider.notifier).search();
    Navigator.of(context).pop();
  }
}
