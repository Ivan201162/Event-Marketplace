import 'package:flutter/material.dart';

/// Утилиты для адаптивного дизайна
class ResponsiveUtils {
  // Брейкпоинты для разных размеров экранов
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1600;

  /// Определить тип экрана на основе ширины
  static ScreenType getScreenType(double width) {
    if (width < mobileBreakpoint) {
      return ScreenType.mobile;
    } else if (width < tabletBreakpoint) {
      return ScreenType.tablet;
    } else if (width < desktopBreakpoint) {
      return ScreenType.desktop;
    } else {
      return ScreenType.largeDesktop;
    }
  }

  /// Получить количество колонок для сетки
  static int getGridColumns(double width) {
    final screenType = getScreenType(width);
    switch (screenType) {
      case ScreenType.mobile:
        return 1;
      case ScreenType.tablet:
        return 2;
      case ScreenType.desktop:
        return 3;
      case ScreenType.largeDesktop:
        return 4;
    }
  }

  /// Получить отступы для экрана
  static EdgeInsets getScreenPadding(double width) {
    final screenType = getScreenType(width);
    switch (screenType) {
      case ScreenType.mobile:
        return const EdgeInsets.all(16);
      case ScreenType.tablet:
        return const EdgeInsets.all(24);
      case ScreenType.desktop:
        return const EdgeInsets.all(32);
      case ScreenType.largeDesktop:
        return const EdgeInsets.all(48);
    }
  }

  /// Получить максимальную ширину контента
  static double getMaxContentWidth(double width) {
    final screenType = getScreenType(width);
    switch (screenType) {
      case ScreenType.mobile:
        return width;
      case ScreenType.tablet:
        return 800;
      case ScreenType.desktop:
        return 1200;
      case ScreenType.largeDesktop:
        return 1600;
    }
  }

  /// Получить размер шрифта для заголовка
  static double getTitleFontSize(double width) {
    final screenType = getScreenType(width);
    switch (screenType) {
      case ScreenType.mobile:
        return 24;
      case ScreenType.tablet:
        return 28;
      case ScreenType.desktop:
        return 32;
      case ScreenType.largeDesktop:
        return 36;
    }
  }

  /// Получить размер шрифта для подзаголовка
  static double getSubtitleFontSize(double width) {
    final screenType = getScreenType(width);
    switch (screenType) {
      case ScreenType.mobile:
        return 16;
      case ScreenType.tablet:
        return 18;
      case ScreenType.desktop:
        return 20;
      case ScreenType.largeDesktop:
        return 22;
    }
  }

  /// Получить размер шрифта для основного текста
  static double getBodyFontSize(double width) {
    final screenType = getScreenType(width);
    switch (screenType) {
      case ScreenType.mobile:
        return 14;
      case ScreenType.tablet:
        return 16;
      case ScreenType.desktop:
        return 16;
      case ScreenType.largeDesktop:
        return 18;
    }
  }

  /// Получить размер иконки
  static double getIconSize(double width) {
    final screenType = getScreenType(width);
    switch (screenType) {
      case ScreenType.mobile:
        return 24;
      case ScreenType.tablet:
        return 28;
      case ScreenType.desktop:
        return 32;
      case ScreenType.largeDesktop:
        return 36;
    }
  }

  /// Получить высоту AppBar
  static double getAppBarHeight(double width) {
    final screenType = getScreenType(width);
    switch (screenType) {
      case ScreenType.mobile:
        return 56;
      case ScreenType.tablet:
        return 64;
      case ScreenType.desktop:
        return 72;
      case ScreenType.largeDesktop:
        return 80;
    }
  }

  /// Получить размер карточки
  static Size getCardSize(double width) {
    final screenType = getScreenType(width);
    switch (screenType) {
      case ScreenType.mobile:
        return const Size(200, 120);
      case ScreenType.tablet:
        return const Size(250, 150);
      case ScreenType.desktop:
        return const Size(300, 180);
      case ScreenType.largeDesktop:
        return const Size(350, 200);
    }
  }

  /// Получить количество элементов в строке для списка
  static int getItemsPerRow(double width) {
    final screenType = getScreenType(width);
    switch (screenType) {
      case ScreenType.mobile:
        return 1;
      case ScreenType.tablet:
        return 2;
      case ScreenType.desktop:
        return 3;
      case ScreenType.largeDesktop:
        return 4;
    }
  }

