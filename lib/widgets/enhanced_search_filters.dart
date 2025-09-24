import 'package:flutter/material.dart';

import '../models/enhanced_specialist_category.dart';
import '../services/enhanced_search_service.dart';

/// Виджет расширенных фильтров поиска
class EnhancedSearchFilters extends StatefulWidget {
  const EnhancedSearchFilters({
    super.key,
    required this.selectedCategories,
    this.selectedLocation,
    this.minPrice,
    this.maxPrice,
    this.availableFrom,
    this.availableTo,
    this.minRating,
    required this.sortBy,
    required this.onCategoriesChanged,
    required this.onLocationChanged,
    required this.onPriceRangeChanged,
    required this.onAvailabilityChanged,
    required this.onRatingChanged,
    required this.onSortChanged,
  });

  final List<EnhancedSpecialistCategory> selectedCategories;
  final String? selectedLocation;
  final double? minPrice;
  final double? maxPrice;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final double? minRating;
  final SearchSortOption sortBy;
  final Function(List<EnhancedSpecialistCategory>) onCategoriesChanged;
  final Function(String?) onLocationChanged;
  final Function(double?, double?) onPriceRangeChanged;
  final Function(DateTime?, DateTime?) onAvailabilityChanged;
  final Function(double?) onRatingChanged;
  final Function(SearchSortOption) onSortChanged;

  @override
  State<EnhancedSearchFilters> createState() => _EnhancedSearchFiltersState();
}

