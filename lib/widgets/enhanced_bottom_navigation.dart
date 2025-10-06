import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Улучшенный BottomNavigationBar с проверкой удобства использования
class EnhancedBottomNavigationBar extends ConsumerStatefulWidget {
  const EnhancedBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int>? onTap;

  @override
  ConsumerState<EnhancedBottomNavigationBar> createState() =>
      _EnhancedBottomNavigationBarState();
}

class _EnhancedBottomNavigationBarState
    extends ConsumerState<EnhancedBottomNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _fadeAnimation = Tween<double>(
      begin: 1,
      end: 0.8,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _animateButton() async {
    await _animationController.forward();
    _animationController.reverse();
  }

  void _onItemTap(int index) {
    // Анимация нажатия
    _animateButton();

    // Haptic feedback
    // HapticFeedback.lightImpact();

    // Вызов callback
    widget.onTap?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;

    // Для десктопа используем NavigationRail
    if (isDesktop) {
      return NavigationRail(
        selectedIndex: widget.currentIndex,
        onDestinationSelected: _onItemTap,
        labelType: NavigationRailLabelType.all,
        backgroundColor: theme.colorScheme.surface,
        selectedIconTheme: IconThemeData(
          color: theme.colorScheme.primary,
        ),
        unselectedIconTheme: IconThemeData(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        selectedLabelTextStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        destinations: _getNavigationDestinations(),
      );
    }

    // Для мобильных устройств и планшетов используем BottomNavigationBar
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24.0 : 16.0,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _buildNavigationItems(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<NavigationRailDestination> _getNavigationDestinations() => [
        const NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Главная'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: Text('Поиск'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: Text('Сообщения'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.lightbulb_outline),
          selectedIcon: Icon(Icons.lightbulb),
          label: Text('Идеи'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: Text('Заказы'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Профиль'),
        ),
      ];

  List<Widget> _buildNavigationItems() {
    final theme = Theme.of(context);
    final items = [
      const _NavigationItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Главная',
        index: 0,
      ),
      const _NavigationItem(
        icon: Icons.search_outlined,
        activeIcon: Icons.search,
        label: 'Поиск',
        index: 1,
      ),
      const _NavigationItem(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Сообщения',
        index: 2,
      ),
      const _NavigationItem(
        icon: Icons.lightbulb_outline,
        activeIcon: Icons.lightbulb,
        label: 'Идеи',
        index: 3,
      ),
      const _NavigationItem(
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        label: 'Заказы',
        index: 4,
      ),
      const _NavigationItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Профиль',
        index: 5,
      ),
    ];

    return items.map((item) {
      final isSelected = widget.currentIndex == item.index;
      return Expanded(
        child: _NavigationItemWidget(
          item: item,
          isSelected: isSelected,
          onTap: () => _onItemTap(item.index),
        ),
      );
    }).toList();
  }
}

/// Виджет элемента навигации
class _NavigationItemWidget extends StatefulWidget {
  const _NavigationItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_NavigationItemWidget> createState() => _NavigationItemWidgetState();
}

class _NavigationItemWidgetState extends State<_NavigationItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.9,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _colorAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didUpdateWidget(_NavigationItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final color = Color.lerp(
            theme.colorScheme.onSurfaceVariant,
            theme.colorScheme.primary,
            _colorAnimation.value,
          )!;

          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16.0 : 12.0,
                vertical: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.isSelected
                          ? widget.item.activeIcon
                          : widget.item.icon,
                      key: ValueKey(widget.isSelected),
                      color: color,
                      size: isTablet ? 28.0 : 24.0,
                    ),
                  ),
                  if (isTablet) ...[
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      child: Text(widget.item.label),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Модель элемента навигации
class _NavigationItem {
  const _NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
}

/// Виджет для отображения уведомлений на элементах навигации
class NavigationBadge extends StatelessWidget {
  const NavigationBadge({
    super.key,
    required this.child,
    this.count,
    this.showDot = false,
  });

  final Widget child;
  final int? count;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    if (count == null && !showDot) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -8,
          top: -8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
            child: Center(
              child: count != null
                  ? Text(
                      count! > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const SizedBox(
                      width: 8,
                      height: 8,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Виджет для отображения подсказок навигации
class NavigationTooltip extends StatelessWidget {
  const NavigationTooltip({
    super.key,
    required this.message,
    required this.child,
  });

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: message,
        preferBelow: false,
        child: child,
      );
}
