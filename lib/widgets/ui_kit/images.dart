import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// UI Kit для изображений
class UIImages {
  /// Основное изображение с кэшированием
  static Widget primary({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
    VoidCallback? onTap,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
            errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
            fadeInDuration: const Duration(milliseconds: 300),
            fadeOutDuration: const Duration(milliseconds: 100),
          ),
        ),
      ),
    );
  }

  /// Изображение с ленивой загрузкой
  static Widget lazy({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
    VoidCallback? onTap,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
            errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
            fadeInDuration: const Duration(milliseconds: 300),
            fadeOutDuration: const Duration(milliseconds: 100),
            memCacheWidth: width?.toInt(),
            memCacheHeight: height?.toInt(),
          ),
        ),
      ),
    );
  }

  /// Изображение с прогрессом загрузки
  static Widget withProgress({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? progressColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            placeholder: (context, url) => _buildProgressPlaceholder(
              progressColor: progressColor,
            ),
            errorWidget: (context, url, error) => _buildErrorWidget(),
            fadeInDuration: const Duration(milliseconds: 300),
            fadeOutDuration: const Duration(milliseconds: 100),
          ),
        ),
      ),
    );
  }

  /// Изображение с анимацией появления
  static Widget animated({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
    VoidCallback? onTap,
    Color? backgroundColor,
    Duration animationDuration = const Duration(milliseconds: 500),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
            errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
            fadeInDuration: animationDuration,
            fadeOutDuration: const Duration(milliseconds: 100),
          ),
        ),
      ),
    );
  }

  /// Изображение с эффектом размытия
  static Widget blurred({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    double blurRadius = 10,
    Widget? child,
    VoidCallback? onTap,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                width: width,
                height: height,
                fit: fit,
                placeholder: (context, url) => _buildPlaceholder(),
                errorWidget: (context, url, error) => _buildErrorWidget(),
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 100),
              ),
              if (child != null)
                Positioned.fill(
                  child: child,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Изображение с градиентом
  static Widget withGradient({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    required Gradient gradient,
    Widget? child,
    VoidCallback? onTap,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                width: width,
                height: height,
                fit: fit,
                placeholder: (context, url) => _buildPlaceholder(),
                errorWidget: (context, url, error) => _buildErrorWidget(),
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 100),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: gradient,
                  ),
                ),
              ),
              if (child != null)
                Positioned.fill(
                  child: child,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Изображение с тенью
  static Widget withShadow({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Color? shadowColor,
    double elevation = 4,
    Offset offset = const Offset(0, 2),
    double blurRadius = 8,
    Widget? child,
    VoidCallback? onTap,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: shadowColor ?? Colors.black.withOpacity(0.2),
              offset: offset,
              blurRadius: blurRadius,
              spreadRadius: elevation,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                width: width,
                height: height,
                fit: fit,
                placeholder: (context, url) => _buildPlaceholder(),
                errorWidget: (context, url, error) => _buildErrorWidget(),
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 100),
              ),
              if (child != null)
                Positioned.fill(
                  child: child,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Плейсхолдер для изображения
  static Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.image,
          color: Colors.grey,
          size: 48,
        ),
      ),
    );
  }

  /// Виджет ошибки для изображения
  static Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
          size: 48,
        ),
      ),
    );
  }

  /// Плейсхолдер с прогрессом
  static Widget _buildProgressPlaceholder({Color? progressColor}) {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            progressColor ?? Colors.blue,
          ),
        ),
      ),
    );
  }
}

/// Расширение для BuildContext для удобного доступа к изображениям
extension UIImagesExtension on BuildContext {
  Widget primaryImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
    VoidCallback? onTap,
    Color? backgroundColor,
  }) {
    return UIImages.primary(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      placeholder: placeholder,
      errorWidget: errorWidget,
      onTap: onTap,
      backgroundColor: backgroundColor,
    );
  }

  Widget lazyImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
    VoidCallback? onTap,
    Color? backgroundColor,
  }) {
    return UIImages.lazy(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      placeholder: placeholder,
      errorWidget: errorWidget,
      onTap: onTap,
      backgroundColor: backgroundColor,
    );
  }

  Widget progressImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? progressColor,
  }) {
    return UIImages.withProgress(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      onTap: onTap,
      backgroundColor: backgroundColor,
      progressColor: progressColor,
    );
  }

  Widget animatedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
    VoidCallback? onTap,
    Color? backgroundColor,
    Duration animationDuration = const Duration(milliseconds: 500),
  }) {
    return UIImages.animated(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      placeholder: placeholder,
      errorWidget: errorWidget,
      onTap: onTap,
      backgroundColor: backgroundColor,
      animationDuration: animationDuration,
    );
  }
}
