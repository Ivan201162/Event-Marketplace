import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/message.dart';

class FilePreview extends StatelessWidget {
  final Message message;

  const FilePreview({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(message.fileName ?? 'Файл'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadFile(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareFile(context),
          ),
        ],
      ),
      body: Center(
        child: _buildPreview(context, theme),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, ThemeData theme) {
    switch (message.type) {
      case MessageType.image:
        return _buildImagePreview(context, theme);
      case MessageType.video:
        return _buildVideoPreview(context, theme);
      case MessageType.file:
        return _buildFilePreview(context, theme);
      default:
        return _buildUnsupportedPreview(context, theme);
    }
  }

  Widget _buildImagePreview(BuildContext context, ThemeData theme) {
    return InteractiveViewer(
      child: Image.network(
        message.fileUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPreview(context, theme, 'Ошибка загрузки изображения');
        },
      ),
    );
  }

  Widget _buildVideoPreview(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_filled,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  'Нажмите для воспроизведения',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '🎥 Видео',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileIcon(message.fileType ?? ''),
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            message.fileName ?? 'Файл',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (message.fileSize != null)
            Text(
              message.fileSizeFormatted,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _downloadFile(context),
            icon: const Icon(Icons.download),
            label: const Text('Скачать файл'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openFile(context),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Открыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedPreview(BuildContext context, ThemeData theme) {
    return _buildErrorPreview(context, theme, 'Предпросмотр не поддерживается');
  }

  Widget _buildErrorPreview(BuildContext context, ThemeData theme, String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _downloadFile(context),
            icon: const Icon(Icons.download),
            label: const Text('Скачать файл'),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    if (fileType.contains('pdf')) return Icons.picture_as_pdf;
    if (fileType.contains('word') || fileType.contains('doc')) return Icons.description;
    if (fileType.contains('excel') || fileType.contains('sheet')) return Icons.table_chart;
    if (fileType.contains('powerpoint') || fileType.contains('presentation')) return Icons.slideshow;
    if (fileType.contains('image')) return Icons.image;
    if (fileType.contains('video')) return Icons.video_file;
    if (fileType.contains('audio')) return Icons.audio_file;
    if (fileType.contains('zip') || fileType.contains('rar')) return Icons.archive;
    return Icons.attach_file;
  }

  void _downloadFile(BuildContext context) {
    // Implement file download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Загрузка файла...')),
    );
  }

  void _shareFile(BuildContext context) {
    // Implement file sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Поделиться файлом...')),
    );
  }

  void _openFile(BuildContext context) async {
    if (message.fileUrl != null) {
      final uri = Uri.parse(message.fileUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть файл')),
        );
      }
    }
  }
}
