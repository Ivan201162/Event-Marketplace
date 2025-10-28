import 'package:event_marketplace_app/services/media_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Виджет для просмотра медиафайлов мероприятия
class MediaGalleryWidget extends StatefulWidget {
  const MediaGalleryWidget({
    required this.bookingId, super.key,
    this.specialistId,
    this.showUploadButton = false,
    this.onUploadComplete,
  });

  final String bookingId;
  final String? specialistId;
  final bool showUploadButton;
  final VoidCallback? onUploadComplete;

  @override
  State<MediaGalleryWidget> createState() => _MediaGalleryWidgetState();
}

class _MediaGalleryWidgetState extends State<MediaGalleryWidget> {
  final MediaStorageService _mediaService = MediaStorageService();

  List<MediaFile> _mediaFiles = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadMediaFiles();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          if (_isLoading) _buildLoading(),
          if (_error != null) _buildError(),
          if (!_isLoading && _error == null) _buildContent(),
        ],
      );

  Widget _buildHeader() => Row(
        children: [
          const Icon(Icons.photo_library, color: Colors.blue),
          const SizedBox(width: 8),
          const Text(
            'Медиафайлы мероприятия',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (_mediaFiles.isNotEmpty)
            Text(
              '${_mediaFiles.length} файлов',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
        ],
      );

  Widget _buildLoading() => const Center(
        child: Padding(
            padding: EdgeInsets.all(32), child: CircularProgressIndicator(),),
      );

  Widget _buildError() => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(
              child:
                  Text(_error!, style: TextStyle(color: Colors.red.shade700)),
            ),
            TextButton(
                onPressed: _loadMediaFiles, child: const Text('Повторить'),),
          ],
        ),
      );

  Widget _buildContent() {
    if (_mediaFiles.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildCategoryFilter(),
        const SizedBox(height: 16),
        _buildMediaGrid(),
      ],
    );
  }

  Widget _buildEmptyState() => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.photo_library_outlined,
                size: 64, color: Colors.grey.shade400,),
            const SizedBox(height: 16),
            Text(
              'Медиафайлы не загружены',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,),
            ),
            const SizedBox(height: 8),
            Text(
              'Специалист еще не загрузил фото и видео с мероприятия',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildCategoryFilter() {
    final categories = _getCategories();
    if (categories.length <= 1) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryChip('Все', null),
          const SizedBox(width: 8),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildCategoryChip(category, category),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? category) {
    final isSelected = _selectedCategory == category;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
    );
  }

  Widget _buildMediaGrid() {
    final filteredFiles = _getFilteredFiles();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: filteredFiles.length,
      itemBuilder: (context, index) {
        final file = filteredFiles[index];
        return _buildMediaItem(file);
      },
    );
  }

  Widget _buildMediaItem(MediaFile file) => GestureDetector(
        onTap: () => _showMediaDetails(file),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (file.isImage)
                  Image.network(
                    file.downloadUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildErrorPlaceholder(),
                  )
                else if (file.isVideo)
                  _buildVideoThumbnail(file)
                else
                  _buildFileThumbnail(file),

                // Overlay с информацией о файле
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          file.fileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          file.formattedSize,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 8,),
                        ),
                      ],
                    ),
                  ),
                ),

                // Иконка типа файла
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      file.isImage
                          ? Icons.image
                          : file.isVideo
                              ? Icons.video_file
                              : Icons.insert_drive_file,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildVideoThumbnail(MediaFile file) => ColoredBox(
        color: Colors.grey.shade200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_filled,
                size: 48, color: Colors.grey.shade600,),
            const SizedBox(height: 8),
            Text('Видео',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),),
          ],
        ),
      );

  Widget _buildFileThumbnail(MediaFile file) => ColoredBox(
        color: Colors.grey.shade200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              file.isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
              size: 48,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              file.isPdf ? 'PDF' : 'Файл',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      );

  Widget _buildErrorPlaceholder() => ColoredBox(
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
      );

  // ========== МЕТОДЫ ==========

  Future<void> _loadMediaFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final files = await _mediaService.getEventMedia(widget.bookingId);
      setState(() {
        _mediaFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки медиафайлов: $e';
        _isLoading = false;
      });
    }
  }

  List<String> _getCategories() {
    final categories = <String>{};
    for (final file in _mediaFiles) {
      if (file.isImage) {
        categories.add('Фото');
      } else if (file.isVideo) {
        categories.add('Видео');
      } else {
        categories.add('Файлы');
      }
    }
    return categories.toList()..sort();
  }

  List<MediaFile> _getFilteredFiles() {
    if (_selectedCategory == null) return _mediaFiles;

    return _mediaFiles.where((file) {
      if (_selectedCategory == 'Фото') return file.isImage;
      if (_selectedCategory == 'Видео') return file.isVideo;
      if (_selectedCategory == 'Файлы') return !file.isImage && !file.isVideo;
      return true;
    }).toList();
  }

  void _showMediaDetails(MediaFile file) {
    showDialog<void>(
      context: context,
      builder: (context) => _MediaDetailsDialog(file: file),
    );
  }
}

/// Диалог с детальной информацией о медиафайле
class _MediaDetailsDialog extends StatelessWidget {
  const _MediaDetailsDialog({required this.file});

  final MediaFile file;

  @override
  Widget build(BuildContext context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Flexible(child: _buildContent()),
              _buildActions(context),
            ],
          ),
        ),
      );

  Widget _buildHeader(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Row(
          children: [
            Icon(
              file.isImage
                  ? Icons.image
                  : file.isVideo
                      ? Icons.video_file
                      : Icons.insert_drive_file,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                file.fileName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),),
          ],
        ),
      );

  Widget _buildContent() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (file.isImage) _buildImagePreview(),
            if (file.isVideo) _buildVideoPreview(),
            if (!file.isImage && !file.isVideo) _buildFilePreview(),
            const SizedBox(height: 16),
            _buildFileInfo(),
          ],
        ),
      );

  Widget _buildImagePreview() => Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            file.downloadUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image, size: 64, color: Colors.grey),),
          ),
        ),
      );

  Widget _buildVideoPreview() => Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_filled,
                size: 64, color: Colors.grey.shade600,),
            const SizedBox(height: 16),
            Text('Видео файл',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 18),),
          ],
        ),
      );

  Widget _buildFilePreview() => Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              file.isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
              size: 64,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              file.isPdf ? 'PDF документ' : 'Файл',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
            ),
          ],
        ),
      );

  Widget _buildFileInfo() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Размер:', file.formattedSize),
          _buildInfoRow('Тип:', file.mimeType),
          _buildInfoRow('Загружен:', _formatDate(file.uploadedAt)),
          if (file.description != null)
            _buildInfoRow('Описание:', file.description!),
        ],
      );

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold),),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  Widget _buildActions(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Закрыть'),),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _downloadFile(context),
              icon: const Icon(Icons.download),
              label: const Text('Скачать'),
            ),
          ],
        ),
      );

  String _formatDate(DateTime date) =>
      '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

  Future<void> _downloadFile(BuildContext context) async {
    try {
      final url = Uri.parse(file.downloadUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Не удалось открыть файл'),
                backgroundColor: Colors.red,),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка скачивания: $e'),
              backgroundColor: Colors.red,),
        );
      }
    }
  }
}
