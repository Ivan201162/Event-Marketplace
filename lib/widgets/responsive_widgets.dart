import 'package:flutter/material.dart';
import '../core/app_styles.dart';

/// Адаптивный виджет, который показывает разные виджеты в зависимости от размера экрана
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? fallback;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (AppStyles.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (AppStyles.isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}

/// Адаптивный контейнер с разными отступами для разных размеров экрана
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;
  final EdgeInsets? fallbackPadding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.fallbackPadding,
  });

  @override
  Widget build(BuildContext context) {
    EdgeInsets padding;

    if (AppStyles.isDesktop(context)) {
      padding = desktopPadding ??
          tabletPadding ??
          mobilePadding ??
          fallbackPadding ??
          EdgeInsets.zero;
    } else if (AppStyles.isTablet(context)) {
      padding =
          tabletPadding ?? mobilePadding ?? fallbackPadding ?? EdgeInsets.zero;
    } else {
      padding = mobilePadding ?? fallbackPadding ?? EdgeInsets.zero;
    }

    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// Адаптивная сетка с разным количеством колонок
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    int columns;

    if (AppStyles.isDesktop(context)) {
      columns = desktopColumns ?? tabletColumns ?? mobileColumns;
    } else if (AppStyles.isTablet(context)) {
      columns = tabletColumns ?? mobileColumns;
    } else {
      columns = mobileColumns;
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children
          .map((child) => SizedBox(
                width: (MediaQuery.of(context).size.width -
                        (spacing * (columns - 1))) /
                    columns,
                child: child,
              ))
          .toList(),
    );
  }
}

