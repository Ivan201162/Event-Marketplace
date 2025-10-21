import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../models/app_user.dart';
import '../../providers/auth_providers.dart';
import '../../services/image_upload_service.dart';
import '../../widgets/animations/animated_content.dart';

/// Экран добавления новой идеи
class AddIdeaScreen extends ConsumerStatefulWidget {
  const AddIdeaScreen({super.key});

  @override
  ConsumerState<AddIdeaScreen> createState() => _AddIdeaScreenState();
}

class _AddIdeaScreenState extends ConsumerState<AddIdeaScreen>
    with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();
  final _dateController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final ImageUploadService _imageUploadService = ImageUploadService();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _isUploadingImage = false;
  List<String> _selectedImages = [];
  DateTime? _selectedDate;

  final List<String> _popularLocations = [
    'Москва',
    'Санкт-Петербург',
    'Казань',
    'Екатеринбург',
    'Новосибирск',
    'Нижний Новгород',
    'Челябинск',
    'Самара',
    'Омск',
    'Ростов-на-Дону',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() => _isUploadingImage = true);

        for (final image in images) {
          final downloadUrl = await _imageUploadService.uploadIdeaImage(
            File(image.path),
            'temp_${DateTime.now().millisecondsSinceEpoch}',
          );
          _selectedImages.add(downloadUrl);
        }

        setState(() => _isUploadingImage = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Загружено ${images.length} изображений'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error uploading images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки изображений: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = '${picked.day}.${picked.month}.${picked.year}';
      });
    }
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Выберите город',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _popularLocations.length,
                itemBuilder: (context, index) {
                  final location = _popularLocations[index];
                  return ListTile(
                    title: Text(location),
                    onTap: () {
                      _locationController.text = location;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveIdea() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      _showError('Заполните обязательные поля');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        _showError('Пользователь не авторизован');
        return;
      }

      // TODO: Реализовать сохранение идеи в Firestore с информацией об авторе
      // final idea = EventIdea(
      //   id: '',
      //   title: _titleController.text.trim(),
      //   description: _descriptionController.text.trim(),
      //   authorId: currentUser.uid,
      //   authorName: currentUser.name,
      //   authorPhotoUrl: currentUser.avatarUrl,
      //   images: _selectedImages,
      //   budget: _budgetController.text.isNotEmpty ? int.tryParse(_budgetController.text) : null,
      //   location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      //   eventDate: _selectedDate,
      //   createdAt: DateTime.now(),
      //   updatedAt: DateTime.now(),
      // );

      await Future.delayed(const Duration(seconds: 2)); // Имитация загрузки

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Идея успешно добавлена'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      _showError('Ошибка сохранения: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новая идея'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveIdea,
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
      body: AnimatedContent(
        animationType: AnimationType.fadeSlideIn,
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Основная информация
                _buildBasicInfoSection(theme),
                const SizedBox(height: 16),

                // Детали мероприятия
                _buildEventDetailsSection(theme),
                const SizedBox(height: 16),

                // Изображения
                _buildImagesSection(theme),
                const SizedBox(height: 16),

                // Бюджет и дата
                _buildBudgetAndDateSection(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Основная информация',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название идеи *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lightbulb),
                hintText: 'Например: Свадьба в стиле ретро',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                hintText: 'Подробно опишите вашу идею...',
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetailsSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Детали мероприятия',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Место проведения',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_drop_down),
                  onPressed: _showLocationPicker,
                ),
              ),
              readOnly: true,
              onTap: _showLocationPicker,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Изображения',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_isUploadingImage)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_selectedImages.isEmpty)
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.primaryColor, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 40, color: theme.primaryColor),
                      const SizedBox(height: 8),
                      Text(
                        'Добавить изображения',
                        style: TextStyle(color: theme.primaryColor),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _selectedImages.length) {
                          return GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.primaryColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, color: theme.primaryColor),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Добавить',
                                    style: TextStyle(color: theme.primaryColor, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _selectedImages[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Добавить еще'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetAndDateSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Бюджет и дата',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _budgetController,
              decoration: const InputDecoration(
                labelText: 'Бюджет (руб.)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                hintText: 'Например: 50000',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Желаемая дата',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
                hintText: 'Выберите дату',
              ),
              readOnly: true,
              onTap: _selectDate,
            ),
          ],
        ),
      ),
    );
  }
}
