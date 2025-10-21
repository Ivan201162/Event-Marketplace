import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';

/// Главный экран авторизации с поддержкой разных способов входа
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isLoginMode = true;
  String? _errorMessage;

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
      setState(() {
        _errorMessage = 'Заполните все поля';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        context.go('/main');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Произошла ошибка: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Заполните все поля';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (mounted) {
        context.go('/main');
      }
    } on FirebaseAuthException catch (e) {
      final String errorMessage = _getErrorMessage(e.code);

      // Если email уже используется с Google, предлагаем войти через Google
      if (e.code == 'email-already-in-use-google') {
        _showGoogleSignInDialog();
        return;
      }

      setState(() {
        _errorMessage = errorMessage;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Произошла ошибка: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithPhone() async {
    // Переходим на экран ввода номера телефона
    context.push('/phone-auth');
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();

      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      String errorMessage = 'Ошибка входа через Google';
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'account-exists-with-different-credential':
            errorMessage = 'Аккаунт с таким email уже существует с другим способом входа';
            break;
          case 'invalid-credential':
            errorMessage = 'Неверные учетные данные Google';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Вход через Google не разрешен';
            break;
          case 'user-disabled':
            errorMessage = 'Аккаунт заблокирован';
            break;
          case 'user-not-found':
            errorMessage = 'Пользователь не найден';
            break;
          case 'wrong-password':
            errorMessage = 'Неверный пароль';
            break;
          case 'invalid-verification-code':
            errorMessage = 'Неверный код подтверждения';
            break;
          case 'invalid-verification-id':
            errorMessage = 'Неверный ID подтверждения';
            break;
          case 'network-request-failed':
            errorMessage = 'Ошибка сети. Проверьте подключение к интернету';
            break;
          default:
            errorMessage = 'Ошибка Google Sign-In: ${e.message ?? e.code}';
        }
      } else if (e.toString().contains('ApiException: 10')) {
        errorMessage = 'Ошибка конфигурации Google Sign-In. Обратитесь к разработчику';
      } else {
        errorMessage = 'Ошибка входа через Google: ${e.toString()}';
      }
      
      setState(() {
        _errorMessage = errorMessage;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      // Логотип
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.event,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Заголовок
                      Text(
                        'Event Marketplace',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Найдите идеального специалиста для вашего события',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      // Переключатель режима
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLoginMode = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isLoginMode ? theme.primaryColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Вход',
                                    style: TextStyle(
                                      color: _isLoginMode ? Colors.white : Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLoginMode = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !_isLoginMode ? theme.primaryColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Регистрация',
                                    style: TextStyle(
                                      color: !_isLoginMode ? Colors.white : Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Форма авторизации
                      if (_isLoginMode) ...[
                        // Поля для входа
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Пароль',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Кнопка входа
                        ElevatedButton(
                          onPressed: _isLoading ? null : _signInWithEmail,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Войти'),
                        ),

                        const SizedBox(height: 16),

                        // Ссылка "Забыли пароль?"
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.go('/forgot-password'),
                            child: const Text('Забыли пароль?'),
                          ),
                        ),
                      ] else ...[
                        // Поля для регистрации
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Имя',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Пароль',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Кнопка регистрации
                        ElevatedButton(
                          onPressed: _isLoading ? null : _signUpWithEmail,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Зарегистрироваться'),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Ошибка
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[700]),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Разделитель
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'или',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Вход по телефону
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signInWithPhone,
                        icon: const Icon(Icons.phone),
                        label: const Text('Войти по телефону'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Google Sign-In button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: Image.asset(
                            'assets/icons/google_logo.png',
                            height: 24.0,
                            width: 24.0,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.login),
                          ),
                          label: const Text('Войти через Google'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
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
    );
  }
}
