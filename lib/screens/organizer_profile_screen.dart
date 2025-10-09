import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/organizer_profile.dart';
import '../services/organizer_service.dart';
import '../widgets/common_widgets.dart';

/// Экран профиля организатора
class OrganizerProfileScreen extends ConsumerStatefulWidget {
  const OrganizerProfileScreen({
    super.key,
    this.organizerId,
    this.isEditMode = false,
  });

  final String? organizerId;
  final bool isEditMode;

  @override
  ConsumerState<OrganizerProfileScreen> createState() =>
      _OrganizerProfileScreenState();
}

class _OrganizerProfileScreenState
    extends ConsumerState<OrganizerProfileScreen> {
  final OrganizerService _organizerService = OrganizerService();
  OrganizerProfile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // Контроллеры для редактирования
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _locationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _responseTimeController = TextEditingController();
  final _minBudgetController = TextEditingController();
  final _maxBudgetController = TextEditingController();

  List<String> _selectedCategories = [];
  List<String> _selectedSpecializations = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    _experienceController.dispose();
    _responseTimeController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (widget.organizerId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final profile =
          await _organizerService.getOrganizerProfile(widget.organizerId!);
      if (profile != null) {
        setState(() {
          _profile = profile;
          _populateControllers();
        });
      }
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка загрузки профиля: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateControllers() {
    if (_profile == null) return;

    _nameController.text = _profile!.name;
    _descriptionController.text = _profile!.description ?? '';
    _phoneController.text = _profile!.phone ?? '';
    _emailController.text = _profile!.email ?? '';
    _websiteController.text = _profile!.website ?? '';
    _locationController.text = _profile!.location ?? '';
    _experienceController.text = _profile!.experienceYears.toString();
    _responseTimeController.text = _profile!.responseTime ?? '';
    _minBudgetController.text = _profile!.minBudget?.toString() ?? '';
    _maxBudgetController.text = _profile!.maxBudget?.toString() ?? '';

    _selectedCategories = List.from(_profile!.categories);
    _selectedSpecializations = List.from(_profile!.specializations);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_profile == null) return;

    try {
      final updatedProfile = _profile!.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        experienceYears: int.tryParse(_experienceController.text) ?? 0,
        responseTime: _responseTimeController.text.trim().isEmpty
            ? null
            : _responseTimeController.text.trim(),
        minBudget: double.tryParse(_minBudgetController.text),
        maxBudget: double.tryParse(_maxBudgetController.text),
        categories: _selectedCategories,
        specializations: _selectedSpecializations,
        updatedAt: DateTime.now(),
      );

      await _organizerService.updateOrganizerProfile(updatedProfile);

      setState(() {
        _profile = updatedProfile;
        _isEditing = false;
      });

      _showSuccessSnackBar('Профиль успешно обновлен');
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка сохранения профиля: $e');
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Профиль организатора')),
        body: const Center(
          child: Text('Профиль не найден'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Редактирование профиля' : 'Профиль организатора',
        ),
        actions: [
          if (!_isEditing && widget.isEditMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing) ...[
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _populateControllers();
                });
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Сохранить'),
            ),
          ],
        ],
      ),
      body: _isEditing ? _buildEditForm() : _buildProfileView(),
    );
  }

  Widget _buildProfileView() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок профиля
            _buildProfileHeader(),
            const SizedBox(height: 24),

            // Основная информация
            _buildBasicInfo(),
            const SizedBox(height: 24),

            // Категории и специализации
            _buildCategoriesAndSpecializations(),
            const SizedBox(height: 24),

            // Контактная информация
            _buildContactInfo(),
            const SizedBox(height: 24),

            // Портфолио
            _buildPortfolio(),
            const SizedBox(height: 24),

            // Статистика
            _buildStats(),
          ],
        ),
      );

  Widget _buildProfileHeader() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: _profile!.logoUrl != null
                    ? NetworkImage(_profile!.logoUrl!)
                    : null,
                child: _profile!.logoUrl == null
                    ? const Icon(Icons.business, size: 40)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profile!.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_profile!.description != null)
                      Text(
                        _profile!.description!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _profile!.formattedRating,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${_profile!.reviewCount} отзывов)',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_profile!.isVerified)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Верифицирован',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _buildBasicInfo() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
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
              _buildInfoRow('Опыт работы', _profile!.experienceText),
              _buildInfoRow('Локация', _profile!.location ?? 'Не указана'),
              _buildInfoRow('Бюджет', _profile!.formattedBudget),
              if (_profile!.responseTime != null)
                _buildInfoRow('Время ответа', _profile!.responseTime!),
            ],
          ),
        ),
      );

  Widget _buildCategoriesAndSpecializations() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Категории мероприятий',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_profile!.categories.isEmpty)
                const Text('Категории не указаны')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _profile!.categories
                      .map((category) => Chip(label: Text(category)))
                      .toList(),
                ),
              const SizedBox(height: 16),
              const Text(
                'Специализации',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_profile!.specializations.isEmpty)
                const Text('Специализации не указаны')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _profile!.specializations
                      .map((spec) => Chip(label: Text(spec)))
                      .toList(),
                ),
            ],
          ),
        ),
      );

  Widget _buildContactInfo() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Контактная информация',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_profile!.phone != null)
                _buildContactRow(Icons.phone, _profile!.phone!),
              if (_profile!.email != null)
                _buildContactRow(Icons.email, _profile!.email!),
              if (_profile!.website != null)
                _buildContactRow(Icons.web, _profile!.website!),
            ],
          ),
        ),
      );

  Widget _buildPortfolio() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Портфолио',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (!_profile!.hasPortfolio)
                const Text('Портфолио пусто')
              else ...[
                if (_profile!.portfolioImages.isNotEmpty) ...[
                  const Text(
                    'Изображения:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _profile!.portfolioImages.length,
                      itemBuilder: (context, index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _profile!.portfolioImages[index],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_profile!.pastEvents.isNotEmpty) ...[
                  const Text(
                    'Завершенные проекты:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text('${_profile!.projectCount} проектов'),
                ],
              ],
            ],
          ),
        ),
      );

  Widget _buildStats() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Статистика',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Рейтинг',
                    _profile!.formattedRating,
                    Icons.star,
                  ),
                  _buildStatItem(
                    'Отзывы',
                    _profile!.reviewCount.toString(),
                    Icons.rate_review,
                  ),
                  _buildStatItem(
                    'Проекты',
                    _profile!.projectCount.toString(),
                    Icons.work,
                  ),
                  _buildStatItem(
                    'Команда',
                    _profile!.teamMembers.length.toString(),
                    Icons.group,
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  Widget _buildContactRow(IconData icon, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(child: Text(value)),
          ],
        ),
      );

  Widget _buildStatItem(String label, String value, IconData icon) => Column(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      );

  Widget _buildEditForm() => Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основная информация
              _buildEditSection(
                'Основная информация',
                [
                  _buildTextField(
                    _nameController,
                    'Название организации',
                    true,
                  ),
                  _buildTextField(
                    _descriptionController,
                    'Описание',
                    false,
                    maxLines: 3,
                  ),
                  _buildTextField(_locationController, 'Локация', false),
                  _buildTextField(
                    _experienceController,
                    'Опыт работы (лет)',
                    false,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Контактная информация
              _buildEditSection(
                'Контактная информация',
                [
                  _buildTextField(_phoneController, 'Телефон', false),
                  _buildTextField(_emailController, 'Email', false),
                  _buildTextField(_websiteController, 'Веб-сайт', false),
                ],
              ),
              const SizedBox(height: 24),

              // Бюджет и время ответа
              _buildEditSection(
                'Условия работы',
                [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _minBudgetController,
                          'Мин. бюджет',
                          false,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          _maxBudgetController,
                          'Макс. бюджет',
                          false,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  _buildTextField(
                    _responseTimeController,
                    'Время ответа',
                    false,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Категории
              _buildCategorySelection(),
              const SizedBox(height: 24),

              // Специализации
              _buildSpecializationSelection(),
            ],
          ),
        ),
      );

  Widget _buildEditSection(String title, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      );

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool required, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Поле обязательно для заполнения';
                  }
                  return null;
                }
              : null,
        ),
      );

  Widget _buildCategorySelection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Категории мероприятий',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: EventCategory.values.map((category) {
                  final isSelected =
                      _selectedCategories.contains(category.name);
                  return FilterChip(
                    label: Text(category.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(category.name);
                        } else {
                          _selectedCategories.remove(category.name);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );

  Widget _buildSpecializationSelection() {
    final commonSpecializations = [
      'Свадебный организатор',
      'Корпоративный организатор',
      'Детский организатор',
      'Праздничный организатор',
      'Конференц-организатор',
      'Выставочный организатор',
      'Фестивальный организатор',
      'Концертный организатор',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Специализации',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: commonSpecializations.map((spec) {
                final isSelected = _selectedSpecializations.contains(spec);
                return FilterChip(
                  label: Text(spec),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSpecializations.add(spec);
                      } else {
                        _selectedSpecializations.remove(spec);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
