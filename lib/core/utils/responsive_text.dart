import 'package:flutter/material.dart';

class ResponsiveText extends StatelessWidget {

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
    this.fontWeight,
    this.color,
  });
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final responsiveFontSize = fontSize ?? _getResponsiveFontSize(screenWidth);

    return Text(
      text,
      style: style?.copyWith(
              fontSize: responsiveFontSize,
              fontWeight: fontWeight,
              color: color,) ??
          TextStyle(
              fontSize: responsiveFontSize,
              fontWeight: fontWeight,
              color: color,),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  double _getResponsiveFontSize(double screenWidth) {
    if (screenWidth < 600) {
      return 14; // Mobile
    } else if (screenWidth < 900) {
      return 16; // Tablet
    } else {
      return 18; // Desktop
    }
  }
}
