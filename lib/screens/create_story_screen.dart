import 'dart:io';

import 'package:event_marketplace_app/models/specialist_story.dart';
import 'package:event_marketplace_app/models/story.dart';
import 'package:event_marketplace_app/services/story_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({
    required this.specialistId, required this.specialistName, super.key,
    this.specialistAvatar,
  });
  final String specialistId;
  final String specialistName;
  final String? specialistAvatar;

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  final StoryService _storyService = StoryService();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();

  File? _selectedFile;
  StoryContentType _selectedType = StoryContentType.image;
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Создать сторис'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            if (_selectedFile != null)
              TextButton(
                onPressed: _isLoading ? null : _createStory,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Опубликовать'),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Выбор типа контента
              _buildContentTypeSelector(),

              const SizedBox(height: 24),

              // Выбор файла
              _buildFileSelector(),

              const SizedBox(height: 24),

              // Предварительный просмотр
              if (_selectedFile != null) _buildPreview(),

              const SizedBox(height: 24),

              // Текстовые поля
              _buildTextFields(),

              const SizedBox(height: 24),

              // Информация о сторис
              _buildStoryInfo(),
            ],
          ),
        ),
      );

  Widget _buildContentTypeSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Тип контента',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
          const SizedBox(height: 12),
          Row(
            children: StoryContentType.values
                .map(
                  (type) => Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = type;
                          _selectedFile =
                              null; // Сбрасываем файл при смене типа
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedType == type
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedType == type
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(_getContentTypeIcon(type),
                                style: const TextStyle(fontSize: 24),),
                            const SizedBox(height: 8),
                            Text(
                              _getContentTypeName(type),
                              style: TextStyle(
                                color: _selectedType == type
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      );

  Widget _buildFileSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Выберите файл',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _selectedFile == null
                ? InkWell(
                    onTap: _pickFile,
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getContentTypeIcon(_selectedType),
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нажмите для выбора ${_getContentTypeName(_selectedType).toLowerCase()}',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 16,),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _selectedType == StoryContentType.image
                            ? Image.file(
                                _selectedFile!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.black,
                                child: const Center(
                                  child: Text(
                                    'Видео файл выбран',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedFile = null;
                            });
                          },
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.add_photo_alternate),
            label: Text(
                'Выбрать ${_getContentTypeName(_selectedType).toLowerCase()}',),
          ),
        ],
      );

  Widget _buildPreview() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Предварительный просмотр',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _selectedType == StoryContentType.image
                  ? Image.file(_selectedFile!, fit: BoxFit.cover)
                  : const ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: Text(
                          'Видео предварительный просмотр',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      );

  Widget _buildTextFields() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Текст и подпись',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
          const SizedBox(height: 12),

          // Текст (для текстовых сторис)
          if (_selectedType == StoryContentType.text) ...[
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Текст сторис',
                hintText: 'Введите текст для сторис',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              maxLength: 200,
            ),
            const SizedBox(height: 16),
          ],

          // Подпись
          TextField(
            controller: _captionController,
            decoration: const InputDecoration(
              labelText: 'Подпись (необязательно)',
              hintText: 'Добавьте подпись к сторис',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            maxLength: 100,
          ),
        ],
      );

  Widget _buildStoryInfo() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Информация о сторис',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Тип', _getContentTypeName(_selectedType)),
            _buildInfoRow('Автор', widget.specialistName),
            _buildInfoRow('Время жизни', '24 часа'),
            _buildInfoRow('Статус', 'Будет опубликована'),
          ],
        ),
      );

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.w500),),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  Future<void> _pickFile() async {
    final picker = ImagePicker();

    try {
      XFile? file;
      if (_selectedType == StoryContentType.image) {
        file = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1080,
          maxHeight: 1920,
          imageQuality: 85,
        );
      } else if (_selectedType == StoryContentType.video) {
        file = await picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(seconds: 15),
        );
      }

      if (file != null) {
        setState(() {
          _selectedFile = File(file.path);
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка выбора файла: $e')));
      }
    }
  }

  Future<void> _createStory() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите файл для сторис')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _storyService.createStory(
        imageFile: _selectedFile,
        textContent: _textController.text.isEmpty ? null : _textController.text,
        privacy: StoryPrivacy.public,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Сторис успешно создана')));
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка создания сторис: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getContentTypeIcon(StoryContentType type) {
    switch (type) {
      case StoryContentType.image:
        return '📷';
      case StoryContentType.video:
        return '🎥';
      case StoryContentType.text:
        return '📝';
    }
  }

  String _getContentTypeName(StoryContentType type) {
    switch (type) {
      case StoryContentType.image:
        return 'Фото';
      case StoryContentType.video:
        return 'Видео';
      case StoryContentType.text:
        return 'Текст';
    }
  }
}
