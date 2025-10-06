import 'package:flutter/material.dart';

/// Адаптивная карточка для различных размеров экрана с поддержкой Material Design 3
class ResponsiveCard extends StatelessWidget {
  const ResponsiveCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.elevation,
    this.color,
    this.shadowColor,
    this.shape,
    this.borderOnForeground = true,
    this.clipBehavior,
    this.responsive = true,
    this.adaptivePadding = true,
    this.adaptiveElevation = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color? color;
  final Color? shadowColor;
  final ShapeBorder? shape;
  final bool borderOnForeground;
  final Clip? clipBehavior;
  final bool responsive;
  final bool adaptivePadding;
  final bool adaptiveElevation;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    // Адаптивные отступы
    var responsivePadding = padding;
    if (responsive && adaptivePadding) {
      if (isDesktop) {
        responsivePadding = padding ?? const EdgeInsets.all(24);
      } else if (isTablet) {
        responsivePadding = padding ?? const EdgeInsets.all(20);
      } else {
        responsivePadding = padding ?? const EdgeInsets.all(16);
      }
    }

    // Адаптивная высота тени
    var responsiveElevation = elevation;
    if (responsive && adaptiveElevation) {
      if (isDesktop) {
        responsiveElevation = elevation ?? 4.0;
      } else if (isTablet) {
        responsiveElevation = elevation ?? 3.0;
      } else {
        responsiveElevation = elevation ?? 2.0;
      }
    }

    // Адаптивная форма
    var responsiveShape = shape;
    if (responsive) {
      final radius = isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0);
      responsiveShape = shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          );
    }

    return Card(
      margin: margin,
      elevation: responsiveElevation,
      color: color,
      shadowColor: shadowColor,
      shape: responsiveShape,
      borderOnForeground: borderOnForeground,
      clipBehavior: clipBehavior,
      child: responsivePadding != null
          ? Padding(
              padding: responsivePadding,
              child: child,
            )
          : child,
    );
  }
}
