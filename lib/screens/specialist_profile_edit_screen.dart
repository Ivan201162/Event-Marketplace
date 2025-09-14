import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist_profile.dart';
import '../providers/profile_providers.dart';
import '../providers/auth_providers.dart';

class SpecialistProfileEditScreen extends ConsumerStatefulWidget {
  const SpecialistProfileEditScreen({super.key});

  @override
  ConsumerState<SpecialistProfileEditScreen> createState() => _SpecialistProfileEditScreenState();
}

class _SpecialistProfileEditScreenState extends ConsumerState<SpecialistProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _vkController = TextEditingController();
  final _instagramController = TextEditingController();
  final _telegramController = TextEditingController();
  
  List<SpecialistCategory> _selectedCategories = [];
  int _experienceYears = 0;
  List<String> _services = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _hourlyRateController.dispose();
    _vkController.dispose();
    _instagramController.dispose();
    _telegramController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser != null) {
      ref.read(specialistProfileEditProvider.notifier).loadProfile(currentUser.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(specialistProfileEditProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    // Инициализация полей при загрузке профиля
    if (editState.profile != null && !editState.isDirty) {
      final profile = editState.profile!;
      _bioController.text = profile.bio ?? '';
      _phoneController.text = profile.phoneNumber ?? '';
      _locationController.text = profile.location ?? '';
      _hourlyRateController.text = profile.hourlyRate.toString();
      _vkController.text = profile.socialLinks['vk'] ?? '';
      _instagramController.text = profile.socialLinks['instagram'] ?? '';
      _telegramController.text = profile.socialLinks['telegram'] ?? '';
      _selectedCategories = List.from(profile.categories);
      _experienceYears = profile.experienceYears;
      _services = List.from(profile.services);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование профиля'),
        actions: [
          if (editState.isDirty)
            TextButton(
              onPressed: editState.isLoading ? null : () {
                ref.read(specialistProfileEditProvider.notifier).saveProfile();
              },
              child: editState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Сохранить'),
            ),
        ],
      ),
      body: editState.isLoading && editState.profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Фото профиля
                    _buildProfilePhoto(),
                    const SizedBox(height: 24),

                    // Основная информация
                    _buildBasicInfo(),
                    const SizedBox(height: 24),

                    // Категории и опыт
                    _buildCategoriesAndExperience(),
                    const SizedBox(height: 24),

                    // Ценообразование
                    _buildPricing(),
                    const SizedBox(height: 24),

                    // Социальные сети
                    _buildSocialLinks(),
                    const SizedBox(height: 24),

                    // Услуги
                    _buildServices(),
                    const SizedBox(height: 24),

                    // Портфолио
                    _buildPortfolio(),
                    const SizedBox(height: 24),

                    // Ошибка
                    if (editState.errorMessage != null)
                      _buildErrorMessage(editState.errorMessage!),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePhoto() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: const Icon(
              Icons.person,
              size: 60,
              color: Colors.grey,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: () {
                  // TODO: Реализовать загрузку фото
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Загрузка фото будет реализована позже')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Основная информация',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
              onChanged: (value) {
                ref.read(specialistProfileEditProvider.notifier).updateField(bio: value);
              },
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
              onChanged: (value) {
                ref.read(specialistProfileEditProvider.notifier).updateField(phoneNumber: value);
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
              onChanged: (value) {
                ref.read(specialistProfileEditProvider.notifier).updateField(location: value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesAndExperience() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Категории и опыт',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Категории
            Text(
              'Категории услуг',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
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
                    ref.read(specialistProfileEditProvider.notifier).updateField(
                      categories: _selectedCategories,
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Опыт работы
            Text(
              'Опыт работы (лет)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _experienceYears.toDouble(),
              min: 0,
              max: 50,
              divisions: 50,
              label: '$_experienceYears лет',
              onChanged: (value) {
                setState(() {
                  _experienceYears = value.round();
                });
                ref.read(specialistProfileEditProvider.notifier).updateField(
                  experienceYears: _experienceYears,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricing() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ценообразование',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _hourlyRateController,
              decoration: const InputDecoration(
                labelText: 'Почасовая ставка (₽)',
                hintText: '5000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final rate = double.tryParse(value) ?? 0.0;
                ref.read(specialistProfileEditProvider.notifier).updateField(
                  hourlyRate: rate,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinks() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Социальные сети',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // ВКонтакте
            TextFormField(
              controller: _vkController,
              decoration: const InputDecoration(
                labelText: 'ВКонтакте',
                hintText: 'https://vk.com/username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              onChanged: (value) {
                final socialLinks = <String, String>{};
                if (value.isNotEmpty) socialLinks['vk'] = value;
                ref.read(specialistProfileEditProvider.notifier).updateField(
                  socialLinks: socialLinks,
                );
              },
            ),
            const SizedBox(height: 16),

            // Instagram
            TextFormField(
              controller: _instagramController,
              decoration: const InputDecoration(
                labelText: 'Instagram',
                hintText: 'https://instagram.com/username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              onChanged: (value) {
                final socialLinks = <String, String>{};
                if (value.isNotEmpty) socialLinks['instagram'] = value;
                ref.read(specialistProfileEditProvider.notifier).updateField(
                  socialLinks: socialLinks,
                );
              },
            ),
            const SizedBox(height: 16),

            // Telegram
            TextFormField(
              controller: _telegramController,
              decoration: const InputDecoration(
                labelText: 'Telegram',
                hintText: '@username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              onChanged: (value) {
                final socialLinks = <String, String>{};
                if (value.isNotEmpty) socialLinks['telegram'] = value;
                ref.read(specialistProfileEditProvider.notifier).updateField(
                  socialLinks: socialLinks,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServices() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Услуги',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _showAddServiceDialog();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_services.isEmpty)
              const Text('Добавьте услуги, которые вы предоставляете')
            else
              Wrap(
                spacing: 8,
                children: _services.map((service) {
                  return Chip(
                    label: Text(service),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _services.remove(service);
                      });
                      ref.read(specialistProfileEditProvider.notifier).updateField(
                        services: _services,
                      );
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolio() {
    final editState = ref.watch(specialistProfileEditProvider);
    final portfolio = editState.profile?.portfolio ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Портфолио',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _showAddPortfolioDialog();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (portfolio.isEmpty)
              const Text('Добавьте работы в портфолио')
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: portfolio.length,
                itemBuilder: (context, index) {
                  final item = portfolio[index];
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.withOpacity(0.1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.type == 'photo' ? Icons.image :
                          item.type == 'video' ? Icons.videocam : Icons.description,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.title ?? 'Без названия',
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 16),
                          onPressed: () {
                            ref.read(specialistProfileEditProvider.notifier)
                                .removePortfolioItem(item.id);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить услугу'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Название услуги',
            hintText: 'Например: Фотосъемка свадьбы',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _services.add(controller.text);
                });
                ref.read(specialistProfileEditProvider.notifier).updateField(
                  services: _services,
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showAddPortfolioDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить в портфолио'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Фото'),
              onTap: () {
                Navigator.of(context).pop();
                _addPortfolioItem('photo');
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Видео'),
              onTap: () {
                Navigator.of(context).pop();
                _addPortfolioItem('video');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Документ'),
              onTap: () {
                Navigator.of(context).pop();
                _addPortfolioItem('document');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _addPortfolioItem(String type) {
    // TODO: Реализовать загрузку файлов
    final item = PortfolioItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      url: 'https://example.com/portfolio/${type}_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Новая работа',
      description: 'Описание работы',
      createdAt: DateTime.now(),
    );
    
    ref.read(specialistProfileEditProvider.notifier).addPortfolioItem(item);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Загрузка файлов будет реализована позже')),
    );
  }

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
    }
  }
}
