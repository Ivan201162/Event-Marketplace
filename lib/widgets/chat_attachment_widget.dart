import 'package:event_marketplace_app/models/chat_attachment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Виджет для отображения вложений в чате
class ChatAttachmentWidget extends ConsumerWidget {
  const ChatAttachmentWidget({
    required this.attachment, required this.isFromCurrentUser, super.key,
    this.onTap,
    this.onDelete,
  });
  final ChatAttachment attachment;
  final bool isFromCurrentUser;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: _buildAttachmentContent(context),
      );

  Widget _buildAttachmentContent(BuildContext context) {
    switch (attachment.type) {
      case AttachmentType.image:
        return _buildImageAttachment(context);
      case AttachmentType.video:
        return _buildVideoAttachment(context);
      case AttachmentType.audio:
        return _buildAudioAttachment(context);
      case AttachmentType.document:
        return _buildDocumentAttachment(context);
      case AttachmentType.other:
        return _buildOtherAttachment(context);
    }
  }

  Widget _buildImageAttachment(BuildContext context) => GestureDetector(
        onTap: onTap ?? () => _openImage(context),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.network(
                  attachment.thumbnailUrl ?? attachment.fileUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 200,
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 50),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.zoom_in,
                        color: Colors.white, size: 16,),
                  ),
                ),
                if (attachment.originalFileName.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
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
                      child: Text(
                        attachment.originalFileName,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

  Widget _buildVideoAttachment(BuildContext context) => GestureDetector(
        onTap: onTap ?? () => _openVideo(context),
        child: Container(
          width: 200,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[900],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Превью видео (если есть)
                if (attachment.thumbnailUrl != null)
                  Image.network(attachment.thumbnailUrl!,
                      fit: BoxFit.cover, width: 200, height: 120,),
                // Иконка воспроизведения
                const Center(
                    child: Icon(Icons.play_circle_filled,
                        color: Colors.white, size: 48,),),
                // Информация о файле
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          attachment.originalFileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          attachment.getFormattedFileSize(),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10,),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildAudioAttachment(BuildContext context) => Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.blue[50],
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.audiotrack, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    attachment.originalFileName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14,),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    attachment.getFormattedFileSize(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onTap ?? () => _openFile(context),
              icon: const Icon(Icons.play_arrow),
              color: Colors.blue,
            ),
          ],
        ),
      );

  Widget _buildDocumentAttachment(BuildContext context) => Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[100],
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(_getDocumentIcon(), color: Colors.grey[700], size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    attachment.originalFileName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14,),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    attachment.getFormattedFileSize(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onTap ?? () => _openFile(context),
              icon: const Icon(Icons.download),
              color: Colors.grey[700],
            ),
          ],
        ),
      );

  Widget _buildOtherAttachment(BuildContext context) => Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.orange[50],
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.attach_file, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    attachment.originalFileName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14,),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    attachment.getFormattedFileSize(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onTap ?? () => _openFile(context),
              icon: const Icon(Icons.download),
              color: Colors.orange,
            ),
          ],
        ),
      );

  IconData _getDocumentIcon() {
    final extension = attachment.getFileExtension();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'rtf':
        return Icons.text_fields;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _openImage(BuildContext context) {
    // TODO(developer): Открыть изображение в полноэкранном режиме
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(
        content: Text('Открытие изображения: ${attachment.originalFileName}'),),);
  }

  void _openVideo(BuildContext context) {
    // TODO(developer): Открыть видео в плеере
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(
        content: Text('Открытие видео: ${attachment.originalFileName}'),),);
  }

  Future<void> _openFile(BuildContext context) async {
    try {
      final uri = Uri.parse(attachment.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('Не удалось открыть файл')),);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка открытия файла: $e')));
    }
  }
}
