import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:event_marketplace_app/services/auth_service.dart';
import 'package:event_marketplace_app/features/auth/utils/auth_error_mapper.dart';
import 'package:event_marketplace_app/models/user.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final bool isRegistration;
  final String? name;
  final UserRole? role;

  const PhoneVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.isRegistration = false,
    this.name,
    this.role,
  });

  @override
  ConsumerState<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends ConsumerState<PhoneVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int _resendTimer = 0;
  bool _canResend = true;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 60;
      _canResend = false;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendTimer--;
          if (_resendTimer <= 0) {
            _canResend = true;
            return false;
          }
        });
        return true;
      }
      return false;
    });
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length != 6) {
      setState(() {
        _errorMessage = 'Введите 6-значный код';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.verifySmsCode(
        verificationId: widget.verificationId,
        smsCode: _codeController.text,
      );

      if (user != null && mounted) {
        if (widget.isRegistration) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Регистрация успешна!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Вход выполнен успешно!'),
              backgroundColor: Colors.green,
            ),
          );
        }
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

  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithPhone(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (credential) async {
          // Автоматическая верификация
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
          setState(() {
            _isLoading = false;
          });
          _startResendTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS отправлена повторно'),
              backgroundColor: Colors.green,
            ),
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подтверждение номера'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              
              // Иконка
              const Icon(
                Icons.sms,
                size: 80,
                color: Colors.blue,
              ),
              
              const SizedBox(height: 24),
              
              // Заголовок
              Text(
                'Подтверждение номера',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Описание
              Text(
                'Мы отправили SMS с кодом подтверждения на номер\n${widget.phoneNumber}',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Поле ввода кода
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  labelText: 'Код подтверждения',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                onChanged: (value) {
                  if (value.length == 6) {
                    _verifyCode();
                  }
                },
              ),
              
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
              
              // Кнопка подтверждения
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Подтвердить'),
              ),
              
              const SizedBox(height: 16),
              
              // Кнопка повторной отправки
              OutlinedButton(
                onPressed: _canResend && !_isLoading ? _resendCode : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _canResend
                    ? const Text('Отправить код повторно')
                    : Text('Повторная отправка через $_resendTimer сек'),
              ),
              
              const SizedBox(height: 24),
              
              // Ссылка назад
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Назад'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
