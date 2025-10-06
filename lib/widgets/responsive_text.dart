import 'package:flutter/material.dart';

/// Адаптивный текст для различных размеров экрана с поддержкой Material Design 3
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
    this.responsive = true,
    this.minFontSize = 10.0,
    this.maxFontSize = 24.0,
    this.isTitle = false,
    this.isSubtitle = false,
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
  final bool responsive;
  final double minFontSize;
  final double maxFontSize;
  final bool isTitle;
  final bool isSubtitle;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    // Адаптивный размер шрифта
    var responsiveFontSize = style?.fontSize ?? 14.0;

    // Применяем стили для заголовков и подзаголовков
    if (isTitle) {
      responsiveFontSize = 24.0;
    } else if (isSubtitle) {
      responsiveFontSize = 16.0;
    }

    if (responsive) {
      if (isDesktop) {
        responsiveFontSize = responsiveFontSize * 1.2;
      } else if (isTablet) {
        responsiveFontSize = responsiveFontSize * 1.1;
      }

      // Ограничиваем размер шрифта
      responsiveFontSize = responsiveFontSize.clamp(minFontSize, maxFontSize);
    }

    // Адаптивные отступы
    final responsiveStyle = style?.copyWith(
          fontSize: responsiveFontSize,
          fontWeight: isTitle ? FontWeight.bold : style?.fontWeight,
        ) ??
        TextStyle(
          fontSize: responsiveFontSize,
          fontWeight: isTitle ? FontWeight.bold : null,
        );

    return Text(
      text,
      style: responsiveStyle,
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
