import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:event_marketplace_app/main_fixed.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Ideas Flow Integration Tests', () {
    testWidgets('Ideas list loads', (WidgetTester tester) async {
      // Запуск приложения
      app.main();
      await tester.pumpAndSettle();

      // Ожидание загрузки
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Навигация к идеям
      await tester.tap(find.text('Идеи'));
      await tester.pumpAndSettle();

      // Проверка наличия элементов идей
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Idea creation works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Навигация к идеям
      await tester.tap(find.text('Идеи'));
      await tester.pumpAndSettle();

      // Проверка кнопки создания идеи
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Idea filters work', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Навигация к идеям
      await tester.tap(find.text('Идеи'));
      await tester.pumpAndSettle();

      // Проверка фильтров
      expect(find.text('Все'), findsOneWidget);
      expect(find.text('Популярные'), findsOneWidget);
      expect(find.text('Недавние'), findsOneWidget);
    });

    testWidgets('Idea interactions work', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Навигация к идеям
      await tester.tap(find.text('Идеи'));
      await tester.pumpAndSettle();

      // Проверка взаимодействий
      expect(find.byIcon(Icons.favorite), findsWidgets);
      expect(find.byIcon(Icons.comment), findsWidgets);
    });
  });
}
