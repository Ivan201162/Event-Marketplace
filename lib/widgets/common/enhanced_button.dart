import 'package:flutter/material.dart';

/// Улучшенная кнопка с анимациями и состояниями
class EnhancedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonType type;
  final ButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const EnhancedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: _buildButton(isEnabled),
        );
      },
    );
  }

  Widget _buildButton(bool isEnabled) {
    switch (widget.type) {
      case ButtonType.primary:
        return _buildElevatedButton(isEnabled);
      case ButtonType.secondary:
        return _buildOutlinedButton(isEnabled);
      case ButtonType.text:
        return _buildTextButton(isEnabled);
      case ButtonType.icon:
        return _buildIconButton(isEnabled);
    }
  }

  Widget _buildElevatedButton(bool isEnabled) {
    return SizedBox(
      width: widget.isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isEnabled ? _handlePress : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor ?? _getPrimaryColor(),
          foregroundColor: widget.foregroundColor ?? Colors.white,
          elevation: isEnabled ? 2 : 0,
          shadowColor: _getPrimaryColor().withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius()),
          ),
          padding: _getPadding(),
          minimumSize: _getMinimumSize(),
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildOutlinedButton(bool isEnabled) {
    return SizedBox(
      width: widget.isFullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: isEnabled ? _handlePress : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: widget.foregroundColor ?? _getPrimaryColor(),
          side: BorderSide(
            color: isEnabled 
                ? (widget.backgroundColor ?? _getPrimaryColor())
                : Colors.grey,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius()),
          ),
          padding: _getPadding(),
          minimumSize: _getMinimumSize(),
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildTextButton(bool isEnabled) {
    return SizedBox(
      width: widget.isFullWidth ? double.infinity : null,
      child: TextButton(
        onPressed: isEnabled ? _handlePress : null,
        style: TextButton.styleFrom(
          foregroundColor: widget.foregroundColor ?? _getPrimaryColor(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius()),
          ),
          padding: _getPadding(),
          minimumSize: _getMinimumSize(),
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildIconButton(bool isEnabled) {
    return IconButton(
      onPressed: isEnabled ? _handlePress : null,
      icon: _buildButtonContent(),
      style: IconButton.styleFrom(
        backgroundColor: widget.backgroundColor ?? _getPrimaryColor().withOpacity(0.1),
        foregroundColor: widget.foregroundColor ?? _getPrimaryColor(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        ),
        padding: _getPadding(),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (widget.isLoading) {
      return SizedBox(
        width: _getLoadingSize(),
        height: _getLoadingSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.foregroundColor ?? Colors.white,
          ),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: _getIconSize()),
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: TextStyle(
              fontSize: _getFontSize(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      widget.text,
      style: TextStyle(
        fontSize: _getFontSize(),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _handlePress() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onPressed?.call();
  }

  Color _getPrimaryColor() {
    return Theme.of(context).primaryColor;
  }

  double _getBorderRadius() {
    switch (widget.size) {
      case ButtonSize.small:
        return 8;
      case ButtonSize.medium:
        return 12;
      case ButtonSize.large:
        return 16;
    }
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  Size _getMinimumSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return const Size(80, 32);
      case ButtonSize.medium:
        return const Size(120, 44);
      case ButtonSize.large:
        return const Size(160, 56);
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 12;
      case ButtonSize.medium:
        return 14;
      case ButtonSize.large:
        return 16;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }

  double _getLoadingSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }
}

/// Типы кнопок
enum ButtonType {
  primary,
  secondary,
  text,
  icon,
}

/// Размеры кнопок
enum ButtonSize {
  small,
  medium,
  large,
}
