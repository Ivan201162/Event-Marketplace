import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/specialist_profile.dart';
import '../models/user.dart';
import '../providers/auth_providers.dart';
import '../services/profile_service.dart';

/// Экран регистрации специалиста с выбором категории
class SpecialistRegistrationScreen extends ConsumerStatefulWidget {
  const SpecialistRegistrationScreen({super.key});

  @override
  ConsumerState<SpecialistRegistrationScreen> createState() => _SpecialistRegistrationScreenState();
}

class _SpecialistRegistrationScreenState extends ConsumerState<SpecialistRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  final List<SpecialistCategory> _selectedCategories = [];
  int _experienceYears = 0;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Регистрация специалиста'),
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text(
              'Создание профиля специалиста',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Заполните информацию о себе и своих услугах',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Основная информация
            _buildBasicInfoSection(),
            const SizedBox(height: 24),

            // Выбор категорий
            _buildCategorySelectionSection(),
            const SizedBox(height: 24),

            // Опыт и ценообразование
            _buildExperienceAndPricingSection(),
            const SizedBox(height: 24),

            // Контактная информация
            _buildContactInfoSection(),
            const SizedBox(height: 24),

            // Ошибка
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Кнопка регистрации
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegistration,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Создать профиль'),
              ),
            ),
            const SizedBox(height: 16),

            // Ссылка на вход
            Center(
              child: TextButton(
                onPressed: () => context.go('/auth'),
                child: const Text('Уже есть аккаунт? Войти'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildBasicInfoSection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Основная информация',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Имя
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Имя или название компании',
              hintText: 'Введите ваше имя',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Пожалуйста, введите имя';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'example@email.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Пожалуйста, введите email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Пожалуйста, введите корректный email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Биография
          TextFormField(
            controller: _bioController,
            decoration: const InputDecoration(
              labelText: 'О себе',
              hintText: 'Расскажите о своем опыте и услугах',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Пожалуйста, расскажите о себе';
              }
              return null;
            },
          ),
        ],
      ),
    ),
  );

  Widget _buildCategorySelectionSection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Категории услуг',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите категории, в которых вы работаете',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SpecialistCategory.values.map((category) {
              final isSelected = _selectedCategories.contains(category);
              return FilterChip(
                label: Text(_getCategoryDisplayName(category)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(category);
                    } else {
                      _selectedCategories.remove(category);
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (_selectedCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Пожалуйста, выберите хотя бы одну категорию',
                style: TextStyle(color: Colors.red[600], fontSize: 12),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _buildExperienceAndPricingSection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Опыт и ценообразование',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Опыт работы
          Text(
            'Опыт работы: $_experienceYears лет',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _experienceYears.toDouble(),
            max: 50,
            divisions: 50,
            label: '$_experienceYears лет',
            onChanged: (value) {
              setState(() {
                _experienceYears = value.round();
              });
            },
          ),
          const SizedBox(height: 16),

          // Почасовая ставка
          TextFormField(
            controller: _hourlyRateController,
            decoration: const InputDecoration(
              labelText: 'Почасовая ставка (₽)',
              hintText: '5000',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Пожалуйста, укажите почасовую ставку';
              }
              final rate = double.tryParse(value);
              if (rate == null || rate <= 0) {
                return 'Пожалуйста, введите корректную ставку';
              }
              return null;
            },
          ),
        ],
      ),
    ),
  );

  Widget _buildContactInfoSection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Контактная информация',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Телефон
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Телефон',
              hintText: '+7 (999) 123-45-67',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Пожалуйста, введите телефон';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Локация
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Город',
              hintText: 'Москва',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Пожалуйста, укажите город';
              }
              return null;
            },
          ),
        ],
      ),
    ),
  );

  String _getCategoryDisplayName(SpecialistCategory category) {
    switch (category) {
      case SpecialistCategory.host:
        return 'Ведущий';
      case SpecialistCategory.photographer:
        return 'Фотограф';
      case SpecialistCategory.animator:
        return 'Аниматор';
      case SpecialistCategory.dj:
        return 'Диджей';
      case SpecialistCategory.decorator:
        return 'Оформитель';
      case SpecialistCategory.catering:
        return 'Кейтеринг';
      case SpecialistCategory.cleaning:
        return 'Клининг';
      case SpecialistCategory.equipment:
        return 'Аренда свет/звук';
      case SpecialistCategory.clothing:
        return 'Платья/костюмы';
      case SpecialistCategory.fireShow:
        return 'Фаер-шоу';
      case SpecialistCategory.fireworks:
        return 'Салюты';
      case SpecialistCategory.lightShow:
        return 'Световые шоу';
      case SpecialistCategory.florist:
        return 'Флорист';
      case SpecialistCategory.coverBand:
        return 'Кавер-группа';
      case SpecialistCategory.teamBuilding:
        return 'Тимбилдинг';
      case SpecialistCategory.videographer:
        return 'Видеограф';
      case SpecialistCategory.musician:
        return 'Музыкант';
      case SpecialistCategory.caterer:
        return 'Кейтеринг';
      case SpecialistCategory.security:
        return 'Охрана';
      case SpecialistCategory.technician:
        return 'Техник';
      case SpecialistCategory.lighting:
        return 'Световое оформление';
      case SpecialistCategory.sound:
        return 'Звуковое оборудование';
      case SpecialistCategory.costume:
        return 'Платья/костюмы';
      case SpecialistCategory.rental:
        return 'Аренда оборудования';
      case SpecialistCategory.makeup:
        return 'Визажист';
      case SpecialistCategory.hairstylist:
        return 'Парикмахер';
      case SpecialistCategory.stylist:
        return 'Стилист';
      case SpecialistCategory.choreographer:
        return 'Хореограф';
      case SpecialistCategory.dance:
        return 'Танцы';
      case SpecialistCategory.magic:
        return 'Фокусы/иллюзионист';
      case SpecialistCategory.clown:
        return 'Клоун';
      case SpecialistCategory.balloon:
        return 'Аэродизайн';
      case SpecialistCategory.cake:
        return 'Торты/кондитер';
      case SpecialistCategory.transport:
        return 'Транспорт';
      case SpecialistCategory.venue:
        return 'Площадки';
      case SpecialistCategory.other:
        return 'Другое';
    }
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategories.isEmpty) {
      setState(() {
        _errorMessage = 'Пожалуйста, выберите хотя бы одну категорию';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final profileService = ref.read(profileServiceProvider);

      // Создаем пользователя
      final user = await authService.registerWithEmail(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: 'temp_password', // Временный пароль, будет изменен
        role: UserRole.specialist,
      );

      // Создаем профиль специалиста
      final profile = SpecialistProfile(
        userId: user.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        bio: _bioController.text.trim(),
        categories: _selectedCategories,
        experienceYears: _experienceYears,
        hourlyRate: double.parse(_hourlyRateController.text.trim()),
        phoneNumber: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await profileService.createOrUpdateSpecialistProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Профиль специалиста создан успешно!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
