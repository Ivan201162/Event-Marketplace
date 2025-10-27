import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:event_marketplace_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Requests Flow Tests', () {
    testWidgets('Requests screen loads with list', (WidgetTester tester) async {
      // Запуск приложения
      app.main();
      await tester.pumpAndSettle();

      // Ожидание загрузки главного экрана
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Переход на экран заявок
      await tester.tap(find.text('Заявки'));
      await tester.pumpAndSettle();

      // Проверка наличия экрана заявок
      expect(find.text('Заявки'), findsOneWidget);

      // Проверка наличия кнопки добавления
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Проверка наличия фильтров
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('Create request flow works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран заявок
      await tester.tap(find.text('Заявки'));
      await tester.pumpAndSettle();

      // Нажатие на кнопку добавления заявки
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Проверка открытия экрана создания заявки
      expect(find.text('Создать заявку'), findsOneWidget);

      // Заполнение формы
      await tester.enterText(
          find.byKey(const Key('title_field')), 'Тестовая заявка');
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('description_field')),
          'Описание тестовой заявки');
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('city_field')), 'Москва');
      await tester.pumpAndSettle();

      // Выбор даты
      await tester.tap(find.text('Выберите дату'));
      await tester.pumpAndSettle();

      // Выбор завтрашней даты
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await tester.tap(find.text('${tomorrow.day}'));
      await tester.pumpAndSettle();

      // Нажатие кнопки "ОК" в календаре
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Нажатие кнопки "Сохранить"
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();

      // Проверка возврата на экран заявок
      expect(find.text('Заявки'), findsOneWidget);
    });

    testWidgets('Request filters work', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран заявок
      await tester.tap(find.text('Заявки'));
      await tester.pumpAndSettle();

      // Нажатие на кнопку фильтров
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Проверка открытия диалога фильтров
      expect(find.text('Фильтры'), findsOneWidget);
      expect(find.text('Все'), findsOneWidget);
      expect(find.text('Открытые'), findsOneWidget);
      expect(find.text('В работе'), findsOneWidget);
      expect(find.text('Завершённые'), findsOneWidget);

      // Выбор фильтра "Открытые"
      await tester.tap(find.text('Открытые'));
      await tester.pumpAndSettle();

      // Нажатие кнопки "Применить"
      await tester.tap(find.text('Применить'));
      await tester.pumpAndSettle();
    });

    testWidgets('Request search works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран заявок
      await tester.tap(find.text('Заявки'));
      await tester.pumpAndSettle();

      // Нажатие на кнопку поиска
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Проверка открытия диалога поиска
      expect(find.text('Поиск заявок'), findsOneWidget);
      expect(find.text('Введите запрос...'), findsOneWidget);

      // Ввод поискового запроса
      await tester.enterText(find.byType(TextField), 'тест');
      await tester.pumpAndSettle();

      // Нажатие кнопки "Найти"
      await tester.tap(find.text('Найти'));
      await tester.pumpAndSettle();
    });

    testWidgets('Request details screen works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран заявок
      await tester.tap(find.text('Заявки'));
      await tester.pumpAndSettle();

      // Ожидание загрузки заявок
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Нажатие на первую заявку (если есть)
      if (find.byType(Card).evaluate().isNotEmpty) {
        await tester.tap(find.byType(Card).first);
        await tester.pumpAndSettle();

        // Проверка открытия экрана деталей заявки
        expect(find.text('Детали заявки'), findsOneWidget);
      }
    });

    testWidgets('Pull to refresh works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Переход на экран заявок
      await tester.tap(find.text('Заявки'));
      await tester.pumpAndSettle();

      // Выполнение pull-to-refresh
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Проверка, что список заявок обновился
      expect(find.byType(Card), findsWidgets);
    });
  });
}
