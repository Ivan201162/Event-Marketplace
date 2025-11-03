import 'package:event_marketplace_app/core/app_components.dart';
import 'package:event_marketplace_app/core/app_theme.dart';
import 'package:event_marketplace_app/screens/chat/chat_list_screen_improved.dart';
import 'package:event_marketplace_app/screens/feed/feed_screen_improved.dart';
import 'package:event_marketplace_app/screens/home/home_screen_simple.dart';
import 'package:event_marketplace_app/screens/ideas/ideas_screen.dart';
import 'package:event_marketplace_app/screens/requests/requests_screen_improved.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Main navigation screen with bottom navigation
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late PageController _pageController;

  final List<NavigationItem> _navigationItems = [
    const NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Главная',
      screen: HomeScreenSimple(),
    ),
    const NavigationItem(
      icon: Icons.dynamic_feed_outlined,
      activeIcon: Icons.dynamic_feed,
      label: 'Лента',
      screen: FeedScreenImproved(),
    ),
    const NavigationItem(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
      label: 'Заявки',
      screen: RequestsScreenImproved(),
    ),
    const NavigationItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Чаты',
      screen: ChatListScreenImproved(),
    ),
    const NavigationItem(
      icon: Icons.lightbulb_outline,
      activeIcon: Icons.lightbulb,
      label: 'Идеи',
      screen: IdeasScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ),);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_currentIndex == 0) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Выйти из приложения?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Нет'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Да'),
                ),
              ],
            ),
          );
          if (shouldExit == true && mounted) {
            SystemNavigator.pop();
          }
        } else {
          setState(() => _currentIndex = 0);
          _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
      },
      child: Scaffold(
        body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _navigationItems.map((item) => item.screen).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.surfaceColor,
              AppTheme.backgroundColor,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _navigationItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isActive = index == _currentIndex;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (index != _currentIndex) {
                        _animationController.forward().then((_) {
                          _animationController.reverse();
                        });
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12,),
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? const LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryVariant,
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        border: isActive
                            ? Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _scaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: isActive ? _scaleAnimation.value : 1.0,
                                child: Icon(
                                  isActive ? item.activeIcon : item.icon,
                                  color: isActive
                                      ? Colors.white
                                      : Colors.grey[600],
                                  size: isActive ? 26 : 24,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Navigation item model
class NavigationItem {

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;
}
