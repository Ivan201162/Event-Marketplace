import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/city_region.dart';
import '../providers/city_region_providers.dart';
import '../widgets/city_search_widget.dart';
import '../widgets/city_list_widget.dart';
import '../widgets/city_map_widget.dart';

/// Экран выбора города с поиском, картой и списком
class CitySelectionScreen extends ConsumerStatefulWidget {
  const CitySelectionScreen({
    super.key,
    this.onCitySelected,
    this.initialCity,
  });

  final Function(CityRegion)? onCitySelected;
  final CityRegion? initialCity;

  @override
  ConsumerState<CitySelectionScreen> createState() =>
      _CitySelectionScreenState();
}

class _CitySelectionScreenState extends ConsumerState<CitySelectionScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  CityRegion? _selectedCity;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedCity = widget.initialCity;

    // Инициализируем данные городов при первом запуске
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(citiesInitializationProvider.future);
    });
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
        title: const Text('Выбор города'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'Поиск'),
            Tab(icon: Icon(Icons.map), text: 'Карта'),
            Tab(icon: Icon(Icons.list), text: 'Список'),
          ],
        ),
        actions: [
          if (_selectedCity != null)
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _getCurrentLocation,
              tooltip: 'Мое местоположение',
            ),
          if (_selectedCity != null)
            TextButton(
              onPressed: _confirmSelection,
              child: const Text('Выбрать'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Поисковая строка
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CitySearchWidget(
              controller: _searchController,
              onSearchChanged: _onSearchChanged,
              onCitySelected: _onCitySelected,
            ),
          ),

          // Выбранный город
          if (_selectedCity != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_city,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedCity!.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedCity = null),
                    iconSize: 20,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Контент вкладок
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSearchTab(),
                _buildMapTab(),
                _buildListTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Consumer(
      builder: (context, ref, child) {
        final searchState = ref.watch(citySearchProvider);
        final popularCitiesState = ref.watch(popularCitiesProvider);

        return Column(
          children: [
            // Результаты поиска
            if (_isSearching)
              Expanded(
                child: searchState.when(
                  data: (cities) => CityListWidget(
                    cities: cities,
                    onCitySelected: _onCitySelected,
                    showDistance: false,
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Ошибка поиска: $error'),
                  ),
                ),
              )
            else
              // Популярные города
              Expanded(
                child: popularCitiesState.when(
                  data: (cities) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Популярные города',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Expanded(
                        child: CityListWidget(
                          cities: cities,
                          onCitySelected: _onCitySelected,
                          showDistance: false,
                        ),
                      ),
                    ],
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Ошибка загрузки: $error'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMapTab() {
    return Consumer(
      builder: (context, ref, child) {
        final currentLocationState = ref.watch(currentLocationProvider);
        final nearbyCitiesState = ref.watch(nearbyCitiesProvider);

        return CityMapWidget(
          selectedCity: _selectedCity,
          onCitySelected: _onCitySelected,
          currentLocation: currentLocationState.valueOrNull,
          nearbyCities: nearbyCitiesState.valueOrNull ?? [],
          onLocationRequested: _getCurrentLocation,
        );
      },
    );
  }

  Widget _buildListTab() {
    return Consumer(
      builder: (context, ref, child) {
        final filteredCitiesState = ref.watch(filteredCitiesProvider);

        return Column(
          children: [
            // Фильтры
            _buildFilters(),

            // Список городов
            Expanded(
              child: filteredCitiesState.when(
                data: (cities) => CityListWidget(
                  cities: cities,
                  onCitySelected: _onCitySelected,
                  showDistance: false,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Ошибка загрузки: $error'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Фильтр по региону
          Consumer(
            builder: (context, ref, child) {
              final regionsState = ref.watch(regionsProvider);

              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Регион',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Все регионы'),
                  ),
                  ...regionsState.valueOrNull?.map(
                        (region) => DropdownMenuItem<String>(
                          value: region,
                          child: Text(region),
                        ),
                      ) ??
                      [],
                ],
                onChanged: (region) {
                  ref
                      .read(filteredCitiesProvider.notifier)
                      .updateRegion(region);
                },
              );
            },
          ),

          const SizedBox(height: 16),

          // Фильтр по размеру города
          DropdownButtonFormField<CitySize>(
            decoration: const InputDecoration(
              labelText: 'Размер города',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<CitySize>(
                value: null,
                child: Text('Все размеры'),
              ),
              ...CitySize.values.map(
                (size) => DropdownMenuItem<CitySize>(
                  value: size,
                  child: Text('${size.icon} ${size.displayName}'),
                ),
              ),
            ],
            onChanged: (size) {
              ref.read(filteredCitiesProvider.notifier).updateCitySize(size);
            },
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() => _isSearching = query.isNotEmpty);

    if (query.isNotEmpty) {
      ref.read(citySearchProvider.notifier).searchCities(query);
    } else {
      ref.read(citySearchProvider.notifier).clearSearch();
    }
  }

  void _onCitySelected(CityRegion city) {
    setState(() => _selectedCity = city);

    // Переключаемся на карту для показа выбранного города
    _tabController.animateTo(1);
  }

  void _getCurrentLocation() async {
    try {
      final location = await ref.read(currentLocationProvider.future);
      if (location != null) {
        // Получаем ближайшие города
        await ref.read(nearbyCitiesProvider.notifier).getNearbyCities(
              latitude: location.latitude,
              longitude: location.longitude,
            );

        // Переключаемся на карту
        _tabController.animateTo(1);
      } else {
        _showLocationError();
      }
    } catch (e) {
      _showLocationError();
    }
  }

  void _showLocationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Не удалось получить ваше местоположение'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _confirmSelection() {
    if (_selectedCity != null) {
      widget.onCitySelected?.call(_selectedCity!);
      Navigator.of(context).pop(_selectedCity);
    }
  }
}
