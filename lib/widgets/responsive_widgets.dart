import 'package:flutter/material.dart';

/// Утилиты для адаптивного дизайна
class ResponsiveUtils {
  /// Определить тип экрана на основе ширины
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return ScreenType.mobile;
    } else if (width < 1024) {
      return ScreenType.tablet;
    } else {
      return ScreenType.desktop;
    }
  }

  /// Получить количество колонок для сетки в зависимости от размера экрана
  static int getGridColumns(
    BuildContext context, {
    int mobileColumns = 2,
    int tabletColumns = 3,
    int desktopColumns = 4,
  }) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return mobileColumns;
      case ScreenType.tablet:
        return tabletColumns;
      case ScreenType.desktop:
        return desktopColumns;
    }
  }

  /// Получить отступы в зависимости от размера экрана
  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    EdgeInsets? mobilePadding,
    EdgeInsets? tabletPadding,
    EdgeInsets? desktopPadding,
  }) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return mobilePadding ?? const EdgeInsets.all(16);
      case ScreenType.tablet:
        return tabletPadding ?? const EdgeInsets.all(24);
      case ScreenType.desktop:
        return desktopPadding ?? const EdgeInsets.all(32);
    }
  }

  /// Получить размер шрифта в зависимости от размера экрана
  static double getResponsiveFontSize(
    BuildContext context, {
    double? mobileSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return mobileSize ?? 14;
      case ScreenType.tablet:
        return tabletSize ?? 16;
      case ScreenType.desktop:
        return desktopSize ?? 18;
    }
  }

  /// Проверить, является ли экран мобильным
  static bool isMobile(BuildContext context) => getScreenType(context) == ScreenType.mobile;

  /// Проверить, является ли экран планшетом
  static bool isTablet(BuildContext context) => getScreenType(context) == ScreenType.tablet;

  /// Проверить, является ли экран десктопом
  static bool isDesktop(BuildContext context) => getScreenType(context) == ScreenType.desktop;
}

/// Типы экранов
enum ScreenType { mobile, tablet, desktop }

/// Адаптивный виджет, который изменяет свой контент в зависимости от размера экрана
class ResponsiveWidget extends StatelessWidget {
  const ResponsiveWidget({super.key, required this.mobile, this.tablet, this.desktop});

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveUtils.getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

/// Адаптивная сетка
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.spacing = 8,
    this.runSpacing = 8,
    this.aspectRatio = 1,
  });

  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveUtils.getGridColumns(
      context,
      mobileColumns: mobileColumns,
      tabletColumns: tabletColumns,
      desktopColumns: desktopColumns,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Адаптивный контейнер
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.mobileMargin,
    this.tabletMargin,
    this.desktopMargin,
    this.mobileWidth,
    this.tabletWidth,
    this.desktopWidth,
    this.mobileMaxWidth,
    this.tabletMaxWidth,
    this.desktopMaxWidth,
    this.decoration,
  });

  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;
  final EdgeInsets? mobileMargin;
  final EdgeInsets? tabletMargin;
  final EdgeInsets? desktopMargin;
  final double? mobileWidth;
  final double? tabletWidth;
  final double? desktopWidth;
  final double? mobileMaxWidth;
  final double? tabletMaxWidth;
  final double? desktopMaxWidth;
  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveUtils.getScreenType(context);

    EdgeInsets? padding;
    EdgeInsets? margin;
    double? width;
    double? maxWidth;

    switch (screenType) {
      case ScreenType.mobile:
        padding = mobilePadding;
        margin = mobileMargin;
        width = mobileWidth;
        maxWidth = mobileMaxWidth;
        break;
      case ScreenType.tablet:
        padding = tabletPadding;
        margin = tabletMargin;
        width = tabletWidth;
        maxWidth = tabletMaxWidth;
        break;
      case ScreenType.desktop:
        padding = desktopPadding;
        margin = desktopMargin;
        width = desktopWidth;
        maxWidth = desktopMaxWidth;
        break;
    }

    return Container(
      width: width,
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      padding: padding,
      margin: margin,
      decoration: decoration,
      child: child,
    );
  }
}

