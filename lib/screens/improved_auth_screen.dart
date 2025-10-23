import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

/// Улучшенный экран авторизации с вкладками и интеграцией Supabase
class ImprovedAuthScreen extends ConsumerStatefulWidget {
  const ImprovedAuthScreen({super.key});

  @override
  ConsumerState<ImprovedAuthScreen> createState() => _ImprovedAuthScreenState();
}

class _ImprovedAuthScreenState extends ConsumerState<ImprovedAuthScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Контроллеры для Email/Password
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // Контроллеры для телефона
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();

  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _isPasswordVisible = false;
  bool _isSmsSent = false;
  String? _errorMessage;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null && mounted) {
        // Проверяем, есть ли профиль
        final profile = await SupabaseService.getProfile(response.user!.id);
        if (profile == null) {
          // Создаем профиль при первом входе
          await _createProfile(response.user!);
        }

        context.go('/main');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.message);
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'name': _nameController.text.trim()},
      );

      if (response.user != null && mounted) {
        // Создаем профиль
        await _createProfile(response.user!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Регистрация успешна! Проверьте email для подтверждения.')),
        );

        context.go('/main');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.message);
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
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Введите номер телефона';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithOtp(
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isSmsSent = true;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('SMS код отправлен на ваш номер')));
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.message);
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

  Future<void> _verifySmsCode() async {
    if (_smsCodeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Введите код из SMS';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        phone: _phoneController.text.trim(),
        token: _smsCodeController.text.trim(),
        type: OtpType.sms,
      );

      if (response.user != null && mounted) {
        // Проверяем, есть ли профиль
        final profile = await SupabaseService.getProfile(response.user!.id);
        if (profile == null) {
          // Создаем профиль при первом входе
          await _createProfile(response.user!);
        }

        context.go('/main');
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.message);
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

  Future<void> _createProfile(User user) async {
    try {
      final name = user.userMetadata?['name'] ??
          user.email?.split('@')[0] ??
          'Пользователь';
      final username = _generateUsername(name);

      await Supabase.instance.client.from('profiles').insert({
        'id': user.id,
        'username': username,
        'name': name,
        'avatar_url': user.userMetadata?['avatar_url'],
        'city': user.userMetadata?['city'],
        'is_public': true,
        'can_receive_messages': true,
      });
    } catch (e) {
      debugPrint('Ошибка создания профиля: $e');
    }
  }

  String _generateUsername(String name) {
    final base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zа-я0-9]'), '')
        .substring(0, name.length > 10 ? 10 : name.length);
    return '$base${DateTime.now().millisecondsSinceEpoch % 1000}';
  }

  String _getErrorMessage(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Неверный email или пароль';
    } else if (message.contains('Email not confirmed')) {
      return 'Подтвердите email перед входом';
    } else if (message.contains('User already registered')) {
      return 'Пользователь уже зарегистрирован';
    } else if (message.contains('Password should be at least')) {
      return 'Пароль должен содержать минимум 6 символов';
    } else if (message.contains('Invalid phone number')) {
      return 'Неверный формат номера телефона';
    } else if (message.contains('Invalid OTP')) {
      return 'Неверный код подтверждения';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Заголовок
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Логотип
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child:
                        const Icon(Icons.event, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Event Marketplace',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Найдите идеального специалиста для вашего события',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Вкладки
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Email'),
                  Tab(text: 'Телефон'),
                  Tab(text: 'Гость'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Содержимое вкладок
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEmailTab(),
                  _buildPhoneTab(),
                  _buildGuestTab()
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                          color: _isLoginMode
                              ? theme.primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Вход',
                          style: TextStyle(
                            color:
                                _isLoginMode ? Colors.white : Colors.grey[600],
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
                          color: !_isLoginMode
                              ? theme.primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Регистрация',
                          style: TextStyle(
                            color:
                                !_isLoginMode ? Colors.white : Colors.grey[600],
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

            // Поля формы
            if (!_isLoginMode) ...[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите имя';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Введите корректный email';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Пароль',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                border: const OutlineInputBorder(),
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

            const SizedBox(height: 24),

            // Кнопка
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : (_isLoginMode ? _signInWithEmail : _signUpWithEmail),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isLoginMode ? 'Войти' : 'Зарегистрироваться'),
            ),

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
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isSmsSent) ...[
            // Поле телефона
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Номер телефона',
                hintText: '+7 (999) 123-45-67',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите номер телефона';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Кнопка отправки SMS
            ElevatedButton(
              onPressed: _isLoading ? null : _signInWithPhone,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Отправить SMS код'),
            ),
          ] else ...[
            // Поле кода
            TextFormField(
              controller: _smsCodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'SMS код',
                hintText: '123456',
                prefixIcon: Icon(Icons.sms),
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),

            const SizedBox(height: 24),

            // Кнопка подтверждения
            ElevatedButton(
              onPressed: _isLoading ? null : _verifySmsCode,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Подтвердить код'),
            ),

            const SizedBox(height: 16),

            // Кнопка повторной отправки
            TextButton(
              onPressed: () {
                setState(() {
                  _isSmsSent = false;
                  _smsCodeController.clear();
                });
              },
              child: const Text('Отправить код повторно'),
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

          // Информация о безопасности
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: theme.primaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ваши данные защищены. Код действителен 5 минут.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestTab() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.person_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'Гостевой режим',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Вы можете просматривать приложение без регистрации, но для полного функционала потребуется создать аккаунт.',
            style:
                theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              // Создаем анонимного пользователя
              context.go('/main');
            },
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Продолжить как гость'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              _tabController.animateTo(0);
            },
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Создать аккаунт'),
          ),
        ],
      ),
    );
  }
}
