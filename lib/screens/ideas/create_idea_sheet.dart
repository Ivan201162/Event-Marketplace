import 'package:event_marketplace_app/models/idea.dart';
import 'package:event_marketplace_app/providers/ideas_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Модальное окно создания идеи
class CreateIdeaSheet extends ConsumerStatefulWidget {
  const CreateIdeaSheet({super.key});

  @override
  ConsumerState<CreateIdeaSheet> createState() => _CreateIdeaSheetState();
}

class _CreateIdeaSheetState extends ConsumerState<CreateIdeaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _tagsController = TextEditingController();

  final List<String> _attachments = [];
  List<String> _tags = [];
  bool _isPoll = false;
  String _pollQuestion = '';
  final List<String> _pollOptions = ['', ''];

  @override
  void dispose() {
    _textController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Создать идею'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            TextButton(
              onPressed: _publishIdea,
              child: const Text('Опубликовать'),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Текст идеи
                TextFormField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: 'Опишите вашу идею *',
                    hintText: 'Что у вас на уме?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите текст идеи';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Теги
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Теги',
                    hintText: 'Введите теги через запятую',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _tags = value
                          .split(',')
                          .map((tag) => tag.trim())
                          .where((tag) => tag.isNotEmpty)
                          .toList();
                    });
                  },
                ),

                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text('#$tag'),
                        onDeleted: () {
                          setState(() {
                            _tags.remove(tag);
                            _tagsController.text = _tags.join(', ');
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 16),

                // Вложения
                Row(
                  children: [
                    const Text('Вложения:'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: _addAttachment,
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: _addPhoto,
                    ),
                  ],
                ),

                if (_attachments.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _attachments.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.attach_file),
                        title: Text(_attachments[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeAttachment(index),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 16),

                // Опрос
                SwitchListTile(
                  title: const Text('Создать опрос'),
                  subtitle: const Text('Добавить интерактивный опрос к идее'),
                  value: _isPoll,
                  onChanged: (value) => setState(() => _isPoll = value),
                ),

                if (_isPoll) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Вопрос опроса',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _pollQuestion = value,
                  ),
                  const SizedBox(height: 16),
                  const Text('Варианты ответов:'),
                  const SizedBox(height: 8),
                  ...List.generate(_pollOptions.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                hintText: 'Вариант ${index + 1}',
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (value) => _pollOptions[index] = value,
                            ),
                          ),
                          if (_pollOptions.length > 2)
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => _removePollOption(index),
                            ),
                        ],
                      ),
                    );
                  }),
                  if (_pollOptions.length < 6)
                    TextButton.icon(
                      onPressed: _addPollOption,
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить вариант'),
                    ),
                ],

                const SizedBox(height: 24),

                // Кнопки действий
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saveDraft,
                        icon: const Icon(Icons.save),
                        label: const Text('Сохранить черновик'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _publishIdea,
                        icon: const Icon(Icons.publish),
                        label: const Text('Опубликовать'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addAttachment() {
    // TODO: Реализовать добавление файлов
    setState(() {
      _attachments.add('Вложение ${_attachments.length + 1}');
    });
  }

  void _addPhoto() {
    // TODO: Реализовать добавление фото
    setState(() {
      _attachments.add('Фото ${_attachments.length + 1}');
    });
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _addPollOption() {
    setState(() {
      _pollOptions.add('');
    });
  }

  void _removePollOption(int index) {
    setState(() {
      _pollOptions.removeAt(index);
    });
  }

  void _saveDraft() {
    // TODO: Реализовать сохранение черновика
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Черновик сохранён')),
    );
  }

  Future<void> _publishIdea() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final idea = Idea(
        text: _textController.text.trim(),
        authorId: 'current_user_id', // TODO: Получить ID текущего пользователя
        authorName:
            'Текущий пользователь', // TODO: Получить имя текущего пользователя
        media: _attachments,
        tags: _tags,
        poll: _isPoll && _pollQuestion.isNotEmpty
            ? {
                'question': _pollQuestion,
                'options':
                    _pollOptions.where((option) => option.isNotEmpty).toList(),
                'votes': {},
              }
            : null,
        city: 'Москва', // TODO: Получить город пользователя
        likesCount: 0,
        commentsCount: 0,
        sharesCount: 0,
        isLiked: false,
        isSaved: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(ideasProvider.notifier).createIdea(idea);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Идея опубликована успешно')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка публикации идеи: $e')),
        );
      }
    }
  }
}
