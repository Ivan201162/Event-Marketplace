import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_constants.dart';
import '../services/chat_file_service.dart';

/// Виджет для прикрепления файлов в чате
class ChatFileAttachment extends ConsumerStatefulWidget {
  const ChatFileAttachment({
    super.key,
    required this.onFileSelected,
    this.onCancel,
  });
  final Function(String fileUrl, String fileName, int fileSize, String fileType)
      onFileSelected;
  final Function()? onCancel;

  @override
  ConsumerState<ChatFileAttachment> createState() => _ChatFileAttachmentState();
}

class _ChatFileAttachmentState extends ConsumerState<ChatFileAttachment> {
  final ChatFileService _fileService = ChatFileService();
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _uploadingFileName;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Прикрепить файл',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Кнопки выбора файлов
            if (!_isUploading) ...[
              _buildFileTypeButton(
                icon: Icons.image,
                label: 'Фото',
                description: 'JPG, PNG, GIF',
                onTap: () => _pickFiles(FileType.image),
              ),
              const SizedBox(height: 12),
              _buildFileTypeButton(
                icon: Icons.videocam,
                label: 'Видео',
                description: 'MP4, MOV, AVI',
                onTap: () => _pickFiles(FileType.video),
              ),
              const SizedBox(height: 12),
              _buildFileTypeButton(
                icon: Icons.audiotrack,
                label: 'Аудио',
                description: 'MP3, WAV, AAC',
                onTap: () => _pickFiles(FileType.audio),
              ),
              const SizedBox(height: 12),
              _buildFileTypeButton(
                icon: Icons.description,
                label: 'Документы',
                description: 'PDF, DOC, TXT',
                onTap: () => _pickFiles(
                  FileType.custom,
                  allowedExtensions: AppConstants.supportedDocumentFormats,
                ),
              ),
              const SizedBox(height: 12),
              _buildFileTypeButton(
                icon: Icons.folder,
                label: 'Любой файл',
                description: 'Выбрать файл',
                onTap: () => _pickFiles(FileType.any),
              ),
            ],

            // Прогресс загрузки
            if (_isUploading) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Загрузка: $_uploadingFileName',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // Информация о поддерживаемых форматах
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Поддерживаемые форматы:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._fileService.getSupportedFileTypes().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${entry.key}: ${entry.value.join(', ').toUpperCase()}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                  const SizedBox(height: 8),
                  const Text(
                    'Максимальный размер: ${AppConstants.maxImageUploadSizeMB}MB (изображения), ${AppConstants.maxVideoUploadSizeMB}MB (видео), ${AppConstants.maxAudioUploadSizeMB}MB (аудио), 10MB (документы)',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildFileTypeButton({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: Colors.blue[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      );

  Future<void> _pickFiles(
    FileType fileType, {
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          await _uploadFile(File(file.path!), file.name);
        } else if (file.bytes != null) {
          await _uploadFileFromBytes(file.bytes!, file.name);
        }
      }
    } catch (e) {
      _showError('Ошибка выбора файла: $e');
    }
  }

  Future<void> _uploadFile(File file, String fileName) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadingFileName = fileName;
    });

    try {
      // TODO: Получить chatId и senderId из контекста
      const chatId = 'temp_chat_id';
      const senderId = 'temp_sender_id';

      final fileUrl = await _fileService.uploadChatFile(
        chatId: chatId,
        senderId: senderId,
        file: file,
        fileName: fileName,
      );

      final fileSize = await file.length();
      final fileType = _getFileType(fileName);

      widget.onFileSelected(fileUrl, fileName, fileSize, fileType);
    } catch (e) {
      _showError('Ошибка загрузки файла: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadingFileName = null;
      });
    }
  }

  Future<void> _uploadFileFromBytes(Uint8List bytes, String fileName) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadingFileName = fileName;
    });

    try {
      // TODO: Получить chatId и senderId из контекста
      const chatId = 'temp_chat_id';
      const senderId = 'temp_sender_id';

      final fileUrl = await _fileService.uploadChatFileFromBytes(
        chatId: chatId,
        senderId: senderId,
        bytes: bytes,
        fileName: fileName,
      );

      final fileType = _getFileType(fileName);

      widget.onFileSelected(fileUrl, fileName, bytes.length, fileType);
    } catch (e) {
      _showError('Ошибка загрузки файла: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadingFileName = null;
      });
    }
  }

  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    if (AppConstants.supportedImageFormats.contains(extension)) {
      return 'image';
    } else if (AppConstants.supportedVideoFormats.contains(extension)) {
      return 'video';
    } else if (AppConstants.supportedAudioFormats.contains(extension)) {
      return 'audio';
    } else if (AppConstants.supportedDocumentFormats.contains(extension)) {
      return 'document';
    }

    return 'file';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// Виджет для отображения прикрепленного файла в чате
class ChatFileMessage extends StatelessWidget {
  const ChatFileMessage({
    super.key,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    this.thumbnailUrl,
    this.onTap,
  });
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String fileType;
  final String? thumbnailUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildFileIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatFileSize(fileSize),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.download,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildFileIcon() {
    IconData icon;
    Color color;

    switch (fileType) {
      case 'image':
        icon = Icons.image;
        color = Colors.green;
        break;
      case 'video':
        icon = Icons.videocam;
        color = Colors.red;
        break;
      case 'audio':
        icon = Icons.audiotrack;
        color = Colors.orange;
        break;
      case 'document':
        icon = Icons.description;
        color = Colors.blue;
        break;
      default:
        icon = Icons.attach_file;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
