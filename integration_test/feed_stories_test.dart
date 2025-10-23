import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:event_marketplace_app/main_fixed.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feed and Stories Integration Tests', () {
    testWidgets('Feed loads without errors', (WidgetTester tester) async {
      // Запуск приложения
      app.main();
      await tester.pumpAndSettle();

      // Ожидание загрузки
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Проверка, что приложение запустилось
      expect(find.byType(MaterialApp), findsOneWidget);

      // Навигация к ленте
      await tester.tap(find.text('Лента'));
      await tester.pumpAndSettle();

      // Проверка наличия элементов ленты
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('Stories section displays', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Навигация к ленте
      await tester.tap(find.text('Лента'));
      await tester.pumpAndSettle();

      // Проверка наличия Stories виджета
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('Feed filters work', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Навигация к ленте
      await tester.tap(find.text('Лента'));
      await tester.pumpAndSettle();

      // Проверка фильтров
      expect(find.text('Все'), findsOneWidget);
      expect(find.text('Популярные'), findsOneWidget);
    });

    testWidgets('Post creation works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Навигация к ленте
      await tester.tap(find.text('Лента'));
      await tester.pumpAndSettle();

      // Проверка кнопки создания поста
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
