import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class GoldButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final bool filledInitially;
  final EdgeInsets padding;
  final double radius;

  const GoldButton({
    super.key,
    required this.text,
    this.onTap,
    this.filledInitially = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    this.radius = 22,
  });

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final filled = _pressed || widget.filledInitially;
    final bg = filled ? AppColors.gold : Colors.transparent;
    final fg = filled ? Colors.black : AppColors.gold;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(color: AppColors.gold, width: 1.2),
        ),
        child: Center(
          child: Text(
            widget.text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              color: fg,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