  /// Получить отступы между элементами
  static double getItemSpacing(double width) {
    final screenType = getScreenType(width);
    switch (screenType) {
      case ScreenType.mobile:
        return 8;
      case ScreenType.tablet:
        return 12;
      case ScreenType.desktop:
        return 16;
      case ScreenType.largeDesktop:
        return 20;
    }
  }
}

/// Типы экранов
enum ScreenType { mobile, tablet, desktop, largeDesktop }

/// Виджет для адаптивного контейнера
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.center,
  });
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveMaxWidth = maxWidth ?? ResponsiveUtils.getMaxContentWidth(screenWidth);
    final effectivePadding = padding ?? ResponsiveUtils.getScreenPadding(screenWidth);

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        padding: effectivePadding,
        child: child,
      ),
    );
  }
}

/// Виджет для адаптивной сетки
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.crossAxisCount,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.childAspectRatio,
  });
  final List<Widget> children;
  final int? crossAxisCount;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;
  final double? childAspectRatio;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final gridCrossAxisCount = crossAxisCount ?? ResponsiveUtils.getGridColumns(screenWidth);
    final effectiveCrossAxisSpacing =
        crossAxisSpacing ?? ResponsiveUtils.getItemSpacing(screenWidth);
    final effectiveMainAxisSpacing = mainAxisSpacing ?? ResponsiveUtils.getItemSpacing(screenWidth);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCrossAxisCount,
        crossAxisSpacing: effectiveCrossAxisSpacing,
        mainAxisSpacing: effectiveMainAxisSpacing,
        childAspectRatio: childAspectRatio ?? 1.5,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Виджет для адаптивного текста
class ResponsiveText extends StatelessWidget {
  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isTitle = false,
    this.isSubtitle = false,
  });
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool isTitle;
  final bool isSubtitle;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    double fontSize;
    if (isTitle) {
      fontSize = ResponsiveUtils.getTitleFontSize(screenWidth);
    } else if (isSubtitle) {
      fontSize = ResponsiveUtils.getSubtitleFontSize(screenWidth);
    } else {
      fontSize = ResponsiveUtils.getBodyFontSize(screenWidth);
    }

    return Text(
      text,
      style: style?.copyWith(fontSize: fontSize) ?? TextStyle(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Виджет для адаптивной иконки
class ResponsiveIcon extends StatelessWidget {
  const ResponsiveIcon(this.icon, {super.key, this.color, this.size});
  final IconData icon;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveSize = size ?? ResponsiveUtils.getIconSize(screenWidth);

    return Icon(icon, size: effectiveSize, color: color);
  }
}

/// Виджет для адаптивного отступа
class ResponsivePadding extends StatelessWidget {
  const ResponsivePadding({super.key, required this.child, this.padding, this.multiplier = 1.0});
  final Widget child;
  final EdgeInsets? padding;
  final double? multiplier;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final basePadding = ResponsiveUtils.getScreenPadding(screenWidth);
    final effectivePadding = padding ?? basePadding * multiplier!;

    return Padding(padding: effectivePadding, child: child);
  }
}

/// Виджет для адаптивного разделителя
class ResponsiveDivider extends StatelessWidget {
  const ResponsiveDivider({
    super.key,
    this.height,
    this.color,
    this.thickness,
    this.indent,
    this.endIndent,
  });
  final double? height;
  final Color? color;
  final double? thickness;
  final double? indent;
  final double? endIndent;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveHeight = height ?? ResponsiveUtils.getItemSpacing(screenWidth);

    return Divider(
      height: effectiveHeight,
      color: color,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
    );
  }
}

/// Расширения для BuildContext
extension ResponsiveContext on BuildContext {
  /// Получить тип экрана
  ScreenType get screenType => ResponsiveUtils.getScreenType(MediaQuery.of(this).size.width);

  /// Проверить, является ли экран мобильным
  bool get isMobile => screenType == ScreenType.mobile;

  /// Проверить, является ли экран планшетом
  bool get isTablet => screenType == ScreenType.tablet;

  /// Проверить, является ли экран десктопом
  bool get isDesktop => screenType == ScreenType.desktop;

  /// Проверить, является ли экран большим десктопом
  bool get isLargeDesktop => screenType == ScreenType.largeDesktop;

  /// Получить ширину экрана
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Получить высоту экрана
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Получить отступы для экрана
  EdgeInsets get screenPadding => ResponsiveUtils.getScreenPadding(screenWidth);

  /// Получить максимальную ширину контента
  double get maxContentWidth => ResponsiveUtils.getMaxContentWidth(screenWidth);
}
