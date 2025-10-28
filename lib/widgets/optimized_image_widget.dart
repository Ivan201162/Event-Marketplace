import 'package:cached_network_image/cached_network_image.dart';
import 'package:event_marketplace_app/widgets/profile_image_placeholder.dart';
import 'package:flutter/material.dart';

/// Оптимизированный виджет для загрузки изображений с кэшированием
class OptimizedImage extends StatelessWidget {
  const OptimizedImage({
    required this.imageUrl, super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.border,
    this.shadow,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeOutDuration = const Duration(milliseconds: 100),
    this.memCacheWidth,
    this.memCacheHeight,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? shadow;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: maxWidthDiskCache,
      maxHeightDiskCache: maxHeightDiskCache,
      placeholder: (context, url) =>
          placeholder ?? _buildDefaultPlaceholder(theme),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildDefaultErrorWidget(theme),
      imageBuilder: (context, imageProvider) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: border,
          boxShadow: shadow,
          image: DecorationImage(image: imageProvider, fit: fit),
        ),
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildDefaultPlaceholder(ThemeData theme) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius,
          border: border,
        ),
        child: Center(
          child: SizedBox(
            width: (width ?? 100) * 0.3,
            height: (height ?? 100) * 0.3,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
        ),
      );

  Widget _buildDefaultErrorWidget(ThemeData theme) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: borderRadius,
          border: border,
        ),
        child: Center(
          child: Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
            size: (width ?? 100) * 0.3,
          ),
        ),
      );
}

/// Оптимизированный аватар с кэшированием
class OptimizedAvatar extends StatelessWidget {
  const OptimizedAvatar({
    required this.imageUrl, super.key,
    this.name,
    this.size = 60,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.border,
    this.showBorder = true,
    this.onTap,
    this.status,
  });

  final String imageUrl;
  final String? name;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final bool showBorder;
  final VoidCallback? onTap;
  final AvatarStatus? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(size / 2);

    Widget avatarWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      imageBuilder: (context, imageProvider) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius,
          border: showBorder
              ? (border ??
                  Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),))
              : null,
          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
        ),
      ),
      placeholder: (context, url) => ProfileImagePlaceholder(
        size: size,
        name: name,
        backgroundColor: backgroundColor,
        textColor: textColor,
        borderRadius: effectiveBorderRadius,
        border: border,
        showBorder: showBorder,
      ),
      errorWidget: (context, url, error) => ProfileImagePlaceholder(
        size: size,
        name: name,
        backgroundColor: backgroundColor,
        textColor: textColor,
        borderRadius: effectiveBorderRadius,
        border: border,
        showBorder: showBorder,
      ),
    );

    if (status != null) {
      avatarWidget = StatusAvatar(
        imageUrl: imageUrl,
        name: name,
        size: size,
        status: status!,
        backgroundColor: backgroundColor,
        textColor: textColor,
        borderRadius: borderRadius,
        border: border,
        showBorder: showBorder,
        onTap: onTap,
      );
    } else if (onTap != null) {
      avatarWidget = GestureDetector(onTap: onTap, child: avatarWidget);
    }

    return avatarWidget;
  }
}

/// Оптимизированная галерея изображений
class OptimizedImageGallery extends StatelessWidget {
  const OptimizedImageGallery({
    required this.imageUrls, super.key,
    this.crossAxisCount = 3,
    this.crossAxisSpacing = 4,
    this.mainAxisSpacing = 4,
    this.aspectRatio = 1.0,
    this.borderRadius,
    this.onImageTap,
    this.maxImages = 9,
    this.showMoreIndicator = true,
  });

  final List<String> imageUrls;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double aspectRatio;
  final BorderRadius? borderRadius;
  final Function(String imageUrl, int index)? onImageTap;
  final int maxImages;
  final bool showMoreIndicator;

  @override
  Widget build(BuildContext context) {
    final displayImages = imageUrls.take(maxImages).toList();
    final remainingCount = imageUrls.length - maxImages;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: displayImages.length +
          (showMoreIndicator && remainingCount > 0 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < displayImages.length) {
          return _buildImageItem(context, displayImages[index], index);
        } else {
          return _buildMoreIndicator(context, remainingCount);
        }
      },
    );
  }

  Widget _buildImageItem(BuildContext context, String imageUrl, int index) =>
      GestureDetector(
        onTap: () => onImageTap?.call(imageUrl, index),
        child: OptimizedImage(
          imageUrl: imageUrl,
          borderRadius: borderRadius,
          fadeInDuration: const Duration(milliseconds: 200),
        ),
      );

  Widget _buildMoreIndicator(BuildContext context, int remainingCount) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.more_horiz,
                color: theme.colorScheme.onSurfaceVariant, size: 24,),
            Text(
              '+$remainingCount',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Оптимизированный виджет для отображения изображения с ленивой загрузкой
class LazyImage extends StatefulWidget {
  const LazyImage({
    required this.imageUrl, super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.border,
    this.shadow,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.intersectionThreshold = 0.1,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? shadow;
  final Duration fadeInDuration;
  final double intersectionThreshold;

  @override
  State<LazyImage> createState() => _LazyImageState();
}

class _LazyImageState extends State<LazyImage> {
  bool _isVisible = false;
  late final IntersectionObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = IntersectionObserver(
      threshold: widget.intersectionThreshold,
      callback: (entries) {
        if (entries.isNotEmpty && entries.first.isIntersecting) {
          setState(() {
            _isVisible = true;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _observer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VisibilityDetector(
        key: Key(widget.imageUrl),
        onVisibilityChanged: (visibilityInfo) {
          if (visibilityInfo.visibleFraction > widget.intersectionThreshold) {
            setState(() {
              _isVisible = true;
            });
          }
        },
        child: _isVisible
            ? OptimizedImage(
                imageUrl: widget.imageUrl,
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
                placeholder: widget.placeholder,
                errorWidget: widget.errorWidget,
                borderRadius: widget.borderRadius,
                border: widget.border,
                shadow: widget.shadow,
                fadeInDuration: widget.fadeInDuration,
              )
            : widget.placeholder ?? _buildDefaultPlaceholder(),
      );

  Widget _buildDefaultPlaceholder() => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: widget.borderRadius,
          border: widget.border,
        ),
      );
}

/// Простой IntersectionObserver для Flutter
class IntersectionObserver {
  IntersectionObserver({required this.threshold, required this.callback});
  final double threshold;
  final Function(List<IntersectionObserverEntry>) callback;

  void dispose() {
    // Cleanup if needed
  }
}

class IntersectionObserverEntry {
  IntersectionObserverEntry(
      {required this.isIntersecting, required this.intersectionRatio,});
  final bool isIntersecting;
  final double intersectionRatio;
}

/// Простой VisibilityDetector для Flutter
class VisibilityDetector extends StatefulWidget {
  const VisibilityDetector(
      {required this.onVisibilityChanged, required this.child, super.key,});
  final Function(VisibilityInfo) onVisibilityChanged;
  final Widget child;

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  Widget build(BuildContext context) => widget.child;
}

class VisibilityInfo {
  VisibilityInfo({required this.visibleFraction});
  final double visibleFraction;
}
