import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Оптимизированный виджет для загрузки изображений с кэшированием
class OptimizedImage extends StatelessWidget {
  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeOutDuration = const Duration(milliseconds: 100),
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: fadeOutDuration,
        placeholder: placeholder as Widget Function(BuildContext, String)? ??
            (context, url) => _buildPlaceholder(),
        errorWidget:
            errorWidget as Widget Function(BuildContext, String, Object)? ??
                (context, url, error) => _buildErrorWidget(),
        // Оптимизации для производительности
        maxWidthDiskCache: 1000,
        maxHeightDiskCache: 1000,
      );

  Widget _buildPlaceholder() => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );

  Widget _buildErrorWidget() => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.error_outline,
            color: Colors.grey,
            size: 32,
          ),
        ),
      );
}

/// Оптимизированный виджет для аватаров пользователей
class OptimizedAvatar extends StatelessWidget {
  const OptimizedAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[300],
        child: ClipOval(
          child: OptimizedImage(
            imageUrl: imageUrl,
            width: radius * 2,
            height: radius * 2,
            memCacheWidth: (radius * 2).toInt(),
            memCacheHeight: (radius * 2).toInt(),
            placeholder: placeholder,
            errorWidget: errorWidget,
          ),
        ),
      );
}

/// Оптимизированный виджет для изображений в списках
class OptimizedListImage extends StatelessWidget {
  const OptimizedListImage({
    super.key,
    required this.imageUrl,
    this.width = 80,
    this.height = 80,
    this.fit = BoxFit.cover,
    this.borderRadius = 8,
  });

  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: OptimizedImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: fit,
          memCacheWidth: width.toInt(),
          memCacheHeight: height.toInt(),
        ),
      );
}
