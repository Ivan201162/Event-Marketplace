import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Сервис для оптимизации изображений
class ImageOptimizationService {
  static const int _maxImageWidth = 1920;
  static const int _maxImageHeight = 1080;
  static const int _thumbnailWidth = 300;
  static const int _thumbnailHeight = 300;
  static const int _quality = 85;

  /// Сжать изображение
  static Future<Uint8List> compressImage(
    Uint8List imageBytes, {
    int? maxWidth,
    int? maxHeight,
    int quality = _quality,
  }) async {
    try {
      // Декодируем изображение
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Не удалось декодировать изображение');
      }

      // Вычисляем новые размеры
      var newWidth = image.width;
      var newHeight = image.height;

      if (maxWidth != null && image.width > maxWidth) {
        newWidth = maxWidth;
        newHeight = (image.height * maxWidth / image.width).round();
      }

      if (maxHeight != null && newHeight > maxHeight) {
        newHeight = maxHeight;
        newWidth = (newWidth * maxHeight / newHeight).round();
      }

      // Изменяем размер изображения
      final resizedImage = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.cubic,
      );

      // Кодируем в JPEG с заданным качеством
      final compressedBytes = img.encodeJpg(resizedImage, quality: quality);

      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      debugPrint('Ошибка сжатия изображения: $e');
      return imageBytes; // Возвращаем оригинал в случае ошибки
    }
  }

  /// Создать миниатюру
  static Future<Uint8List> createThumbnail(
    Uint8List imageBytes, {
    int width = _thumbnailWidth,
    int height = _thumbnailHeight,
  }) async =>
      compressImage(
        imageBytes,
        maxWidth: width,
        maxHeight: height,
        quality: 80,
      );

  /// Получить размер изображения
  static Future<Size> getImageSize(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return const Size(0, 0);
      }
      return Size(image.width.toDouble(), image.height.toDouble());
    } catch (e) {
      debugPrint('Ошибка получения размера изображения: $e');
      return const Size(0, 0);
    }
  }

  /// Сохранить изображение локально
  static Future<String> saveImageLocally(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(directory.path, 'images'));

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final file = File(path.join(imagesDir.path, fileName));
      await file.writeAsBytes(imageBytes);

      return file.path;
    } catch (e) {
      debugPrint('Ошибка сохранения изображения: $e');
      rethrow;
    }
  }

  /// Загрузить изображение из локального хранилища
  static Future<Uint8List?> loadImageLocally(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка загрузки изображения: $e');
      return null;
    }
  }

  /// Удалить изображение из локального хранилища
  static Future<void> deleteImageLocally(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Ошибка удаления изображения: $e');
    }
  }

  /// Очистить кэш изображений
  static Future<void> clearImageCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(directory.path, 'images'));

      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Ошибка очистки кэша изображений: $e');
    }
  }

  /// Получить размер кэша изображений
  static Future<int> getImageCacheSize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(directory.path, 'images'));

      if (!await imagesDir.exists()) {
        return 0;
      }

      var totalSize = 0;
      await for (final entity in imagesDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Ошибка получения размера кэша: $e');
      return 0;
    }
  }

  /// Форматировать размер в читаемый вид
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Виджет для оптимизированного отображения изображений
class OptimizedImage extends StatefulWidget {
  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.enableCaching = true,
    this.enableCompression = true,
    this.maxWidth,
    this.maxHeight,
    this.quality = 85,
  });
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableCaching;
  final bool enableCompression;
  final int? maxWidth;
  final int? maxHeight;
  final int quality;

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(OptimizedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Проверяем кэш
      if (widget.enableCaching) {
        final cachedImage = await _getCachedImage();
        if (cachedImage != null) {
          if (mounted) {
            setState(() {
              _imageBytes = cachedImage;
              _isLoading = false;
            });
          }
          return;
        }
      }

      // Загружаем изображение
      final imageBytes = await _loadImageFromUrl();

      if (imageBytes != null && mounted) {
        // Сжимаем изображение если нужно
        var finalBytes = imageBytes;
        if (widget.enableCompression) {
          finalBytes = await ImageOptimizationService.compressImage(
            imageBytes,
            maxWidth: widget.maxWidth,
            maxHeight: widget.maxHeight,
            quality: widget.quality,
          );
        }

        // Сохраняем в кэш
        if (widget.enableCaching) {
          await _cacheImage(finalBytes);
        }

        setState(() {
          _imageBytes = finalBytes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки изображения: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<Uint8List?> _getCachedImage() async {
    try {
      final fileName = _getCacheFileName();
      return await ImageOptimizationService.loadImageLocally(fileName);
    } catch (e) {
      debugPrint('Ошибка получения кэшированного изображения: $e');
      return null;
    }
  }

  Future<void> _cacheImage(Uint8List imageBytes) async {
    try {
      final fileName = _getCacheFileName();
      await ImageOptimizationService.saveImageLocally(imageBytes, fileName);
    } catch (e) {
      debugPrint('Ошибка кэширования изображения: $e');
    }
  }

  String _getCacheFileName() {
    final uri = Uri.parse(widget.imageUrl);
    final fileName = path.basename(uri.path);
    final hash = widget.imageUrl.hashCode.toString();
    return '${hash}_$fileName';
  }

  Future<Uint8List?> _loadImageFromUrl() async {
    try {
      final uri = Uri.parse(widget.imageUrl);
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        return bytes;
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка загрузки изображения по URL: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
    }

    if (_hasError) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.error),
            ),
          );
    }

    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }

    return const SizedBox.shrink();
  }
}

