import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/advanced_search_filters.dart';
import '../models/city_region.dart';
import '../models/specialist.dart';
import '../providers/city_region_providers.dart';
import 'city_selection_widget.dart';

/// Виджет расширенных фильтров поиска
class AdvancedSearchFiltersWidget extends ConsumerStatefulWidget {
  const AdvancedSearchFiltersWidget({
    super.key,
    required this.filters,
    this.onFiltersChanged,
  });

  final AdvancedSearchFilters filters;
  final Function(AdvancedSearchFilters)? onFiltersChanged;

  @override
  ConsumerState<AdvancedSearchFiltersWidget> createState() => _AdvancedSearchFiltersWidgetState();
}

class _AdvancedSearchFiltersWidgetState extends ConsumerState<AdvancedSearchFiltersWidget> {
  late AdvancedSearchFilters _filters;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _filters = widget.filters;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Индикатор страниц
        Container(
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: PageView.builder(
            controller: _pageController,
            itemCount: 4,
            onPageChanged: (index) {},
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          ),
        ),
        
        // Контент фильтров
        Expanded(
          child: PageView(
            controller: _pageController,
            children: [
              _buildLocationFilters(),
              _buildCategoryFilters(),
              _buildPriceFilters(),
              _buildAdvancedFilters(),
            ],
          ),
        ),
        
        // Кнопки навигации
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildLocationFilters() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Местоположение',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Выбор города
          CitySelectionWidget(
            selectedCity: _filters.selectedCity,
            onCitySelected: (city) => _updateFilters(_filters.copyWith(selectedCity: city)),
            hintText: 'Выберите город',
          ),
          
          const SizedBox(height: 16),
          
          // Радиус поиска
          Text(
            'Радиус поиска: ${_filters.radiusKm.round()} км',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _filters.radiusKm,
            min: 10,
            max: 200,
            divisions: 19,
            label: '${_filters.radiusKm.round()} км',
            onChanged: (value) {
              _updateFilters(_filters.copyWith(radiusKm: value));
            },
          ),
          
          const SizedBox(height: 16),
          
          // Включить соседние города
          SwitchListTile(
            title: const Text('Включить соседние города'),
            subtitle: const Text('Поиск в близлежащих городах'),
            value: _filters.includeNearbyCities,
            onChanged: (value) {
              _updateFilters(_filters.copyWith(includeNearbyCities: value));
            },
          ),
          
          const SizedBox(height: 16),
          
