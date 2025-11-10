import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/constants/specialist_roles.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Экран онбординга: роль + ФИО + город
class RoleNameCityOnboardingScreen extends StatefulWidget {
  const RoleNameCityOnboardingScreen({super.key});

  @override
  State<RoleNameCityOnboardingScreen> createState() => _RoleNameCityOnboardingScreenState();
}

class _RoleNameCityOnboardingScreenState extends State<RoleNameCityOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cityController = TextEditingController();
  final List<String> _selectedRoleIds = [];
  bool _isSaving = false;
  bool _isLoadingLocation = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    debugLog("ONBOARDING_OPENED");
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _detectCity() async {
    setState(() => _isLoadingLocation = true);
    try {
      // Проверка разрешений
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Включите геолокацию в настройках')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Разрешение на геолокацию отклонено')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Разрешение на геолокацию отклонено навсегда. Введите город вручную')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        final city = placemarks.first.locality ?? placemarks.first.subAdministrativeArea ?? 'Неизвестно';
        if (mounted) {
          setState(() {
            _cityController.text = city;
          });
        }
      }
    } catch (e) {
      debugPrint('Error detecting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось определить город: $e. Введите вручную')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _toggleRole(String roleId) {
    setState(() {
      if (_selectedRoleIds.contains(roleId)) {
        _selectedRoleIds.remove(roleId);
      } else {
        if (_selectedRoleIds.length < 3) {
          _selectedRoleIds.add(roleId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Можно выбрать до 3 ролей')),
          );
        }
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoleIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы одну роль')),
      );
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Необходимо согласиться с правилами')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final roles = _selectedRoleIds.map((roleId) {
        final role = SpecialistRoles.getRoleById(roleId);
        return {
          'id': roleId,
          'label': role?['label'] ?? roleId,
        };
      }).toList();

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final city = _cityController.text.trim();
      final rolesLower = _selectedRoleIds.map((id) => id.toLowerCase()).toList();
      final cityLower = city.toLowerCase();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'city': city,
        'cityLower': cityLower,
        'roles': roles,
        'rolesLower': rolesLower,
        'roleMain': roles.isNotEmpty ? roles.first['id'] : null,
        'isSpecialist': roles.isNotEmpty,
        'role': roles.isNotEmpty ? 'specialist' : 'user',
        'onboarded': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugLog("ONBOARDING_SAVED:${user.uid}");
      debugLog("ONBOARDING_COMPLETED:${user.uid}");

      if (mounted) {
        // Используем go_router для навигации
        context.go('/main');
      }
    } catch (e) {
      final errorCode = e is FirebaseException ? e.code : 'unknown';
      debugLog("ONBOARDING_ERR:$errorCode:$e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          debugLog("ONBOARDING_ABORTED");
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Добро пожаловать!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Заполните профиль',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  
                  // Имя
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Имя *',
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
                  
                  // Фамилия
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Фамилия *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите фамилию';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Город
                  TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'Город *',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: _isLoadingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.location_on),
                        onPressed: _detectCity,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите город';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Роли
                  const Text(
                    'Выберите ваши роли (до 3)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: SpecialistRoles.allRoles.map((role) {
                          final roleId = role['id']!;
                          final isSelected = _selectedRoleIds.contains(roleId);
                          return FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(SpecialistRoles.getIcon(roleId)),
                                const SizedBox(width: 4),
                                Text(role['label']!),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (_) => _toggleRole(roleId),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  if (_selectedRoleIds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Выбрано: ${_selectedRoleIds.length}/3',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 24),
                  
                  // Согласие с правилами
                  Row(
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreedToTerms = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // TODO: Открыть правила
                            Navigator.of(context).pushNamed('/terms');
                          },
                          child: Text(
                            'Я согласен с правилами использования',
                            style: TextStyle(
                              fontSize: 14,
                              color: _agreedToTerms ? Colors.blue : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Кнопка сохранения
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isSaving || !_agreedToTerms) ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Продолжить'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

