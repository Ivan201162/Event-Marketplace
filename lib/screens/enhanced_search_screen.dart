import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enhanced_specialist.dart';
import '../models/enhanced_specialist_category.dart';
import '../services/enhanced_search_service.dart';
import '../services/ai_recommendation_service.dart';
import '../widgets/enhanced_search_filters.dart';
import '../widgets/specialist_recommendation_card.dart';
import '../widgets/smart_upsell_widget.dart';

/// Экран расширенного поиска специалистов
class EnhancedSearchScreen extends ConsumerStatefulWidget {
  const EnhancedSearchScreen({super.key});

  @override
  ConsumerState<EnhancedSearchScreen> createState() => _EnhancedSearchScreenState();
}

class _EnhancedSearchScreenState extends ConsumerState<EnhancedSearchScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<EnhancedSpecialist> _searchResults = [];
  List<SpecialistRecommendation> _recommendations = [];
  bool _isLoading = false;
  bool _showFilters = false;
  
  // Фильтры
  List<EnhancedSpecialistCategory> _selectedCategories = [];
  String? _selectedLocation;
  double? _minPrice;
  double? _maxPrice;
  DateTime? _availableFrom;
  DateTime? _availableTo;
  double? _minRating;
  SearchSortOption _sortBy = SearchSortOption.relevance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
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
            Tab(text: 'Поиск', icon: Icon(Icons.search)),
            Tab(text: 'Рекомендации', icon: Icon(Icons.recommend)),
          ],
        ),
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
          // Поисковая строка
          _buildSearchBar(theme),
          
          // Фильтры
          if (_showFilters) _buildFiltersSection(theme),
          
          // Контент
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSearchTab(),
                _buildRecommendationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по имени, категории, городу...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() {});
                if (value.length >= 3) {
                  _performSearch();
                }
              },
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _performSearch,
            icon: const Icon(Icons.search),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: EnhancedSearchFilters(
        selectedCategories: _selectedCategories,
        selectedLocation: _selectedLocation,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        availableFrom: _availableFrom,
        availableTo: _availableTo,
        minRating: _minRating,
        sortBy: _sortBy,
        onCategoriesChanged: (categories) {
          setState(() {
            _selectedCategories = categories;
          });
          _performSearch();
        },
        onLocationChanged: (location) {
          setState(() {
            _selectedLocation = location;
          });
          _performSearch();
        },
        onPriceRangeChanged: (min, max) {
          setState(() {
            _minPrice = min;
            _maxPrice = max;
          });
          _performSearch();
        },
        onAvailabilityChanged: (from, to) {
          setState(() {
            _availableFrom = from;
            _availableTo = to;
          });
          _performSearch();
        },
        onRatingChanged: (rating) {
          setState(() {
            _minRating = rating;
          });
          _performSearch();
        },
        onSortChanged: (sortBy) {
          setState(() {
            _sortBy = sortBy;
          });
          _performSearch();
        },
      ),
    );
  }

  Widget _buildSearchTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return _buildEmptySearchResults();
    }

    if (_searchResults.isEmpty) {
      return _buildSearchPrompt();
    }

    return RefreshIndicator(
      onRefresh: _performSearch,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final specialist = _searchResults[index];
          return SpecialistRecommendationCard(
            specialist: specialist,
            onTap: () => _showSpecialistDetails(specialist),
            onBook: () => _bookSpecialist(specialist),
            onFavorite: () => _toggleFavorite(specialist),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recommendations.isEmpty) {
      return _buildEmptyRecommendations();
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recommendations.length,
        itemBuilder: (context, index) {
          final recommendation = _recommendations[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: SpecialistRecommendationCard(
              specialist: recommendation.specialist,
              recommendationReason: recommendation.reason,
              recommendationScore: recommendation.score,
              onTap: () => _showSpecialistDetails(recommendation.specialist),
              onBook: () => _bookSpecialist(recommendation.specialist),
              onFavorite: () => _toggleFavorite(recommendation.specialist),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptySearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Ничего не найдено',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуйте изменить параметры поиска',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedCategories.clear();
                _selectedLocation = null;
                _minPrice = null;
                _maxPrice = null;
                _availableFrom = null;
                _availableTo = null;
                _minRating = null;
                _sortBy = SearchSortOption.relevance;
              });
            },
            child: const Text('Сбросить фильтры'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Найдите идеального специалиста',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Введите запрос или используйте фильтры для поиска',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecommendations() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.recommend_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет рекомендаций',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Сделайте несколько заказов, чтобы получить персональные рекомендации',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _performSearch() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final searchService = EnhancedSearchService();
      final results = await searchService.searchSpecialists(
        query: _searchController.text.isNotEmpty ? _searchController.text : null,
        categories: _selectedCategories.isNotEmpty ? _selectedCategories : null,
        location: _selectedLocation,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        availableFrom: _availableFrom,
        availableTo: _availableTo,
        minRating: _minRating,
        sortBy: _sortBy,
        limit: 20,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Ошибка поиска: $e');
    }
  }

  Future<void> _loadRecommendations() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final recommendationService = AIRecommendationService();
      final recommendations = await recommendationService.getPersonalizedRecommendations(
        userId: 'current_user_id', // В реальном приложении получать из AuthService
        limit: 10,
      );

      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Ошибка загрузки рекомендаций: $e');
    }
  }

  void _showSpecialistDetails(EnhancedSpecialist specialist) {
    Navigator.pushNamed(
      context,
      '/specialist_details',
      arguments: specialist.id,
    );
  }

  void _bookSpecialist(EnhancedSpecialist specialist) {
    Navigator.pushNamed(
      context,
      '/booking',
      arguments: specialist.id,
    );
  }

  void _toggleFavorite(EnhancedSpecialist specialist) {
    // Логика добавления/удаления из избранного
    _showSuccessSnackBar('Добавлено в избранное');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
