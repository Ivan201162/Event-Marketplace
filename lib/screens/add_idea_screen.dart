import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/auth_providers.dart';
import '../services/ideas_service.dart';

class AddIdeaScreen extends ConsumerStatefulWidget {
  const AddIdeaScreen({super.key});

  @override
  ConsumerState<AddIdeaScreen> createState() => _AddIdeaScreenState();
}

class _AddIdeaScreenState extends ConsumerState<AddIdeaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _tagsController = TextEditingController();

  final IdeasService _ideasService = IdeasService();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedCategory = 'Все';
  String _selectedPriceCurrency = 'RUB';
  bool _isVideo = false;
  File? _selectedFile;
  bool _isLoading = false;

  final List<String> _categories = [
    'Все',
    'Свадьба',
    'День рождения',
    'Корпоратив',
    'Детский праздник',
    'Другое',
  ];
  final List<String> _currencies = ['RUB', 'USD', 'EUR'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить идею'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitIdea,
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
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(
                child: Text('Войдите в аккаунт, чтобы добавить идею'));
          }

          return _buildForm(user);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ошибка: $error')),
      ),
    );
  }

  Widget _buildForm(user) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Выбор медиа файла
              _buildMediaSelector(),
              const SizedBox(height: 24),

              // Заголовок
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Заголовок *',
                  hintText: 'Краткое описание идеи',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите заголовок';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Описание
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание *',
                  hintText: 'Подробное описание идеи',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите описание';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Категория
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Категория *',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((category) => DropdownMenuItem(
                        value: category, child: Text(category)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
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
              ),
              const SizedBox(height: 16),

              // Местоположение
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Местоположение',
                  hintText: 'Город или адрес',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Цена и валюта
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Цена',
                        hintText: '0',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedPriceCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Валюта',
                        border: OutlineInputBorder(),
                      ),
                      items: _currencies
                          .map((currency) => DropdownMenuItem(
                              value: currency, child: Text(currency)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPriceCurrency = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Длительность (для видео)
              if (_isVideo) ...[
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Длительность (минуты)',
                    hintText: '0',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
              ],

              // Кнопка отправки
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitIdea,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 16),
                            Text('Публикация...'),
                          ],
                        )
                      : const Text('Опубликовать идею'),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildMediaSelector() => Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _selectedFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Выберите фото или видео'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickMedia(false),
                        icon: const Icon(Icons.photo),
                        label: const Text('Фото'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _pickMedia(true),
                        icon: const Icon(Icons.videocam),
                        label: const Text('Видео'),
                      ),
                    ],
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _isVideo
                        ? Container(
                            color: Colors.black,
                            child: const Center(
                              child: Icon(Icons.play_circle_fill,
                                  color: Colors.white, size: 60),
                            ),
                          )
                        : Image.file(
                            _selectedFile!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                            _isVideo = false;
                          });
                        },
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ),
                  if (_isVideo)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ВИДЕО',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      );

  Future<void> _pickMedia(bool isVideo) async {
    try {
      final file = isVideo
          ? await _imagePicker.pickVideo(source: ImageSource.gallery)
          : await _imagePicker.pickImage(source: ImageSource.gallery);

      if (file != null) {
        setState(() {
          _selectedFile = File(file.path);
          _isVideo = isVideo;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка выбора файла: $e')));
    }
  }

  Future<void> _submitIdea() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите фото или видео')));
      return;
    }

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          const SnackBar(content: Text('Пользователь не авторизован')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final ideaId = await _ideasService.createIdea(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        authorId: currentUser.id,
        authorName: currentUser.name ?? 'Пользователь',
        authorAvatar: currentUser.avatar,
        mediaFile: _selectedFile!,
        isVideo: _isVideo,
        tags: tags,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        price: _priceController.text.trim().isEmpty
            ? null
            : double.tryParse(_priceController.text.trim()),
        priceCurrency: _priceController.text.trim().isEmpty
            ? null
            : _selectedPriceCurrency,
        duration: _durationController.text.trim().isEmpty
            ? null
            : int.tryParse(_durationController.text.trim()),
      );

      if (ideaId != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('Идея успешно опубликована!')));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка публикации идеи')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
