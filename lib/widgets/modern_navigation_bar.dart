import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Современная навигационная панель с Material Design 3
class ModernNavigationBar extends ConsumerStatefulWidget {
  const ModernNavigationBar({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int>? onTap;

  @override
  ConsumerState<ModernNavigationBar> createState() => _ModernNavigationBarState();
}

class _ModernNavigationBarState extends ConsumerState<ModernNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

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
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTap(int index) {
    if (index != widget.currentIndex) {
      HapticFeedback.lightImpact();
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
      widget.onTap?.call(index);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _buildNavigationItems(),
        ),
      ),
    ),
  );

  List<Widget> _buildNavigationItems() => [
    _buildNavItem(0, Icons.home_outlined, Icons.home, 'Главная'),
    _buildNavItem(1, Icons.newspaper_outlined, Icons.newspaper, 'Лента'),
    _buildNavItem(2, Icons.assignment_outlined, Icons.assignment, 'Заявки'),
    _buildNavItem(3, Icons.chat_bubble_outline, Icons.chat_bubble, 'Чаты'),
    _buildNavItem(4, Icons.lightbulb_outline, Icons.lightbulb, 'Идеи'),
  ];

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = widget.currentIndex == index;

    return Expanded(
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: isSelected ? _scaleAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () => _onItemTap(index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).textTheme.bodyMedium?.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Плавающая кнопка действий
class ModernFAB extends StatefulWidget {
  const ModernFAB({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.tooltip = 'Создать',
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;

  @override
  State<ModernFAB> createState() => _ModernFABState();
}

class _ModernFABState extends State<ModernFAB> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.1,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPressed() {
    HapticFeedback.mediumImpact();
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animationController,
    builder: (context, child) => Transform.scale(
      scale: _scaleAnimation.value,
      child: Transform.rotate(
        angle: _rotationAnimation.value,
        child: FloatingActionButton(
          onPressed: _onPressed,
          tooltip: widget.tooltip,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Icon(widget.icon, size: 28),
        ),
      ),
    ),
  );
}

/// Контейнер для экрана с современной навигацией
class ModernScaffold extends StatelessWidget {
  const ModernScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.currentIndex = 0,
    this.onNavigationTap,
    this.fab,
    this.floatingActionButtonLocation = FloatingActionButtonLocation.endFloat,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final int currentIndex;
  final ValueChanged<int>? onNavigationTap;
  final Widget? fab;
  final FloatingActionButtonLocation floatingActionButtonLocation;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: appBar,
    body: body,
    bottomNavigationBar: ModernNavigationBar(currentIndex: currentIndex, onTap: onNavigationTap),
    floatingActionButton: fab,
    floatingActionButtonLocation: floatingActionButtonLocation,
  );
}