          // Максимальное расстояние
          if (_filters.includeNearbyCities) ...[
            Text(
              'Максимальное расстояние: ${_filters.maxDistance.round()} км',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _filters.maxDistance,
              min: 50,
              max: 500,
              divisions: 18,
              label: '${_filters.maxDistance.round()} км',
              onChanged: (value) {
                _updateFilters(_filters.copyWith(maxDistance: value));
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Категории и услуги',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Категории специалистов
          Text(
            'Категории',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SpecialistCategory.values.map((category) {
              final isSelected = _filters.categories.contains(category);
              return FilterChip(
                label: Text('${category.icon} ${category.displayName}'),
                selected: isSelected,
                onSelected: (selected) {
                  final newCategories = List<SpecialistCategory>.from(_filters.categories);
                  if (selected) {
                    newCategories.add(category);
                  } else {
                    newCategories.remove(category);
                  }
                  _updateFilters(_filters.copyWith(categories: newCategories));
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Подкатегории
          Text(
            'Подкатегории',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          TextField(
            decoration: const InputDecoration(
              hintText: 'Введите подкатегории через запятую',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              final subcategories = value
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              _updateFilters(_filters.copyWith(subcategories: subcategories));
            },
          ),
          
          const SizedBox(height: 24),
          
          // Услуги
          Text(
            'Услуги',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          TextField(
            decoration: const InputDecoration(
              hintText: 'Введите услуги через запятую',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              final services = value
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              _updateFilters(_filters.copyWith(services: services));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPriceFilters() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Цена и опыт',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Ценовой диапазон
          Text(
            'Ценовой диапазон',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          RangeSlider(
            values: RangeValues(_filters.minPrice.toDouble(), _filters.maxPrice.toDouble()),
            min: 0,
            max: 100000,
            divisions: 100,
            labels: RangeLabels(
              '${_filters.minPrice} ₽',
              '${_filters.maxPrice} ₽',
            ),
            onChanged: (values) {
              _updateFilters(_filters.copyWith(
                minPrice: values.start.round(),
                maxPrice: values.end.round(),
              ));
            },
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_filters.minPrice} ₽'),
              Text('${_filters.maxPrice} ₽'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Опыт работы
          Text(
            'Опыт работы',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          RangeSlider(
            values: RangeValues(_filters.minExperience.toDouble(), _filters.maxExperience.toDouble()),
            min: 0,
            max: 50,
            divisions: 50,
            labels: RangeLabels(
              '${_filters.minExperience} лет',
              '${_filters.maxExperience} лет',
            ),
            onChanged: (values) {
              _updateFilters(_filters.copyWith(
                minExperience: values.start.round(),
                maxExperience: values.end.round(),
              ));
            },
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_filters.minExperience} лет'),
              Text('${_filters.maxExperience} лет'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Уровень опыта
          Text(
            'Уровень опыта',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          DropdownButtonFormField<ExperienceLevel>(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<ExperienceLevel>(
                value: null,
                child: Text('Любой уровень'),
              ),
              ...ExperienceLevel.values.map((level) => 
                DropdownMenuItem<ExperienceLevel>(
                  value: level,
                  child: Text(level.displayName),
                ),
              ),
            ],
            value: _filters.experienceLevel,
            onChanged: (level) {
              _updateFilters(_filters.copyWith(experienceLevel: level));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Дополнительные фильтры',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Рейтинг
          Text(
            'Рейтинг: ${_filters.minRating.toStringAsFixed(1)} - ${_filters.maxRating.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          RangeSlider(
            values: RangeValues(_filters.minRating, _filters.maxRating),
            min: 0,
            max: 5,
            divisions: 50,
            labels: RangeLabels(
              _filters.minRating.toStringAsFixed(1),
              _filters.maxRating.toStringAsFixed(1),
            ),
            onChanged: (values) {
              _updateFilters(_filters.copyWith(
                minRating: values.start,
                maxRating: values.end,
              ));
            },
          ),
          
          const SizedBox(height: 24),
          
          // Переключатели
          SwitchListTile(
            title: const Text('Доступен сейчас'),
            subtitle: const Text('Специалист доступен в данный момент'),
            value: _filters.isAvailableNow,
            onChanged: (value) {
              _updateFilters(_filters.copyWith(isAvailableNow: value));
            },
          ),
          
          SwitchListTile(
            title: const Text('Верифицирован'),
            subtitle: const Text('Проверенные специалисты'),
            value: _filters.isVerified,
            onChanged: (value) {
              _updateFilters(_filters.copyWith(isVerified: value));
            },
          ),
          
          SwitchListTile(
            title: const Text('Есть портфолио'),
            subtitle: const Text('С примерами работ'),
            value: _filters.hasPortfolio,
            onChanged: (value) {
              _updateFilters(_filters.copyWith(hasPortfolio: value));
            },
          ),
          
          SwitchListTile(
            title: const Text('Есть отзывы'),
            subtitle: const Text('С отзывами клиентов'),
            value: _filters.hasReviews,
            onChanged: (value) {
              _updateFilters(_filters.copyWith(hasReviews: value));
            },
          ),
          
          const SizedBox(height: 24),
          
          // Сортировка
          Text(
            'Сортировка',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          DropdownButtonFormField<AdvancedSearchSortBy>(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: AdvancedSearchSortBy.values.map((sortBy) => 
              DropdownMenuItem<AdvancedSearchSortBy>(
                value: sortBy,
                child: Text('${sortBy.icon} ${sortBy.displayName}'),
              ),
            ).toList(),
            value: _filters.sortBy,
            onChanged: (sortBy) {
              if (sortBy != null) {
                _updateFilters(_filters.copyWith(sortBy: sortBy));
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Порядок сортировки
          SwitchListTile(
            title: const Text('По возрастанию'),
            subtitle: const Text('Изменить порядок сортировки'),
            value: _filters.sortAscending,
            onChanged: (value) {
              _updateFilters(_filters.copyWith(sortAscending: value));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _previousPage,
              child: const Text('Назад'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _nextPage,
              child: const Text('Далее'),
            ),
          ),
        ],
      ),
    );
  }

  void _previousPage() {
    if (_pageController.page! > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_pageController.page! < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateFilters(AdvancedSearchFilters filters) {
    setState(() {
      _filters = filters;
    });
    widget.onFiltersChanged?.call(filters);
  }
}
