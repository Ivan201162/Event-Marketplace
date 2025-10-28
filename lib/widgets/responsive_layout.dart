import 'package:event_marketplace_app/core/responsive_utils.dart';
import 'package:flutter/material.dart';

/// Адаптивный layout для разных размеров экранов
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.mobile, super.key,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;

    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
}

/// Адаптивный Scaffold с поддержкой разных размеров экранов
class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    required this.body, super.key,
    this.appBar,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final FloatingActionButton? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;

    // Для десктопа используем другой layout
    if (screenType == ScreenType.desktop ||
        screenType == ScreenType.largeDesktop) {
      return _buildDesktopLayout(context);
    }

    // Для мобильных устройств и планшетов используем стандартный Scaffold
    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      backgroundColor: backgroundColor,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }

  Widget _buildDesktopLayout(BuildContext context) => Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            // Боковая панель навигации
            if (drawer != null) SizedBox(width: 280, child: drawer),
            // Основной контент
            Expanded(child: body),
            // Правая панель (если есть)
            if (endDrawer != null) SizedBox(width: 280, child: endDrawer),
          ],
        ),
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        backgroundColor: backgroundColor,
      );
}

/// Адаптивная навигационная панель
class ResponsiveNavigationBar extends StatelessWidget {
  const ResponsiveNavigationBar({
    required this.currentIndex, required this.items, super.key,
    this.onTap,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
  });
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final List<NavigationBarItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;

    if (screenType == ScreenType.desktop ||
        screenType == ScreenType.largeDesktop) {
      return _buildNavigationRail(context);
    } else {
      return _buildBottomNavigationBar(context);
    }
  }

  Widget _buildBottomNavigationBar(BuildContext context) => BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: backgroundColor,
        selectedItemColor: selectedItemColor,
        unselectedItemColor: unselectedItemColor,
        items: items
            .map((item) =>
                BottomNavigationBarItem(icon: item.icon, label: item.label),)
            .toList(),
      );

  Widget _buildNavigationRail(BuildContext context) => NavigationRail(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: backgroundColor,
        selectedIconTheme: IconThemeData(color: selectedItemColor),
        unselectedIconTheme: IconThemeData(color: unselectedItemColor),
        selectedLabelTextStyle: TextStyle(color: selectedItemColor),
        unselectedLabelTextStyle: TextStyle(color: unselectedItemColor),
        destinations: items
            .map((item) => NavigationRailDestination(
                icon: item.icon, label: Text(item.label),),)
            .toList(),
      );
}

/// Элемент навигации
class NavigationBarItem {
  const NavigationBarItem({required this.icon, required this.label});
  final Widget icon;
  final String label;
}

/// Адаптивная карточка
class ResponsiveCard extends StatelessWidget {
  const ResponsiveCard({
    required this.child, super.key,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.shadow,
  });
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final BoxShadow? shadow;

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;

    // Адаптивные размеры
    EdgeInsets effectivePadding;
    EdgeInsets effectiveMargin;
    double effectiveElevation;
    BorderRadius effectiveBorderRadius;

    switch (screenType) {
      case ScreenType.mobile:
        effectivePadding = padding ?? const EdgeInsets.all(16);
        effectiveMargin = margin ?? const EdgeInsets.all(8);
        effectiveElevation = elevation ?? 2;
        effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);
      case ScreenType.tablet:
        effectivePadding = padding ?? const EdgeInsets.all(20);
        effectiveMargin = margin ?? const EdgeInsets.all(12);
        effectiveElevation = elevation ?? 3;
        effectiveBorderRadius = borderRadius ?? BorderRadius.circular(16);
      case ScreenType.desktop:
        effectivePadding = padding ?? const EdgeInsets.all(24);
        effectiveMargin = margin ?? const EdgeInsets.all(16);
        effectiveElevation = elevation ?? 4;
        effectiveBorderRadius = borderRadius ?? BorderRadius.circular(20);
      case ScreenType.largeDesktop:
        effectivePadding = padding ?? const EdgeInsets.all(28);
        effectiveMargin = margin ?? const EdgeInsets.all(20);
        effectiveElevation = elevation ?? 5;
        effectiveBorderRadius = borderRadius ?? BorderRadius.circular(24);
    }

    return Container(
      margin: effectiveMargin,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: effectiveBorderRadius,
        boxShadow: shadow != null
            ? [shadow!]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: effectiveElevation * 2,
                  offset: Offset(0, effectiveElevation),
                ),
              ],
      ),
      child: Padding(padding: effectivePadding, child: child),
    );
  }
}

