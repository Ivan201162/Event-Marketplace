import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Оптимизированный виджет для кэшированных изображений с улучшенной производительностью
class OptimizedCachedImage extends StatefulWidget {
  const OptimizedCachedImage({
    required this.imageUrl, super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.placeholderColor,
    this.errorColor,
    this.fadeInDuration = const Duration(milliseconds: 200),
    this.fadeOutDuration = const Duration(milliseconds: 100),
    this.memCacheWidth,
    this.memCacheHeight,
    this.maxWidthDiskCache = 1000,
    this.maxHeightDiskCache = 1000,
    this.useOldImageOnUrlChange = true,
    this.enableMemoryOptimization = true,
    this.enableDiskCache = true,
    this.cacheKey,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? placeholderColor;
  final Color? errorColor;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int maxWidthDiskCache;
  final int maxHeightDiskCache;
  final bool useOldImageOnUrlChange;
  final bool enableMemoryOptimization;
  final bool enableDiskCache;
  final String? cacheKey;

  @override
  State<OptimizedCachedImage> createState() => _OptimizedCachedImageState();
}

class _OptimizedCachedImageState extends State<OptimizedCachedImage>
    with AutomaticKeepAliveClientMixin {
  late String _effectiveImageUrl;

  @override
  bool get wantKeepAlive => widget.enableMemoryOptimization;

  @override
  void initState() {
    super.initState();
    _effectiveImageUrl = widget.imageUrl;
    _preloadImage();
  }

  @override
  void didUpdateWidget(OptimizedCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _effectiveImageUrl = widget.imageUrl;
      _preloadImage();
    }
  }

  void _preloadImage() {
    if (widget.enableMemoryOptimization) {
      // Предзагрузка изображения в кэш
      precacheImage(CachedNetworkImageProvider(_effectiveImageUrl), context)
          .then((_) {
        if (mounted) {
          setState(() {});
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);

    Widget imageWidget = CachedNetworkImage(
      imageUrl: _effectiveImageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      fadeInDuration: widget.fadeInDuration,
      fadeOutDuration: widget.fadeOutDuration,
      useOldImageOnUrlChange: widget.useOldImageOnUrlChange,
      memCacheWidth: widget.memCacheWidth,
      memCacheHeight: widget.memCacheHeight,
      maxWidthDiskCache:
          widget.enableDiskCache ? widget.maxWidthDiskCache : null,
      maxHeightDiskCache:
          widget.enableDiskCache ? widget.maxHeightDiskCache : null,
      cacheKey: widget.cacheKey,
      placeholder: (context, url) => _buildPlaceholder(theme),
      errorWidget: (context, url, error) => _buildErrorWidget(theme),
      imageBuilder: (context, imageProvider) =>
          _buildImageBuilder(imageProvider),
    );

    if (widget.borderRadius != null) {
      imageWidget =
          ClipRRect(borderRadius: widget.borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildPlaceholder(ThemeData theme) {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.placeholderColor ??
            theme.colorScheme.surfaceContainerHighest,
        borderRadius: widget.borderRadius,
      ),
      child: Center(
        child: SizedBox(
          width: (widget.width ?? 100) * 0.2,
          height: (widget.height ?? 100) * 0.2,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor:
                AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme) {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.errorColor ?? theme.colorScheme.errorContainer,
        borderRadius: widget.borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: theme.colorScheme.onErrorContainer,
          size: (widget.width ?? 100) * 0.3,
        ),
      ),
    );
  }

  Widget _buildImageBuilder(ImageProvider imageProvider) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          image: DecorationImage(image: imageProvider, fit: widget.fit),
        ),
      );
}

/// Специализированный виджет для аватаров с оптимизацией
class OptimizedAvatar extends StatelessWidget {
  const OptimizedAvatar({
    required this.imageUrl, super.key,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.child,
    this.onTap,
  });

  final String imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Widget? child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
      child: imageUrl.isNotEmpty
          ? ClipOval(
              child: OptimizedCachedImage(
                imageUrl: imageUrl,
                width: radius * 2,
                height: radius * 2,
                memCacheWidth: (radius * 2).toInt(),
                memCacheHeight: (radius * 2).toInt(),
                maxWidthDiskCache: (radius * 2).toInt(),
                maxHeightDiskCache: (radius * 2).toInt(),
              ),
            )
          : child ?? Icon(Icons.person, size: radius),
    );

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}

/// Специализированный виджет для карточек с изображениями
class OptimizedCardImage extends StatelessWidget {
  const OptimizedCardImage({
    required this.imageUrl, super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.elevation = 2,
    this.onTap,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final double elevation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget image = OptimizedCachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: 800,
      maxHeightDiskCache: 600,
    );

    if (elevation > 0) {
      image = Material(
          elevation: elevation, borderRadius: borderRadius, child: image,);
    }

    if (onTap != null) {
      image = GestureDetector(onTap: onTap, child: image);
    }

    return image;
  }
}
