import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:event_marketplace_app/main_fixed.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Requests Flow Integration Tests', () {
    testWidgets('Create request flow', (WidgetTester tester) async {
      // Запуск приложения
      app.main();
      await tester.pumpAndSettle();

      // Ожидание загрузки
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Навигация к заявкам
      await tester.tap(find.text('Заявки'));
      await tester.pumpAndSettle();

      // Проверка наличия кнопки создания заявки
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Нажатие на кнопку создания заявки
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Проверка открытия экрана создания заявки
      expect(find.text('Создать заявку'), findsOneWidget);
    });

    testWidgets('Request filters work', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Навигация к заявкам
      await tester.tap(find.text('Заявки'));
      await tester.pumpAndSettle();

      // Проверка фильтров
      expect(find.text('Все'), findsOneWidget);
      expect(find.text('В ожидании'), findsOneWidget);
      expect(find.text('Подтверждено'), findsOneWidget);
    });

    testWidgets('Request sorting works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Навигация к заявкам
      await tester.tap(find.text('Заявки'));
      await tester.pumpAndSettle();

      // Проверка сортировки
      expect(find.text('По дате'), findsOneWidget);
      expect(find.text('По бюджету'), findsOneWidget);
    });

    testWidgets('Request status changes', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Навигация к заявкам
      await tester.tap(find.text('Заявки'));
      await tester.pumpAndSettle();

      // Проверка статусов заявок
      expect(find.byType(Card), findsWidgets);
    });
  });
}
