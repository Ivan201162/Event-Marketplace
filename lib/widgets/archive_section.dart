import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_theme.dart';
import '../models/event_archive.dart';
import '../providers/archive_providers.dart';

/// Виджет секции архивов фото/видео
class ArchiveSection extends ConsumerStatefulWidget {
  const ArchiveSection(
      {super.key, required this.bookingId, required this.currentUserId});
  final String bookingId;
  final String currentUserId;

  @override
  ConsumerState<ArchiveSection> createState() => _ArchiveSectionState();
}

class _ArchiveSectionState extends ConsumerState<ArchiveSection> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _canUpload = false;

  @override
  void initState() {
    super.initState();
    _checkUploadPermission();
  }

  Future<void> _checkUploadPermission() async {
    try {
      // В реальном приложении здесь бы была проверка прав на загрузку
      // Пока что разрешаем загрузку всем
      setState(() => _canUpload = true);
    } catch (e) {
      setState(() => _canUpload = false);
    }
  }

  Future<void> _uploadArchive() async {
    try {
      // Показываем диалог выбора источника
      final source = await _showSourceDialog();
      if (source == null) return;

      if (source == ImageSource.gallery) {
        await ref
            .read(archiveUploadStateProvider.notifier)
            .uploadArchiveFromGallery(
              bookingId: widget.bookingId,
              uploadedBy: widget.currentUserId,
            );
      } else if (source == ImageSource.camera) {
        await ref
            .read(archiveUploadStateProvider.notifier)
            .uploadArchiveFromCamera(
                bookingId: widget.bookingId, uploadedBy: widget.currentUserId);
      }

      // Обновляем список архивов
      ref.refresh(bookingArchivesProvider(widget.bookingId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Архив успешно загружен'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
            content: Text('Ошибка загрузки: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<ImageSource?> _showSourceDialog() async => showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Выберите источник'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Галерея'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Камера'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      );

  Future<void> _deleteArchive(EventArchive archive) async {
    try {
      final confirmed = await _showDeleteConfirmation(archive);
      if (!confirmed) return;

      await ref
          .read(archiveUploadStateProvider.notifier)
          .deleteArchive(archive.id);

      // Обновляем список архивов
      ref.refresh(bookingArchivesProvider(widget.bookingId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Архив удален'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
            content: Text('Ошибка удаления: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<bool> _showDeleteConfirmation(EventArchive archive) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Удалить архив?'),
          content: Text(
              'Вы уверены, что хотите удалить "${archive.fileName ?? 'файл'}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Удалить'),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final archivesAsync = ref.watch(bookingArchivesProvider(widget.bookingId));
    final uploadState = ref.watch(archiveUploadStateProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с кнопкой загрузки
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Архив фото/видео',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_canUpload)
                  ElevatedButton.icon(
                    onPressed: uploadState.isUploading ? null : _uploadArchive,
                    icon: uploadState.isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload),
                    label: Text(
                        uploadState.isUploading ? 'Загрузка...' : 'Загрузить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Список архивов
            archivesAsync.when(
              data: (archives) {
                if (archives.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildArchivesList(archives);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorWidget(error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Архив пуст',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(
              'Загрузите фото и видео после завершения мероприятия',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildErrorWidget(Object error) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text('Ошибка загрузки',
                style: TextStyle(fontSize: 18, color: Colors.red.shade600)),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(fontSize: 14, color: Colors.red.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.refresh(bookingArchivesProvider(widget.bookingId)),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );

  Widget _buildArchivesList(List<EventArchive> archives) =>
      Column(children: archives.map(_buildArchiveItem).toList());

  Widget _buildArchiveItem(EventArchive archive) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: _buildArchiveIcon(archive),
          title: Text(archive.fileName ?? 'Файл',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(archive.formattedFileSize),
              if (archive.description != null &&
                  archive.description!.isNotEmpty)
                Text(archive.description!,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              Text(
                'Загружено: ${_formatDate(archive.uploadedAt)}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'download':
                  _downloadArchive(archive);
                  break;
                case 'delete':
                  _deleteArchive(archive);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'download',
                child: Row(children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Скачать')
                ]),
              ),
              if (_canUpload)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Удалить', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
          onTap: () => _showArchivePreview(archive),
        ),
      );

  Widget _buildArchiveIcon(EventArchive archive) {
    if (archive.isImage) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: archive.isImage
              ? DecorationImage(
                  image: NetworkImage(archive.fileUrl), fit: BoxFit.cover)
              : null,
          color: !archive.isImage ? Colors.grey.shade200 : null,
        ),
        child: !archive.isImage
            ? const Icon(Icons.image, color: Colors.grey)
            : null,
      );
    } else if (archive.isVideo) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade200,
        ),
        child: const Icon(Icons.videocam, color: Colors.grey),
      );
    } else {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade200,
        ),
        child: const Icon(Icons.insert_drive_file, color: Colors.grey),
      );
    }
  }

  void _downloadArchive(EventArchive archive) {
    // В реальном приложении здесь бы использовался url_launcher
    // для скачивания файла
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Скачивание: ${archive.fileName ?? 'файл'}'),
        action: SnackBarAction(
          label: 'Открыть',
          onPressed: () {
            // Открыть файл в браузере или приложении
          },
        ),
      ),
    );
  }

  void _showArchivePreview(EventArchive archive) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: double.infinity,
          height: 400,
          child: Column(
            children: [
              // Заголовок
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        archive.fileName ?? 'Файл',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Превью
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  child: archive.isImage
                      ? Image.network(
                          archive.fileUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.error, size: 50)),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam, size: 50),
                              SizedBox(height: 16),
                              Text('Видео превью'),
                            ],
                          ),
                        ),
                ),
              ),
              // Кнопки действий
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _downloadArchive(archive),
                      icon: const Icon(Icons.download),
                      label: const Text('Скачать'),
                    ),
                    if (_canUpload)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _deleteArchive(archive);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Удалить'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }
}
