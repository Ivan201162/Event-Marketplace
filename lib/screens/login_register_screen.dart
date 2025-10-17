import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/user.dart';
import '../providers/auth_providers.dart';

class LoginRegisterScreen extends ConsumerStatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  ConsumerState<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends ConsumerState<LoginRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isSignUpMode = false;
  bool _isLoading = false;
  String? _errorMessage;
  UserRole _selectedRole = UserRole.customer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  // Логотип и заголовок
                  _buildHeader(context),

                  const SizedBox(height: 48),

                  // Форма входа/регистрации
                  _buildAuthForm(context),

                  const SizedBox(height: 24),

                  // Кнопка входа через Google
                  _buildGoogleSignInButton(context),

                  const SizedBox(height: 16),

                  // Кнопка входа как гость
                  if (!_isSignUpMode) ...[
                    _buildGuestButton(context),
                    const SizedBox(height: 16),
                  ],

                  // Дополнительные действия
                  _buildAdditionalActions(context),
                ],
              ),
            ),
          ),
        ),
      );

  /// Построение заголовка
  Widget _buildHeader(BuildContext context) => Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.event,
              size: 40,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Event Marketplace',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Найдите идеального специалиста для вашего мероприятия',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      );

  /// Построение формы аутентификации
  Widget _buildAuthForm(BuildContext context) => Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Заголовок формы
              Text(
                _isSignUpMode ? 'Регистрация' : 'Вход',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Поля формы
              if (_isSignUpMode) ...[
                _buildDisplayNameField(context),
                const SizedBox(height: 16),
                _buildRoleSelector(context),
                const SizedBox(height: 16),
              ],

              _buildEmailField(context),
              const SizedBox(height: 16),
              _buildPasswordField(context),

              const SizedBox(height: 24),

              // Кнопка отправки
              _buildSubmitButton(context),

              // Ошибка
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _buildErrorMessage(context, _errorMessage!),
              ],

              // Разделитель
              const SizedBox(height: 24),
              _buildDivider(context),
              const SizedBox(height: 24),

              // Кнопки социальных сетей
              _buildSocialButtons(context),
            ],
          ),
        ),
      );

  /// Поле для имени пользователя
  Widget _buildDisplayNameField(BuildContext context) => TextFormField(
        controller: _displayNameController,
        decoration: const InputDecoration(
          labelText: 'Имя',
          hintText: 'Введите ваше имя',
          prefixIcon: Icon(Icons.person),
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (_isSignUpMode && (value == null || value.trim().isEmpty)) {
            return 'Введите имя';
          }
          return null;
        },
      );

  /// Селектор роли
  Widget _buildRoleSelector(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Роль',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<UserRole>(
                      title: const Text('Заказчик'),
                      subtitle: const Text('Ищу специалистов'),
                      value: UserRole.customer,
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedRole = value;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<UserRole>(
                      title: const Text('Специалист'),
                      subtitle: const Text('Предоставляю услуги'),
                      value: UserRole.specialist,
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedRole = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              RadioListTile<UserRole>(
                title: const Text('Организатор'),
                subtitle: const Text('Организую мероприятия'),
                value: UserRole.organizer,
                groupValue: _selectedRole,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      );

  /// Поле для email
  Widget _buildEmailField(BuildContext context) => TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Email',
          hintText: 'Введите ваш email',
          prefixIcon: Icon(Icons.email),
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Введите email';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Введите корректный email';
          }
          return null;
        },
      );

  /// Поле для пароля
  Widget _buildPasswordField(BuildContext context) => TextFormField(
        controller: _passwordController,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'Пароль',
          hintText: 'Введите пароль',
          prefixIcon: Icon(Icons.lock),
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Введите пароль';
          }
          if (_isSignUpMode && value.length < 6) {
            return 'Пароль должен содержать минимум 6 символов';
          }
          return null;
        },
      );

  /// Кнопка отправки
  Widget _buildSubmitButton(BuildContext context) => ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                _isSignUpMode ? 'Зарегистрироваться' : 'Войти',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      );

  /// Кнопка входа как гость
  Widget _buildGuestButton(BuildContext context) => OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleGuestSignIn,
        icon: const Icon(Icons.person_outline),
        label: const Text('Войти как гость'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

  /// Дополнительные действия
  Widget _buildAdditionalActions(BuildContext context) => Column(
        children: [
          // Переключение режима
          TextButton(
            onPressed: () {
              setState(() {
                _isSignUpMode = !_isSignUpMode;
                _errorMessage = null;
              });
            },
            child: Text(
              _isSignUpMode ? 'Уже есть аккаунт? Войти' : 'Нет аккаунта? Зарегистрироваться',
            ),
          ),

          // Сброс пароля
          if (!_isSignUpMode) ...[
            TextButton(
              onPressed: _showResetPasswordDialog,
              child: const Text('Забыли пароль?'),
            ),
          ],
        ],
      );

  /// Сообщение об ошибке
  Widget _buildErrorMessage(BuildContext context, String message) {
    final isSuccess = message.contains('отправлено');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess ? Colors.green : Colors.red,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isSuccess ? Colors.green : Colors.red,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Разделитель
  Widget _buildDivider(BuildContext context) => Row(
        children: [
          Expanded(
            child: Divider(color: Theme.of(context).colorScheme.outline),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'или',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Divider(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      );

  /// Кнопки социальных сетей
  Widget _buildSocialButtons(BuildContext context) => Column(
        children: [
          // Кнопка Google
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _handleGoogleSignIn,
              icon: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              label: const Text('Войти через Google'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Кнопка ВКонтакте
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _handleVKSignIn,
              icon: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFF0077FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'VK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              label: const Text('Войти через ВКонтакте'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );

  /// Кнопка входа через Google
  Widget _buildGoogleSignInButton(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleGoogleSignIn,
          icon: const Icon(Icons.login),
          label: const Text('Войти через Google'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );

  /// Обработка отправки формы
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);

      if (_isSignUpMode) {
        // Регистрация
        final user = await authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          displayName: _displayNameController.text.trim(),
        );

        if (user != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Добро пожаловать, ${user.displayNameOrEmail}!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/home');
        }
      } else {
        // Вход
        final user = await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (user != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Добро пожаловать, ${user.displayNameOrEmail}!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/home');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Обработка входа как гость
  Future<void> _handleGuestSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInAsGuest();

      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Добро пожаловать, гость!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Обработка входа через Google (временно отключено)
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _errorMessage = 'Вход через Google временно отключен';
    });
  }

  /// Обработка входа через ВКонтакте (временно отключено)
  Future<void> _handleVKSignIn() async {
    setState(() {
      _errorMessage = 'Вход через ВКонтакте временно отключен';
    });
  }

  /// Показать диалог сброса пароля
  void _showResetPasswordDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сброс пароля'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Введите email для сброса пароля:'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final authService = ref.read(authServiceProvider);
                await authService.resetPassword(_emailController.text.trim());
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Письмо для сброса пароля отправлено на ${_emailController.text}',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }
}
