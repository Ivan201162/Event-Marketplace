import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/constants/specialist_roles.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Экран онбординга после Google Sign-In
class PostGoogleOnboardingScreen extends StatefulWidget {
  const PostGoogleOnboardingScreen({super.key});

  @override
  State<PostGoogleOnboardingScreen> createState() => _PostGoogleOnboardingScreenState();
}

class _PostGoogleOnboardingScreenState extends State<PostGoogleOnboardingScreen> {
  bool _isSpecialist = false;
  final List<String> _selectedRoleIds = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    debugLog("ONBOARD_OPENED");
  }

  Future<void> _saveOnboarding() async {
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

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isSpecialist': _isSpecialist,
        'roles': roles,
        'onboarded': true,
        'role': _isSpecialist && roles.isNotEmpty ? 'specialist' : 'user',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (_isSpecialist && _selectedRoleIds.isNotEmpty) {
        debugLog("ONBOARD_SPECIALIST_ROLES_SET:${_selectedRoleIds.join(',')}");
      }

      debugLog("ONBOARD_DONE:${user.uid}");

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Error saving onboarding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
        setState(() => _isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Добро пожаловать!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Выберите ваш тип аккаунта',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                
                // Выбор типа аккаунта
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Я заказчик'),
                        selected: !_isSpecialist,
                        onSelected: (selected) {
                          setState(() {
                            _isSpecialist = false;
                            _selectedRoleIds.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Я специалист'),
                        selected: _isSpecialist,
                        onSelected: (selected) {
                          setState(() {
                            _isSpecialist = true;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                // Выбор ролей (только для специалиста)
                if (_isSpecialist) ...[
                  const SizedBox(height: 32),
                  const Text(
                    'Выберите ваши роли (до 3)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
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
                  if (_selectedRoleIds.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Выбрано: ${_selectedRoleIds.length}/3',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],

                const Spacer(),

                // Кнопка сохранения
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving || (_isSpecialist && _selectedRoleIds.isEmpty)
                        ? null
                        : _saveOnboarding,
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
    );
  }
}

