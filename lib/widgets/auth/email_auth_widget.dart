import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Виджет авторизации по email
class EmailAuthWidget extends ConsumerStatefulWidget {
  const EmailAuthWidget({super.key});

  @override
  ConsumerState<EmailAuthWidget> createState() => _EmailAuthWidgetState();
}

class _EmailAuthWidgetState extends ConsumerState<EmailAuthWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = ref.read(authServiceProvider);
    final authLoading = ref.read(authLoadingProvider.notifier);
    final authError = ref.read(authErrorProvider.notifier);

    try {
      authLoading.setLoading(true);
      authError.clearError();

      if (_isSignUp) {
        // Регистрация
        await authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          displayName: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null,
        );
      } else {
        // Вход
        await authService.signInWithEmail(
            _emailController.text.trim(), _passwordController.text,);
      }

      // Переход на главный экран
      if (mounted) {
        context.go('/main');
      }
    } on Exception catch (e) {
      authError.setError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      authLoading.setLoading(false);
    }
  }

  Future<void> _handlePasswordReset() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(
          content: Text('Введите email для восстановления пароля'),),);
      return;
    }

    final authService = ref.read(authServiceProvider);
    final authError = ref.read(authErrorProvider.notifier);

    try {
      await authService.resetPassword(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Письмо для восстановления пароля отправлено на ваш email',),),
        );
      }
    } on Exception catch (e) {
      authError.setError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Переключатель режима
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isSignUp = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isSignUp
                              ? theme.primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Вход',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                !_isSignUp ? Colors.white : theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isSignUp = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isSignUp
                              ? theme.primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Регистрация',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                _isSignUp ? Colors.white : theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Поле имени (только для регистрации)
            if (_isSignUp) ...[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Имя',
                  hintText: 'Введите ваше имя',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
            ],

            // Поле email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Введите ваш email',
                prefixIcon: const Icon(Icons.email_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value.trim())) {
                  return 'Введите корректный email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Поле пароля
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Пароль',
                hintText: 'Введите пароль',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility
                      : Icons.visibility_off,),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textInputAction:
                  _isSignUp ? TextInputAction.next : TextInputAction.done,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите пароль';
                }
                if (_isSignUp && value.length < 6) {
                  return 'Пароль должен содержать минимум 6 символов';
                }
                return null;
              },
            ),

            // Поле подтверждения пароля (только для регистрации)
            if (_isSignUp) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Подтвердите пароль',
                  hintText: 'Повторите пароль',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,),
                    onPressed: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword,),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),),
                ),
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Подтвердите пароль';
                  }
                  if (value != _passwordController.text) {
                    return 'Пароли не совпадают';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 24),

            // Кнопка авторизации
            ElevatedButton(
              onPressed: _handleAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),),
              ),
              child: Text(
                _isSignUp ? 'Зарегистрироваться' : 'Войти',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 16),

            // Кнопка восстановления пароля (только для входа)
            if (!_isSignUp)
              TextButton(
                onPressed: _handlePasswordReset,
                child: Text(
                  'Забыли пароль?',
                  style: TextStyle(
                      color: theme.primaryColor, fontWeight: FontWeight.w500,),
                ),
              ),

            // Дополнительный отступ снизу для безопасности
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
