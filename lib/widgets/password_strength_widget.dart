import 'package:flutter/material.dart';

import '../models/security_password_strength.dart';
import '../services/security_service.dart';

/// Виджет для отображения силы пароля
class PasswordStrengthWidget extends StatefulWidget {
  const PasswordStrengthWidget({
    super.key,
    required this.password,
    this.onStrengthChanged,
    this.showRecommendations = true,
  });
  final String password;
  final VoidCallback? onStrengthChanged;
  final bool showRecommendations;

  @override
  State<PasswordStrengthWidget> createState() => _PasswordStrengthWidgetState();
}

class _PasswordStrengthWidgetState extends State<PasswordStrengthWidget> {
  final SecurityService _securityService = SecurityService();
  SecurityPasswordStrength? _strength;

  @override
  void initState() {
    super.initState();
    _updateStrength();
  }

  @override
  void didUpdateWidget(PasswordStrengthWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.password != widget.password) {
      _updateStrength();
    }
  }

  Future<void> _updateStrength() async {
    final result =
        await _securityService.checkPasswordStrength(widget.password);
    setState(() {
      _strength = SecurityPasswordStrength.fromMap(result);
    });
    widget.onStrengthChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_strength == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Индикатор силы пароля
        _buildStrengthIndicator(),

        const SizedBox(height: 8),

        // Процентное значение
        _buildPercentageIndicator(),

        if (widget.showRecommendations && _strength!.issues.isNotEmpty) ...[
          const SizedBox(height: 12),

          // Рекомендации
          _buildRecommendations(),
        ],
      ],
    );
  }

  Widget _buildStrengthIndicator() => Row(
        children: [
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Colors.grey[300],
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _strength!.percentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: _getStrengthColor(_strength!.level),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Текст уровня
          Text(
            _getStrengthText(_strength!.level),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getStrengthColor(_strength!.level),
            ),
          ),
        ],
      );

  Widget _buildPercentageIndicator() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Сила пароля: ${_strength!.score}/${_strength!.maxScore}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            '${_strength!.percentage.toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getStrengthColor(_strength!.level),
            ),
          ),
        ],
      );

  Widget _buildRecommendations() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 8),
                Text(
                  'Рекомендации:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._strength!.issues.map(
              (issue) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 4,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Color _getStrengthColor(PasswordStrength level) {
    switch (level) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.blue;
      case PasswordStrength.veryStrong:
        return Colors.green;
    }
  }

  String _getStrengthText(PasswordStrength level) {
    switch (level) {
      case PasswordStrength.weak:
        return 'Слабый';
      case PasswordStrength.medium:
        return 'Средний';
      case PasswordStrength.strong:
        return 'Сильный';
      case PasswordStrength.veryStrong:
        return 'Очень сильный';
    }
  }
}

/// Виджет для генерации пароля
class PasswordGeneratorWidget extends StatefulWidget {
  const PasswordGeneratorWidget({
    super.key,
    required this.onPasswordGenerated,
    this.initialPassword,
  });
  final Function(String) onPasswordGenerated;
  final String? initialPassword;

  @override
  State<PasswordGeneratorWidget> createState() =>
      _PasswordGeneratorWidgetState();
}

class _PasswordGeneratorWidgetState extends State<PasswordGeneratorWidget> {
  final SecurityService _securityService = SecurityService();

  int _length = 12;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;

  String _generatedPassword = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialPassword != null) {
      _generatedPassword = widget.initialPassword!;
    } else {
      _generatePassword();
    }
  }

  void _generatePassword() {
    setState(() {
      _generatedPassword = _securityService.generateSecurePassword(
        length: _length,
        includeUppercase: _includeUppercase,
        includeLowercase: _includeLowercase,
        includeNumbers: _includeNumbers,
        includeSpecialChars: _includeSymbols,
      );
    });
    widget.onPasswordGenerated(_generatedPassword);
  }

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Генератор паролей',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Сгенерированный пароль
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _generatedPassword,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        // TODO(developer): Копировать в буфер обмена
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Пароль скопирован')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Настройки генерации
              const Text(
                'Настройки:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              // Длина пароля
              Row(
                children: [
                  const Text('Длина: '),
                  Expanded(
                    child: Slider(
                      value: _length.toDouble(),
                      min: 4,
                      max: 32,
                      divisions: 28,
                      label: _length.toString(),
                      onChanged: (value) {
                        setState(() {
                          _length = value.round();
                        });
                        _generatePassword();
                      },
                    ),
                  ),
                  Text('$_length'),
                ],
              ),

              // Опции
              CheckboxListTile(
                title: const Text('Заглавные буквы (A-Z)'),
                value: _includeUppercase,
                onChanged: (value) {
                  setState(() {
                    _includeUppercase = value!;
                  });
                  _generatePassword();
                },
                dense: true,
              ),

              CheckboxListTile(
                title: const Text('Строчные буквы (a-z)'),
                value: _includeLowercase,
                onChanged: (value) {
                  setState(() {
                    _includeLowercase = value!;
                  });
                  _generatePassword();
                },
                dense: true,
              ),

              CheckboxListTile(
                title: const Text('Цифры (0-9)'),
                value: _includeNumbers,
                onChanged: (value) {
                  setState(() {
                    _includeNumbers = value!;
                  });
                  _generatePassword();
                },
                dense: true,
              ),

              CheckboxListTile(
                title: const Text('Специальные символы (!@#...)'),
                value: _includeSymbols,
                onChanged: (value) {
                  setState(() {
                    _includeSymbols = value!;
                  });
                  _generatePassword();
                },
                dense: true,
              ),

              const SizedBox(height: 16),

              // Кнопка генерации
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generatePassword,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Сгенерировать новый пароль'),
                ),
              ),
            ],
          ),
        ),
      );
}