/// Адаптивный список
class ResponsiveList extends StatelessWidget {
  const ResponsiveList(
      {required this.children, super.key, this.padding, this.spacing,});
  final List<Widget> children;
  final EdgeInsets? padding;
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    // final screenType = context.screenType;
    final effectiveSpacing =
        spacing ?? ResponsiveUtils.getItemSpacing(context.screenWidth);
    final effectivePadding =
        padding ?? ResponsiveUtils.getScreenPadding(context.screenWidth);

    return Padding(
      padding: effectivePadding,
      child: Column(
        children: children
            .expand(
              (child) => [
                child,
                if (child != children.last) SizedBox(height: effectiveSpacing),
              ],
            )
            .toList(),
      ),
    );
  }
}

/// Адаптивная кнопка
class ResponsiveButton extends StatelessWidget {
  const ResponsiveButton({
    required this.child, super.key,
    this.onPressed,
    this.style,
    this.padding,
  });
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;

    EdgeInsets effectivePadding;
    double fontSize;

    switch (screenType) {
      case ScreenType.mobile:
        effectivePadding =
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
        fontSize = 14;
      case ScreenType.tablet:
        effectivePadding =
            padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
        fontSize = 16;
      case ScreenType.desktop:
        effectivePadding =
            padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
        fontSize = 16;
      case ScreenType.largeDesktop:
        effectivePadding =
            padding ?? const EdgeInsets.symmetric(horizontal: 28, vertical: 18);
        fontSize = 18;
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: style?.copyWith(
            padding: WidgetStateProperty.all(effectivePadding),
            textStyle: WidgetStateProperty.all(TextStyle(fontSize: fontSize)),
          ) ??
          ElevatedButton.styleFrom(
            padding: effectivePadding,
            textStyle: TextStyle(fontSize: fontSize),
          ),
      child: child,
    );
  }
}

/// Адаптивный диалог
class ResponsiveDialog extends StatelessWidget {
  const ResponsiveDialog({
    required this.child, super.key,
    this.title,
    this.actions,
    this.contentPadding,
  });
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final EdgeInsets? contentPadding;

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;

    double maxWidth;
    EdgeInsets effectiveContentPadding;

    switch (screenType) {
      case ScreenType.mobile:
        maxWidth = context.screenWidth * 0.9;
        effectiveContentPadding = contentPadding ?? const EdgeInsets.all(16);
      case ScreenType.tablet:
        maxWidth = 500;
        effectiveContentPadding = contentPadding ?? const EdgeInsets.all(20);
      case ScreenType.desktop:
        maxWidth = 600;
        effectiveContentPadding = contentPadding ?? const EdgeInsets.all(24);
      case ScreenType.largeDesktop:
        maxWidth = 700;
        effectiveContentPadding = contentPadding ?? const EdgeInsets.all(28);
    }

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Padding(
                padding: effectiveContentPadding,
                child: Text(title!,
                    style: Theme.of(context).textTheme.headlineSmall,),
              ),
            Flexible(
              child: Padding(padding: effectiveContentPadding, child: child),
            ),
            if (actions != null)
              Padding(
                padding: effectiveContentPadding,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions!,),
              ),
          ],
        ),
      ),
    );
  }
}
