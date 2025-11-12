/// Dynamic Canvas Layer - V7.6
/// Визуальный слой, реагирующий на звук и движение

import 'package:flutter/material.dart';
import 'package:event_marketplace_app/services/dynamic_canvas/dynamic_canvas_service.dart';
import 'package:event_marketplace_app/theme/colors.dart';

class DynamicCanvasLayer extends StatelessWidget {
  final Widget child;
  
  const DynamicCanvasLayer({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    return Stack(
      children: [
        // Динамический фон, реагирующий на звук
        ValueListenableBuilder<double>(
          valueListenable: DynamicCanvasService.intensity,
          builder: (context, value, _) {
            final scale = 1.0 + value * 0.05;
            final opacity = (0.3 + value * 0.7).clamp(0.3, 1.0);
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  colors: [
                    colors.accent.withOpacity(opacity),
                    colors.background,
                  ],
                  radius: 1.5 + value * 0.5,
                ),
              ),
              transform: Matrix4.identity()..scale(scale),
            );
          },
        ),
        // Контент поверх динамического фона
        child,
      ],
    );
  }
}
