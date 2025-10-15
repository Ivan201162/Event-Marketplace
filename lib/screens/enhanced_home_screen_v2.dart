import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../widgets/animated_categories.dart';
import '../widgets/animated_interesting_section.dart';
import '../widgets/animated_search_bar.dart';
import '../widgets/animated_specialists_carousel.dart';
import '../widgets/animated_user_header.dart';

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
    ).animate(CurvedAnimation(
      parent: _appBarAnimationController,
      curve: Curves.easeInOut,
    ));

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
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // SliverAppBar с анимацией
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
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
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Логотип/название
                            Text(
                              'Event',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            // Действия
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_outlined),
                                  onPressed: () => context.push('/notifications'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.settings_outlined),
                                  onPressed: () => context.push('/settings'),
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
              data: (user) => AnimatedUserHeader(
                user: user,
                isVisible: _isUserHeaderVisible,
              ),
              loading: () => AnimatedUserHeader(
                user: null,
                isVisible: _isUserHeaderVisible,
              ),
              error: (_, __) => AnimatedUserHeader(
                user: null,
                isVisible: _isUserHeaderVisible,
              ),
            ),
          ),

          // Поиск специалистов
          SliverToBoxAdapter(
            child: AnimatedSearchBar(
              onSearch: (query) {
                context.push('/search?q=${Uri.encodeComponent(query)}');
              },
            ),
          ),

          // Категории специалистов
          SliverToBoxAdapter(
            child: AnimatedCategories(
              onCategorySelected: (category) {
                context.push('/search?category=${Uri.encodeComponent(category)}');
              },
            ),
          ),

          // Карусель лучших специалистов недели
          SliverToBoxAdapter(
            child: AnimatedSpecialistsCarousel(),
          ),

          // Блок "Интересное"
          SliverToBoxAdapter(
            child: AnimatedInterestingSection(),
          ),

          // Быстрые действия
          SliverToBoxAdapter(
            child: _buildQuickActionsSection(),
          ),

          // Отступ внизу
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  /// Быстрые действия
  Widget _buildQuickActionsSection() => Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Быстрые действия',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.event,
                    title: 'Создать заявку',
                    onTap: () => context.push('/requests/create'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.photo_library,
                    title: 'Мои идеи',
                    onTap: () => context.push('/ideas'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

/// Карточка быстрого действия
class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) {
                setState(() => _isPressed = true);
                _animationController.forward();
              },
              onTapUp: (_) {
                setState(() => _isPressed = false);
                _animationController.reverse();
              },
              onTapCancel: () {
                setState(() => _isPressed = false);
                _animationController.reverse();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isPressed
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isPressed
                        ? Theme.of(context).primaryColor.withOpacity(0.3)
                        : Theme.of(context).dividerColor,
                    width: _isPressed ? 2 : 1,
                  ),
                  boxShadow: _isPressed
                      ? [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    AnimatedScale(
                      scale: _isPressed ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        widget.icon,
                        size: 32,
                        color: _isPressed
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: _isPressed ? FontWeight.bold : FontWeight.w500,
                        color: _isPressed
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}
