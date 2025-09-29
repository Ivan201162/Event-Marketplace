import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:event_marketplace_app/models/user.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/services/auth_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'simple_auth_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('Simple Auth Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    test('should create AppUser with required fields', () {
      final user = AppUser(
        id: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
        role: UserRole.customer,
        createdAt: DateTime.now(),
      );

      expect(user.id, 'test-user-id');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.role, UserRole.customer);
      expect(user.isActive, true); // default value
    });

    test('should handle email validation', () {
      // Тест валидации email
      final validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'user+tag@example.org',
      ];

      final invalidEmails = [
        'invalid-email',
        'user@',
        'user@domain',
      ];

      for (final email in validEmails) {
        expect(email.contains('@') && email.contains('.'), isTrue);
      }

      for (final email in invalidEmails) {
        // Проверяем, что email невалиден (не содержит @ или .)
        final isValid = email.contains('@') && email.contains('.');
        if (isValid) {
          print('Unexpected valid email: $email');
        }
        expect(isValid, isFalse);
      }
    });

    test('should handle password validation', () {
      // Тест валидации пароля
      final weakPasswords = ['123', 'abc', 'pass'];
      final strongPasswords = [
        'Password123!',
        'MyStr0ng@Pass',
        'SecureP@ssw0rd'
      ];

      for (final password in weakPasswords) {
        expect(password.length < 6, isTrue);
      }

      for (final password in strongPasswords) {
        expect(password.length >= 6, isTrue);
      }
    });

    test('should mock AuthService signInAsGuest', () async {
      // Создаем мок пользователя
      final mockUser = AppUser(
        id: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
        role: UserRole.customer,
        createdAt: DateTime.now(),
      );

      // Настраиваем мок
      when(mockAuthService.signInAsGuest()).thenAnswer((_) async => mockUser);

      // Вызываем метод
      final result = await mockAuthService.signInAsGuest();

      // Проверяем результат
      expect(result, isNotNull);
      expect(result!.id, 'test-user-id');
      expect(result.email, 'test@example.com');
      expect(result.role, UserRole.customer);

      // Проверяем, что метод был вызван
      verify(mockAuthService.signInAsGuest()).called(1);
    });

    test('should handle AuthService error', () async {
      // Настраиваем мок для возврата ошибки
      when(mockAuthService.signInAsGuest())
          .thenThrow(Exception('Login failed'));

      // Проверяем, что метод выбрасывает исключение
      expect(
        () async => await mockAuthService.signInAsGuest(),
        throwsA(isA<Exception>()),
      );

      // Проверяем, что метод был вызван
      verify(mockAuthService.signInAsGuest()).called(1);
    });

    test('should validate UserRole enum', () {
      expect(UserRole.customer.toString(), 'UserRole.customer');
      expect(UserRole.specialist.toString(), 'UserRole.specialist');
      expect(UserRole.admin.toString(), 'UserRole.admin');
    });

    test('should handle AppUser toMap conversion', () {
      final user = AppUser(
        id: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
        role: UserRole.customer,
        createdAt: DateTime.now(),
      );

      final userMap = user.toMap();

      expect(userMap['id'], 'test-user-id');
      expect(userMap['email'], 'test@example.com');
      expect(userMap['displayName'], 'Test User');
      expect(userMap['role'], 'customer');
      expect(userMap['isActive'], true);
    });

    test('should handle AppUser toMap conversion with all fields', () {
      final user = AppUser(
        id: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
        role: UserRole.customer,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isActive: true,
        socialProvider: 'google',
        socialId: 'google-123',
      );

      final userMap = user.toMap();

      expect(userMap['id'], 'test-user-id');
      expect(userMap['email'], 'test@example.com');
      expect(userMap['displayName'], 'Test User');
      expect(userMap['role'], 'customer');
      expect(userMap['isActive'], true);
      expect(userMap['socialProvider'], 'google');
      expect(userMap['socialId'], 'google-123');
    });
  });
}
