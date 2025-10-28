import 'package:event_marketplace_app/core/safe_log.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Экран аутентификации по номеру телефона
class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  bool _isCodeSent = false;
  bool _isVerifying = false;
  String? _errorMessage;
  String? _successMessage;
  int _countdown = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Вход по телефону'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Заголовок
                  _buildHeader(context),

                  const SizedBox(height: 32),

                  // Форма
                  _buildForm(context),

                  const SizedBox(height: 24),

                  // Кнопки действий
                  _buildActionButtons(context),

                  const SizedBox(height: 16),

                  // Сообщения
                  if (_errorMessage != null) _buildErrorMessage(context),
                  if (_successMessage != null) _buildSuccessMessage(context),

                  const SizedBox(height: 24),

                  // Дополнительные действия
                  _buildAdditionalActions(context),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildHeader(BuildContext context) => Column(
        children: [
          Icon(Icons.phone_android,
              size: 64, color: Theme.of(context).primaryColor,),
          const SizedBox(height: 16),
          Text(
            _isCodeSent ? 'Введите код из SMS' : 'Вход по номеру телефона',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _isCodeSent
                ? 'Мы отправили код на номер ${_phoneController.text}'
                : 'Введите номер телефона для получения SMS кода',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      );

  Widget _buildForm(BuildContext context) => Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isCodeSent) ...[
                // Поле номера телефона
                _buildPhoneField(context),
                const SizedBox(height: 16),
              ] else ...[
                // Поле SMS кода
                _buildCodeField(context),
                const SizedBox(height: 16),

                // Счетчик обратного отсчета
                if (_countdown > 0) _buildCountdown(context),
              ],
            ],
          ),
        ),
      );

  Widget _buildPhoneField(BuildContext context) => TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(15),
        ],
        decoration: const InputDecoration(
          labelText: 'Номер телефона',
          hintText: '+7 (999) 123-45-67',
          prefixIcon: Icon(Icons.phone),
          border: OutlineInputBorder(),
          helperText: 'Введите номер в международном формате',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Введите номер телефона';
          }
          if (value.length < 10) {
            return 'Номер телефона слишком короткий';
          }
          return null;
        },
        onChanged: (value) {
          // Форматирование номера телефона
          if (value.isNotEmpty && !value.startsWith('+')) {
            _phoneController.value = _phoneController.value.copyWith(
              text: '+$value',
              selection: TextSelection.collapsed(offset: value.length + 1),
            );
          }
        },
      );

  Widget _buildCodeField(BuildContext context) => TextFormField(
        controller: _codeController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        decoration: const InputDecoration(
          labelText: 'SMS код',
          hintText: '123456',
          prefixIcon: Icon(Icons.sms),
          border: OutlineInputBorder(),
          helperText: 'Введите 6-значный код из SMS',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Введите SMS код';
          }
          if (value.length != 6) {
            return 'SMS код должен содержать 6 цифр';
          }
          return null;
        },
      );

  Widget _buildCountdown(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer, color: Colors.blue.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              'Повторная отправка через $_countdown сек',
              style: TextStyle(
                  color: Colors.blue.shade700, fontWeight: FontWeight.w500,),
            ),
          ],
        ),
      );

  Widget _buildActionButtons(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isCodeSent) ...[
            // Кнопка отправки SMS
            ElevatedButton(
              onPressed: _isLoading ? null : _sendSMSCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Отправка SMS...'),
                      ],
                    )
                  : const Text(
                      'Отправить SMS код',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ] else ...[
            // Кнопка входа с кодом
            ElevatedButton(
              onPressed: _isVerifying ? null : _verifySMSCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isVerifying
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Проверка кода...'),
                      ],
                    )
                  : const Text('Войти',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
            ),

            const SizedBox(height: 12),

            // Кнопка повторной отправки
            OutlinedButton(
              onPressed: _countdown > 0 ? null : _resendSMSCode,
              child: const Text('Отправить код повторно'),
            ),
          ],
        ],
      );

  Widget _buildErrorMessage(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                    color: Colors.red.shade700, fontWeight: FontWeight.w500,),
              ),
            ),
          ],
        ),
      );

  Widget _buildSuccessMessage(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _successMessage!,
                style: TextStyle(
                    color: Colors.green.shade700, fontWeight: FontWeight.w500,),
              ),
            ),
          ],
        ),
      );

  Widget _buildAdditionalActions(BuildContext context) => Column(
        children: [
          TextButton(
            onPressed: () => context.go('/auth'),
            child: const Text('Вернуться к обычному входу'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/auth?mode=guest'),
            child: const Text('Войти как гость'),
          ),
        ],
      );

  Future<void> _sendSMSCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final phoneNumber = _phoneController.text.trim();

      SafeLog.info('Отправка SMS кода на номер: $phoneNumber');

      await authService.signInWithPhone(phoneNumber);

      setState(() {
        _isCodeSent = true;
        _isLoading = false;
        _successMessage = 'SMS код отправлен на номер $phoneNumber';
        _countdown = 60; // 60 секунд до возможности повторной отправки
      });

      // Запускаем обратный отсчет
      _startCountdown();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      SafeLog.error('Ошибка отправки SMS кода', e);
    }
  }

  Future<void> _verifySMSCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final smsCode = _codeController.text.trim();

      SafeLog.info('Проверка SMS кода: $smsCode');

      final user = await authService.confirmPhoneCode(smsCode);

      if (user != null && mounted) {
        setState(() {
          _isVerifying = false;
          _successMessage =
              'Успешный вход! Добро пожаловать, ${user.displayNameOrEmail}';
        });

        // Показываем уведомление об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Добро пожаловать, ${user.displayNameOrEmail}!'),
            backgroundColor: Colors.green,
          ),
        );

        // Переходим на главную страницу
        context.go('/home');
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Не удалось войти. Проверьте код и попробуйте снова.';
        });
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _errorMessage = e.toString();
      });

      SafeLog.error('Ошибка проверки SMS кода', e);
    }
  }

  Future<void> _resendSMSCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final phoneNumber = _phoneController.text.trim();

      SafeLog.info('Повторная отправка SMS кода на номер: $phoneNumber');

      await authService.signInWithPhone(phoneNumber);

      setState(() {
        _isLoading = false;
        _successMessage = 'SMS код повторно отправлен';
        _countdown = 60; // Сбрасываем счетчик
      });

      // Запускаем обратный отсчет
      _startCountdown();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      SafeLog.error('Ошибка повторной отправки SMS кода', e);
    }
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _countdown--;
        });
        return _countdown > 0;
      }
      return false;
    });
  }
}
