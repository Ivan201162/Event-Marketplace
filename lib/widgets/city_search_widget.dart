import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/city_region.dart';
import '../providers/city_region_providers.dart';

/// Виджет поиска городов
class CitySearchWidget extends ConsumerStatefulWidget {
  const CitySearchWidget({
    super.key,
    required this.controller,
    this.onSearchChanged,
    this.onCitySelected,
    this.hintText = 'Поиск города...',
    this.showSuggestions = true,
  });

  final TextEditingController controller;
  final Function(String)? onSearchChanged;
  final Function(CityRegion)? onCitySelected;
  final String hintText;
  final bool showSuggestions;

  @override
  ConsumerState<CitySearchWidget> createState() => _CitySearchWidgetState();
}

class _CitySearchWidgetState extends ConsumerState<CitySearchWidget> {
  bool _isSearching = false;
  List<CityRegion> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final query = widget.controller.text;
    setState(() => _isSearching = query.isNotEmpty);

    if (query.isNotEmpty) {
      ref.read(citySearchProvider.notifier).searchCities(query);
    } else {
      ref.read(citySearchProvider.notifier).clearSearch();
    }

    widget.onSearchChanged?.call(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Поисковая строка
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      widget.controller.clear();
                      setState(() => _isSearching = false);
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            filled: true,
            fillColor: theme.cardColor,
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),

        // Результаты поиска или подсказки
        if (widget.showSuggestions) _buildSearchResults(),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (!_isSearching) {
      return _buildQuickSuggestions();
    }

    return Consumer(
      builder: (context, ref, child) {
        final searchState = ref.watch(citySearchProvider);

        return searchState.when(
          data: (cities) => _buildSearchSuggestions(cities),
          loading: () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Ошибка поиска: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickSuggestions() {
    return Consumer(
      builder: (context, ref, child) {
        final popularCitiesState = ref.watch(popularCitiesProvider);

        return popularCitiesState.when(
          data: (cities) => Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Популярные города',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: cities.take(5).length,
                    itemBuilder: (context, index) {
                      final city = cities[index];
                      return _buildCityTile(city);
                    },
                  ),
                ),
              ],
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildSearchSuggestions(List<CityRegion> cities) {
    if (cities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Город не найден',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: cities.length,
        itemBuilder: (context, index) {
          final city = cities[index];
          return _buildCityTile(city);
        },
      ),
    );
  }

  Widget _buildCityTile(CityRegion city) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
        child: Text(
          city.citySize.icon,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      title: Text(
        city.cityName,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            city.regionName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (city.population > 0)
            Text(
              '${_formatPopulation(city.population)} жителей',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      trailing: city.isCapital
          ? Icon(
              Icons.star,
              color: theme.colorScheme.primary,
              size: 20,
            )
          : null,
      onTap: () {
        widget.onCitySelected?.call(city);
        _addToRecentSearches(city);
      },
    );
  }

  void _addToRecentSearches(CityRegion city) {
    setState(() {
      _recentSearches.removeWhere((c) => c.id == city.id);
      _recentSearches.insert(0, city);
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.take(5).toList();
      }
    });
  }

  String _formatPopulation(int population) {
    if (population >= 1000000) {
      return '${(population / 1000000).toStringAsFixed(1)}М';
    } else if (population >= 1000) {
      return '${(population / 1000).toStringAsFixed(0)}К';
    } else {
      return population.toString();
    }
  }
}
