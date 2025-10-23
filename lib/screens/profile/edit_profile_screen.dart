import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../models/user_profile_enhanced.dart';
import '../../services/user_profile_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/profile/profile_image_picker.dart';
import '../../widgets/profile/social_links_editor.dart';
import '../../widgets/profile/visibility_settings_widget.dart';

/// Экран редактирования профиля
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userProfileService = UserProfileService();
  final _authService = AuthService();

  // Контроллеры полей
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _regionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();

  UserProfileEnhanced? _currentProfile;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _avatarUrl;
  String? _coverUrl;
  String? _videoUrl;
  List<SocialLink> _socialLinks = [];
  ProfileVisibilitySettings? _visibilitySettings;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _regionController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  /// Загрузить профиль пользователя
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _userProfileService.getCurrentUserProfile();
      if (profile != null) {
        _currentProfile = profile;
        _fillFormFields(profile);
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка загрузки профиля: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Заполнить поля формы данными профиля
  void _fillFormFields(UserProfileEnhanced profile) {
    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
    _usernameController.text = profile.username ?? '';
    _bioController.text = profile.bio ?? '';
    _cityController.text = profile.city ?? '';
    _regionController.text = profile.region ?? '';
    _phoneController.text = profile.phone ?? '';
    _websiteController.text = profile.website ?? '';

    setState(() {
      _avatarUrl = profile.avatarUrl;
      _coverUrl = profile.coverUrl;
      _videoUrl = profile.videoPresentation;
      _socialLinks = profile.socialLinks ?? [];
      _visibilitySettings = profile.visibilitySettings;
    });
  }

  /// Сохранить изменения профиля
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        _showErrorSnackBar('Пользователь не авторизован');
        return;
      }

      // Проверяем доступность username
      if (_usernameController.text.isNotEmpty) {
        final isAvailable = await _userProfileService.isUsernameAvailable(
          _usernameController.text,
        );
        if (!isAvailable) {
          _showErrorSnackBar('Этот username уже занят');
          return;
        }
      }

      // Обновляем базовую информацию
      await _userProfileService.updateBasicInfo(
        userId: userId,
        firstName: _firstNameController.text.trim().isEmpty 
            ? null 
            : _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty 
            ? null 
            : _lastNameController.text.trim(),
        username: _usernameController.text.trim().isEmpty 
            ? null 
            : _usernameController.text.trim(),
        bio: _bioController.text.trim().isEmpty 
            ? null 
            : _bioController.text.trim(),
        city: _cityController.text.trim().isEmpty 
            ? null 
            : _cityController.text.trim(),
        region: _regionController.text.trim().isEmpty 
            ? null 
            : _regionController.text.trim(),
        phone: _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty 
            ? null 
            : _websiteController.text.trim(),
      );

      // Обновляем социальные ссылки
      if (_socialLinks.isNotEmpty) {
        final currentProfile = await _userProfileService.getUserProfile(userId);
        if (currentProfile?.socialLinks != null) {
          // Удаляем старые ссылки
          for (final link in currentProfile!.socialLinks!) {
            await _userProfileService.removeSocialLink(userId, link);
          }
        }
        // Добавляем новые ссылки
        for (final link in _socialLinks) {
          await _userProfileService.addSocialLink(userId, link);
        }
      }

      // Обновляем настройки видимости
      if (_visibilitySettings != null) {
        await _userProfileService.updateVisibilitySettings(
          userId,
          _visibilitySettings!,
        );
      }

      _showSuccessSnackBar('Профиль успешно обновлен');
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('Ошибка сохранения: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Загрузить аватарку
  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isLoading = true);

        final userId = _authService.currentUser?.uid;
        if (userId != null) {
          final url = await _userProfileService.uploadAvatar(userId, image);
          if (url != null) {
            setState(() => _avatarUrl = url);
          }
        }

        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка загрузки аватарки: $e');
    }
  }

  /// Загрузить обложку
  Future<void> _pickCover() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isLoading = true);

        final userId = _authService.currentUser?.uid;
        if (userId != null) {
          final url = await _userProfileService.uploadCover(userId, image);
          if (url != null) {
            setState(() => _coverUrl = url);
          }
        }

        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка загрузки обложки: $e');
    }
  }

  /// Загрузить видео-презентацию
  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );

      if (video != null) {
        setState(() => _isLoading = true);

        final userId = _authService.currentUser?.uid;
        if (userId != null) {
          final url = await _userProfileService.uploadVideoPresentation(
            userId,
            video,
          );
          if (url != null) {
            setState(() => _videoUrl = url);
          }
        }

        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка загрузки видео: $e');
    }
  }

  /// Показать настройки видимости
  Future<void> _showVisibilitySettings() async {
    final result = await Navigator.of(context).push<ProfileVisibilitySettings>(
      MaterialPageRoute(
        builder: (context) => VisibilitySettingsWidget(
          initialSettings: _visibilitySettings,
        ),
      ),
    );

    if (result != null) {
      setState(() => _visibilitySettings = result);
    }
  }

  /// Показать редактор социальных ссылок
  Future<void> _showSocialLinksEditor() async {
    final result = await Navigator.of(context).push<List<SocialLink>>(
      MaterialPageRoute(
        builder: (context) => SocialLinksEditor(
          initialLinks: _socialLinks,
        ),
      ),
    );

    if (result != null) {
      setState(() => _socialLinks = result);
    }
  }

  /// Показать предпросмотр профиля
  Future<void> _showProfilePreview() async {
    // TODO: Реализовать предпросмотр профиля
    _showInfoSnackBar('Предпросмотр профиля будет реализован');
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

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Редактирование профиля',
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
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Аватарка и обложка
                _buildImageSection(),
                const SizedBox(height: 24),

                // Основная информация
                _buildBasicInfoSection(),
                const SizedBox(height: 24),

                // Контактная информация
                _buildContactInfoSection(),
                const SizedBox(height: 24),

                // Социальные ссылки
                _buildSocialLinksSection(),
                const SizedBox(height: 24),

                // Настройки видимости
                _buildVisibilitySection(),
                const SizedBox(height: 24),

                // Действия
                _buildActionsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Фотографии',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Аватарка
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Аватарка'),
                      const SizedBox(height: 8),
                      ProfileImagePicker(
                        imageUrl: _avatarUrl,
                        onImagePicked: _pickAvatar,
                        size: 80,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Обложка'),
                      const SizedBox(height: 8),
                      ProfileImagePicker(
                        imageUrl: _coverUrl,
                        onImagePicked: _pickCover,
                        size: 80,
                        isCover: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Видео-презентация
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Видео-презентация (до 30 сек)'),
                const SizedBox(height: 8),
                if (_videoUrl != null)
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_circle_outline, size: 32),
                          const SizedBox(width: 8),
                          const Text('Видео загружено'),
                          const Spacer(),
                          IconButton(
                            onPressed: () => setState(() => _videoUrl = null),
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.video_call),
                    label: const Text('Загрузить видео'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
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
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Имя',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != null && value.trim().isEmpty) {
                        return 'Имя не может быть пустым';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Фамилия',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username (@username)',
                border: OutlineInputBorder(),
                prefixText: '@',
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (value.trim().length < 3) {
                    return 'Username должен содержать минимум 3 символа';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                    return 'Username может содержать только буквы, цифры и _';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Биография',
                border: OutlineInputBorder(),
                hintText: 'Расскажите о себе...',
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Контактная информация',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Город',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _regionController,
                    decoration: const InputDecoration(
                      labelText: 'Регион',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Телефон',
                border: OutlineInputBorder(),
                hintText: '+7 (999) 123-45-67',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Сайт',
                border: OutlineInputBorder(),
                hintText: 'https://example.com',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinksSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Социальные сети',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _showSocialLinksEditor,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            if (_socialLinks.isEmpty)
              const Text(
                'Социальные ссылки не добавлены',
                style: TextStyle(color: Colors.grey),
              )
            else
              ..._socialLinks.map((link) => ListTile(
                leading: Icon(_getSocialIcon(link.platform)),
                title: Text(link.platform),
                subtitle: Text(link.url),
                trailing: IconButton(
                  onPressed: () {
                    setState(() {
                      _socialLinks.remove(link);
                    });
                  },
                  icon: const Icon(Icons.delete),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Настройки видимости',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _showVisibilitySettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('Настроить'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            const Text(
              'Управляйте тем, кто может видеть вашу информацию',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showProfilePreview,
                icon: const Icon(Icons.visibility),
                label: const Text('Предпросмотр профиля'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Сохранение...' : 'Сохранить изменения'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'telegram':
        return Icons.telegram;
      case 'vk':
        return Icons.group;
      case 'youtube':
        return Icons.play_circle;
      case 'twitter':
        return Icons.alternate_email;
      default:
        return Icons.link;
    }
  }
}