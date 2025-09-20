import 'package:flutter/material.dart';

/// Адаптивный текст для различных размеров экрана
class ResponsiveText extends StatelessWidget {
  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.textScaleFactor,
    this.textScaler,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final double? textScaleFactor;
  final TextScaler? textScaler;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      textScaler: textScaler,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}
