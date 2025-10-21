import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../providers/auth_providers.dart';

/// Onboarding screen for new users
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _statusController = TextEditingController();

  UserType _selectedType = UserType.physical;
  bool _isLoading = false;

  final List<String> _popularCities = [
    'Москва',
    'Санкт-Петербург',
    'Казань',
    'Екатеринбург',
    'Новосибирск',
    'Нижний Новгород',
    'Челябинск',
    'Самара',
    'Омск',
    'Ростов-на-Дону',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_nameController.text.isEmpty || _cityController.text.isEmpty) {
      _showError('Заполните обязательные поля');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.updateUserProfile(
        name: _nameController.text.trim(),
        city: _cityController.text.trim(),
        status: _statusController.text.trim().isEmpty ? null : _statusController.text.trim(),
        type: _selectedType,
      );

      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      _showError('Ошибка сохранения: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Выберите город',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _popularCities.length,
                itemBuilder: (context, index) {
                  final city = _popularCities[index];
                  return ListTile(
                    title: Text(city),
                    onTap: () {
                      _cityController.text = city;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),

                // Welcome text
                const Text(
                  'Добро пожаловать!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Расскажите немного о себе',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),

                const Spacer(),

                // Onboarding form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Name field
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Ваше имя *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // City field
                      TextField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: 'Город *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.location_city),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.arrow_drop_down),
                            onPressed: _showCityPicker,
                          ),
                        ),
                        readOnly: true,
                        onTap: _showCityPicker,
                      ),
                      const SizedBox(height: 16),

                      // Status field
                      TextField(
                        controller: _statusController,
                        decoration: const InputDecoration(
                          labelText: 'Статус (необязательно)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.info),
                          hintText: 'Например: Фотограф, Ведущий, DJ',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // User type selection
                      const Text(
                        'Тип аккаунта',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...UserType.values.map(
                        (type) => RadioListTile<UserType>(
                          title: Text(type.displayName),
                          value: type,
                          groupValue: _selectedType,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedType = value);
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Complete button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _completeOnboarding,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Завершить настройку'),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
