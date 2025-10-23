import 'package:flutter/material.dart';
import '../../utils/responsive_utils.dart';

/// Адаптивный контейнер
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final Color? color;
  final BoxDecoration? decoration;
  final double? width;
  final double? height;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.decoration,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
      margin: margin,
      decoration: decoration ?? BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(
          borderRadius ?? ResponsiveUtils.getResponsiveBorderRadius(context),
        ),
      ),
      child: child,
    );
  }
}

/// Адаптивный текст
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style?.copyWith(
        fontSize: ResponsiveUtils.getResponsiveFontSize(context),
      ) ?? TextStyle(
        fontSize: ResponsiveUtils.getResponsiveFontSize(context),
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Адаптивная кнопка
class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsets? padding;
  final double? borderRadius;
  final double? width;
  final double? height;

  const ResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.borderRadius,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? ResponsiveUtils.getResponsiveButtonHeight(context),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getResponsiveSpacing(context) * 2,
            vertical: ResponsiveUtils.getResponsiveSpacing(context),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              borderRadius ?? ResponsiveUtils.getResponsiveBorderRadius(context),
            ),
          ),
        ),
        child: ResponsiveText(
          text,
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context),
          ),
        ),
      ),
    );
  }
}

/// Адаптивная иконка
class ResponsiveIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double? size;

  const ResponsiveIcon(
    this.icon, {
    super.key,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: color,
      size: size ?? ResponsiveUtils.getResponsiveIconSize(context),
    );
  }
}

/// Адаптивная карточка
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final Color? color;
  final BoxDecoration? decoration;
  final double? elevation;
  final double? width;
  final double? height;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.decoration,
    this.elevation,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 2.0,
      margin: margin ?? EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          borderRadius ?? ResponsiveUtils.getResponsiveBorderRadius(context),
        ),
      ),
      child: Container(
        width: width,
        height: height,
        padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
        decoration: decoration ?? BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(
            borderRadius ?? ResponsiveUtils.getResponsiveBorderRadius(context),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Адаптивная сетка
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? crossAxisCount;
  final double? childAspectRatio;
  final double? mainAxisSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.crossAxisCount,
    this.childAspectRatio,
    this.mainAxisSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final columns = crossAxisCount ?? ResponsiveUtils.getResponsiveColumns(context);
    
    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: spacing,
      mainAxisSpacing: mainAxisSpacing ?? runSpacing,
      childAspectRatio: childAspectRatio ?? 1.0,
      children: children,
    );
  }
}

/// Адаптивный список
class ResponsiveList extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveList({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Адаптивный AppBar
class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;

  const ResponsiveAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: ResponsiveText(
        title,
        style: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(
            context,
            mobile: 18.0,
            tablet: 20.0,
            desktop: 22.0,
          ),
        ),
      ),
      actions: actions,
      leading: leading,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      toolbarHeight: ResponsiveUtils.getResponsiveAppBarHeight(context),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(ResponsiveUtils.getResponsiveAppBarHeight(null));
}

/// Адаптивный BottomNavigationBar
class ResponsiveBottomNavBar extends StatelessWidget {
  final List<BottomNavigationBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? elevation;

  const ResponsiveBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: items,
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: backgroundColor,
      selectedItemColor: selectedItemColor,
      unselectedItemColor: unselectedItemColor,
      elevation: elevation ?? 8.0,
      type: ResponsiveUtils.isDesktop(context) 
          ? BottomNavigationBarType.fixed 
          : BottomNavigationBarType.fixed,
    );
  }
}

/// Адаптивный разделитель
class ResponsiveDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final Color? color;
  final double? indent;
  final double? endIndent;

  const ResponsiveDivider({
    super.key,
    this.height,
    this.thickness,
    this.color,
    this.indent,
    this.endIndent,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height ?? ResponsiveUtils.getResponsiveSpacing(context),
      thickness: thickness ?? 1.0,
      color: color,
      indent: indent,
      endIndent: endIndent,
    );
  }
}

/// Адаптивный отступ
class ResponsiveSpacing extends StatelessWidget {
  final double? width;
  final double? height;
  final double multiplier;

  const ResponsiveSpacing({
    super.key,
    this.width,
    this.height,
    this.multiplier = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveUtils.getResponsiveSpacing(context) * multiplier;
    
    return SizedBox(
      width: width ?? spacing,
      height: height ?? spacing,
    );
  }
}

/// Адаптивный LayoutBuilder
class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveLayoutBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils.responsiveBuilder(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

/// Адаптивный SafeArea
class ResponsiveSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const ResponsiveSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
}

/// Адаптивный Scaffold
class ResponsiveScaffold extends StatelessWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  const ResponsiveScaffold({
    super.key,
    this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