/// Адаптивный текст
class ResponsiveText extends StatelessWidget {
  const ResponsiveText(
    this.text, {
    super.key,
    this.mobileStyle,
    this.tabletStyle,
    this.desktopStyle,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? mobileStyle;
  final TextStyle? tabletStyle;
  final TextStyle? desktopStyle;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveUtils.getScreenType(context);

    TextStyle? style;
    switch (screenType) {
      case ScreenType.mobile:
        style = mobileStyle;
        break;
      case ScreenType.tablet:
        style = tabletStyle;
        break;
      case ScreenType.desktop:
        style = desktopStyle;
        break;
    }

    return Text(text, style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow);
  }
}

/// Адаптивная кнопка
class ResponsiveButton extends StatelessWidget {
  const ResponsiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.mobileStyle,
    this.tabletStyle,
    this.desktopStyle,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? mobileStyle;
  final ButtonStyle? tabletStyle;
  final ButtonStyle? desktopStyle;
  final EdgeInsetsGeometry? mobilePadding;
  final EdgeInsetsGeometry? tabletPadding;
  final EdgeInsetsGeometry? desktopPadding;

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveUtils.getScreenType(context);

    ButtonStyle? style;
    EdgeInsetsGeometry? padding;

    switch (screenType) {
      case ScreenType.mobile:
        style = mobileStyle;
        padding = mobilePadding;
        break;
      case ScreenType.tablet:
        style = tabletStyle;
        padding = tabletPadding;
        break;
      case ScreenType.desktop:
        style = desktopStyle;
        padding = desktopPadding;
        break;
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );
  }
}

/// Адаптивный список
class ResponsiveList extends StatelessWidget {
  const ResponsiveList({
    super.key,
    required this.children,
    this.mobileSpacing = 8,
    this.tabletSpacing = 12,
    this.desktopSpacing = 16,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  });

  final List<Widget> children;
  final double mobileSpacing;
  final double tabletSpacing;
  final double desktopSpacing;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveUtils.getScreenType(context);

    double spacing;
    EdgeInsets? padding;

    switch (screenType) {
      case ScreenType.mobile:
        spacing = mobileSpacing;
        padding = mobilePadding;
        break;
      case ScreenType.tablet:
        spacing = tabletSpacing;
        padding = tabletPadding;
        break;
      case ScreenType.desktop:
        spacing = desktopSpacing;
        padding = desktopPadding;
        break;
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: children.length,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Адаптивная карточка
class ResponsiveCard extends StatelessWidget {
  const ResponsiveCard({
    super.key,
    required this.child,
    this.mobileElevation = 2,
    this.tabletElevation = 4,
    this.desktopElevation = 6,
    this.mobileMargin,
    this.tabletMargin,
    this.desktopMargin,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.mobileBorderRadius,
    this.tabletBorderRadius,
    this.desktopBorderRadius,
  });

  final Widget child;
  final double mobileElevation;
  final double tabletElevation;
  final double desktopElevation;
  final EdgeInsets? mobileMargin;
  final EdgeInsets? tabletMargin;
  final EdgeInsets? desktopMargin;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;
  final BorderRadius? mobileBorderRadius;
  final BorderRadius? tabletBorderRadius;
  final BorderRadius? desktopBorderRadius;

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveUtils.getScreenType(context);

    double elevation;
    EdgeInsets? margin;
    EdgeInsets? padding;
    BorderRadius? borderRadius;

    switch (screenType) {
      case ScreenType.mobile:
        elevation = mobileElevation;
        margin = mobileMargin;
        padding = mobilePadding;
        borderRadius = mobileBorderRadius;
        break;
      case ScreenType.tablet:
        elevation = tabletElevation;
        margin = tabletMargin;
        padding = tabletPadding;
        borderRadius = tabletBorderRadius;
        break;
      case ScreenType.desktop:
        elevation = desktopElevation;
        margin = desktopMargin;
        padding = desktopPadding;
        borderRadius = desktopBorderRadius;
        break;
    }

    return Card(
      elevation: elevation,
      margin: margin,
      shape: borderRadius != null ? RoundedRectangleBorder(borderRadius: borderRadius) : null,
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );
  }
}

/// Адаптивный LayoutBuilder
class ResponsiveLayoutBuilder extends StatelessWidget {
  const ResponsiveLayoutBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, ScreenType screenType, BoxConstraints constraints)
      builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final screenType = ResponsiveUtils.getScreenType(context);
          return builder(context, screenType, constraints);
        },
      );
}
