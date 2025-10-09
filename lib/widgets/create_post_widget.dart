import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/enhanced_feed_post.dart';
import '../providers/enhanced_feed_providers.dart';

/// Виджет для создания поста
class CreatePostWidget extends ConsumerStatefulWidget {
  const CreatePostWidget({
    super.key,
    required this.authorId,
    this.onPostCreated,
  });

  final String authorId;
  final VoidCallback? onPostCreated;

  @override
  ConsumerState<CreatePostWidget> createState() => _CreatePostWidgetState();
}

class _CreatePostWidgetState extends ConsumerState<CreatePostWidget> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final List<XFile> _selectedMedia = [];
  FeedPostType _selectedType = FeedPostType.text;
  bool _isLoading = false;
  bool _isSponsored = false;

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Создать пост'),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _createPost,
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
              _buildPostTypeSelector(),
              const SizedBox(height: 16),
              _buildContentField(),
              const SizedBox(height: 16),
              _buildMediaSection(),
              const SizedBox(height: 16),
              _buildTagsField(),
              const SizedBox(height: 16),
              _buildLocationField(),
              const SizedBox(height: 16),
              _buildSponsoredToggle(),
              const SizedBox(height: 24),
              _buildPreviewSection(),
            ],
          ),
        ),
      );

  Widget _buildPostTypeSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Тип поста',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: FeedPostType.values.map((type) {
              final isSelected = _selectedType == type;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedType = type;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(type.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        type.displayName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );

  Widget _buildContentField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Содержимое',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Что у вас нового?',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      );

  Widget _buildMediaSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Медиафайлы',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    tooltip: 'Добавить фото',
                  ),
                  IconButton(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.videocam),
                    tooltip: 'Добавить видео',
                  ),
                ],
              ),
            ],
          ),
          if (_selectedMedia.isNotEmpty) _buildMediaPreview(),
        ],
      );

  Widget _buildMediaPreview() => Container(
        height: 100,
        margin: const EdgeInsets.only(top: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _selectedMedia.length,
          itemBuilder: (context, index) {
            final file = _selectedMedia[index];
            return Container(
              width: 100,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: file.path.toLowerCase().endsWith('.mp4') ||
                            file.path.toLowerCase().endsWith('.mov')
                        ? const Center(
                            child: Icon(Icons.play_circle_fill, size: 40),
                          )
                        : Image.file(
                            File(file.path),
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                          ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMedia.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

  Widget _buildTagsField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Теги',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
              hintText:
                  'Введите теги через пробел (например: #событие #праздник)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      );

  Widget _buildLocationField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Местоположение',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              hintText: 'Где это происходит?',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
        ],
      );

  Widget _buildSponsoredToggle() => Row(
        children: [
          Checkbox(
            value: _isSponsored,
            onChanged: (value) {
              setState(() {
                _isSponsored = value ?? false;
              });
            },
          ),
          const Text('Рекламный пост'),
        ],
      );

  Widget _buildPreviewSection() {
    if (_contentController.text.isEmpty && _selectedMedia.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Предварительный просмотр',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      child: Text(
                        widget.authorId.isNotEmpty
                            ? widget.authorId[0].toUpperCase()
                            : 'U',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Пользователь ${widget.authorId}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      'Сейчас',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                if (_contentController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_contentController.text),
                ],
                if (_selectedMedia.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Медиафайлы будут отображены здесь'),
                    ),
                  ),
                ],
                if (_tagsController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: _tagsController.text
                        .split(' ')
                        .where((tag) => tag.trim().isNotEmpty)
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tag.startsWith('#') ? tag : '#$tag',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (_locationController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _locationController.text,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();

      setState(() {
        _selectedMedia.addAll(images);
        if (_selectedMedia.isNotEmpty && _selectedType == FeedPostType.text) {
          _selectedType = FeedPostType.image;
        }
      });
    } catch (e) {
      _showErrorSnackBar('Ошибка выбора изображений: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        setState(() {
          _selectedMedia.add(video);
          _selectedType = FeedPostType.video;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка выбора видео: $e');
    }
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty && _selectedMedia.isEmpty) {
      _showErrorSnackBar('Добавьте текст или медиафайлы');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tags = _tagsController.text
          .split(' ')
          .where((tag) => tag.trim().isNotEmpty)
          .map((tag) => tag.replaceAll('#', ''))
          .toList();

      final feedService = ref.read(enhancedFeedServiceProvider);

      await feedService.createPost(
        authorId: widget.authorId,
        content: _contentController.text.trim(),
        type: _selectedType,
        mediaFiles: _selectedMedia,
        tags: tags,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        isSponsored: _isSponsored,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onPostCreated?.call();
        _showSuccessSnackBar('Пост успешно создан!');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка создания поста: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
