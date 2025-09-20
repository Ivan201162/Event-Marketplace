import 'package:flutter/material.dart';

/// Адаптивная карточка для различных размеров экрана
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: elevation,
      color: color,
      shadowColor: shadowColor,
      shape: shape,
      borderOnForeground: borderOnForeground,
      clipBehavior: clipBehavior,
      child: padding != null
          ? Padding(
              padding: padding!,
              child: child,
            )
          : child,
    );
  }
}
