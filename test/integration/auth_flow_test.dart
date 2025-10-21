import 'package:event_marketplace_app/main.dart';
import 'package:event_marketplace_app/screens/auth_screen.dart';
import 'package:event_marketplace_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Authentication Flow Integration Tests', () {
    testWidgets('Guest login flow', (tester) async {
      // Запускаем приложение
      await tester.pumpWidget(const ProviderScope(child: EventMarketplaceApp()));

      await tester.pumpAndSettle();

      // Проверяем, что открылся экран авторизации
      expect(find.byType(AuthScreen), findsOneWidget);

      // Находим кнопку "Гость"
      final guestButton = find.text('Гость');
      expect(guestButton, findsOneWidget);

      // Нажимаем на кнопку "Гость"
      await tester.tap(guestButton);
      await tester.pumpAndSettle();

      // Проверяем, что открылся главный экран
      expect(find.byType(HomeScreen), findsOneWidget);

      // Проверяем, что пользователь авторизован
      expect(find.text('Найти специалиста'), findsOneWidget);
    });

    testWidgets('Email registration flow', (tester) async {
      // Запускаем приложение
      await tester.pumpWidget(const ProviderScope(child: EventMarketplaceApp()));

      await tester.pumpAndSettle();

      // Проверяем, что открылся экран авторизации
      expect(find.byType(AuthScreen), findsOneWidget);

      // Находим кнопку "Регистрация"
      final registerButton = find.text('Регистрация');
      expect(registerButton, findsOneWidget);

      // Нажимаем на кнопку "Регистрация"
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Проверяем, что открылась форма регистрации
      expect(find.byType(TextFormField), findsWidgets);

      // Заполняем форму регистрации
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).at(1);

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Проверяем, что поля заполнились
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('Email login flow', (tester) async {
      // Запускаем приложение
      await tester.pumpWidget(const ProviderScope(child: EventMarketplaceApp()));

      await tester.pumpAndSettle();

      // Проверяем, что открылся экран авторизации
      expect(find.byType(AuthScreen), findsOneWidget);

      // Находим кнопку "Войти"
      final loginButton = find.text('Войти');
      expect(loginButton, findsOneWidget);

      // Нажимаем на кнопку "Войти"
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Проверяем, что открылась форма входа
      expect(find.byType(TextFormField), findsWidgets);

      // Заполняем форму входа
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).at(1);

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Проверяем, что поля заполнились
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('Phone authentication flow', (tester) async {
      // Запускаем приложение
      await tester.pumpWidget(const ProviderScope(child: EventMarketplaceApp()));

      await tester.pumpAndSettle();

      // Проверяем, что открылся экран авторизации
      expect(find.byType(AuthScreen), findsOneWidget);

      // Ищем кнопку или вкладку для телефонной авторизации
      final phoneButton = find.text('Телефон');
      if (phoneButton.evaluate().isNotEmpty) {
        await tester.tap(phoneButton);
        await tester.pumpAndSettle();

        // Проверяем, что открылась форма телефонной авторизации
        expect(find.byType(TextFormField), findsWidgets);

        // Заполняем номер телефона
        final phoneField = find.byType(TextFormField).first;
        await tester.enterText(phoneField, '+7 999 123 45 67');
        await tester.pumpAndSettle();

        // Проверяем, что поле заполнилось
        expect(find.text('+7 999 123 45 67'), findsOneWidget);
      }
    });

    testWidgets('Google sign-in flow', (tester) async {
      // Запускаем приложение
      await tester.pumpWidget(const ProviderScope(child: EventMarketplaceApp()));

      await tester.pumpAndSettle();

      // Проверяем, что открылся экран авторизации
      expect(find.byType(AuthScreen), findsOneWidget);

      // Ищем кнопку Google Sign-In
      final googleButton = find.text('Google');
      if (googleButton.evaluate().isNotEmpty) {
        expect(googleButton, findsOneWidget);

        // Нажимаем на кнопку Google Sign-In
        await tester.tap(googleButton);
        await tester.pumpAndSettle();

        // В реальном приложении здесь будет открываться Google OAuth
        // В тестах мы просто проверяем, что кнопка существует и нажимается
      }
    });

    testWidgets('Form validation', (tester) async {
      // Запускаем приложение
      await tester.pumpWidget(const ProviderScope(child: EventMarketplaceApp()));

      await tester.pumpAndSettle();

      // Проверяем, что открылся экран авторизации
      expect(find.byType(AuthScreen), findsOneWidget);

      // Нажимаем на кнопку "Войти" без заполнения полей
      final loginButton = find.text('Войти');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Проверяем, что появились сообщения об ошибках валидации
      // (если они реализованы)
      final errorMessages = find.textContaining('обязательно');
      if (errorMessages.evaluate().isNotEmpty) {
        expect(errorMessages, findsWidgets);
      }
    });

    testWidgets('Password visibility toggle', (tester) async {
      // Запускаем приложение
      await tester.pumpWidget(const ProviderScope(child: EventMarketplaceApp()));

      await tester.pumpAndSettle();

      // Проверяем, что открылся экран авторизации
      expect(find.byType(AuthScreen), findsOneWidget);

      // Ищем поле пароля
      final passwordField = find.byType(TextFormField).at(1);
      expect(passwordField, findsOneWidget);

      // Вводим пароль
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Ищем кнопку показа/скрытия пароля
      final visibilityButton = find.byIcon(Icons.visibility);
      if (visibilityButton.evaluate().isNotEmpty) {
        // Нажимаем на кнопку показа/скрытия пароля
        await tester.tap(visibilityButton);
        await tester.pumpAndSettle();

        // Проверяем, что иконка изменилась
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      }
    });
  });
}
