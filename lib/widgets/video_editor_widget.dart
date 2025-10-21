import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist_profile_extended.dart';
// import '../services/specialist_profile_extended_service.dart';

/// Виджет редактора видео
class VideoEditorWidget extends ConsumerStatefulWidget {
  const VideoEditorWidget({
    super.key,
    required this.specialistId,
    this.existingVideo,
    required this.onVideoSaved,
  });
  final String specialistId;
  final PortfolioVideo? existingVideo;
  final VoidCallback onVideoSaved;

  @override
  ConsumerState<VideoEditorWidget> createState() => _VideoEditorWidgetState();
}

class _VideoEditorWidgetState extends ConsumerState<VideoEditorWidget> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _thumbnailUrlController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final List<String> _tags = [];
  String _selectedPlatform = 'youtube';
  bool _isPublic = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingVideo != null) {
      _titleController.text = widget.existingVideo!.title;
      _descriptionController.text = widget.existingVideo!.description;
      _urlController.text = widget.existingVideo!.url;
      _thumbnailUrlController.text = widget.existingVideo!.thumbnailUrl;
      _durationController.text = widget.existingVideo!.duration;
      _tags.addAll(widget.existingVideo!.tags);
      _selectedPlatform = widget.existingVideo!.platform;
      _isPublic = widget.existingVideo!.isPublic;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _thumbnailUrlController.dispose();
    _durationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: Container(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
      child: Column(
        children: [
          AppBar(
            title: Text(widget.existingVideo == null ? 'Новое видео' : 'Редактировать видео'),
            actions: [
              TextButton(
                onPressed: _isSaving ? null : _saveVideo,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Сохранить'),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Название видео *',
                      border: OutlineInputBorder(),
                      hintText: 'Введите название видео',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),

                  // Описание
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Описание *',
                      border: OutlineInputBorder(),
                      hintText: 'Введите описание видео',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),

                  // URL и платформа
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            labelText: 'URL видео *',
                            border: OutlineInputBorder(),
                            hintText: 'https://...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedPlatform,
                          decoration: const InputDecoration(
                            labelText: 'Платформа',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'youtube', child: Text('YouTube')),
                            DropdownMenuItem(value: 'vimeo', child: Text('Vimeo')),
                            DropdownMenuItem(value: 'direct', child: Text('Прямая загрузка')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedPlatform = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Превью и длительность
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _thumbnailUrlController,
                          decoration: const InputDecoration(
                            labelText: 'URL превью',
                            border: OutlineInputBorder(),
                            hintText: 'https://...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _durationController,
                          decoration: const InputDecoration(
                            labelText: 'Длительность',
                            border: OutlineInputBorder(),
                            hintText: '3:45',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Теги
                  _buildTagsSection(),
                  const SizedBox(height: 16),

                  // Настройки
                  _buildSettingsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildTagsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Теги', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),

      // Поле ввода тегов
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                hintText: 'Введите тег и нажмите Enter',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _addTag,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(onPressed: () => _addTag(_tagsController.text), icon: const Icon(Icons.add)),
        ],
      ),
      const SizedBox(height: 8),

      // Список тегов
      if (_tags.isNotEmpty)
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: _tags
              .map(
                (tag) => Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeTag(tag),
                ),
              )
              .toList(),
        ),

      // Предложенные теги
      _buildSuggestedTags(),
    ],
  );

  Widget _buildSuggestedTags() {
    final suggestedTags = [
      'портфолио',
      'работа',
      'мероприятие',
      'свадьба',
      'корпоратив',
      'фотосессия',
      'видеосъёмка',
      'дрон',
      'аэросъёмка',
      'таймлапс',
      'интервью',
      'репортаж',
      'документальный',
      'реклама',
      'презентация',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('Предложенные теги:', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: suggestedTags
              .map(
                (tag) => ActionChip(
                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _addTag(tag),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Настройки', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      SwitchListTile(
        title: const Text('Публичное видео'),
        subtitle: const Text('Клиенты смогут видеть это видео'),
        value: _isPublic,
        onChanged: (value) {
          setState(() {
            _isPublic = value;
          });
        },
      ),
    ],
  );

  void _addTag(String tag) {
    final trimmedTag = tag.trim().toLowerCase();
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
      setState(() {
        _tags.add(trimmedTag);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveVideo() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final url = _urlController.text.trim();
    // final thumbnailUrl = _thumbnailUrlController.text.trim(); // Unused variable
    // final duration = _durationController.text.trim(); // Unused variable

    if (title.isEmpty || description.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Заполните обязательные поля')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // final service = ref.read(specialistServiceProvider); // Unused variable removed

      if (widget.existingVideo != null) {
        // Обновляем существующее видео
        // final updatedVideo = widget.existingVideo!.copyWith( // Unused variable removed
        //   title: title,
        //   description: description,
        //   url: url,
        //   thumbnailUrl: thumbnailUrl,
        //   platform: _selectedPlatform,
        //   duration: duration,
        //   tags: _tags,
        //   isPublic: _isPublic,
        // );

        // TODO(developer): Implement updatePortfolioVideo method
        // await service.updatePortfolioVideo(widget.specialistId, updatedVideo);
      } else {
        // Создаём новое видео
        // TODO(developer): Implement addPortfolioVideo method
        // await service.addPortfolioVideo(
        //   specialistId: widget.specialistId,
        //   title: title,
        //   description: description,
        //   url: url,
        //   thumbnailUrl: thumbnailUrl,
        //   platform: _selectedPlatform,
        //   duration: duration,
        //   tags: _tags,
        //   isPublic: _isPublic,
        // );
      }

      Navigator.pop(context);
      widget.onVideoSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingVideo == null ? 'Видео добавлено' : 'Видео обновлено'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}
