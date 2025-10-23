import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shimmer/shimmer.dart';

/// Оптимизированный виджет для кэшированных изображений с предзагрузкой
class OptimizedCachedImageWidget extends StatefulWidget {
  const OptimizedCachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.enablePreload = true,
    this.cacheManager,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final bool enablePreload;
  final CacheManager? cacheManager;

  @override
  State<OptimizedCachedImageWidget> createState() =>
      _OptimizedCachedImageWidgetState();
}

class _OptimizedCachedImageWidgetState extends State<OptimizedCachedImageWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.enablePreload) {
      _preloadImage();
    }
  }

  Future<void> _preloadImage() async {
    try {
      await precacheImage(
        CachedNetworkImageProvider(widget.imageUrl,
            cacheManager: widget.cacheManager),
        context,
      );
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Widget _buildShimmerPlaceholder() => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: widget.borderRadius),
        ),
      );

  Widget _buildErrorWidget() => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
            color: Colors.grey[200], borderRadius: widget.borderRadius),
        child: Icon(
          Icons.error_outline,
          color: Colors.grey[400],
          size: (widget.width != null && widget.height != null)
              ? (widget.width! < widget.height!
                  ? widget.width! * 0.3
                  : widget.height! * 0.3)
              : 24,
        ),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.imageUrl.isEmpty) {
      return _buildErrorWidget();
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheManager: widget.cacheManager,
      placeholder: (context, url) =>
          widget.placeholder ?? _buildShimmerPlaceholder(),
      errorWidget: (context, url, error) =>
          widget.errorWidget ?? _buildErrorWidget(),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      memCacheWidth: widget.width?.toInt(),
      memCacheHeight: widget.height?.toInt(),
    );

    if (widget.borderRadius != null) {
      imageWidget =
          ClipRRect(borderRadius: widget.borderRadius!, child: imageWidget);
    }

    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300), child: imageWidget);
  }
}

/// Виджет для аватара с кэшированием
class CachedAvatarWidget extends StatelessWidget {
  const CachedAvatarWidget({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.borderColor,
    this.borderWidth = 2,
    this.placeholder,
  });

  final String imageUrl;
  final double radius;
  final Color? borderColor;
  final double borderWidth;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: borderColor != null
              ? Border.all(color: borderColor!, width: borderWidth)
              : null,
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[200],
          child: imageUrl.isNotEmpty
              ? OptimizedCachedImageWidget(
                  imageUrl: imageUrl,
                  width: radius * 2,
                  height: radius * 2,
                  borderRadius: BorderRadius.circular(radius),
                  placeholder: placeholder ??
                      Icon(Icons.person, size: radius, color: Colors.grey[400]),
                )
              : placeholder ??
                  Icon(Icons.person, size: radius, color: Colors.grey[400]),
        ),
      );
}

/// Виджет для карточки изображения с кэшированием
class CachedImageCard extends StatelessWidget {
  const CachedImageCard({
    super.key,
    required this.imageUrl,
    this.width,
    this.height = 200,
    this.borderRadius = 12,
    this.onTap,
    this.child,
  });

  final String imageUrl;
  final double? width;
  final double height;
  final double borderRadius;
  final VoidCallback? onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              children: [
                OptimizedCachedImageWidget(
                  imageUrl: imageUrl,
                  width: width,
                  height: height,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                if (child != null) Positioned.fill(child: child!),
              ],
            ),
          ),
        ),
      );
}

/// Виджет для сетки изображений с кэшированием
class CachedImageGrid extends StatelessWidget {
  const CachedImageGrid({
    super.key,
    required this.imageUrls,
    this.crossAxisCount = 3,
    this.crossAxisSpacing = 4,
    this.mainAxisSpacing = 4,
    this.aspectRatio = 1,
    this.onImageTap,
  });

  final List<String> imageUrls;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double aspectRatio;
  final Function(String imageUrl, int index)? onImageTap;

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: aspectRatio,
        ),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          final imageUrl = imageUrls[index];
          return GestureDetector(
            onTap: () => onImageTap?.call(imageUrl, index),
            child: OptimizedCachedImageWidget(
              imageUrl: imageUrl,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
      );
}
