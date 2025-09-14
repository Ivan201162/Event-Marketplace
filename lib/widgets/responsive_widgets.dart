import 'package:flutter/material.dart';

/// Адаптивный виджет для разных размеров экранов
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth >= 1200) {
      return desktop ?? tablet ?? mobile;
    } else if (screenWidth >= 600) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}

/// Адаптивная сетка
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int columns;
    
    if (screenWidth >= 1200) {
      columns = desktopColumns ?? 4;
    } else if (screenWidth >= 600) {
      columns = tabletColumns ?? 2;
    } else {
      columns = mobileColumns ?? 1;
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children.map((child) {
        return SizedBox(
          width: (screenWidth - spacing * (columns - 1)) / columns,
          child: child,
        );
      }).toList(),
    );
  }
}

/// Адаптивный контейнер
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveMaxWidth = maxWidth ?? (screenWidth >= 1200 ? 1200.0 : screenWidth);
    
    return Center(
      child: Container(
        width: effectiveMaxWidth,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
        child: child,
      ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium;
    
    // Адаптивный размер шрифта
    double fontSize = baseStyle?.fontSize ?? 14;
    if (screenWidth >= 1200) {
      fontSize *= 1.2;
    } else if (screenWidth < 600) {
      fontSize *= 0.9;
    }

    return Text(
      text,
      style: baseStyle?.copyWith(fontSize: fontSize),
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
  final ButtonStyle? style;
  final IconData? icon;
  final bool isFullWidth;

  const ResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style,
    this.icon,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    Widget button;
    
    if (icon != null) {
      button = ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: style,
      );
    } else {
      button = ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: Text(text),
      );
    }

    if (isFullWidth || isMobile) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}

/// Адаптивная карточка
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? elevation;
  final Color? color;
  final BorderRadius? borderRadius;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation,
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Card(
      elevation: elevation ?? (isMobile ? 2 : 4),
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(isMobile ? 8 : 12),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(isMobile ? 12 : 16),
        child: child,
      ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    if (isMobile) {
      return ListView.separated(
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemCount: children.length,
        separatorBuilder: (context, index) => SizedBox(height: spacing),
        itemBuilder: (context, index) => children[index],
      );
    } else {
      return Column(
        children: children
            .expand((child) => [child, SizedBox(height: spacing)])
            .take(children.length * 2 - 1)
            .toList(),
      );
    }
  }
}

/// Адаптивная навигация
class ResponsiveNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavigationItem> items;

  const ResponsiveNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    if (isMobile) {
      return BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        items: items.map((item) => BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.label,
        )).toList(),
      );
    } else {
      return NavigationRail(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        labelType: NavigationRailLabelType.all,
        destinations: items.map((item) => NavigationRailDestination(
          icon: Icon(item.icon),
          label: Text(item.label),
        )).toList(),
      );
    }
  }
}

/// Элемент навигации
class NavigationItem {
  final IconData icon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.label,
  });
}

/// Адаптивный диалог
class ResponsiveDialog extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool isFullScreen;

  const ResponsiveDialog({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    if (isFullScreen || isMobile) {
      return Dialog.fullscreen(
        child: Column(
          children: [
            if (title != null)
              AppBar(
                title: Text(title!),
                automaticallyImplyLeading: true,
              ),
            Expanded(child: child),
            if (actions != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
          ],
        ),
      );
    } else {
      return AlertDialog(
        title: title != null ? Text(title!) : null,
        content: child,
        actions: actions,
      );
    }
  }
}

/// Адаптивная форма
class ResponsiveForm extends StatelessWidget {
  final List<Widget> children;
  final GlobalKey<FormState>? formKey;
  final EdgeInsets? padding;

  const ResponsiveForm({
    super.key,
    required this.children,
    this.formKey,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Form(
      key: formKey,
      child: Padding(
        padding: padding ?? EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// Адаптивное поле ввода
class ResponsiveTextField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const ResponsiveTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 12 : 16,
        ),
      ),
    );
  }
}

