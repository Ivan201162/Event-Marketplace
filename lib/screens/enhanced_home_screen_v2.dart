import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../widgets/animated_categories.dart';
import '../widgets/animated_interesting_section.dart';
import '../widgets/animated_search_bar.dart';
import '../widgets/animated_specialists_carousel.dart';
import '../widgets/animated_user_header.dart';
import '../widgets/filters_dialog.dart';

/// Улучшенный главный экран с анимациями и адаптивным скроллом
class EnhancedHomeScreenV2 extends ConsumerStatefulWidget {
  const EnhancedHomeScreenV2({super.key});

  @override
  ConsumerState<EnhancedHomeScreenV2> createState() => _EnhancedHomeScreenV2State();
}

class _EnhancedHomeScreenV2State extends ConsumerState<EnhancedHomeScreenV2>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _appBarAnimationController;
  late Animation<double> _appBarOpacityAnimation;

  bool _isUserHeaderVisible = true;
  double _lastScrollOffset = 0.0;
  Map<String, dynamic> _currentFilters = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _appBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _appBarOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _appBarAnimationController, curve: Curves.easeInOut));

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _appBarAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;
    final delta = currentOffset - _lastScrollOffset;

    // Показываем/скрываем плашку пользователя при скролле
    if (delta > 10 && _isUserHeaderVisible) {
      // Скролл вниз - скрываем
      setState(() => _isUserHeaderVisible = false);
      _appBarAnimationController.forward();
    } else if (delta < -10 && !_isUserHeaderVisible) {
      // Скролл вверх - показываем
      setState(() => _isUserHeaderVisible = true);
      _appBarAnimationController.reverse();
    }

    _lastScrollOffset = currentOffset;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ideas/add'),
        icon: const Icon(Icons.lightbulb_outline),
        label: const Text('Добавить идею'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Улучшенная шапка с логотипом и градиентом
          SliverAppBar(
            floating: true,
            snap: true,
            expandedHeight: 0,
            toolbarHeight: 0,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: AnimatedBuilder(
              animation: _appBarOpacityAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _appBarOpacityAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Улучшенный логотип с иконкой
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.event,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Event Marketplace',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Найди идеального специалиста',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Улучшенные действия с уведомлениями
                            Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                        onPressed: () => context.push('/notifications'),
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                                    onPressed: () => context.push('/settings'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Плашка пользователя с анимацией
          SliverToBoxAdapter(
            child: currentUserAsync.when(
              data: (user) => AnimatedUserHeader(user: user, isVisible: _isUserHeaderVisible),
              loading: () => AnimatedUserHeader(user: null, isVisible: _isUserHeaderVisible),
              error: (_, __) => AnimatedUserHeader(user: null, isVisible: _isUserHeaderVisible),
            ),
          ),

          // Поиск специалистов
          SliverToBoxAdapter(child: _buildSearchWithFilters()),

          // Категории специалистов
          SliverToBoxAdapter(
            child: AnimatedCategories(
              onCategorySelected: (category) {
                context.push('/search?category=${Uri.encodeComponent(category)}');
              },
            ),
          ),

          // Карусель лучших специалистов недели
          const SliverToBoxAdapter(child: AnimatedSpecialistsCarousel()),

          // Блок "Интересное"
          const SliverToBoxAdapter(child: AnimatedInterestingSection()),

          // Отступ внизу
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  /// Поиск с фильтрами
  Widget _buildSearchWithFilters() => Container(
    margin: const EdgeInsets.all(16),
    child: Row(
      children: [
        Expanded(
          child: AnimatedSearchBar(
            onSearch: (query) {
              _performSearch(query);
            },
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: _showFiltersDialog,
            tooltip: 'Фильтры',
          ),
        ),
      ],
    ),
  );

  /// Показать диалог фильтров
  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => FiltersDialog(
        initialFilters: _currentFilters,
        onApplyFilters: (filters) {
          setState(() {
            _currentFilters = filters;
          });
          _performSearch('');
        },
      ),
    );
  }

  /// Выполнить поиск с применением фильтров
  void _performSearch(String query) {
    final searchParams = <String, String>{};

    if (query.isNotEmpty) {
      searchParams['q'] = query;
    }

    if (_currentFilters['city'] != null) {
      searchParams['city'] = _currentFilters['city'];
    }

    if (_currentFilters['category'] != null) {
      searchParams['category'] = _currentFilters['category'];
    }

    if (_currentFilters['minRating'] != null) {
      searchParams['minRating'] = _currentFilters['minRating'].toString();
    }

    if (_currentFilters['specialistType'] != null) {
      searchParams['type'] = _currentFilters['specialistType'];
    }

    final queryString = searchParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    context.push('/search?$queryString');
  }
}
