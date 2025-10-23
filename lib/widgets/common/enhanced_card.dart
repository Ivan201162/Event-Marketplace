import 'package:flutter/material.dart';

/// Улучшенная карточка с анимациями и состояниями
class EnhancedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? elevation;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final bool isAnimated;
  final bool isSelected;
  final bool isLoading;

  const EnhancedCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.elevation,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.isAnimated = true,
    this.isSelected = false,
    this.isLoading = false,
  });

  @override
  State<EnhancedCard> createState() => _EnhancedCardState();
}

class _EnhancedCardState extends State<EnhancedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 2,
      end: (widget.elevation ?? 2) + 4,
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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isAnimated ? _scaleAnimation.value : 1.0,
          child: _buildCard(),
        );
      },
    );
  }

  Widget _buildCard() {
    return Container(
      margin: widget.margin,
      child: Material(
        color: widget.backgroundColor ?? Theme.of(context).cardColor,
        elevation: widget.isAnimated 
            ? _elevationAnimation.value 
            : (widget.elevation ?? 2),
        shadowColor: Colors.black.withOpacity(0.1),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
        child: InkWell(
          onTap: widget.onTap != null ? _handleTap : null,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          child: Container(
            padding: widget.padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
              border: widget.border,
              color: widget.isSelected 
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : null,
            ),
            child: widget.isLoading 
                ? _buildLoadingContent()
                : widget.child,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      children: [
        Container(
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 14,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  void _handleTap() {
    if (widget.isAnimated) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
    widget.onTap?.call();
  }
}

/// Карточка с заголовком
class EnhancedCardWithHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onTap;
  final Widget? action;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? elevation;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool isAnimated;
  final bool isSelected;

  const EnhancedCardWithHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.onTap,
    this.action,
    this.padding,
    this.margin,
    this.elevation,
    this.backgroundColor,
    this.borderRadius,
    this.isAnimated = true,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedCard(
      onTap: onTap,
      padding: padding,
      margin: margin,
      elevation: elevation,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      isAnimated: isAnimated,
      isSelected: isSelected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Карточка статистики
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: color ?? Theme.of(context).primaryColor,
              size: 32,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color ?? Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Карточка действия
class ActionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  final bool isEnabled;

  const ActionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.color,
    this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedCard(
      onTap: isEnabled ? onTap : null,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            icon,
            color: isEnabled 
                ? (color ?? Theme.of(context).primaryColor)
                : Colors.grey,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isEnabled ? null : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
