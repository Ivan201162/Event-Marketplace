import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/app_user.dart';
import 'package:event_marketplace_app/models/specialist_categories_list.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

/// Экран редактирования профиля
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();

  File? _selectedAvatar;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _usernameError;
  Timer? _usernameDebounceTimer;
  
  // Режим специалиста
  bool _isSpecialist = false;
  List<String> _selectedCategories = [];
  final _experienceController = TextEditingController();
  final _startYearController = TextEditingController();
  final _workCityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugLog("PROFILE_EDIT_OPENED");
      _loadProfile();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _startYearController.dispose();
    _workCityController.dispose();
    _usernameDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _firstNameController.text = data['firstName'] ?? '';
        _lastNameController.text = data['lastName'] ?? '';
        _usernameController.text = data['username'] ?? '';
        _cityController.text = data['city'] ?? '';
        _bioController.text = data['bio'] ?? '';
        
        // Загружаем данные специалиста
        _isSpecialist = (data['isSpecialist'] as bool?) ?? false;
        if (data['specialist'] != null) {
          final specialist = data['specialist'] as Map<String, dynamic>;
          _selectedCategories = List<String>.from((specialist['categories'] as List?)?.cast<String>() ?? []);
          final experienceYears = specialist['experienceYears'];
          _experienceController.text = experienceYears != null ? experienceYears.toString() : '';
          final startYear = specialist['startYear'];
          _startYearController.text = startYear != null ? startYear.toString() : '';
          _workCityController.text = (specialist['workCity'] as String?) ?? (data['city'] as String?) ?? '';
        } else {
          _startYearController.text = '';
          _workCityController.text = (data['city'] as String?) ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUsername() async {
    final username = _usernameController.text.trim().toLowerCase();
    if (username.isEmpty) {
      setState(() => _usernameError = null);
      return;
    }

    _usernameDebounceTimer?.cancel();
    _usernameDebounceTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return;

        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('usernameLower', isEqualTo: username)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty && query.docs.first.id != currentUser.uid) {
          setState(() => _usernameError = 'Этот username уже занят');
        } else {
          setState(() => _usernameError = null);
        }
      } catch (e) {
        debugPrint('Error checking username: $e');
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedAvatar = File(image.path));
    }
  }

  Future<String?> _uploadAvatar() async {
    if (_selectedAvatar == null) return null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('uploads/avatars/${user.uid}/avatar.jpg');

      await ref.putFile(_selectedAvatar!);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usernameError != null) return;
    if (_isSpecialist && _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы одну категорию')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final avatarUrl = await _uploadAvatar();

      final data = <String, dynamic>{
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'firstNameLower': _firstNameController.text.trim().toLowerCase(),
        'lastNameLower': _lastNameController.text.trim().toLowerCase(),
        'city': _cityController.text.trim(),
        'cityLower': _cityController.text.trim().toLowerCase(),
        'bio': _bioController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_usernameController.text.trim().isNotEmpty) {
        data['username'] = _usernameController.text.trim();
        data['usernameLower'] = _usernameController.text.trim().toLowerCase();
      }

      if (avatarUrl != null) {
        data['photoURL'] = avatarUrl;
        data['avatarUrl'] = avatarUrl;
      }

      // Данные специалиста
      data['isSpecialist'] = _isSpecialist;
      if (_isSpecialist) {
        data['specialist'] = {
          'categories': _selectedCategories,
          'experienceYears': int.tryParse(_experienceController.text.trim()) ?? 0,
          'startYear': _startYearController.text.trim().isNotEmpty 
              ? int.tryParse(_startYearController.text.trim()) 
              : null,
          'workCity': _workCityController.text.trim().isNotEmpty 
              ? _workCityController.text.trim() 
              : _cityController.text.trim(),
        };
        data['role'] = 'specialist';
      } else {
        data['role'] = 'user';
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(data);
      
      if (_isSpecialist) {
        debugLog("PROFILE_SPECIALIST_MODE_ON");
      } else {
        debugLog("PROFILE_SPECIALIST_MODE_OFF");
      }

      debugLog("PROFILE_SAVED");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль обновлён')),
        );
        context.pop();
      }
    } catch (e) {
      debugLog("PROFILE_SAVE_ERR:${e.toString()}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Редактировать профиль'),
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
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _selectedAvatar != null
                              ? FileImage(_selectedAvatar!)
                              : null,
                          child: _selectedAvatar == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Имя
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Обязательное поле';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Фамилия
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Фамилия *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Обязательное поле';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: const OutlineInputBorder(),
                    errorText: _usernameError,
                    prefixText: '@',
                  ),
                  onChanged: (_) => _checkUsername(),
                ),
                const SizedBox(height: 16),

                // Город (с автодополнением и геолокацией)
                Row(
                  children: [
                    Expanded(
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const <String>[];
                          }
                          final russianCities = [
                            'Москва', 'Санкт-Петербург', 'Новосибирск', 'Екатеринбург', 'Казань',
                            'Нижний Новгород', 'Челябинск', 'Самара', 'Омск', 'Ростов-на-Дону',
                            'Уфа', 'Красноярск', 'Воронеж', 'Пермь', 'Волгоград', 'Краснодар',
                            'Саратов', 'Тюмень', 'Тольятти', 'Ижевск', 'Барнаул', 'Ульяновск',
                            'Иркутск', 'Хабаровск', 'Ярославль', 'Владивосток', 'Махачкала',
                            'Томск', 'Оренбург', 'Кемерово', 'Новокузнецк', 'Рязань', 'Астрахань',
                            'Набережные Челны', 'Пенза', 'Липецк', 'Киров', 'Чебоксары', 'Калининград',
                            'Тула', 'Курск', 'Сочи', 'Ставрополь', 'Улан-Удэ', 'Тверь', 'Магнитогорск',
                            'Иваново', 'Брянск', 'Белгород', 'Сургут', 'Владимир', 'Нижний Тагил',
                            'Архангельск', 'Чита', 'Калуга', 'Смоленск', 'Волжский', 'Череповец',
                            'Курган', 'Орёл', 'Владикавказ', 'Грозный', 'Мурманск', 'Тамбов',
                            'Петрозаводск', 'Нижневартовск', 'Йошкар-Ола', 'Новороссийск', 'Кострома',
                          ];
                          return russianCities.where((city) {
                            return city.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          }).toList();
                        },
                        onSelected: (String selection) {
                          _cityController.text = selection;
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          controller.text = _cityController.text;
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            onFieldSubmitted: (value) => onFieldSubmitted(),
                            decoration: InputDecoration(
                              labelText: 'Город',
                              border: const OutlineInputBorder(),
                              hintText: 'Москва, Санкт-Петербург...',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.my_location),
                                tooltip: 'Определить по геолокации',
                                onPressed: () async {
                                  try {
                                    final permission = await Geolocator.checkPermission();
                                    if (permission == LocationPermission.denied) {
                                      final requestPermission = await Geolocator.requestPermission();
                                      if (requestPermission == LocationPermission.denied ||
                                          requestPermission == LocationPermission.deniedForever) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Нужен доступ к геолокации')),
                                          );
                                        }
                                        return;
                                      }
                                    }

                                    final position = await Geolocator.getCurrentPosition(
                                      desiredAccuracy: LocationAccuracy.high,
                                    );

                                    final placemarks = await placemarkFromCoordinates(
                                      position.latitude,
                                      position.longitude,
                                      localeIdentifier: 'ru',
                                    );

                                    if (placemarks.isNotEmpty) {
                                      final city = placemarks.first.locality ?? placemarks.first.administrativeArea;
                                      if (city != null && mounted) {
                                        setState(() {
                                          _cityController.text = city;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Город определён: $city')),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Ошибка геолокации: $e')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                            onChanged: (value) {
                              _cityController.text = value;
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bio
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'О себе',
                    border: OutlineInputBorder(),
                    hintText: 'Краткое описание (до 300 символов)',
                  ),
                  maxLines: 4,
                  maxLength: 300,
                ),
                const SizedBox(height: 24),

                // Режим специалиста
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          title: const Text(
                            'Я предоставляю услуги (стать специалистом)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          value: _isSpecialist,
                          onChanged: (value) {
                            setState(() {
                              _isSpecialist = value ?? false;
                            });
                          },
                        ),
                        if (_isSpecialist) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text(
                            'Данные специалиста',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Категории
                          const Text(
                            'Категории *',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: SpecialistCategoriesList.categories.map((category) {
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
                          if (_selectedCategories.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Выберите хотя бы одну категорию',
                                style: TextStyle(color: Colors.red[700], fontSize: 12),
                              ),
                            ),
                          const SizedBox(height: 16),
                          
                          // Стаж
                          TextFormField(
                            controller: _experienceController,
                            decoration: const InputDecoration(
                              labelText: 'Стаж (лет) *',
                              border: OutlineInputBorder(),
                              hintText: 'Например: 5',
                            ),
                            keyboardType: TextInputType.number,
                            validator: _isSpecialist ? (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Обязательное поле';
                              }
                              final years = int.tryParse(value.trim());
                              if (years == null || years < 0) {
                                return 'Введите корректное число';
                              }
                              return null;
                            } : null,
                          ),
                          const SizedBox(height: 16),
                          
                          // Год начала деятельности
                          TextFormField(
                            controller: _startYearController,
                            decoration: const InputDecoration(
                              labelText: 'Год начала деятельности',
                              border: OutlineInputBorder(),
                              hintText: 'Например: 2015',
                            ),
                            keyboardType: TextInputType.number,
                            validator: _isSpecialist ? (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                final year = int.tryParse(value.trim());
                                final currentYear = DateTime.now().year;
                                if (year == null || year < 1900 || year > currentYear) {
                                  return 'Введите корректный год';
                                }
                              }
                              return null;
                            } : null,
                          ),
                          const SizedBox(height: 16),
                          
                          // Город работы
                          TextFormField(
                            controller: _workCityController,
                            decoration: InputDecoration(
                              labelText: 'Город работы *',
                              border: const OutlineInputBorder(),
                              hintText: _cityController.text.isNotEmpty 
                                  ? 'По умолчанию: ${_cityController.text}'
                                  : 'Введите город',
                            ),
                            validator: _isSpecialist ? (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Обязательное поле';
                              }
                              return null;
                            } : null,
                          ),
                          const SizedBox(height: 16),
                          
                          // Кнопка редактирования прайсов
                          OutlinedButton.icon(
                            icon: const Icon(Icons.attach_money),
                            label: const Text('Управление прайсами'),
                            onPressed: () {
                              context.push('/profile/prices');
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Кнопка сохранить
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Сохранить'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

