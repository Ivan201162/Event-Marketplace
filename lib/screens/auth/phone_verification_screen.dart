import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';

/// Экран ввода SMS кода подтверждения
class PhoneVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const PhoneVerificationScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends ConsumerState<PhoneVerificationScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _timer;
  int _countdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  /// Запуск таймера обратного отсчета
  void _startCountdown() {
    setState(() {
      _countdown = 60;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
          if (_countdown <= 0) {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  /// Валидация SMS кода
  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите код подтверждения';
    }
    if (value.length < 6) {
      return 'Код должен содержать 6 цифр';
    }
    return null;
  }

  /// Проверка SMS кода
  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Обновляем состояние
    ref.read(phoneAuthStateProvider.notifier).setState(PhoneAuthState.verifying);

    try {
      final authService = ref.read(authServiceProvider);
      final verificationId = ref.read(phoneVerificationIdProvider);

      if (verificationId == null) {
        throw FirebaseAuthException(
          code: 'invalid-verification-id',
          message: 'Verification ID not found',
        );
      }

      await authService.verifyPhoneCode(
        verificationId: verificationId,
        smsCode: _codeController.text.trim(),
      );

      // Обновляем состояние
      ref.read(phoneAuthStateProvider.notifier).setState(PhoneAuthState.verified);

      if (mounted) {
        // Переходим на главный экран
        context.go('/main');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Ошибка проверки кода';

      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Неверный код подтверждения';
          break;
        case 'code-expired':
          errorMessage = 'Код истёк. Запросите новый код';
          break;
        case 'session-expired':
          errorMessage = 'Сессия истекла. Начните заново';
          break;
        case 'network-request-failed':
          errorMessage = 'Ошибка сети. Проверьте подключение к интернету';
          break;
        default:
          errorMessage = 'Ошибка проверки кода: ${e.message ?? e.code}';
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

  /// Повторная отправка кода
  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Обновляем состояние
    ref.read(phoneAuthStateProvider.notifier).setState(PhoneAuthState.sending);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendPhoneVerificationCode(widget.phoneNumber);

      // Обновляем verification ID
      ref.read(phoneVerificationIdProvider.notifier).setVerificationId(authService.currentVerificationId);

      // Запускаем новый таймер
      _startCountdown();

      // Обновляем состояние
      ref.read(phoneAuthStateProvider.notifier).setState(PhoneAuthState.codeSent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Код отправлен повторно'), backgroundColor: Colors.green),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Ошибка отправки кода';

      switch (e.code) {
        case 'too-many-requests':
          errorMessage = 'Слишком много запросов. Попробуйте позже';
          break;
        case 'quota-exceeded':
          errorMessage = 'Превышена квота SMS. Попробуйте позже';
          break;
        case 'network-request-failed':
          errorMessage = 'Ошибка сети. Проверьте подключение к интернету';
          break;
        default:
          errorMessage = 'Ошибка отправки кода: ${e.message ?? e.code}';
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
        title: const Text('Подтверждение номера'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
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

                // Иконка SMS
                const Icon(Icons.sms, size: 80, color: Colors.blue),
                const SizedBox(height: 24),

                // Заголовок
                const Text(
                  'Введите код из SMS',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  'Код отправлен на номер\n${widget.phoneNumber}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Поле ввода кода
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Код подтверждения',
                    hintText: '123456',
                    prefixIcon: Icon(Icons.security),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: _validateCode,
                  onChanged: (value) {
                    // Автоматически переходим к проверке при вводе 6 цифр
                    if (value.length == 6) {
                      _verifyCode();
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Кнопка проверки
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Подтвердить', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),

                // Таймер и кнопка повторной отправки
                if (!_canResend)
                  Text(
                    'Повторная отправка через $_countdownс',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  )
                else
                  TextButton(
                    onPressed: _isLoading ? null : _resendCode,
                    child: const Text('Отправить код повторно', style: TextStyle(fontSize: 16)),
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
                          child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Информация
                const Text(
                  'Не получили SMS? Проверьте правильность номера или попробуйте позже',
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
