import 'package:flutter/material.dart';
import '../models/specialist.dart';

/// Виджет фильтров поиска
class SearchFiltersWidget extends StatefulWidget {
  final Function(SpecialistFilters) onFiltersChanged;
  final SpecialistFilters? initialFilters;

  const SearchFiltersWidget({
    super.key,
    required this.onFiltersChanged,
    this.initialFilters,
  });

  @override
  State<SearchFiltersWidget> createState() => _SearchFiltersWidgetState();
}

class _SearchFiltersWidgetState extends State<SearchFiltersWidget> {
  late SpecialistFilters _filters;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters ?? const SpecialistFilters();
    _updateControllers();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  void _updateControllers() {
    _priceController.text = _filters.maxHourlyRate?.toString() ?? '';
    _ratingController.text = _filters.minRating?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок
        Row(
          children: [
            const Text(
              'Фильтры',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Сбросить'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Категория
        _buildCategoryFilter(),

        const SizedBox(height: 16),

        // Подкатегории
        _buildSubcategoriesFilter(),

        const SizedBox(height: 16),

        // Уровень опыта
        _buildExperienceFilter(),

        const SizedBox(height: 16),

        // Цена и рейтинг
        Row(
          children: [
            Expanded(child: _buildPriceFilter()),
            const SizedBox(width: 16),
            Expanded(child: _buildRatingFilter()),
          ],
        ),

        const SizedBox(height: 16),

        // Области обслуживания
        _buildServiceAreasFilter(),

        const SizedBox(height: 16),

        // Языки
        _buildLanguagesFilter(),

        const SizedBox(height: 16),

        // Дополнительные фильтры
        _buildAdditionalFilters(),

        const SizedBox(height: 16),

        // Фильтр по дате
        _buildDateFilter(),

        const SizedBox(height: 16),

        // Сортировка
        _buildSortFilter(),
      ],
    );
  }

  /// Построить фильтр категории
  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Категория',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<SpecialistCategory?>(
          value: _filters.category,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: const Text('Все категории'),
          items: [
            const DropdownMenuItem<SpecialistCategory?>(
              value: null,
              child: Text('Все категории'),
            ),
            ...SpecialistCategory.values.map((category) {
              return DropdownMenuItem<SpecialistCategory?>(
                value: category,
                child: Text(category.displayName),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(category: value);
            });
            widget.onFiltersChanged(_filters);
          },
        ),
      ],
    );
  }

  /// Построить фильтр подкатегорий
  Widget _buildSubcategoriesFilter() {
    final subcategories = _getAvailableSubcategories();

    if (subcategories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Подкатегории',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: subcategories.map((subcategory) {
            final isSelected =
                _filters.subcategories?.contains(subcategory) ?? false;
            return FilterChip(
              label: Text(subcategory),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final currentSubcategories =
                      List<String>.from(_filters.subcategories ?? []);
                  if (selected) {
                    currentSubcategories.add(subcategory);
                  } else {
                    currentSubcategories.remove(subcategory);
                  }
                  _filters = _filters.copyWith(
                    subcategories: currentSubcategories.isEmpty
                        ? null
                        : currentSubcategories,
                  );
                });
                widget.onFiltersChanged(_filters);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Построить фильтр опыта
  Widget _buildExperienceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Минимальный опыт',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ExperienceLevel?>(
          value: _filters.minExperienceLevel,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: const Text('Любой опыт'),
          items: [
            const DropdownMenuItem<ExperienceLevel?>(
              value: null,
              child: Text('Любой опыт'),
            ),
            ...ExperienceLevel.values.map((level) {
              return DropdownMenuItem<ExperienceLevel?>(
                value: level,
                child: Text(level.displayName),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(minExperienceLevel: value);
            });
            widget.onFiltersChanged(_filters);
          },
        ),
      ],
    );
  }

  /// Построить фильтр цены
  Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Максимальная цена (₽/час)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _priceController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            hintText: 'Не ограничено',
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final price = double.tryParse(value);
            setState(() {
              _filters = _filters.copyWith(maxHourlyRate: price);
            });
            widget.onFiltersChanged(_filters);
          },
        ),
      ],
    );
  }

  /// Построить фильтр рейтинга
  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Минимальный рейтинг',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ratingController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            hintText: 'Любой рейтинг',
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final rating = double.tryParse(value);
            setState(() {
              _filters = _filters.copyWith(minRating: rating);
            });
            widget.onFiltersChanged(_filters);
          },
        ),
      ],
    );
  }

  /// Построить фильтр областей обслуживания
  Widget _buildServiceAreasFilter() {
    final serviceAreas = _getAvailableServiceAreas();

    if (serviceAreas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Области обслуживания',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: serviceAreas.map((area) {
            final isSelected = _filters.serviceAreas?.contains(area) ?? false;
            return FilterChip(
              label: Text(area),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final currentAreas =
                      List<String>.from(_filters.serviceAreas ?? []);
                  if (selected) {
                    currentAreas.add(area);
                  } else {
                    currentAreas.remove(area);
                  }
                  _filters = _filters.copyWith(
                    serviceAreas: currentAreas.isEmpty ? null : currentAreas,
                  );
                });
                widget.onFiltersChanged(_filters);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Построить фильтр языков
  Widget _buildLanguagesFilter() {
    final languages = _getAvailableLanguages();

    if (languages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Языки',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: languages.map((language) {
            final isSelected = _filters.languages?.contains(language) ?? false;
            return FilterChip(
              label: Text(language),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final currentLanguages =
                      List<String>.from(_filters.languages ?? []);
                  if (selected) {
                    currentLanguages.add(language);
                  } else {
                    currentLanguages.remove(language);
                  }
                  _filters = _filters.copyWith(
                    languages:
                        currentLanguages.isEmpty ? null : currentLanguages,
                  );
                });
                widget.onFiltersChanged(_filters);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Построить дополнительные фильтры
  Widget _buildAdditionalFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Дополнительно',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Только верифицированные'),
                value: _filters.isVerified ?? false,
                onChanged: (value) {
                  setState(() {
                    _filters = _filters.copyWith(isVerified: value);
                  });
                  widget.onFiltersChanged(_filters);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Только доступные'),
                value: _filters.isAvailable ?? false,
                onChanged: (value) {
                  setState(() {
                    _filters = _filters.copyWith(isAvailable: value);
                  });
                  widget.onFiltersChanged(_filters);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Построить фильтр сортировки
  Widget _buildSortFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Сортировка',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _filters.sortBy,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'rating', child: Text('По рейтингу')),
                  DropdownMenuItem(value: 'price', child: Text('По цене')),
                  DropdownMenuItem(
                      value: 'experience', child: Text('По опыту')),
                  DropdownMenuItem(value: 'reviews', child: Text('По отзывам')),
                ],
                onChanged: (value) {
                  setState(() {
                    _filters = _filters.copyWith(sortBy: value);
                  });
                  widget.onFiltersChanged(_filters);
                },
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: Icon(
                _filters.sortAscending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
              ),
              onPressed: () {
                setState(() {
                  _filters =
                      _filters.copyWith(sortAscending: !_filters.sortAscending);
                });
                widget.onFiltersChanged(_filters);
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Получить доступные подкатегории
  List<String> _getAvailableSubcategories() {
    // В реальном приложении это должно приходить из API
    return [
      'свадебная фотография',
      'портретная съемка',
      'корпоративные мероприятия',
      'свадебные торжества',
      'частные вечеринки',
      'свадебное оформление',
      'детские праздники',
      'свадебная видеосъемка',
      'рекламные ролики',
    ];
  }

  /// Получить доступные области обслуживания
  List<String> _getAvailableServiceAreas() {
    return [
      'Москва',
      'Санкт-Петербург',
      'Московская область',
      'Калужская область',
      'Тверская область',
    ];
  }

  /// Получить доступные языки
  List<String> _getAvailableLanguages() {
    return [
      'Русский',
      'Английский',
      'Французский',
      'Немецкий',
      'Испанский',
    ];
  }

  /// Построить фильтр по дате
  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Доступность на дату',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _filters.availableDate != null
                        ? '${_filters.availableDate!.day}.${_filters.availableDate!.month}.${_filters.availableDate!.year}'
                        : 'Выберите дату',
                    style: TextStyle(
                      color: _filters.availableDate != null
                          ? Colors.black
                          : Colors.grey[600],
                    ),
                  ),
                ),
                if (_filters.availableDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      setState(() {
                        _filters = _filters.copyWith(availableDate: null);
                      });
                      widget.onFiltersChanged(_filters);
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Выбрать дату
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _filters.availableDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _filters = _filters.copyWith(availableDate: date);
      });
      widget.onFiltersChanged(_filters);
    }
  }

  /// Очистить фильтры
  void _clearFilters() {
    setState(() {
      _filters = const SpecialistFilters();
      _updateControllers();
    });
    widget.onFiltersChanged(_filters);
  }
}

