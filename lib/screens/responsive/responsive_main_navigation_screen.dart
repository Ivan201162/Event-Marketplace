import 'package:flutter/material.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive/responsive_widgets.dart';
import 'responsive_home_screen.dart';
import 'responsive_feed_screen.dart';
import 'responsive_requests_screen.dart';
import 'responsive_chat_screen.dart';
import 'responsive_ideas_screen.dart';
import 'responsive_profile_screen.dart';

/// Адаптивный главный экран навигации
class ResponsiveMainNavigationScreen extends StatefulWidget {
  const ResponsiveMainNavigationScreen({super.key});

  @override
  State<ResponsiveMainNavigationScreen> createState() => _ResponsiveMainNavigationScreenState();
}

class _ResponsiveMainNavigationScreenState extends State<ResponsiveMainNavigationScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<NavigationItem> _navigationItems = [
    const NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Главная',
      screen: ResponsiveHomeScreen(),
    ),
    const NavigationItem(
      icon: Icons.dynamic_feed_outlined,
      activeIcon: Icons.dynamic_feed,
      label: 'Лента',
      screen: ResponsiveFeedScreen(),
    ),
    const NavigationItem(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
      label: 'Заявки',
      screen: ResponsiveRequestsScreen(),
    ),
    const NavigationItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Чаты',
      screen: ResponsiveChatScreen(),
    ),
    const NavigationItem(
      icon: Icons.lightbulb_outline,
      activeIcon: Icons.lightbulb,
      label: 'Идеи',
      screen: ResponsiveIdeasScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onItemTapped(int index) {
    if (index != _currentIndex) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      body: ResponsiveLayoutBuilder(
        mobile: (context) => _buildMobileLayout(context),
        tablet: (context) => _buildTabletLayout(context),
        desktop: (context) => _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return ResponsiveSafeArea(
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _navigationItems.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                return _navigationItems[index].screen;
              },
            ),
          ),
          ResponsiveBottomNavBar(
            items: _navigationItems.map((item) => BottomNavigationBarItem(
              icon: ResponsiveIcon(item.icon),
              activeIcon: ResponsiveIcon(item.activeIcon),
              label: item.label,
            )).toList(),
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return ResponsiveSafeArea(
      child: Row(
        children: [
          ResponsiveContainer(
            width: ResponsiveUtils.getResponsiveWidth(context, mobile: 0.0, tablet: 0.3, desktop: 0.2),
            child: ResponsiveList(
              children: [
                ResponsiveSpacing(height: 16),
                ..._navigationItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isActive = index == _currentIndex;

                  return ResponsiveCard(
                    child: ResponsiveButton(
                      text: item.label,
                      onPressed: () => _onItemTapped(index),
                      backgroundColor: isActive ? Colors.blue : Colors.transparent,
                      textColor: isActive ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          ResponsiveDivider(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _navigationItems.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                return _navigationItems[index].screen;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return ResponsiveSafeArea(
      child: Row(
        children: [
          ResponsiveContainer(
            width: ResponsiveUtils.getResponsiveWidth(context, mobile: 0.0, tablet: 0.0, desktop: 0.15),
            child: ResponsiveList(
              children: [
                ResponsiveSpacing(height: 16),
                ..._navigationItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isActive = index == _currentIndex;

                  return ResponsiveCard(
                    child: ResponsiveButton(
                      text: item.label,
                      onPressed: () => _onItemTapped(index),
                      backgroundColor: isActive ? Colors.blue : Colors.transparent,
                      textColor: isActive ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          ResponsiveDivider(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _navigationItems.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                return _navigationItems[index].screen;
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Элемент навигации
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
  });
}
