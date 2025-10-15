import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/swipe_back_wrapper.dart';
import 'enhanced_chats_screen.dart';
import 'enhanced_feed_screen.dart';
import 'enhanced_home_screen_v2.dart';
import 'enhanced_ideas_screen.dart';
import 'enhanced_requests_screen.dart';

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

  final List<NavigationItem> _navigationItems = [
    const NavigationItem(
      title: 'Главное',
      icon: Icons.home,
      selectedIcon: Icons.home,
      page: EnhancedHomeScreenV2(),
    ),
    const NavigationItem(
      title: 'Лента',
      icon: Icons.dynamic_feed,
      selectedIcon: Icons.dynamic_feed,
      page: EnhancedFeedScreen(),
    ),
    const NavigationItem(
      title: 'Заявки',
      icon: Icons.assignment,
      selectedIcon: Icons.assignment,
      page: EnhancedRequestsScreen(),
    ),
    const NavigationItem(
      title: 'Чаты',
      icon: Icons.chat,
      selectedIcon: Icons.chat,
      page: EnhancedChatsScreen(),
    ),
    const NavigationItem(
      title: 'Идеи',
      icon: Icons.lightbulb,
      selectedIcon: Icons.lightbulb,
      page: EnhancedIdeasScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _tabController =
        TabController(length: _navigationItems.length, vsync: this);

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
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop) {
            _handleSystemBack();
          }
        },
        child: Scaffold(
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
                      transitionBuilder: (child, animation) => SlideTransition(
                        position: animation.drive(
                          Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).chain(CurveTween(curve: Curves.easeInOut)),
                        ),
                        child: child,
                      ),
                      child: Container(
                        key: ValueKey(_currentIndex),
                        child: _navigationItems[_currentIndex].page,
                      ),
                    ),
                  ),
                ),
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

  Widget _buildPage(Widget page) => SwipeBackWrapper(
        child: page,
      );

  Widget _buildBottomNavigation() => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            onTap: _animateToTab,
            tabs: _navigationItems.map((item) {
              final isSelected =
                  _navigationItems.indexOf(item) == _currentIndex;
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
    if (index >= 0 &&
        index < _navigationItems.length &&
        index != _currentIndex) {
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

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Event';
      case 1:
        return 'Event';
      case 2:
        return 'Event';
      case 3:
        return 'Event';
      case 4:
        return 'Event';
      default:
        return 'Event';
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
final enhancedMainScreenProvider =
    Provider<EnhancedMainScreen>((ref) => const EnhancedMainScreen());

/// Провайдер для текущего индекса вкладки (мигрирован с StateProvider)
class CurrentTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTabIndex(int index) {
    state = index;
  }
}

/// Провайдер для видимости быстрой навигации (мигрирован с StateProvider)
class QuickNavVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setVisible(bool visible) {
    state = visible;
  }

  void toggle() {
    state = !state;
  }
}

final currentTabIndexProvider =
    NotifierProvider<CurrentTabIndexNotifier, int>(CurrentTabIndexNotifier.new);
final quickNavVisibleProvider = NotifierProvider<QuickNavVisibleNotifier, bool>(
  QuickNavVisibleNotifier.new,
);
