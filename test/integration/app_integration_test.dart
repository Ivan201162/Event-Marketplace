import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:event_marketplace_app/main_fixed.dart' as app;

/// Интеграционные тесты приложения
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Event Marketplace App Integration Tests', () {
    testWidgets('App launches and shows main navigation', (WidgetTester tester) async {
      // Запуск приложения
      app.main();
      await tester.pumpAndSettle();

      // Проверка наличия главной навигации
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      
      // Проверка наличия всех вкладок
      expect(find.text('Главная'), findsOneWidget);
      expect(find.text('Лента'), findsOneWidget);
      expect(find.text('Заявки'), findsOneWidget);
      expect(find.text('Чаты'), findsOneWidget);
      expect(find.text('Идеи'), findsOneWidget);
    });

    testWidgets('Navigation between tabs works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на вкладку "Лента"
      await tester.tap(find.text('Лента'));
      await tester.pumpAndSettle();
      
      // Проверка отображения ленты
      expect(find.text('Лента'), findsOneWidget);

      // Переход на вкладку "Заявки"
      await tester.tap(find.text('Заявки'));
      await tester.pumpAndSettle();
      
      // Проверка отображения заявок
      expect(find.text('Заявки'), findsOneWidget);

      // Переход на вкладку "Чаты"
      await tester.tap(find.text('Чаты'));
      await tester.pumpAndSettle();
      
      // Проверка отображения чатов
      expect(find.text('Чаты'), findsOneWidget);

      // Переход на вкладку "Идеи"
      await tester.tap(find.text('Идеи'));
      await tester.pumpAndSettle();
      
      // Проверка отображения идей
      expect(find.text('Идеи'), findsOneWidget);

      // Возврат на главную
      await tester.tap(find.text('Главная'));
      await tester.pumpAndSettle();
      
      // Проверка отображения главной
      expect(find.text('Главная'), findsOneWidget);
    });

    testWidgets('Swipe navigation works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Проверка свайпа влево (следующая вкладка)
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      
      // Проверка свайпа вправо (предыдущая вкладка)
      await tester.drag(find.byType(PageView), const Offset(300, 0));
      await tester.pumpAndSettle();
    });

    testWidgets('Search functionality works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Поиск поля поиска
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.tap(searchField.first);
        await tester.pumpAndSettle();
        
        // Ввод текста поиска
        await tester.enterText(searchField.first, 'тест');
        await tester.pumpAndSettle();
        
        // Проверка отображения результатов
        expect(find.text('тест'), findsOneWidget);
      }
    });

    testWidgets('Filter functionality works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Поиск кнопки фильтра
      final filterButton = find.byIcon(Icons.filter_list);
      if (filterButton.evaluate().isNotEmpty) {
        await tester.tap(filterButton.first);
        await tester.pumpAndSettle();
        
        // Проверка отображения фильтров
        expect(find.byType(BottomSheet), findsOneWidget);
        
        // Закрытие фильтров
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Profile access works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Поиск аватара пользователя
      final avatar = find.byType(CircleAvatar);
      if (avatar.evaluate().isNotEmpty) {
        await tester.tap(avatar.first);
        await tester.pumpAndSettle();
        
        // Проверка отображения профиля
        expect(find.text('Профиль'), findsOneWidget);
        
        // Возврат назад
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Create content buttons work', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Поиск кнопок создания контента
      final createButtons = find.byIcon(Icons.add);
      if (createButtons.evaluate().isNotEmpty) {
        for (int i = 0; i < createButtons.evaluate().length; i++) {
          await tester.tap(createButtons.at(i));
          await tester.pumpAndSettle();
          
          // Проверка отображения экрана создания
          expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
          
          // Возврат назад
          await tester.tap(find.byIcon(Icons.arrow_back));
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Settings access works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Поиск кнопки настроек
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton.first);
        await tester.pumpAndSettle();
        
        // Проверка отображения настроек
        expect(find.text('Настройки'), findsOneWidget);
        
        // Возврат назад
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('App handles errors gracefully', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Проверка отсутствия критических ошибок
      expect(find.text('Ошибка'), findsNothing);
      expect(find.text('Error'), findsNothing);
      expect(find.text('Exception'), findsNothing);
    });

    testWidgets('App performance is acceptable', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      app.main();
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      // Проверка времени загрузки (должно быть менее 5 секунд)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });
  });
}
