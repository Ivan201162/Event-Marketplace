import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_profile_extended.dart';
import '../services/customer_profile_extended_service.dart';

/// Виджет редактора заметок
class NoteEditorWidget extends ConsumerStatefulWidget {
  final String userId;
  final CustomerNote? existingNote;
  final VoidCallback onNoteSaved;

  const NoteEditorWidget({
    super.key,
    required this.userId,
    this.existingNote,
    required this.onNoteSaved,
  });

  @override
  ConsumerState<NoteEditorWidget> createState() => _NoteEditorWidgetState();
}

class _NoteEditorWidgetState extends ConsumerState<NoteEditorWidget> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final List<String> _tags = [];
  bool _isPinned = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      _titleController.text = widget.existingNote!.title;
      _contentController.text = widget.existingNote!.content;
      _tags.addAll(widget.existingNote!.tags);
      _isPinned = widget.existingNote!.isPinned;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            AppBar(
              title: Text(widget.existingNote == null ? 'Новая заметка' : 'Редактировать заметку'),
              actions: [
                TextButton(
                  onPressed: _isSaving ? null : _saveNote,
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Заголовок *',
                        border: OutlineInputBorder(),
                        hintText: 'Введите заголовок заметки',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    
                    // Содержимое
                    TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Содержимое *',
                        border: OutlineInputBorder(),
                        hintText: 'Введите текст заметки',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
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
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Теги',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
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
            IconButton(
              onPressed: () => _addTag(_tagsController.text),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Список тегов
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _tags.map((tag) => Chip(
              label: Text(tag),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => _removeTag(tag),
            )).toList(),
          ),
        
        // Предложенные теги
        _buildSuggestedTags(),
      ],
    );
  }

  Widget _buildSuggestedTags() {
    final suggestedTags = [
      'важно', 'идея', 'бюджет', 'дата', 'место', 'гости',
      'декор', 'еда', 'музыка', 'фото', 'видео', 'подарки'
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Предложенные теги:',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: suggestedTags.map((tag) => ActionChip(
            label: Text(tag, style: const TextStyle(fontSize: 12)),
            onPressed: () => _addTag(tag),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Настройки',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        SwitchListTile(
          title: const Text('Закрепить заметку'),
          subtitle: const Text('Закреплённые заметки отображаются вверху списка'),
          value: _isPinned,
          onChanged: (value) {
            setState(() {
              _isPinned = value;
            });
          },
        ),
      ],
    );
  }

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

  void _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните заголовок и содержимое')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final service = ref.read(customerProfileExtendedServiceProvider);
      
      if (widget.existingNote != null) {
        // Обновляем существующую заметку
        final updatedNote = widget.existingNote!.copyWith(
          title: title,
          content: content,
          tags: _tags,
          isPinned: _isPinned,
        );
        
        await service.updateNote(widget.userId, updatedNote);
      } else {
        // Создаём новую заметку
        await service.addNote(
          userId: widget.userId,
          title: title,
          content: content,
          tags: _tags,
          isPinned: _isPinned,
        );
      }

      Navigator.pop(context);
      widget.onNoteSaved();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingNote == null 
                ? 'Заметка создана' 
                : 'Заметка обновлена'
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}
