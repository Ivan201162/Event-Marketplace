import 'package:flutter/material.dart';

/// Утилиты для адаптивного дизайна
class ResponsiveUtils {
  /// Определение типа экрана
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) {
      return ScreenType.mobile;
    } else if (width < 900) {
      return ScreenType.tablet;
    } else {
      return ScreenType.desktop;
    }
  }

  /// Определение размера экрана
  static ScreenSize getScreenSize(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (size.width < 360) {
      return ScreenSize.small;
    } else if (size.width < 600) {
      return ScreenSize.medium;
    } else if (size.width < 900) {
      return ScreenSize.large;
    } else {
      return ScreenSize.extraLarge;
    }
  }

  /// Адаптивная ширина
  static double getResponsiveWidth(
    BuildContext context, {
    double mobile = 1.0,
    double tablet = 0.8,
    double desktop = 0.6,
  }) {
    final screenType = getScreenType(context);
    final screenWidth = MediaQuery.of(context).size.width;

    switch (screenType) {
      case ScreenType.mobile:
        return screenWidth * mobile;
      case ScreenType.tablet:
        return screenWidth * tablet;
      case ScreenType.desktop:
        return screenWidth * desktop;
    }
  }

  /// Адаптивная высота
  static double getResponsiveHeight(
    BuildContext context, {
    double mobile = 1.0,
    double tablet = 0.9,
    double desktop = 0.8,
  }) {
    final screenType = getScreenType(context);
    final screenHeight = MediaQuery.of(context).size.height;

    switch (screenType) {
      case ScreenType.mobile:
        return screenHeight * mobile;
      case ScreenType.tablet:
        return screenHeight * tablet;
      case ScreenType.desktop:
        return screenHeight * desktop;
    }
  }

  /// Адаптивный размер шрифта
  static double getResponsiveFontSize(
    BuildContext context, {
    double mobile = 14.0,
    double tablet = 16.0,
    double desktop = 18.0,
  }) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet;
      case ScreenType.desktop:
        return desktop;
    }
  }

  /// Адаптивный отступ
  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    EdgeInsets mobile = const EdgeInsets.all(16),
    EdgeInsets tablet = const EdgeInsets.all(24),
    EdgeInsets desktop = const EdgeInsets.all(32),
  }) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet;
      case ScreenType.desktop:
        return desktop;
    }
  }

  /// Адаптивное количество колонок
  static int getResponsiveColumns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet;
      case ScreenType.desktop:
        return desktop;
    }
  }

  /// Адаптивный размер карточки
  static Size getResponsiveCardSize(
    BuildContext context, {
    Size mobile = const Size(300, 200),
    Size tablet = const Size(400, 250),
    Size desktop = const Size(500, 300),
  }) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet;
      case ScreenType.desktop:
        return desktop;
    }
  }

  /// Адаптивный размер иконки
  static double getResponsiveIconSize(
    BuildContext context, {
    double mobile = 24.0,
    double tablet = 28.0,
    double desktop = 32.0,
  }) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet;
      case ScreenType.desktop:
        return desktop;
    }
  }

  /// Адаптивная высота кнопки
  static double getResponsiveButtonHeight(
    BuildContext context, {
    double mobile = 48.0,
    double tablet = 52.0,
    double desktop = 56.0,
  }) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet;
      case ScreenType.desktop:
        return desktop;
    }
  }

  /// Адаптивный радиус границы
  static double getResponsiveBorderRadius(
    BuildContext context, {
    double mobile = 8.0,
    double tablet = 12.0,
    double desktop = 16.0,
  }) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet;
      case ScreenType.desktop:
        return desktop;
    }
  }

  /// Адаптивный отступ между элементами
  static double getResponsiveSpacing(
    BuildContext context, {
    double mobile = 8.0,
    double tablet = 12.0,
    double desktop = 16.0,
  }) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet;
      case ScreenType.desktop:
        return desktop;
    }
  }

  /// Адаптивная высота AppBar
  static double getResponsiveAppBarHeight(
    BuildContext context, {
    double mobile = 56.0,
    double tablet = 64.0,
    double desktop = 72.0,
  }) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet;
      case ScreenType.desktop:
        return desktop;
    }
  }

  /// Адаптивная высота BottomNavigationBar
  static double getResponsiveBottomNavHeight(
    BuildContext context, {
    double mobile = 60.0,
    double tablet = 70.0,
    double desktop = 80.0,
  }) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet;
      case ScreenType.desktop:
        return desktop;
    }
  }

  /// Проверка, является ли экран мобильным
  static bool isMobile(BuildContext context) {
    return getScreenType(context) == ScreenType.mobile;
  }

  /// Проверка, является ли экран планшетом
  static bool isTablet(BuildContext context) {
    return getScreenType(context) == ScreenType.tablet;
  }

  /// Проверка, является ли экран десктопом
  static bool isDesktop(BuildContext context) {
    return getScreenType(context) == ScreenType.desktop;
  }

  /// Проверка, является ли экран маленьким
  static bool isSmallScreen(BuildContext context) {
    return getScreenSize(context) == ScreenSize.small;
  }

  /// Проверка, является ли экран большим
  static bool isLargeScreen(BuildContext context) {
    return getScreenSize(context) == ScreenSize.large ||
        getScreenSize(context) == ScreenSize.extraLarge;
  }

  /// Адаптивный LayoutBuilder
  static Widget responsiveBuilder(
    BuildContext context, {
    required Widget Function(BuildContext context) mobile,
    Widget Function(BuildContext context)? tablet,
    Widget Function(BuildContext context)? desktop,
  }) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return mobile(context);
      case ScreenType.tablet:
        return tablet?.call(context) ?? mobile(context);
      case ScreenType.desktop:
        return desktop?.call(context) ??
            tablet?.call(context) ??
            mobile(context);
    }
  }

  /// Адаптивный GridView
  static Widget responsiveGrid({
    required List<Widget> children,
    required BuildContext context,
    double spacing = 8.0,
    double runSpacing = 8.0,
  }) {
    final columns = getResponsiveColumns(context);

    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: spacing,
      mainAxisSpacing: runSpacing,
      children: children,
    );
  }

  /// Адаптивный ListView
  static Widget responsiveList({
    required List<Widget> children,
    required BuildContext context,
    double spacing = 8.0,
    bool shrinkWrap = false,
  }) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      itemCount: children.length,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) => children[index],
    );
  }

  /// Адаптивный Container
  static Widget responsiveContainer({
    required Widget child,
    required BuildContext context,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? borderRadius,
    Color? color,
    BoxDecoration? decoration,
  }) {
    return Container(
      padding: padding ?? getResponsivePadding(context),
      margin: margin,
      decoration: decoration ??
          BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(
              borderRadius ?? getResponsiveBorderRadius(context),
            ),
          ),
      child: child,
    );
  }

  /// Адаптивный Text
  static Widget responsiveText(
    String text, {
    required BuildContext context,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Text(
      text,
      style: style?.copyWith(
            fontSize: getResponsiveFontSize(context),
          ) ??
          TextStyle(
            fontSize: getResponsiveFontSize(context),
          ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// Адаптивный Button
  static Widget responsiveButton({
    required String text,
    required VoidCallback onPressed,
    required BuildContext context,
    Color? backgroundColor,
    Color? textColor,
    EdgeInsets? padding,
    double? borderRadius,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: padding ??
            EdgeInsets.symmetric(
              horizontal: getResponsiveSpacing(context) * 2,
              vertical: getResponsiveSpacing(context),
            ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            borderRadius ?? getResponsiveBorderRadius(context),
          ),
        ),
        minimumSize: Size(
          0,
          getResponsiveButtonHeight(context),
        ),
      ),
      child: responsiveText(
        text,
        context: context,
        style: TextStyle(
          fontSize: getResponsiveFontSize(context),
        ),
      ),
    );
  }

  /// Адаптивный Icon
  static Widget responsiveIcon(
    IconData icon, {
    required BuildContext context,
    Color? color,
    double? size,
  }) {
    return Icon(
      icon,
      color: color,
      size: size ?? getResponsiveIconSize(context),
    );
  }

  /// Адаптивный AppBar
  static PreferredSizeWidget responsiveAppBar({
    required String title,
    required BuildContext context,
    List<Widget>? actions,
    Widget? leading,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return AppBar(
      title: responsiveText(
        title,
        context: context,
        style: TextStyle(
          fontSize: getResponsiveFontSize(context,
              mobile: 18, tablet: 20, desktop: 22,),
        ),
      ),
      actions: actions,
      leading: leading,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      toolbarHeight: getResponsiveAppBarHeight(context),
    );
  }

  /// Адаптивный BottomNavigationBar
  static Widget responsiveBottomNavBar({
    required List<BottomNavigationBarItem> items,
    required int currentIndex,
    required ValueChanged<int> onTap,
    required BuildContext context,
    Color? backgroundColor,
    Color? selectedItemColor,
    Color? unselectedItemColor,
  }) {
    return BottomNavigationBar(
      items: items,
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: backgroundColor,
      selectedItemColor: selectedItemColor,
      unselectedItemColor: unselectedItemColor,
      type: isDesktop(context)
          ? BottomNavigationBarType.fixed
          : BottomNavigationBarType.fixed,
      elevation: 8,
    );
  }
}

/// Типы экранов
enum ScreenType {
  mobile,
  tablet,
  desktop,
}

/// Размеры экранов
enum ScreenSize {
  small,
  medium,
  large,
  extraLarge,
}
