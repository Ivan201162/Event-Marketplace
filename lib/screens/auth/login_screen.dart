import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:event_marketplace_app/services/auth_service.dart';
import 'package:event_marketplace_app/features/auth/utils/auth_error_mapper.dart';
import 'package:event_marketplace_app/models/user.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEmailMode = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (user != null) {
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final phoneNumber = authService.formatPhoneNumber(_phoneController.text.trim());
      
      if (!authService.isValidPhoneNumber(phoneNumber)) {
        setState(() {
          _errorMessage = 'Неверный формат номера телефона';
        });
        return;
      }

      // Отправляем SMS
      await authService.signInWithPhone(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) async {
          // Автоматическая верификация (обычно на мобильных устройствах)
          try {
            final user = await authService.verifySmsCode(
              verificationId: credential.verificationId ?? '',
              smsCode: credential.smsCode ?? '',
            );
            if (user != null && mounted) {
              context.go('/home');
            }
          } catch (e) {
            setState(() {
              _errorMessage = e.toString().replaceFirst('Exception: ', '');
            });
          }
        },
        verificationFailed: (error) {
          setState(() {
            _errorMessage = AuthErrorMapper.mapFirebaseAuthException(error);
          });
        },
        codeSent: (verificationId, resendToken) {
          // Переходим на экран ввода кода
          if (mounted) {
            context.push('/auth/phone-verification', extra: {
              'verificationId': verificationId,
              'phoneNumber': phoneNumber,
            });
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          // Таймаут автоматического получения кода
          setState(() {
            _errorMessage = 'Время ожидания SMS истекло. Попробуйте еще раз.';
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInAsGuest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInAsGuest();

      if (user != null && mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                
                // Переключатель режима входа
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Email'),
                            value: true,
                            groupValue: _isEmailMode,
                            onChanged: (value) {
                              setState(() {
                                _isEmailMode = value!;
                                _errorMessage = null;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Телефон'),
                            value: false,
                            groupValue: _isEmailMode,
                            onChanged: (value) {
                              setState(() {
                                _isEmailMode = value!;
                                _errorMessage = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Поля ввода
                if (_isEmailMode) ...[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите email';
                      }
                      if (!value.contains('@')) {
                        return 'Введите корректный email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Пароль',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите пароль';
                      }
                      if (value.length < 6) {
                        return 'Пароль должен содержать минимум 6 символов';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Номер телефона',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                      hintText: '+7 (999) 123-45-67',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите номер телефона';
                      }
                      return null;
                    },
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Сообщение об ошибке
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Кнопка входа
                ElevatedButton(
                  onPressed: _isLoading ? null : (_isEmailMode ? _signInWithEmail : _signInWithPhone),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEmailMode ? 'Войти' : 'Отправить SMS'),
                ),
                
                const SizedBox(height: 16),
                
                // Кнопка входа как гость
                OutlinedButton(
                  onPressed: _isLoading ? null : _signInAsGuest,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Войти как гость'),
                ),
                
                const SizedBox(height: 24),
                
                // Ссылка на регистрацию
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Нет аккаунта? '),
                    TextButton(
                      onPressed: () => context.push('/auth/register'),
                      child: const Text('Зарегистрироваться'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Ссылка на восстановление пароля
                if (_isEmailMode)
                  TextButton(
                    onPressed: () => context.push('/auth/reset-password'),
                    child: const Text('Забыли пароль?'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
