import 'package:event_marketplace_app/utils/responsive_utils.dart';
import 'package:flutter/material.dart';

/// Адаптивный контейнер
class ResponsiveContainer extends StatelessWidget {

  const ResponsiveContainer({
    required this.child, super.key,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.decoration,
    this.width,
    this.height,
  });
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final Color? color;
  final BoxDecoration? decoration;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
      margin: margin,
      decoration: decoration ??
          BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(
              borderRadius ??
                  ResponsiveUtils.getResponsiveBorderRadius(context),
            ),
          ),
      child: child,
    );
  }
}

/// Адаптивный текст
class ResponsiveText extends StatelessWidget {

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style?.copyWith(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context),
          ) ??
          TextStyle(
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

  const ResponsiveButton({
    required this.text, super.key,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.borderRadius,
    this.width,
    this.height,
  });
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsets? padding;
  final double? borderRadius;
  final double? width;
  final double? height;

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
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getResponsiveSpacing(context) * 2,
                vertical: ResponsiveUtils.getResponsiveSpacing(context),
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              borderRadius ??
                  ResponsiveUtils.getResponsiveBorderRadius(context),
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

  const ResponsiveIcon(
    this.icon, {
    super.key,
    this.color,
    this.size,
  });
  final IconData icon;
  final Color? color;
  final double? size;

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

  const ResponsiveCard({
    required this.child, super.key,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.decoration,
    this.elevation,
    this.width,
    this.height,
  });
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final Color? color;
  final BoxDecoration? decoration;
  final double? elevation;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 2.0,
      margin: margin ??
          EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          borderRadius ?? ResponsiveUtils.getResponsiveBorderRadius(context),
        ),
      ),
      child: Container(
        width: width,
        height: height,
        padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
        decoration: decoration ??
            BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(
                borderRadius ??
                    ResponsiveUtils.getResponsiveBorderRadius(context),
              ),
            ),
        child: child,
      ),
    );
  }
}

/// Адаптивная сетка
class ResponsiveGrid extends StatelessWidget {

  const ResponsiveGrid({
    required this.children, super.key,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.crossAxisCount,
    this.childAspectRatio,
    this.mainAxisSpacing,
  });
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? crossAxisCount;
  final double? childAspectRatio;
  final double? mainAxisSpacing;

  @override
  Widget build(BuildContext context) {
    final columns =
        crossAxisCount ?? ResponsiveUtils.getResponsiveColumns(context);

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

  const ResponsiveList({
    required this.children, super.key,
    this.spacing = 8.0,
    this.shrinkWrap = false,
    this.physics,
  });
  final List<Widget> children;
  final double spacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

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

  const ResponsiveAppBar({
    required this.title, super.key,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
  });
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: ResponsiveText(
        title,
        style: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(
            context,
            mobile: 18,
            tablet: 20,
            desktop: 22,
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
  Size get preferredSize =>
      Size.fromHeight(ResponsiveUtils.getResponsiveAppBarHeight(null));
}

/// Адаптивный BottomNavigationBar
class ResponsiveBottomNavBar extends StatelessWidget {

  const ResponsiveBottomNavBar({
    required this.items, required this.currentIndex, required this.onTap, super.key,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation,
  });
  final List<BottomNavigationBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? elevation;

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

  const ResponsiveDivider({
    super.key,
    this.height,
    this.thickness,
    this.color,
    this.indent,
    this.endIndent,
  });
  final double? height;
  final double? thickness;
  final Color? color;
  final double? indent;
  final double? endIndent;

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

  const ResponsiveSpacing({
    super.key,
    this.width,
    this.height,
    this.multiplier = 1.0,
  });
  final double? width;
  final double? height;
  final double multiplier;

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

  const ResponsiveLayoutBuilder({
    required this.mobile, super.key,
    this.tablet,
    this.desktop,
  });
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

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

  const ResponsiveSafeArea({
    required this.child, super.key,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

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

  const ResponsiveScaffold({
    super.key,
    this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

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
