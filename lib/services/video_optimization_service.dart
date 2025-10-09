import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Сервис для оптимизации видео
class VideoOptimizationService {
  static const int _maxVideoSize = 100 * 1024 * 1024; // 100 MB
  static const int _thumbnailWidth = 320;
  static const int _thumbnailHeight = 240;

  /// Получить информацию о видео
  static Future<VideoInfo?> getVideoInfo(String videoPath) async {
    try {
      final file = File(videoPath);
      if (!await file.exists()) {
        return null;
      }

      final fileSize = await file.length();
      final fileName = path.basename(videoPath);
      final fileExtension = path.extension(videoPath).toLowerCase();

      return VideoInfo(
        path: videoPath,
        fileName: fileName,
        fileSize: fileSize,
        duration:
            const Duration(), // TODO(developer): Получить реальную длительность
        format: fileExtension,
        resolution: const Size(
          1920,
          1080,
        ), // TODO(developer): Получить реальное разрешение
      );
    } on Exception catch (e) {
      debugPrint('Ошибка получения информации о видео: $e');
      return null;
    }
  }

  /// Сжать видео
  static Future<String?> compressVideo(
    String inputPath,
    String outputPath, {
    int? maxWidth,
    int? maxHeight,
    int? bitrate,
    int? frameRate,
  }) async {
    try {
      // TODO(developer): Реализовать сжатие видео с помощью FFmpeg
      // Пока просто копируем файл
      final inputFile = File(inputPath);
      final outputFile = File(outputPath);

      await inputFile.copy(outputPath);

      return outputPath;
    } on Exception catch (e) {
      debugPrint('Ошибка сжатия видео: $e');
      return null;
    }
  }

  /// Создать миниатюру видео
  static Future<Uint8List?> createVideoThumbnail(
    String videoPath, {
    int width = _thumbnailWidth,
    int height = _thumbnailHeight,
    Duration? timeOffset,
  }) async {
    try {
      // TODO(developer): Реализовать создание миниатюры с помощью FFmpeg
      // Пока возвращаем заглушку
      return _createPlaceholderThumbnail(width, height);
    } on Exception catch (e) {
      debugPrint('Ошибка создания миниатюры видео: $e');
      return null;
    }
  }

  /// Создать заглушку для миниатюры
  static Uint8List _createPlaceholderThumbnail(int width, int height) {
    // Создаем простое изображение-заглушку
    final image = List.generate(
      width * height * 4,
      (index) => (index % 4 == 3) ? 255 : 100, // RGBA
    );
    return Uint8List.fromList(image);
  }

  /// Сохранить видео локально
  static Future<String> saveVideoLocally(
    Uint8List videoBytes,
    String fileName,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videosDir = Directory(path.join(directory.path, 'videos'));

      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }

      final file = File(path.join(videosDir.path, fileName));
      await file.writeAsBytes(videoBytes);

      return file.path;
    } on Exception catch (e) {
      debugPrint('Ошибка сохранения видео: $e');
      rethrow;
    }
  }

  /// Загрузить видео из локального хранилища
  static Future<Uint8List?> loadVideoLocally(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } on Exception catch (e) {
      debugPrint('Ошибка загрузки видео: $e');
      return null;
    }
  }

  /// Удалить видео из локального хранилища
  static Future<void> deleteVideoLocally(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } on Exception catch (e) {
      debugPrint('Ошибка удаления видео: $e');
    }
  }

  /// Очистить кэш видео
  static Future<void> clearVideoCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videosDir = Directory(path.join(directory.path, 'videos'));

      if (await videosDir.exists()) {
        await videosDir.delete(recursive: true);
      }
    } on Exception catch (e) {
      debugPrint('Ошибка очистки кэша видео: $e');
    }
  }

  /// Получить размер кэша видео
  static Future<int> getVideoCacheSize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videosDir = Directory(path.join(directory.path, 'videos'));

      if (!await videosDir.exists()) {
        return 0;
      }

      var totalSize = 0;
      await for (final entity in videosDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } on Exception catch (e) {
      debugPrint('Ошибка получения размера кэша видео: $e');
      return 0;
    }
  }

  /// Проверить, поддерживается ли формат видео
  static bool isSupportedFormat(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    const supportedFormats = ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm'];
    return supportedFormats.contains(extension);
  }

  /// Получить рекомендуемые настройки сжатия
  static CompressionSettings getRecommendedSettings(VideoInfo videoInfo) {
    if (videoInfo.fileSize > 50 * 1024 * 1024) {
      // > 50 MB
      return const CompressionSettings(
        maxWidth: 1280,
        maxHeight: 720,
        bitrate: 2000000, // 2 Mbps
        frameRate: 30,
      );
    } else if (videoInfo.fileSize > 20 * 1024 * 1024) {
      // > 20 MB
      return const CompressionSettings(
        maxWidth: 1920,
        maxHeight: 1080,
        bitrate: 4000000, // 4 Mbps
        frameRate: 30,
      );
    } else {
      return const CompressionSettings(
        maxWidth: 1920,
        maxHeight: 1080,
        bitrate: 8000000, // 8 Mbps
        frameRate: 60,
      );
    }
  }
}

