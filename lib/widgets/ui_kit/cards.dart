import 'package:flutter/material.dart';

/// UI Kit для карточек
class UICards {
  /// Основная карточка
  static Widget primary({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    double? elevation,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      child: Material(
        elevation: elevation ?? 2,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        color: backgroundColor ?? Theme.of(context).cardColor,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Карточка с изображением
  static Widget image({
    required BuildContext context,
    required String imageUrl,
    required Widget child,
    double? imageHeight,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    double? elevation,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
    BoxFit imageFit = BoxFit.cover,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      child: Material(
        elevation: elevation ?? 2,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        color: backgroundColor ?? Theme.of(context).cardColor,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: imageHeight ?? 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(borderRadius?.topLeft.x ?? 12),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: imageFit,
                  ),
                ),
              ),
              Container(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Карточка статистики
  static Widget stats({
    required BuildContext context,
    required String title,
    required String value,
    IconData? icon,
    Color? iconColor,
    Color? valueColor,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.all(4),
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).cardColor,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: iconColor ?? Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? Theme.of(context).textTheme.headlineSmall?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Карточка списка
  static Widget list({
    required BuildContext context,
    required Widget leading,
    required Widget title,
    Widget? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    double? elevation,
    BorderRadius? borderRadius,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        elevation: elevation ?? 1,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        color: backgroundColor ?? Theme.of(context).cardColor,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        subtitle,
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 16),
                  trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Карточка загрузки (skeleton)
  static Widget loading({
    double? height,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
  }) {
    return Container(
      height: height ?? 100,
      margin: margin ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Карточка ошибки
  static Widget error({
    required String message,
    VoidCallback? onRetry,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'Ошибка',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Повторить'),
            ),
          ],
        ],
      ),
    );
  }

  /// Карточка пустого состояния
  static Widget empty({
    required String title,
    String? subtitle,
    IconData? icon,
    Widget? action,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Colors.grey[400],
              size: 64,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 16),
            action,
          ],
        ],
      ),
    );
  }
}

/// Расширение для BuildContext для удобного доступа к карточкам
extension UICardsExtension on BuildContext {
  Widget primaryCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    double? elevation,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return UICards.primary(
      context: this,
      child: child,
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor,
      elevation: elevation,
      borderRadius: borderRadius,
      onTap: onTap,
      isSelected: isSelected,
    );
  }

  Widget imageCard({
    required String imageUrl,
    required Widget child,
    double? imageHeight,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    double? elevation,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
    BoxFit imageFit = BoxFit.cover,
  }) {
    return UICards.image(
      context: this,
      imageUrl: imageUrl,
      child: child,
      imageHeight: imageHeight,
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor,
      elevation: elevation,
      borderRadius: borderRadius,
      onTap: onTap,
      imageFit: imageFit,
    );
  }

  Widget statsCard({
    required String title,
    required String value,
    IconData? icon,
    Color? iconColor,
    Color? valueColor,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
  }) {
    return UICards.stats(
      context: this,
      title: title,
      value: value,
      icon: icon,
      iconColor: iconColor,
      valueColor: valueColor,
      onTap: onTap,
      margin: margin,
    );
  }

  Widget listCard({
    required Widget leading,
    required Widget title,
    Widget? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    double? elevation,
    BorderRadius? borderRadius,
  }) {
    return UICards.list(
      context: this,
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor,
      elevation: elevation,
      borderRadius: borderRadius,
    );
  }
}
