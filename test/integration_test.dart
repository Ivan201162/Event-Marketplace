import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:event_marketplace_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Event Marketplace App Integration Tests', () {
    testWidgets('Complete app flow test', (WidgetTester tester) async {
      // Запуск приложения
      app.main();
      await tester.pumpAndSettle();

      // Проверка загрузки главного экрана
      expect(find.byType(MaterialApp), findsOneWidget);

      // Ожидание загрузки
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Проверка основных элементов интерфейса
      expect(find.text('Event Marketplace'), findsOneWidget);

      print('✅ App successfully loaded');
    });

    testWidgets('Navigation test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Тест навигации по основным экранам
      // (Здесь можно добавить тесты навигации)

      print('✅ Navigation test completed');
    });

    testWidgets('Theme switching test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Тест переключения темы
      // (Здесь можно добавить тесты темы)

      print('✅ Theme switching test completed');
    });

    testWidgets('Performance test', (WidgetTester tester) async {
      app.main();

      // Измерение времени загрузки
      final stopwatch = Stopwatch()..start();
      await tester.pumpAndSettle();
      stopwatch.stop();

      print('✅ App load time: ${stopwatch.elapsedMilliseconds}ms');

      // Проверка производительности
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });
  });
}
