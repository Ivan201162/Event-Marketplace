import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Ideas and Reels Tests', () {
    testWidgets('Ideas screen navigation and basic functionality',
        (tester) async {
      // Запуск приложения
      app.main();
      await tester.pumpAndSettle();

      // Ожидание загрузки приложения
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Переход на вкладку "Идеи"
      final ideasTab = find.byIcon(Icons.lightbulb_outline);
      expect(ideasTab, findsOneWidget);
      await tester.tap(ideasTab);
      await tester.pumpAndSettle();

      // Проверка, что экран идей загрузился
      expect(find.text('Идеи'), findsOneWidget);
      expect(find.text('Поиск идей...'), findsOneWidget);

      // Проверка наличия категорий
      expect(find.text('Все'), findsOneWidget);
      expect(find.text('Фото'), findsOneWidget);
      expect(find.text('Видео'), findsOneWidget);

      // Проверка наличия табов
      expect(find.text('Все идеи'), findsOneWidget);
      expect(find.text('Сохраненные'), findsOneWidget);

      // Проверка кнопки добавления идеи
      final addButton = find.byIcon(Icons.add);
      expect(addButton, findsOneWidget);
    });

    testWidgets('Add idea screen functionality', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на вкладку "Идеи"
      final ideasTab = find.byIcon(Icons.lightbulb_outline);
      await tester.tap(ideasTab);
      await tester.pumpAndSettle();

      // Нажатие на кнопку добавления идеи
      final addButton = find.byIcon(Icons.add);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Проверка, что экран добавления идеи открылся
      expect(find.text('Добавить идею'), findsOneWidget);
      expect(find.text('Заголовок *'), findsOneWidget);
      expect(find.text('Описание *'), findsOneWidget);
      expect(find.text('Категория *'), findsOneWidget);

      // Проверка кнопок выбора медиа
      expect(find.text('Фото'), findsOneWidget);
      expect(find.text('Видео'), findsOneWidget);

      // Проверка кнопки публикации
      expect(find.text('Опубликовать'), findsOneWidget);

      // Возврат назад
      final backButton = find.byIcon(Icons.arrow_back);
      await tester.tap(backButton);
      await tester.pumpAndSettle();
    });

    testWidgets('Category filtering', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на вкладку "Идеи"
      final ideasTab = find.byIcon(Icons.lightbulb_outline);
      await tester.tap(ideasTab);
      await tester.pumpAndSettle();

      // Тестирование фильтрации по категориям
      final photoCategory = find.text('Фото');
      if (photoCategory.evaluate().isNotEmpty) {
        await tester.tap(photoCategory);
        await tester.pumpAndSettle();
      }

      final videoCategory = find.text('Видео');
      if (videoCategory.evaluate().isNotEmpty) {
        await tester.tap(videoCategory);
        await tester.pumpAndSettle();
      }

      // Возврат к категории "Все"
      final allCategory = find.text('Все');
      await tester.tap(allCategory);
      await tester.pumpAndSettle();
    });

    testWidgets('Search functionality', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на вкладку "Идеи"
      final ideasTab = find.byIcon(Icons.lightbulb_outline);
      await tester.tap(ideasTab);
      await tester.pumpAndSettle();

      // Тестирование поиска
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'свадьба');
      await tester.pumpAndSettle();

      // Очистка поиска
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
    });

    testWidgets('Grid and list view toggle', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на вкладку "Идеи"
      final ideasTab = find.byIcon(Icons.lightbulb_outline);
      await tester.tap(ideasTab);
      await tester.pumpAndSettle();

      // Переключение между видами отображения
      final viewToggleButton = find.byIcon(Icons.grid_view);
      if (viewToggleButton.evaluate().isNotEmpty) {
        await tester.tap(viewToggleButton);
        await tester.pumpAndSettle();

        // Проверка, что иконка изменилась
        expect(find.byIcon(Icons.list), findsOneWidget);

        // Обратное переключение
        await tester.tap(find.byIcon(Icons.list));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Saved ideas tab', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на вкладку "Идеи"
      final ideasTab = find.byIcon(Icons.lightbulb_outline);
      await tester.tap(ideasTab);
      await tester.pumpAndSettle();

      // Переход на вкладку "Сохраненные"
      final savedTab = find.text('Сохраненные');
      await tester.tap(savedTab);
      await tester.pumpAndSettle();

      // Проверка, что вкладка активна
      expect(savedTab, findsOneWidget);
    });

    testWidgets('Navigation between screens', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Тестирование навигации между вкладками
      final homeTab = find.byIcon(Icons.home_outlined);
      final feedTab = find.byIcon(Icons.newspaper_outlined);
      final bookingsTab = find.byIcon(Icons.assignment_outlined);
      final chatsTab = find.byIcon(Icons.chat_bubble_outline);
      final ideasTab = find.byIcon(Icons.lightbulb_outline);

      // Переход на каждую вкладку
      await tester.tap(homeTab);
      await tester.pumpAndSettle();

      await tester.tap(feedTab);
      await tester.pumpAndSettle();

      await tester.tap(bookingsTab);
      await tester.pumpAndSettle();

      await tester.tap(chatsTab);
      await tester.pumpAndSettle();

      await tester.tap(ideasTab);
      await tester.pumpAndSettle();

      // Проверка, что приложение не вылетело
      expect(find.text('Идеи'), findsOneWidget);
    });

    testWidgets('Back button functionality', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на вкладку "Идеи"
      final ideasTab = find.byIcon(Icons.lightbulb_outline);
      await tester.tap(ideasTab);
      await tester.pumpAndSettle();

      // Нажатие на кнопку добавления идеи
      final addButton = find.byIcon(Icons.add);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Проверка кнопки "Назад"
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);

      // Возврат назад
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Проверка, что вернулись на экран идей
      expect(find.text('Идеи'), findsOneWidget);
    });

    testWidgets('App stability and performance', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Тестирование стабильности приложения
      for (var i = 0; i < 5; i++) {
        // Переход на вкладку "Идеи"
        final ideasTab = find.byIcon(Icons.lightbulb_outline);
        await tester.tap(ideasTab);
        await tester.pumpAndSettle();

        // Переход на другую вкладку
        final homeTab = find.byIcon(Icons.home_outlined);
        await tester.tap(homeTab);
        await tester.pumpAndSettle();

        // Небольшая пауза
        await tester.pump(const Duration(milliseconds: 500));
      }

      // Проверка, что приложение все еще работает
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Error handling and empty states', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на вкладку "Идеи"
      final ideasTab = find.byIcon(Icons.lightbulb_outline);
      await tester.tap(ideasTab);
      await tester.pumpAndSettle();

      // Переход на вкладку "Сохраненные" (может быть пустой)
      final savedTab = find.text('Сохраненные');
      await tester.tap(savedTab);
      await tester.pumpAndSettle();

      // Проверка, что приложение не вылетело при пустом состоянии
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
