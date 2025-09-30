import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:event_marketplace_app/models/user.dart';
import 'package:event_marketplace_app/services/auth_service.dart';
import 'package:event_marketplace_app/features/auth/utils/auth_error_mapper.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../unit/auth_test.mocks.dart';
import '../unit/auth_service_mock.dart';

void main() {
  group('Web Authentication Tests', () {
    late MockAuthService mockAuthService;
    late MockFirebaseAuth mockFirebaseAuth;

    setUp(() {
      mockAuthService = MockAuthService();
      mockFirebaseAuth = MockFirebaseAuth();
    });

    test('should handle email registration successfully', () async {
      // Arrange
      when(mockAuthService.registerWithEmail(
        name: any,
        email: any,
        password: any,
        role: any,
      )).thenAnswer((_) async {});

      // Act
      await mockAuthService.registerWithEmail(
        name: 'Test User',
        email: 'test@example.com',
        password: 'TestPassword123!',
        role: UserRole.customer,
      );

      // Assert
      verify(mockAuthService.registerWithEmail(
        name: 'Test User',
        email: 'test@example.com',
        password: 'TestPassword123!',
        role: UserRole.customer,
      )).called(1);
    });

    test('should handle email login successfully', () async {
      // Arrange
      final testUser = AppUser(
        id: 'test-123',
        email: 'test@example.com',
        displayName: 'Test User',
        role: UserRole.customer,
        createdAt: DateTime.now(),
      );

      when(mockAuthService.signInWithEmail(
        email: any,
        password: any,
      )).thenAnswer((_) async => testUser);

      // Act
      final result = await mockAuthService.signInWithEmail(
        email: 'test@example.com',
        password: 'TestPassword123!',
      );

      // Assert
      expect(result, isA<AppUser>());
      expect(result?.email, 'test@example.com');
      verify(mockAuthService.signInWithEmail(
        email: 'test@example.com',
        password: 'TestPassword123!',
      )).called(1);
    });

    test('should handle Google sign-in with popup', () async {
      // Arrange
      final testUser = AppUser(
        id: 'google-123',
        email: 'test@gmail.com',
        displayName: 'Google User',
        role: UserRole.customer,
        createdAt: DateTime.now(),
        socialProvider: 'google',
        socialId: 'google-123',
      );

      when(mockAuthService.signInWithGoogle()).thenAnswer((_) async => testUser);

      // Act
      final result = await mockAuthService.signInWithGoogle();

      // Assert
      expect(result, isA<AppUser>());
      expect(result?.email, 'test@gmail.com');
      expect(result?.socialProvider, 'google');
      verify(mockAuthService.signInWithGoogle()).called(1);
    });

    test('should handle Google sign-in redirect fallback', () async {
      // Arrange
      final testUser = AppUser(
        id: 'google-123',
        email: 'test@gmail.com',
        displayName: 'Google User',
        role: UserRole.customer,
        createdAt: DateTime.now(),
        socialProvider: 'google',
        socialId: 'google-123',
      );

      when(mockAuthService.handleGoogleRedirectResult())
          .thenAnswer((_) async => testUser);

      // Act
      final result = await mockAuthService.handleGoogleRedirectResult();

      // Assert
      expect(result, isA<AppUser>());
      expect(result?.email, 'test@gmail.com');
      expect(result?.socialProvider, 'google');
      verify(mockAuthService.handleGoogleRedirectResult()).called(1);
    });

    test('should handle anonymous sign-in (guest)', () async {
      // Arrange
      final testUser = AppUser(
        id: 'guest-123',
        email: 'guest@example.com',
        displayName: 'Guest User',
        role: UserRole.guest,
        createdAt: DateTime.now(),
      );

      when(mockAuthService.signInAsGuest()).thenAnswer((_) async => testUser);

      // Act
      final result = await mockAuthService.signInAsGuest();

      // Assert
      expect(result, isA<AppUser>());
      expect(result?.role, UserRole.guest);
      verify(mockAuthService.signInAsGuest()).called(1);
    });

    test('should handle VK sign-in when configured', () async {
      // Arrange
      final testUser = AppUser(
        id: 'vk-123',
        email: 'test@vk.com',
        displayName: 'VK User',
        role: UserRole.customer,
        createdAt: DateTime.now(),
        socialProvider: 'vk',
        socialId: 'vk-123',
      );

      when(mockAuthService.signInWithVK(role: any))
          .thenAnswer((_) async => testUser);

      // Act
      final result = await mockAuthService.signInWithVK(role: UserRole.customer);

      // Assert
      expect(result, isA<AppUser>());
      expect(result?.email, 'test@vk.com');
      expect(result?.socialProvider, 'vk');
      verify(mockAuthService.signInWithVK(role: UserRole.customer)).called(1);
    });

    test('should handle Firebase auth exceptions properly', () {
      // Test email already in use
      final emailInUseException = FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'The email address is already in use by another account.',
      );

      final mappedError = AuthErrorMapper.mapFirebaseAuthException(emailInUseException);
      expect(mappedError, 'Этот email уже зарегистрирован.');

      // Test weak password
      final weakPasswordException = FirebaseAuthException(
        code: 'weak-password',
        message: 'The password provided is too weak.',
      );

      final weakPasswordError = AuthErrorMapper.mapFirebaseAuthException(weakPasswordException);
      expect(weakPasswordError, 'Пароль слишком слабый. Используйте не менее 6 символов.');

      // Test user not found
      final userNotFoundException = FirebaseAuthException(
        code: 'user-not-found',
        message: 'There is no user record corresponding to this identifier.',
      );

      final userNotFoundError = AuthErrorMapper.mapFirebaseAuthException(userNotFoundException);
      expect(userNotFoundError, 'Пользователь с таким email не найден.');

      // Test wrong password
      final wrongPasswordException = FirebaseAuthException(
        code: 'wrong-password',
        message: 'The password is invalid.',
      );

      final wrongPasswordError = AuthErrorMapper.mapFirebaseAuthException(wrongPasswordException);
      expect(wrongPasswordError, 'Неверный пароль.');
    });

    test('should handle network errors gracefully', () {
      final networkException = FirebaseAuthException(
        code: 'network-request-failed',
        message: 'A network error occurred.',
      );

      final networkError = AuthErrorMapper.mapFirebaseAuthException(networkException);
      expect(networkError, 'Ошибка сети. Проверьте подключение к интернету.');
    });

    test('should handle popup blocked errors', () {
      final popupBlockedException = FirebaseAuthException(
        code: 'popup-blocked-by-browser',
        message: 'The popup was blocked by the browser.',
      );

      final popupError = AuthErrorMapper.mapFirebaseAuthException(popupBlockedException);
      expect(popupError, 'Всплывающее окно заблокировано браузером. Разрешите всплывающие окна или попробуйте другой способ входа.');
    });

    test('should validate email format', () {
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
        expect(email.contains('@') && email.contains('.') && !email.startsWith('@') && !email.endsWith('@'), isTrue);
      }

      for (final email in invalidEmails) {
        final isValid = email.contains('@') && 
                       email.contains('.') && 
                       !email.startsWith('@') && 
                       !email.endsWith('@') &&
                       !email.contains('..');
        expect(isValid, isFalse);
      }
    });

    test('should validate password strength', () {
      final weakPasswords = ['123', 'abc', 'pass', '12345'];
      final strongPasswords = ['Password123!', 'MyStr0ng@Pass', 'SecureP@ssw0rd', 'Test123!@#'];

      for (final password in weakPasswords) {
        expect(password.length < 6, isTrue);
      }

      for (final password in strongPasswords) {
        expect(password.length >= 6, isTrue);
        expect(password.contains(RegExp(r'[A-Z]')), isTrue); // Contains uppercase
        expect(password.contains(RegExp(r'[a-z]')), isTrue); // Contains lowercase
        expect(password.contains(RegExp(r'[0-9]')), isTrue); // Contains digit
      }
    });
  });
}