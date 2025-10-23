import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';

/// Экран ввода номера телефона для авторизации
class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Валидация номера телефона
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите номер телефона';
    }

    // Убираем все символы кроме цифр
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    // Проверяем формат +7XXXXXXXXXX или 8XXXXXXXXXX
    if (digitsOnly.startsWith('8') && digitsOnly.length == 11) {
      return null; // 8XXXXXXXXXX
    } else if (digitsOnly.startsWith('7') && digitsOnly.length == 11) {
      return null; // 7XXXXXXXXXX
    } else if (digitsOnly.length == 10) {
      return null; // XXXXXXXXXX (будем добавлять +7)
    }

    return 'Введите корректный номер телефона (+7XXXXXXXXXX)';
  }

  /// Отправка SMS кода
  Future<void> _sendVerificationCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Обновляем состояние
    ref.read(phoneAuthStateProvider.notifier).setState(PhoneAuthState.sending);

    try {
      String phoneNumber = _phoneController.text.trim();

      // Нормализуем номер телефона
      if (phoneNumber.startsWith('8')) {
        phoneNumber = '+7${phoneNumber.substring(1)}';
      } else if (phoneNumber.startsWith('7')) {
        phoneNumber = '+$phoneNumber';
      } else if (phoneNumber.length == 10) {
        phoneNumber = '+7$phoneNumber';
      }

      debugPrint('📱 Отправка SMS на номер: $phoneNumber');

      // Сохраняем номер телефона
      ref.read(phoneNumberProvider.notifier).setPhoneNumber(phoneNumber);

      final authService = ref.read(authServiceProvider);
      await authService.sendPhoneVerificationCode(phoneNumber);

      // Обновляем состояние
      ref
          .read(phoneAuthStateProvider.notifier)
          .setState(PhoneAuthState.codeSent);
      ref
          .read(phoneVerificationIdProvider.notifier)
          .setVerificationId(authService.currentVerificationId);

      if (mounted) {
        // Переходим на экран ввода кода
        context.push('/phone-verification', extra: phoneNumber);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Ошибка отправки SMS';

      switch (e.code) {
        case 'invalid-phone-number':
          errorMessage = 'Неверный формат номера телефона';
          break;
        case 'too-many-requests':
          errorMessage = 'Слишком много запросов. Попробуйте позже';
          break;
        case 'quota-exceeded':
          errorMessage = 'Превышена квота SMS. Попробуйте позже';
          break;
        case 'network-request-failed':
          errorMessage = 'Ошибка сети. Проверьте подключение к интернету';
          break;
        case 'billing-not-enabled':
          errorMessage =
              'Phone Authentication не настроена. Обратитесь к администратору';
          break;
        default:
          errorMessage = 'Ошибка отправки SMS: ${e.message ?? e.code}';
      }

      // Обновляем состояние ошибки
      ref.read(phoneAuthStateProvider.notifier).setState(PhoneAuthState.error);

      setState(() {
        _errorMessage = errorMessage;
      });
    } catch (e) {
      // Обновляем состояние ошибки
      ref.read(phoneAuthStateProvider.notifier).setState(PhoneAuthState.error);

      setState(() {
        _errorMessage = 'Произошла ошибка: ${e.toString()}';
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
        title: const Text('Вход по телефону'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Иконка телефона
                const Icon(Icons.phone_android, size: 80, color: Colors.blue),
                const SizedBox(height: 24),

                // Заголовок
                const Text(
                  'Введите номер телефона',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                const Text(
                  'Мы отправим SMS с кодом подтверждения',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Поле ввода номера
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Номер телефона',
                    hintText: '+7 (999) 123-45-67',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validatePhoneNumber,
                  onChanged: (value) {
                    // Автоматически форматируем номер
                    if (value.isNotEmpty && !value.startsWith('+')) {
                      if (value.startsWith('8')) {
                        _phoneController.value =
                            _phoneController.value.copyWith(
                          text: '+7${value.substring(1)}',
                          selection: TextSelection.collapsed(
                            offset: '+7${value.substring(1)}'.length,
                          ),
                        );
                      } else if (value.startsWith('7')) {
                        _phoneController.value =
                            _phoneController.value.copyWith(
                          text: '+$value',
                          selection:
                              TextSelection.collapsed(offset: '+$value'.length),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Кнопка отправки
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendVerificationCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Отправить код',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),

                // Сообщение об ошибке
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!,
                              style: TextStyle(color: Colors.red.shade700)),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Информация о конфиденциальности
                const Text(
                  'Нажимая "Отправить код", вы соглашаетесь с условиями использования и политикой конфиденциальности',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
