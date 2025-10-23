import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Виджет для кэширования изображений с улучшенной производительностью
class CachedImageWidget extends StatelessWidget {
  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.placeholderColor,
    this.errorColor,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.useOldImageOnUrlChange = true,
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
  final bool useOldImageOnUrlChange;

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildErrorWidget(),
      fadeInDuration: fadeInDuration,
      useOldImageOnUrlChange: useOldImageOnUrlChange,
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildPlaceholder() {
    if (placeholder != null) return placeholder!;

    return Container(
      width: width,
      height: height,
      color: placeholderColor ?? Colors.grey[200],
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildErrorWidget() {
    if (errorWidget != null) return errorWidget!;

    return Container(
      width: width,
      height: height,
      color: errorColor ?? Colors.grey[300],
      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    );
  }
}

/// Адаптивный кэшированный аватар
class CachedAvatar extends StatelessWidget {
  const CachedAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.fallbackIcon,
  });
  final String? imageUrl;
  final String? name;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? theme.colorScheme.primary,
        child: CachedImageWidget(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          borderRadius: BorderRadius.circular(radius),
          placeholder: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              color: backgroundColor ?? theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          errorWidget: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              color: backgroundColor ?? theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              fallbackIcon ?? Icons.person,
              size: radius,
              color: foregroundColor ?? theme.colorScheme.onPrimary,
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
      child: name != null && name!.isNotEmpty
          ? Text(
              name![0].toUpperCase(),
              style: TextStyle(
                  fontSize: radius * 0.6, fontWeight: FontWeight.bold),
            )
          : Icon(fallbackIcon ?? Icons.person, size: radius),
    );
  }
}

/// Кэшированная сетка изображений
class CachedImageGrid extends StatelessWidget {
  const CachedImageGrid({
    super.key,
    required this.imageUrls,
    this.crossAxisCount = 3,
    this.spacing = 4,
    this.childAspectRatio = 1.0,
    this.onImageTap,
    this.maxImages,
    this.showMoreIndicator = true,
  });
  final List<String> imageUrls;
  final int crossAxisCount;
  final double spacing;
  final double childAspectRatio;
  final VoidCallback? onImageTap;
  final int? maxImages;
  final bool showMoreIndicator;

  @override
  Widget build(BuildContext context) {
    final displayImages = maxImages != null && imageUrls.length > maxImages!
        ? imageUrls.take(maxImages!).toList()
        : imageUrls;

    final hasMoreImages = maxImages != null && imageUrls.length > maxImages!;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount:
          displayImages.length + (hasMoreImages && showMoreIndicator ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasMoreImages &&
            showMoreIndicator &&
            index == displayImages.length) {
          return _buildMoreIndicator(context, imageUrls.length - maxImages!);
        }

        return _buildImageItem(context, displayImages[index], index);
      },
    );
  }

  Widget _buildImageItem(BuildContext context, String imageUrl, int index) =>
      GestureDetector(
        onTap: onImageTap,
        child: CachedImageWidget(
          imageUrl: imageUrl,
          borderRadius: BorderRadius.circular(8),
          placeholder: Container(
            color: Colors.grey[200],
            child:
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: Container(
            color: Colors.grey[300],
            child: const Center(
                child: Icon(Icons.broken_image, color: Colors.grey)),
          ),
        ),
      );

  Widget _buildMoreIndicator(BuildContext context, int remainingCount) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '+$remainingCount',
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
}

/// Кэшированный список изображений
class CachedImageList extends StatelessWidget {
  const CachedImageList({
    super.key,
    required this.imageUrls,
    this.height = 200,
    this.spacing = 8,
    this.onImageTap,
    this.showIndicators = true,
  });
  final List<String> imageUrls;
  final double height;
  final double spacing;
  final VoidCallback? onImageTap;
  final bool showIndicators;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: imageUrls.length,
          itemBuilder: (context, index) => Container(
            width: height,
            margin: EdgeInsets.only(
                right: index < imageUrls.length - 1 ? spacing : 0),
            child: GestureDetector(
              onTap: onImageTap,
              child: CachedImageWidget(
                imageUrl: imageUrls[index],
                width: height,
                height: height,
                borderRadius: BorderRadius.circular(8),
                placeholder: Container(
                  color: Colors.grey[200],
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: Container(
                  color: Colors.grey[300],
                  child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Кэшированное изображение с ленивой загрузкой
class LazyCachedImage extends StatefulWidget {
  const LazyCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;

  @override
  State<LazyCachedImage> createState() => _LazyCachedImageState();
}

class _LazyCachedImageState extends State<LazyCachedImage> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) => VisibilityDetector(
        key: Key(widget.imageUrl),
        onVisibilityChanged: (visibilityInfo) {
          if (visibilityInfo.visibleFraction > 0.1 && !_isVisible) {
            setState(() {
              _isVisible = true;
            });
          }
        },
        child: _isVisible
            ? CachedImageWidget(
                imageUrl: widget.imageUrl,
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
                borderRadius: widget.borderRadius,
                placeholder: widget.placeholder,
                errorWidget: widget.errorWidget,
                fadeInDuration: widget.fadeInDuration,
              )
            : Container(
                width: widget.width,
                height: widget.height,
                color: Colors.grey[200],
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
      );
}

/// Простой виджет для определения видимости (заглушка)
class VisibilityDetector extends StatefulWidget {
  const VisibilityDetector(
      {super.key, required this.child, required this.onVisibilityChanged});
  final Widget child;
  final Function(VisibilityInfo) onVisibilityChanged;

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  void initState() {
    super.initState();
    // Симулируем видимость через небольшую задержку
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        widget.onVisibilityChanged(VisibilityInfo(visibleFraction: 1));
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Информация о видимости виджета
class VisibilityInfo {
  VisibilityInfo({required this.visibleFraction});
  final double visibleFraction;
}
