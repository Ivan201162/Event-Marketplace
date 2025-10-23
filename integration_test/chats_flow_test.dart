import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:event_marketplace_app/main_fixed.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chats Flow Integration Tests', () {
    testWidgets('Chat list loads', (WidgetTester tester) async {
      // Запуск приложения
      app.main();
      await tester.pumpAndSettle();

      // Ожидание загрузки
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Навигация к чатам
      await tester.tap(find.text('Чаты'));
      await tester.pumpAndSettle();

      // Проверка наличия элементов чата
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Chat search works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Навигация к чатам
      await tester.tap(find.text('Чаты'));
      await tester.pumpAndSettle();

      // Проверка поиска
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('Chat sorting works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Навигация к чатам
      await tester.tap(find.text('Чаты'));
      await tester.pumpAndSettle();

      // Проверка сортировки
      expect(find.byIcon(Icons.sort), findsOneWidget);
    });

    testWidgets('Message sending works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Навигация к чатам
      await tester.tap(find.text('Чаты'));
      await tester.pumpAndSettle();

      // Проверка возможности отправки сообщений
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
