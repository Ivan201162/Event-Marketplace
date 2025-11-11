import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../main/main_screen.dart';
import '../../utils/debug_log.dart';
import '../../constants/specialist_roles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final first = TextEditingController();
  final last = TextEditingController();
  final city = TextEditingController();
  final List<String> _selectedRoles = [];
  bool _isSaving = false;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    debugLog('ONBOARDING_OPENED');
  }

  Future<void> _getLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
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
            const SnackBar(content: Text('Разрешение на геолокацию отклонено навсегда')),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final cityName = placemarks.first.locality ?? placemarks.first.administrativeArea ?? '';
        if (cityName.isNotEmpty && mounted) {
          city.text = cityName;
        }
      }
    } catch (e) {
      debugLog('ONBOARDING_LOCATION_ERR:$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось определить город')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _save() async {
    if (first.text.isEmpty || last.text.isEmpty || city.text.isEmpty || _selectedRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля и выберите хотя бы одну роль')),
      );
      return;
    }

    if (_selectedRoles.length > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите не более 3 ролей')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      // Преобразуем roleId в roleLabel для сохранения
      final roleLabels = _selectedRoles.map((roleId) {
        final role = SpecialistRoles.allRoles.firstWhere(
          (r) => r['id'] == roleId,
          orElse: () => {'id': roleId, 'label': roleId},
        );
        return role['label']!;
      }).toList();

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'firstName': first.text.trim(),
        'lastName': last.text.trim(),
        'city': city.text.trim(),
        'cityLower': city.text.trim().toLowerCase(),
        'roles': roleLabels, // Сохраняем названия ролей
        'rolesLower': roleLabels.map((r) => r.toLowerCase()).toList(),
        'roleIds': _selectedRoles, // Сохраняем ID для поиска
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugLog('ONBOARDING_SAVED:$uid');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      debugLog('ONBOARDING_ERR:$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Онбординг")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: first,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: last,
                decoration: const InputDecoration(
                  labelText: 'Фамилия',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: city,
                      decoration: const InputDecoration(
                        labelText: 'Город',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.location_on),
                    onPressed: _isLoadingLocation ? null : _getLocation,
                    tooltip: 'Определить город',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Выберите роли (1-3):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SpecialistRoles.allRoles.map((roleMap) {
                  final roleId = roleMap['id']!;
                  final roleLabel = roleMap['label']!;
                  final isSelected = _selectedRoles.contains(roleId);
                  return FilterChip(
                    label: Text(roleLabel),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (_selectedRoles.length < 3) {
                            _selectedRoles.add(roleId);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Можно выбрать не более 3 ролей')),
                            );
                          }
                        } else {
                          _selectedRoles.remove(roleId);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Продолжить"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    city.dispose();
    super.dispose();
  }
}
