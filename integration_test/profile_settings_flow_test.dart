import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:event_marketplace_app/main_fixed.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Profile and Settings Flow Integration Tests', () {
    testWidgets('Profile loads with user data', (WidgetTester tester) async {
      // Запуск приложения
      app.main();
      await tester.pumpAndSettle();

      // Ожидание загрузки
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Навигация к профилю
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();

      // Проверка наличия элементов профиля
      expect(find.byType(CircleAvatar), findsWidgets);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('Settings screen loads', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Навигация к настройкам через профиль
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();

      // Проверка наличия кнопки настроек
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('Profile tabs work', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Навигация к профилю
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();

      // Проверка табов профиля
      expect(find.text('Посты'), findsOneWidget);
      expect(find.text('Рилсы'), findsOneWidget);
      expect(find.text('Медиа'), findsOneWidget);
      expect(find.text('Отметки'), findsOneWidget);
    });

    testWidgets('Settings sections work', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Навигация к настройкам
      await tester.tap(find.text('Настройки'));
      await tester.pumpAndSettle();

      // Проверка разделов настроек
      expect(find.text('Профиль'), findsOneWidget);
      expect(find.text('Внешний вид'), findsOneWidget);
      expect(find.text('Уведомления'), findsOneWidget);
      expect(find.text('Конфиденциальность'), findsOneWidget);
      expect(find.text('Pro-аккаунт'), findsOneWidget);
      expect(find.text('Монетизация'), findsOneWidget);
      expect(find.text('Поддержка'), findsOneWidget);
    });

    testWidgets('About dialog shows version', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Навигация к настройкам
      await tester.tap(find.text('Настройки'));
      await tester.pumpAndSettle();

      // Нажатие на "О приложении"
      await tester.tap(find.text('О приложении'));
      await tester.pumpAndSettle();

      // Проверка диалога
      expect(find.text('Event Marketplace'), findsOneWidget);
      expect(find.text('1.0.1 (2)'), findsOneWidget);
    });
  });
}
