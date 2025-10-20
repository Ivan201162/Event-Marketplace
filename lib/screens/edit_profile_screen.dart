import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../models/social_models.dart';
import '../providers/auth_providers.dart';

/// Экран редактирования профиля
class EditProfileScreen extends ConsumerStatefulWidget {
  final Profile? initialProfile;

  const EditProfileScreen({
    super.key,
    this.initialProfile,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();

  File? _selectedAvatar;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.initialProfile != null) {
      _nameController.text = widget.initialProfile!.name ?? '';
      _cityController.text = widget.initialProfile!.city ?? '';
      _bioController.text = widget.initialProfile!.bio ?? '';
      _skillsController.text = widget.initialProfile!.skills.join(', ') ?? '';
    } else {
      // Инициализируем поля данными из Firebase Auth
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentUser = ref.read(currentUserProvider).value;
        if (currentUser != null) {
          _nameController.text = currentUser.displayName ?? '';
          _cityController.text = currentUser.city ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Сохранить'),
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
              // Аватар
              _buildAvatarSection(),
              const SizedBox(height: 24),

              // Имя
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  hintText: 'Введите ваше имя',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите имя';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Город
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Город',
                  hintText: 'Введите ваш город',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите город';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Био
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'О себе',
                  hintText: 'Расскажите о себе...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // Навыки
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: 'Навыки',
                  hintText: 'Фотограф, Видеограф, DJ (через запятую)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Сохраняем...'),
                          ],
                        )
                      : const Text('Сохранить изменения'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                backgroundImage: _selectedAvatar != null
                    ? FileImage(_selectedAvatar!)
                    : (widget.initialProfile?.avatarUrl != null
                        ? NetworkImage(widget.initialProfile!.avatarUrl!)
                        : null) as ImageProvider?,
                child: _selectedAvatar == null && widget.initialProfile?.avatarUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    onPressed: _pickAvatar,
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _pickAvatar,
            child: const Text('Изменить фото'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedAvatar = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при выборе фото: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Загружаем аватар, если выбран новый
      final String? avatarUrl = widget.initialProfile?.avatarUrl;
      if (_selectedAvatar != null) {
        setState(() {
          _isUploading = true;
        });

        // TODO: Реализовать загрузку аватара в Supabase Storage
        // avatarUrl = await SupabaseService.uploadAvatar(_selectedAvatar!);

        setState(() {
          _isUploading = false;
        });
      }

      // Парсим навыки
      final skills = _skillsController.text
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty)
          .toList();

      // Создаем обновленный профиль
      final updatedProfile = Profile(
        id: currentUser.uid,
        username: widget.initialProfile?.username ?? currentUser.email.split('@').first ?? 'user',
        name: _nameController.text.trim(),
        avatarUrl: avatarUrl,
        city: _cityController.text.trim(),
        bio: _bioController.text.trim(),
        skills: skills,
        createdAt: widget.initialProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Сохраняем профиль
      // TODO: Реализовать сохранение профиля в Supabase
      // await SupabaseService.updateProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль успешно обновлен!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при сохранении: $e')),
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
}
