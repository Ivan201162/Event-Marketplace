import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/user.dart' show UserRole;
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Экран дозаполнения профиля после Google Sign-In
class OnboardingCompleteProfileScreen extends StatefulWidget {
  const OnboardingCompleteProfileScreen({super.key});

  @override
  State<OnboardingCompleteProfileScreen> createState() => _OnboardingCompleteProfileScreenState();
}

class _OnboardingCompleteProfileScreenState extends State<OnboardingCompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool _usernameAvailable = true;
  Timer? _usernameDebounceTimer;
  DateTime? _birthDate;
  bool _isSpecialist = false;
  int? _specialistSinceYear;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _usernameController.addListener(() {
      _checkUsernameAvailability(_usernameController.text);
    });
  }

  Future<void> _loadExistingData() async {
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
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _usernameController.text = data['username'] ?? '';
          _cityController.text = data['city'] ?? '';
          _isSpecialist = data['role'] == 'specialist';
          if (data['birthDate'] != null) {
            _birthDate = (data['birthDate'] as Timestamp).toDate();
          }
          if (data['specialistSinceYear'] != null) {
            _specialistSinceYear = data['specialistSinceYear'] as int;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading existing data: $e');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _cityController.dispose();
    _usernameDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty) {
      setState(() {
        _usernameAvailable = true;
        _isCheckingUsername = false;
      });
      return;
    }

    _usernameDebounceTimer?.cancel();
    _usernameDebounceTimer = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isCheckingUsername = true);

      try {
        final usernameLower = username.toLowerCase().trim();
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('usernameLower', isEqualTo: usernameLower)
            .limit(1)
            .get();

        setState(() {
          _usernameAvailable = snapshot.docs.isEmpty;
          _isCheckingUsername = false;
        });
      } catch (e) {
        setState(() {
          _usernameAvailable = false;
          _isCheckingUsername = false;
        });
      }
    });
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 100);
    final lastDate = DateTime(now.year - 14); // Минимум 14 лет

    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('ru', 'RU'),
    );

    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final city = _cityController.text.trim();

    // ФИО обязательны
    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Имя и фамилия обязательны'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Проверка username если указан
    if (username.isNotEmpty && !_usernameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Этот username уже занят'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (username.isNotEmpty) {
        updateData['username'] = username;
        updateData['usernameLower'] = username.toLowerCase().trim();
      }

      if (city.isNotEmpty) {
        updateData['city'] = city;
      }

      if (_birthDate != null) {
        updateData['birthDate'] = Timestamp.fromDate(_birthDate!);
      }

      if (_isSpecialist) {
        updateData['role'] = 'specialist';
        if (_specialistSinceYear != null) {
          updateData['specialistSinceYear'] = _specialistSinceYear;
        }
      } else {
        updateData['role'] = 'user';
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      debugLog("AUTH_ENRICH_PROFILE_SAVED");

      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _skip() async {
    // Пропустить можно только username/city/birthDate/год начала, но не ФИО
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Имя и фамилия обязательны. Нельзя пропустить.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Сохраняем только ФИО и роль, остальное пропускаем
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
        'role': _isSpecialist ? 'specialist' : 'user',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      debugLog("AUTH_ENRICH_PROFILE_SAVED");

      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Не позволяем закрыть без сохранения ФИО
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Завершите профиль'),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Заполните обязательные поля',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
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
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username (опционально)',
                    border: const OutlineInputBorder(),
                    suffixIcon: _isCheckingUsername
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_usernameController.text.isNotEmpty
                            ? Icon(
                                _usernameAvailable ? Icons.check : Icons.close,
                                color: _usernameAvailable ? Colors.green : Colors.red,
                              )
                            : null),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Город (опционально)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectBirthDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Дата рождения (опционально)',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _birthDate != null
                          ? DateFormat('dd.MM.yyyy', 'ru').format(_birthDate!)
                          : 'Выберите дату',
                      style: TextStyle(
                        color: _birthDate != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('Вы специалист?'),
                  value: _isSpecialist,
                  onChanged: (value) {
                    setState(() {
                      _isSpecialist = value;
                      if (!value) {
                        _specialistSinceYear = null;
                      }
                    });
                  },
                ),
                if (_isSpecialist) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'С какого года работаете',
                      border: OutlineInputBorder(),
                    ),
                    value: _specialistSinceYear,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Не указывать'),
                      ),
                      ...List.generate(
                        DateTime.now().year - 1990 + 1,
                        (index) => DropdownMenuItem(
                          value: 1990 + index,
                          child: Text('${1990 + index}'),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _specialistSinceYear = value);
                    },
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Сохранить'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isLoading ? null : _skip,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Пропустить позже'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

