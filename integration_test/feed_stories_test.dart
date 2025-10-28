import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feed and Stories Tests', () {
    testWidgets('Feed loads with stories and posts',
        (tester) async {
      // Запуск приложения
      app.main();
      await tester.pumpAndSettle();

      // Ожидание загрузки главного экрана
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Проверка наличия ленты
      expect(find.text('Лента'), findsOneWidget);

      // Проверка наличия Stories
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Проверка наличия постов
      expect(find.byType(Card), findsWidgets);

      // Проверка кнопок действий
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('Search functionality works', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Нажатие на кнопку поиска
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Проверка открытия диалога поиска
      expect(find.text('Поиск'), findsOneWidget);
      expect(find.text('Введите запрос...'), findsOneWidget);

      // Ввод поискового запроса
      await tester.enterText(find.byType(TextField), 'тест');
      await tester.pumpAndSettle();

      // Нажатие кнопки "Найти"
      await tester.tap(find.text('Найти'));
      await tester.pumpAndSettle();
    });

    testWidgets('Filter functionality works', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Нажатие на кнопку фильтров
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Проверка открытия диалога фильтров
      expect(find.text('Фильтры'), findsOneWidget);
      expect(find.text('Все'), findsOneWidget);
      expect(find.text('Популярные'), findsOneWidget);
      expect(find.text('Недавние'), findsOneWidget);

      // Выбор фильтра "Популярные"
      await tester.tap(find.text('Популярные'));
      await tester.pumpAndSettle();

      // Нажатие кнопки "Применить"
      await tester.tap(find.text('Применить'));
      await tester.pumpAndSettle();
    });

    testWidgets('Post interactions work', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Ожидание загрузки постов
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Проверка наличия кнопок взаимодействия с постами
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

    testWidgets('Pull to refresh works', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Выполнение pull-to-refresh
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Проверка, что лента обновилась
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('Stories interaction works', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Проверка наличия Stories
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Нажатие на Story (если есть)
      if (find.byType(GestureDetector).evaluate().isNotEmpty) {
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();
      }
    });
  });
}
