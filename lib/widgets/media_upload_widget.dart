import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/media_storage_service.dart';

/// Виджет для загрузки медиафайлов мероприятия
class MediaUploadWidget extends StatefulWidget {
  const MediaUploadWidget({
    super.key,
    required this.bookingId,
    required this.specialistId,
    this.onUploadComplete,
    this.onUploadError,
  });

  final String bookingId;
  final String specialistId;
  final VoidCallback? onUploadComplete;
  final Function(String)? onUploadError;

  @override
  State<MediaUploadWidget> createState() => _MediaUploadWidgetState();
}

class _MediaUploadWidgetState extends State<MediaUploadWidget> {
  final MediaStorageService _mediaService = MediaStorageService();
  final TextEditingController _descriptionController = TextEditingController();

  final List<XFile> _selectedFiles = [];
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _uploadError;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildFileSelection(),
              const SizedBox(height: 16),
              _buildSelectedFiles(),
              const SizedBox(height: 16),
              _buildUploadButton(),
              if (_isUploading) _buildUploadProgress(),
              if (_uploadError != null) _buildError(),
            ],
          ),
        ),
      );

  Widget _buildHeader() => Row(
        children: [
          const Icon(Icons.cloud_upload, color: Colors.blue),
          const SizedBox(width: 8),
          const Text(
            'Загрузка медиафайлов',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (_selectedFiles.isNotEmpty)
            Text(
              '${_selectedFiles.length} файлов',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
        ],
      );

  Widget _buildDescriptionField() => TextField(
        controller: _descriptionController,
        decoration: const InputDecoration(
          labelText: 'Описание медиафайлов',
          hintText: 'Опишите загружаемые файлы...',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.description),
        ),
        maxLines: 3,
      );

  Widget _buildFileSelection() => Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _selectImages,
              icon: const Icon(Icons.photo_library),
              label: const Text('Выбрать фото'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _selectVideos,
              icon: const Icon(Icons.video_library),
              label: const Text('Выбрать видео'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _selectFiles,
              icon: const Icon(Icons.attach_file),
              label: const Text('Выбрать файлы'),
            ),
          ),
        ],
      );

  Widget _buildSelectedFiles() {
    if (_selectedFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Выбранные файлы:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...(_selectedFiles.asMap().entries.map((entry) {
          final index = entry.key;
          final file = entry.value;
          return _buildFileItem(file, index);
        })),
      ],
    );
  }

  Widget _buildFileItem(XFile file, int index) => Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: _getFileIcon(file.path),
          title: Text(
            file.name,
            style: const TextStyle(fontSize: 14),
          ),
          subtitle: Text(
            _getFileSize(file.path),
            style: const TextStyle(fontSize: 12),
          ),
          trailing: IconButton(
            onPressed: _isUploading ? null : () => _removeFile(index),
            icon: const Icon(Icons.close, color: Colors.red),
          ),
        ),
      );

  Widget _getFileIcon(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
      return const Icon(Icons.image, color: Colors.blue);
    } else if (['mp4', 'avi', 'mov'].contains(extension)) {
      return const Icon(Icons.video_file, color: Colors.red);
    } else if (extension == 'pdf') {
      return const Icon(Icons.picture_as_pdf, color: Colors.red);
    } else {
      return const Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }

  String _getFileSize(String filePath) {
    try {
      final file = File(filePath);
      final size = file.lengthSync();
      if (size < 1024) return '$size B';
      if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
      if (size < 1024 * 1024 * 1024) {
        return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } catch (e) {
      return 'Неизвестный размер';
    }
  }

  Widget _buildUploadButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed:
              _selectedFiles.isEmpty || _isUploading ? null : _uploadFiles,
          icon: _isUploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_upload),
          label: Text(_isUploading ? 'Загрузка...' : 'Загрузить файлы'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );

  Widget _buildUploadProgress() => Column(
        children: [
          const SizedBox(height: 16),
          LinearProgressIndicator(value: _uploadProgress),
          const SizedBox(height: 8),
          Text(
            '${(_uploadProgress * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      );

  Widget _buildError() => Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(12),
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
              child: Text(
                _uploadError!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _uploadError = null),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      );

  // ========== МЕТОДЫ ==========

  Future<void> _selectImages() async {
    try {
      final images = await ImagePicker().pickMultiImage();
      setState(() {
        _selectedFiles.addAll(images);
        _uploadError = null;
      });
    } catch (e) {
      setState(() => _uploadError = 'Ошибка выбора изображений: $e');
    }
  }

  Future<void> _selectVideos() async {
    try {
      final video = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
      );
      if (video != null) {
        setState(() {
          _selectedFiles.add(video);
          _uploadError = null;
        });
      }
    } catch (e) {
      setState(() => _uploadError = 'Ошибка выбора видео: $e');
    }
  }

  Future<void> _selectFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );

      if (result != null) {
        final files = result.files
            .where((file) => file.path != null)
            .map((file) => XFile(file.path!))
            .toList();

        setState(() {
          _selectedFiles.addAll(files);
          _uploadError = null;
        });
      }
    } catch (e) {
      setState(() => _uploadError = 'Ошибка выбора файлов: $e');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadError = null;
    });

    try {
      final uploadedFiles = await _mediaService.uploadEventMedia(
        bookingId: widget.bookingId,
        specialistId: widget.specialistId,
        files: _selectedFiles,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      setState(() {
        _isUploading = false;
        _uploadProgress = 1.0;
        _selectedFiles.clear();
        _descriptionController.clear();
      });

      if (widget.onUploadComplete != null) {
        widget.onUploadComplete!();
      }

      // Показываем уведомление об успешной загрузке
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Успешно загружено ${uploadedFiles.length} файлов'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadError = 'Ошибка загрузки: $e';
      });

      if (widget.onUploadError != null) {
        widget.onUploadError!(e.toString());
      }
    }
  }
}
