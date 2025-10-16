import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Tests', () {
    testWidgets('Email login flow', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for auth screen to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and tap email login button
      final emailButton = find.text('Войти по email');
      if (emailButton.evaluate().isNotEmpty) {
        await tester.tap(emailButton);
        await tester.pumpAndSettle();
      }

      // Enter test email
      final emailField = find.byType(TextField).first;
      if (emailField.evaluate().isNotEmpty) {
        await tester.enterText(emailField, 'test@example.com');
        await tester.pumpAndSettle();
      }

      // Enter test password
      final passwordField = find.byType(TextField).last;
      if (passwordField.evaluate().isNotEmpty) {
        await tester.enterText(passwordField, '123456');
        await tester.pumpAndSettle();
      }

      // Tap login button
      final loginButton = find.text('Войти');
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Verify successful login (should see home screen)
      expect(find.text('Главная'), findsOneWidget);
    });

    testWidgets('Phone login flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find and tap phone login button
      final phoneButton = find.text('Войти по телефону');
      if (phoneButton.evaluate().isNotEmpty) {
        await tester.tap(phoneButton);
        await tester.pumpAndSettle();
      }

      // Enter test phone
      final phoneField = find.byType(TextField).first;
      if (phoneField.evaluate().isNotEmpty) {
        await tester.enterText(phoneField, '+79998887766');
        await tester.pumpAndSettle();
      }

      // Tap send code button
      final sendCodeButton = find.text('Отправить код');
      if (sendCodeButton.evaluate().isNotEmpty) {
        await tester.tap(sendCodeButton);
        await tester.pumpAndSettle();
      }

      // Enter verification code
      final codeField = find.byType(TextField);
      if (codeField.evaluate().isNotEmpty) {
        await tester.enterText(codeField, '1111');
        await tester.pumpAndSettle();
      }

      // Tap verify button
      final verifyButton = find.text('Подтвердить');
      if (verifyButton.evaluate().isNotEmpty) {
        await tester.tap(verifyButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
    });

    testWidgets('Guest login flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find and tap guest login button
      final guestButton = find.text('Войти как гость');
      if (guestButton.evaluate().isNotEmpty) {
        await tester.tap(guestButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Verify guest access (should see limited functionality)
      expect(find.text('Главная'), findsOneWidget);
    });

    testWidgets('Registration flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find and tap registration button
      final registerButton = find.text('Регистрация');
      if (registerButton.evaluate().isNotEmpty) {
        await tester.tap(registerButton);
        await tester.pumpAndSettle();
      }

      // Fill registration form
      final nameField = find.byKey(const Key('name_field'));
      if (nameField.evaluate().isNotEmpty) {
        await tester.enterText(nameField, 'Test User');
        await tester.pumpAndSettle();
      }

      final emailField = find.byKey(const Key('email_field'));
      if (emailField.evaluate().isNotEmpty) {
        await tester.enterText(emailField, 'newuser@example.com');
        await tester.pumpAndSettle();
      }

      final passwordField = find.byKey(const Key('password_field'));
      if (passwordField.evaluate().isNotEmpty) {
        await tester.enterText(passwordField, 'password123');
        await tester.pumpAndSettle();
      }

      // Tap register button
      final submitButton = find.text('Зарегистрироваться');
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
    });

    testWidgets('Logout flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to profile
      final profileButton = find.byIcon(Icons.person);
      if (profileButton.evaluate().isNotEmpty) {
        await tester.tap(profileButton);
        await tester.pumpAndSettle();
      }

      // Find and tap logout button
      final logoutButton = find.text('Выйти');
      if (logoutButton.evaluate().isNotEmpty) {
        await tester.tap(logoutButton);
        await tester.pumpAndSettle();
      }

      // Verify logout (should return to auth screen)
      expect(find.text('Войти'), findsOneWidget);
    });
  });
}


