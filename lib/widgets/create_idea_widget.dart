import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/enhanced_idea.dart';
import '../services/enhanced_ideas_service.dart';
import '../providers/enhanced_ideas_providers.dart';

/// Виджет для создания идеи
class CreateIdeaWidget extends ConsumerStatefulWidget {
  const CreateIdeaWidget({
    super.key,
    required this.authorId,
    this.onIdeaCreated,
  });

  final String authorId;
  final VoidCallback? onIdeaCreated;

  @override
  ConsumerState<CreateIdeaWidget> createState() => _CreateIdeaWidgetState();
}

class _CreateIdeaWidgetState extends ConsumerState<CreateIdeaWidget> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _timelineController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  List<XFile> _selectedMedia = [];
  IdeaType _selectedType = IdeaType.general;
  bool _isLoading = false;
  bool _isPublic = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _categoryController.dispose();
    _budgetController.dispose();
    _timelineController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать идею'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createIdea,
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
            _buildIdeaTypeSelector(),
            const SizedBox(height: 16),
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 16),
            _buildMediaSection(),
            const SizedBox(height: 16),
            _buildTagsField(),
            const SizedBox(height: 16),
            _buildCategoryField(),
            const SizedBox(height: 16),
            _buildBudgetField(),
            const SizedBox(height: 16),
            _buildTimelineField(),
            const SizedBox(height: 16),
            _buildLocationField(),
            const SizedBox(height: 16),
            _buildPublicToggle(),
            const SizedBox(height: 24),
            _buildPreviewSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildIdeaTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Тип идеи',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: IdeaType.values.map((type) {
            final isSelected = _selectedType == type;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = type;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Заголовок',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Краткое описание идеи',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Описание',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Подробное описание идеи',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSection() {
    return Column(
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
  }

  Widget _buildMediaPreview() {
    return Container(
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
  }

  Widget _buildTagsField() {
    return Column(
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
            hintText: 'Введите теги через пробел (например: #событие #праздник)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Категория',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _categoryController,
          decoration: const InputDecoration(
            hintText: 'Категория идеи',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Бюджет',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _budgetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Бюджет в рублях',
            border: OutlineInputBorder(),
            prefixText: '₽ ',
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Временные рамки',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _timelineController,
          decoration: const InputDecoration(
            hintText: 'Например: 1 день, 1 неделя, 1 месяц',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
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
            hintText: 'Где будет реализована идея?',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
      ],
    );
  }

  Widget _buildPublicToggle() {
    return Row(
      children: [
        Checkbox(
          value: _isPublic,
          onChanged: (value) {
            setState(() {
              _isPublic = value ?? true;
            });
          },
        ),
        const Text('Публичная идея'),
      ],
    );
  }

  Widget _buildPreviewSection() {
    if (_titleController.text.isEmpty && _descriptionController.text.isEmpty) {
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
                      child: Text(widget.authorId.isNotEmpty 
                          ? widget.authorId[0].toUpperCase() 
                          : 'U'),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(_selectedType.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      _selectedType.displayName,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                if (_titleController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _titleController.text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (_descriptionController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_descriptionController.text),
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
                        .map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      );
                    }).toList(),
                  ),
                ],
                if (_budgetController.text.isNotEmpty || 
                    _timelineController.text.isNotEmpty || 
                    _locationController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        if (_budgetController.text.isNotEmpty)
                          _buildPreviewDetailRow(
                            Icons.attach_money,
                            'Бюджет',
                            '₽ ${_budgetController.text}',
                          ),
                        if (_timelineController.text.isNotEmpty)
                          _buildPreviewDetailRow(
                            Icons.schedule,
                            'Сроки',
                            _timelineController.text,
                          ),
                        if (_locationController.text.isNotEmpty)
                          _buildPreviewDetailRow(
                            Icons.location_on,
                            'Место',
                            _locationController.text,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      
      setState(() {
        _selectedMedia.addAll(images);
      });
    } catch (e) {
      _showErrorSnackBar('Ошибка выбора изображений: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      
      if (video != null) {
        setState(() {
          _selectedMedia.add(video);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка выбора видео: $e');
    }
  }

  Future<void> _createIdea() async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Введите заголовок идеи');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showErrorSnackBar('Введите описание идеи');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final List<String> tags = _tagsController.text
          .split(' ')
          .where((tag) => tag.trim().isNotEmpty)
          .map((tag) => tag.replaceAll('#', ''))
          .toList();

      final double? budget = _budgetController.text.trim().isNotEmpty
          ? double.tryParse(_budgetController.text.trim())
          : null;

      final ideasService = ref.read(enhancedIdeasServiceProvider);
      
      await ideasService.createIdea(
        authorId: widget.authorId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        mediaFiles: _selectedMedia,
        tags: tags,
        category: _categoryController.text.trim().isNotEmpty 
            ? _categoryController.text.trim() 
            : null,
        budget: budget,
        timeline: _timelineController.text.trim().isNotEmpty 
            ? _timelineController.text.trim() 
            : null,
        location: _locationController.text.trim().isNotEmpty 
            ? _locationController.text.trim() 
            : null,
        isPublic: _isPublic,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onIdeaCreated?.call();
        _showSuccessSnackBar('Идея успешно создана!');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка создания идеи: $e');
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
