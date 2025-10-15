import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/specialists/specialists_filters_widget.dart';
import '../widgets/specialists/specialists_list_widget.dart';
import '../widgets/specialists/specialists_search_widget.dart';
import '../widgets/specialists/specialists_sort_widget.dart';

/// Экран каталога специалистов
class SpecialistsScreen extends ConsumerStatefulWidget {
  const SpecialistsScreen({super.key});

  @override
  ConsumerState<SpecialistsScreen> createState() => _SpecialistsScreenState();
}

class _SpecialistsScreenState extends ConsumerState<SpecialistsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Все';
  String _selectedCity = 'Все города';
  String _sortBy = 'Рейтинг';
  double _minPrice = 0;
  double _maxPrice = 100000;
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Специалисты'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_outlined),
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
          // Поиск
          SpecialistsSearchWidget(
            controller: _searchController,
            onSearchChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
          ),

          // Фильтры (если показаны)
          if (_showFilters)
            SpecialistsFiltersWidget(
              selectedCategory: _selectedCategory,
              selectedCity: _selectedCity,
              minPrice: _minPrice,
              maxPrice: _maxPrice,
              onCategoryChanged: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              onCityChanged: (city) {
                setState(() {
                  _selectedCity = city;
                });
              },
              onPriceRangeChanged: (min, max) {
                setState(() {
                  _minPrice = min;
                  _maxPrice = max;
                });
              },
            ),

          // Сортировка
          SpecialistsSortWidget(
            selectedSort: _sortBy,
            onSortChanged: (sort) {
              setState(() {
                _sortBy = sort;
              });
            },
          ),

          // Список специалистов
          Expanded(
            child: SpecialistsListWidget(
              searchQuery: _searchQuery,
              category: _selectedCategory,
              city: _selectedCity,
              sortBy: _sortBy,
              minPrice: _minPrice,
              maxPrice: _maxPrice,
              onSpecialistTap: (specialistId) {
                context.push('/specialist/$specialistId');
              },
            ),
          ),
        ],
      ),
    );
  }
}