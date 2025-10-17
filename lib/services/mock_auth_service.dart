import 'package:flutter/material.dart';
import '../models/user.dart';

/// Мок-сервис аутентификации для тестирования без Firebase
class MockAuthService {
  factory MockAuthService() => _instance;
  MockAuthService._internal();
  static final MockAuthService _instance = MockAuthService._internal();

  AppUser? _currentUser;
  final List<AppUser> _users = [
    // Тестовый email аккаунт
    AppUser(
      id: 'test-email-user',
      email: 'testuser@example.com',
      displayName: 'Тестовый пользователь',
      role: UserRole.customer,
      createdAt: DateTime.now(),
    ),
    // Тестовый телефон аккаунт
    AppUser(
      id: 'test-phone-user',
      email: 'phone@example.com',
      displayName: 'Телефонный пользователь',
      role: UserRole.customer,
      createdAt: DateTime.now(),
    ),
  ];

  /// Получить текущего пользователя
  AppUser? get currentUser => _currentUser;

  /// Поток изменений состояния аутентификации
  Stream<AppUser?> get authStateChanges => Stream.value(_currentUser);

  /// Вход по email и паролю
  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      debugPrint('INFO: [mock_auth_service] Попытка входа с email: $email');

      // Имитируем задержку сети
      await Future.delayed(const Duration(seconds: 1));

      // Проверяем тестовый аккаунт
      if (email == 'testuser@example.com' && password == 'Test1234') {
        _currentUser = _users.firstWhere((user) => user.email == email);
        debugPrint('INFO: [mock_auth_service] Успешный вход с email');
        return _currentUser;
      }

      // Проверяем существующих пользователей
      final user = _users.firstWhere(
        (user) => user.email == email,
        orElse: () => throw Exception('user-not-found'),
      );

      // Для демонстрации принимаем любой пароль
      _currentUser = user;
      debugPrint('INFO: [mock_auth_service] Успешный вход с email');
      return _currentUser;
    } catch (e) {
      debugPrint('ERROR: [mock_auth_service] Ошибка входа с email: $e');
      throw _handleAuthException(e.toString());
    }
  }

  /// Регистрация по email и паролю
  Future<AppUser?> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      debugPrint(
        'INFO: [mock_auth_service] Попытка регистрации с email: $email',
      );

      // Имитируем задержку сети
      await Future.delayed(const Duration(seconds: 1));

      // Проверяем, не занят ли email
      if (_users.any((user) => user.email == email)) {
        throw Exception('email-already-in-use');
      }

      // Создаем нового пользователя
      final newUser = AppUser(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: displayName ?? 'Пользователь',
        role: UserRole.customer,
        createdAt: DateTime.now(),
      );

      _users.add(newUser);
      _currentUser = newUser;

      debugPrint('INFO: [mock_auth_service] Успешная регистрация с email');
      return _currentUser;
    } catch (e) {
      debugPrint('ERROR: [mock_auth_service] Ошибка регистрации с email: $e');
      throw _handleAuthException(e.toString());
    }
  }

  /// Вход по телефону
  Future<void> signInWithPhone(String phoneNumber) async {
    try {
      debugPrint(
        'INFO: [mock_auth_service] Отправка SMS на номер: $phoneNumber',
      );

      // Имитируем задержку отправки SMS
      await Future.delayed(const Duration(seconds: 1));

      // Для тестового номера сразу "отправляем" SMS
      if (phoneNumber == '+79998887766') {
        debugPrint(
          'INFO: [mock_auth_service] SMS код отправлен (тестовый режим)',
        );
        return;
      }

      throw Exception('invalid-phone-number');
    } catch (e) {
      debugPrint('ERROR: [mock_auth_service] Ошибка отправки SMS: $e');
      rethrow;
    }
  }

  /// Подтверждение SMS кода
  Future<AppUser?> confirmPhoneCode(String smsCode) async {
    try {
      debugPrint('INFO: [mock_auth_service] Подтверждение SMS кода');

      // Имитируем задержку проверки кода
      await Future.delayed(const Duration(seconds: 1));

      // Проверяем тестовый код
      if (smsCode == '123456') {
        _currentUser = _users.firstWhere((user) => user.id == 'test-phone-user');
        debugPrint('INFO: [mock_auth_service] Успешный вход по телефону');
        return _currentUser;
      }

      throw Exception('invalid-verification-code');
    } catch (e) {
      debugPrint('ERROR: [mock_auth_service] Ошибка подтверждения SMS: $e');
      rethrow;
    }
  }

  /// Вход как гость
  Future<AppUser?> signInAsGuest() async {
    try {
      debugPrint('INFO: [mock_auth_service] Попытка входа как гость');

      // Имитируем задержку
      await Future.delayed(const Duration(milliseconds: 500));

      // Создаем гостевого пользователя
      final guestUser = AppUser(
        id: 'guest-${DateTime.now().millisecondsSinceEpoch}',
        email: 'guest@example.com',
        displayName: 'Гость',
        role: UserRole.guest,
        createdAt: DateTime.now(),
      );

      _currentUser = guestUser;
      debugPrint('INFO: [mock_auth_service] Успешный вход как гость');
      return _currentUser;
    } catch (e) {
      debugPrint('ERROR: [mock_auth_service] Ошибка входа как гость: $e');
      rethrow;
    }
  }

  /// Выход
  Future<void> signOut() async {
    try {
      _currentUser = null;
      debugPrint('INFO: [mock_auth_service] Выход выполнен');
    } catch (e) {
      debugPrint('ERROR: [mock_auth_service] Ошибка выхода: $e');
      rethrow;
    }
  }

  /// Обработка ошибок
  String _handleAuthException(String error) {
    if (error.contains('user-not-found')) {
      return 'Пользователь с таким email не найден';
    } else if (error.contains('wrong-password')) {
      return 'Неверный пароль';
    } else if (error.contains('email-already-in-use')) {
      return 'Такой email уже зарегистрирован';
    } else if (error.contains('weak-password')) {
      return 'Пароль слишком слабый';
    } else if (error.contains('invalid-email')) {
      return 'Неверный формат email';
    } else if (error.contains('invalid-verification-code')) {
      return 'Неверный код подтверждения';
    } else if (error.contains('invalid-phone-number')) {
      return 'Неверный номер телефона';
    } else {
      return 'Произошла ошибка: $error';
    }
  }
}
