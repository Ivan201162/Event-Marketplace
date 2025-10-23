import 'package:flutter/material.dart';
import '../../models/user_profile_enhanced.dart';

/// Виджет настройки двухфакторной аутентификации
class TwoFactorSetupWidget extends StatefulWidget {
  const TwoFactorSetupWidget({
    super.key,
    this.currentSettings,
  });

  final SecuritySettings? currentSettings;

  @override
  State<TwoFactorSetupWidget> createState() => _TwoFactorSetupWidgetState();
}

class _TwoFactorSetupWidgetState extends State<TwoFactorSetupWidget> {
  late bool _isEnabled;
  late TwoFactorMethod _selectedMethod;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.currentSettings?.twoFactorEnabled ?? false;
    _selectedMethod = widget.currentSettings?.twoFactorMethod ?? TwoFactorMethod.sms;
  }

  /// Включить/выключить 2FA
  Future<void> _toggleTwoFactor() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Реализовать включение/выключение 2FA
      await Future.delayed(const Duration(seconds: 1)); // Заглушка
      
      setState(() => _isEnabled = !_isEnabled);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnabled 
                ? 'Двухфакторная аутентификация включена' 
                : 'Двухфакторная аутентификация отключена',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Изменить метод 2FA
  Future<void> _changeMethod() async {
    final result = await showDialog<TwoFactorMethod>(
      context: context,
      builder: (context) => _MethodSelectionDialog(
        currentMethod: _selectedMethod,
      ),
    );

    if (result != null) {
      setState(() => _isLoading = true);

      try {
        // TODO: Реализовать смену метода 2FA
        await Future.delayed(const Duration(seconds: 1)); // Заглушка
        
        setState(() => _selectedMethod = result);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Метод двухфакторной аутентификации изменен'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Двухфакторная аутентификация'),
        actions: [
          if (_isEnabled)
            TextButton(
              onPressed: _isLoading ? null : _toggleTwoFactor,
              child: const Text('Отключить'),
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Статус 2FA
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Статус',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Switch(
                          value: _isEnabled,
                          onChanged: _isLoading ? null : (value) => _toggleTwoFactor(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEnabled 
                          ? 'Двухфакторная аутентификация включена' 
                          : 'Двухфакторная аутентификация отключена',
                      style: TextStyle(
                        color: _isEnabled ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Метод аутентификации
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Метод аутентификации',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ListTile(
                      leading: Icon(_getMethodIcon(_selectedMethod)),
                      title: Text(_getMethodTitle(_selectedMethod)),
                      subtitle: Text(_getMethodDescription(_selectedMethod)),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _isLoading ? null : _changeMethod,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Информация о безопасности
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.security, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Безопасность',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Двухфакторная аутентификация добавляет дополнительный уровень безопасности к вашему аккаунту.',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Рекомендации
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'Рекомендации',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Используйте приложение-аутентификатор для максимальной безопасности\n'
                      '• Сохраните резервные коды в безопасном месте\n'
                      '• Регулярно проверяйте активные сессии',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMethodIcon(TwoFactorMethod method) {
    switch (method) {
      case TwoFactorMethod.sms:
        return Icons.sms;
      case TwoFactorMethod.email:
        return Icons.email;
      case TwoFactorMethod.authenticator:
        return Icons.security;
    }
  }

  String _getMethodTitle(TwoFactorMethod method) {
    switch (method) {
      case TwoFactorMethod.sms:
        return 'SMS';
      case TwoFactorMethod.email:
        return 'Email';
      case TwoFactorMethod.authenticator:
        return 'Приложение-аутентификатор';
    }
  }

  String _getMethodDescription(TwoFactorMethod method) {
    switch (method) {
      case TwoFactorMethod.sms:
        return 'Коды будут отправляться на ваш номер телефона';
      case TwoFactorMethod.email:
        return 'Коды будут отправляться на ваш email';
      case TwoFactorMethod.authenticator:
        return 'Используйте приложение Google Authenticator или аналогичное';
    }
  }
}

/// Диалог выбора метода 2FA
class _MethodSelectionDialog extends StatefulWidget {
  const _MethodSelectionDialog({
    required this.currentMethod,
  });

  final TwoFactorMethod currentMethod;

  @override
  State<_MethodSelectionDialog> createState() => _MethodSelectionDialogState();
}

class _MethodSelectionDialogState extends State<_MethodSelectionDialog> {
  late TwoFactorMethod _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.currentMethod;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Выберите метод'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: TwoFactorMethod.values.map((method) => RadioListTile<TwoFactorMethod>(
          title: Text(_getMethodTitle(method)),
          subtitle: Text(_getMethodDescription(method)),
          value: method,
          groupValue: _selectedMethod,
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedMethod = value);
            }
          },
        )).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedMethod),
          child: const Text('Выбрать'),
        ),
      ],
    );
  }

  String _getMethodTitle(TwoFactorMethod method) {
    switch (method) {
      case TwoFactorMethod.sms:
        return 'SMS';
      case TwoFactorMethod.email:
        return 'Email';
      case TwoFactorMethod.authenticator:
        return 'Приложение-аутентификатор';
    }
  }

  String _getMethodDescription(TwoFactorMethod method) {
    switch (method) {
      case TwoFactorMethod.sms:
        return 'Коды будут отправляться на ваш номер телефона';
      case TwoFactorMethod.email:
        return 'Коды будут отправляться на ваш email';
      case TwoFactorMethod.authenticator:
        return 'Используйте приложение Google Authenticator или аналогичное';
    }
  }
}