/// Адаптивный список с разным количеством элементов в строке
class ResponsiveList extends StatelessWidget {
  final List<Widget> children;
  final int mobileItemsPerRow;
  final int? tabletItemsPerRow;
  final int? desktopItemsPerRow;
  final double spacing;
  final double runSpacing;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ResponsiveList({
    super.key,
    required this.children,
    this.mobileItemsPerRow = 1,
    this.tabletItemsPerRow,
    this.desktopItemsPerRow,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    int itemsPerRow;

    if (AppStyles.isDesktop(context)) {
      itemsPerRow =
          desktopItemsPerRow ?? tabletItemsPerRow ?? mobileItemsPerRow;
    } else if (AppStyles.isTablet(context)) {
      itemsPerRow = tabletItemsPerRow ?? mobileItemsPerRow;
    } else {
      itemsPerRow = mobileItemsPerRow;
    }

    return ListView.builder(
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: (children.length / itemsPerRow).ceil(),
      itemBuilder: (context, index) {
        final startIndex = index * itemsPerRow;
        final endIndex = (startIndex + itemsPerRow).clamp(0, children.length);
        final rowChildren = children.sublist(startIndex, endIndex);

        return Padding(
          padding: EdgeInsets.only(bottom: runSpacing),
          child: Row(
            children: rowChildren
                .map((child) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                        child: child,
                      ),
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

/// Адаптивный виджет с разными стилями для разных размеров экрана
class ResponsiveStyle extends StatelessWidget {
  final Widget child;
  final TextStyle? mobileStyle;
  final TextStyle? tabletStyle;
  final TextStyle? desktopStyle;
  final TextStyle? fallbackStyle;

  const ResponsiveStyle({
    super.key,
    required this.child,
    this.mobileStyle,
    this.tabletStyle,
    this.desktopStyle,
    this.fallbackStyle,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle? style;

    if (AppStyles.isDesktop(context)) {
      style = desktopStyle ?? tabletStyle ?? mobileStyle ?? fallbackStyle;
    } else if (AppStyles.isTablet(context)) {
      style = tabletStyle ?? mobileStyle ?? fallbackStyle;
    } else {
      style = mobileStyle ?? fallbackStyle;
    }

    if (style != null && child is Text) {
      return Text(
        (child as Text).data ?? '',
        style: (child as Text).style?.merge(style) ?? style,
        textAlign: (child as Text).textAlign,
        maxLines: (child as Text).maxLines,
        overflow: (child as Text).overflow,
      );
    }

    return child;
  }
}

/// Адаптивный виджет с разными размерами для разных размеров экрана
class ResponsiveSize extends StatelessWidget {
  final Widget child;
  final double? mobileSize;
  final double? tabletSize;
  final double? desktopSize;
  final double? fallbackSize;

  const ResponsiveSize({
    super.key,
    required this.child,
    this.mobileSize,
    this.tabletSize,
    this.desktopSize,
    this.fallbackSize,
  });

  @override
  Widget build(BuildContext context) {
    double? size;

    if (AppStyles.isDesktop(context)) {
      size = desktopSize ?? tabletSize ?? mobileSize ?? fallbackSize;
    } else if (AppStyles.isTablet(context)) {
      size = tabletSize ?? mobileSize ?? fallbackSize;
    } else {
      size = mobileSize ?? fallbackSize;
    }

    if (size != null) {
      return SizedBox(
        width: size,
        height: size,
        child: child,
      );
    }

    return child;
  }
}

/// Адаптивный виджет с разными отступами для разных размеров экрана
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;
  final EdgeInsets? fallbackPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.fallbackPadding,
  });

  @override
  Widget build(BuildContext context) {
    EdgeInsets padding;

    if (AppStyles.isDesktop(context)) {
      padding = desktopPadding ??
          tabletPadding ??
          mobilePadding ??
          fallbackPadding ??
          EdgeInsets.zero;
    } else if (AppStyles.isTablet(context)) {
      padding =
          tabletPadding ?? mobilePadding ?? fallbackPadding ?? EdgeInsets.zero;
    } else {
      padding = mobilePadding ?? fallbackPadding ?? EdgeInsets.zero;
    }

    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// Адаптивный виджет с разными отступами для разных размеров экрана
class ResponsiveMargin extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobileMargin;
  final EdgeInsets? tabletMargin;
  final EdgeInsets? desktopMargin;
  final EdgeInsets? fallbackMargin;

  const ResponsiveMargin({
    super.key,
    required this.child,
    this.mobileMargin,
    this.tabletMargin,
    this.desktopMargin,
    this.fallbackMargin,
  });

  @override
  Widget build(BuildContext context) {
    EdgeInsets margin;

    if (AppStyles.isDesktop(context)) {
      margin = desktopMargin ??
          tabletMargin ??
          mobileMargin ??
          fallbackMargin ??
          EdgeInsets.zero;
    } else if (AppStyles.isTablet(context)) {
      margin =
          tabletMargin ?? mobileMargin ?? fallbackMargin ?? EdgeInsets.zero;
    } else {
      margin = mobileMargin ?? fallbackMargin ?? EdgeInsets.zero;
    }

    return Container(
      margin: margin,
      child: child,
    );
  }
}

/// Адаптивный виджет с разными стилями для разных размеров экрана
class ResponsiveDecoration extends StatelessWidget {
  final Widget child;
  final BoxDecoration? mobileDecoration;
  final BoxDecoration? tabletDecoration;
  final BoxDecoration? desktopDecoration;
  final BoxDecoration? fallbackDecoration;

  const ResponsiveDecoration({
    super.key,
    required this.child,
    this.mobileDecoration,
    this.tabletDecoration,
    this.desktopDecoration,
    this.fallbackDecoration,
  });

  @override
  Widget build(BuildContext context) {
    BoxDecoration? decoration;

    if (AppStyles.isDesktop(context)) {
      decoration = desktopDecoration ??
          tabletDecoration ??
          mobileDecoration ??
          fallbackDecoration;
    } else if (AppStyles.isTablet(context)) {
      decoration = tabletDecoration ?? mobileDecoration ?? fallbackDecoration;
    } else {
      decoration = mobileDecoration ?? fallbackDecoration;
    }

    if (decoration != null) {
      return Container(
        decoration: decoration,
        child: child,
      );
    }

    return child;
  }
}

/// Адаптивный виджет с разными стилями для разных размеров экрана
class ResponsiveElevation extends StatelessWidget {
  final Widget child;
  final double? mobileElevation;
  final double? tabletElevation;
  final double? desktopElevation;
  final double? fallbackElevation;

  const ResponsiveElevation({
    super.key,
    required this.child,
    this.mobileElevation,
    this.tabletElevation,
    this.desktopElevation,
    this.fallbackElevation,
  });

  @override
  Widget build(BuildContext context) {
    double? elevation;

    if (AppStyles.isDesktop(context)) {
      elevation = desktopElevation ??
          tabletElevation ??
          mobileElevation ??
          fallbackElevation;
    } else if (AppStyles.isTablet(context)) {
      elevation = tabletElevation ?? mobileElevation ?? fallbackElevation;
    } else {
      elevation = mobileElevation ?? fallbackElevation;
    }

    if (elevation != null) {
      return Material(
        elevation: elevation,
        child: child,
      );
    }

    return child;
  }
}

/// Адаптивный виджет с разными стилями для разных размеров экрана
class ResponsiveBorderRadius extends StatelessWidget {
  final Widget child;
  final BorderRadius? mobileBorderRadius;
  final BorderRadius? tabletBorderRadius;
  final BorderRadius? desktopBorderRadius;
  final BorderRadius? fallbackBorderRadius;

  const ResponsiveBorderRadius({
    super.key,
    required this.child,
    this.mobileBorderRadius,
    this.tabletBorderRadius,
    this.desktopBorderRadius,
    this.fallbackBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    BorderRadius? borderRadius;

    if (AppStyles.isDesktop(context)) {
      borderRadius = desktopBorderRadius ??
          tabletBorderRadius ??
          mobileBorderRadius ??
          fallbackBorderRadius;
    } else if (AppStyles.isTablet(context)) {
      borderRadius =
          tabletBorderRadius ?? mobileBorderRadius ?? fallbackBorderRadius;
    } else {
      borderRadius = mobileBorderRadius ?? fallbackBorderRadius;
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: child,
      );
    }

    return child;
  }
}
