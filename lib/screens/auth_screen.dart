import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_routes.dart';
import '../providers/auth_providers.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

enum AuthFormType { login, phoneInput, phoneVerify }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  AuthFormType _currentForm = AuthFormType.login;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _smsCodeController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _handleEmailLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Заполните все поля');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await ref.read(loginFormNotifierProvider.notifier).signInWithEmail(
            _emailController.text,
            _passwordController.text,
          );

      _showSuccess('Успешный вход!');

      // Переходим на главный экран
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } on Exception catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleEmailRegister() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Заполните все поля');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await ref.read(loginFormNotifierProvider.notifier).signUpWithEmail(
            _emailController.text,
            _passwordController.text,
            displayName: _displayNameController.text.isNotEmpty
                ? _displayNameController.text
                : null,
          );

      _showSuccess('Успешная регистрация!');

      // Переходим на главный экран
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } on Exception catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePhoneSendCode() async {
    if (_phoneController.text.isEmpty) {
      _showError('Введите номер телефона');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await ref.read(loginFormNotifierProvider.notifier).sendPhoneCode(
            _phoneController.text,
          );

      if (mounted) {
        setState(() {
          _currentForm = AuthFormType.phoneVerify;
        });
        _showSuccess('Код отправлен на ваш номер');
      }
    } on Exception catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePhoneVerifyCode() async {
    if (_smsCodeController.text.isEmpty) {
      _showError('Введите код из SMS');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await ref.read(loginFormNotifierProvider.notifier).confirmPhoneCode(
            _smsCodeController.text,
          );

      _showSuccess('Успешный вход по телефону!');

      // Переходим на главный экран
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } on Exception catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGuestSignIn() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await ref.read(loginFormNotifierProvider.notifier).signInAsGuest();

      _showSuccess('Успешный вход как гость!');

      // Переходим на главный экран
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } on Exception catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleTestEmailLogin() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await ref.read(loginFormNotifierProvider.notifier).signInWithTestEmail();

      _showSuccess('Успешный вход с тестовым email!');

      // Переходим на главный экран
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } on Exception catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleTestPhoneLogin() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await ref.read(loginFormNotifierProvider.notifier).signInWithTestPhone();

      _showSuccess('Успешный вход с тестовым телефоном!');

      // Переходим на главный экран
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } on Exception catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Авторизация'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          centerTitle: true,
          automaticallyImplyLeading:
              false, // Убираем кнопку назад на экране авторизации
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Логотип или заголовок
              const Icon(
                Icons.event,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),

              const Text(
                'Event Marketplace',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              const Text(
                'Найдите идеального специалиста для вашего мероприятия',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Отображение ошибки
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),

              _buildAuthForm(),
              const SizedBox(height: 20),

              if (_currentForm != AuthFormType.phoneVerify) ...[
                // Тестовые кнопки для быстрого входа
                const Text(
                  'Тестовые аккаунты:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                CustomButton(
                  text: 'Войти тестовым email (test@example.com)',
                  onPressed: _isLoading ? null : _handleTestEmailLogin,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 10),

                CustomButton(
                  text: 'Войти тестовым телефоном (+79998887766)',
                  onPressed: _isLoading ? null : _handleTestPhoneLogin,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 10),

                CustomButton(
                  text: 'Войти как гость',
                  onPressed: _isLoading ? null : _handleGuestSignIn,
                  isPrimary: false,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 20),

                // Разделитель
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
                const SizedBox(height: 20),

                // Обычные кнопки
                CustomButton(
                  text: 'Войти по Email',
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _currentForm = AuthFormType.login;
                            _errorMessage = null;
                          });
                        },
                  isPrimary: _currentForm == AuthFormType.login,
                  isLoading: _isLoading && _currentForm == AuthFormType.login,
                ),
                const SizedBox(height: 10),
                CustomButton(
                  text: 'Войти по телефону',
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _currentForm = AuthFormType.phoneInput;
                            _errorMessage = null;
                          });
                        },
                  isPrimary: _currentForm == AuthFormType.phoneInput,
                  isLoading:
                      _isLoading && _currentForm == AuthFormType.phoneInput,
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildAuthForm() {
    switch (_currentForm) {
      case AuthFormType.login:
        return Column(
          children: [
            CustomTextField(
              controller: _emailController,
              labelText: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            CustomTextField(
              controller: _passwordController,
              labelText: 'Пароль',
              obscureText: true,
            ),
            const SizedBox(height: 10),
            CustomTextField(
              controller: _displayNameController,
              labelText: 'Имя (необязательно)',
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Войти',
              onPressed: _isLoading ? null : _handleEmailLogin,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 10),
            CustomButton(
              text: 'Зарегистрироваться',
              onPressed: _isLoading ? null : _handleEmailRegister,
              isPrimary: false,
              isLoading: _isLoading,
            ),
          ],
        );
      case AuthFormType.phoneInput:
        return Column(
          children: [
            CustomTextField(
              controller: _phoneController,
              labelText: 'Номер телефона (+7XXXXXXXXXX)',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            CustomButton(
              text: 'Получить код',
              onPressed: _isLoading ? null : _handlePhoneSendCode,
              isLoading: _isLoading,
            ),
          ],
        );
      case AuthFormType.phoneVerify:
        return Column(
          children: [
            CustomTextField(
              controller: _smsCodeController,
              labelText: 'Код из SMS',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            CustomButton(
              text: 'Подтвердить код',
              onPressed: _isLoading ? null : _handlePhoneVerifyCode,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 10),
            CustomButton(
              text: 'Отменить',
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _currentForm = AuthFormType.phoneInput;
                        _smsCodeController.clear();
                        _errorMessage = null;
                      });
                    },
              isPrimary: false,
            ),
          ],
        );
    }
  }
}
