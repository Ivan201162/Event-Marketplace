import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Виджет для локализованного текста
class LocalizedText extends StatelessWidget {
  final String Function(AppLocalizations l10n) textBuilder;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final double? textScaleFactor;

  const LocalizedText(
    this.textBuilder, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.textScaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      textBuilder(l10n),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      textScaleFactor: textScaleFactor,
    );
  }
}

/// Виджет для локализованного текста с параметрами
class LocalizedTextWithParams extends StatelessWidget {
  final String Function(AppLocalizations l10n) textBuilder;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final double? textScaleFactor;

  const LocalizedTextWithParams(
    this.textBuilder, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.textScaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      textBuilder(l10n),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      textScaleFactor: textScaleFactor,
    );
  }
}

/// Виджет для локализованного текста с форматированием
class LocalizedRichText extends StatelessWidget {
  final TextSpan Function(AppLocalizations l10n) textSpanBuilder;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final int? maxLines;
  final Locale? locale;
  final StrutStyle? strutStyle;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  const LocalizedRichText(
    this.textSpanBuilder, {
    super.key,
    this.textAlign,
    this.textDirection,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
    this.locale,
    this.strutStyle,
    this.textWidthBasis,
    this.textHeightBehavior,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RichText(
      text: textSpanBuilder(l10n),
      textAlign: textAlign ?? TextAlign.start,
      textDirection: textDirection,
      softWrap: softWrap ?? true,
      overflow: overflow ?? TextOverflow.clip,
      textScaleFactor: textScaleFactor ?? 1.0,
      maxLines: maxLines,
      locale: locale,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis ?? TextWidthBasis.parent,
      textHeightBehavior: textHeightBehavior,
    );
  }
}

/// Виджет для локализованного текста с автоматическим определением направления
class LocalizedDirectionalText extends StatelessWidget {
  final String Function(AppLocalizations l10n) textBuilder;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final double? textScaleFactor;

  const LocalizedDirectionalText(
    this.textBuilder, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textScaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = textBuilder(l10n);

    // Автоматическое определение направления текста
    final textDirection = _getTextDirection(text);

    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: textDirection,
      softWrap: softWrap,
      textScaleFactor: textScaleFactor,
    );
  }

  TextDirection _getTextDirection(String text) {
    // Простая эвристика для определения направления текста
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    final hebrewRegex = RegExp(r'[\u0590-\u05FF]');

    if (arabicRegex.hasMatch(text) || hebrewRegex.hasMatch(text)) {
      return TextDirection.rtl;
    }

    return TextDirection.ltr;
  }
}

/// Виджет для локализованного текста с поддержкой плюрализации
class LocalizedPluralText extends StatelessWidget {
  final String Function(AppLocalizations l10n, int count) textBuilder;
  final int count;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final double? textScaleFactor;

  const LocalizedPluralText(
    this.textBuilder,
    this.count, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.textScaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      textBuilder(l10n, count),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      textScaleFactor: textScaleFactor,
    );
  }
}

/// Виджет для локализованного текста с поддержкой дат
class LocalizedDateText extends StatelessWidget {
  final String Function(AppLocalizations l10n, DateTime date) textBuilder;
  final DateTime date;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final double? textScaleFactor;

  const LocalizedDateText(
    this.textBuilder,
    this.date, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.textScaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      textBuilder(l10n, date),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      textScaleFactor: textScaleFactor,
    );
  }
}

/// Виджет для локализованного текста с поддержкой чисел
class LocalizedNumberText extends StatelessWidget {
  final String Function(AppLocalizations l10n, num number) textBuilder;
  final num number;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final double? textScaleFactor;

  const LocalizedNumberText(
    this.textBuilder,
    this.number, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.textScaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      textBuilder(l10n, number),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      textScaleFactor: textScaleFactor,
    );
  }
}
