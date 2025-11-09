import 'package:event_marketplace_app/core/app_components.dart';
import 'package:event_marketplace_app/screens/chat/chat_list_screen_improved.dart';
import 'package:event_marketplace_app/screens/feed/feed_screen_full.dart';
import 'package:event_marketplace_app/screens/home/home_screen_simple.dart';
import 'package:event_marketplace_app/screens/ideas/ideas_screen.dart';
import 'package:event_marketplace_app/screens/requests/requests_screen_improved.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      label: '', // Без подписи
      screen: HomeScreenSimple(),
    ),
    const NavigationItem(
      icon: Icons.grid_3x3_outlined,
      activeIcon: Icons.grid_3x3,
      label: '', // Без подписи
      screen: FeedScreenFull(),
    ),
    const NavigationItem(
      icon: Icons.work_outline,
      activeIcon: Icons.work,
      label: '', // Без подписи
      screen: RequestsScreenImproved(),
    ),
    const NavigationItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble_outline,
      label: '', // Без подписи
      screen: ChatListScreenImproved(),
    ),
    const NavigationItem(
      icon: Icons.lightbulb_outline,
      activeIcon: Icons.lightbulb_outline,
      label: '', // Без подписи
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
    // Проверка авторизации - не показываем MainScreen без пользователя
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Перенаправляем на auth-gate
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/auth-gate');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 56, // Фиксированная высота 56dp
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        final tabNames = ['home', 'feed', 'requests', 'chats', 'ideas'];
                        if (index < tabNames.length) {
                          debugLog("NAVBAR_TAP:${tabNames[index]}");
                        }
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            color: isActive
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          size: 24, // Минималистичные иконки, без подписей
                        ),
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
