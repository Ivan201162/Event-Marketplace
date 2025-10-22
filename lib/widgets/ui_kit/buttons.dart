import 'package:flutter/material.dart';

/// UI Kit для кнопок
class UIButtons {
  /// Основная кнопка
  static Widget primary({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    double? width,
    double height = 48,
    EdgeInsetsGeometry? padding,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  /// Вторичная кнопка
  static Widget secondary({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    double? width,
    double height = 48,
    EdgeInsetsGeometry? padding,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).primaryColor,
          side: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  /// Текстовая кнопка
  static Widget text({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    Color? textColor,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return TextButton(
      onPressed: isEnabled && !isLoading ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: textColor ?? Theme.of(context).primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  textColor ?? Theme.of(context).primaryColor,
                ),
              ),
            )
          : Text(
              text,
              style: TextStyle(
                fontSize: fontSize ?? 16,
                fontWeight: fontWeight ?? FontWeight.w500,
              ),
            ),
    );
  }

  /// Кнопка с иконкой
  static Widget icon({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? iconColor,
    double? iconSize,
    bool isEnabled = true,
  }) {
    return IconButton(
      onPressed: isEnabled ? onPressed : null,
      icon: Icon(
        icon,
        color: iconColor ?? Theme.of(context).iconTheme.color,
        size: iconSize ?? 24,
      ),
      tooltip: tooltip,
    );
  }

  /// Плавающая кнопка действий
  static Widget floatingAction({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? backgroundColor,
    Color? foregroundColor,
    bool isExtended = false,
    String? label,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      child: isExtended
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon),
                if (label != null) ...[
                  const SizedBox(width: 8),
                  Text(label),
                ],
              ],
            )
          : Icon(icon),
    );
  }
}

/// Расширение для BuildContext для удобного доступа к кнопкам
extension UIButtonsExtension on BuildContext {
  Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    double? width,
    double height = 48,
    EdgeInsetsGeometry? padding,
  }) {
    return UIButtons.primary(
      context: this,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      width: width,
      height: height,
      padding: padding,
    );
  }

  Widget secondaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    double? width,
    double height = 48,
    EdgeInsetsGeometry? padding,
  }) {
    return UIButtons.secondary(
      context: this,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      width: width,
      height: height,
      padding: padding,
    );
  }

  Widget textButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    Color? textColor,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return UIButtons.text(
      context: this,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      textColor: textColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }
}
