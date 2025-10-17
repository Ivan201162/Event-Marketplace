import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/navigation/back_utils.dart';
import '../../../widgets/form_validators.dart';
import '../../data/models/specialist_profile.dart';
import '../../data/repositories/specialist_profile_repository.dart';

/// Экран редактирования профиля специалиста
class EditSpecialistProfileScreen extends ConsumerStatefulWidget {
  const EditSpecialistProfileScreen({
    super.key,
    required this.specialistId,
    this.isCreating = false,
  });
  final String specialistId;
  final bool isCreating;

  @override
  ConsumerState<EditSpecialistProfileScreen> createState() => _EditSpecialistProfileScreenState();
}

class _EditSpecialistProfileScreenState extends ConsumerState<EditSpecialistProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = SpecialistProfileRepository();

  // Контроллеры
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _experienceController = TextEditingController();

  // Состояние
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  // Данные профиля
  SpecialistProfileForm? _profile;
  List<String> _selectedCategories = [];
  Map<String, double> _servicesWithPrices = {};
  Map<String, String> _contacts = {};
  String? _imageUrl;
  String? _coverUrl;
  File? _selectedImage;
  File? _selectedCover;

  // Доступные категории
  final List<String> _availableCategories = [
    'Фотограф',
    'Видеограф',
    'DJ',
    'Ведущий',
    'Декоратор',
    'Музыкант',
    'Кейтеринг',
    'Охрана',
    'Техник',
    'Аниматор',
    'Флорист',
    'Световое оформление',
    'Звуковое оборудование',
    'Платья/костюмы',
    'Фаер-шоу',
    'Салюты',
    'Световые шоу',
    'Кавер-группы',
    'Тимбилдинги',
    'Клининг',
    'Аренда оборудования',
    'Визажист',
    'Парикмахер',
    'Стилист',
    'Хореограф',
    'Танцы',
    'Фокусы/иллюзионист',
    'Клоун',
    'Аэродизайн',
    'Торты/кондитер',
    'Транспорт',
    'Площадки',
    'Фотостудия',
    'Другое',
  ];

  @override
  void initState() {
    super.initState();
    if (!widget.isCreating) {
      _loadProfile();
    } else {
      _initializeNewProfile();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _hourlyRateController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _repository.getSpecialistProfile(widget.specialistId);
      if (profile != null) {
        _profile = profile;
        _populateForm(profile);
      } else {
        setState(() {
          _errorMessage = 'Профиль не найден';
        });
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

  void _initializeNewProfile() {
    _profile = SpecialistProfileForm(
      id: widget.specialistId,
      userId: 'current_user_id', // TODO(developer): Получить из auth
      name: '',
      email: '',
      phone: '',
      bio: '',
      description: '',
      location: '',
      categories: [],
      yearsOfExperience: 0,
      hourlyRate: 0.0,
      servicesWithPrices: {},
      contacts: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _populateForm(SpecialistProfileForm profile) {
    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _phoneController.text = profile.phone;
    _bioController.text = profile.bio;
    _descriptionController.text = profile.description;
    _locationController.text = profile.location;
    _hourlyRateController.text = profile.hourlyRate.toString();
    _experienceController.text = profile.yearsOfExperience.toString();

    _selectedCategories = List.from(profile.categories);
    _servicesWithPrices = Map.from(profile.servicesWithPrices);
    _contacts = Map.from(profile.contacts);
    _imageUrl = profile.imageUrl;
    _coverUrl = profile.coverUrl;
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
      // Создаем обновленный профиль
      final updatedProfile = _profile!.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        categories: _selectedCategories,
        yearsOfExperience: int.tryParse(_experienceController.text) ?? 0,
        hourlyRate: double.tryParse(_hourlyRateController.text) ?? 0.0,
        servicesWithPrices: _servicesWithPrices,
        contacts: _contacts,
        imageUrl: _imageUrl,
        coverUrl: _coverUrl,
        updatedAt: DateTime.now(),
      );

      // Валидация
      final validationErrors = updatedProfile.validate();
      if (validationErrors.isNotEmpty) {
        setState(() {
          _errorMessage = validationErrors.values.first;
        });
        return;
      }

      // Загружаем изображения если есть
      if (_selectedImage != null) {
        final imageUrl = await _repository.uploadImage(
          _selectedImage!,
          widget.specialistId,
          'avatar',
        );
        updatedProfile.copyWith(imageUrl: imageUrl);
      }

      if (_selectedCover != null) {
        final coverUrl = await _repository.uploadImage(
          _selectedCover!,
          widget.specialistId,
          'cover',
        );
        updatedProfile.copyWith(coverUrl: coverUrl);
      }

      // Сохраняем профиль
      await _repository.saveSpecialistProfile(updatedProfile);

      setState(() {
        _successMessage =
            widget.isCreating ? 'Профиль создан успешно!' : 'Профиль сохранен успешно!';
      });

      // Возвращаемся назад через небольшую задержку
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.pop(true); // Возвращаем true для обновления списка
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка сохранения: $e';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (type == 'avatar') {
          _selectedImage = File(pickedFile.path);
        } else if (type == 'cover') {
          _selectedCover = File(pickedFile.path);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: BackUtils.buildAppBar(
          context,
          title: widget.isCreating ? 'Создание профиля' : 'Редактирование профиля',
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: _saveProfile,
                child: const Text('Сохранить'),
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
                      // Сообщения об ошибках/успехе
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),

                      if (_successMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Text(
                            _successMessage!,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),

                      // Основная информация
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),

                      // Категории
                      _buildCategoriesSection(),
                      const SizedBox(height: 24),

                      // Опыт и цены
                      _buildExperienceAndPricingSection(),
                      const SizedBox(height: 24),

                      // Контакты
                      _buildContactsSection(),
                      const SizedBox(height: 24),

                      // Изображения
                      _buildImagesSection(),
                      const SizedBox(height: 24),

                      // Кнопка сохранения
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  widget.isCreating ? 'Создать профиль' : 'Сохранить изменения',
                                ),
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
              const Text(
                'Основная информация',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя *',
                  border: OutlineInputBorder(),
                ),
                validator: FormValidators.required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: FormValidators.email,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Телефон *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: FormValidators.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Местоположение *',
                  border: OutlineInputBorder(),
                ),
                validator: FormValidators.required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Краткое описание *',
                  border: OutlineInputBorder(),
                  hintText: 'Краткое описание ваших услуг',
                ),
                maxLines: 2,
                validator: (value) => FormValidators.minLength(value, 5),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Подробное описание *',
                  border: OutlineInputBorder(),
                  hintText: 'Расскажите о себе и своих услугах',
                ),
                maxLines: 4,
                validator: (value) => FormValidators.minLength(value, 10),
              ),
            ],
          ),
        ),
      );

  Widget _buildCategoriesSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Категории услуг *',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Выберите категории, в которых вы работаете',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableCategories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
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
              const Text(
                'Опыт и ценообразование',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _experienceController,
                      decoration: const InputDecoration(
                        labelText: 'Опыт (лет)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: FormValidators.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _hourlyRateController,
                      decoration: const InputDecoration(
                        labelText: 'Почасовая ставка (₽)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: FormValidators.positiveNumber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildContactsSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Дополнительные контакты',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _addContact,
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._contacts.entries.map((entry) => _buildContactField(entry.key, entry.value)),
            ],
          ),
        ),
      );

  Widget _buildContactField(String key, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: key,
                decoration: const InputDecoration(
                  labelText: 'Тип контакта',
                  border: OutlineInputBorder(),
                ),
                onChanged: (newKey) {
                  if (newKey != key) {
                    _contacts.remove(key);
                    _contacts[newKey] = value;
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextFormField(
                initialValue: value,
                decoration: const InputDecoration(
                  labelText: 'Значение',
                  border: OutlineInputBorder(),
                ),
                onChanged: (newValue) {
                  _contacts[key] = newValue;
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                setState(() {
                  _contacts.remove(key);
                });
              },
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      );

  Widget _buildImagesSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Изображения',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Аватар
              Row(
                children: [
                  const Text('Аватар:'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage('avatar'),
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Выбрать фото'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Обложка
              Row(
                children: [
                  const Text('Обложка:'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage('cover'),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Выбрать обложку'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  void _addContact() {
    setState(() {
      _contacts['Новый контакт'] = '';
    });
  }
}