/// Информация о видео
class VideoInfo {
  const VideoInfo({
    required this.path,
    required this.fileName,
    required this.fileSize,
    required this.duration,
    required this.format,
    required this.resolution,
  });
  final String path;
  final String fileName;
  final int fileSize;
  final Duration duration;
  final String format;
  final Size resolution;

  /// Получить размер файла в читаемом виде
  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Получить длительность в читаемом виде
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Получить разрешение в читаемом виде
  String get formattedResolution =>
      '${resolution.width.toInt()}x${resolution.height.toInt()}';
}

/// Настройки сжатия видео
class CompressionSettings {
  const CompressionSettings({
    this.maxWidth,
    this.maxHeight,
    this.bitrate,
    this.frameRate,
  });
  final int? maxWidth;
  final int? maxHeight;
  final int? bitrate;
  final int? frameRate;
}

/// Виджет для отображения видео с оптимизацией
class OptimizedVideoPlayer extends StatefulWidget {
  const OptimizedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.width,
    this.height,
    this.autoPlay = false,
    this.showControls = true,
    this.placeholder,
    this.errorWidget,
    this.enableCaching = true,
    this.enableCompression = true,
    this.onTap,
  });
  final String videoUrl;
  final double? width;
  final double? height;
  final bool autoPlay;
  final bool showControls;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableCaching;
  final bool enableCompression;
  final VoidCallback? onTap;

  @override
  State<OptimizedVideoPlayer> createState() => _OptimizedVideoPlayerState();
}

class _OptimizedVideoPlayerState extends State<OptimizedVideoPlayer> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _localVideoPath;
  Uint8List? _thumbnail;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void didUpdateWidget(OptimizedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _loadVideo();
    }
  }

  Future<void> _loadVideo() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Проверяем кэш
      if (widget.enableCaching) {
        final cachedVideo = await _getCachedVideo();
        if (cachedVideo != null) {
          if (mounted) {
            setState(() {
              _localVideoPath = cachedVideo;
              _isLoading = false;
            });
          }
          return;
        }
      }

      // Загружаем видео
      final videoBytes = await _loadVideoFromUrl();

      if (videoBytes != null && mounted) {
        // Сохраняем в кэш
        if (widget.enableCaching) {
          final fileName = _getCacheFileName();
          _localVideoPath = await VideoOptimizationService.saveVideoLocally(
            videoBytes,
            fileName,
          );
        }

        // Создаем миниатюру
        if (_localVideoPath != null) {
          _thumbnail = await VideoOptimizationService.createVideoThumbnail(
            _localVideoPath!,
          );
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      debugPrint('Ошибка загрузки видео: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _getCachedVideo() async {
    try {
      final fileName = _getCacheFileName();
      final directory = await getApplicationDocumentsDirectory();
      final videoPath = path.join(directory.path, 'videos', fileName);

      final file = File(videoPath);
      if (await file.exists()) {
        return videoPath;
      }
      return null;
    } on Exception catch (e) {
      debugPrint('Ошибка получения кэшированного видео: $e');
      return null;
    }
  }

  String _getCacheFileName() {
    final uri = Uri.parse(widget.videoUrl);
    final fileName = path.basename(uri.path);
    final hash = widget.videoUrl.hashCode.toString();
    return '${hash}_$fileName';
  }

  Future<Uint8List?> _loadVideoFromUrl() async {
    try {
      final uri = Uri.parse(widget.videoUrl);
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        return bytes;
      }
      return null;
    } on Exception catch (e) {
      debugPrint('Ошибка загрузки видео по URL: $e');
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

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Миниатюра или видео
            if (_thumbnail != null)
              Image.memory(
                _thumbnail!,
                width: widget.width,
                height: widget.height,
                fit: BoxFit.cover,
              )
            else
              Container(
                width: widget.width,
                height: widget.height,
                color: Colors.grey[800],
                child: const Center(
                  child: Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            // Кнопка воспроизведения
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            // Индикатор видео
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Видео',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Виджет для отображения миниатюр видео
class VideoThumbnail extends StatelessWidget {
  const VideoThumbnail({
    super.key,
    required this.videoUrl,
    this.size = 100,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.onTap,
  });
  final String videoUrl;
  final double size;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => OptimizedVideoPlayer(
        videoUrl: videoUrl,
        width: size,
        height: size,
        fit: fit,
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
        onTap: onTap,
      );
}
