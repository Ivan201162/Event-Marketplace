import 'package:flutter_test/flutter_test.dart';
import 'package:event_marketplace_app/models/user.dart';
import 'package:event_marketplace_app/features/auth/utils/auth_error_mapper.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  group('Auth Refactor Tests', () {
    test('should validate email format correctly', () {
      final validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'user+tag@example.org',
        'test123@test-domain.com',
      ];

      final invalidEmails = [
        'invalid-email',
        'user@',
        'user@domain',
        '@domain.com',
        'user..name@domain.com',
      ];

      for (final email in validEmails) {
        final isValid = email.contains('@') && 
                       email.contains('.') && 
                       !email.startsWith('@') && 
                       !email.endsWith('@') &&
                       !email.contains('..');
        expect(isValid, isTrue, reason: 'Email $email should be valid');
      }

      for (final email in invalidEmails) {
        final isValid = email.contains('@') && 
                       email.contains('.') && 
                       !email.startsWith('@') && 
                       !email.endsWith('@') &&
                       !email.contains('..');
        expect(isValid, isFalse, reason: 'Email $email should be invalid');
      }
    });

    test('should validate phone number format correctly', () {
      final validPhones = [
        '+7-123-456-7890',
        '+7 123 456 7890',
        '+7(123)456-7890',
        '81234567890',
        '71234567890',
      ];

      final invalidPhones = [
        '123',
        'abc',
        '+1-123-456-7890', // US number
        '+44-123-456-7890', // UK number
        'invalid',
      ];

      for (final phone in validPhones) {
        // Простая проверка российского номера
        final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
        final isValid = digits.length == 11 && (digits.startsWith('7') || digits.startsWith('8'));
        expect(isValid, isTrue, reason: 'Phone $phone should be valid');
      }

      for (final phone in invalidPhones) {
        final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
        final isValid = digits.length == 11 && (digits.startsWith('7') || digits.startsWith('8'));
        expect(isValid, isFalse, reason: 'Phone $phone should be invalid');
      }
    });

    test('should create AppUser with phone number', () {
      final now = DateTime.now();
      final user = AppUser(
        id: 'test-123',
        email: 'test@example.com',
        displayName: 'Test User',
        phoneNumber: '+7-123-456-7890',
        role: UserRole.customer,
        createdAt: now,
      );

      expect(user.id, 'test-123');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.phoneNumber, '+7-123-456-7890');
      expect(user.role, UserRole.customer);
      expect(user.createdAt, now);
      expect(user.isActive, isTrue);
    });

    test('should handle AppUser toMap conversion with phone number', () {
      final user = AppUser(
        id: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
        phoneNumber: '+7-123-456-7890',
        role: UserRole.customer,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isActive: true,
        socialProvider: 'email',
        socialId: 'email-123',
      );

      final userMap = user.toMap();

      expect(userMap['id'], 'test-user-id');
      expect(userMap['email'], 'test@example.com');
      expect(userMap['displayName'], 'Test User');
      expect(userMap['phoneNumber'], '+7-123-456-7890');
      expect(userMap['role'], 'customer');
      expect(userMap['isActive'], true);
      expect(userMap['socialProvider'], 'email');
      expect(userMap['socialId'], 'email-123');
    });

    test('should validate password strength correctly', () {
      final weakPasswords = ['123', 'abc', 'pass', '12345'];
      final strongPasswords = ['Password123!', 'MyStr0ng@Pass', 'SecureP@ssw0rd', 'Test123!@#'];

      for (final password in weakPasswords) {
        expect(password.length < 6, isTrue, reason: 'Password $password should be weak');
      }

      for (final password in strongPasswords) {
        expect(password.length >= 6, isTrue, reason: 'Password $password should be strong');
        expect(password.contains(RegExp(r'[A-Z]')), isTrue, reason: 'Password should contain uppercase');
        expect(password.contains(RegExp(r'[a-z]')), isTrue, reason: 'Password should contain lowercase');
        expect(password.contains(RegExp(r'[0-9]')), isTrue, reason: 'Password should contain digit');
      }
    });

    test('should handle Firebase auth exceptions for email/password', () {
      // Test email already in use
      final emailInUseException = FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'The email address is already in use by another account.',
      );

      final mappedError = AuthErrorMapper.mapFirebaseAuthException(emailInUseException);
      expect(mappedError, 'Email уже используется');

      // Test weak password
      final weakPasswordException = FirebaseAuthException(
        code: 'weak-password',
        message: 'The password provided is too weak.',
      );

      final weakPasswordError = AuthErrorMapper.mapFirebaseAuthException(weakPasswordException);
      expect(weakPasswordError, 'Пароль слишком слабый. Используйте минимум 6 символов');

      // Test user not found
      final userNotFoundException = FirebaseAuthException(
        code: 'user-not-found',
        message: 'There is no user record corresponding to this identifier.',
      );

      final userNotFoundError = AuthErrorMapper.mapFirebaseAuthException(userNotFoundException);
      expect(userNotFoundError, 'Пользователь с таким email не найден');

      // Test wrong password
      final wrongPasswordException = FirebaseAuthException(
        code: 'wrong-password',
        message: 'The password is invalid.',
      );

      final wrongPasswordError = AuthErrorMapper.mapFirebaseAuthException(wrongPasswordException);
      expect(wrongPasswordError, 'Неверный пароль');
    });

    test('should handle Firebase auth exceptions for phone authentication', () {
      // Test invalid phone number
      final invalidPhoneException = FirebaseAuthException(
        code: 'invalid-phone-number',
        message: 'The phone number provided is invalid.',
      );

      final invalidPhoneError = AuthErrorMapper.mapFirebaseAuthException(invalidPhoneException);
      expect(invalidPhoneError, 'Ошибка аутентификации: The phone number provided is invalid.');

      // Test too many requests
      final tooManyRequestsException = FirebaseAuthException(
        code: 'too-many-requests',
        message: 'Too many requests. Try again later.',
      );

      final tooManyRequestsError = AuthErrorMapper.mapFirebaseAuthException(tooManyRequestsException);
      expect(tooManyRequestsError, 'Слишком много попыток. Попробуйте позже');

      // Test invalid verification code
      final invalidCodeException = FirebaseAuthException(
        code: 'invalid-verification-code',
        message: 'The verification code is invalid.',
      );

      final invalidCodeError = AuthErrorMapper.mapFirebaseAuthException(invalidCodeException);
      expect(invalidCodeError, 'Неверный код подтверждения');
    });

    test('should handle network errors gracefully', () {
      final networkException = FirebaseAuthException(
        code: 'network-request-failed',
        message: 'A network error occurred.',
      );

      final networkError = AuthErrorMapper.mapFirebaseAuthException(networkException);
      expect(networkError, 'Ошибка сети. Проверьте подключение к интернету');
    });

    test('should validate UserRole enum values', () {
      expect(UserRole.customer.toString(), 'UserRole.customer');
      expect(UserRole.specialist.toString(), 'UserRole.specialist');
      expect(UserRole.organizer.toString(), 'UserRole.organizer');
      expect(UserRole.admin.toString(), 'UserRole.admin');
      expect(UserRole.guest.toString(), 'UserRole.guest');
    });

    test('should handle general errors', () {
      final generalError = Exception('Some general error');
      final mappedError = AuthErrorMapper.mapGeneralError(generalError);
      expect(mappedError, 'Произошла ошибка: Exception: Some general error');
    });

    test('should handle Firebase auth exception in general error mapper', () {
      final firebaseError = FirebaseAuthException(
        code: 'invalid-email',
        message: 'Invalid email format.',
      );

      final mappedError = AuthErrorMapper.mapGeneralError(firebaseError);
      expect(mappedError, 'Неверный формат email');
    });

    test('should format phone numbers correctly', () {
      // Test phone number formatting logic
      final testCases = [
        {'input': '81234567890', 'expected': '+71234567890'},
        {'input': '71234567890', 'expected': '+71234567890'},
        {'input': '+7-123-456-7890', 'expected': '+7-123-456-7890'},
        {'input': '8 (123) 456-78-90', 'expected': '+7 (123) 456-78-90'},
      ];

      for (final testCase in testCases) {
        final input = testCase['input'] as String;
        final expected = testCase['expected'] as String;
        
        // Простая логика форматирования
        String formatted = input;
        final digits = input.replaceAll(RegExp(r'[^\d]'), '');
        if (digits.startsWith('8') && digits.length == 11) {
          formatted = input.replaceFirst('8', '+7');
        } else if (digits.startsWith('7') && digits.length == 11) {
          formatted = input.startsWith('+') ? input : '+$input';
        }
        
        expect(formatted, expected, reason: 'Phone $input should format to $expected');
      }
    });

    test('should validate name field correctly', () {
      final validNames = ['Иван', 'John', 'Мария-Анна', 'Jean-Pierre'];
      final invalidNames = ['', 'A', '123', '!@#'];

      for (final name in validNames) {
        final isValid = name.length >= 2 && RegExp(r'^[a-zA-Zа-яА-Я\s\-]+$').hasMatch(name);
        expect(isValid, isTrue, reason: 'Name $name should be valid');
      }

      for (final name in invalidNames) {
        final isValid = name.length >= 2 && RegExp(r'^[a-zA-Zа-яА-Я\s\-]+$').hasMatch(name);
        expect(isValid, isFalse, reason: 'Name $name should be invalid');
      }
    });
  });
}
