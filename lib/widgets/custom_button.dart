import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
    this.isPrimary = true,
    this.icon,
    this.padding,
    this.borderRadius,
    this.preventDoubleTap = true,
    this.cooldownDuration = const Duration(milliseconds: 1000),
  });
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading;
  final bool isPrimary;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final bool preventDoubleTap;
  final Duration cooldownDuration;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isInCooldown = false;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _getOnPressed(),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.backgroundColor ??
                (widget.isPrimary ? Colors.blue : Colors.grey.shade200),
            foregroundColor: widget.textColor ??
                (widget.isPrimary ? Colors.white : Colors.black87),
            elevation: 0,
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius ?? 8),
            ),
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 20),
                      const SizedBox(width: 8)
                    ],
                    Text(
                      widget.text,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
        ),
      );

  VoidCallback? _getOnPressed() {
    if (widget.isLoading || _isInCooldown) {
      return null;
    }

    if (widget.onPressed == null) {
      return null;
    }

    if (!widget.preventDoubleTap) {
      return widget.onPressed;
    }

    return () {
      widget.onPressed!();
      _startCooldown();
    };
  }

  void _startCooldown() {
    if (!widget.preventDoubleTap) return;

    setState(() {
      _isInCooldown = true;
    });

    Future.delayed(widget.cooldownDuration, () {
      if (mounted) {
        setState(() {
          _isInCooldown = false;
        });
      }
    });
  }
}
