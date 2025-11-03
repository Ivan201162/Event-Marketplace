import 'package:event_marketplace_app/models/app_user.dart';
import 'package:event_marketplace_app/models/user.dart' show UserRole;
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/services/auth_service.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Экран выбора роли после первой регистрации
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugLog("ROLE_SELECTION_SHOWN");
    });
  }

  Future<void> _selectRole(UserRole role) async {
    if (_isLoading) return;

    setState(() {
      _selectedRole = role;
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final currentUser = await authService.currentUser;

      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Update user role in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'role': role.name,
        'roleSelected': true,
        'updatedAt': Timestamp.now(),
      });

      // If specialist, create specialist document
      if (role == UserRole.specialist) {
        await _createSpecialistProfile(currentUser.uid);
      }

      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createSpecialistProfile(String uid) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userDoc.data()!;

    await FirebaseFirestore.instance.collection('specialists').doc(uid).set({
      'uid': uid,
      'name': userData['name'] ?? '',
      'username': userData['username'],
      'email': userData['email'],
      'phone': userData['phone'],
      'avatarUrl': userData['avatarUrl'],
      'city': userData['city'],
      'categories': <String>[],
      'bio': '',
      'priceFrom': null,
      'priceTo': null,
      'isVerified': false,
      'isActive': true,
      'weeklyScore': 0,
      'rating': 0.0,
      'reviewCount': 0,
      'followersCount': 0,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите роль'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Выберите вашу роль',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Это поможет нам настроить ваш профиль',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildRoleCard(
                role: UserRole.customer,
                icon: Icons.person,
                title: 'Клиент',
                description: 'Заказ услуг и участие в событиях',
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                role: UserRole.specialist,
                icon: Icons.work,
                title: 'Специалист',
                description: 'Предоставление услуг и управление профилем',
                color: Colors.purple,
              ),
              if (_isLoading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: _isLoading ? null : () => _selectRole(role),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}

