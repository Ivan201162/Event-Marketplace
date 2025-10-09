import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/smart_specialist.dart';
import '../models/specialist.dart';
import '../services/ai_assistant_service.dart';
import '../services/smart_search_service.dart';
import '../widgets/ai_assistant_dialog.dart';
import '../widgets/smart_search_filters.dart';
import '../widgets/specialist_card.dart';

// Временное определение для совместимости
enum SpecialistSortOption {
  rating,
  price,
  experience,
  reviews,
  name,
  dateAdded,
}

/// Экран умного поиска специалистов
class SmartSearchScreen extends ConsumerStatefulWidget {
  const SmartSearchScreen({super.key});

  @override
  ConsumerState<SmartSearchScreen> createState() => _SmartSearchScreenState();
}

class _SmartSearchScreenState extends ConsumerState<SmartSearchScreen> {
  final SmartSearchService _smartSearchService = SmartSearchService();
  final AIAssistantService _aiAssistantService = AIAssistantService();
  
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<SmartSpecialist> _specialists = [];
  List<SmartSpecialist> _recommendations = [];
  bool _isLoading = false;
  bool _showFilters = false;
  String? _currentUserId;
  
  // Фильтры
  SpecialistCategory? _selectedCategory;
  String? _selectedCity;
  double _minPrice = 0;
  double _maxPrice = 100000;
  DateTime? _selectedDate;
  List<String> _selectedStyles = [];
  SpecialistSortOption? _selectedSort;
  
  // Состояние AI-помощника
  AIConversation? _aiConversation;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Загрузить начальные данные
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      // Загружаем популярных специалистов
      final popularSpecialists = await _smartSearchService.getPopularSpecialists(limit: 20);
      setState(() {
        _specialists = popularSpecialists;
        _isLoading = false;
      });
      
      // Загружаем персональные рекомендации если есть userId
      if (_currentUserId != null) {
        final recommendations = await _smartSearchService.getPersonalRecommendations(
          _currentUserId!,
        );
        setState(() => _recommendations = recommendations);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка загрузки данных: $e');
    }
  }

  /// Обработка скролла
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreSpecialists();
    }
  }

  /// Загрузить больше специалистов
  Future<void> _loadMoreSpecialists() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final moreSpecialists = await _smartSearchService.smartSearch(
        query: _searchController.text.isNotEmpty ? _searchController.text : null,
        category: _selectedCategory,
        city: _selectedCity,
        minPrice: _minPrice > 0 ? _minPrice : null,
        maxPrice: _maxPrice < 100000 ? _maxPrice : null,
        eventDate: _selectedDate,
        styles: _selectedStyles.isNotEmpty ? _selectedStyles : null,
        sortBy: _selectedSort,
        userId: _currentUserId,
      );
      
      setState(() {
        _specialists.addAll(moreSpecialists);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка загрузки: $e');
    }
  }

  /// Выполнить поиск
  Future<void> _performSearch() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final specialists = await _smartSearchService.smartSearch(
        query: _searchController.text.isNotEmpty ? _searchController.text : null,
        category: _selectedCategory,
        city: _selectedCity,
        minPrice: _minPrice > 0 ? _minPrice : null,
        maxPrice: _maxPrice < 100000 ? _maxPrice : null,
        eventDate: _selectedDate,
        styles: _selectedStyles.isNotEmpty ? _selectedStyles : null,
        sortBy: _selectedSort,
        userId: _currentUserId,
      );
      
      setState(() {
        _specialists = specialists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка поиска: $e');
    }
  }

  /// Открыть AI-помощника
  Future<void> _openAIAssistant() async {
    final conversation = await _aiAssistantService.startConversation(userId: _currentUserId);
    setState(() => _aiConversation = conversation);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AIAssistantDialog(
          conversation: conversation,
          onClose: () {
            setState(() => _aiConversation = null);
          },
        ),
      );
    }
  }

  /// Показать ошибку
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Умный поиск'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy),
            onPressed: _openAIAssistant,
            tooltip: 'AI-помощник',
          ),
        ],
      ),
      body: Column(
        children: [
          // Поисковая строка
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск специалистов...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          
          // Фильтры
          if (_showFilters)
            SmartSearchFilters(
              selectedCategory: _selectedCategory,
              selectedCity: _selectedCity,
              minPrice: _minPrice,
              maxPrice: _maxPrice,
              selectedDate: _selectedDate,
              selectedStyles: _selectedStyles,
              selectedSort: _selectedSort,
              onCategoryChanged: (category) {
                setState(() => _selectedCategory = category);
                _performSearch();
              },
              onCityChanged: (city) {
                setState(() => _selectedCity = city);
                _performSearch();
              },
              onPriceChanged: (min, max) {
                setState(() {
                  _minPrice = min;
                  _maxPrice = max;
                });
                _performSearch();
              },
              onDateChanged: (date) {
                setState(() => _selectedDate = date);
                _performSearch();
              },
              onStylesChanged: (styles) {
                setState(() => _selectedStyles = styles);
                _performSearch();
              },
              onSortChanged: (sort) {
                setState(() => _selectedSort = sort);
                _performSearch();
              },
            ),
          
          // Персональные рекомендации
          if (_recommendations.isNotEmpty)
            Container(
              height: 200,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '🔮 Вам подойдут эти специалисты',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _recommendations.length,
                      itemBuilder: (context, index) {
                        final specialist = _recommendations[index];
                        return Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 12),
                          child: SpecialistCard(
                            specialist: specialist,
                            showCompatibility: true,
                            onTap: () => _onSpecialistTap(specialist),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          // Результаты поиска
          Expanded(
            child: _isLoading && _specialists.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _specialists.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Специалисты не найдены',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Попробуйте изменить параметры поиска',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInitialData,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _specialists.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _specialists.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            
                            final specialist = _specialists[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SpecialistCard(
                                specialist: specialist,
                                onTap: () => _onSpecialistTap(specialist),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAIAssistant,
        tooltip: 'AI-помощник',
        child: const Icon(Icons.smart_toy),
      ),
    );

  /// Обработка нажатия на специалиста
  void _onSpecialistTap(SmartSpecialist specialist) {
    // Записываем взаимодействие
    if (_currentUserId != null) {
      _smartSearchService.recordUserInteraction(
        userId: _currentUserId!,
        specialistId: specialist.id,
        action: 'view',
      );
    }
    
    // Переходим к профилю специалиста
    Navigator.pushNamed(
      context,
      '/specialist_profile',
      arguments: specialist.id,
    );
  }
}
