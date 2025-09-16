import 'package:flutter/material.dart';

/// Адаптивная навигационная панель с Material 3 дизайном
class AdaptiveNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final List<NavigationDestination> destinations;
  final bool showLabels;

  const AdaptiveNavigationBar({
    super.key,
    required this.currentIndex,
    this.onTap,
    required this.destinations,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    if (isTablet) {
      // На планшетах используем NavigationRail
      return NavigationRail(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        labelType: showLabels
            ? NavigationRailLabelType.all
            : NavigationRailLabelType.none,
        destinations: destinations
            .map((dest) => NavigationRailDestination(
                  icon: dest.icon,
                  selectedIcon: dest.selectedIcon,
                  label: Text(dest.label),
                ))
            .toList(),
      );
    } else {
      // На телефонах используем NavigationBar
      return NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        destinations: destinations,
      );
    }
  }
}

/// Адаптивный BottomNavigationBar с Material 3 дизайном
class AdaptiveBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final List<BottomNavigationBarItem> items;
  final bool showLabels;

  const AdaptiveBottomNavigationBar({
    super.key,
    required this.currentIndex,
    this.onTap,
    required this.items,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    if (isTablet) {
      // На планшетах используем NavigationBar
      return NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        destinations: items
            .map((item) => NavigationDestination(
                  icon: item.icon,
                  selectedIcon: item.activeIcon,
                  label: item.label ?? '',
                ))
            .toList(),
      );
    } else {
      // На телефонах используем BottomNavigationBar
      return BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: showLabels,
        showUnselectedLabels: showLabels,
        items: items,
      );
    }
  }
}

/// Адаптивный Drawer с Material 3 дизайном
class AdaptiveDrawer extends StatelessWidget {
  final Widget? header;
  final List<Widget> children;
  final Widget? footer;

  const AdaptiveDrawer({
    super.key,
    this.header,
    required this.children,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Drawer(
      width: isTablet ? 300 : null,
      child: Column(
        children: [
          if (header != null) ...[
            header!,
            const Divider(),
          ],
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: children,
            ),
          ),
          if (footer != null) ...[
            const Divider(),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Адаптивный FloatingActionButton с Material 3 дизайном
class AdaptiveFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool mini;

  const AdaptiveFloatingActionButton({
    super.key,
    this.onPressed,
    required this.child,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      mini: mini && !isTablet,
      child: child,
    );
  }
}

/// Адаптивный SpeedDial с Material 3 дизайном
class AdaptiveSpeedDial extends StatefulWidget {
  final List<SpeedDialChild> children;
  final Widget icon;
  final Widget? activeIcon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool visible;

  const AdaptiveSpeedDial({
    super.key,
    required this.children,
    required this.icon,
    this.activeIcon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.visible = true,
  });

  @override
  State<AdaptiveSpeedDial> createState() => _AdaptiveSpeedDialState();
}

class _AdaptiveSpeedDialState extends State<AdaptiveSpeedDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isOpen) ...[
          ...widget.children.map((child) => ScaleTransition(
                scale: _animation,
                child: FadeTransition(
                  opacity: _animation,
                  child: child,
                ),
              )),
          const SizedBox(height: 8),
        ],
        FloatingActionButton(
          onPressed: _toggle,
          tooltip: widget.tooltip,
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.foregroundColor,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: _isOpen ? (widget.activeIcon ?? widget.icon) : widget.icon,
          ),
        ),
      ],
    );
  }
}

/// Элемент SpeedDial
class SpeedDialChild extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SpeedDialChild({
    super.key,
    required this.child,
    this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FloatingActionButton.small(
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        child: child,
      ),
    );
  }
}

/// Адаптивный TabBar с Material 3 дизайном
class AdaptiveTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController? controller;
  final List<Widget> tabs;
  final bool isScrollable;
  final TabBarIndicatorSize? indicatorSize;
  final Color? indicatorColor;
  final double? indicatorWeight;
  final EdgeInsets? indicatorPadding;
  final bool automaticIndicatorColorAdjustment;

  const AdaptiveTabBar({
    super.key,
    this.controller,
    required this.tabs,
    this.isScrollable = false,
    this.indicatorSize,
    this.indicatorColor,
    this.indicatorWeight,
    this.indicatorPadding,
    this.automaticIndicatorColorAdjustment = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return TabBar(
      controller: controller,
      tabs: tabs,
      isScrollable: isScrollable || isTablet,
      indicatorSize: indicatorSize,
      indicatorColor: indicatorColor,
      indicatorWeight: indicatorWeight ?? 2.0,
      indicatorPadding: indicatorPadding ?? EdgeInsets.zero,
      automaticIndicatorColorAdjustment: automaticIndicatorColorAdjustment,
      labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
      unselectedLabelStyle: Theme.of(context).textTheme.titleSmall,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Адаптивный AppBar с TabBar
class AdaptiveAppBarWithTabs extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final TabController? tabController;
  final List<Widget> tabs;
  final bool isScrollable;

  const AdaptiveAppBarWithTabs({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.tabController,
    required this.tabs,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor:
          backgroundColor ?? Theme.of(context).colorScheme.inversePrimary,
      foregroundColor: foregroundColor,
      elevation: elevation,
      bottom: AdaptiveTabBar(
        controller: tabController,
        tabs: tabs,
        isScrollable: isScrollable,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight * 2);
}

/// Адаптивный SearchBar с Material 3 дизайном
class AdaptiveSearchBar extends StatefulWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool enabled;
  final Widget? leading;
  final List<Widget>? trailing;

  const AdaptiveSearchBar({
    super.key,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.enabled = true,
    this.leading,
    this.trailing,
  });

  @override
  State<AdaptiveSearchBar> createState() => _AdaptiveSearchBarState();
}

class _AdaptiveSearchBarState extends State<AdaptiveSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return SearchBar(
      controller: _controller,
      hintText: widget.hintText ?? 'Поиск...',
      leading: widget.leading ?? const Icon(Icons.search),
      trailing: widget.trailing,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      enabled: widget.enabled,
      constraints: BoxConstraints(
        minHeight: isTablet ? 56.0 : 48.0,
      ),
    );
  }
}
