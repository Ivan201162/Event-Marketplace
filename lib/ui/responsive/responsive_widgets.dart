import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';

/// Адаптивный виджет для разных размеров экрана
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
    this.elevation,
    this.borderRadius,
    this.color,
    this.shadowColor,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final BorderRadiusGeometry? borderRadius;
  final Color? color;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ??
        context.responsive(
          const EdgeInsets.all(16),
          const EdgeInsets.all(20),
          const EdgeInsets.all(24),
        );

    final responsiveMargin = margin ??
        context.responsive(
          const EdgeInsets.all(8),
          const EdgeInsets.all(12),
          const EdgeInsets.all(16),
        );

    final responsiveElevation = elevation ?? context.responsive(2, 3, 4);

    final responsiveBorderRadius = borderRadius ??
        context.responsive(
          BorderRadius.circular(8),
          BorderRadius.circular(12),
          BorderRadius.circular(16),
        );

    return Card(
      elevation: responsiveElevation,
      margin: responsiveMargin,
      color: color,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: responsiveBorderRadius!,
      ),
      child: Padding(
        padding: responsivePadding!,
        child: child,
      ),
    );
  }
}

/// Адаптивный контейнер
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.constraints,
    this.decoration,
    this.alignment,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final Decoration? decoration;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ??
        context.responsive(
          const EdgeInsets.all(16),
          const EdgeInsets.all(20),
          const EdgeInsets.all(24),
        );

    final responsiveMargin = margin ??
        context.responsive(
          const EdgeInsets.all(8),
          const EdgeInsets.all(12),
          const EdgeInsets.all(16),
        );

    return Container(
      padding: responsivePadding,
      margin: responsiveMargin,
      width: width,
      height: height,
      constraints: constraints,
      decoration: decoration,
      alignment: alignment,
      child: child,
    );
  }
}

/// Адаптивная сетка
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
    final responsiveCrossAxisCount =
        crossAxisCount ?? context.responsive(2, 3, 4);
    final responsiveCrossAxisSpacing =
        crossAxisSpacing ?? context.responsive(8, 12, 16);
    final responsiveMainAxisSpacing =
        mainAxisSpacing ?? context.responsive(8, 12, 16);
    final responsiveChildAspectRatio =
        childAspectRatio ?? context.responsive(1, 1.2, 1.5);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: responsiveCrossAxisCount!,
        crossAxisSpacing: responsiveCrossAxisSpacing!,
        mainAxisSpacing: responsiveMainAxisSpacing!,
        childAspectRatio: responsiveChildAspectRatio!,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Адаптивный список
class ResponsiveList extends StatelessWidget {
  const ResponsiveList({
    super.key,
    required this.children,
    this.padding,
    this.spacing,
  });
  
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ??
        context.responsive(
          const EdgeInsets.all(16),
          const EdgeInsets.all(20),
          const EdgeInsets.all(24),
        );
    
    final responsiveSpacing = spacing ?? context.responsive(8, 12, 16);

    return Padding(
      padding: responsivePadding!,
      child: Column(
        children: children
            .expand((child) => [child, SizedBox(height: responsiveSpacing!)])
            .take(children.length * 2 - 1)
            .toList(),
      ),
    );
  }
}
