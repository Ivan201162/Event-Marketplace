/// Dynamic Background & Blur Layers - V7.5
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:event_marketplace_app/theme/colors.dart';

/// Построение адаптивного фона
Widget buildBackground(BuildContext context) {
  final colors = AppColors.of(context);
  
  return AnimatedContainer(
    duration: const Duration(milliseconds: 600),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colors.gradientStart, colors.gradientEnd],
      ),
    ),
  );
}

/// Glass Container с blur и прозрачностью
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double blur;
  final BorderRadius? borderRadius;
  
  const GlassContainer({
    Key? key,
    required this.child,
    this.opacity = 0.8,
    this.blur = 10.0,
    this.borderRadius,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(opacity),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(
          color: colors.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: child,
        ),
      ),
    );
  }
}

