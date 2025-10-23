import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';

/// Виджет авторизации по телефону
class PhoneAuthWidget extends ConsumerStatefulWidget {
  const PhoneAuthWidget({super.key});

  @override
  ConsumerState<PhoneAuthWidget> createState() => _PhoneAuthWidgetState();
}

class _PhoneAuthWidgetState extends ConsumerState<PhoneAuthWidget> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isCodeSent = false;
  final bool _isCodeVerified = false;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = ref.read(authServiceProvider);
    final authLoading = ref.read(authLoadingProvider.notifier);
    final authError = ref.read(authErrorProvider.notifier);

    try {
      authLoading.setLoading(true);
      authError.clearError();

      await authService.signInWithPhone(_phoneController.text.trim());

      setState(() {
        _isCodeSent = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('SMS код отправлен на ваш номер')));
      }
    } on Exception catch (e) {
      authError.setError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      authLoading.setLoading(false);
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите код из SMS')));
      return;
    }

    final authService = ref.read(authServiceProvider);
    final authLoading = ref.read(authLoadingProvider.notifier);
    final authError = ref.read(authErrorProvider.notifier);

    try {
      authLoading.setLoading(true);
      authError.clearError();

      await authService.confirmPhoneCode(_codeController.text.trim());

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

  void _resendCode() {
    setState(() {
      _isCodeSent = false;
      _codeController.clear();
    });
    _sendCode();
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
            // Заголовок
            Text(
              _isCodeSent ? 'Подтвердите номер' : 'Вход по телефону',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              _isCodeSent
                  ? 'Введите код из SMS, отправленного на ${_phoneController.text}'
                  : 'Введите номер телефона для получения SMS кода',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            if (!_isCodeSent) ...[
              // Поле телефона
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Номер телефона',
                  hintText: '+7 (999) 123-45-67',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите номер телефона';
                  }
                  // Простая валидация российского номера
                  final phone = value.trim().replaceAll(RegExp(r'[^\d+]'), '');
                  if (phone.length < 10) {
                    return 'Введите корректный номер телефона';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Кнопка отправки кода
              ElevatedButton(
                onPressed: _sendCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Отправить код',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ] else ...[
              // Поле кода
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'SMS код',
                  hintText: '123456',
                  prefixIcon: const Icon(Icons.sms_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  counterText: '',
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _verifyCode(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите код из SMS';
                  }
                  if (value.trim().length < 4) {
                    return 'Код должен содержать минимум 4 цифры';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Кнопка подтверждения кода
              ElevatedButton(
                onPressed: _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Подтвердить код',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),

              // Кнопка повторной отправки
              TextButton(
                onPressed: _resendCode,
                child: Text(
                  'Отправить код повторно',
                  style: TextStyle(
                      color: theme.primaryColor, fontWeight: FontWeight.w500),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Информация о безопасности
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.primaryColor.withValues(alpha: 0.3)),
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

            // Дополнительный отступ снизу для безопасности
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
