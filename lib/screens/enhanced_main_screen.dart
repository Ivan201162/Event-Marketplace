import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/swipe_back_wrapper.dart';
import 'home_screen.dart';
import 'enhanced_feed_screen.dart';
import 'requests_screen.dart';
import 'chats_screen.dart';
import 'enhanced_ideas_screen.dart';

/// Улучшенный главный экран с поддержкой свайпов
class EnhancedMainScreen extends ConsumerStatefulWidget {
  const EnhancedMainScreen({super.key});

  @override
  ConsumerState<EnhancedMainScreen> createState() => _EnhancedMainScreenState();
}

class _EnhancedMainScreenState extends ConsumerState<EnhancedMainScreen>
    with TickerProviderStateMixin, SwipeBackMixin {
  late PageController _pageController;
  late TabController _tabController;
  int _currentIndex = 0;
  bool _isQuickNavVisible = true;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      title: 'Главное',
      icon: Icons.home,
      selectedIcon: Icons.home,
      page: const HomeScreen(),
    ),
    NavigationItem(
      title: 'Лента',
      icon: Icons.dynamic_feed,
      selectedIcon: Icons.dynamic_feed,
      page: const EnhancedFeedScreen(),
    ),
    NavigationItem(
      title: 'Заявки',
      icon: Icons.assignment,
      selectedIcon: Icons.assignment,
      page: const RequestsScreen(),
    ),
    NavigationItem(
      title: 'Чаты',
      icon: Icons.chat,
      selectedIcon: Icons.chat,
      page: const ChatsScreen(),
    ),
    NavigationItem(
      title: 'Идеи',
      icon: Icons.lightbulb,
      selectedIcon: Icons.lightbulb,
      page: const EnhancedIdeasScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _tabController = TabController(length: _navigationItems.length, vsync: this);
    
    // Слушаем изменения в TabController
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleSystemBack();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(_navigationItems[_currentIndex].title),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          if (_currentIndex == 0) // Главная
            IconButton(
              onPressed: () => context.go('/promos'),
              icon: const Icon(Icons.local_offer_outlined),
              tooltip: 'Акции',
            ),
          if (_currentIndex == 0) // Главная
            IconButton(
              onPressed: () => context.go('/settings'),
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Настройки',
            ),
        ],
      ),
      body: wrapWithSwipeBack(
        Column(
          children: [
            Expanded(
              child: GestureDetector(
                onPanEnd: (details) {
                  // Определяем направление свайпа
                  if (details.velocity.pixelsPerSecond.dx > 500) {
                    // Свайп вправо - предыдущая вкладка
                    if (_currentIndex > 0) {
                      _animateToTab(_currentIndex - 1);
                    }
                  } else if (details.velocity.pixelsPerSecond.dx < -500) {
                    // Свайп влево - следующая вкладка
                    if (_currentIndex < _navigationItems.length - 1) {
                      _animateToTab(_currentIndex + 1);
                    }
                  }
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeInOut)),
                      ),
                      child: child,
                    );
                  },
                  child: Container(
                    key: ValueKey(_currentIndex),
                    child: _navigationItems[_currentIndex].page,
                  ),
                ),
              ),
            ),
            if (_isQuickNavVisible) _buildQuickNavigation(),
            _buildBottomNavigation(),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 1 // Лента
          ? FloatingActionButton(
              onPressed: _createPost,
              child: const Icon(Icons.add),
            )
          : _currentIndex == 4 // Идеи
              ? FloatingActionButton(
                  onPressed: _createIdea,
                  child: const Icon(Icons.add),
                )
              : null,
      ),
    );
  }

  Widget _buildPage(Widget page) {
    return SwipeBackWrapper(
      enableSwipeBack: true, // Включаем свайп назад для лучшего UX
      child: page,
    );
  }

  Widget _buildQuickNavigation() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isQuickNavVisible ? 60 : 0,
      child: _isQuickNavVisible
          ? const QuickNavigationBar()
          : const SizedBox.shrink(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          onTap: (index) {
            _animateToTab(index);
          },
          tabs: _navigationItems.map((item) {
            final isSelected = _navigationItems.indexOf(item) == _currentIndex;
            return Tab(
              icon: Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: 24,
              ),
              text: item.title,
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Переключить видимость быстрой навигации
  void toggleQuickNavigation() {
    setState(() {
      _isQuickNavVisible = !_isQuickNavVisible;
    });
  }

  /// Создать новый пост
  void _createPost() {
    // TODO: Реализовать создание поста
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Создание поста будет реализовано')),
    );
  }

  /// Создать новую идею
  void _createIdea() {
    // TODO: Реализовать создание идеи
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Создание идеи будет реализовано')),
    );
  }

  /// Анимированное переключение на вкладку
  void _animateToTab(int index) {
    if (index >= 0 && index < _navigationItems.length && index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      _tabController.animateTo(index);
    }
  }

  /// Перейти к определённой вкладке
  void navigateToTab(int index) {
    _animateToTab(index);
  }

  /// Обработка системной кнопки "назад"
  void _handleSystemBack() {
    // Если мы на главной вкладке, показываем диалог выхода
    if (_currentIndex == 0) {
      _showExitDialog();
    } else {
      // Иначе переходим на главную вкладку
      _animateToTab(0);
    }
  }

  /// Показать диалог выхода из приложения
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход из приложения'),
        content: const Text('Вы действительно хотите выйти из приложения?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Выход из приложения
              SystemNavigator.pop();
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  /// Перейти к следующей вкладке
  void nextTab() {
    if (_currentIndex < _navigationItems.length - 1) {
      navigateToTab(_currentIndex + 1);
    }
  }

  /// Перейти к предыдущей вкладке
  void previousTab() {
    if (_currentIndex > 0) {
      navigateToTab(_currentIndex - 1);
    }
  }
}

/// Элемент навигации
class NavigationItem {
  const NavigationItem({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });

  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}

/// Провайдер для главного экрана
final enhancedMainScreenProvider = Provider<EnhancedMainScreen>((ref) {
  return const EnhancedMainScreen();
});

/// Провайдер для текущего индекса вкладки
final currentTabIndexProvider = StateProvider<int>((ref) => 0);

/// Провайдер для видимости быстрой навигации
final quickNavVisibleProvider = StateProvider<bool>((ref) => true);
