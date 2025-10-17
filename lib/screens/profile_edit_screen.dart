import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../models/social_models.dart';
import '../services/supabase_service.dart';

/// Экран редактирования профиля
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _skillsController = TextEditingController();

  Profile? _currentProfile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  File? _selectedImage;
  List<String> _skills = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser != null) {
        final profile = await SupabaseService.getProfile(currentUser.id);
        setState(() {
          _currentProfile = profile;
          _isLoading = false;
        });

        if (profile != null) {
          _nameController.text = profile.name;
          _bioController.text = profile.bio ?? '';
          _cityController.text = profile.city ?? '';
          _skills = List.from(profile.skills);
          _updateSkillsText();
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _updateSkillsText() {
    _skillsController.text = _skills.join(', ');
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка выбора изображения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      String? avatarUrl;

      // Загружаем аватар, если выбран новый
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        avatarUrl = await SupabaseService.uploadAvatar(
          _selectedImage!.path,
          bytes,
        );
      }

      // Обновляем профиль
      final success = await SupabaseService.updateProfile(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        skills: _skills,
        avatarUrl: avatarUrl,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Профиль обновлен успешно!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        throw Exception('Не удалось обновить профиль');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления профиля: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _addSkill() {
    final skill = _skillsController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillsController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Сохранить',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки профиля',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCurrentProfile,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Аватар
            _buildAvatarSection(),
            const SizedBox(height: 32),

            // Основная информация
            _buildBasicInfoSection(),
            const SizedBox(height: 24),

            // Навыки
            _buildSkillsSection(),
            const SizedBox(height: 24),

            // Дополнительная информация
            _buildAdditionalInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final theme = Theme.of(context);

    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : (_currentProfile?.avatarUrl != null
                      ? NetworkImage(_currentProfile!.avatarUrl!)
                      : null),
              child: _selectedImage == null && _currentProfile?.avatarUrl == null
                  ? Icon(
                      Icons.person,
                      size: 60,
                      color: theme.primaryColor,
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: _pickImage,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Нажмите на камеру, чтобы изменить фото',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Основная информация',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Имя
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Имя *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Введите имя';
            }
            if (value.trim().length < 2) {
              return 'Имя должно содержать минимум 2 символа';
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
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
            hintText: 'В каком городе вы работаете?',
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Навыки',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Поле для добавления навыков
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: 'Добавить навык',
                  border: OutlineInputBorder(),
                  hintText: 'Например: Фотография, Видеосъемка',
                ),
                onFieldSubmitted: (_) => _addSkill(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addSkill,
              child: const Text('Добавить'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Список навыков
        if (_skills.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills.map((skill) {
              return Chip(
                label: Text(skill),
                onDeleted: () => _removeSkill(skill),
                deleteIcon: const Icon(Icons.close, size: 18),
              );
            }).toList(),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Добавьте ваши навыки и специализации',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Дополнительная информация',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Биография
        TextFormField(
          controller: _bioController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'О себе',
            border: OutlineInputBorder(),
            hintText: 'Расскажите о себе, своем опыте и достижениях...',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
