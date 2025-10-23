import 'package:event_marketplace_app/core/navigation/back_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Back Navigation Tests', () {
    testWidgets('BackNav.exitOrHome should show snackbar on first press',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => BackNav.exitOrHome(context),
                child: const Text('Exit'),
              ),
            ),
          ),
        ),
      );

      // Нажимаем кнопку выхода
      await tester.tap(find.text('Exit'));
      await tester.pumpAndSettle();

      // Проверяем, что показался SnackBar
      expect(find.text('Нажмите «Назад» ещё раз, чтобы выйти'), findsOneWidget);
    });

    testWidgets('BackNav.safeBack should work without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => BackNav.safeBack(context),
                child: const Text('Back'),
              ),
            ),
          ),
        ),
      );

      // Нажимаем кнопку назад
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Проверяем, что не было ошибок
      expect(find.text('Back'), findsOneWidget);
    });
  });
}
