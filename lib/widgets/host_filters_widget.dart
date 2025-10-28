import 'package:event_marketplace_app/providers/hosts_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Виджет фильтров для поиска ведущих
class HostFiltersWidget extends ConsumerStatefulWidget {
  const HostFiltersWidget({required this.onFiltersChanged, super.key});
  final Function(HostFilters) onFiltersChanged;

  @override
  ConsumerState<HostFiltersWidget> createState() => _HostFiltersWidgetState();
}

class _HostFiltersWidgetState extends ConsumerState<HostFiltersWidget> {
  late RangeValues _priceRange;
  late RangeValues _ratingRange;
  String? _selectedCity;
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeFilters() {
    _priceRange = const RangeValues(0, 100000);
    _ratingRange = const RangeValues(1, 5);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final citiesAsync = ref.watch(hostCitiesProvider);
    final priceRangeAsync = ref.watch(hostPriceRangeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок
        Row(
          children: [
            Icon(Icons.filter_list, color: theme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Фильтры поиска',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Поисковый запрос
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Поиск по имени или городу...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (value) => _applyFilters(),
        ),

        const SizedBox(height: 16),

        // Фильтры в сетке
        if (isMobile)
          _buildMobileFilters(theme, citiesAsync, priceRangeAsync)
        else
          _buildDesktopFilters(theme, citiesAsync, priceRangeAsync),

        const SizedBox(height: 16),

        // Кнопки действий
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Сбросить'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _applyFilters,
                icon: const Icon(Icons.search),
                label: const Text('Применить'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileFilters(
    ThemeData theme,
    AsyncValue<List<String>> citiesAsync,
    AsyncValue<Map<String, double>> priceRangeAsync,
  ) =>
      Column(
        children: [
          // Фильтр по цене
          _buildPriceFilter(theme, priceRangeAsync),
          const SizedBox(height: 16),

          // Фильтр по рейтингу
          _buildRatingFilter(theme),
          const SizedBox(height: 16),

          // Фильтр по городу
          _buildCityFilter(theme, citiesAsync),
          const SizedBox(height: 16),

          // Фильтр по дате
          _buildDateFilter(theme),
        ],
      );

  Widget _buildDesktopFilters(
    ThemeData theme,
    AsyncValue<List<String>> citiesAsync,
    AsyncValue<Map<String, double>> priceRangeAsync,
  ) =>
      Row(
        children: [
          // Фильтр по цене
          Expanded(child: _buildPriceFilter(theme, priceRangeAsync)),
          const SizedBox(width: 16),

          // Фильтр по рейтингу
          Expanded(child: _buildRatingFilter(theme)),
          const SizedBox(width: 16),

          // Фильтр по городу
          Expanded(child: _buildCityFilter(theme, citiesAsync)),
          const SizedBox(width: 16),

          // Фильтр по дате
          Expanded(child: _buildDateFilter(theme)),
        ],
      );

  Widget _buildPriceFilter(
          ThemeData theme, AsyncValue<Map<String, double>> priceRangeAsync,) =>
      priceRangeAsync.when(
        data: (priceRange) {
          final minPrice = priceRange['min'] ?? 0;
          final maxPrice = priceRange['max'] ?? 100000;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Цена: ${_priceRange.start.round()}-${_priceRange.end.round()} ₽',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              RangeSlider(
                values: _priceRange,
                min: minPrice,
                max: maxPrice,
                divisions: 20,
                onChanged: (values) {
                  setState(() {
                    _priceRange = values;
                  });
                },
                onChangeEnd: (values) => _applyFilters(),
              ),
            ],
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (_, __) => const Text('Ошибка загрузки цен'),
      );

  Widget _buildRatingFilter(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Рейтинг: ${_ratingRange.start.toStringAsFixed(1)}-${_ratingRange.end.toStringAsFixed(1)}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _ratingRange,
            min: 1,
            max: 5,
            divisions: 40,
            onChanged: (values) {
              setState(() {
                _ratingRange = values;
              });
            },
            onChangeEnd: (values) => _applyFilters(),
          ),
        ],
      );

  Widget _buildCityFilter(
          ThemeData theme, AsyncValue<List<String>> citiesAsync,) =>
      citiesAsync.when(
        data: (cities) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Город',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCity,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Все города'),
              items: [
                const DropdownMenuItem<String>(child: Text('Все города')),
                ...cities.map((city) =>
                    DropdownMenuItem<String>(value: city, child: Text(city)),),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCity = value;
                });
                _applyFilters();
              },
            ),
          ],
        ),
        loading: () => const CircularProgressIndicator(),
        error: (_, __) => const Text('Ошибка загрузки городов'),
      );

  Widget _buildDateFilter(ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Доступная дата',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.5),),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                          : 'Выберите дату',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _selectedDate != null
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  if (_selectedDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                        });
                        _applyFilters();
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      );

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    final filters = HostFilters(
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end,
      minRating: _ratingRange.start,
      maxRating: _ratingRange.end,
      city: _selectedCity,
      availableDate: _selectedDate,
      searchQuery: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
    );

    widget.onFiltersChanged(filters);
  }

  void _clearFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 100000);
      _ratingRange = const RangeValues(1, 5);
      _selectedCity = null;
      _selectedDate = null;
      _searchController.clear();
    });

    widget.onFiltersChanged(const HostFilters());
  }
}
