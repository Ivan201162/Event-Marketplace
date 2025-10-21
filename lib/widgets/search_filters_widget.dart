import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/search_filters.dart';
import '../providers/specialist_providers.dart';

/// Widget for search filters
class SearchFiltersWidget extends ConsumerStatefulWidget {
  final SearchFilters initialFilters;
  final Function(SearchFilters) onApplyFilters;

  const SearchFiltersWidget({
    super.key,
    required this.initialFilters,
    required this.onApplyFilters,
  });

  @override
  ConsumerState<SearchFiltersWidget> createState() => _SearchFiltersWidgetState();
}

class _SearchFiltersWidgetState extends ConsumerState<SearchFiltersWidget> {
  late SearchFilters _currentFilters;

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    final specializationsAsync = ref.watch(specializationsProvider);
    final citiesAsync = ref.watch(citiesProvider);
    final servicesAsync = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Фильтры поиска'),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Сбросить'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // City filter
            _buildSectionTitle('Город'),
            citiesAsync.when(
              data: (cities) => _buildCityFilter(cities),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Ошибка загрузки городов'),
            ),
            const SizedBox(height: 20),

            // Specialization filter
            _buildSectionTitle('Специализация'),
            specializationsAsync.when(
              data: (specializations) => _buildSpecializationFilter(specializations),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Ошибка загрузки специализаций'),
            ),
            const SizedBox(height: 20),

            // Rating filter
            _buildSectionTitle('Минимальный рейтинг'),
            _buildRatingFilter(),
            const SizedBox(height: 20),

            // Price range filter
            _buildSectionTitle('Цена за час'),
            _buildPriceRangeFilter(),
            const SizedBox(height: 20),

            // Services filter
            _buildSectionTitle('Услуги'),
            servicesAsync.when(
              data: (services) => _buildServicesFilter(services),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Ошибка загрузки услуг'),
            ),
            const SizedBox(height: 20),

            // Availability filter
            _buildSectionTitle('Доступность'),
            _buildAvailabilityFilter(),
            const SizedBox(height: 20),

            // Sort options
            _buildSectionTitle('Сортировка'),
            _buildSortFilter(),
            const SizedBox(height: 40),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApplyFilters(_currentFilters);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Применить фильтры'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildCityFilter(List<String> cities) {
    return DropdownButtonFormField<String>(
      initialValue: _currentFilters.city,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Выберите город',
      ),
      items: [
        const DropdownMenuItem(
          child: Text('Любой город'),
        ),
        ...cities.map((city) => DropdownMenuItem(
              value: city,
              child: Text(city),
            )),
      ],
      onChanged: (value) {
        setState(() {
          _currentFilters = _currentFilters.copyWith(city: value);
        });
      },
    );
  }

  Widget _buildSpecializationFilter(List<String> specializations) {
    return DropdownButtonFormField<String>(
      initialValue: _currentFilters.specialization,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Выберите специализацию',
      ),
      items: [
        const DropdownMenuItem(
          child: Text('Любая специализация'),
        ),
        ...specializations.map((specialization) => DropdownMenuItem(
              value: specialization,
              child: Text(specialization),
            )),
      ],
      onChanged: (value) {
        setState(() {
          _currentFilters = _currentFilters.copyWith(specialization: value);
        });
      },
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      children: [
        Slider(
          value: _currentFilters.minRating ?? 0.0,
          max: 5,
          divisions: 10,
          label: (_currentFilters.minRating ?? 0.0).toStringAsFixed(1),
          onChanged: (value) {
            setState(() {
              _currentFilters = _currentFilters.copyWith(
                minRating: value == 0 ? null : value,
              );
            });
          },
        ),
        Text(
          'Минимальный рейтинг: ${(_currentFilters.minRating ?? 0.0).toStringAsFixed(1)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _currentFilters.minPrice?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'От (₽)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = int.tryParse(value);
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(
                      minPrice: price,
                    );
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: _currentFilters.maxPrice?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'До (₽)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = int.tryParse(value);
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(
                      maxPrice: price,
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServicesFilter(List<String> services) {
    return Column(
      children: services
          .take(10)
          .map((service) => CheckboxListTile(
                title: Text(service),
                value: _currentFilters.services?.contains(service) ?? false,
                onChanged: (value) {
                  setState(() {
                    final currentServices = _currentFilters.services ?? [];
                    if (value == true) {
                      _currentFilters = _currentFilters.copyWith(
                        services: [...currentServices, service],
                      );
                    } else {
                      _currentFilters = _currentFilters.copyWith(
                        services: currentServices.where((s) => s != service).toList(),
                      );
                    }
                  });
                },
              ))
          .toList(),
    );
  }

  Widget _buildAvailabilityFilter() {
    return Column(
      children: [
        Column(
          children: [
            ListTile(
              title: const Text('Любая'),
              leading: Radio<bool?>(
                value: null,
                groupValue: _currentFilters.isAvailable,
                onChanged: (value) {
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(isAvailable: value);
                  });
                },
              ),
              onTap: () {
                setState(() {
                  _currentFilters = _currentFilters.copyWith(isAvailable: null);
                });
              },
            ),
            ListTile(
              title: const Text('Только доступные'),
              leading: Radio<bool?>(
                value: true,
                groupValue: _currentFilters.isAvailable,
                onChanged: (value) {
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(isAvailable: value);
                  });
                },
              ),
              onTap: () {
                setState(() {
                  _currentFilters = _currentFilters.copyWith(isAvailable: true);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortFilter() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _currentFilters.sortBy ?? 'rating',
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Сортировать по',
          ),
          items: const [
            DropdownMenuItem(value: 'rating', child: Text('Рейтингу')),
            DropdownMenuItem(value: 'price', child: Text('Цене')),
            DropdownMenuItem(value: 'experience', child: Text('Опыту')),
            DropdownMenuItem(value: 'name', child: Text('Имени')),
          ],
          onChanged: (value) {
            setState(() {
              _currentFilters = _currentFilters.copyWith(sortBy: value);
            });
          },
        ),
        const SizedBox(height: 16),
        RadioGroup<bool>(
          value: _currentFilters.sortAscending,
          onChanged: (value) {
            setState(() {
              _currentFilters = _currentFilters.copyWith(sortAscending: value);
            });
          },
          children: [
            ListTile(
              title: const Text('По возрастанию'),
              leading: Radio<bool>(
                value: true,
                groupValue: _currentFilters.sortAscending,
                onChanged: (value) {
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(sortAscending: value);
                  });
                },
              ),
              onTap: () {
                setState(() {
                  _currentFilters = _currentFilters.copyWith(sortAscending: true);
                });
              },
            ),
            ListTile(
              title: const Text('По убыванию'),
              leading: Radio<bool>(
                value: false,
                groupValue: _currentFilters.sortAscending,
                onChanged: (value) {
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(sortAscending: value);
                  });
                },
              ),
              onTap: () {
                setState(() {
                  _currentFilters = _currentFilters.copyWith(sortAscending: false);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _currentFilters = SearchFilters.empty();
    });
  }
}
