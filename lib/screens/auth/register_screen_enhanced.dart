import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/user.dart' show UserRole;
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Улучшенный экран регистрации с обязательными полями
class RegisterScreenEnhanced extends ConsumerStatefulWidget {
  const RegisterScreenEnhanced({super.key});

  @override
  ConsumerState<RegisterScreenEnhanced> createState() => _RegisterScreenEnhancedState();
}

class _RegisterScreenEnhancedState extends ConsumerState<RegisterScreenEnhanced> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool _usernameAvailable = true;
  Timer? _usernameDebounceTimer;
  UserRole? _selectedRole;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите роль'), backgroundColor: Colors.red),
      );
      return;
    }

    final username = _usernameController.text.trim();
    if (username.isNotEmpty && !_usernameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Этот username уже занят'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final firebaseUser = (await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      )).user;

      if (firebaseUser == null) throw Exception('Failed to create user');

      final usernameLower = username.isEmpty ? null : username.toLowerCase().trim();
      
      await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'username': username.isEmpty ? null : username.trim(),
        'usernameLower': usernameLower,
        'email': _emailController.text.trim(),
        'role': _selectedRole!.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'provider': 'email',
      });

      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Имя *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Обязательное поле' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Фамилия *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Обязательное поле' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username (необязательно)',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isCheckingUsername
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : _usernameController.text.isEmpty
                          ? null
                          : Icon(_usernameAvailable ? Icons.check : Icons.close, color: _usernameAvailable ? Colors.green : Colors.red),
                ),
                onChanged: _checkUsernameAvailability,
              ),
              if (_usernameController.text.isNotEmpty && !_usernameAvailable && !_isCheckingUsername)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Username занят', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty ?? true || !v!.contains('@') ? 'Введите email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Пароль *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v?.length ?? 0) < 6 ? 'Минимум 6 символов' : null,
              ),
              const SizedBox(height: 24),
              const Text('Роль *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              RadioListTile<UserRole>(
                title: const Text('Пользователь'),
                value: UserRole.customer,
                groupValue: _selectedRole,
                onChanged: (v) => setState(() => _selectedRole = v),
              ),
              RadioListTile<UserRole>(
                title: const Text('Специалист'),
                value: UserRole.specialist,
                groupValue: _selectedRole,
                onChanged: (v) => setState(() => _selectedRole = v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_isLoading || (_usernameController.text.isNotEmpty && !_usernameAvailable)) ? null : _register,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Зарегистрироваться'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

