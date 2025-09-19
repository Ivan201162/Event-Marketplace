import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';

/// Адаптивный текстовый виджет
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
    this.isTitle = false,
  });
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final bool isTitle;

  @override
  Widget build(BuildContext context) {
    final responsiveStyle = _getResponsiveStyle(context);

    return Text(
      text,
      style: style?.merge(responsiveStyle) ?? responsiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  TextStyle _getResponsiveStyle(BuildContext context) {
    var baseFontSize = fontSize ?? (isTitle ? 18.0 : 14.0);

    if (context.isMobile) {
      baseFontSize = fontSize ?? (isTitle ? 18.0 : 14.0);
    } else if (context.isTablet) {
      baseFontSize = (fontSize ?? (isTitle ? 18.0 : 14.0)) * 1.1;
    } else if (context.isDesktop) {
      baseFontSize = (fontSize ?? (isTitle ? 18.0 : 14.0)) * 1.2;
    }

    return TextStyle(
      fontSize: baseFontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}

/// Адаптивная карточка
class ResponsiveCard extends StatelessWidget {
  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final responsivePadding = _getResponsivePadding(context);
    final responsiveElevation = _getResponsiveElevation(context);
    final responsiveBorderRadius = _getResponsiveBorderRadius(context);

    final Widget card = Card(
      margin: margin,
      color: color,
      elevation: elevation ?? responsiveElevation,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? responsiveBorderRadius,
      ),
      child: Padding(
        padding: padding ?? responsivePadding,
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: (borderRadius ?? responsiveBorderRadius) as BorderRadius?,
        child: card,
      );
    }

    return card;
  }

  EdgeInsetsGeometry _getResponsivePadding(BuildContext context) {
    if (context.isMobile) {
      return const EdgeInsets.all(12);
    } else if (context.isTablet) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(20);
    }
  }

  double _getResponsiveElevation(BuildContext context) {
    if (context.isMobile) {
      return 2;
    } else if (context.isTablet) {
      return 4;
    } else {
      return 6;
    }
  }

  BorderRadiusGeometry _getResponsiveBorderRadius(BuildContext context) {
    if (context.isMobile) {
      return BorderRadius.circular(8);
    } else if (context.isTablet) {
      return BorderRadius.circular(12);
    } else {
      return BorderRadius.circular(16);
    }
  }
}

/// Адаптивный контейнер
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.width,
    this.height,
    this.decoration,
    this.alignment,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? width;
  final double? height;
  final BoxDecoration? decoration;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final responsivePadding = _getResponsivePadding(context);
    final responsiveWidth = _getResponsiveWidth(context);

    return Container(
      width: width ?? responsiveWidth,
      height: height,
      padding: padding ?? responsivePadding,
      margin: margin,
      color: color,
      decoration: decoration,
      alignment: alignment,
      child: child,
    );
  }

  EdgeInsetsGeometry _getResponsivePadding(BuildContext context) {
    if (context.isMobile) {
      return const EdgeInsets.all(8);
    } else if (context.isTablet) {
      return const EdgeInsets.all(12);
    } else {
      return const EdgeInsets.all(16);
    }
  }

  double? _getResponsiveWidth(BuildContext context) {
    if (context.isMobile) {
      return null; // Полная ширина
    } else if (context.isTablet) {
      return context.screenWidth * 0.8;
    } else {
      return context.screenWidth * 0.6;
    }
  }
}

/// Адаптивная сетка
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing,
    this.runSpacing,
    this.crossAxisCount,
    this.childAspectRatio,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });
  final List<Widget> children;
  final double? spacing;
  final double? runSpacing;
  final int? crossAxisCount;
  final double? childAspectRatio;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final responsiveCrossAxisCount = _getResponsiveCrossAxisCount(context);
    final responsiveSpacing = _getResponsiveSpacing(context);
    final responsiveChildAspectRatio = _getResponsiveChildAspectRatio(context);

    return GridView.count(
      crossAxisCount: crossAxisCount ?? responsiveCrossAxisCount,
      childAspectRatio: childAspectRatio ?? responsiveChildAspectRatio,
      mainAxisSpacing: spacing ?? responsiveSpacing,
      crossAxisSpacing: runSpacing ?? responsiveSpacing,
      children: children,
    );
  }

  int _getResponsiveCrossAxisCount(BuildContext context) {
    if (context.isMobile) {
      return 1;
    } else if (context.isTablet) {
      return 2;
    } else {
      return 3;
    }
  }

  double _getResponsiveSpacing(BuildContext context) {
    if (context.isMobile) {
      return 8;
    } else if (context.isTablet) {
      return 12;
    } else {
      return 16;
    }
  }

  double _getResponsiveChildAspectRatio(BuildContext context) {
    if (context.isMobile) {
      return 1.5;
    } else if (context.isTablet) {
      return 1.3;
    } else {
      return 1.2;
    }
  }
}

/// Адаптивный список
class ResponsiveList extends StatelessWidget {
  const ResponsiveList({
    super.key,
    required this.children,
    this.padding,
    this.spacing,
    this.physics,
    this.shrinkWrap = false,
  });
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double? spacing;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final responsivePadding = _getResponsivePadding(context);
    final responsiveSpacing = _getResponsiveSpacing(context);

    return ListView.separated(
      padding: padding ?? responsivePadding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: children.length,
      separatorBuilder: (context, index) => SizedBox(height: responsiveSpacing),
      itemBuilder: (context, index) => children[index],
    );
  }

  EdgeInsetsGeometry _getResponsivePadding(BuildContext context) {
    if (context.isMobile) {
      return const EdgeInsets.all(8);
    } else if (context.isTablet) {
      return const EdgeInsets.all(12);
    } else {
      return const EdgeInsets.all(16);
    }
  }

  double _getResponsiveSpacing(BuildContext context) {
    if (context.isMobile) {
      return 8;
    } else if (context.isTablet) {
      return 12;
    } else {
      return 16;
    }
  }
}

/// Адаптивный виджет (базовый)
class ResponsiveWidget extends StatelessWidget {
  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop && desktop != null) {
      return desktop!;
    } else if (context.isTablet && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}
