import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/story.dart';
import '../providers/auth_providers.dart';
import '../services/story_service.dart';

/// Диалог создания сторис
class CreateStoryDialog extends ConsumerStatefulWidget {
  const CreateStoryDialog({super.key});

  @override
  ConsumerState<CreateStoryDialog> createState() => _CreateStoryDialogState();
}

class _CreateStoryDialogState extends ConsumerState<CreateStoryDialog> {
  final StoryService _storyService = StoryService();
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();

  StoryContentType _selectedType = StoryContentType.image;
  XFile? _selectedFile;
  Color _backgroundColor = Colors.black;
  Color _textColor = Colors.white;
  double _fontSize = 24;
  bool _isUploading = false;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Создать сторис'),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Выбор типа контента
                _buildContentTypeSelector(),
                const SizedBox(height: 16),

                // Выбор файла или ввод текста
                _buildContentInput(),
                const SizedBox(height: 16),

                // Настройки для текстовых сторис
                if (_selectedType == StoryContentType.text) ...[
                  _buildTextSettings(),
                  const SizedBox(height: 16),
                ],

                // Ошибка
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!, style: TextStyle(color: Colors.red[600])),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: _isUploading ? null : _createStory,
            child: _isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Создать'),
          ),
        ],
      );

  Widget _buildContentTypeSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Тип контента', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          RadioGroup<StoryContentType>(
            value: _selectedType,
            onChanged: (value) {
              setState(() {
                _selectedType = value;
                _selectedFile = null;
              });
            },
            children: [
              Expanded(
                child: RadioListTile<StoryContentType>(
                  title: const Text('Изображение'),
                  value: StoryContentType.image,
                ),
              ),
              Expanded(
                child: RadioListTile<StoryContentType>(
                  title: const Text('Видео'),
                  value: StoryContentType.video,
                ),
              ),
              Expanded(
                child: RadioListTile<StoryContentType>(
                  title: const Text('Текст'),
                  value: StoryContentType.text,
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildContentInput() {
    if (_selectedType == StoryContentType.text) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Текст сторис', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _textController,
            decoration: const InputDecoration(
              hintText: 'Введите текст для сторис...',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите текст';
              }
              return null;
            },
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Выберите файл', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_selectedFile == null) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Галерея'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Камера'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedType == StoryContentType.image ? Icons.image : Icons.video_library,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFile!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatFileSize(File(_selectedFile!.path).lengthSync()),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedFile = null;
                      });
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }
  }

  Widget _buildTextSettings() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Настройки текста', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Цвет фона
          Row(
            children: [
              const Text('Цвет фона: '),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    Colors.black,
                    Colors.white,
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                  ]
                      .map(
                        (color) => GestureDetector(
                          onTap: () {
                            setState(() {
                              _backgroundColor = color;
                            });
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _backgroundColor == color ? Colors.blue : Colors.grey,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Цвет текста
          Row(
            children: [
              const Text('Цвет текста: '),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    Colors.white,
                    Colors.black,
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                  ]
                      .map(
                        (color) => GestureDetector(
                          onTap: () {
                            setState(() {
                              _textColor = color;
                            });
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _textColor == color ? Colors.blue : Colors.grey,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Размер шрифта
          Row(
            children: [
              const Text('Размер шрифта: '),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 16,
                  max: 48,
                  divisions: 16,
                  label: _fontSize.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      _fontSize = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      );

  Future<void> _pickFromGallery() async {
    try {
      final file = _selectedType == StoryContentType.image
          ? await _storyService.pickImage()
          : await _storyService.pickVideo();

      if (file != null) {
        setState(() {
          _selectedFile = file;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка выбора файла: $e';
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final file = _selectedType == StoryContentType.image
          ? await _storyService.takePhoto()
          : await _storyService.recordVideo();

      if (file != null) {
        setState(() {
          _selectedFile = file;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка создания файла: $e';
      });
    }
  }

  Future<void> _createStory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedType != StoryContentType.text && _selectedFile == null) {
      setState(() {
        _error = 'Выберите файл';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      final currentUserAsync = ref.read(currentUserProvider);
      final currentUser = currentUserAsync.value;
      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      String content;
      if (_selectedType == StoryContentType.text) {
        content = _textController.text.trim();
      } else {
        // Загружаем файл
        if (_selectedType == StoryContentType.image) {
          content = await _storyService.uploadStoryImage(
            authorId: currentUser.uid,
            imageFile: _selectedFile!,
          );
        } else {
          content = await _storyService.uploadStoryVideo(
            authorId: currentUser.uid,
            videoFile: _selectedFile!,
          );
        }
      }

      // Создаем сторис
      final createStory = CreateStory(
        authorId: currentUser.uid,
        contentType: _selectedType,
        content: content,
        text: _selectedType == StoryContentType.text ? _textController.text.trim() : null,
        backgroundColor: _selectedType == StoryContentType.text
            ? '#${_backgroundColor.toARGB32().toRadixString(16).substring(2)}'
            : null,
        textColor: _selectedType == StoryContentType.text
            ? '#${_textColor.toARGB32().toRadixString(16).substring(2)}'
            : null,
        fontSize: _selectedType == StoryContentType.text ? _fontSize : null,
      );

      await _storyService.createStory(
        specialistId: createStory.specialistId,
        mediaUrl: createStory.mediaUrl,
        text: createStory.text,
        metadata: createStory.metadata,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сторис создана'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isUploading = false;
      });
    }
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
