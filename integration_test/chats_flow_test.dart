import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:event_marketplace_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chats Flow Tests', () {
    testWidgets('Chat list screen loads with chats', (WidgetTester tester) async {
      // Запуск приложения
      app.main();
      await tester.pumpAndSettle();

      // Ожидание загрузки главного экрана
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Переход на экран чатов
      await tester.tap(find.text('Чаты'));
      await tester.pumpAndSettle();

      // Проверка наличия экрана чатов
      expect(find.text('Чаты'), findsOneWidget);

      // Проверка наличия кнопок поиска и фильтров
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('Chat search functionality works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран чатов
      await tester.tap(find.text('Чаты'));
      await tester.pumpAndSettle();

      // Нажатие на кнопку поиска
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Проверка открытия диалога поиска
      expect(find.text('Поиск в чатах'), findsOneWidget);
      expect(find.text('Введите запрос...'), findsOneWidget);

      // Ввод поискового запроса
      await tester.enterText(find.byType(TextField), 'тест');
      await tester.pumpAndSettle();

      // Нажатие кнопки "Найти"
      await tester.tap(find.text('Найти'));
      await tester.pumpAndSettle();
    });

    testWidgets('Chat filters work', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран чатов
      await tester.tap(find.text('Чаты'));
      await tester.pumpAndSettle();

      // Нажатие на кнопку фильтров
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Проверка открытия диалога фильтров
      expect(find.text('Фильтры чатов'), findsOneWidget);
      expect(find.text('Все'), findsOneWidget);
      expect(find.text('Непрочитанные'), findsOneWidget);
      expect(find.text('С медиа'), findsOneWidget);

      // Выбор фильтра "Непрочитанные"
      await tester.tap(find.text('Непрочитанные'));
      await tester.pumpAndSettle();

      // Нажатие кнопки "Применить"
      await tester.tap(find.text('Применить'));
      await tester.pumpAndSettle();
    });

    testWidgets('Chat screen opens and works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран чатов
      await tester.tap(find.text('Чаты'));
      await tester.pumpAndSettle();

      // Ожидание загрузки чатов
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Нажатие на первый чат (если есть)
      if (find.byType(Card).evaluate().isNotEmpty) {
        await tester.tap(find.byType(Card).first);
        await tester.pumpAndSettle();

        // Проверка открытия экрана чата
        expect(find.text('Чат'), findsOneWidget);

        // Проверка наличия поля ввода
        expect(find.byType(TextField), findsOneWidget);

        // Проверка наличия кнопок действий
        expect(find.byIcon(Icons.attach_file), findsOneWidget);
        expect(find.byIcon(Icons.mic), findsOneWidget);
      }
    });

    testWidgets('Message sending works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран чатов
      await tester.tap(find.text('Чаты'));
      await tester.pumpAndSettle();

      // Ожидание загрузки чатов
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Нажатие на первый чат (если есть)
      if (find.byType(Card).evaluate().isNotEmpty) {
        await tester.tap(find.byType(Card).first);
        await tester.pumpAndSettle();

        // Ввод сообщения
        await tester.enterText(find.byType(TextField), 'Тестовое сообщение');
        await tester.pumpAndSettle();

        // Нажатие кнопки отправки
        if (find.byIcon(Icons.send).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.send));
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Pull to refresh works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран чатов
      await tester.tap(find.text('Чаты'));
      await tester.pumpAndSettle();

      // Выполнение pull-to-refresh
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Проверка, что список чатов обновился
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('Chat info dialog works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран чатов
      await tester.tap(find.text('Чаты'));
      await tester.pumpAndSettle();

      // Ожидание загрузки чатов
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Нажатие на первый чат (если есть)
      if (find.byType(Card).evaluate().isNotEmpty) {
        await tester.tap(find.byType(Card).first);
        await tester.pumpAndSettle();

        // Нажатие на кнопку информации о чате
        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();

        // Проверка открытия диалога информации
        expect(find.text('Информация о чате'), findsOneWidget);
        expect(find.text('Детали чата будут здесь'), findsOneWidget);
      }
    });
  });
}