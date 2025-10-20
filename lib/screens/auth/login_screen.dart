import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';

/// Login screen with email, phone, and guest options
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _isPhoneAuth = false;
  bool _isLoading = false;
  String? _verificationId;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Заполните все поля');
      return;
    }

    setState(() => _isLoading = true);
    ref.read(authLoadingProvider.notifier).state = true;

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      _showError('Ошибка входа: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty) {
      _showError('Заполните все поля');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Пароль должен содержать минимум 6 символов');
      return;
    }

    setState(() => _isLoading = true);
    ref.read(authLoadingProvider.notifier).state = true;

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (mounted) {
        context.go('/onboarding');
      }
    } on FirebaseAuthException catch (e) {
      final String errorMessage = _getErrorMessage(e.code);

      // Если email уже используется с Google, предлагаем войти через Google
      if (e.code == 'email-already-in-use-google') {
        _showGoogleSignInDialog();
        return;
      }

      _showError(errorMessage);
    } catch (e) {
      _showError('Ошибка регистрации: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _signInWithPhone() async {
    if (_phoneController.text.isEmpty) {
      _showError('Введите номер телефона');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        onCodeSent: (verificationId) {
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
          _showPhoneCodeDialog();
        },
        onError: (error) {
          setState(() => _isLoading = false);
          _showError('Ошибка: $error');
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Ошибка: ${e.toString()}');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    ref.read(authLoadingProvider.notifier).state = true;

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      _showError('Google вход: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  void _showPhoneCodeDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Введите код'),
        content: TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Код из SMS',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isPhoneAuth = false);
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isEmpty || _verificationId == null) return;

              setState(() => _isLoading = true);

              try {
                final authService = ref.read(authServiceProvider);
                await authService.verifyPhoneCode(
                  verificationId: _verificationId!,
                  code: codeController.text.trim(),
                );

                if (mounted) {
                  Navigator.pop(context);
                  context.go('/main');
                }
              } catch (e) {
                _showError('Неверный код: ${e.toString()}');
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Этот email уже используется. Попробуйте войти или восстановить пароль.';
      case 'email-already-in-use-google':
        return 'Этот email уже используется с Google. Войти через Google?';
      case 'email-already-in-use-phone':
        return 'Этот email уже используется с номером телефона. Попробуйте войти или восстановить пароль.';
      case 'weak-password':
        return 'Пароль должен содержать минимум 6 символов';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'user-disabled':
        return 'Аккаунт заблокирован';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'google-account':
        return 'Этот email зарегистрирован через Google. Войдите через Google или используйте другой email.';
      case 'phone-account':
        return 'Этот email зарегистрирован через номер телефона. Войдите через телефон или используйте другой email.';
      default:
        return 'Произошла ошибка: $errorCode';
    }
  }

  void _showGoogleSignInDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email уже используется'),
        content:
            const Text('Этот email уже зарегистрирован через Google. Хотите войти через Google?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _signInWithGoogle();
            },
            child: const Text('Войти через Google'),
          ),
        ],
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
            colors: [
              Color(0xFF6C5CE7),
              Color(0xFFA29BFE),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),

                // App logo and title
                const Icon(
                  Icons.event,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Event Marketplace',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Найди идеального специалиста для своего мероприятия',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),

                const Spacer(),

                // Auth form
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
                      // Toggle between sign in and sign up
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setState(() => _isSignUp = false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isSignUp ? Colors.grey[200] : Colors.blue,
                                foregroundColor: _isSignUp ? Colors.grey[600] : Colors.white,
                              ),
                              child: const Text('Войти'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setState(() => _isSignUp = true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isSignUp ? Colors.blue : Colors.grey[200],
                                foregroundColor: _isSignUp ? Colors.white : Colors.grey[600],
                              ),
                              child: const Text('Регистрация'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Name field (only for sign up)
                      if (_isSignUp) ...[
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Имя',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email field
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Пароль',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Email auth button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : (_isSignUp ? _signUpWithEmail : _signInWithEmail),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(_isSignUp ? 'Зарегистрироваться' : 'Войти'),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Forgot password link (only for sign in)
                      if (!_isSignUp) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.go('/forgot-password'),
                            child: const Text('Забыли пароль?'),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Divider
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('или'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Phone auth button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _signInWithPhone,
                          icon: const Icon(Icons.phone),
                          label: const Text('Войти по телефону'),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Google Sign-In button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: const Icon(Icons.account_circle),
                          label: const Text('Войти через Google'),
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
