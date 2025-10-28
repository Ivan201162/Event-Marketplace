import 'package:flutter/material.dart';

/// Responsive text widget that adapts to screen size
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
    this.isTitle,
    this.isSubtitle,
  });
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final bool? isTitle;
  final bool? isSubtitle;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive font size based on type
    var baseFontSize = fontSize ?? 14.0;
    if (isTitle ?? false) {
      baseFontSize = fontSize ?? 18.0;
    } else if (isSubtitle ?? false) {
      baseFontSize = fontSize ?? 16.0;
    }

    var responsiveFontSize = baseFontSize;
    if (screenWidth < 600) {
      responsiveFontSize = baseFontSize * 0.9;
    } else if (screenWidth > 1200) {
      responsiveFontSize = baseFontSize * 1.1;
    }

    // Set appropriate font weight based on type
    var finalFontWeight = fontWeight ?? FontWeight.normal;
    if (isTitle ?? false) {
      finalFontWeight = fontWeight ?? FontWeight.bold;
    } else if (isSubtitle ?? false) {
      finalFontWeight = fontWeight ?? FontWeight.w500;
    }

    return Text(
      text,
      style: style?.copyWith(
            fontSize: responsiveFontSize,
            fontWeight: finalFontWeight,
            color: color,
          ) ??
          TextStyle(
            fontSize: responsiveFontSize,
            fontWeight: finalFontWeight,
            color: color,
          ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