/// Расширение для отображения названий категорий
extension SpecialistCategoryExtension on SpecialistCategory {
  String get displayName {
    switch (this) {
      case SpecialistCategory.photographer:
        return 'Фотограф';
      case SpecialistCategory.videographer:
        return 'Видеограф';
      case SpecialistCategory.dj:
        return 'DJ';
      case SpecialistCategory.host:
        return 'Ведущий';
      case SpecialistCategory.decorator:
        return 'Декоратор';
      case SpecialistCategory.musician:
        return 'Музыкант';
      case SpecialistCategory.caterer:
        return 'Кейтеринг';
      case SpecialistCategory.security:
        return 'Охрана';
      case SpecialistCategory.technician:
        return 'Техник';
      case SpecialistCategory.animator:
        return 'Аниматор';
      case SpecialistCategory.florist:
        return 'Флорист';
      case SpecialistCategory.lighting:
        return 'Световое оформление';
      case SpecialistCategory.sound:
        return 'Звуковое оборудование';
      case SpecialistCategory.costume:
        return 'Платья/костюмы';
      case SpecialistCategory.fireShow:
        return 'Фаер-шоу';
      case SpecialistCategory.fireworks:
        return 'Салюты';
      case SpecialistCategory.lightShow:
        return 'Световые шоу';
      case SpecialistCategory.coverBand:
        return 'Кавер-группы';
      case SpecialistCategory.teamBuilding:
        return 'Тимбилдинги';
      case SpecialistCategory.cleaning:
        return 'Клининг';
      case SpecialistCategory.rental:
        return 'Аренда оборудования';
      case SpecialistCategory.makeup:
        return 'Визажист';
      case SpecialistCategory.hairstylist:
        return 'Парикмахер';
      case SpecialistCategory.stylist:
        return 'Стилист';
      case SpecialistCategory.choreographer:
        return 'Хореограф';
      case SpecialistCategory.dance:
        return 'Танцы';
      case SpecialistCategory.magic:
        return 'Фокусы/иллюзионист';
      case SpecialistCategory.clown:
        return 'Клоун';
      case SpecialistCategory.balloon:
        return 'Аэродизайн';
      case SpecialistCategory.cake:
        return 'Торты/кондитер';
      case SpecialistCategory.transport:
        return 'Транспорт';
      case SpecialistCategory.venue:
        return 'Площадки';
      case SpecialistCategory.other:
        return 'Другое';
    }
  }
}

/// Расширение для отображения названий уровней опыта
extension ExperienceLevelExtension on ExperienceLevel {
  String get displayName {
    switch (this) {
      case ExperienceLevel.beginner:
        return 'Начинающий';
      case ExperienceLevel.intermediate:
        return 'Средний';
      case ExperienceLevel.advanced:
        return 'Продвинутый';
      case ExperienceLevel.expert:
        return 'Эксперт';
    }
  }
}
