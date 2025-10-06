/// Утилиты для валидации данных
library;

/// Валидация email адреса
bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}

/// Валидация номера телефона
bool isValidPhone(String phone) {
  final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
  return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
}

/// Валидация URL
bool isValidUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  } catch (e) {
    return false;
  }
}

/// Валидация пароля (минимум 8 символов, содержит буквы и цифры)
bool isValidPassword(String password) {
  if (password.length < 8) return false;
  final hasLetter = RegExp('[a-zA-Z]').hasMatch(password);
  final hasDigit = RegExp('[0-9]').hasMatch(password);
  return hasLetter && hasDigit;
}

/// Валидация имени (только буквы, пробелы и дефисы)
bool isValidName(String name) {
  final nameRegex = RegExp(r'^[a-zA-Zа-яА-Я\s\-]+$');
  return nameRegex.hasMatch(name) && name.trim().isNotEmpty;
}

/// Валидация возраста
bool isValidAge(int age) => age >= 0 && age <= 150;

/// Валидация цены
bool isValidPrice(double price) => price >= 0;

/// Валидация рейтинга
bool isValidRating(double rating) => rating >= 0 && rating <= 5;
