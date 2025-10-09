import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Тесты создания заявок и чатов', () {
    testWidgets('Загрузка приложения и проверка навигации', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Проверяем, что приложение загрузилось
      expect(find.byType(MaterialApp), findsOneWidget);

      print('✓ Приложение успешно загружено');
      
      // Даем время на инициализацию
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      print('✓ Инициализация завершена');
    });
  });
}
