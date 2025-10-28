import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Экран входа и регистрации
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Заполните все поля');
      return;
    }

    setState(() => _isLoading = true);
    ref.read(authLoadingProvider.notifier).setLoading(true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        context.go('/main');
      }
    } on FirebaseAuthException catch (e) {
      _showError(_getErrorMessage(e.code));
    } catch (e) {
      _showError('Произошла ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty) {
      _showError('Заполните все поля');
      return;
    }

    setState(() => _isLoading = true);
    ref.read(authLoadingProvider.notifier).setLoading(true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      );

      if (mounted) {
        context.go('/main');
      }
    } on FirebaseAuthException catch (e) {
      _showError(_getErrorMessage(e.code));
    } catch (e) {
      _showError('Произошла ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> _signInWithPhone() async {
    // Переходим на экран ввода номера телефона
    await context.push('/phone-auth');
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    ref.read(authLoadingProvider.notifier).setLoading(true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();

      if (mounted) {
        context.go('/main');
      }
    } on FirebaseAuthException catch (e) {
      var errorMessage = 'Ошибка входа через Google';

      if (e.code == 'account-exists-with-different-credential') {
        errorMessage =
            'Аккаунт с таким email уже существует с другим способом входа';
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'Неверные учетные данные Google';
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = 'Вход через Google не разрешен';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'Аккаунт заблокирован';
      } else if (e.code == 'user-not-found') {
        errorMessage = 'Пользователь не найден';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Ошибка сети. Проверьте подключение к интернету';
      } else {
        errorMessage = 'Ошибка Google Sign-In: ${e.message ?? e.code}';
      }

      _showError(errorMessage);
    } catch (e) {
      var errorMessage = 'Ошибка входа через Google';

      if (e.toString().contains('ApiException: 10')) {
        errorMessage =
            'Ошибка конфигурации Google Sign-In. Обратитесь к разработчику';
      } else {
        errorMessage = 'Ошибка входа через Google: $e';
      }

      _showError(errorMessage);
    } finally {
      setState(() => _isLoading = false);
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),);
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
      default:
        return 'Произошла ошибка: $errorCode';
    }
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48, // 48 = padding * 2
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // App logo and title
                        const Icon(Icons.event, size: 80, color: Colors.white),
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
                          style: TextStyle(fontSize: 16, color: Colors.white70),
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
                                color: Colors.black.withValues(alpha: 0.1),
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
                                      onPressed: () =>
                                          setState(() => _isSignUp = false),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isSignUp
                                            ? Colors.grey[200]
                                            : Colors.blue,
                                        foregroundColor: _isSignUp
                                            ? Colors.grey[600]
                                            : Colors.white,
                                      ),
                                      child: const Text('Вход'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          setState(() => _isSignUp = true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isSignUp
                                            ? Colors.blue
                                            : Colors.grey[200],
                                        foregroundColor: _isSignUp
                                            ? Colors.white
                                            : Colors.grey[600],
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
                                  onPressed: _isLoading
                                      ? null
                                      : (_isSignUp
                                          ? _signUpWithEmail
                                          : _signInWithEmail),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16,),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,)
                                      : Text(_isSignUp
                                          ? 'Зарегистрироваться'
                                          : 'Войти',),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Divider
                              const Row(
                                children: [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
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
                                  onPressed:
                                      _isLoading ? null : _signInWithPhone,
                                  icon: const Icon(Icons.phone),
                                  label: const Text('Войти по телефону'),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Google Sign-In button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _isLoading ? null : _signInWithGoogle,
                                  icon: const Icon(Icons.account_circle),
                                  label: const Text('Войти через Google'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
