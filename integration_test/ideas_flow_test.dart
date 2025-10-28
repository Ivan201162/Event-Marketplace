import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Ideas Flow Tests', () {
    testWidgets('Ideas screen loads with ideas list',
        (tester) async {
      // Запуск приложения
      app.main();
      await tester.pumpAndSettle();

      // Ожидание загрузки главного экрана
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Переход на экран идей
      await tester.tap(find.text('Идеи'));
      await tester.pumpAndSettle();

      // Проверка наличия экрана идей
      expect(find.text('Идеи'), findsOneWidget);

      // Проверка наличия кнопки добавления
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Проверка наличия кнопок поиска и фильтров
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('Create idea flow works', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран идей
      await tester.tap(find.text('Идеи'));
      await tester.pumpAndSettle();

      // Нажатие на кнопку добавления идеи
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Проверка открытия модального окна создания идеи
      expect(find.text('Создать идею'), findsOneWidget);

      // Заполнение текста идеи
      await tester.enterText(
          find.byKey(const Key('idea_text_field')), 'Тестовая идея',);
      await tester.pumpAndSettle();

      // Добавление тегов
      await tester.enterText(find.byKey(const Key('tags_field')), 'тест, идея');
      await tester.pumpAndSettle();

      // Нажатие кнопки "Опубликовать"
      await tester.tap(find.text('Опубликовать'));
      await tester.pumpAndSettle();

      // Проверка закрытия модального окна
      expect(find.text('Создать идею'), findsNothing);
    });

    testWidgets('Ideas search functionality works',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран идей
      await tester.tap(find.text('Идеи'));
      await tester.pumpAndSettle();

      // Нажатие на кнопку поиска
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Проверка открытия диалога поиска
      expect(find.text('Поиск идей'), findsOneWidget);
      expect(find.text('Введите запрос...'), findsOneWidget);

      // Ввод поискового запроса
      await tester.enterText(find.byType(TextField), 'тест');
      await tester.pumpAndSettle();

      // Нажатие кнопки "Найти"
      await tester.tap(find.text('Найти'));
      await tester.pumpAndSettle();
    });

    testWidgets('Ideas filters work', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран идей
      await tester.tap(find.text('Идеи'));
      await tester.pumpAndSettle();

      // Нажатие на кнопку фильтров
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Проверка открытия диалога фильтров
      expect(find.text('Фильтры идей'), findsOneWidget);
      expect(find.text('Все'), findsOneWidget);
      expect(find.text('Популярные'), findsOneWidget);
      expect(find.text('Новые'), findsOneWidget);
      expect(find.text('Тренды'), findsOneWidget);

      // Выбор фильтра "Популярные"
      await tester.tap(find.text('Популярные'));
      await tester.pumpAndSettle();

      // Нажатие кнопки "Применить"
      await tester.tap(find.text('Применить'));
      await tester.pumpAndSettle();
    });

    testWidgets('Idea interactions work', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран идей
      await tester.tap(find.text('Идеи'));
      await tester.pumpAndSettle();

      // Ожидание загрузки идей
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Проверка наличия кнопок взаимодействия с идеями
      expect(find.byIcon(Icons.favorite_border), findsWidgets);
      expect(find.byIcon(Icons.comment_outlined), findsWidgets);
      expect(find.byIcon(Icons.share), findsWidgets);
      expect(find.byIcon(Icons.bookmark_border), findsWidgets);

      // Нажатие на лайк
      if (find.byIcon(Icons.favorite_border).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.favorite_border).first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Poll creation works', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран идей
      await tester.tap(find.text('Идеи'));
      await tester.pumpAndSettle();

      // Нажатие на кнопку добавления идеи
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Включение опроса
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Заполнение вопроса опроса
      await tester.enterText(find.byKey(const Key('poll_question_field')),
          'Какой ваш любимый цвет?',);
      await tester.pumpAndSettle();

      // Заполнение вариантов ответов
      await tester.enterText(find.byKey(const Key('poll_option_0')), 'Красный');
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('poll_option_1')), 'Синий');
      await tester.pumpAndSettle();

      // Нажатие кнопки "Опубликовать"
      await tester.tap(find.text('Опубликовать'));
      await tester.pumpAndSettle();
    });

    testWidgets('Pull to refresh works', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран идей
      await tester.tap(find.text('Идеи'));
      await tester.pumpAndSettle();

      // Выполнение pull-to-refresh
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Проверка, что список идей обновился
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('Idea card interactions work', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран идей
      await tester.tap(find.text('Идеи'));
      await tester.pumpAndSettle();

      // Ожидание загрузки идей
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Нажатие на карточку идеи (если есть)
      if (find.byType(Card).evaluate().isNotEmpty) {
        await tester.tap(find.byType(Card).first);
        await tester.pumpAndSettle();

        // Проверка, что открылись детали идеи
        expect(find.text('Открытие идеи'), findsOneWidget);
      }
    });
  });
}
