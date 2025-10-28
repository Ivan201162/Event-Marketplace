import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

/// Анимированное нижнее меню с плавными переходами
class AnimatedBottomNavigation extends StatefulWidget {
  const AnimatedBottomNavigation({
    required this.items, required this.onTap, super.key,
    this.currentIndex = 0,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
    this.animationDuration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.height = 60,
    this.iconSize = 24,
    this.showLabels = true,
    this.labelStyle,
  });

  final List<BottomNavigationItem> items;
  final ValueChanged<int> onTap;
  final int currentIndex;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final Duration animationDuration;
  final Curve curve;
  final double height;
  final double iconSize;
  final bool showLabels;
  final TextStyle? labelStyle;

  @override
  State<AnimatedBottomNavigation> createState() =>
      _AnimatedBottomNavigationState();
}

class _AnimatedBottomNavigationState extends State<AnimatedBottomNavigation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: widget.animationDuration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (index != widget.currentIndex) {
      _controller.forward().then((_) {
        _controller.reverse();
      });
      widget.onTap(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.primaryColor;
    final activeColor = widget.activeColor ?? theme.colorScheme.onPrimary;
    final inactiveColor = widget.inactiveColor ??
        theme.colorScheme.onPrimary.withValues(alpha: 0.6);

    return Container(
      height: widget.height + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: widget.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == widget.currentIndex;

            return Expanded(
              child: GestureDetector(
                onTap: () => _handleTap(index),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => SizedBox(
                    height: widget.height,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: widget.animationDuration,
                          curve: widget.curve,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? activeColor.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Transform.scale(
                            scale: isSelected ? _scaleAnimation.value : 1.0,
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: widget.iconSize,
                              color: isSelected ? activeColor : inactiveColor,
                            ),
                          ),
                        ),
                        if (widget.showLabels) ...[
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: widget.animationDuration,
                            style: (widget.labelStyle ??
                                    theme.textTheme.labelSmall)!
                                .copyWith(
                              color: isSelected ? activeColor : inactiveColor,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            child: Text(item.label),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Элемент нижнего меню
class BottomNavigationItem {
  const BottomNavigationItem(
      {required this.icon, required this.activeIcon, required this.label,});

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Кривое анимированное нижнее меню
class CurvedBottomNavigation extends StatefulWidget {
  const CurvedBottomNavigation({
    required this.items, required this.onTap, super.key,
    this.currentIndex = 0,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
    this.animationDuration = const Duration(milliseconds: 300),
    this.height = 60,
    this.iconSize = 24,
  });

  final List<IconData> items;
  final ValueChanged<int> onTap;
  final int currentIndex;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final Duration animationDuration;
  final double height;
  final double iconSize;

  @override
  State<CurvedBottomNavigation> createState() => _CurvedBottomNavigationState();
}

class _CurvedBottomNavigationState extends State<CurvedBottomNavigation> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.primaryColor;
    final activeColor = widget.activeColor ?? theme.colorScheme.onPrimary;
    final inactiveColor = widget.inactiveColor ??
        theme.colorScheme.onPrimary.withValues(alpha: 0.6);

    return CurvedNavigationBar(
      items: widget.items
          .map((icon) => Icon(icon, size: widget.iconSize))
          .toList(),
      onTap: widget.onTap,
      index: widget.currentIndex,
      height: widget.height,
      color: backgroundColor,
      buttonBackgroundColor: activeColor.withValues(alpha: 0.1),
      backgroundColor: Colors.transparent,
      animationCurve: Curves.easeInOut,
      animationDuration: widget.animationDuration,
    );
  }
}

/// Анимированное плавающее меню
class FloatingBottomNavigation extends StatefulWidget {
  const FloatingBottomNavigation({
    required this.items, required this.onTap, super.key,
    this.currentIndex = 0,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
    this.animationDuration = const Duration(milliseconds: 300),
    this.height = 70,
    this.iconSize = 24,
    this.showLabels = true,
    this.labelStyle,
  });

  final List<BottomNavigationItem> items;
  final ValueChanged<int> onTap;
  final int currentIndex;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final Duration animationDuration;
  final double height;
  final double iconSize;
  final bool showLabels;
  final TextStyle? labelStyle;

  @override
  State<FloatingBottomNavigation> createState() =>
      _FloatingBottomNavigationState();
}

class _FloatingBottomNavigationState extends State<FloatingBottomNavigation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: widget.animationDuration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (index != widget.currentIndex) {
      _controller.forward().then((_) {
        _controller.reverse();
      });
      widget.onTap(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.cardColor;
    final activeColor = widget.activeColor ?? theme.primaryColor;
    final inactiveColor = widget.inactiveColor ??
        theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.height / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        height: widget.height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: widget.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == widget.currentIndex;

            return Expanded(
              child: GestureDetector(
                onTap: () => _handleTap(index),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => SizedBox(
                    height: widget.height,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: widget.animationDuration,
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? activeColor.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Transform.scale(
                            scale: isSelected ? _scaleAnimation.value : 1.0,
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: widget.iconSize,
                              color: isSelected ? activeColor : inactiveColor,
                            ),
                          ),
                        ),
                        if (widget.showLabels) ...[
                          const SizedBox(height: 2),
                          AnimatedDefaultTextStyle(
                            duration: widget.animationDuration,
                            style: (widget.labelStyle ??
                                    theme.textTheme.labelSmall)!
                                .copyWith(
                              color: isSelected ? activeColor : inactiveColor,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 10,
                            ),
                            child: Text(item.label),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
