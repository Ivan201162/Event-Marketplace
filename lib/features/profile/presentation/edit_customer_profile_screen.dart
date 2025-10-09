import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/navigation/back_utils.dart';
import '../../../widgets/form_validators.dart';
import '../data/models/customer_profile.dart';
import '../data/repositories/customer_profile_repository.dart';

/// Экран редактирования профиля заказчика
class EditCustomerProfileScreen extends ConsumerStatefulWidget {
  const EditCustomerProfileScreen({
    super.key,
    required this.customerId,
    this.isCreating = false,
  });
  final String customerId;
  final bool isCreating;

  @override
  ConsumerState<EditCustomerProfileScreen> createState() =>
      _EditCustomerProfileScreenState();
}

class _EditCustomerProfileScreenState
    extends ConsumerState<EditCustomerProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Контроллеры
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _websiteController = TextEditingController();

  // Состояние
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  File? _selectedImage;
  String? _imageUrl;

  // Репозиторий
  final CustomerProfileRepository _repository = CustomerProfileRepository();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _companyNameController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Загружаем профиль из репозитория
      final profile = await _repository.getProfile(widget.customerId);

      if (profile != null) {
        _nameController.text = profile.name;
        _emailController.text = profile.email;
        _phoneController.text = profile.phone ?? '';
        _bioController.text = profile.bio ?? '';
        _locationController.text = profile.location ?? '';
        _companyNameController.text = profile.companyName ?? '';
        _websiteController.text = profile.website ?? '';
        _imageUrl = profile.avatarUrl;
      } else {
        // Если профиль не найден, оставляем поля пустыми
        // Это нормально для создания нового профиля
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки профиля: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка выбора изображения: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Создаем или обновляем профиль
      final profile = CustomerProfile(
        id: widget.customerId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        bio: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        companyName: _companyNameController.text.trim().isNotEmpty
            ? _companyNameController.text.trim()
            : null,
        website: _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null,
        avatarUrl: _imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Сохраняем профиль
      final success = await _repository.saveProfile(profile);

      if (success) {
        setState(() {
          _successMessage = 'Профиль успешно сохранен';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Профиль успешно сохранен'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } else {
        throw Exception('Не удалось сохранить профиль');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка сохранения: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => BackButtonHandler(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Редактирование профиля'),
            actions: [
              TextButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Сохранить'),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Аватар
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!)
                                    : (_imageUrl != null
                                        ? NetworkImage(_imageUrl!)
                                        : null) as ImageProvider?,
                                child:
                                    _selectedImage == null && _imageUrl == null
                                        ? const Icon(Icons.person, size: 60)
                                        : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: FloatingActionButton.small(
                                  onPressed: _pickImage,
                                  child: const Icon(Icons.camera_alt),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Основная информация
                        Text(
                          'Основная информация',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Имя',
                            border: OutlineInputBorder(),
                          ),
                          validator: FormValidators.required,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: FormValidators.email,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Телефон',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: FormValidators.phone,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _bioController,
                          decoration: const InputDecoration(
                            labelText: 'О себе',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Город',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Дополнительная информация
                        Text(
                          'Дополнительная информация',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _companyNameController,
                          decoration: const InputDecoration(
                            labelText: 'Название компании',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _websiteController,
                          decoration: const InputDecoration(
                            labelText: 'Веб-сайт',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.url,
                          validator: FormValidators.url,
                        ),
                        const SizedBox(height: 32),

                        // Сообщения об ошибках и успехе
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),

                        if (_successMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              border: Border.all(color: Colors.green.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _successMessage!,
                              style: TextStyle(color: Colors.green.shade700),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Кнопка сохранения
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            child: _isSaving
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Сохранение...'),
                                    ],
                                  )
                                : const Text('Сохранить профиль'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      );
}
