import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Кнопка K1: только обводка (1.2px), скругление 12-14px, hover/pressed эффекты
class OutlinedButtonX extends StatefulWidget {
  const OutlinedButtonX({
    required this.text,
    this.onTap,
    this.icon,
    this.padding,
    this.borderRadius = 14,
    super.key,
  });

  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  @override
  State<OutlinedButtonX> createState() => _OutlinedButtonXState();
}

class _OutlinedButtonXState extends State<OutlinedButtonX> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final fillColor = primaryColor.withOpacity(_pressed ? 0.06 : 0.03);
    final borderColor = _pressed ? primaryColor : primaryColor.withOpacity(0.8);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 18, color: primaryColor),
              const SizedBox(width: 8),
            ],
            Text(
              widget.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

