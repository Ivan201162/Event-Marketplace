import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';

/// Улучшенный экран аутентификации по телефону
class PhoneAuthImproved extends ConsumerStatefulWidget {
  const PhoneAuthImproved({super.key});

  @override
  ConsumerState<PhoneAuthImproved> createState() => _PhoneAuthImprovedState();
}

class _PhoneAuthImprovedState extends ConsumerState<PhoneAuthImproved> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  
  bool _isLoading = false;
  bool _isCodeSent = false;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_phoneController.text.isEmpty) {
      _showError('Введите номер телефона');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final verificationId = await authService.sendPhoneVerificationCode(
        _phoneController.text.trim(),
      );
      
      setState(() {
        _isCodeSent = true;
        _verificationId = verificationId;
      });
      
      _showSuccess('Код отправлен на номер ${_phoneController.text}');
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty) {
      _showError('Введите код подтверждения');
      return;
    }

    if (_verificationId == null) {
      _showError('Ошибка верификации');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.verifyPhoneCode(
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
      );

      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
              Color(0xFF60A5FA),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Кнопка назад
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.go('/auth'),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Логотип
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.phone,
                    size: 40,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Заголовок
                Text(
                  _isCodeSent ? 'Подтверждение номера' : 'Вход по телефону',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  _isCodeSent 
                    ? 'Введите код из SMS'
                    : 'Введите номер телефона для получения кода',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Карточка с формой
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (!_isCodeSent) ...[
                        // Поле для номера телефона
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Номер телефона',
                            hintText: '+7 (999) 123-45-67',
                            prefixIcon: const Icon(Icons.phone, color: Color(0xFF1E3A8A)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Кнопка отправки кода
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Отправить код',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                          ),
                        ),
                      ] else ...[
                        // Поле для кода подтверждения
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Код подтверждения',
                            hintText: '123456',
                            prefixIcon: const Icon(Icons.sms, color: Color(0xFF1E3A8A)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                            ),
                            counterText: '',
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Кнопка подтверждения
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Подтвердить',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Кнопка повторной отправки
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isCodeSent = false;
                              _codeController.clear();
                            });
                          },
                          child: const Text(
                            'Изменить номер',
                            style: TextStyle(color: Color(0xFF1E3A8A)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Информация
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Код будет отправлен на указанный номер. Убедитесь, что номер указан правильно.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
