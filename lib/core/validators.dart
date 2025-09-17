/// Валидаторы для форм
class Validators {
  /// Валидатор email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Введите корректный email';
    }
    return null;
  }

  /// Валидатор пароля
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    if (value.length < 6) {
      return 'Пароль должен содержать минимум 6 символов';
    }
    return null;
  }

  /// Валидатор подтверждения пароля
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Подтвердите пароль';
    }
    if (value != password) {
      return 'Пароли не совпадают';
    }
    return null;
  }

  /// Валидатор имени
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите имя';
    }
    if (value.length < 2) {
      return 'Имя должно содержать минимум 2 символа';
    }
    return null;
  }

  /// Валидатор телефона
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите номер телефона';
    }
    final cleanPhone = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(cleanPhone)) {
      return 'Введите корректный номер телефона';
    }
    return null;
  }

  /// Валидатор обязательного поля
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Поле'} обязательно для заполнения';
    }
    return null;
  }

  /// Валидатор минимальной длины
  static String? minLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Поле'} обязательно для заполнения';
    }
    if (value.length < minLength) {
      return '${fieldName ?? 'Поле'} должно содержать минимум $minLength символов';
    }
    return null;
  }

  /// Валидатор максимальной длины
  static String? maxLength(String? value, int maxLength, {String? fieldName}) {
    if (value != null && value.length > maxLength) {
      return '${fieldName ?? 'Поле'} должно содержать максимум $maxLength символов';
    }
    return null;
  }

  /// Валидатор цены
  static String? price(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите цену';
    }
    final price = double.tryParse(value.replaceAll(',', '.'));
    if (price == null) {
      return 'Введите корректную цену';
    }
    if (price < 0) {
      return 'Цена не может быть отрицательной';
    }
    return null;
  }

  /// Валидатор количества участников
  static String? participantsCount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите количество участников';
    }
    final count = int.tryParse(value);
    if (count == null) {
      return 'Введите корректное количество';
    }
    if (count < 1) {
      return 'Количество участников должно быть больше 0';
    }
    if (count > 1000) {
      return 'Максимальное количество участников: 1000';
    }
    return null;
  }

  /// Валидатор даты
  static String? date(DateTime? value) {
    if (value == null) {
      return 'Выберите дату';
    }
    if (value.isBefore(DateTime.now())) {
      return 'Дата не может быть в прошлом';
    }
    return null;
  }

  /// Валидатор времени
  static String? time(DateTime? value) {
    if (value == null) {
      return 'Выберите время';
    }
    return null;
  }

  /// Валидатор URL
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL не обязателен
    }
    if (!RegExp(r'^https?:\/\/').hasMatch(value)) {
      return 'Введите корректный URL (начинающийся с http:// или https://)';
    }
    return null;
  }

  /// Валидатор рейтинга
  static String? rating(int? value) {
    if (value == null) {
      return 'Выберите рейтинг';
    }
    if (value < 1 || value > 5) {
      return 'Рейтинг должен быть от 1 до 5';
    }
    return null;
  }

  /// Комбинированный валидатор
  static String? combine(List<String? Function()> validators) {
    for (final validator in validators) {
      final result = validator();
      if (result != null) return result;
    }
    return null;
  }
}
