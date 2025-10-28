import 'package:flutter/material.dart';

/// Оптимизированные const виджеты для улучшения производительности

/// Оптимизированная кнопка
class OptimizedButton extends StatelessWidget {
  const OptimizedButton({
    required this.onPressed, required this.child, super.key,
    this.style,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: Padding(padding: padding, child: child),
      );
}

/// Оптимизированная карточка
class OptimizedCard extends StatelessWidget {
  const OptimizedCard({
    required this.child, super.key,
    this.margin = const EdgeInsets.all(8),
    this.padding = const EdgeInsets.all(16),
    this.elevation = 2,
    this.borderRadius = 8,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => Card(
        margin: margin,
        elevation: elevation,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),),
        child: Padding(padding: padding, child: child),
      );
}

/// Оптимизированный список элементов
class OptimizedListTile extends StatelessWidget {
  const OptimizedListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        contentPadding: padding,
      );
}

/// Оптимизированный контейнер с градиентом
class OptimizedGradientContainer extends StatelessWidget {
  const OptimizedGradientContainer({
    required this.child, required this.gradient, super.key,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 8,
  });

  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      );
}

/// Оптимизированный текст с стилизацией
class OptimizedText extends StatelessWidget {
  const OptimizedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) => Text(text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,);
}

/// Оптимизированная иконка
class OptimizedIcon extends StatelessWidget {
  const OptimizedIcon(this.icon, {super.key, this.size = 24, this.color});

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Icon(icon, size: size, color: color);
}

/// Оптимизированный разделитель
class OptimizedDivider extends StatelessWidget {
  const OptimizedDivider({
    super.key,
    this.height = 1,
    this.thickness = 1,
    this.color,
    this.indent = 0,
    this.endIndent = 0,
  });

  final double height;
  final double thickness;
  final Color? color;
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) => Divider(
        height: height,
        thickness: thickness,
        color: color,
        indent: indent,
        endIndent: endIndent,
      );
}

/// Оптимизированный отступ
class OptimizedSpacing extends StatelessWidget {
  const OptimizedSpacing({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) => SizedBox(width: width, height: height);
}

/// Оптимизированный контейнер с тенью
class OptimizedShadowContainer extends StatelessWidget {
  const OptimizedShadowContainer({
    required this.child, super.key,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(8),
    this.borderRadius = 8,
    this.elevation = 4,
    this.shadowColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double elevation;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: shadowColor ?? Colors.black.withValues(alpha: 0.1),
              blurRadius: elevation,
              offset: Offset(0, elevation / 2),
            ),
          ],
        ),
        child: child,
      );
}

/// Оптимизированный индикатор загрузки
class OptimizedLoadingIndicator extends StatelessWidget {
  const OptimizedLoadingIndicator(
      {super.key, this.size = 24, this.strokeWidth = 2, this.color,});

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Theme.of(context).primaryColor,),
        ),
      );
}

/// Оптимизированный пустой виджет
class OptimizedEmptyWidget extends StatelessWidget {
  const OptimizedEmptyWidget({
    super.key,
    this.icon = Icons.inbox,
    this.title = 'Нет данных',
    this.subtitle,
    this.iconSize = 64,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OptimizedIcon(icon, size: iconSize, color: Colors.grey),
            const OptimizedSpacing(height: 16),
            OptimizedText(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const OptimizedSpacing(height: 8),
              OptimizedText(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
}
