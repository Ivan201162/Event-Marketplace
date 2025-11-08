import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Экран создания идеи/поста
class CreateIdeaScreen extends ConsumerStatefulWidget {
  const CreateIdeaScreen({super.key});

  @override
  ConsumerState<CreateIdeaScreen> createState() => _CreateIdeaScreenState();
}

class _CreateIdeaScreenState extends ConsumerState<CreateIdeaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();

  String? _selectedCategory;
  List<File> _selectedImages = [];
  bool _isLoading = false;

  final List<String> _categories = [
    'Фотография',
    'Видеосъемка',
    'Декор',
    'Кейтеринг',
    'Музыка',
    'Анимация',
    'Другое',
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'doc', 'docx', 'mp4', 'mov'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          final newFiles = result.files
              .where((f) => f.path != null)
              .map((f) => File(f.path!))
              .where((file) {
            final size = file.lengthSync();
            if (size > 30 * 1024 * 1024) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Файл ${file.path.split('/').last} превышает 30 МБ')),
              );
              return false;
            }
            return true;
          }).take(10 - _selectedImages.length).toList();
          
          _selectedImages.addAll(newFiles);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выбора файлов: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    await _pickImages(); // Используем общий метод
  }

  Future<void> _createIdea() async {
    if (!_formKey.currentState!.validate()) return;
    
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введите описание идеи')),
        );
      }
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Войдите в аккаунт')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final storage = FirebaseStorage.instance;
      final ideaId = firestore.collection('ideas').doc().id;
      
      // Загружаем файлы
      final files = <Map<String, String>>[];
      for (int i = 0; i < _selectedImages.length; i++) {
        final file = _selectedImages[i];
        final fileName = file.path.split('/').last;
        final filePath = 'uploads/ideas/${currentUser.uid}/$ideaId/$fileName';
        final fileRef = storage.ref().child(filePath);
        
        await fileRef.putFile(file);
        final url = await fileRef.getDownloadURL();
        
        // Определяем тип файла
        String fileType = 'image';
        if (fileName.toLowerCase().endsWith('.mp4') || fileName.toLowerCase().endsWith('.mov')) {
          fileType = 'video';
        } else if (fileName.toLowerCase().endsWith('.pdf')) {
          fileType = 'pdf';
        } else if (fileName.toLowerCase().endsWith('.doc') || fileName.toLowerCase().endsWith('.docx')) {
          fileType = 'doc';
        }
        
        files.add({'url': url, 'type': fileType});
      }

      // Сохраняем в Firestore
      await firestore.collection('ideas').doc(ideaId).set({
        'id': ideaId,
        'authorId': currentUser.uid,
        'text': text,
        'files': files,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugLog("IDEA_PUBLISHED:$ideaId");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Идея создана успешно!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      final errorCode = e is FirebaseException ? e.code : 'unknown';
      debugLog("IDEA_PUBLISH_ERR:$errorCode:$e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания идеи: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать идею'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createIdea,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Опубликовать',
                    style: TextStyle(color: Colors.white),),
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
              // Тип контента
              _buildTypeSelector(),
              const SizedBox(height: 24),

              // Категория
              _buildCategorySelector(),
              const SizedBox(height: 24),

              // Контент
              _buildContentField(),
              const SizedBox(height: 24),

              // Медиа
              _buildMediaSection(),
              const SizedBox(height: 24),

              // Предварительный просмотр
              if (_selectedImages.isNotEmpty) _buildMediaPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Тип контента',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _types.map((type) {
            final isSelected = _selectedType == type;
            return FilterChip(
              label: Text(_getTypeLabel(type)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedType = type;
                  if (type != 'photo' && type != 'video') {
                    _selectedImages.clear();
                  }
                });
              },
              selectedColor: theme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: theme.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Категория',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Выберите категорию',
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(value: category, child: Text(category));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Описание',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),),
        const SizedBox(height: 12),
        TextFormField(
          controller: _contentController,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Расскажите о вашей идее...',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              if (_selectedType == 'text' && _selectedImages.isEmpty) {
                return 'Введите описание или добавьте медиа';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Медиа',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Фото'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.videocam),
                label: const Text('Видео'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Предварительный просмотр',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              final file = _selectedImages[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Image.file(
                        file,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16,),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'text':
        return 'Текст';
      case 'photo':
        return 'Фото';
      case 'video':
        return 'Видео';
      case 'reel':
        return 'Рилс';
      default:
        return type;
    }
  }
}