class _EnhancedSearchFiltersState extends State<EnhancedSearchFilters> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _locationController.text = widget.selectedLocation ?? '';
    _minPriceController.text = widget.minPrice?.toString() ?? '';
    _maxPriceController.text = widget.maxPrice?.toString() ?? '';
  }

  @override
  void dispose() {
    _locationController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Категории
        _buildCategoriesSection(theme),
        const SizedBox(height: 16),
        
        // Местоположение
        _buildLocationSection(theme),
        const SizedBox(height: 16),
        
        // Ценовой диапазон
        _buildPriceRangeSection(theme),
        const SizedBox(height: 16),
        
        // Доступность
        _buildAvailabilitySection(theme),
        const SizedBox(height: 16),
        
        // Рейтинг
        _buildRatingSection(theme),
        const SizedBox(height: 16),
        
        // Сортировка
        _buildSortSection(theme),
        const SizedBox(height: 16),
        
        // Кнопки
        _buildActionButtons(theme),
      ],
    );
  }

  Widget _buildCategoriesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Категории',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EnhancedSpecialistCategory.values.map((category) {
            final isSelected = widget.selectedCategories.contains(category);
            return FilterChip(
              label: Text(_getCategoryDisplayName(category)),
              selected: isSelected,
              onSelected: (selected) {
                final newCategories = List<EnhancedSpecialistCategory>.from(widget.selectedCategories);
                if (selected) {
                  newCategories.add(category);
                } else {
                  newCategories.remove(category);
                }
                widget.onCategoriesChanged(newCategories);
              },
              selectedColor: theme.colorScheme.primary.withOpacity(0.2),
              checkmarkColor: theme.colorScheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Местоположение',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'Введите город или регион',
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (value) {
            widget.onLocationChanged(value.isEmpty ? null : value);
          },
        ),
      ],
    );
  }

  Widget _buildPriceRangeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ценовой диапазон',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minPriceController,
                decoration: InputDecoration(
                  hintText: 'От',
                  prefixText: '₽ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final minPrice = double.tryParse(value);
                  widget.onPriceRangeChanged(minPrice, widget.maxPrice);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _maxPriceController,
                decoration: InputDecoration(
                  hintText: 'До',
                  prefixText: '₽ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final maxPrice = double.tryParse(value);
                  widget.onPriceRangeChanged(widget.minPrice, maxPrice);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Доступность',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.availableFrom != null
                            ? '${widget.availableFrom!.day}.${widget.availableFrom!.month}.${widget.availableFrom!.year}'
                            : 'От даты',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.availableTo != null
                            ? '${widget.availableTo!.day}.${widget.availableTo!.month}.${widget.availableTo!.year}'
                            : 'До даты',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Минимальный рейтинг',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final rating = (index + 1).toDouble();
            final isSelected = widget.minRating != null && widget.minRating! <= rating;
            
            return GestureDetector(
              onTap: () {
                widget.onRatingChanged(rating);
              },
              child: Icon(
                isSelected ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 32,
              ),
            );
          }),
        ),
        if (widget.minRating != null)
          Text(
            'От ${widget.minRating!.toStringAsFixed(1)} звезд',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
      ],
    );
  }

  Widget _buildSortSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Сортировка',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<SearchSortOption>(
          value: widget.sortBy,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: SearchSortOption.values.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(_getSortOptionName(option)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              widget.onSortChanged(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _clearFilters,
            child: const Text('Сбросить'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Фильтры уже применяются автоматически
            },
            child: const Text('Применить'),
          ),
        ),
      ],
    );
  }

  String _getCategoryDisplayName(EnhancedSpecialistCategory category) {
    switch (category) {
      case EnhancedSpecialistCategory.photography:
        return 'Фотография';
      case EnhancedSpecialistCategory.videography:
        return 'Видеосъемка';
      case EnhancedSpecialistCategory.music:
        return 'Музыка';
      case EnhancedSpecialistCategory.catering:
        return 'Кейтеринг';
      case EnhancedSpecialistCategory.decoration:
        return 'Декор';
      case EnhancedSpecialistCategory.fireShow:
        return 'Фаер-шоу';
      case EnhancedSpecialistCategory.florist:
        return 'Флористы';
      case EnhancedSpecialistCategory.contentCreator:
        return 'Контент-мейкеры';
      case EnhancedSpecialistCategory.photoStudio:
        return 'Фотостудии';
      case EnhancedSpecialistCategory.dj:
        return 'DJ';
      case EnhancedSpecialistCategory.animator:
        return 'Аниматоры';
      case EnhancedSpecialistCategory.makeupArtist:
        return 'Визажисты';
      case EnhancedSpecialistCategory.stylist:
        return 'Стилисты';
      case EnhancedSpecialistCategory.security:
        return 'Охрана';
      case EnhancedSpecialistCategory.transport:
        return 'Транспорт';
      case EnhancedSpecialistCategory.equipment:
        return 'Оборудование';
      case EnhancedSpecialistCategory.entertainment:
        return 'Развлечения';
      case EnhancedSpecialistCategory.wellness:
        return 'Wellness';
      case EnhancedSpecialistCategory.education:
        return 'Образование';
      case EnhancedSpecialistCategory.business:
        return 'Бизнес-услуги';
    }
  }

  String _getSortOptionName(SearchSortOption option) {
    switch (option) {
      case SearchSortOption.relevance:
        return 'Релевантность';
      case SearchSortOption.rating:
        return 'Рейтинг';
      case SearchSortOption.priceLow:
        return 'Цена (по возрастанию)';
      case SearchSortOption.priceHigh:
        return 'Цена (по убыванию)';
      case SearchSortOption.popularity:
        return 'Популярность';
      case SearchSortOption.newest:
        return 'Новые';
      case SearchSortOption.responseTime:
        return 'Время отклика';
    }
  }

  Future<void> _selectDate(bool isFrom) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: isFrom 
          ? (widget.availableFrom ?? DateTime.now())
          : (widget.availableTo ?? DateTime.now().add(const Duration(days: 1))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      if (isFrom) {
        widget.onAvailabilityChanged(selectedDate, widget.availableTo);
      } else {
        widget.onAvailabilityChanged(widget.availableFrom, selectedDate);
      }
    }
  }

  void _clearFilters() {
    _locationController.clear();
    _minPriceController.clear();
    _maxPriceController.clear();
    
    widget.onCategoriesChanged([]);
    widget.onLocationChanged(null);
    widget.onPriceRangeChanged(null, null);
    widget.onAvailabilityChanged(null, null);
    widget.onRatingChanged(null);
    widget.onSortChanged(SearchSortOption.relevance);
  }
}
