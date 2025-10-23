import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/specialist_providers.dart';
import '../../models/specialist_enhanced.dart';
import '../../widgets/animated_skeleton.dart';
import '../../services/navigation_service.dart';

/// Расширенный экран поиска с фильтрами
class SearchScreenEnhanced extends ConsumerStatefulWidget {
  const SearchScreenEnhanced({super.key});

  @override
  ConsumerState<SearchScreenEnhanced> createState() =>
      _SearchScreenEnhancedState();
}

class _SearchScreenEnhancedState extends ConsumerState<SearchScreenEnhanced>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _showFilters = false;
  String _selectedSortBy = 'rating';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentFilters = ref.watch(currentSearchFiltersProvider);
    final searchResults = ref.watch(searchSpecialistsProvider(currentFilters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск специалистов'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationService.safePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
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
          // Поисковая строка
          _buildSearchBar(),

          // Фильтры
          if (_showFilters) _buildFiltersPanel(currentFilters),

          // Результаты поиска
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildSearchResults(searchResults),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Поисковая строка
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A8A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (value) {
          _performSearch(value);
        },
        decoration: InputDecoration(
          hintText: 'Поиск по имени, специализации, городу...',
          hintStyle: TextStyle(color: Colors.grey[300]),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: () {
              _searchController.clear();
              _clearSearch();
            },
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  /// Панель фильтров
  Widget _buildFiltersPanel(SearchFilters currentFilters) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок фильтров
          Row(
            children: [
              const Text(
                'Фильтры',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  ref
                      .read(currentSearchFiltersProvider.notifier)
                      .clearFilters();
                },
                child: const Text(
                  'Сбросить',
                  style: TextStyle(color: Color(0xFF1E3A8A)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Категории
          _buildCategoryFilters(currentFilters),

          const SizedBox(height: 16),

          // Рейтинг
          _buildRatingFilter(currentFilters),

          const SizedBox(height: 16),

          // Ценовой диапазон
          _buildPriceFilter(currentFilters),

          const SizedBox(height: 16),

          // Сортировка
          _buildSortFilter(),

          const SizedBox(height: 16),

          // Кнопки
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showFilters = false;
                    });
                  },
                  child: const Text('Скрыть'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _applyFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Применить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Фильтр по категориям
  Widget _buildCategoryFilters(SearchFilters currentFilters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Категории',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SpecialistCategory.values.map((category) {
            final isSelected =
                currentFilters.categories.contains(category.name);
            return GestureDetector(
              onTap: () {
                _toggleCategory(category.name);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF1E3A8A) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1E3A8A)
                        : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      category.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Фильтр по рейтингу
  Widget _buildRatingFilter(SearchFilters currentFilters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Рейтинг',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: currentFilters.minRating?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'От',
                  hintText: '0.0',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final rating = double.tryParse(value);
                  _updateRatingFilter(rating, currentFilters.maxRating);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: currentFilters.maxRating?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'До',
                  hintText: '5.0',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final rating = double.tryParse(value);
                  _updateRatingFilter(currentFilters.minRating, rating);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Фильтр по цене
  Widget _buildPriceFilter(SearchFilters currentFilters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ценовой диапазон',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: currentFilters.minPrice?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'От (₽)',
                  hintText: '0',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = double.tryParse(value);
                  _updatePriceFilter(price, currentFilters.maxPrice);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: currentFilters.maxPrice?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'До (₽)',
                  hintText: '100000',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = double.tryParse(value);
                  _updatePriceFilter(currentFilters.minPrice, price);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Фильтр сортировки
  Widget _buildSortFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Сортировка',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedSortBy,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'rating', child: Text('По рейтингу')),
            DropdownMenuItem(
                value: 'orders', child: Text('По количеству заказов')),
            DropdownMenuItem(value: 'price', child: Text('По цене')),
            DropdownMenuItem(
                value: 'newest', child: Text('По дате регистрации')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedSortBy = value ?? 'rating';
            });
          },
        ),
      ],
    );
  }

  /// Результаты поиска
  Widget _buildSearchResults(
      AsyncValue<List<SpecialistEnhanced>> searchResults) {
    return searchResults.when(
      data: (specialists) {
        if (specialists.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            // Информация о результатах
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Найдено: ${specialists.length} специалистов',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const Spacer(),
                  if (ref.read(currentSearchFiltersProvider).hasActiveFilters)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Фильтры активны',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E3A8A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Список специалистов
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: specialists.length,
                itemBuilder: (context, index) {
                  final specialist = specialists[index];
                  return _buildSpecialistCard(specialist);
                },
              ),
            ),
          ],
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  /// Карточка специалиста в списке
  Widget _buildSpecialistCard(SpecialistEnhanced specialist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            NavigationService.safeGo(context, '/profile/${specialist.id}');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Аватар
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipOval(
                    child: specialist.avatarUrl != null
                        ? Image.network(
                            specialist.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.grey,
                              );
                            },
                          )
                        : const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.grey,
                          ),
                  ),
                ),

                const SizedBox(width: 16),

                // Информация
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Имя и специализация
                      Text(
                        specialist.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialist.specialization,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Рейтинг и заказы
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            specialist.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${specialist.successfulOrders} заказов',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Бейджи
                      if (specialist.badges.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: specialist.badges.take(3).map((badge) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(badge.color).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${badge.emoji} ${badge.label}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(badge.color),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),

                // Кнопка избранного
                IconButton(
                  icon: Icon(
                    ref
                            .watch(favoriteSpecialistsProvider)
                            .contains(specialist.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: ref
                            .watch(favoriteSpecialistsProvider)
                            .contains(specialist.id)
                        ? Colors.red
                        : Colors.grey,
                  ),
                  onPressed: () {
                    ref
                        .read(favoriteSpecialistsProvider.notifier)
                        .toggleFavorite(specialist.id);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Пустое состояние
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Специалисты не найдены',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуйте изменить фильтры поиска',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(currentSearchFiltersProvider.notifier).clearFilters();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Сбросить фильтры'),
          ),
        ],
      ),
    );
  }

  /// Состояние загрузки
  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: const ShimmerBox(
            width: double.infinity,
            height: 100,
            borderRadius: 16,
          ),
        );
      },
    );
  }

  /// Состояние ошибки
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(searchSpecialistsProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  /// Выполнить поиск
  void _performSearch(String query) {
    if (query.isEmpty) return;

    // Здесь можно добавить логику поиска по тексту
    // Пока просто обновляем результаты
    ref.invalidate(searchSpecialistsProvider);
  }

  /// Очистить поиск
  void _clearSearch() {
    _searchController.clear();
    ref.invalidate(searchSpecialistsProvider);
  }

  /// Переключить категорию
  void _toggleCategory(String category) {
    final currentFilters = ref.read(currentSearchFiltersProvider);
    final categories = currentFilters.categories;

    List<String> newCategories;
    if (categories.contains(category)) {
      newCategories = categories.where((c) => c != category).toList();
    } else {
      newCategories = [...categories, category];
    }

    ref.read(currentSearchFiltersProvider.notifier).updateFilters(
          currentFilters.copyWith(categories: newCategories),
        );
  }

  /// Обновить фильтр рейтинга
  void _updateRatingFilter(double? minRating, double? maxRating) {
    final currentFilters = ref.read(currentSearchFiltersProvider);
    ref.read(currentSearchFiltersProvider.notifier).updateFilters(
          currentFilters.copyWith(
            minRating: minRating,
            maxRating: maxRating,
          ),
        );
  }

  /// Обновить фильтр цены
  void _updatePriceFilter(double? minPrice, double? maxPrice) {
    final currentFilters = ref.read(currentSearchFiltersProvider);
    ref.read(currentSearchFiltersProvider.notifier).updateFilters(
          currentFilters.copyWith(
            minPrice: minPrice,
            maxPrice: maxPrice,
          ),
        );
  }

  /// Применить фильтры
  void _applyFilters() {
    final currentFilters = ref.read(currentSearchFiltersProvider);
    ref.read(currentSearchFiltersProvider.notifier).updateFilters(
          currentFilters.copyWith(sortBy: _selectedSortBy),
        );

    setState(() {
      _showFilters = false;
    });
  }
}
