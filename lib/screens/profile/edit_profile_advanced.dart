import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/auth_providers.dart';
import '../../services/storage_service.dart';

/// Расширенный экран редактирования профиля
class EditProfileAdvanced extends ConsumerStatefulWidget {
  const EditProfileAdvanced({super.key});

  @override
  ConsumerState<EditProfileAdvanced> createState() => _EditProfileAdvancedState();
}

class _EditProfileAdvancedState extends ConsumerState<EditProfileAdvanced> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _instagramController = TextEditingController();
  final _vkController = TextEditingController();
  final _telegramController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _youtubeController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final StorageService _storageService = StorageService();

  File? _avatarImage;
  File? _coverImage;
  String? _selectedRole;
  bool _showCity = true;
  bool _allowMentions = true;
  bool _allowMessages = true;
  bool _isLoading = false;

  final List<String> _roles = [
    'Ведущий',
    'Диджей',
    'Фотограф',
    'Видеограф',
    'Декоратор',
    'Музыкант',
    'Артист',
    'Организатор',
    'Другое',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _vkController.dispose();
    _telegramController.dispose();
    _tiktokController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _cityController.text = data['city'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _websiteController.text = data['website'] ?? '';
          _instagramController.text = data['socialLinks']?['instagram'] ?? '';
          _vkController.text = data['socialLinks']?['vk'] ?? '';
          _telegramController.text = data['socialLinks']?['telegram'] ?? '';
          _tiktokController.text = data['socialLinks']?['tiktok'] ?? '';
          _youtubeController.text = data['socialLinks']?['youtube'] ?? '';
          _selectedRole = data['proCategory'] ?? '';
          _showCity = data['showCity'] ?? true;
          _allowMentions = data['allowMentions'] ?? true;
          _allowMessages = data['allowMessages'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _pickImage(ImageSource source, bool isCover) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: isCover ? 1200 : 800,
        maxHeight: isCover ? 600 : 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (isCover) {
            _coverImage = File(image.path);
          } else {
            _avatarImage = File(image.path);
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showErrorSnackBar('Ошибка при выборе изображения');
    }
  }

  Future<String?> _uploadImage(File image, String type) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      if (type == 'avatar') {
        return await _storageService.uploadUserAvatar(user.uid, image);
      } else if (type == 'cover') {
        return await _storageService.uploadUserCover(user.uid, image);
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      _showErrorSnackBar('Ошибка при загрузке изображения');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('Пользователь не авторизован');
        return;
      }

      // Загружаем изображения
      String? avatarUrl;
      String? coverUrl;

      if (_avatarImage != null) {
        avatarUrl = await _uploadImage(_avatarImage!, 'avatar');
      }

      if (_coverImage != null) {
        coverUrl = await _uploadImage(_coverImage!, 'cover');
      }

      // Подготавливаем данные для сохранения
      final updateData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'city': _cityController.text.trim(),
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
        'website': _websiteController.text.trim(),
        'proCategory': _selectedRole,
        'showCity': _showCity,
        'allowMentions': _allowMentions,
        'allowMessages': _allowMessages,
        'socialLinks': {
          'instagram': _instagramController.text.trim(),
          'vk': _vkController.text.trim(),
          'telegram': _telegramController.text.trim(),
          'tiktok': _tiktokController.text.trim(),
          'youtube': _youtubeController.text.trim(),
        },
        'updatedAt': Timestamp.now(),
      };

      // Добавляем URL изображений если они загружены
      if (avatarUrl != null) {
        updateData['avatarUrl'] = avatarUrl;
      }
      if (coverUrl != null) {
        updateData['coverUrl'] = coverUrl;
      }

      // Сохраняем в Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      _showSuccessSnackBar('Профиль успешно обновлен');
      
      // Возвращаемся назад
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/main');
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      _showErrorSnackBar('Ошибка при сохранении профиля');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/main');
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
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
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
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
              // Обложка и аватар
              _buildImageSection(),
              const SizedBox(height: 24),

              // Основная информация
              _buildSectionTitle('Основная информация'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Имя',
                hint: 'Введите ваше имя',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Имя обязательно';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _cityController,
                label: 'Город',
                hint: 'Введите ваш город',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Город обязателен';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bioController,
                label: 'О себе',
                hint: 'Расскажите о себе',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Телефон',
                hint: '+7 (999) 123-45-67',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // Роль
              _buildSectionTitle('Роль'),
              const SizedBox(height: 16),
              _buildRoleDropdown(),
              const SizedBox(height: 24),

              // Социальные сети
              _buildSectionTitle('Социальные сети'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _websiteController,
                label: 'Веб-сайт',
                hint: 'https://example.com',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _instagramController,
                label: 'Instagram',
                hint: '@username',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _vkController,
                label: 'VKontakte',
                hint: 'vk.com/username',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _telegramController,
                label: 'Telegram',
                hint: '@username',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _tiktokController,
                label: 'TikTok',
                hint: '@username',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _youtubeController,
                label: 'YouTube',
                hint: 'youtube.com/channel/...',
              ),
              const SizedBox(height: 24),

              // Настройки приватности
              _buildSectionTitle('Настройки приватности'),
              const SizedBox(height: 16),
              _buildSwitchTile(
                title: 'Показывать город',
                subtitle: 'Другие пользователи смогут видеть ваш город',
                value: _showCity,
                onChanged: (value) => setState(() => _showCity = value),
              ),
              _buildSwitchTile(
                title: 'Разрешить отметки',
                subtitle: 'Другие пользователи смогут отмечать вас в постах',
                value: _allowMentions,
                onChanged: (value) => setState(() => _allowMentions = value),
              ),
              _buildSwitchTile(
                title: 'Разрешить личные сообщения',
                subtitle: 'Другие пользователи смогут писать вам в личные сообщения',
                value: _allowMessages,
                onChanged: (value) => setState(() => _allowMessages = value),
              ),
              const SizedBox(height: 32),

              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Сохранить изменения',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        // Обложка
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
            image: _coverImage != null
                ? DecorationImage(
                    image: FileImage(_coverImage!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _coverImage == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text('Обложка профиля', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showImagePicker(true),
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Добавить обложку'),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () => _showImagePicker(true),
                        icon: const Icon(Icons.edit, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),

        // Аватар
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: _avatarImage != null
                    ? FileImage(_avatarImage!)
                    : null,
                child: _avatarImage == null
                    ? const Icon(Icons.person, size: 50, color: Colors.grey)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: IconButton(
                  onPressed: () => _showImagePicker(false),
                  icon: const Icon(Icons.camera_alt),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E3A8A),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Роль',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
      ),
      items: _roles.map((role) {
        return DropdownMenuItem(
          value: role,
          child: Text(role),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedRole = value),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF1E3A8A),
    );
  }

  void _showImagePicker(bool isCover) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Камера'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, isCover);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Галерея'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, isCover);
              },
            ),
          ],
        ),
      ),
    );
  }
}
