import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Виджет для отображения изображений с placeholder и прогрессом загрузки
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.showProgressIndicator = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final bool showProgressIndicator;
  final Duration fadeInDuration;
  final int? memCacheWidth;
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: fit,
          memCacheWidth: memCacheWidth,
          memCacheHeight: memCacheHeight,
          placeholder: (context, url) => _buildPlaceholder(context),
          errorWidget: (context, url, error) => _buildErrorWidget(context),
          fadeInDuration: fadeInDuration,
          fadeOutDuration: const Duration(milliseconds: 100),
        ),
      );

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) {
      return placeholder!;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showProgressIndicator) ...[
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Icon(
            Icons.image_outlined,
            size: 32,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4),
          Text(
            'Загрузка...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (errorWidget != null) {
      return errorWidget!;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 32,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(height: 4),
          Text(
            'Ошибка загрузки',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения аватара с placeholder
class AvatarPlaceholder extends StatelessWidget {
  const AvatarPlaceholder({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.borderRadius,
  });

  final String? imageUrl;
  final String? name;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primary;
    final txtColor = textColor ?? theme.colorScheme.onPrimary;
    final radius = borderRadius ?? BorderRadius.circular(size / 2);

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: ImagePlaceholder(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          borderRadius: radius,
          placeholder: _buildInitialsPlaceholder(context, bgColor, txtColor),
          errorWidget: _buildInitialsPlaceholder(context, bgColor, txtColor),
        ),
      );
    }

    return _buildInitialsPlaceholder(context, bgColor, txtColor);
  }

  Widget _buildInitialsPlaceholder(
    BuildContext context,
    Color backgroundColor,
    Color textColor,
  ) {
    final initials = _getInitials(name);
    final radius = borderRadius ?? BorderRadius.circular(size / 2);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize ?? (size * 0.4),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) {
      return '?';
    }

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }

    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }
}

/// Виджет для отображения изображения с ленивой загрузкой
class LazyImage extends StatefulWidget {
  const LazyImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.placeholderColor,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Duration fadeInDuration;
  final Color? placeholderColor;

  @override
  State<LazyImage> createState() => _LazyImageState();
}

class _LazyImageState extends State<LazyImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.fadeInDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        child: Stack(
          children: [
            // Placeholder
            if (!_isLoaded && !_hasError)
              Container(
                width: widget.width,
                height: widget.height,
                color: widget.placeholderColor ??
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                child: widget.placeholder ??
                    Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
              ),

            // Error widget
            if (_hasError)
              Container(
                width: widget.width,
                height: widget.height,
                color: Theme.of(context).colorScheme.errorContainer,
                child: widget.errorWidget ??
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ошибка загрузки',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                          ),
                        ],
                      ),
                    ),
              ),

            // Image
            if (_isLoaded)
              FadeTransition(
                opacity: _animation,
                child: Image.network(
                  widget.imageUrl,
                  width: widget.width,
                  height: widget.height,
                  fit: widget.fit,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      _controller.forward();
                      return child;
                    }
                    return Container(
                      width: widget.width,
                      height: widget.height,
                      color: widget.placeholderColor ??
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    setState(() {
                      _hasError = true;
                    });
                    return const SizedBox.shrink();
                  },
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) {
                      setState(() {
                        _isLoaded = true;
                      });
                      _controller.forward();
                      return child;
                    }
                    if (frame != null) {
                      setState(() {
                        _isLoaded = true;
                      });
                      return child;
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
          ],
        ),
      );
}

/// Виджет для отображения сетки изображений с placeholder
class ImageGrid extends StatelessWidget {
  const ImageGrid({
    super.key,
    required this.imageUrls,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 8,
    this.mainAxisSpacing = 8,
    this.aspectRatio = 1.0,
    this.borderRadius,
    this.onImageTap,
  });

  final List<String> imageUrls;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double aspectRatio;
  final BorderRadius? borderRadius;
  final Function(String imageUrl)? onImageTap;

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
            onTap: () => onImageTap?.call(imageUrl),
            child: ImagePlaceholder(
              imageUrl: imageUrl,
              borderRadius: borderRadius ?? BorderRadius.circular(8),
            ),
          );
        },
      );
}
