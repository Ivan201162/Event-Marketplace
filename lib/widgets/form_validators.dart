import 'package:flutter/material.dart';

/// Валидаторы для форм в стиле Material Design 3
class FormValidators {
  /// Валидатор для обязательных полей
  static String? required(String? value, {String? errorText}) {
    if (value == null || value.trim().isEmpty) {
      return errorText ?? 'Это поле обязательно для заполнения';
    }
    return null;
  }

  /// Валидатор для email
  static String? email(String? value, {String? errorText}) {
    if (value == null || value.trim().isEmpty) {
      return 'Email обязателен';
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (!emailRegex.hasMatch(value.trim())) {
      return errorText ?? 'Введите корректный email';
    }
    return null;
  }

  /// Валидатор для пароля
  static String? password(String? value, {String? errorText}) {
    if (value == null || value.isEmpty) {
      return 'Пароль обязателен';
    }

    if (value.length < 8) {
      return errorText ?? 'Пароль должен содержать минимум 8 символов';
    }

    // Проверка на наличие хотя бы одной цифры
    if (!RegExp('[0-9]').hasMatch(value)) {
      return 'Пароль должен содержать хотя бы одну цифру';
    }

    // Проверка на наличие хотя бы одной буквы
    if (!RegExp('[a-zA-Z]').hasMatch(value)) {
      return 'Пароль должен содержать хотя бы одну букву';
    }

    return null;
  }

  /// Валидатор для подтверждения пароля
  static String? confirmPassword(String? value, String? password, {String? errorText}) {
    if (value == null || value.isEmpty) {
      return 'Подтвердите пароль';
    }

    if (value != password) {
      return errorText ?? 'Пароли не совпадают';
    }

    return null;
  }

  /// Валидатор для номера телефона
  static String? phone(String? value, {String? errorText}) {
    if (value == null || value.trim().isEmpty) {
      return 'Номер телефона обязателен';
    }

    // Убираем все символы кроме цифр
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 10) {
      return errorText ?? 'Введите корректный номер телефона';
    }

    return null;
  }

  /// Валидатор для минимальной длины
  static String? minLength(String? value, int minLength, {String? errorText}) {
    if (value == null || value.trim().length < minLength) {
      return errorText ?? 'Минимум $minLength символов';
    }
    return null;
  }

  /// Валидатор для максимальной длины
  static String? maxLength(String? value, int maxLength, {String? errorText}) {
    if (value != null && value.length > maxLength) {
      return errorText ?? 'Максимум $maxLength символов';
    }
    return null;
  }

  /// Валидатор для числового значения
  static String? number(String? value, {String? errorText}) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите число';
    }

    if (double.tryParse(value.trim()) == null) {
      return errorText ?? 'Введите корректное число';
    }

    return null;
  }

  /// Валидатор для положительного числа
  static String? positiveNumber(String? value, {String? errorText}) {
    final numberError = number(value, errorText: errorText);
    if (numberError != null) return numberError;

    final num = double.parse(value!.trim());
    if (num <= 0) {
      return errorText ?? 'Число должно быть положительным';
    }

    return null;
  }

  /// Валидатор для диапазона чисел
  static String? numberRange(String? value, double min, double max, {String? errorText}) {
    final numberError = number(value, errorText: errorText);
    if (numberError != null) return numberError;

    final num = double.parse(value!.trim());
    if (num < min || num > max) {
      return errorText ?? 'Число должно быть от $min до $max';
    }

    return null;
  }

  /// Валидатор для URL
  static String? url(String? value, {String? errorText}) {
    if (value == null || value.trim().isEmpty) {
      return 'URL обязателен';
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return errorText ?? 'Введите корректный URL';
    }

    return null;
  }

  /// Валидатор для даты
  static String? date(String? value, {String? errorText}) {
    if (value == null || value.trim().isEmpty) {
      return 'Дата обязательна';
    }

    try {
      DateTime.parse(value.trim());
      return null;
    } catch (e) {
      return errorText ?? 'Введите корректную дату';
    }
  }

  /// Валидатор для будущей даты
  static String? futureDate(String? value, {String? errorText}) {
    final dateError = date(value, errorText: errorText);
    if (dateError != null) return dateError;

    final parsedDate = DateTime.parse(value!.trim());
    if (parsedDate.isBefore(DateTime.now())) {
      return errorText ?? 'Дата должна быть в будущем';
    }

    return null;
  }

  /// Валидатор для прошлой даты
  static String? pastDate(String? value, {String? errorText}) {
    final dateError = date(value, errorText: errorText);
    if (dateError != null) return dateError;

    final parsedDate = DateTime.parse(value!.trim());
    if (parsedDate.isAfter(DateTime.now())) {
      return errorText ?? 'Дата должна быть в прошлом';
    }

    return null;
  }

  /// Комбинированный валидатор
  static String? combine(List<String? Function(String?)> validators, String? value) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }
}

