import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_profile.dart';
import '../../providers/profile_providers.dart';

/// Экран редактирования профиля
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedAvatar;
  String? _selectedCover;
  bool _isPro = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    final profileState = ref.read(profileProvider);
    profileState.whenData((profile) {
      _displayNameController.text = profile.displayName;
      _usernameController.text = profile.username;
      _bioController.text = profile.bio;
      _cityController.text = profile.city;
      _websiteController.text = profile.website ?? '';
      _phoneController.text = profile.phone ?? '';
      _emailController.text = profile.email;
      _isPro = profile.isPro;
      _isVerified = profile.isVerified;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Сохранить'),
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
              // Аватар и обложка
              _AvatarSection(
                avatarUrl: _selectedAvatar,
                onAvatarTap: _selectAvatar,
              ),

              const SizedBox(height: 16),

              _CoverSection(
                coverUrl: _selectedCover,
                onCoverTap: _selectCover,
              ),

              const SizedBox(height: 24),

              // Основная информация
              const Text(
                'Основная информация',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Имя и фамилия *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите имя и фамилию';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Имя пользователя *',
                  hintText: '@username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите имя пользователя';
                  }
                  if (!value.startsWith('@')) {
                    return 'Имя пользователя должно начинаться с @';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'О себе',
                  hintText: 'Расскажите о себе...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Город',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              // Контактная информация
              const Text(
                'Контактная информация',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите email';
                  }
                  if (!value.contains('@')) {
                    return 'Введите корректный email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Веб-сайт',
                  hintText: 'https://example.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 24),

              // Статус
              const Text(
                'Статус',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Pro-аккаунт'),
                subtitle: const Text('Расширенные возможности'),
                value: _isPro,
                onChanged: (value) => setState(() => _isPro = value),
              ),

              SwitchListTile(
                title: const Text('Верифицированный'),
                subtitle: const Text('Подтверждённый аккаунт'),
                value: _isVerified,
                onChanged: (value) => setState(() => _isVerified = value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectAvatar() {
    // TODO: Реализовать выбор аватара
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Выбор аватара')),
    );
  }

  void _selectCover() {
    // TODO: Реализовать выбор обложки
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Выбор обложки')),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final profile = UserProfile(
        id: 'current_user_id', // TODO: Получить ID текущего пользователя
        displayName: _displayNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        city: _cityController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        socialLinks: {},
        avatarUrl: _selectedAvatar,
        coverUrl: _selectedCover,
        isPro: _isPro,
        isVerified: _isVerified,
        followersCount: 0,
        followingCount: 0,
        postsCount: 0,
        ideasCount: 0,
        requestsCount: 0,
        isFollowing: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(profileProvider.notifier).updateProfile(profile);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль обновлён успешно')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления профиля: $e')),
        );
      }
    }
  }
}

/// Секция аватара
class _AvatarSection extends StatelessWidget {
  final String? avatarUrl;
  final VoidCallback onAvatarTap;

  const _AvatarSection({
    this.avatarUrl,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Аватар',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: onAvatarTap,
            child: CircleAvatar(
              radius: 50,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child:
                  avatarUrl == null ? const Icon(Icons.person, size: 50) : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: onAvatarTap,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Изменить аватар'),
          ),
        ),
      ],
    );
  }
}

/// Секция обложки
class _CoverSection extends StatelessWidget {
  final String? coverUrl;
  final VoidCallback onCoverTap;

  const _CoverSection({
    this.coverUrl,
    required this.onCoverTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Обложка',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onCoverTap,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
              image: coverUrl != null
                  ? DecorationImage(
                      image: NetworkImage(coverUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: coverUrl == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 40),
                        SizedBox(height: 8),
                        Text('Добавить обложку'),
                      ],
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: onCoverTap,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Изменить обложку'),
          ),
        ),
      ],
    );
  }
}