/// Виджет для отображения миниатюр
class ThumbnailImage extends StatelessWidget {
  const ThumbnailImage({
    super.key,
    required this.imageUrl,
    this.size = 100,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });
  final String imageUrl;
  final double size;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) => OptimizedImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: fit,
        maxWidth: 300,
        maxHeight: 300,
        quality: 80,
        placeholder: placeholder ??
            Container(
              width: size,
              height: size,
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        errorWidget: errorWidget ??
            Container(
              width: size,
              height: size,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.error),
              ),
            ),
      );
}

/// Виджет для отображения изображений в сетке с lazy loading
class LazyImageGrid extends StatefulWidget {
  const LazyImageGrid({
    super.key,
    required this.imageUrls,
    this.crossAxisCount = 3,
    this.crossAxisSpacing = 8,
    this.mainAxisSpacing = 8,
    this.childAspectRatio = 1.0,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.onImageTap,
    this.enableCaching = true,
    this.enableCompression = true,
  });
  final List<String> imageUrls;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final VoidCallback? onImageTap;
  final bool enableCaching;
  final bool enableCompression;

  @override
  State<LazyImageGrid> createState() => _LazyImageGridState();
}

class _LazyImageGridState extends State<LazyImageGrid> {
  final ScrollController _scrollController = ScrollController();
  final Set<int> _visibleIndices = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Определяем видимые элементы
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;

    // Вычисляем индексы видимых элементов
    final visibleIndices = <int>{};
    for (var i = 0; i < widget.imageUrls.length; i++) {
      // Упрощенная логика определения видимости
      if (i >= (offset / 100).floor() && i <= ((offset + viewportHeight) / 100).ceil()) {
        visibleIndices.add(i);
      }
    }

    if (visibleIndices != _visibleIndices) {
      setState(() {
        _visibleIndices.clear();
        _visibleIndices.addAll(visibleIndices);
      });
    }
  }

  @override
  Widget build(BuildContext context) => GridView.builder(
        controller: _scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          crossAxisSpacing: widget.crossAxisSpacing,
          mainAxisSpacing: widget.mainAxisSpacing,
          childAspectRatio: widget.childAspectRatio,
        ),
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          final isVisible = _visibleIndices.contains(index);

          return GestureDetector(
            onTap: widget.onImageTap,
            child: isVisible
                ? OptimizedImage(
                    imageUrl: widget.imageUrls[index],
                    fit: widget.fit,
                    enableCaching: widget.enableCaching,
                    enableCompression: widget.enableCompression,
                    placeholder: widget.placeholder,
                    errorWidget: widget.errorWidget,
                  )
                : Container(
                    color: Colors.grey[300],
                    child: widget.placeholder,
                  ),
          );
        },
      );
}