/// Виджет для отображения ошибок валидации
class ValidationErrorWidget extends StatelessWidget {
  const ValidationErrorWidget({super.key, required this.error, this.icon, this.style});

  final String error;
  final IconData? icon;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.error_outline, size: 16, color: theme.colorScheme.error),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              error,
              style: style ?? theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения успешной валидации
class ValidationSuccessWidget extends StatelessWidget {
  const ValidationSuccessWidget({super.key, required this.message, this.icon, this.style});

  final String message;
  final IconData? icon;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.check_circle_outline, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              message,
              style: style ?? theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения подсказки
class ValidationHintWidget extends StatelessWidget {
  const ValidationHintWidget({super.key, required this.hint, this.icon, this.style});

  final String hint;
  final IconData? icon;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              hint,
              style:
                  style ??
                  theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения силы пароля
class PasswordStrengthWidget extends StatelessWidget {
  const PasswordStrengthWidget({super.key, required this.password, this.showStrength = true});

  final String password;
  final bool showStrength;

  @override
  Widget build(BuildContext context) {
    if (!showStrength || password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = _calculatePasswordStrength(password);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: strength.score / 4,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(strength.color),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                strength.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: strength.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (strength.suggestions.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...strength.suggestions.map(
              (suggestion) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Text(
                  '• $suggestion',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  PasswordStrength _calculatePasswordStrength(String password) {
    var score = 0;
    final suggestions = <String>[];

    // Длина пароля
    if (password.length >= 8) {
      score++;
    } else {
      suggestions.add('Минимум 8 символов');
    }

    // Наличие цифр
    if (RegExp('[0-9]').hasMatch(password)) {
      score++;
    } else {
      suggestions.add('Добавьте цифры');
    }

    // Наличие строчных букв
    if (RegExp('[a-z]').hasMatch(password)) {
      score++;
    } else {
      suggestions.add('Добавьте строчные буквы');
    }

    // Наличие заглавных букв
    if (RegExp('[A-Z]').hasMatch(password)) {
      score++;
    } else {
      suggestions.add('Добавьте заглавные буквы');
    }

    // Наличие специальных символов
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      score++;
    } else {
      suggestions.add('Добавьте специальные символы');
    }

    String label;
    Color color;

    switch (score) {
      case 0:
      case 1:
        label = 'Слабый';
        color = Colors.red;
        break;
      case 2:
        label = 'Средний';
        color = Colors.orange;
        break;
      case 3:
        label = 'Хороший';
        color = Colors.blue;
        break;
      case 4:
      case 5:
        label = 'Отличный';
        color = Colors.green;
        break;
      default:
        label = 'Слабый';
        color = Colors.red;
    }

    return PasswordStrength(score: score, label: label, color: color, suggestions: suggestions);
  }
}

class PasswordStrength {
  PasswordStrength({
    required this.score,
    required this.label,
    required this.color,
    required this.suggestions,
  });
  final int score;
  final String label;
  final Color color;
  final List<String> suggestions;
}
