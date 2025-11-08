import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Бейдж для ролей/цен/рейтингов
class ChipBadge extends StatelessWidget {
  const ChipBadge({
    required this.label,
    this.icon,
    this.color,
    this.backgroundColor,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = Theme.of(context).colorScheme.primary;
    final defaultBg = isDark
        ? defaultColor.withOpacity(0.15)
        : defaultColor.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color ?? defaultColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color ?? defaultColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

