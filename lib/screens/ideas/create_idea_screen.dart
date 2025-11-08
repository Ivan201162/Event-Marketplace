import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Экран создания идеи
class CreateIdeaScreen extends StatefulWidget {
  const CreateIdeaScreen({super.key});

  @override
  State<CreateIdeaScreen> createState() => _CreateIdeaScreenState();
}

class _CreateIdeaScreenState extends State<CreateIdeaScreen> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final List<File> _selectedFiles = [];
  final List<String> _mediaUrls = [];
  bool _isUploading = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        final files = result.files
            .where((f) => f.path != null)
            .map((f) => File(f.path!))
            .toList();

        if (_selectedFiles.length + files.length > 10) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Можно добавить до 10 файлов')),
            );
          }
          return;
        }

        setState(() {
          _selectedFiles.addAll(files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора файлов: $e')),
        );
      }
    }
  }

  Future<void> _uploadFiles(String ideaId) async {
    if (_selectedFiles.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final storage = FirebaseStorage.instance;
      final urls = <String>[];

      for (final file in _selectedFiles) {
        final fileName = file.path.split('/').last;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final ref = storage.ref().child('uploads/ideas/${user.uid}/$ideaId/${timestamp}_$fileName');

        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        urls.add(url);
      }

      setState(() {
        _mediaUrls.addAll(urls);
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      throw Exception('Ошибка загрузки файлов: $e');
    }
  }

  Future<void> _publishIdea() async {
    try {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      final title = _titleController.text.trim();
      final text = _textController.text.trim();

      if (title.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Введите заголовок')),
          );
        }
        return;
      }

      if (text.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Введите текст идеи')),
          );
        }
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugLog("IDEA_ERR:auth_required");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Войдите в аккаунт')),
          );
        }
        return;
      }

      setState(() => _isSubmitting = true);

      final ideaRef = FirebaseFirestore.instance.collection('ideas').doc();
      final ideaId = ideaRef.id;

      // Загружаем файлы если есть
      if (_selectedFiles.isNotEmpty) {
        await _uploadFiles(ideaId);
      }

      await ideaRef.set({
        'authorId': user.uid,
        'title': title,
        'text': text,
        'mediaUrls': _mediaUrls,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugLog("IDEA_PUBLISHED:$ideaId");
      
      // Firebase Analytics
      try {
        await FirebaseAnalytics.instance.logEvent(
          name: 'publish_idea',
          parameters: {'idea_id': ideaId},
        );
      } catch (e) {
        debugPrint('Analytics error: $e');
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Идея опубликована')),
        );
      }
    } catch (e) {
      final errorCode = e is FirebaseException ? e.code : 'unknown';
      debugLog("IDEA_ERR:$errorCode");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка публикации: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      if (index < _mediaUrls.length) {
        _mediaUrls.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Создать идею'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (_titleController.text.isNotEmpty && _textController.text.isNotEmpty)
              TextButton(
                onPressed: _isSubmitting ? null : _publishIdea,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Опубликовать'),
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
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Заголовок *',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите заголовок';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: 'Текст идеи *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 10,
                  maxLength: 2000,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите текст идеи';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickFiles,
                  icon: const Icon(Icons.attach_file),
                  label: Text(_selectedFiles.isEmpty
                      ? 'Добавить медиа (до 10 файлов)'
                      : 'Добавлено: ${_selectedFiles.length}'),
                ),
                if (_selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_selectedFiles.length, (index) {
                      return Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.insert_drive_file),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              onPressed: () => _removeFile(index),
                              icon: const Icon(Icons.close, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
                if (_isUploading) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
