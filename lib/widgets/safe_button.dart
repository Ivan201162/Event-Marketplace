import 'package:flutter/material.dart';

/// Безопасная кнопка с защитой от повторных нажатий и индикатором загрузки
class SafeButton extends StatefulWidget {
  const SafeButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
    this.cooldownDuration = const Duration(milliseconds: 1000),
    this.preventDoubleTap = true,
    this.style,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Duration cooldownDuration;
  final bool preventDoubleTap;
  final ButtonStyle? style;

  @override
  State<SafeButton> createState() => _SafeButtonState();
}

class _SafeButtonState extends State<SafeButton> {
  bool _isInCooldown = false;

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: _getOnPressed(),
        style: widget.style,
        child: widget.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : widget.child,
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

/// Безопасная кнопка с иконкой
class SafeIconButton extends StatefulWidget {
  const SafeIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.cooldownDuration = const Duration(milliseconds: 1000),
    this.preventDoubleTap = true,
    this.tooltip,
    this.style,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Duration cooldownDuration;
  final bool preventDoubleTap;
  final String? tooltip;
  final ButtonStyle? style;

  @override
  State<SafeIconButton> createState() => _SafeIconButtonState();
}

class _SafeIconButtonState extends State<SafeIconButton> {
  bool _isInCooldown = false;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: _getOnPressed(),
        icon: widget.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : widget.icon,
        tooltip: widget.tooltip,
        style: widget.style,
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
