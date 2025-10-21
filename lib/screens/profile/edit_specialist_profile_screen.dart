import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/app_user.dart';
import '../../providers/auth_providers.dart';
import '../../services/auth_service.dart';

class EditSpecialistProfileScreen extends ConsumerStatefulWidget {
  const EditSpecialistProfileScreen({super.key});

  @override
  ConsumerState<EditSpecialistProfileScreen> createState() => _EditSpecialistProfileScreenState();
}

class _EditSpecialistProfileScreenState extends ConsumerState<EditSpecialistProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  String? _selectedSpecialistType;
  String? _avatarUrl;
  bool _isLoading = false;
  
  final List<String> _specialistTypes = [
    'Фотограф',
    'Видеограф', 
    'Ведущий',
    'Диджей',
    'Декоратор',
    'Флорист',
    'Кейтеринг',
    'Другое'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      _nameController.text = user.name ?? '';
      _cityController.text = user.city ?? '';
      _descriptionController.text = user.bio ?? '';
      _priceController.text = user.hourlyRate?.toString() ?? '';
      _selectedSpecialistType = user.specialistType;
      _avatarUrl = user.avatarUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final user = ref.read(currentUserProvider).value;
        if (user != null) {
          final ref = FirebaseStorage.instance.ref().child('avatars/${user.uid}');
          await ref.putFile(image as dynamic);
          final url = await ref.getDownloadURL();
          
          setState(() {
            _avatarUrl = url;
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка загрузки изображения: $e')),
          );
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;
      
      final authService = ref.read(authServiceProvider);
      
      await authService.updateUserProfile(
        name: _nameController.text.trim(),
        city: _cityController.text.trim(),
        bio: _descriptionController.text.trim(),
        specialistType: _selectedSpecialistType,
        hourlyRate: double.tryParse(_priceController.text),
        avatarUrl: _avatarUrl,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль успешно обновлен')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование профиля'),
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
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _avatarUrl != null 
                        ? NetworkImage(_avatarUrl!)
                        : null,
                      child: _avatarUrl == null 
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
              const SizedBox(height: 32),
              
              // Имя
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
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
              
              // Тип специалиста
              DropdownButtonFormField<String>(
                value: _selectedSpecialistType,
                decoration: const InputDecoration(
                  labelText: 'Тип специалиста',
                  border: OutlineInputBorder(),
                ),
                items: _specialistTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSpecialistType = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Выберите тип специалиста';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Описание
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
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
              
              // Цена за час
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Цена за час (₽)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите цену за час';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Введите корректную цену';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
