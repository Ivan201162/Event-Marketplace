import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Адаптивный контейнер, который изменяет размер в зависимости от экрана
class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? maxWidth;
  final bool centerContent;

  const AdaptiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.maxWidth,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    // Определяем максимальную ширину контента
    double contentMaxWidth = maxWidth ?? (isDesktop ? 1200 : isTablet ? 800 : double.infinity);

    // Определяем отступы
    EdgeInsets contentPadding = padding ?? EdgeInsets.symmetric(
      horizontal: isTablet ? 32 : 16,
      vertical: isTablet ? 24 : 16,
    );

    Widget content = Container(
      padding: contentPadding,
      margin: margin,
      constraints: BoxConstraints(maxWidth: contentMaxWidth),
      child: child,
    );

    if (centerContent && contentMaxWidth < double.infinity) {
      content = Center(child: content);
    }

    return content;
  }
}

/// Адаптивная сетка, которая изменяет количество колонок в зависимости от размера экрана
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double childAspectRatio;
  final double spacing;
  final double runSpacing;
  final int? maxColumns;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.childAspectRatio = 1.0,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.maxColumns,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    // Определяем количество колонок
    int crossAxisCount;
    if (maxColumns != null) {
      crossAxisCount = maxColumns!;
    } else if (isDesktop) {
      crossAxisCount = 4;
    } else if (isTablet) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Адаптивный список, который изменяет отображение в зависимости от размера экрана
class AdaptiveList extends StatelessWidget {
  final List<Widget> children;
  final bool useCardLayout;
  final double? itemHeight;

  const AdaptiveList({
    super.key,
    required this.children,
    this.useCardLayout = true,
    this.itemHeight,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    if (isTablet && useCardLayout) {
      // На планшетах используем сетку карточек
      return AdaptiveGrid(
        children: children,
        childAspectRatio: 1.2,
      );
    } else {
      // На телефонах используем обычный список
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      );
    }
  }
}

/// Адаптивная кнопка, которая изменяет размер в зависимости от экрана
class AdaptiveButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool isFullWidth;
  final double? minHeight;

  const AdaptiveButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.isFullWidth = false,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    Widget button = ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: child,
    );

    if (isFullWidth) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    if (minHeight != null) {
      button = SizedBox(
        height: minHeight,
        child: button,
      );
    }

    return button;
  }
}

/// Адаптивный текст, который изменяет размер шрифта в зависимости от экрана
class AdaptiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AdaptiveText(
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
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    // Определяем размер шрифта
    double? fontSize;
    if (style?.fontSize != null) {
      if (isDesktop) {
        fontSize = style!.fontSize! * 1.2;
      } else if (isTablet) {
        fontSize = style!.fontSize! * 1.1;
      } else {
        fontSize = style!.fontSize;
      }
    }

    return Text(
      text,
      style: style?.copyWith(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Адаптивный AppBar с улучшенным дизайном
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;

  const AdaptiveAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return AppBar(
      title: AdaptiveText(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.inversePrimary,
      foregroundColor: foregroundColor,
      elevation: elevation ?? (isTablet ? 2 : 1),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Адаптивная карточка с улучшенным дизайном
class AdaptiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? elevation;
  final Color? color;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const AdaptiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.color,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    Widget card = Card(
      elevation: elevation ?? (isTablet ? 4 : 2),
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(isTablet ? 16 : 12),
      ),
      margin: margin ?? EdgeInsets.all(isTablet ? 16 : 8),
      child: Padding(
        padding: padding ?? EdgeInsets.all(isTablet ? 24 : 16),
        child: child,
      ),
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(isTablet ? 16 : 12),
        child: card,
      );
    }

    return card;
  }
}

/// Адаптивный диалог с улучшенным дизайном
class AdaptiveDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final bool scrollable;

  const AdaptiveDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    Widget dialogContent = content;
    if (scrollable) {
      dialogContent = SingleChildScrollView(child: content);
    }

    return AlertDialog(
      title: AdaptiveText(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: dialogContent,
      actions: actions,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
      ),
      contentPadding: EdgeInsets.all(isTablet ? 24 : 16),
      actionsPadding: EdgeInsets.all(isTablet ? 24 : 16),
    );
  }
}

/// Адаптивный BottomSheet с улучшенным дизайном
class AdaptiveBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool isScrollControlled;

  const AdaptiveBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.isScrollControlled = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    Widget content = child;
    
    if (title != null || actions != null) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Padding(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: AdaptiveText(
                title!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(),
          ],
          Flexible(child: content),
          if (actions != null) ...[
            const Divider(),
            Padding(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              ),
            ),
          ],
        ],
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: content,
    );
  }
}

/// Адаптивный индикатор загрузки
class AdaptiveLoadingIndicator extends StatelessWidget {
  final String? message;
  final double? size;

  const AdaptiveLoadingIndicator({
    super.key,
    this.message,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? (isTablet ? 48 : 32),
            height: size ?? (isTablet ? 48 : 32),
            child: const CircularProgressIndicator(),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            AdaptiveText(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Адаптивное сообщение об ошибке
class AdaptiveErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const AdaptiveErrorMessage({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? Icons.error_outline,
            size: isTablet ? 64 : 48,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          AdaptiveText(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            AdaptiveButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ],
      ),
    );
  }
}
