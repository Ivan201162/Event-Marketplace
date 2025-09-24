import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/advanced_search_filters.dart';
import '../models/city_region.dart';
import '../models/specialist.dart';
import '../providers/city_region_providers.dart';
import '../widgets/advanced_search_filters_widget.dart';
import '../widgets/specialist_search_results_widget.dart';
import '../widgets/city_selection_widget.dart';

/// Экран расширенного поиска специалистов по всей России
class AdvancedSearchScreen extends ConsumerStatefulWidget {
  const AdvancedSearchScreen({
    super.key,
    this.initialFilters,
    this.onSpecialistSelected,
  });

  final AdvancedSearchFilters? initialFilters;
  final Function(Specialist)? onSpecialistSelected;

  @override
  ConsumerState<AdvancedSearchScreen> createState() =>
      _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends ConsumerState<AdvancedSearchScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  AdvancedSearchFilters _filters = const AdvancedSearchFilters();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filters = widget.initialFilters ?? const AdvancedSearchFilters();
    _searchController.text = _filters.searchQuery;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск специалистов'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'Поиск'),
            Tab(icon: Icon(Icons.tune), text: 'Фильтры'),
          ],
        ),
        actions: [
          IconButton(
            icon:
                Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: 'Показать/скрыть фильтры',
          ),
          if (_filters.hasFilters)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Сбросить'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Поисковая строка
          _buildSearchBar(theme),

          // Быстрые фильтры
          if (_showFilters) _buildQuickFilters(),

          // Контент вкладок
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSearchTab(),
                _buildFiltersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Поиск специалистов...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _updateSearchQuery('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          filled: true,
          fillColor: theme.cardColor,
        ),
        onChanged: _updateSearchQuery,
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Выбор города
          Expanded(
            child: CitySelectionWidget(
              selectedCity: _filters.selectedCity,
              onCitySelected: _updateSelectedCity,
              hintText: 'Выберите город',
            ),
          ),

          const SizedBox(width: 8),

          // Категории
          Expanded(
            child: _buildCategoryFilter(),
          ),

          const SizedBox(width: 8),

          // Цена
          Expanded(
            child: _buildPriceFilter(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return DropdownButtonFormField<SpecialistCategory>(
      decoration: const InputDecoration(
        labelText: 'Категория',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<SpecialistCategory>(
          value: null,
          child: Text('Все категории'),
        ),
        ...SpecialistCategory.values.map(
          (category) => DropdownMenuItem<SpecialistCategory>(
            value: category,
            child: Text('${category.icon} ${category.displayName}'),
          ),
        ),
      ],
      onChanged: (category) {
        _updateCategories(category != null ? [category] : []);
      },
    );
  }

  Widget _buildPriceFilter() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Цена',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem<String>(
          value: null,
          child: Text('Любая'),
        ),
        DropdownMenuItem<String>(
          value: '0-5000',
          child: Text('До 5 000 ₽'),
        ),
        DropdownMenuItem<String>(
          value: '5000-15000',
          child: Text('5 000 - 15 000 ₽'),
        ),
        DropdownMenuItem<String>(
          value: '15000-30000',
          child: Text('15 000 - 30 000 ₽'),
        ),
        DropdownMenuItem<String>(
          value: '30000+',
          child: Text('От 30 000 ₽'),
        ),
      ],
      onChanged: (priceRange) {
        _updatePriceRange(priceRange);
      },
    );
  }

  Widget _buildSearchTab() {
    return SpecialistSearchResultsWidget(
      filters: _filters,
      onSpecialistSelected: widget.onSpecialistSelected,
      onFiltersChanged: _updateFilters,
    );
  }

  Widget _buildFiltersTab() {
    return AdvancedSearchFiltersWidget(
      filters: _filters,
      onFiltersChanged: _updateFilters,
    );
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _filters = _filters.copyWith(searchQuery: query);
    });
  }

  void _updateSelectedCity(CityRegion? city) {
    setState(() {
      _filters = _filters.copyWith(selectedCity: city);
    });
  }

  void _updateCategories(List<SpecialistCategory> categories) {
    setState(() {
      _filters = _filters.copyWith(categories: categories);
    });
  }

  void _updatePriceRange(String? priceRange) {
    if (priceRange == null) {
      setState(() {
        _filters = _filters.copyWith(minPrice: 0, maxPrice: 100000);
      });
      return;
    }

    int minPrice = 0;
    int maxPrice = 100000;

    switch (priceRange) {
      case '0-5000':
        minPrice = 0;
        maxPrice = 5000;
        break;
      case '5000-15000':
        minPrice = 5000;
        maxPrice = 15000;
        break;
      case '15000-30000':
        minPrice = 15000;
        maxPrice = 30000;
        break;
      case '30000+':
        minPrice = 30000;
        maxPrice = 100000;
        break;
    }

    setState(() {
      _filters = _filters.copyWith(minPrice: minPrice, maxPrice: maxPrice);
    });
  }

  void _updateFilters(AdvancedSearchFilters filters) {
    setState(() {
      _filters = filters;
    });
  }

  void _clearFilters() {
    setState(() {
      _filters = const AdvancedSearchFilters();
      _searchController.clear();
    });
  }

  void _performSearch(String query) {
    // Поиск уже выполняется автоматически при изменении фильтров
  }
}

/// Виджет выбора города для быстрых фильтров
class CitySelectionWidget extends StatelessWidget {
  const CitySelectionWidget({
    super.key,
    this.selectedCity,
    this.onCitySelected,
    this.hintText = 'Выберите город',
  });

  final CityRegion? selectedCity;
  final Function(CityRegion?)? onCitySelected;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCitySelection(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_city,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedCity?.cityName ?? hintText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selectedCity != null
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showCitySelection(BuildContext context) async {
    final selectedCity = await Navigator.of(context).push<CityRegion>(
      MaterialPageRoute(
        builder: (context) => const CitySelectionScreen(),
      ),
    );

    if (selectedCity != null) {
      onCitySelected?.call(selectedCity);
    }
  }
}
