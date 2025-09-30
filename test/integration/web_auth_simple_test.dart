import 'package:flutter_test/flutter_test.dart';
import 'package:event_marketplace_app/models/user.dart';
import 'package:event_marketplace_app/features/auth/utils/auth_error_mapper.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  group('Web Authentication Simple Tests', () {
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

    test('should create AppUser with required fields', () {
      final now = DateTime.now();
      final user = AppUser(
        id: 'test-123',
        email: 'test@example.com',
        role: UserRole.customer,
        createdAt: now,
      );

      expect(user.id, 'test-123');
      expect(user.email, 'test@example.com');
      expect(user.role, UserRole.customer);
      expect(user.createdAt, now);
      expect(user.displayName, isNull);
      expect(user.photoURL, isNull);
      expect(user.phoneNumber, isNull);
      expect(user.isActive, isTrue);
    });

    test('should handle AppUser toMap conversion', () {
      final now = DateTime.now();
      final user = AppUser(
        id: 'test-id',
        email: 'test@test.com',
        role: UserRole.customer,
        createdAt: now,
      );

      final userMap = user.toMap();

      expect(userMap['id'], 'test-id');
      expect(userMap['email'], 'test@test.com');
      expect(userMap['displayName'], isNull);
      expect(userMap['role'], 'customer');
      expect(userMap['isActive'], true);
    });

    test('should handle AppUser toMap conversion with all fields', () {
      final user = AppUser(
        id: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
        photoURL: 'http://example.com/photo.jpg',
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

    test('should validate UserRole enum values', () {
      expect(UserRole.customer.toString(), 'UserRole.customer');
      expect(UserRole.specialist.toString(), 'UserRole.specialist');
      expect(UserRole.admin.toString(), 'UserRole.admin');
      expect(UserRole.guest.toString(), 'UserRole.guest');
    });

    test('should handle Firebase auth exceptions properly', () {
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

    test('should handle network errors gracefully', () {
      final networkException = FirebaseAuthException(
        code: 'network-request-failed',
        message: 'A network error occurred.',
      );

      final networkError = AuthErrorMapper.mapFirebaseAuthException(networkException);
      expect(networkError, 'Ошибка сети. Проверьте подключение к интернету');
    });

    test('should handle popup blocked errors', () {
      final popupBlockedException = FirebaseAuthException(
        code: 'popup-blocked',
        message: 'The popup was blocked by the browser.',
      );

      final popupError = AuthErrorMapper.mapFirebaseAuthException(popupBlockedException);
      expect(popupError, 'Всплывающее окно заблокировано браузером. Разрешите всплывающие окна');
    });

    test('should handle configuration not found error', () {
      final configException = FirebaseAuthException(
        code: 'configuration-not-found',
        message: 'Firebase configuration not found.',
      );

      final configError = AuthErrorMapper.mapFirebaseAuthException(configException);
      expect(configError, 'Конфигурация Firebase не найдена. Проверьте настройки проекта');
    });

    test('should handle operation not allowed error', () {
      final operationException = FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'This operation is not allowed.',
      );

      final operationError = AuthErrorMapper.mapFirebaseAuthException(operationException);
      expect(operationError, 'Операция не разрешена. Проверьте настройки Firebase');
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
  });
}
